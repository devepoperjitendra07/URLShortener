package com.goindiainfotech.urlshortener.dto.admin;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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
public class AdminShortenRequestDto {

    @NotNull(message = "Target App ID is required")
    private UUID appId;

    @NotBlank(message = "Link name is required")
    private String name;

    private String customSlug; // Optional slug

    @NotBlank(message = "In-App Destination URI is required")
    private String destinationUri; // e.g. app://store/product?id=442

    private OffsetDateTime expiryDate; // Optional
}
