-- Diagnostic storage only. Future accounts and progression require separate tables/authentication.
CREATE TABLE IF NOT EXISTS fx_reports (
 id text PRIMARY KEY,
 created_at timestamptz NOT NULL DEFAULT now(),
 match_id text NOT NULL,
 room text NOT NULL,
 actor text NOT NULL,
 device_id text NOT NULL,
 build text NOT NULL,
 hero text NOT NULL,
 payload jsonb NOT NULL
);
CREATE INDEX IF NOT EXISTS fx_reports_match_time ON fx_reports(match_id, created_at);
CREATE INDEX IF NOT EXISTS fx_reports_retention ON fx_reports(created_at);
