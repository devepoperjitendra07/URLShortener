package com.goindiainfotech.urlshortener.dto.url;

import com.goindiainfotech.urlshortener.entity.DeepLinkConfig;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import org.hibernate.validator.constraints.URL;

import java.time.OffsetDateTime;

@Data
public class ShortenRequestDto {
    @NotBlank(message = "Destination URL cannot be empty")
    @URL(message = "Invalid destination URL format")
    private String longUrl;

    private String customSlug;
    private String packageName;
    private OffsetDateTime expiryDate;
    private DeepLinkConfig deepLinkCfg;
}
