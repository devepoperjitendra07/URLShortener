package com.goindiainfotech.urlshortener.controller;

import com.goindiainfotech.urlshortener.dto.ddl.DdlRegisterDto;
import com.goindiainfotech.urlshortener.dto.ddl.DdlResolveDto;
import com.goindiainfotech.urlshortener.dto.ddl.DdlResolveResponseDto;
import com.goindiainfotech.urlshortener.entity.DeepLinkConfig;
import com.goindiainfotech.urlshortener.entity.DdlLog;
import com.goindiainfotech.urlshortener.entity.UrlMapping;
import com.goindiainfotech.urlshortener.repository.DdlLogRepository;
import com.goindiainfotech.urlshortener.repository.UrlMappingRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.time.OffsetDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/api/ddl")
@RequiredArgsConstructor
@Slf4j
public class DdlController {

    private final StringRedisTemplate redisTemplate;
    private final UrlMappingRepository urlMappingRepository;
    private final DdlLogRepository ddlLogRepository;

    private final ObjectMapper objectMapper;

    private static final String REDIS_DDL_PREFIX = "urlshortener:ddl:";

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DdlCachePayload {
        private String shortCode;
        private String sessionId;
        private String utmSource;
        private String utmMedium;
        private String utmCampaign;
        private String utmTerm;
        private String utmContent;
    }

    @PostMapping("/register")
    public ResponseEntity<Void> register(@RequestBody @Valid DdlRegisterDto dto) {
        String redisKey = REDIS_DDL_PREFIX + dto.getFingerprint();
        try {
            DdlCachePayload payload = DdlCachePayload.builder()
                    .shortCode(dto.getShortCode())
                    .sessionId(dto.getSessionId())
                    .utmSource(dto.getUtmSource())
                    .utmMedium(dto.getUtmMedium())
                    .utmCampaign(dto.getUtmCampaign())
                    .utmTerm(dto.getUtmTerm())
                    .utmContent(dto.getUtmContent())
                    .build();
            String json = objectMapper.writeValueAsString(payload);
            redisTemplate.opsForValue().set(redisKey, json, 60, TimeUnit.SECONDS);

            // Save deterministic referrer lookup key
            String referrerKey = REDIS_DDL_PREFIX + "referrer:" + dto.getSessionId();
            redisTemplate.opsForValue().set(referrerKey, json, 60, TimeUnit.SECONDS);
        } catch (Exception e) {
            log.error("Failed to serialize DDL payload", e);
        }

        log.info("[DDL] Registered fingerprint={}. shortCode={}, sessionId={}",
                dto.getFingerprint(), dto.getShortCode(), dto.getSessionId());

        ddlLogRepository.save(DdlLog.builder()
                .level("INFO")
                .tag("FINGERPRINT")
                .message("Fingerprint registered successfully for shortCode=" + dto.getShortCode())
                .deviceId(dto.getFingerprint())
                .sessionId(dto.getSessionId())
                .createdAt(OffsetDateTime.now())
                .build());

        return ResponseEntity.ok().build();
    }

    @PostMapping("/resolve")
    public ResponseEntity<DdlResolveResponseDto> resolve(@RequestBody @Valid DdlResolveDto dto) {
        String redisKey = REDIS_DDL_PREFIX + dto.getFingerprint();
        String cached = redisTemplate.opsForValue().get(redisKey);

        if (cached == null) {
            log.info("[DDL] No deferred link found for fingerprint={}", dto.getFingerprint());
            ddlLogRepository.save(DdlLog.builder()
                    .level("WARN")
                    .tag("DDL_RESOLVER")
                    .message("No deferred link found for fingerprint: " + dto.getFingerprint())
                    .deviceId(dto.getFingerprint())
                    .createdAt(OffsetDateTime.now())
                    .build());
            return ResponseEntity.notFound().build();
        }

        // Delete from Redis immediately (one-shot consume)
        redisTemplate.delete(redisKey);

        DdlCachePayload payload = null;
        try {
            payload = objectMapper.readValue(cached, DdlCachePayload.class);
        } catch (Exception e) {
            log.error("Failed to deserialize DDL payload", e);
            return ResponseEntity.notFound().build();
        }

        String shortCode = payload.getShortCode();
        String sessionId = payload.getSessionId();

        Optional<UrlMapping> mappingOpt = urlMappingRepository.findByShortCode(shortCode);
        if (mappingOpt.isEmpty() || mappingOpt.get().getDeepLinkCfg() == null) {
            return ResponseEntity.notFound().build();
        }

        UrlMapping mapping = mappingOpt.get();
        log.info("[DDL] Match found! Redirecting session={} to deep link destination={}",
                sessionId, mapping.getDeepLinkCfg().getDestination());

        ddlLogRepository.save(DdlLog.builder()
                .level("INFO")
                .tag("DDL_RESOLVER")
                .message("Match found. Redirecting to deep link: " + mapping.getDeepLinkCfg().getDestination())
                .deviceId(dto.getFingerprint())
                .sessionId(sessionId)
                .createdAt(OffsetDateTime.now())
                .build());

        return ResponseEntity.ok(mapToResponse(mapping, payload));
    }

