package com.goindiainfotech.urlshortener.dto.analytics;

import com.goindiainfotech.urlshortener.entity.DeepLinkConfig;
import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class LinkAnalyticsDto {
    private String shortCode;
    private String longUrl;
    private long totalClicks;
    private double weeklyChange;
    private List<DayCount> clicksByDay;
    private List<DeviceCount> deviceDistribution;
    private List<UtmCount> utmDistribution;
    private DeepLinkConfig deepLinkCfg;
}
