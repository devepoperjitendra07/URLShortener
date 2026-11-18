package com.goindiainfotech.urlshortener.service;

import com.goindiainfotech.urlshortener.dto.auth.AuthResponseDto;
import com.goindiainfotech.urlshortener.dto.auth.LoginRequestDto;
import com.goindiainfotech.urlshortener.dto.auth.SignupRequestDto;

public interface AuthService {
    AuthResponseDto signup(SignupRequestDto request);
    AuthResponseDto login(LoginRequestDto request);
}
