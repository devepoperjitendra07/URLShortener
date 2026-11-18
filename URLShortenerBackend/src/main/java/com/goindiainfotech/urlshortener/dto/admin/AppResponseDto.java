package com.goindiainfotech.urlshortener.dto.admin;

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
public class AppResponseDto {
    private UUID id;
    private String name;
    private String androidPackageName;
    private String sha256Fingerprint;
    private String playStoreUrl;
    private String iosBundleId;
    private String appleTeamId;
    private String appStoreUrl;
    private String sdkKey;
    private OffsetDateTime createdAt;
}
