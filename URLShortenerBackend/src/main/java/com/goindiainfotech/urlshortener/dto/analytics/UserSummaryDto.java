package com.goindiainfotech.urlshortener.dto.analytics;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UserSummaryDto {
    private long totalClicks;
    private long activeUrls;
    private double weeklyGrowth;
}
