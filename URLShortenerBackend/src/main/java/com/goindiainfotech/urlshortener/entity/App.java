package com.goindiainfotech.urlshortener.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "apps")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class App {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(name = "android_package_name", length = 200)
    private String androidPackageName;

    @Column(name = "sha256_fingerprint", length = 200)
    private String sha256Fingerprint; // For Android assetlinks.json

    @Column(name = "play_store_url", columnDefinition = "TEXT")
    private String playStoreUrl;

    @Column(name = "ios_bundle_id", length = 200)
    private String iosBundleId;

    @Column(name = "apple_team_id", length = 50)
    private String appleTeamId; // For iOS apple-app-site-association

    @Column(name = "app_store_url", columnDefinition = "TEXT")
    private String appStoreUrl;

    @Column(nullable = false, updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
