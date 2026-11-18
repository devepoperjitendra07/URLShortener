package com.goindiainfotech.urlshortener.service.impl;

import com.goindiainfotech.urlshortener.dto.auth.AuthResponseDto;
import com.goindiainfotech.urlshortener.dto.auth.LoginRequestDto;
import com.goindiainfotech.urlshortener.dto.auth.SignupRequestDto;
import com.goindiainfotech.urlshortener.dto.auth.UserDto;
import com.goindiainfotech.urlshortener.entity.User;
import com.goindiainfotech.urlshortener.repository.UserRepository;
import com.goindiainfotech.urlshortener.security.JwtService;
import com.goindiainfotech.urlshortener.service.AuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Override
    @Transactional
    public AuthResponseDto signup(SignupRequestDto request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Email already registered: " + request.getEmail());
        }

        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .build();

        User savedUser = userRepository.save(user);
        log.info("[AUTH] User registered: {} ({})", savedUser.getName(), savedUser.getId());
        return buildResponse(savedUser);
    }

    @Override
    public AuthResponseDto login(LoginRequestDto request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("Invalid email or password");
        }

        log.info("[AUTH] User login successful: {}", user.getEmail());
        return buildResponse(user);
    }

    private AuthResponseDto buildResponse(User user) {
        String token = jwtService.generateToken(user);
        UserDto userDto = UserDto.builder()
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .build();

        return AuthResponseDto.builder()
                .token(token)
                .user(userDto)
                .build();
    }
}
