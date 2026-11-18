package com.goindiainfotech.urlshortener.service.impl;

import com.goindiainfotech.urlshortener.entity.DdlLog;
import com.goindiainfotech.urlshortener.entity.UrlMapping;
import com.goindiainfotech.urlshortener.repository.DdlLogRepository;
import com.goindiainfotech.urlshortener.service.RedirectionService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.time.OffsetDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class RedirectionServiceImpl implements RedirectionService {

    private final DdlLogRepository ddlLogRepository;

    @Override
    public ResponseEntity<?> buildRedirect(UrlMapping mapping, HttpServletRequest request) {
        String userAgent = request.getHeader("User-Agent");
        boolean isMobile = detectMobile(userAgent);

        if (isMobile && mapping.getDeepLinkCfg() != null && mapping.getDeepLinkCfg().isEnabled()) {
            String sessionId = UUID.randomUUID().toString();
            log.info("[RTC] Deep link redirect active. Serving DDL setup page for shortCode={}, sessionId={}",
                    mapping.getShortCode(), sessionId);

            ddlLogRepository.save(DdlLog.builder()
                    .level("INFO")
                    .tag("DDL_RESOLVER")
                    .message("Serving deep link landing page for path /r/" + mapping.getShortCode())
                    .sessionId(sessionId)
                    .createdAt(OffsetDateTime.now())
                    .build());

            String utmSource = request.getParameter("utm_source");
            String utmMedium = request.getParameter("utm_medium");
            String utmCampaign = request.getParameter("utm_campaign");
            String utmTerm = request.getParameter("utm_term");
            String utmContent = request.getParameter("utm_content");

            String html = getDdlHtml(mapping.getShortCode(), sessionId, mapping.getApp(), utmSource, utmMedium, utmCampaign, utmTerm, utmContent);
            return ResponseEntity.ok()
                    .contentType(MediaType.TEXT_HTML)
                    .body(html);
        }

        // Direct 302 Redirect
        log.info("[RTC] Redirecting to longUrl={}", mapping.getLongUrl());
        HttpHeaders headers = new HttpHeaders();
        headers.setLocation(URI.create(mapping.getLongUrl()));
        return new ResponseEntity<>(headers, HttpStatus.FOUND);
    }

    private boolean detectMobile(String ua) {
        if (ua == null) return false;
        return ua.contains("Android") || ua.contains("iPhone") || ua.contains("iPad") || ua.contains("Mobile");
    }

    private String getDdlHtml(String shortCode, String sessionId, com.goindiainfotech.urlshortener.entity.App app,
                              String utmSource, String utmMedium, String utmCampaign, String utmTerm, String utmContent) {
        if (app == null) {
            return """
            <!DOCTYPE html>
            <html>
            <head>
                <title>App Not Found</title>
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        background-color: #0b0f19;
                        color: #ffffff;
                        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        height: 100vh;
                        margin: 0;
                        overflow: hidden;
                    }
                    .container {
                        text-align: center;
                        max-width: 90%%;
                    }
                    h2 {
                        font-size: 24px;
                        font-weight: 600;
                        margin-bottom: 8px;
                        color: #ef4444;
                    }
                    p {
                        color: #9ca3af;
                        font-size: 16px;
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <h2>App Not Found</h2>
                    <p>The application for this link could not be found or has been disabled.</p>
                </div>
            </body>
            </html>
            """;
        }

        String androidPackage = "com.example.app";
        String androidStoreUrl = "https://play.google.com/store/apps";
        String iosStoreUrl = "https://apps.apple.com/";

        if (app.getAndroidPackageName() != null && !app.getAndroidPackageName().isEmpty()) {
                androidPackage = app.getAndroidPackageName();
                androidStoreUrl = app.getPlayStoreUrl() != null ? app.getPlayStoreUrl() : androidStoreUrl;
            }
            if (app.getAppStoreUrl() != null && !app.getAppStoreUrl().isEmpty()) {
                iosStoreUrl = app.getAppStoreUrl();
            }
        // URL encoded referrer parameter for Android
        String playStoreFallback = "https://play.google.com/store/apps/details?id=" + androidPackage + "&referrer=click_token%3D" + sessionId;
        if (app.getPlayStoreUrl() != null && !app.getPlayStoreUrl().isEmpty()) {
            // Use custom store URL if present, but append referrer if it's a Play Store link
            if (androidStoreUrl.contains("play.google.com")) {
                androidStoreUrl = androidStoreUrl + (androidStoreUrl.contains("?") ? "&" : "?") + "referrer=click_token%3D" + sessionId;
            }
            playStoreFallback = androidStoreUrl;
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Redirecting...</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    background-color: #0b0f19;
                    color: #ffffff;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    height: 100vh;
                    margin: 0;
                    overflow: hidden;
                }
                .container {
                    text-align: center;
                    max-width: 90%%;
                }
                .loader {
                    border: 4px solid rgba(255, 255, 255, 0.1);
                    width: 48px;
                    height: 48px;
                    border-radius: 50%%;
                    border-left-color: #6366f1;
                    animation: spin 1s linear infinite;
                    margin: 0 auto 20px;
                }
                h2 {
                    font-size: 20px;
                    font-weight: 600;
                    margin-bottom: 8px;
                }
                p {
                    color: #9ca3af;
                    font-size: 14px;
                }
                @keyframes spin {
                    0%% { transform: rotate(0deg); }
                    100%% { transform: rotate(360deg); }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="loader"></div>
                <h2>Routing to App...</h2>
                <p>If you are not redirected automatically, please click below.</p>
                <button id="openAppBtn" 
                        style="padding: 12px 24px; font-size: 16px; background-color: #007bff; color: white; border: none; border-radius: 8px; cursor: pointer; margin-top: 15px;">
                    Open App
                </button>
            </div>
            <script>
                function sha256Pure(ascii) {
                    function rightRotate(value, amount) {
                        return (value >>> amount) | (value << (32 - amount));
                    }
                    var mathPow = Math.pow;
                    var maxWord = mathPow(2, 32);
                    var lengthProperty = 'length';
                    var i, j;
                    var result = '';
                    var words = [];
                    var asciiLength = ascii[lengthProperty] * 8;
                    var hash = sha256Pure.h = sha256Pure.h || [];
                    var k = sha256Pure.k = sha256Pure.k || [];
                    var primeCounter = k[lengthProperty];
                    var isComposite = {};
                    for (var candidate = 2; primeCounter < 64; candidate++) {
                        if (!isComposite[candidate]) {
                            for (i = 0; i < 313; i += candidate) {
                                isComposite[i] = 1;
                            }
                            hash[primeCounter] = (mathPow(candidate, .5) * maxWord) | 0;
                            k[primeCounter++] = (mathPow(candidate, 1 / 3) * maxWord) | 0;
                        }
                    }
                    ascii += '\\x80';
                    while (ascii[lengthProperty] %% 64 - 56) ascii += '\\x00';
                    for (i = 0; i < ascii[lengthProperty]; i++) {
                        j = ascii.charCodeAt(i);
                        if (j >> 8) return;
                        words[i >> 2] |= j << ((3 - i) %% 4 * 8);
                    }
                    words[words[lengthProperty]] = ((asciiLength / maxWord) | 0);
                    words[words[lengthProperty]] = (asciiLength | 0);
                    var h = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
                    for (j = 0; j < words[lengthProperty]; j += 16) {
                        var w = words.slice(j, j + 16);
                        var oldHash = h.slice(0);
                        for (i = 0; i < 64; i++) {
                            var w15 = w[i - 15], w2 = w[i - 2];
                            var s0 = rightRotate(w15, 7) ^ rightRotate(w15, 18) ^ (w15 >>> 3);
                            var s1 = rightRotate(w2, 17) ^ rightRotate(w2, 19) ^ (w2 >>> 10);
                            var ch = (h[4] & h[5]) ^ (~h[4] & h[6]);
                            var maj = (h[0] & h[1]) ^ (h[0] & h[2]) ^ (h[1] & h[2]);
                            var temp1 = h[7] + (rightRotate(h[4], 6) ^ rightRotate(h[4], 11) ^ rightRotate(h[4], 25)) + ch + k[i] + (w[i] = (i < 16 ? w[i] : (w[i - 16] + s0 + w[i - 7] + s1) | 0));
                            var temp2 = (rightRotate(h[0], 2) ^ rightRotate(h[0], 13) ^ rightRotate(h[0], 22)) + maj;
                            h = [(temp1 + temp2) | 0].concat(h);
                            h[4] = (h[4] + temp1) | 0;
                            h.length = 8;
                        }
                        for (i = 0; i < 8; i++) h[i] = (h[i] + oldHash[i]) | 0;
                    }
                    for (i = 0; i < 8; i++) {
                        var hex = (h[i] >>> 0).toString(16);
                        result += ('00000000' + hex).slice(-8);
                    }
                    return result;
                }

                async function sha256(message) {
                    try {
                        if (window.crypto && crypto.subtle) {
                            const msgBuffer = new TextEncoder().encode(message);
                            const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
                            const hashArray = Array.from(new Uint8Array(hashBuffer));
                            return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
                        }
                    } catch (e) {
                        console.warn('Crypto subtle failed, fallback:', e);
                    }
                    return sha256Pure(message);
                }

                async function tryOpenApp() {
                    const isIos = /iPhone|iPad|iPod/i.test(navigator.userAgent);
                    const platform = isIos ? 'iOS' : 'Android';
                    
                    const timezoneOffset = new Date().getTimezoneOffset();
                    const langBase = (navigator.language || 'en').split('-')[0].split('_')[0];
                    const fingerprintRaw = timezoneOffset + '|' + langBase + '|' + platform;
                    const fingerprint = await sha256(fingerprintRaw);
                    
                    try {
                        await fetch('/api/ddl/register', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({
                                fingerprint: fingerprint,
                                shortCode: '%s',
                                sessionId: '%s',
                                utmSource: %s,
                                utmMedium: %s,
                                utmCampaign: %s,
                                utmTerm: %s,
                                utmContent: %s
                            })
                        });
                    } catch (e) {
                        console.error('Registration failed:', e);
                    }

                    const playStoreFallback = encodeURIComponent('%s');
                    
                    const targetStore = isIos 
                        ? '%s' 
                        : 'intent://' + window.location.host + '/r/%s#Intent;scheme=http;package=%s;S.browser_fallback_url=' + playStoreFallback + ';end';
                    
                    var start = Date.now();
                    window.location.href = targetStore;
                    
                    setTimeout(function() {
                        var elapsed = Date.now() - start;
                        if (elapsed < 1500 && !document.hidden) {
                            alert("App not installed, or browser blocked the navigation to open the app");
                        }
                    }, 1000);
                }
                
                document.getElementById('openAppBtn').addEventListener('click', tryOpenApp);
                window.onload = function() {
                    setTimeout(tryOpenApp, 300);
                };
                
            </script>
        </body>
        </html>
        """.formatted(shortCode, sessionId, 
                      utmSource != null ? "'" + utmSource.replace("'", "\\'") + "'" : "null",
                      utmMedium != null ? "'" + utmMedium.replace("'", "\\'") + "'" : "null",
                      utmCampaign != null ? "'" + utmCampaign.replace("'", "\\'") + "'" : "null",
                      utmTerm != null ? "'" + utmTerm.replace("'", "\\'") + "'" : "null",
                      utmContent != null ? "'" + utmContent.replace("'", "\\'") + "'" : "null",
                      playStoreFallback, iosStoreUrl, shortCode, androidPackage);
    }
}
