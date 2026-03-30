-- 100xBet CRM — Bonus Decision Engine Tables
-- Required for the Bonus Decision Engine (Constitution v2.0)
-- Generated 2026-03-30

BEGIN;

CREATE TABLE IF NOT EXISTS bonus_decisions (
  id                    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id             text,
  phone_number          text,
  action                text,
  bonus_amount          decimal(12,2) DEFAULT 0,
  expected_deposit      decimal(12,2) DEFAULT 0,
  ev                    decimal(12,2) DEFAULT 0,
  p_deposit             decimal(5,4) DEFAULT 0,
  trigger_reason        text,
  previous_churn_status text,
  new_churn_status      text,
  status                text        DEFAULT 'pending',
  negative_signals      jsonb,
  actual_revenue        decimal(12,2),
  decided_by            text,
  decided_at            timestamptz,
  created_at            timestamptz DEFAULT now(),
  updated_at            timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bonus_decisions_player_id ON bonus_decisions (player_id);
CREATE INDEX IF NOT EXISTS idx_bonus_decisions_status ON bonus_decisions (status);
CREATE INDEX IF NOT EXISTS idx_bonus_decisions_created_at ON bonus_decisions (created_at);

ALTER TABLE bonus_decisions ENABLE ROW LEVEL SECURITY;
CREATE POLICY bd_authenticated_full_access ON bonus_decisions
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE TABLE IF NOT EXISTS bonus_settings (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  key         text        NOT NULL UNIQUE,
  value       jsonb,
  updated_by  text,
  updated_at  timestamptz DEFAULT now()
);

ALTER TABLE bonus_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY bs_authenticated_full_access ON bonus_settings
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE TABLE IF NOT EXISTS bonus_negative_signals (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id   text,
  signal_type text,
  signal_name text,
  details     jsonb,
  is_active   boolean     DEFAULT true,
  detected_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bns_player_id ON bonus_negative_signals (player_id);

ALTER TABLE bonus_negative_signals ENABLE ROW LEVEL SECURITY;
CREATE POLICY bns_authenticated_full_access ON bonus_negative_signals
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

COMMIT;
