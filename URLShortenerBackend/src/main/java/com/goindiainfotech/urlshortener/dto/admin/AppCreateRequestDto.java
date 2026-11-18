package com.goindiainfotech.urlshortener.dto.admin;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AppCreateRequestDto {

    @NotBlank(message = "App name is required")
    private String name;

    private String androidPackageName;
    private String sha256Fingerprint;
    private String playStoreUrl;

    private String iosBundleId;
    private String appleTeamId;
    private String appStoreUrl;
}
