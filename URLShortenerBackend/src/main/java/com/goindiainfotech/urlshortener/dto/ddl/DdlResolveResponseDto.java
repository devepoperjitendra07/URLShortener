package com.goindiainfotech.urlshortener.dto.ddl;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DdlResolveResponseDto {
    private boolean enabled;
    private String destination;
    private Map<String, String> params;
    
    // Additional context from the URL mapping
    private String shortCode;
    private String longUrl;

    // UTM Tracking Parameters
    private String utmSource;
    private String utmMedium;
    private String utmCampaign;
    private String utmTerm;
    private String utmContent;
}
