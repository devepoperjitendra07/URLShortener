package com.goindiainfotech.urlshortener.dto.ddl;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class DdlRegisterDto {
    @NotBlank
    private String fingerprint;

    @NotBlank
    private String shortCode;

    @NotBlank
    private String sessionId;

    private String utmSource;
    private String utmMedium;
    private String utmCampaign;
    private String utmTerm;
    private String utmContent;
}
