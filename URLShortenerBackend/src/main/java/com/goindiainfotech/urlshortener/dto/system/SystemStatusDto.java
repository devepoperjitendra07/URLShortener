package com.goindiainfotech.urlshortener.dto.system;

import lombok.Builder;
import lombok.Data;

import java.util.Map;

@Data
@Builder
public class SystemStatusDto {
    private String version;
    private long latencyMs;
    private double hitRate;
    private String memoryUsage;
    private int activeConnections;
    private Map<String, Boolean> verifications; // ios, android, customScheme
}
