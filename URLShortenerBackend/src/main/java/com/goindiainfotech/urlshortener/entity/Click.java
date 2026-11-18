package com.goindiainfotech.urlshortener.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;

@Entity
@Table(name = "clicks")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Click {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "url_id", nullable = false)
    private UrlMapping urlMapping;

    @Column(nullable = false)
    @Builder.Default
    private OffsetDateTime clickedAt = OffsetDateTime.now();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private DeviceType deviceType = DeviceType.UNKNOWN;

    @Column(length = 2)
    private String country; // ISO-3166

    @Column(columnDefinition = "TEXT")
    private String referer;

    @Column(length = 255)
    private String utmSource;

    @Column(length = 255)
    private String utmMedium;

    @Column(length = 255)
    private String utmCampaign;

    @Column(length = 255)
    private String utmTerm;

    @Column(length = 255)
    private String utmContent;
}
