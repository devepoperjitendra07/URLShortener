package com.goindiainfotech.urlshortener.controller;

import com.goindiainfotech.urlshortener.dto.auth.AuthResponseDto;
import com.goindiainfotech.urlshortener.dto.auth.LoginRequestDto;
import com.goindiainfotech.urlshortener.dto.auth.SignupRequestDto;
import com.goindiainfotech.urlshortener.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {

    private final AuthService authService;

    @PostMapping("/signup")
    public ResponseEntity<AuthResponseDto> signup(@RequestBody @Valid SignupRequestDto dto) {
        log.info("[AUTH] Signup attempt for email: {}", dto.getEmail());
        return ResponseEntity.ok(authService.signup(dto));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponseDto> login(@RequestBody @Valid LoginRequestDto dto) {
        log.info("[AUTH] Login attempt for email: {}", dto.getEmail());
        return ResponseEntity.ok(authService.login(dto));
    }
}
