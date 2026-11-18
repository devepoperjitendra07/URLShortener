package com.goindiainfotech.urlshortener.entity;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import lombok.extern.slf4j.Slf4j;

@Converter(autoApply = true)
@Slf4j
public class DeepLinkConfigConverter implements AttributeConverter<DeepLinkConfig, String> {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public String convertToDatabaseColumn(DeepLinkConfig attribute) {
        if (attribute == null) return null;
        try {
            return objectMapper.writeValueAsString(attribute);
        } catch (JsonProcessingException e) {
            log.error("[DB] Failed to serialize DeepLinkConfig to JSON string", e);
            return null;
        }
    }

    @Override
    public DeepLinkConfig convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.isEmpty()) return null;
        try {
            return objectMapper.readValue(dbData, DeepLinkConfig.class);
        } catch (JsonProcessingException e) {
            log.error("[DB] Failed to deserialize JSON string to DeepLinkConfig", e);
            return null;
        }
    }
}
