package com.goindiainfotech.urlshortener.dto.analytics;

import com.goindiainfotech.urlshortener.entity.DeviceType;

public interface DeviceCount {
    DeviceType getDeviceType();
    long getCount();
}