    @GetMapping("/resolve-direct/{code}")
    public ResponseEntity<DdlResolveResponseDto> resolveDirect(@PathVariable String code) {
        Optional<UrlMapping> mappingOpt = urlMappingRepository.findByShortCode(code);
        if (mappingOpt.isEmpty() || mappingOpt.get().getDeepLinkCfg() == null) {
            return ResponseEntity.notFound().build();
        }

        UrlMapping mapping = mappingOpt.get();
        log.info("[DDL] Direct app-link match found for shortCode={} to deep link destination={}",
                code, mapping.getDeepLinkCfg().getDestination());

        ddlLogRepository.save(DdlLog.builder()
                .level("INFO")
                .tag("DDL_RESOLVER")
                .message("Direct App Link match. Redirecting to deep link: " + mapping.getDeepLinkCfg().getDestination())
                .createdAt(OffsetDateTime.now())
                .build());

        return ResponseEntity.ok(mapToResponse(mapping, null));
    }

    @PostMapping("/resolve-referrer")
    public ResponseEntity<DdlResolveResponseDto> resolveReferrer(@RequestBody @Valid com.goindiainfotech.urlshortener.dto.ddl.DdlResolveReferrerDto dto) {
        String redisKey = REDIS_DDL_PREFIX + "referrer:" + dto.getSessionId();
        String cached = redisTemplate.opsForValue().get(redisKey);

        if (cached == null) {
            log.info("[DDL] No deferred link found for install referrer sessionId={}", dto.getSessionId());
            ddlLogRepository.save(DdlLog.builder()
                    .level("WARN")
                    .tag("DDL_RESOLVER")
                    .message("No deferred link found for install referrer sessionId: " + dto.getSessionId())
                    .sessionId(dto.getSessionId())
                    .createdAt(OffsetDateTime.now())
                    .build());
            return ResponseEntity.notFound().build();
        }

        // Delete from Redis immediately (one-shot consume)
        redisTemplate.delete(redisKey);

        DdlCachePayload payload = null;
        try {
            // Fallback for backwards compatibility if it's just a raw shortCode string
            if (!cached.startsWith("{")) {
                payload = DdlCachePayload.builder().shortCode(cached).sessionId(dto.getSessionId()).build();
            } else {
                payload = objectMapper.readValue(cached, DdlCachePayload.class);
            }
        } catch (Exception e) {
            log.error("Failed to deserialize DDL referrer payload", e);
            return ResponseEntity.notFound().build();
        }

        String shortCode = payload.getShortCode();

        Optional<UrlMapping> mappingOpt = urlMappingRepository.findByShortCode(shortCode);
        if (mappingOpt.isEmpty() || mappingOpt.get().getDeepLinkCfg() == null) {
            return ResponseEntity.notFound().build();
        }

        UrlMapping mapping = mappingOpt.get();
        log.info("[DDL] Exact Referrer match found! Redirecting sessionId={} to deep link destination={}",
                dto.getSessionId(), mapping.getDeepLinkCfg().getDestination());

        ddlLogRepository.save(DdlLog.builder()
                .level("INFO")
                .tag("DDL_RESOLVER")
                .message("Exact Referrer match found. Redirecting to deep link: " + mapping.getDeepLinkCfg().getDestination())
                .sessionId(dto.getSessionId())
                .createdAt(OffsetDateTime.now())
                .build());

        return ResponseEntity.ok(mapToResponse(mapping, payload));
    }

    private DdlResolveResponseDto mapToResponse(UrlMapping mapping, DdlCachePayload payload) {
        DdlResolveResponseDto response = DdlResolveResponseDto.builder()
                .enabled(mapping.getDeepLinkCfg().isEnabled())
                .destination(mapping.getDeepLinkCfg().getDestination())
                .params(mapping.getDeepLinkCfg().getParams())
                .shortCode(mapping.getShortCode())
                .longUrl(mapping.getLongUrl())
                .build();
                
        if (payload != null) {
            response.setUtmSource(payload.getUtmSource());
            response.setUtmMedium(payload.getUtmMedium());
            response.setUtmCampaign(payload.getUtmCampaign());
            response.setUtmTerm(payload.getUtmTerm());
            response.setUtmContent(payload.getUtmContent());
        }
        
        return response;
    }
}
