package com.goindiainfotech.urlshortener.dto.ddl;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class DdlResolveReferrerDto {
    @NotBlank
    private String sessionId;
}
