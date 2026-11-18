package com.goindiainfotech.urlshortener.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.goindiainfotech.urlshortener.repository.SdkKeyRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Component
@RequiredArgsConstructor
@Slf4j
public class SdkAuthFilter extends OncePerRequestFilter {

    private final SdkKeyRepository sdkKeyRepository;
    private final ObjectMapper objectMapper;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String path = request.getRequestURI();
        
        // Only intercept /api/ddl/resolve and /api/ddl/resolve-referrer (or exact match starting with /api/ddl/resolve)
        // Note: the servlet context path is /api, so the URI is /api/ddl/resolve
        if (path.startsWith("/api/ddl/resolve")) {
            String sdkKey = request.getHeader("X-SDK-Key");

            if (sdkKey == null || sdkKey.trim().isEmpty()) {
                log.warn("[SDK_AUTH] Missing X-SDK-Key header for path={}", path);
                sendUnauthorized(response, "Missing X-SDK-Key header");
                return;
            }

            boolean isValid = sdkKeyRepository.findByKeyValueAndIsActiveTrue(sdkKey).isPresent();
            if (!isValid) {
                log.warn("[SDK_AUTH] Invalid X-SDK-Key provided for path={}", path);
                sendUnauthorized(response, "Invalid SDK Key");
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    private void sendUnauthorized(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpStatus.UNAUTHORIZED.value());
        response.setContentType("application/json");

        Map<String, Object> body = new HashMap<>();
        body.put("timestamp", LocalDateTime.now().toString());
        body.put("status", HttpStatus.UNAUTHORIZED.value());
        body.put("error", "Unauthorized");
        body.put("message", message);

        response.getWriter().write(objectMapper.writeValueAsString(body));
        response.getWriter().flush();
    }
}
