package com.goindiainfotech.urlshortener.dto.auth;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class UserDto {
    private UUID id;
    private String name;
    private String email;
}
