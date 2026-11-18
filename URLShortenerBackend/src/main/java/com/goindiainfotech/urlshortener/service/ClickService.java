package com.goindiainfotech.urlshortener.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.goindiainfotech.urlshortener.dto.url.ClickEventDto;
import com.goindiainfotech.urlshortener.entity.Click;
import com.goindiainfotech.urlshortener.entity.DeviceType;
import com.goindiainfotech.urlshortener.entity.UrlMapping;
import com.goindiainfotech.urlshortener.repository.ClickRepository;
import com.goindiainfotech.urlshortener.repository.UrlMappingRepository;
import jakarta.persistence.EntityManager;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class ClickService {

    private final ClickRepository clickRepository;
    private final UrlMappingRepository urlMappingRepository;
    private final StringRedisTemplate redisTemplate;
    private final EntityManager entityManager;
    private final ObjectMapper objectMapper;

    private static final String REDIS_CLICKS_PREFIX = "urlshortener:clicks:";
    private static final String REDIS_BUFFER_KEY = "urlshortener:click_buffer";

    @Async
    public void recordAsync(UrlMapping mapping, String userAgent, String referer, String remoteAddr, 
                            String utmSource, String utmMedium, String utmCampaign, String utmTerm, String utmContent) {
        try {
            DeviceType deviceType = detectDevice(userAgent);
            String country = getMockCountry(remoteAddr);

            ClickEventDto dto = ClickEventDto.builder()
                    .urlMappingId(mapping.getId())
                    .clickedAt(OffsetDateTime.now())
                    .deviceType(deviceType.name())
                    .country(country)
                    .referer(referer)
                    .utmSource(utmSource)
                    .utmMedium(utmMedium)
                    .utmCampaign(utmCampaign)
                    .utmTerm(utmTerm)
                    .utmContent(utmContent)
                    .build();

            String json = objectMapper.writeValueAsString(dto);
            redisTemplate.opsForList().leftPush(REDIS_BUFFER_KEY, json);

            log.info("[ANALYTICS] Buffered click event to Redis for shortCode={}", mapping.getShortCode());

            // Redis counter INCR (synced hourly back to Postgres mapping table)
            String redisKey = REDIS_CLICKS_PREFIX + mapping.getId();
            redisTemplate.opsForValue().increment(redisKey);
        } catch (Exception e) {
            log.error("[ANALYTICS] Failed to buffer click event to Redis", e);
        }
    }

    @Scheduled(fixedRate = 10000) // every 10 seconds
    @Transactional
    public void flushClickBuffer() {
        List<String> rawEvents = new ArrayList<>();
        String json;
        // Pop all elements currently in the buffer
        while ((json = redisTemplate.opsForList().rightPop(REDIS_BUFFER_KEY)) != null) {
            rawEvents.add(json);
        }

        if (rawEvents.isEmpty()) {
            return;
        }

        log.info("[ANALYTICS] Popped {} click events from Redis buffer. Writing to DB...", rawEvents.size());
        List<ClickEventDto> dtos = new ArrayList<>();
        List<Click> clicks = new ArrayList<>();

        for (String eventJson : rawEvents) {
            try {
                ClickEventDto dto = objectMapper.readValue(eventJson, ClickEventDto.class);
                dtos.add(dto);
                
                // Get proxy reference for UrlMapping to avoid executing a SELECT query for each mapping
                UrlMapping mappingRef = entityManager.getReference(UrlMapping.class, dto.getUrlMappingId());

                Click click = Click.builder()
                        .urlMapping(mappingRef)
                        .clickedAt(dto.getClickedAt())
                        .deviceType(DeviceType.valueOf(dto.getDeviceType()))
                        .country(dto.getCountry())
                        .referer(dto.getReferer())
                        .utmSource(dto.getUtmSource())
                        .utmMedium(dto.getUtmMedium())
                        .utmCampaign(dto.getUtmCampaign())
                        .utmTerm(dto.getUtmTerm())
                        .utmContent(dto.getUtmContent())
                        .build();
                clicks.add(click);
            } catch (Exception e) {
                log.error("[ANALYTICS] Error deserializing click event from buffer: {}", eventJson, e);
            }
        }

        try {
            clickRepository.saveAll(clicks);
            log.info("[ANALYTICS] Successfully batch-inserted {} click logs to PostgreSQL.", clicks.size());
        } catch (Exception e) {
            log.error("[ANALYTICS] Failed to batch insert clicks to PostgreSQL. Re-queueing to Redis to prevent data loss...", e);
            // Re-queue raw events back to Redis
            for (String eventJson : rawEvents) {
                try {
                    redisTemplate.opsForList().leftPush(REDIS_BUFFER_KEY, eventJson);
                } catch (Exception ex) {
                    log.error("[ANALYTICS] CRITICAL: Failed to re-queue event: {}", eventJson, ex);
                }
            }
        }
    }

    private DeviceType detectDevice(String ua) {
        if (ua == null) return DeviceType.UNKNOWN;
        if (ua.contains("Android")) return DeviceType.ANDROID;
        if (ua.contains("iPhone") || ua.contains("iPad")) return DeviceType.IOS;
        return DeviceType.DESKTOP;
    }

    private String getMockCountry(String ip) {
        // Return ISO codes based on simple hashes for local variability
        if (ip == null) return "US";
        int hash = ip.hashCode();
        String[] countries = {"IN", "US", "GB", "DE", "FR", "CA"};
        return countries[Math.abs(hash) % countries.length];
    }

    @Scheduled(fixedRate = 5000) // every 5 seconds
    @Transactional
    public void syncClickCounts() {
        Set<String> keys = redisTemplate.keys(REDIS_CLICKS_PREFIX + "*");
        if (keys == null || keys.isEmpty()) return;

        log.info("[ANALYTICS] Starting sync of Redis click counters back to database");
        for (String key : keys) {
            try {
                String countStr = redisTemplate.opsForValue().getAndDelete(key);
                if (countStr != null) {
                    UUID urlId = UUID.fromString(key.substring(REDIS_CLICKS_PREFIX.length()));
                    long count = Long.parseLong(countStr);
                    urlMappingRepository.incrementClickCount(urlId, count);
                    log.info("[ANALYTICS] Synced click increment +{} to UrlMapping={}", count, urlId);
                }
            } catch (Exception e) {
                log.error("[ANALYTICS] Failed to sync click counter key: {}", key, e);
            }
        }
    }
}
