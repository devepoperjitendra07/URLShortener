-- Drop legacy sdk_applications table if it exists
DROP TABLE IF EXISTS sdk_applications CASCADE;

-- Create apps table
CREATE TABLE apps (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name                VARCHAR(100) NOT NULL,
  platform            VARCHAR(10) NOT NULL,  -- 'ANDROID' or 'IOS'
  package_name        VARCHAR(200) NOT NULL,
  sha256_fingerprint  VARCHAR(200),          -- Android only
  apple_team_id       VARCHAR(50),           -- iOS only
  store_url           TEXT NOT NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create sdk_keys table
CREATE TABLE sdk_keys (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  app_id          UUID NOT NULL REFERENCES apps(id) ON DELETE CASCADE,
  key_value       VARCHAR(64) NOT NULL UNIQUE,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Modify url_mappings to reference apps table
ALTER TABLE url_mappings ADD COLUMN app_id UUID REFERENCES apps(id) ON DELETE SET NULL;
