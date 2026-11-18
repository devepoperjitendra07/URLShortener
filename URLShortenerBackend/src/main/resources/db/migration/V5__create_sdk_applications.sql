CREATE TABLE sdk_applications (
    id UUID PRIMARY KEY,
    sdk_key VARCHAR(128) NOT NULL UNIQUE,
    app_name VARCHAR(100) NOT NULL,
    user_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sdk_app_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX idx_sdk_applications_key ON sdk_applications(sdk_key);
