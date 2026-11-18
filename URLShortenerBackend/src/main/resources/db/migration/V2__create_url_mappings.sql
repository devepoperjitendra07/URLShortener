CREATE TABLE url_mappings (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  short_code    VARCHAR(20)  NOT NULL UNIQUE,
  long_url      TEXT         NOT NULL,
  user_id       UUID         REFERENCES users(id) ON DELETE CASCADE,
  status        VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE', -- ACTIVE | BROKEN | EXPIRED
  click_count   BIGINT       NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  expiry_date   TIMESTAMPTZ,
  deep_link_cfg JSONB        -- {enabled, destination, params}
);

CREATE INDEX idx_url_user     ON url_mappings(user_id, created_at DESC);
CREATE INDEX idx_url_status   ON url_mappings(status);
CREATE INDEX idx_url_expiry   ON url_mappings(expiry_date) WHERE expiry_date IS NOT NULL;
