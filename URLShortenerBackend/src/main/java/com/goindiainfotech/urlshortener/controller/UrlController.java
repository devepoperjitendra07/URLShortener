package com.goindiainfotech.urlshortener.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.goindiainfotech.urlshortener.dto.url.ShortenRequestDto;
import com.goindiainfotech.urlshortener.dto.url.ShortenResponseDto;
import com.goindiainfotech.urlshortener.dto.url.UrlMappingDto;
import com.goindiainfotech.urlshortener.entity.App;
import com.goindiainfotech.urlshortener.entity.DeepLinkConfig;
import com.goindiainfotech.urlshortener.entity.LinkStatus;
import com.goindiainfotech.urlshortener.entity.User;
import com.goindiainfotech.urlshortener.entity.UrlMapping;
import com.goindiainfotech.urlshortener.exception.ConflictException;
import com.goindiainfotech.urlshortener.exception.ResourceNotFoundException;
import com.goindiainfotech.urlshortener.repository.UrlMappingRepository;
import com.goindiainfotech.urlshortener.repository.AppRepository;
import com.goindiainfotech.urlshortener.service.ClickService;
import com.goindiainfotech.urlshortener.service.RedirectionService;
import com.goindiainfotech.urlshortener.util.SecurityUtils;
import com.goindiainfotech.urlshortener.util.ShortCodeGenerator;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class UrlController {

    private final UrlMappingRepository urlMappingRepository;
    private final AppRepository appRepository;
    private final ShortCodeGenerator shortCodeGenerator;
    private final ClickService clickService;
    private final RedirectionService redirectionService;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    private static final String REDIS_CACHE_PREFIX = "urlshortener:cache:";

    @org.springframework.beans.factory.annotation.Value("${app.base-url}")
    private String appBaseUrl;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CachedUrl {
        private UUID id;
        private String shortCode;
        private String longUrl;
        private LinkStatus status;
        private OffsetDateTime expiryDate;
        private DeepLinkConfig deepLinkCfg;

        private String androidPackageName;
        private String playStoreUrl;
        private String iosBundleId;
        private String appStoreUrl;

        public boolean isExpired() {
            return expiryDate != null && OffsetDateTime.now().isAfter(expiryDate);
        }
    }

    @PostMapping("/shorten")
    @Transactional
    public ResponseEntity<ShortenResponseDto> shorten(@RequestBody @Valid ShortenRequestDto dto) {
        User user = SecurityUtils.currentUser();

        String code;
        if (dto.getCustomSlug() != null && !dto.getCustomSlug().trim().isEmpty()) {
            String cleanSlug = dto.getCustomSlug().trim();
            if (urlMappingRepository.existsByShortCode(cleanSlug)) {
                throw new ConflictException("Slug already in use: " + cleanSlug);
            }
            code = cleanSlug;
        } else {
            code = shortCodeGenerator.generate();
        }

        App app = null;
        if (dto.getPackageName() != null && !dto.getPackageName().isEmpty()) {
            List<App> matchedApps = appRepository.findByAndroidPackageNameAndUserId(dto.getPackageName(), user.getId());
            if (matchedApps.isEmpty()) {
                matchedApps = appRepository.findByIosBundleIdAndUserId(dto.getPackageName(), user.getId());
            }
            if (!matchedApps.isEmpty()) {
                app = matchedApps.get(0);
            }
        }

        if (app == null) {
            List<App> userApps = appRepository.findByUserId(user.getId());
            if (!userApps.isEmpty()) {
                app = userApps.get(0);
            }
        }

        UrlMapping mapping = UrlMapping.builder()
                .shortCode(code)
                .longUrl(dto.getLongUrl())
                .user(user)
                .app(app)
                .status(LinkStatus.ACTIVE)
                .expiryDate(dto.getExpiryDate())
                .deepLinkCfg(dto.getDeepLinkCfg())
                .createdAt(OffsetDateTime.now())
                .build();

        UrlMapping saved = urlMappingRepository.save(mapping);
        log.info("[SHORTEN] Created mapping: shortCode={} -> longUrl={}", code, dto.getLongUrl());

        return ResponseEntity.status(HttpStatus.CREATED).body(ShortenResponseDto.builder()
                .shortUrl(appBaseUrl + "/r/" + code)
                .longUrl(saved.getLongUrl())
                .createdAt(saved.getCreatedAt())
                .status("LIVE_DEPLOYED")
                .build());
    }

    @GetMapping("/r/{code}")
    public ResponseEntity<?> redirect(@PathVariable String code, HttpServletRequest request) {
        String cacheKey = REDIS_CACHE_PREFIX + code;
        CachedUrl cached = null;

        try {
            String json = redisTemplate.opsForValue().get(cacheKey);
            if (json != null) {
                cached = objectMapper.readValue(json, CachedUrl.class);
            }
        } catch (Exception e) {
            log.error("[REDIRECT] Failed to load URL mapping from Redis cache", e);
        }

        UrlMapping mapping;
        if (cached != null) {
            App app = null;
            if (cached.getAndroidPackageName() != null || cached.getIosBundleId() != null) {
                app = App.builder()
                        .androidPackageName(cached.getAndroidPackageName())
                        .playStoreUrl(cached.getPlayStoreUrl())
                        .iosBundleId(cached.getIosBundleId())
                        .appStoreUrl(cached.getAppStoreUrl())
                        .build();
            }

            // Reconstruct a lightweight mapping instance for processing
            mapping = UrlMapping.builder()
                    .id(cached.getId())
                    .shortCode(cached.getShortCode())
                    .longUrl(cached.getLongUrl())
                    .status(cached.getStatus())
                    .expiryDate(cached.getExpiryDate())
                    .deepLinkCfg(cached.getDeepLinkCfg())
                    .app(app)
                    .build();
        } else {
            mapping = urlMappingRepository.findByShortCode(code)
                    .orElseThrow(() -> new ResourceNotFoundException("Short URL not found: " + code));

            // Write back to cache
            try {
                CachedUrl.CachedUrlBuilder toCacheBuilder = CachedUrl.builder()
                        .id(mapping.getId())
                        .shortCode(mapping.getShortCode())
                        .longUrl(mapping.getLongUrl())
                        .status(mapping.getStatus())
                        .expiryDate(mapping.getExpiryDate())
                        .deepLinkCfg(mapping.getDeepLinkCfg());

                if (mapping.getApp() != null) {
                    toCacheBuilder
                            .androidPackageName(mapping.getApp().getAndroidPackageName())
                            .playStoreUrl(mapping.getApp().getPlayStoreUrl())
                            .iosBundleId(mapping.getApp().getIosBundleId())
                            .appStoreUrl(mapping.getApp().getAppStoreUrl());
                }

                CachedUrl toCache = toCacheBuilder.build();
                redisTemplate.opsForValue().set(cacheKey, objectMapper.writeValueAsString(toCache), 1, TimeUnit.HOURS);
            } catch (Exception e) {
                log.error("[REDIRECT] Failed to cache URL mapping", e);
            }
        }

        if (mapping.isExpired()) {
            throw new ResponseStatusException(HttpStatus.GONE, "Short URL has expired");
        }
        if (mapping.getStatus() == LinkStatus.BROKEN) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Short URL is broken");
        }

        // Record click stats asynchronously
        String userAgent = request.getHeader("User-Agent");
        String referer = request.getHeader("Referer");
        String remoteAddr = request.getRemoteAddr();
        
        String utmSource = request.getParameter("utm_source");
        String utmMedium = request.getParameter("utm_medium");
        String utmCampaign = request.getParameter("utm_campaign");
        String utmTerm = request.getParameter("utm_term");
        String utmContent = request.getParameter("utm_content");

        clickService.recordAsync(mapping, userAgent, referer, remoteAddr, utmSource, utmMedium, utmCampaign, utmTerm, utmContent);

        // Perform OS detection and direct/deferred redirection
        return redirectionService.buildRedirect(mapping, request);
    }

    @GetMapping("/links")
    public ResponseEntity<Page<UrlMappingDto>> getLinks(Pageable pageable) {
        User user = SecurityUtils.currentUser();
        Page<UrlMapping> page = urlMappingRepository.findByUserIdOrderByCreatedAtDesc(user.getId(), pageable);

        Page<UrlMappingDto> dtoPage = page.map(m -> UrlMappingDto.builder()
                .id(m.getId())
                .shortCode(m.getShortCode())
                .longUrl(m.getLongUrl())
                .status(m.getStatus())
                .clickCount(m.getClickCount())
                .createdAt(m.getCreatedAt())
                .expiryDate(m.getExpiryDate())
                .deepLinkCfg(m.getDeepLinkCfg())
                .build());

        return ResponseEntity.ok(dtoPage);
    }

    @DeleteMapping("/links/{id}")
    @Transactional
    public ResponseEntity<Void> deleteLink(@PathVariable UUID id) {
        User user = SecurityUtils.currentUser();
        UrlMapping mapping = urlMappingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Short URL not found"));

        if (!mapping.getUser().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
        }

        urlMappingRepository.delete(mapping);
        // Evict from Redis cache
        redisTemplate.delete(REDIS_CACHE_PREFIX + mapping.getShortCode());
        log.info("[SHORTEN] Deleted shortCode={}", mapping.getShortCode());

        return ResponseEntity.noContent().build();
    }
}
