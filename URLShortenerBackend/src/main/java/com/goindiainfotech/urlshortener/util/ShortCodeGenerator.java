package com.goindiainfotech.urlshortener.util;

import com.goindiainfotech.urlshortener.repository.UrlMappingRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class ShortCodeGenerator {

    private final StringRedisTemplate redisTemplate;
    private final UrlMappingRepository urlMappingRepository;

    private static final String BASE62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    private static final String REDIS_COUNTER_KEY = "urlshortener:counter";

    @PostConstruct
    public void initCounter() {
        Boolean hasKey = redisTemplate.hasKey(REDIS_COUNTER_KEY);
        if (hasKey == null || !hasKey) {
            log.info("[BOOTSTRAP] Redis counter key not found. Scanning DB to seed the counter...");
            long maxVal = 100000L; // Default base

            List<String> shortCodes = urlMappingRepository.findAllShortCodes();
            for (String code : shortCodes) {
                // Generated short codes start at 100,000L (3 chars) and stay short (<= 7 chars).
                // Long custom slugs (e.g., 'nshedggdshsh') will be ignored by this length filter.
                if (code.length() >= 3 && code.length() <= 4) {
                    try {
                        long decoded = decodeBase62(code);
                        if (decoded >= 100000L && decoded <= 10000000L) {
                            if (decoded > maxVal) {
                                maxVal = decoded;
                            }
                        }
                    } catch (Exception ignored) {
                        // Skip if it contains non-base62 characters
                    }
                }
            }

            redisTemplate.opsForValue().set(REDIS_COUNTER_KEY, String.valueOf(maxVal));
            log.info("[BOOTSTRAP] Redis counter initialized successfully to: {}", maxVal);
        } else {
            log.info("[BOOTSTRAP] Redis counter already exists: {}", redisTemplate.opsForValue().get(REDIS_COUNTER_KEY));
        }
    }

    public String generate() {
        while (true) {
            Long val = redisTemplate.opsForValue().increment(REDIS_COUNTER_KEY);
            if (val == null) {
                val = 100000L;
            }
            String code = encodeBase62(val);
            if (!urlMappingRepository.existsByShortCode(code)) {
                return code;
            }
            log.warn("[COLLISION] Short code '{}' generated from counter already exists in DB! Incrementing again...", code);
        }
    }

    private String encodeBase62(long num) {
        StringBuilder sb = new StringBuilder();
        while (num > 0) {
            sb.append(BASE62.charAt((int) (num % 62)));
            num /= 62;
        }
        return sb.reverse().toString();
    }

    private long decodeBase62(String s) {
        long num = 0;
        for (int i = 0; i < s.length(); i++) {
            int charIndex = BASE62.indexOf(s.charAt(i));
            if (charIndex == -1) {
                throw new IllegalArgumentException("Invalid Base62 character: " + s.charAt(i));
            }
            num = num * 62 + charIndex;
        }
        return num;
    }
}
