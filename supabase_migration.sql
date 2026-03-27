-- 100xBet CRM — Supabase Migration
-- Based on bwanabet-crm schema, enhanced with ViperPro fields
-- Generated 2026-03-27

BEGIN;

-- =============================================================================
-- 1. customers (core player table)
-- =============================================================================
CREATE TABLE IF NOT EXISTS customers (
  -- Original fields
  id                          text        PRIMARY KEY,
  phone_number                text,
  registration_date           timestamptz,
  last_activity               timestamptz,
  last_deposit_date           timestamptz,
  sport_bet_amount            numeric     DEFAULT 0,
  sport_win_amount            numeric     DEFAULT 0,
  sport_bet_count             integer     DEFAULT 0,
  sport_win_count             integer     DEFAULT 0,
  casino_bet_amount           numeric     DEFAULT 0,
  casino_win_amount           numeric     DEFAULT 0,
  casino_bet_count            integer     DEFAULT 0,
  casino_win_count            integer     DEFAULT 0,
  deposit_amount              numeric     DEFAULT 0,
  deposit_count               integer     DEFAULT 0,
  withdrawal_amount           numeric     DEFAULT 0,
  withdrawal_count            integer     DEFAULT 0,
  bonus_amount                numeric     DEFAULT 0,
  status                      text,
  currency                    text        DEFAULT 'EUR',

  -- ViperPro-enriched fields
  email                       text,
  username                    text,
  name                        text,
  affiliate_id                integer,
  vip_level                   text,
  kyc_status                  text,
  ggr                         numeric     DEFAULT 0,
  net_deposit                 numeric     DEFAULT 0,
  avg_deposit_amount          numeric     DEFAULT 0,
  first_deposit_date          timestamptz,
  first_deposit_amount        numeric     DEFAULT 0,
  last_withdrawal_date        timestamptz,
  pending_withdrawal_amount   numeric     DEFAULT 0,
  last_login_date             timestamptz,
  days_since_last_login       integer     DEFAULT 0,
  login_count_30d             integer     DEFAULT 0,
  preferred_channel           text,
  favorite_games              jsonb,
  top_provider                text,
  bet_frequency_7d            integer     DEFAULT 0,
  bet_frequency_30d           integer     DEFAULT 0,
  total_bonuses_claimed       integer     DEFAULT 0,
  active_bonus                boolean     DEFAULT false,
  wagering_progress_pct       numeric     DEFAULT 0,
  last_bonus_date             timestamptz,
  cashback_received_total     numeric     DEFAULT 0,
  freespins_received          integer     DEFAULT 0,
  failed_login_count          integer     DEFAULT 0,
  withdrawal_rejection_count  integer     DEFAULT 0,
  high_value_flag             boolean     DEFAULT false,
  deposit_method              text,
  segment_codes               jsonb,
  mission_completion_count    integer     DEFAULT 0,
  mystery_box_wins            integer     DEFAULT 0,
  affiliate_earnings          numeric     DEFAULT 0
);

-- Indexes on customers
CREATE INDEX IF NOT EXISTS idx_customers_phone_number     ON customers (phone_number);
CREATE INDEX IF NOT EXISTS idx_customers_email            ON customers (email);
CREATE INDEX IF NOT EXISTS idx_customers_status           ON customers (status);
CREATE INDEX IF NOT EXISTS idx_customers_vip_level        ON customers (vip_level);
CREATE INDEX IF NOT EXISTS idx_customers_preferred_channel ON customers (preferred_channel);
CREATE INDEX IF NOT EXISTS idx_customers_last_login_date  ON customers (last_login_date);
CREATE INDEX IF NOT EXISTS idx_customers_ggr              ON customers (ggr);
CREATE INDEX IF NOT EXISTS idx_customers_registration_date ON customers (registration_date);

-- RLS on customers
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY customers_authenticated_full_access ON customers
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- =============================================================================
-- 2. crm_users
-- =============================================================================
CREATE TABLE IF NOT EXISTS crm_users (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  email       text        NOT NULL UNIQUE,
  role        text        NOT NULL DEFAULT 'agent',
  name        text,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- =============================================================================
-- 3. agents
-- =============================================================================
CREATE TABLE IF NOT EXISTS agents (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text        NOT NULL,
  promo_code  text        UNIQUE,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- =============================================================================
-- 4. call_logs
-- =============================================================================
CREATE TABLE IF NOT EXISTS call_logs (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id    uuid        REFERENCES agents(id) ON DELETE SET NULL,
  user_id     text        REFERENCES customers(id) ON DELETE SET NULL,
  direction   text        NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  duration    integer     DEFAULT 0,
  notes       text,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- =============================================================================
-- 5. chat_messages
-- =============================================================================
CREATE TABLE IF NOT EXISTS chat_messages (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id     text        NOT NULL,
  sender      text        NOT NULL,
  message     text        NOT NULL,
  created_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_id ON chat_messages (chat_id);

-- =============================================================================
-- 6. agent_player_activity
-- =============================================================================
CREATE TABLE IF NOT EXISTS agent_player_activity (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id        uuid        REFERENCES agents(id) ON DELETE SET NULL,
  player_id       text        REFERENCES customers(id) ON DELETE SET NULL,
  activity_type   text        NOT NULL,
  notes           text,
  created_at      timestamptz DEFAULT now()
);

-- =============================================================================
-- 7. agent_weekly_data
-- =============================================================================
CREATE TABLE IF NOT EXISTS agent_weekly_data (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id    uuid        REFERENCES agents(id) ON DELETE SET NULL,
  week_start  date        NOT NULL,
  calls_made  integer     DEFAULT 0,
  conversions integer     DEFAULT 0,
  revenue     numeric     DEFAULT 0,
  created_at  timestamptz DEFAULT now()
);

-- =============================================================================
-- 8. agent_payments
-- =============================================================================
CREATE TABLE IF NOT EXISTS agent_payments (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id    uuid        REFERENCES agents(id) ON DELETE SET NULL,
  amount      numeric     NOT NULL DEFAULT 0,
  period      text        NOT NULL,
  status      text        NOT NULL DEFAULT 'pending',
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- =============================================================================
-- 9. fraud_risk_scores
-- =============================================================================
CREATE TABLE IF NOT EXISTS fraud_risk_scores (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     text        REFERENCES customers(id) ON DELETE CASCADE,
  score       numeric     NOT NULL DEFAULT 0,
  factors     jsonb,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fraud_risk_scores_user_id ON fraud_risk_scores (user_id);

-- =============================================================================
-- 10. commission_tiers
-- =============================================================================
CREATE TABLE IF NOT EXISTS commission_tiers (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_name       text        NOT NULL UNIQUE,
  min_revenue     numeric     NOT NULL DEFAULT 0,
  commission_pct  numeric     NOT NULL DEFAULT 0,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

-- =============================================================================
-- 11. tier_promotions
-- =============================================================================
CREATE TABLE IF NOT EXISTS tier_promotions (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_id         uuid        REFERENCES commission_tiers(id) ON DELETE CASCADE,
  promo_details   jsonb,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

-- =============================================================================
-- 12. telegram_subscribers
-- =============================================================================
CREATE TABLE IF NOT EXISTS telegram_subscribers (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id         text        NOT NULL,
  user_id         text        REFERENCES customers(id) ON DELETE SET NULL,
  subscribed_at   timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_telegram_subscribers_chat_id ON telegram_subscribers (chat_id);

COMMIT;
