package com.goindiainfotech.urlshortener.entity;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeepLinkConfig {
    private boolean enabled;
    private String destination;
    private Map<String, String> params;
}
