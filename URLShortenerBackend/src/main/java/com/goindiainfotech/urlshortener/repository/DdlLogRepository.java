package com.goindiainfotech.urlshortener.repository;

import com.goindiainfotech.urlshortener.entity.DdlLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DdlLogRepository extends JpaRepository<DdlLog, Long> {
    Page<DdlLog> findAllByOrderByCreatedAtDesc(Pageable pageable);
}
