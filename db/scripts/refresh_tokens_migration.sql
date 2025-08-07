-- Migration script to add RefreshTokens table for secure session management
-- This table stores refresh tokens for the JWT authentication system
-- Execute this script on your PostgreSQL database

-- Create RefreshTokens table
CREATE TABLE IF NOT EXISTS "RefreshTokens" (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    token_hash VARCHAR(128) NOT NULL UNIQUE, -- SHA256 hash of the refresh token
    fingerprint_hash VARCHAR(128) NOT NULL, -- SHA256 hash of the user fingerprint
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    device_info JSONB DEFAULT '{}', -- Optional: store device/browser info
    ip_address INET, -- Optional: store IP for security tracking
    
    -- Foreign key constraint to User table
    CONSTRAINT fk_refresh_tokens_user 
        FOREIGN KEY (user_id) 
        REFERENCES "User"(id) 
        ON DELETE CASCADE,
    
    -- Note: Unique constraint for active tokens is created as partial index below
    -- This allows multiple inactive tokens (for history) but only one active token per user
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON "RefreshTokens"(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token_hash ON "RefreshTokens"(token_hash);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires_at ON "RefreshTokens"(expires_at);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_active ON "RefreshTokens"(is_active) WHERE is_active = true;

-- Create partial unique index to ensure only one active token per user
-- This allows multiple inactive tokens (for audit history) but only one active token
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_user_token 
ON "RefreshTokens" (user_id) 
WHERE is_active = true;

-- Create a function to automatically clean up expired tokens
CREATE OR REPLACE FUNCTION cleanup_expired_refresh_tokens()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM "RefreshTokens" 
    WHERE expires_at < NOW() OR is_active = false;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RAISE NOTICE 'Cleaned up % expired/inactive refresh tokens', deleted_count;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to run cleanup (optional - requires pg_cron extension)
-- SELECT cron.schedule('cleanup-refresh-tokens', '0 2 * * *', 'SELECT cleanup_expired_refresh_tokens();');

-- Add comments for documentation
COMMENT ON TABLE "RefreshTokens" IS 'Stores refresh tokens for JWT authentication system with security fingerprinting';
COMMENT ON COLUMN "RefreshTokens".token_hash IS 'SHA256 hash of the actual refresh token for security';
COMMENT ON COLUMN "RefreshTokens".fingerprint_hash IS 'SHA256 hash of user fingerprint to prevent token sidejacking';
COMMENT ON COLUMN "RefreshTokens".device_info IS 'Optional JSON object to store device/browser information';
COMMENT ON COLUMN "RefreshTokens".ip_address IS 'IP address when token was created for security tracking';