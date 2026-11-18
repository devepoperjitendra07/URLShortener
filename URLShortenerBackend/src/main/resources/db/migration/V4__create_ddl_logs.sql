CREATE TABLE ddl_logs (
  id          BIGSERIAL PRIMARY KEY,
  level       VARCHAR(10)  NOT NULL, -- INFO | WARN | ERROR
  tag         VARCHAR(30)  NOT NULL, -- DDL_RESOLVER | SYSTEM | FINGERPRINT
  message     TEXT         NOT NULL,
  device_id   VARCHAR(64),
  session_id  VARCHAR(64),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ddl_time ON ddl_logs(created_at DESC);
