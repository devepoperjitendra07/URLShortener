package com.goindiainfotech.urlshortener.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;

@Entity
@Table(name = "ddl_logs")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DdlLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 10)
    private String level; // INFO | WARN | ERROR

    @Column(nullable = false, length = 30)
    private String tag; // DDL_RESOLVER | SYSTEM | FINGERPRINT

    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    private String deviceId;
    private String sessionId;

    @Column(nullable = false, updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
