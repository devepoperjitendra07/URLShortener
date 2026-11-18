package com.goindiainfotech.urlshortener.dto.url;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClickEventDto {
    private UUID urlMappingId;
    private OffsetDateTime clickedAt;
    private String deviceType; // String representation of DeviceType enum
    private String country;
    private String referer;
    private String utmSource;
    private String utmMedium;
    private String utmCampaign;
    private String utmTerm;
    private String utmContent;
}
