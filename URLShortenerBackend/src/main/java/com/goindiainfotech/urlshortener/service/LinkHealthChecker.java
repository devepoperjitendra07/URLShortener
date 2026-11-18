package com.goindiainfotech.urlshortener.service;

import com.goindiainfotech.urlshortener.entity.LinkStatus;
import com.goindiainfotech.urlshortener.entity.UrlMapping;
import com.goindiainfotech.urlshortener.repository.UrlMappingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class LinkHealthChecker {

    private final UrlMappingRepository urlMappingRepository;
    private final StringRedisTemplate redisTemplate;

    private static final String REDIS_CACHE_PREFIX = "urlshortener:cache:";

    @Scheduled(fixedRate = 3600000) // every hour
    @Transactional
    public void checkAllLinksHealth() {
        List<UrlMapping> activeMappings = urlMappingRepository.findByStatus(LinkStatus.ACTIVE);
        if (activeMappings.isEmpty()) return;

        log.info("[HEALTH] Starting health check for {} active links", activeMappings.size());

        for (UrlMapping mapping : activeMappings) {
            try {
                URI uri = new URI(mapping.getLongUrl());
                URL url = uri.toURL();
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("HEAD");
                conn.setConnectTimeout(5000);
                conn.setReadTimeout(5000);
                
                int responseCode = conn.getResponseCode();
                if (responseCode >= 400) {
                    markLinkAsBroken(mapping, "HTTP " + responseCode);
                }
            } catch (Exception e) {
                markLinkAsBroken(mapping, e.getMessage());
            }
        }
    }

    private void markLinkAsBroken(UrlMapping mapping, String reason) {
        log.warn("[HEALTH] Link shortCode={} is broken! Reason: {}. Marking as BROKEN.", mapping.getShortCode(), reason);
        mapping.setStatus(LinkStatus.BROKEN);
        urlMappingRepository.save(mapping);

        // Evict from Redis redirect cache
        redisTemplate.delete(REDIS_CACHE_PREFIX + mapping.getShortCode());
    }

    // Background job to clean expired links (runs hourly)
    @Scheduled(fixedRate = 3600000)
    @Transactional
    public void checkLinkExpirations() {
        log.info("[HEALTH] Checking for expired links...");
        int expiredCount = urlMappingRepository.markExpiredLinks();
        if (expiredCount > 0) {
            log.info("[HEALTH] Marked {} links as EXPIRED", expiredCount);
            // Evict all from Redis to be safe (or clean dynamically)
            // For simple cache-aside, clients hitting an expired link will fetch from DB, see status, and fail
        }
    }
}
