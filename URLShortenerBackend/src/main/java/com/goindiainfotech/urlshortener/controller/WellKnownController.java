package com.goindiainfotech.urlshortener.controller;

import com.goindiainfotech.urlshortener.entity.App;
import com.goindiainfotech.urlshortener.repository.AppRepository;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequiredArgsConstructor
public class WellKnownController {

    private final AppRepository appRepository;

    @Data
    @Builder
    public static class AssetLinkTarget {
        private String namespace;
        private String package_name;
        private List<String> sha256_cert_fingerprints;
    }

    @Data
    @Builder
    public static class AssetLink {
        private List<String> relation;
        private AssetLinkTarget target;
    }

    @GetMapping(value = "/.well-known/assetlinks.json", produces = MediaType.APPLICATION_JSON_VALUE)
    public List<AssetLink> getAssetLinks() {
        List<App> androidApps = appRepository.findAll().stream()
                .filter(app -> app.getAndroidPackageName() != null && !app.getAndroidPackageName().isEmpty())
                .collect(Collectors.toList());

        List<AssetLink> result = new ArrayList<>();

        for (App app : androidApps) {
            List<String> fingerprints = new ArrayList<>();
            if (app.getSha256Fingerprint() != null && !app.getSha256Fingerprint().isEmpty()) {
                // If stored with colons or spaces, keep it. Some might register as a clean comma-separated or list
                fingerprints.add(app.getSha256Fingerprint());
            }

            result.add(AssetLink.builder()
                    .relation(List.of("delegate_permission/common.handle_all_urls"))
                    .target(AssetLinkTarget.builder()
                            .namespace("android_app")
                            .package_name(app.getAndroidPackageName())
                            .sha256_cert_fingerprints(fingerprints)
                            .build())
                    .build());
        }

        return result;
    }

    @GetMapping(value = "/.well-known/apple-app-site-association", produces = MediaType.APPLICATION_JSON_VALUE)
    public Map<String, Object> getAppleAppSiteAssociation() {
        List<App> iosApps = appRepository.findAll().stream()
                .filter(app -> app.getIosBundleId() != null && !app.getIosBundleId().isEmpty())
                .collect(Collectors.toList());

        List<Map<String, Object>> details = new ArrayList<>();

        for (App app : iosApps) {
            if (app.getAppleTeamId() != null && !app.getAppleTeamId().isEmpty()) {
                Map<String, Object> detail = new HashMap<>();
                detail.put("appID", app.getAppleTeamId() + "." + app.getIosBundleId());
                detail.put("paths", List.of("/r/*"));
                details.add(detail);
            }
        }

        Map<String, Object> applinks = new HashMap<>();
        applinks.put("apps", List.of());
        applinks.put("details", details);

        Map<String, Object> result = new HashMap<>();
        result.put("applinks", applinks);

        return result;
    }
}
