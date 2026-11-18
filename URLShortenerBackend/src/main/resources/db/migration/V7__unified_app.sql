ALTER TABLE apps DROP COLUMN IF EXISTS platform;
ALTER TABLE apps RENAME COLUMN package_name TO android_package_name;
ALTER TABLE apps RENAME COLUMN store_url TO play_store_url;

ALTER TABLE apps ADD COLUMN ios_bundle_id VARCHAR(255);
ALTER TABLE apps ADD COLUMN app_store_url VARCHAR(255);
