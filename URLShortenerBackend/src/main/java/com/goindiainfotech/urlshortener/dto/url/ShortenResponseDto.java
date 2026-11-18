package com.goindiainfotech.urlshortener.dto.url;

import lombok.Builder;
import lombok.Data;

import java.time.OffsetDateTime;

@Data
@Builder
public class ShortenResponseDto {
    private String shortUrl;
    private String longUrl;
    private OffsetDateTime createdAt;
    private String status;
}
