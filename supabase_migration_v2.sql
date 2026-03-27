-- 100xBet CRM — Supabase Migration v2
-- Fixed to match all columns the dashboard actually uses
-- Generated 2026-03-27

BEGIN;

-- =============================================================================
-- Drop old tables if re-running (order matters due to foreign keys)
-- =============================================================================
DROP TABLE IF EXISTS tier_promotions CASCADE;
DROP TABLE IF EXISTS commission_tiers CASCADE;
DROP TABLE IF EXISTS agent_payments CASCADE;
DROP TABLE IF EXISTS agent_weekly_data CASCADE;
DROP TABLE IF EXISTS agent_player_activity CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS call_logs CASCADE;
DROP TABLE IF EXISTS fraud_risk_scores CASCADE;
DROP TABLE IF EXISTS telegram_subscribers CASCADE;
DROP TABLE IF EXISTS agents CASCADE;
DROP TABLE IF EXISTS crm_users CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- =============================================================================
-- 1. customers (core player table)
-- =============================================================================
CREATE TABLE customers (
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

CREATE INDEX idx_customers_phone_number      ON customers (phone_number);
CREATE INDEX idx_customers_email             ON customers (email);
CREATE INDEX idx_customers_status            ON customers (status);
CREATE INDEX idx_customers_vip_level         ON customers (vip_level);
CREATE INDEX idx_customers_preferred_channel ON customers (preferred_channel);
CREATE INDEX idx_customers_last_login_date   ON customers (last_login_date);
CREATE INDEX idx_customers_ggr               ON customers (ggr);
CREATE INDEX idx_customers_registration_date ON customers (registration_date);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY customers_authenticated_full_access ON customers
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =============================================================================
-- 2. crm_users
-- =============================================================================
CREATE TABLE crm_users (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id     text,
  email       text        NOT NULL UNIQUE,
  name        text,
  role        text        NOT NULL DEFAULT 'agent',
  is_active   boolean     DEFAULT true,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

ALTER TABLE crm_users ENABLE ROW LEVEL SECURITY;
CREATE POLICY crm_users_authenticated_full_access ON crm_users
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =============================================================================
-- 3. agents
-- =============================================================================
CREATE TABLE agents (
  id                          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name                        text        NOT NULL,
  email                       text,
  phone                       text,
  nrc                         text,
  promo_code                  text        UNIQUE,
  password_hash               text,
  commission_plan             text,
  commission_rate             numeric     DEFAULT 0,
  per_client_amount           numeric     DEFAULT 0,
  location                    text,
  recruiter_name              text,
  signup_link                 text,
  source                      text,
  status                      text        DEFAULT 'active',
  is_active                   boolean     DEFAULT true,
  self_registered             boolean     DEFAULT false,
  promo_code_change_request   text,
  promo_code_change_status    text,
  commission_plan_changed_at  timestamptz,
  created_at                  timestamptz DEFAULT now(),
  updated_at                  timestamptz DEFAULT now()
);

ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
CREATE POLICY agents_authenticated_full_access ON agents
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =============================================================================
-- 4. call_logs
-- =============================================================================
CREATE TABLE call_logs (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id       text,
  employee_id     uuid        REFERENCES agents(id) ON DELETE SET NULL,
  outcome         text,
  notes           text,
  rating          integer,
  callback_date   timestamptz,
  created_at      timestamptz DEFAULT now()
);

ALTER TABLE call_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY call_logs_authenticated_full_access ON call_logs
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =============================================================================
-- 5. chat_messages
-- =============================================================================
CREATE TABLE chat_messages (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id        uuid        REFERENCES agents(id) ON DELETE SET NULL,
  sender_type     text,
  sender_id       text,
  sender_name     text,
  message         text        NOT NULL,
  is_read         boolean     DEFAULT false,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX idx_chat_messages_agent_id ON chat_messages (agent_id);

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY chat_messages_authenticated_full_access ON chat_messages
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =============================================================================
-- 6. agent_player_activity
-- =============================================================================
CREATE TABLE agent_player_activity (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id            uuid        REFERENCES agents(id) ON DELETE SET NULL,
  agent_code          text,
  week_start_date     date,
  week_end_date       date,
  user_id             text,
  phone_number        text,
  first_deposit       numeric     DEFAULT 0,
  total_deposit       numeric     DEFAULT 0,
  total_bet_sports    numeric     DEFAULT 0,
  total_bet_casino    numeric     DEFAULT 0,
  total_bet           numeric     DEFAULT 0,
  losses              numeric     DEFAULT 0,
  qualifies_per_client boolean    DEFAULT false,
  commission_earned   numeric     DEFAULT 0,
  created_at          timestamptz DEFAULT now()
);

-- Unique constraint for upsert
CREATE UNIQUE INDEX idx_apa_agent_week_user
  ON agent_player_activity (agent_id, week_start_date, user_id);

ALTER TABLE agent_player_activity ENABLE ROW LEVEL SECURITY;
CREATE POLICY apa_authenticated_full_access ON agent_player_activity
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =============================================================================
-- 7. agent_weekly_data
-- =============================================================================
CREATE TABLE agent_weekly_data (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id            uuid        REFERENCES agents(id) ON DELETE SET NULL,
  week_start_date     date        NOT NULL,
  week_end_date       date,
  total_clients       integer     DEFAULT 0,
  qualifying_clients  integer     DEFAULT 0,
  total_deposits      numeric     DEFAULT 0,
  total_bet_sports    numeric     DEFAULT 0,
  total_bet_casino    numeric     DEFAULT 0,
  total_losses        numeric     DEFAULT 0,
  commission_plan     text,
  per_client_earnings numeric     DEFAULT 0,
  loss_based_earnings numeric     DEFAULT 0,
  total_earnings      numeric     DEFAULT 0,
  created_at          timestamptz DEFAULT now()
);

-- Unique constraint for upsert
CREATE UNIQUE INDEX idx_awd_agent_week
  ON agent_weekly_data (agent_id, week_start_date);

ALTER TABLE agent_weekly_data ENABLE ROW LEVEL SECURITY;
CREATE POLICY awd_authenticated_full_access ON agent_weekly_data
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =============================================================================
-- 8. agent_payments
-- =============================================================================
CREATE TABLE agent_payments (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id        uuid        REFERENCES agents(id) ON DELETE SET NULL,
  amount          numeric     NOT NULL DEFAULT 0,
  payment_method  text,
  payment_date    timestamptz,
  status          text        NOT NULL DEFAULT 'pending',
  notes           text,
  paid_at         timestamptz,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

ALTER TABLE agent_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY ap_authenticated_full_access ON agent_payments
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =============================================================================
-- 9. fraud_risk_scores
-- =============================================================================
CREATE TABLE fraud_risk_scores (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id           text,
  phone_number        text,
  risk_level          text,
  risk_score          numeric     NOT NULL DEFAULT 0,
  flags               jsonb,
  action_taken        text,
  total_deposits      numeric     DEFAULT 0,
  total_bets          numeric     DEFAULT 0,
  total_wins          numeric     DEFAULT 0,
  first_deposit       numeric     DEFAULT 0,
  total_withdrawals   numeric     DEFAULT 0,
  bet_count           integer     DEFAULT 0,
  reviewed            boolean     DEFAULT false,
  reviewed_by         text,
  reviewed_at         timestamptz,
  review_notes        text,
  created_at          timestamptz DEFAULT now(),
  updated_at          timestamptz DEFAULT now()
);

CREATE INDEX idx_fraud_risk_scores_player_id ON fraud_risk_scores (player_id);
CREATE INDEX idx_fraud_risk_scores_risk_level ON fraud_risk_scores (risk_level);

ALTER TABLE fraud_risk_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY frs_authenticated_full_access ON fraud_risk_scores
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =============================================================================
-- 10. commission_tiers
-- =============================================================================
CREATE TABLE commission_tiers (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_name           text        NOT NULL UNIQUE,
  tier_order          integer     DEFAULT 0,
  min_active_clients  integer     DEFAULT 0,
  loss_based_rate     numeric     DEFAULT 0,
  per_client_amount   numeric     DEFAULT 0,
  cash_prize          numeric     DEFAULT 0,
  color               text,
  emoji               text,
  created_at          timestamptz DEFAULT now(),
  updated_at          timestamptz DEFAULT now()
);

ALTER TABLE commission_tiers ENABLE ROW LEVEL SECURITY;
CREATE POLICY ct_authenticated_full_access ON commission_tiers
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =============================================================================
-- 11. tier_promotions
-- =============================================================================
CREATE TABLE tier_promotions (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id        uuid        REFERENCES agents(id) ON DELETE SET NULL,
  previous_tier   text,
  new_tier        text,
  cash_prize      numeric     DEFAULT 0,
  prize_status    text        DEFAULT 'pending',
  week_achieved   date,
  promoted_at     timestamptz DEFAULT now(),
  paid_at         timestamptz,
  notes           text,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

ALTER TABLE tier_promotions ENABLE ROW LEVEL SECURITY;
CREATE POLICY tp_authenticated_full_access ON tier_promotions
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =============================================================================
-- 12. telegram_subscribers
-- =============================================================================
CREATE TABLE telegram_subscribers (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id         text        NOT NULL,
  label           text,
  is_active       boolean     DEFAULT true,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX idx_telegram_subscribers_chat_id ON telegram_subscribers (chat_id);

ALTER TABLE telegram_subscribers ENABLE ROW LEVEL SECURITY;
CREATE POLICY ts_authenticated_full_access ON telegram_subscribers
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

COMMIT;
