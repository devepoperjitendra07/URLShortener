CREATE TABLE clicks (
  id          BIGSERIAL PRIMARY KEY,
  url_id      UUID        NOT NULL REFERENCES url_mappings(id) ON DELETE CASCADE,
  clicked_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  device_type VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN', -- DESKTOP | IOS | ANDROID
  country     VARCHAR(2),   -- ISO-3166 from IP geo
  referer     TEXT
);

CREATE INDEX idx_clicks_url_time ON clicks(url_id, clicked_at DESC);
CREATE INDEX idx_clicks_time     ON clicks(clicked_at DESC); -- for global stats
