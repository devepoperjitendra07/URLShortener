package com.goindiainfotech.urlshortener.service;

import com.goindiainfotech.urlshortener.entity.UrlMapping;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;

public interface RedirectionService {
    ResponseEntity<?> buildRedirect(UrlMapping mapping, HttpServletRequest request);
}
