package com.goindiainfotech.urlshortener.repository;

import com.goindiainfotech.urlshortener.entity.App;
import com.goindiainfotech.urlshortener.entity.LinkStatus;
import com.goindiainfotech.urlshortener.entity.UrlMapping;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UrlMappingRepository extends JpaRepository<UrlMapping, UUID> {

    Optional<UrlMapping> findByShortCode(String shortCode);

    boolean existsByShortCode(String shortCode);

    Page<UrlMapping> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);

    List<UrlMapping> findByAppIdOrderByCreatedAtDesc(UUID appId);

    List<UrlMapping> findByAppInOrderByCreatedAtDesc(List<App> apps);

    long countByUserIdAndStatus(UUID userId, LinkStatus status);

    List<UrlMapping> findByStatus(LinkStatus status);

    @Modifying
    @Query("UPDATE UrlMapping u SET u.status = 'EXPIRED' WHERE u.expiryDate < CURRENT_TIMESTAMP AND u.status = 'ACTIVE'")
    int markExpiredLinks();

    @Modifying
    @Query("UPDATE UrlMapping u SET u.clickCount = u.clickCount + :count WHERE u.id = :id")
    void incrementClickCount(@Param("id") UUID id, @Param("count") Long count);

    @Query("SELECT u.shortCode FROM UrlMapping u")
    List<String> findAllShortCodes();
}
