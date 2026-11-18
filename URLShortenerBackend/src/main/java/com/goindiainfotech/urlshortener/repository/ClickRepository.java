package com.goindiainfotech.urlshortener.repository;

import com.goindiainfotech.urlshortener.dto.analytics.DayCount;
import com.goindiainfotech.urlshortener.dto.analytics.DeviceCount;
import com.goindiainfotech.urlshortener.entity.Click;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public interface ClickRepository extends JpaRepository<Click, Long> {

    long countByUrlMappingId(UUID urlId);

    @Query("SELECT DATE(c.clickedAt) as day, COUNT(c) as count "
         + "FROM Click c WHERE c.urlMapping.id = :id "
         + "AND c.clickedAt >= :since GROUP BY DATE(c.clickedAt) ORDER BY day")
    List<DayCount> clicksByDay(@Param("id") UUID id, @Param("since") OffsetDateTime since);

    @Query("SELECT c.deviceType as deviceType, COUNT(c) as count "
         + "FROM Click c WHERE c.urlMapping.id = :id GROUP BY c.deviceType")
    List<DeviceCount> deviceDistribution(@Param("id") UUID id);

    @Query("SELECT COUNT(c) FROM Click c WHERE c.urlMapping.id = :id "
         + "AND c.clickedAt BETWEEN :from AND :to")
    long countBetween(@Param("id") UUID id, @Param("from") OffsetDateTime from, @Param("to") OffsetDateTime to);

    @Query("SELECT COUNT(c) FROM Click c WHERE c.urlMapping.user.id = :uid")
    long totalClicksForUser(@Param("uid") UUID userId);

    @Query("SELECT COUNT(c) FROM Click c WHERE c.urlMapping.user.id = :uid "
         + "AND c.clickedAt BETWEEN :from AND :to")
    long totalClicksForUserBetween(@Param("uid") UUID userId, @Param("from") OffsetDateTime from, @Param("to") OffsetDateTime to);

    @Query("SELECT c.utmSource as utmSource, c.utmCampaign as utmCampaign, COUNT(c) as count "
         + "FROM Click c WHERE c.urlMapping.id = :id AND c.utmSource IS NOT NULL "
         + "GROUP BY c.utmSource, c.utmCampaign ORDER BY count DESC")
    List<com.goindiainfotech.urlshortener.dto.analytics.UtmCount> utmDistribution(@Param("id") UUID id);
}
