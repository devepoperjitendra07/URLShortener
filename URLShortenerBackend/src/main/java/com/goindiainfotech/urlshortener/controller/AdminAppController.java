package com.goindiainfotech.urlshortener.controller;

import com.goindiainfotech.urlshortener.dto.admin.AppCreateRequestDto;
import com.goindiainfotech.urlshortener.dto.admin.AppResponseDto;
import com.goindiainfotech.urlshortener.entity.App;
import com.goindiainfotech.urlshortener.entity.SdkKey;
import com.goindiainfotech.urlshortener.entity.User;
import com.goindiainfotech.urlshortener.exception.ConflictException;
import com.goindiainfotech.urlshortener.exception.ResourceNotFoundException;
import com.goindiainfotech.urlshortener.repository.AppRepository;
import com.goindiainfotech.urlshortener.repository.SdkKeyRepository;
import com.goindiainfotech.urlshortener.util.SecurityUtils;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/apps")
@RequiredArgsConstructor
@Slf4j
public class AdminAppController {

    private final AppRepository appRepository;
    private final SdkKeyRepository sdkKeyRepository;

    @PostMapping
    @Transactional
    public ResponseEntity<AppResponseDto> registerApp(@RequestBody @Valid AppCreateRequestDto dto) {
        User user = SecurityUtils.currentUser();

        App app = App.builder()
                .user(user)
                .name(dto.getName())
                .androidPackageName(dto.getAndroidPackageName())
                .sha256Fingerprint(dto.getSha256Fingerprint() != null ? dto.getSha256Fingerprint().trim() : null)
                .playStoreUrl(dto.getPlayStoreUrl())
                .iosBundleId(dto.getIosBundleId())
                .appleTeamId(dto.getAppleTeamId() != null ? dto.getAppleTeamId().trim() : null)
                .appStoreUrl(dto.getAppStoreUrl())
                .build();

        App savedApp = appRepository.save(app);

        // Generate initial active SDK Key
        String keyValue = generateSdkKey();
        SdkKey sdkKey = SdkKey.builder()
                .app(savedApp)
                .keyValue(keyValue)
                .isActive(true)
                .build();

        sdkKeyRepository.save(sdkKey);
        log.info("[ADMIN] Registered app={} with sdkKey={}", savedApp.getName(), keyValue);

        return ResponseEntity.status(HttpStatus.CREATED).body(mapToResponseDto(savedApp, keyValue));
    }

    @GetMapping
    public ResponseEntity<List<AppResponseDto>> listApps() {
        User user = SecurityUtils.currentUser();
        List<App> apps = appRepository.findByUserId(user.getId());

        List<AppResponseDto> response = apps.stream().map(app -> {
            String activeKey = sdkKeyRepository.findByAppIdAndIsActiveTrue(app.getId())
                    .map(SdkKey::getKeyValue)
                    .orElse("N/A");
            return mapToResponseDto(app, activeKey);
        }).collect(Collectors.toList());

        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    @Transactional
    public ResponseEntity<AppResponseDto> updateApp(@PathVariable UUID id, @RequestBody @Valid AppCreateRequestDto dto) {
        User user = SecurityUtils.currentUser();
        App app = appRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Application not found"));

        if (!app.getUser().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
        }

        app.setName(dto.getName());
        app.setAndroidPackageName(dto.getAndroidPackageName());
        app.setSha256Fingerprint(dto.getSha256Fingerprint() != null ? dto.getSha256Fingerprint().trim() : null);
        app.setPlayStoreUrl(dto.getPlayStoreUrl());
        app.setIosBundleId(dto.getIosBundleId());
        app.setAppleTeamId(dto.getAppleTeamId() != null ? dto.getAppleTeamId().trim() : null);
        app.setAppStoreUrl(dto.getAppStoreUrl());

        App updatedApp = appRepository.save(app);

        String activeKey = sdkKeyRepository.findByAppIdAndIsActiveTrue(app.getId())
                .map(SdkKey::getKeyValue)
                .orElse("N/A");

        log.info("[ADMIN] Updated app={}", updatedApp.getName());
        return ResponseEntity.ok(mapToResponseDto(updatedApp, activeKey));
    }

    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<Void> deleteApp(@PathVariable UUID id) {
        User user = SecurityUtils.currentUser();
        App app = appRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Application not found"));

        if (!app.getUser().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
        }

        appRepository.delete(app);
        log.info("[ADMIN] Deleted app={}", app.getName());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{appId}/keys/regenerate")
    @Transactional
    public ResponseEntity<AppResponseDto> regenerateKey(@PathVariable UUID appId) {
        User user = SecurityUtils.currentUser();
        App app = appRepository.findById(appId)
                .orElseThrow(() -> new ResourceNotFoundException("Application not found"));

        if (!app.getUser().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
        }

        // Deactivate old keys
        sdkKeyRepository.findByAppIdAndIsActiveTrue(app.getId()).ifPresent(oldKey -> {
            oldKey.setActive(false);
            sdkKeyRepository.save(oldKey);
        });

        // Generate new key
        String newKeyValue = generateSdkKey();
        SdkKey newKey = SdkKey.builder()
                .app(app)
                .keyValue(newKeyValue)
                .isActive(true)
                .build();

        sdkKeyRepository.save(newKey);
        log.info("[ADMIN] Regenerated SDK key for app={}. New key={}", app.getName(), newKeyValue);

        return ResponseEntity.ok(mapToResponseDto(app, newKeyValue));
    }

    @GetMapping("/{appId}/keys")
    public ResponseEntity<String> getActiveKey(@PathVariable UUID appId) {
        User user = SecurityUtils.currentUser();
        App app = appRepository.findById(appId)
                .orElseThrow(() -> new ResourceNotFoundException("Application not found"));

        if (!app.getUser().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");
        }

        String activeKey = sdkKeyRepository.findByAppIdAndIsActiveTrue(app.getId())
                .map(SdkKey::getKeyValue)
                .orElseThrow(() -> new ResourceNotFoundException("No active SDK key found for this app"));

        return ResponseEntity.ok(activeKey);
    }

    private String generateSdkKey() {
        return "git_live_" + UUID.randomUUID().toString().replace("-", "").substring(0, 16);
    }

    private AppResponseDto mapToResponseDto(App app, String sdkKey) {
        return AppResponseDto.builder()
                .id(app.getId())
                .name(app.getName())
                .androidPackageName(app.getAndroidPackageName())
                .sha256Fingerprint(app.getSha256Fingerprint())
                .playStoreUrl(app.getPlayStoreUrl())
                .iosBundleId(app.getIosBundleId())
                .appleTeamId(app.getAppleTeamId())
                .appStoreUrl(app.getAppStoreUrl())
                .sdkKey(sdkKey)
                .createdAt(app.getCreatedAt())
                .build();
    }
}
