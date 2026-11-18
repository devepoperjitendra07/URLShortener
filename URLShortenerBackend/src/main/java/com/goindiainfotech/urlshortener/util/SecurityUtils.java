package com.goindiainfotech.urlshortener.util;

import com.goindiainfotech.urlshortener.entity.User;
import org.springframework.security.core.context.SecurityContextHolder;

public class SecurityUtils {

    public static User currentUser() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof User) {
            return (User) principal;
        }
        throw new IllegalStateException("No authenticated user in context");
    }
}
