package com.goindiainfotech.urlshortener.controller;

import com.goindiainfotech.urlshortener.dto.admin.AdminShortenRequestDto;
import com.goindiainfotech.urlshortener.dto.admin.AdminShortenResponseDto;
import com.goindiainfotech.urlshortener.entity.App;
import com.goindiainfotech.urlshortener.entity.DeepLinkConfig;
import com.goindiainfotech.urlshortener.entity.LinkStatus;
import com.goindiainfotech.urlshortener.entity.UrlMapping;
import com.goindiainfotech.urlshortener.entity.User;
import com.goindiainfotech.urlshortener.exception.ConflictException;
import com.goindiainfotech.urlshortener.exception.ResourceNotFoundException;
import com.goindiainfotech.urlshortener.repository.AppRepository;
import com.goindiainfotech.urlshortener.repository.UrlMappingRepository;
import com.goindiainfotech.urlshortener.util.SecurityUtils;
import com.goindiainfotech.urlshortener.util.ShortCodeGenerator;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/links")
@RequiredArgsConstructor
@Slf4j
public class AdminLinkController {

    private final UrlMappingRepository urlMappingRepository;
    private final AppRepository appRepository;
    private final ShortCodeGenerator shortCodeGenerator;
    private final StringRedisTemplate redisTemplate;

    private static final String REDIS_CACHE_PREFIX = "urlshortener:cache:";

    @org.springframework.beans.factory.annotation.Value("${app.base-url}")
    private String appBaseUrl;

    @PostMapping
    @Transactional
    public ResponseEntity<AdminShortenResponseDto> createDeepLink(@RequestBody @Valid AdminShortenRequestDto dto) {
        User user = SecurityUtils.currentUser();

        App app = appRepository.findById(dto.getAppId())
                .orElseThrow(() -> new ResourceNotFoundException("Application not found"));

        if (!app.getUser().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
        }

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

        // Long URL is the app's store URL, acting as store fallback
        String fallbackUrl = app.getPlayStoreUrl() != null ? app.getPlayStoreUrl() : app.getAppStoreUrl();

        DeepLinkConfig deepLinkConfig = DeepLinkConfig.builder()
                .enabled(true)
                .destination(dto.getDestinationUri())
                .params(new HashMap<>())
                .build();

        UrlMapping mapping = UrlMapping.builder()
                .shortCode(code)
                .longUrl(fallbackUrl)
                .user(user)
                .app(app)
                .status(LinkStatus.ACTIVE)
                .expiryDate(dto.getExpiryDate())
                .deepLinkCfg(deepLinkConfig)
                .createdAt(OffsetDateTime.now())
                .build();

        UrlMapping saved = urlMappingRepository.save(mapping);
        log.info("[ADMIN] Created deep link: shortCode={} -> destination={} for app={}", code, dto.getDestinationUri(), app.getName());

        return ResponseEntity.status(HttpStatus.CREATED).body(mapToResponseDto(saved));
    }

