package com.goindiainfotech.urlshortener.dto.analytics;

public interface UtmCount {
    String getUtmSource();
    String getUtmCampaign();
    long getCount();
}
