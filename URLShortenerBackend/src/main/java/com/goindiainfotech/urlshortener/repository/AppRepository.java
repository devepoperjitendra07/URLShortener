package com.goindiainfotech.urlshortener.repository;

import com.goindiainfotech.urlshortener.entity.App;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AppRepository extends JpaRepository<App, UUID> {
    List<App> findByUserId(UUID userId);
    List<App> findByAndroidPackageNameAndUserId(String packageName, UUID userId);
    List<App> findByIosBundleIdAndUserId(String bundleId, UUID userId);
}
