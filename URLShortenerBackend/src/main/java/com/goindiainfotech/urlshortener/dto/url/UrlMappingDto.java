package com.goindiainfotech.urlshortener.dto.url;

import com.goindiainfotech.urlshortener.entity.DeepLinkConfig;
import com.goindiainfotech.urlshortener.entity.LinkStatus;
import lombok.Builder;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
public class UrlMappingDto {
    private UUID id;
    private String shortCode;
    private String longUrl;
    private LinkStatus status;
    private long clickCount;
    private OffsetDateTime createdAt;
    private OffsetDateTime expiryDate;
    private DeepLinkConfig deepLinkCfg;
}
