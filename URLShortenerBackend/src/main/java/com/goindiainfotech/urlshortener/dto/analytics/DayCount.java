package com.goindiainfotech.urlshortener.dto.analytics;

import java.sql.Date;

public interface DayCount {
    Date getDay();
    long getCount();
}
