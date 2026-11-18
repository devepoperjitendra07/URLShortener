package com.goindiainfotech.urlshortener.controller;

import com.goindiainfotech.urlshortener.dto.analytics.LinkAnalyticsDto;
import com.goindiainfotech.urlshortener.dto.analytics.UserSummaryDto;
import com.goindiainfotech.urlshortener.entity.LinkStatus;
import com.goindiainfotech.urlshortener.entity.UrlMapping;
import com.goindiainfotech.urlshortener.entity.User;
import com.goindiainfotech.urlshortener.exception.ResourceNotFoundException;
import com.goindiainfotech.urlshortener.repository.ClickRepository;
import com.goindiainfotech.urlshortener.repository.UrlMappingRepository;
import com.goindiainfotech.urlshortener.util.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
@Slf4j
public class AnalyticsController {

    private final UrlMappingRepository urlMappingRepository;
    private final ClickRepository clickRepository;

    @GetMapping("/{code}")
    public ResponseEntity<LinkAnalyticsDto> getLinkAnalytics(@PathVariable String code) {
        UrlMapping mapping = urlMappingRepository.findByShortCode(code)
                .orElseThrow(() -> new ResourceNotFoundException("Short code not found: " + code));

        OffsetDateTime now = OffsetDateTime.now();
        OffsetDateTime sevenDaysAgo = now.minusDays(7);
        OffsetDateTime fourteenDaysAgo = now.minusDays(14);

        long thisWeek = clickRepository.countBetween(mapping.getId(), sevenDaysAgo, now);
        long lastWeek = clickRepository.countBetween(mapping.getId(), fourteenDaysAgo, sevenDaysAgo);

        double weeklyChange = 0.0;
        if (lastWeek > 0) {
            weeklyChange = ((thisWeek - lastWeek) / (double) lastWeek) * 100.0;
            weeklyChange = Math.round(weeklyChange * 10.0) / 10.0;
        } else if (thisWeek > 0) {
            weeklyChange = 100.0;
        }

        return ResponseEntity.ok(LinkAnalyticsDto.builder()
                .shortCode(mapping.getShortCode())
                .longUrl(mapping.getLongUrl())
                .totalClicks(mapping.getClickCount() + clickRepository.countByUrlMappingId(mapping.getId()))
                .weeklyChange(weeklyChange)
                .clicksByDay(clickRepository.clicksByDay(mapping.getId(), sevenDaysAgo))
                .deviceDistribution(clickRepository.deviceDistribution(mapping.getId()))
                .utmDistribution(clickRepository.utmDistribution(mapping.getId()))
                .deepLinkCfg(mapping.getDeepLinkCfg())
                .build());
    }

    @GetMapping("/summary")
    public ResponseEntity<UserSummaryDto> getSummary() {
        User user = SecurityUtils.currentUser();
        UUID uid = user.getId();

        OffsetDateTime now = OffsetDateTime.now();
        OffsetDateTime sevenDaysAgo = now.minusDays(7);
        OffsetDateTime fourteenDaysAgo = now.minusDays(14);

        long totalClicks = clickRepository.totalClicksForUser(uid);
        long activeUrls = urlMappingRepository.countByUserIdAndStatus(uid, LinkStatus.ACTIVE);

        long thisWeekClicks = clickRepository.totalClicksForUserBetween(uid, sevenDaysAgo, now);
        long lastWeekClicks = clickRepository.totalClicksForUserBetween(uid, fourteenDaysAgo, sevenDaysAgo);

        double weeklyGrowth = 0.0;
        if (lastWeekClicks > 0) {
            weeklyGrowth = ((thisWeekClicks - lastWeekClicks) / (double) lastWeekClicks) * 100.0;
            weeklyGrowth = Math.round(weeklyGrowth * 10.0) / 10.0;
        } else if (thisWeekClicks > 0) {
            weeklyGrowth = 100.0;
        }

        return ResponseEntity.ok(UserSummaryDto.builder()
                .totalClicks(totalClicks)
                .activeUrls(activeUrls)
                .weeklyGrowth(weeklyGrowth)
                .build());
    }
}