    @GetMapping
    public ResponseEntity<List<AdminShortenResponseDto>> listDeepLinks() {
        User user = SecurityUtils.currentUser();
        List<App> apps = appRepository.findByUserId(user.getId());

        if (apps.isEmpty()) {
            return ResponseEntity.ok(List.of());
        }

        List<UrlMapping> mappings = urlMappingRepository.findByAppInOrderByCreatedAtDesc(apps);
        List<AdminShortenResponseDto> response = mappings.stream()
                .map(this::mapToResponseDto)
                .collect(Collectors.toList());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<AdminShortenResponseDto> getDeepLinkDetails(@PathVariable UUID id) {
        User user = SecurityUtils.currentUser();
        UrlMapping mapping = urlMappingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Deep link not found"));

        if (mapping.getApp() == null || !mapping.getApp().getUser().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
        }

        return ResponseEntity.ok(mapToResponseDto(mapping));
    }

    @PutMapping("/{id}")
    @Transactional
    public ResponseEntity<AdminShortenResponseDto> updateDeepLink(@PathVariable UUID id, @RequestBody @Valid AdminShortenRequestDto dto) {
        User user = SecurityUtils.currentUser();
        UrlMapping mapping = urlMappingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Deep link not found"));

        if (mapping.getApp() == null || !mapping.getApp().getUser().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
        }

        App newApp = appRepository.findById(dto.getAppId())
                .orElseThrow(() -> new ResourceNotFoundException("Application not found"));

        if (!newApp.getUser().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
        }

        // If custom slug changed and is provided
        if (dto.getCustomSlug() != null && !dto.getCustomSlug().trim().isEmpty() && !dto.getCustomSlug().trim().equalsIgnoreCase(mapping.getShortCode())) {
            String cleanSlug = dto.getCustomSlug().trim();
            if (urlMappingRepository.existsByShortCode(cleanSlug)) {
                throw new ConflictException("Slug already in use: " + cleanSlug);
            }
            // Evict old cache
            redisTemplate.delete(REDIS_CACHE_PREFIX + mapping.getShortCode());
            mapping.setShortCode(cleanSlug);
        }

        // Evict current cache
        redisTemplate.delete(REDIS_CACHE_PREFIX + mapping.getShortCode());

        mapping.setApp(newApp);
        mapping.setLongUrl(newApp.getPlayStoreUrl() != null ? newApp.getPlayStoreUrl() : newApp.getAppStoreUrl());
        mapping.setExpiryDate(dto.getExpiryDate());

        DeepLinkConfig deepLinkConfig = DeepLinkConfig.builder()
                .enabled(true)
                .destination(dto.getDestinationUri())
                .params(new HashMap<>())
                .build();
        mapping.setDeepLinkCfg(deepLinkConfig);

        UrlMapping updated = urlMappingRepository.save(mapping);
        log.info("[ADMIN] Updated deep link shortCode={} destination={}", updated.getShortCode(), dto.getDestinationUri());

        return ResponseEntity.ok(mapToResponseDto(updated));
    }

    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<Void> deleteDeepLink(@PathVariable UUID id) {
        User user = SecurityUtils.currentUser();
        UrlMapping mapping = urlMappingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Deep link not found"));

        if (mapping.getApp() == null || !mapping.getApp().getUser().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
        }

        urlMappingRepository.delete(mapping);
        redisTemplate.delete(REDIS_CACHE_PREFIX + mapping.getShortCode());
        log.info("[ADMIN] Deleted deep link shortCode={}", mapping.getShortCode());

        return ResponseEntity.noContent().build();
    }

    private AdminShortenResponseDto mapToResponseDto(UrlMapping m) {
        return AdminShortenResponseDto.builder()
                .id(m.getId())
                .shortUrl(appBaseUrl + "/r/" + m.getShortCode())
                .longUrl(m.getLongUrl())
                .shortCode(m.getShortCode())
                .name(m.getDeepLinkCfg() != null ? "Deep Link: " + m.getShortCode() : "N/A") // Simple name helper for MVP
                .targetAppName(m.getApp() != null ? m.getApp().getName() : "N/A")
                .targetAppId(m.getApp() != null ? m.getApp().getId() : null)
                .targetAppPackageName(m.getApp() != null ? (m.getApp().getAndroidPackageName() != null ? m.getApp().getAndroidPackageName() : m.getApp().getIosBundleId()) : "N/A")
                .destinationUri(m.getDeepLinkCfg() != null ? m.getDeepLinkCfg().getDestination() : "N/A")
                .params(m.getDeepLinkCfg() != null ? m.getDeepLinkCfg().getParams() : null)
                .clickCount(m.getClickCount())
                .status(m.getStatus().toString())
                .expiryDate(m.getExpiryDate())
                .createdAt(m.getCreatedAt())
                .build();
    }
}
