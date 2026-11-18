package com.goindiainfotech.urlshortener.repository;

import com.goindiainfotech.urlshortener.entity.SdkKey;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

public interface SdkKeyRepository extends JpaRepository<SdkKey, UUID> {
    Optional<SdkKey> findByKeyValueAndIsActiveTrue(String keyValue);
    Optional<SdkKey> findByAppIdAndIsActiveTrue(UUID appId);
}
