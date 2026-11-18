package com.goindiainfotech.urlshortener.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.Map;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminShortenResponseDto {
    private UUID id;
    private String shortUrl;
    private String longUrl;
    private String shortCode;
    private String name;
    private String targetAppName;
    private UUID targetAppId;
    private String targetAppPackageName;
    private String destinationUri;
    private Map<String, String> params;
    private long clickCount;
    private String status;
    private OffsetDateTime expiryDate;
    private OffsetDateTime createdAt;
}
