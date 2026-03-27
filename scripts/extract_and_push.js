/**
 * 100xBet CRM — ViperPro Data Extraction & Push Script
 *
 * Connects to the ViperPro MySQL database, aggregates customer data
 * across all relevant tables, and pushes enriched records to the CRM API.
 *
 * Usage:
 *   node extract_and_push.js
 *
 * Environment variables (required):
 *   VIPER_DB_HOST     — MySQL host
 *   VIPER_DB_PORT     — MySQL port (default 3306)
 *   VIPER_DB_USER     — MySQL user
 *   VIPER_DB_PASSWORD — MySQL password
 *   VIPER_DB_NAME     — Database name (default: viperpro)
 *   CRM_API_URL       — e.g. https://your-100xbet-crm.vercel.app/api/customers
 *   CRM_API_KEY       — The x-api-key for the CRM
 */

const mysql = require('mysql2/promise');

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const DB_CONFIG = {
  host:     process.env.VIPER_DB_HOST     || 'localhost',
  port:     parseInt(process.env.VIPER_DB_PORT || '3306'),
  user:     process.env.VIPER_DB_USER     || 'root',
  password: process.env.VIPER_DB_PASSWORD || '',
  database: process.env.VIPER_DB_NAME     || 'viperpro',
  connectTimeout: 30000,
};

const CRM_API_URL = process.env.CRM_API_URL;
const CRM_API_KEY = process.env.CRM_API_KEY;
const BATCH_SIZE  = 1000; // records per API call (max 5000)

// ---------------------------------------------------------------------------
// Main extraction query
// ---------------------------------------------------------------------------
const EXTRACTION_SQL = `
SELECT
  u.id                                                    AS id,
  u.phone                                                 AS phone_number,
  u.email                                                 AS email,
  u.name                                                  AS username,
  CONCAT(COALESCE(u.name, ''), ' ', COALESCE(u.last_name, '')) AS name,
  u.status                                                AS status,
  u.created_at                                            AS registration_date,
  u.inviter                                               AS affiliate_id,

  -- VIP
  CASE
    WHEN u.is_vip = 1 THEN CONCAT('VIP Level ', COALESCE(vu.level, w.vip_level, 0))
    ELSE NULL
  END                                                     AS vip_level,

  -- Currency
  COALESCE(w.currency, 'EUR')                             AS currency,

  -- Deposits
  COALESCE(dep.deposit_amount, 0)                         AS deposit_amount,
  COALESCE(dep.deposit_count, 0)                          AS deposit_count,
  dep.first_deposit_date                                  AS first_deposit_date,
  COALESCE(dep.first_deposit_amount, 0)                   AS first_deposit_amount,
  dep.last_deposit_date                                   AS last_deposit_date,
  CASE WHEN dep.deposit_count > 0
    THEN ROUND(dep.deposit_amount / dep.deposit_count, 2)
    ELSE 0
  END                                                     AS avg_deposit_amount,
  dep.deposit_method                                      AS deposit_method,

  -- Withdrawals
  COALESCE(wd.withdrawal_amount, 0)                       AS withdrawal_amount,
  COALESCE(wd.withdrawal_count, 0)                        AS withdrawal_count,
  wd.last_withdrawal_date                                 AS last_withdrawal_date,
  COALESCE(wd.pending_withdrawal_amount, 0)               AS pending_withdrawal_amount,
  COALESCE(wd.withdrawal_rejection_count, 0)              AS withdrawal_rejection_count,

  -- Net deposit
  COALESCE(dep.deposit_amount, 0) - COALESCE(wd.withdrawal_amount, 0) AS net_deposit,

  -- Sports betting
  COALESCE(sb.sport_bet_amount, 0)                        AS sport_bet_amount,
  COALESCE(sb.sport_win_amount, 0)                        AS sport_win_amount,
  COALESCE(sb.sport_bet_count, 0)                         AS sport_bet_count,
  COALESCE(sb.sport_win_count, 0)                         AS sport_win_count,

  -- Casino
  COALESCE(cb.casino_bet_amount, 0)                       AS casino_bet_amount,
  COALESCE(cb.casino_win_amount, 0)                       AS casino_win_amount,
  COALESCE(cb.casino_bet_count, 0)                        AS casino_bet_count,
  COALESCE(cb.casino_win_count, 0)                        AS casino_win_count,

  -- GGR (bets - wins across both channels)
  (COALESCE(sb.sport_bet_amount, 0) - COALESCE(sb.sport_win_amount, 0))
  + (COALESCE(cb.casino_bet_amount, 0) - COALESCE(cb.casino_win_amount, 0)) AS ggr,

  -- Preferred channel
  CASE
    WHEN COALESCE(sb.sport_bet_count, 0) > 0 AND COALESCE(cb.casino_bet_count, 0) > 0 THEN 'hybrid'
    WHEN COALESCE(sb.sport_bet_count, 0) > 0 THEN 'sports'
    WHEN COALESCE(cb.casino_bet_count, 0) > 0 THEN 'casino'
    ELSE NULL
  END                                                     AS preferred_channel,

  -- Top provider (most played casino provider)
  tp.top_provider                                         AS top_provider,

  -- Favorite games
  fg.favorite_games                                       AS favorite_games,

  -- Activity
  GREATEST(
    COALESCE(u.updated_at, u.created_at),
    COALESCE(sess.last_session, u.created_at)
  )                                                       AS last_activity,

  sess.last_login_date                                    AS last_login_date,
  COALESCE(DATEDIFF(NOW(), sess.last_login_date), 9999)   AS days_since_last_login,
  COALESCE(sess.login_count_30d, 0)                       AS login_count_30d,

  -- Bet frequency
  COALESCE(bf.bet_frequency_7d, 0)                        AS bet_frequency_7d,
  COALESCE(bf.bet_frequency_30d, 0)                       AS bet_frequency_30d,

  -- Bonuses
  COALESCE(bon.bonus_amount, 0)                           AS bonus_amount,
  COALESCE(bon.total_bonuses_claimed, 0)                  AS total_bonuses_claimed,
  COALESCE(bon.has_active_bonus, 0)                       AS active_bonus,
  bon.last_bonus_date                                     AS last_bonus_date,
  COALESCE(wag.wagering_progress_pct, 0)                  AS wagering_progress_pct,
  COALESCE(dcb.cashback_received_total, 0)                AS cashback_received_total,
  COALESCE(fs.freespins_received, 0)                      AS freespins_received,

  -- Login attempts (failed)
  COALESCE(la.failed_login_count, 0)                      AS failed_login_count,

  -- High value flag
  CASE WHEN hvn.hv_count > 0 THEN 1 ELSE 0 END           AS high_value_flag,

  -- KYC (derive from email_verified_at)
  CASE
    WHEN u.email_verified_at IS NOT NULL THEN 'verified'
    ELSE 'unverified'
  END                                                     AS kyc_status,

  -- Segments
  seg.segment_codes                                       AS segment_codes,

  -- Missions
  COALESCE(mis.mission_completion_count, 0)               AS mission_completion_count,

  -- Mystery box
  COALESCE(mb.mystery_box_wins, 0)                        AS mystery_box_wins,

  -- Affiliate earnings (commissions earned by this user as an affiliate)
  COALESCE(ae.affiliate_earnings, 0)                      AS affiliate_earnings

FROM users u

-- Wallet
LEFT JOIN wallets w ON w.user_id = u.id AND w.active = 1

-- VIP
LEFT JOIN vip_users vu ON vu.user_id = u.id

-- Deposits (aggregated)
LEFT JOIN (
  SELECT
    user_id,
    SUM(CASE WHEN status = 1 THEN amount ELSE 0 END) AS deposit_amount,
    COUNT(CASE WHEN status = 1 THEN 1 END)            AS deposit_count,
    MIN(CASE WHEN status = 1 THEN created_at END)     AS first_deposit_date,
    (SELECT d2.amount FROM deposits d2
     WHERE d2.user_id = deposits.user_id AND d2.status = 1
     ORDER BY d2.created_at ASC LIMIT 1)              AS first_deposit_amount,
    MAX(CASE WHEN status = 1 THEN created_at END)     AS last_deposit_date,
    -- Most common deposit type
    (SELECT d3.type FROM deposits d3
     WHERE d3.user_id = deposits.user_id AND d3.status = 1
     GROUP BY d3.type ORDER BY COUNT(*) DESC LIMIT 1) AS deposit_method
  FROM deposits
  GROUP BY user_id
) dep ON dep.user_id = u.id

-- Withdrawals (aggregated)
LEFT JOIN (
  SELECT
    user_id,
    SUM(CASE WHEN status = 1 THEN amount ELSE 0 END)  AS withdrawal_amount,
    COUNT(CASE WHEN status = 1 THEN 1 END)             AS withdrawal_count,
    MAX(CASE WHEN status = 1 THEN created_at END)      AS last_withdrawal_date,
    SUM(CASE WHEN status = 0 THEN amount ELSE 0 END)   AS pending_withdrawal_amount,
    COUNT(CASE WHEN status = 2 THEN 1 END)              AS withdrawal_rejection_count
  FROM withdrawals
  GROUP BY user_id
) wd ON wd.user_id = u.id

-- Sports betting (aggregated)
LEFT JOIN (
  SELECT
    CAST(player_id AS UNSIGNED) AS user_id,
    SUM(CASE WHEN action = 'bet'  THEN amount ELSE 0 END)  AS sport_bet_amount,
    SUM(CASE WHEN action = 'win'  THEN amount ELSE 0 END)  AS sport_win_amount,
    COUNT(CASE WHEN action = 'bet' THEN 1 END)              AS sport_bet_count,
    COUNT(CASE WHEN action = 'win' THEN 1 END)              AS sport_win_count
  FROM sportsbook_transactions
  WHERE status = 'success'
  GROUP BY player_id
) sb ON sb.user_id = u.id

-- Casino (aggregated)
LEFT JOIN (
  SELECT
    player_id AS user_id,
    SUM(debit_amount)                                       AS casino_bet_amount,
    SUM(credit_amount)                                      AS casino_win_amount,
    COUNT(CASE WHEN debit_amount > 0 THEN 1 END)           AS casino_bet_count,
    COUNT(CASE WHEN credit_amount > 0 THEN 1 END)          AS casino_win_count
  FROM casino_game_transactions
  WHERE status = 'success'
  GROUP BY player_id
) cb ON cb.user_id = u.id

-- Top casino provider
LEFT JOIN (
  SELECT
    cgt.player_id AS user_id,
    p.name AS top_provider
  FROM casino_game_transactions cgt
  JOIN games g ON g.game_id = cgt.game_uuid OR g.id = cgt.game_id
  JOIN providers p ON p.id = g.provider_id
  WHERE cgt.status = 'success'
  GROUP BY cgt.player_id, p.name
  ORDER BY COUNT(*) DESC
  LIMIT 1
) tp ON tp.user_id = u.id

-- Favorite games
LEFT JOIN (
  SELECT
    gf.user_id,
    JSON_ARRAYAGG(g.game_name) AS favorite_games
  FROM game_favorites gf
  JOIN games g ON g.id = gf.game_id
  GROUP BY gf.user_id
) fg ON fg.user_id = u.id

-- Sessions / last login
LEFT JOIN (
  SELECT
    user_id,
    MAX(last_activity) AS last_session,
    MAX(created_at) AS last_login_date,
    SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 ELSE 0 END) AS login_count_30d
  FROM user_sessions
  WHERE deleted_at IS NULL
  GROUP BY user_id
) sess ON sess.user_id = u.id

-- Bet frequency (7d / 30d)
LEFT JOIN (
  SELECT
    user_id,
    SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) THEN 1 ELSE 0 END)  AS bet_frequency_7d,
    SUM(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 ELSE 0 END)  AS bet_frequency_30d
  FROM (
    SELECT CAST(player_id AS UNSIGNED) AS user_id, created_at
    FROM sportsbook_transactions WHERE action = 'bet' AND status = 'success'
    UNION ALL
    SELECT player_id AS user_id, created_at
    FROM casino_game_transactions WHERE debit_amount > 0 AND status = 'success'
  ) all_bets
  GROUP BY user_id
) bf ON bf.user_id = u.id

-- Bonuses
LEFT JOIN (
  SELECT
    user_id,
    SUM(COALESCE(bonus_amount, 0)) AS bonus_amount,
    COUNT(*) AS total_bonuses_claimed,
    MAX(CASE WHEN status = 'active' THEN 1 ELSE 0 END) AS has_active_bonus,
    MAX(created_at) AS last_bonus_date
  FROM user_bonuses
  GROUP BY user_id
) bon ON bon.user_id = u.id

-- Wagering progress (latest active bonus)
LEFT JOIN (
  SELECT
    user_id,
    CASE
      WHEN wager_required > 0
      THEN ROUND(LEAST(wagered_amount / wager_required * 100, 100), 2)
      ELSE 0
    END AS wagering_progress_pct
  FROM user_deposit_wagerings
  WHERE completed = 0
  ORDER BY created_at DESC
  LIMIT 1
) wag ON wag.user_id = u.id

-- Cashback
LEFT JOIN (
  SELECT
    user_id,
    SUM(bonus_amount) AS cashback_received_total
  FROM daily_cashback_bonuses
  GROUP BY user_id
) dcb ON dcb.user_id = u.id

-- Free spins received
LEFT JOIN (
  SELECT
    ct.user_id,
    SUM(c.quantity) AS freespins_received
  FROM campaign_targets ct
  JOIN campaigns c ON c.id = ct.campaign_id
  GROUP BY ct.user_id
) fs ON fs.user_id = u.id

-- Failed logins
LEFT JOIN (
  SELECT
    user_id,
    COUNT(*) AS failed_login_count
  FROM login_attempts
  WHERE success = 0 AND user_id IS NOT NULL
  GROUP BY user_id
) la ON la.user_id = u.id

-- High value notifications
LEFT JOIN (
  SELECT
    user_id,
    COUNT(*) AS hv_count
  FROM admin_notifications
  WHERE type = 'withdrawal'
  GROUP BY user_id
) hvn ON hvn.user_id = u.id

-- Segments
LEFT JOIN (
  SELECT
    user_id,
    JSON_ARRAYAGG(segment_code) AS segment_codes
  FROM player_segments
  WHERE (valid_to IS NULL OR valid_to >= NOW())
  GROUP BY user_id
) seg ON seg.user_id = u.id

-- Missions completed
LEFT JOIN (
  SELECT
    user_id,
    COUNT(*) AS mission_completion_count
  FROM mission_users
  WHERE status = 1
  GROUP BY user_id
) mis ON mis.user_id = u.id

-- Mystery box wins
LEFT JOIN (
  SELECT
    user_id,
    COUNT(*) AS mystery_box_wins
  FROM mystery_box_winners
  GROUP BY user_id
) mb ON mb.user_id = u.id

-- Affiliate earnings (this user as an inviter)
LEFT JOIN (
  SELECT
    inviter AS user_id,
    SUM(commission_paid) AS affiliate_earnings
  FROM affiliate_commissions
  GROUP BY inviter
) ae ON ae.user_id = u.id

WHERE u.is_guest = 0
ORDER BY u.id
`;

// ---------------------------------------------------------------------------
// Push to CRM API
// ---------------------------------------------------------------------------
async function pushBatch(records) {
  const res = await fetch(CRM_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': CRM_API_KEY,
    },
    body: JSON.stringify(records),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`CRM API error ${res.status}: ${text}`);
  }

  return res.json();
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  if (!CRM_API_URL || !CRM_API_KEY) {
    console.error('ERROR: CRM_API_URL and CRM_API_KEY must be set');
    process.exit(1);
  }

  console.log('Connecting to ViperPro MySQL...');
  const conn = await mysql.createConnection(DB_CONFIG);

  console.log('Running extraction query...');
  const [rows] = await conn.execute(EXTRACTION_SQL);
  console.log(`Extracted ${rows.length} customers`);

  await conn.end();

  if (rows.length === 0) {
    console.log('No data to push');
    return;
  }

  // Clean up rows — convert BigInt, parse JSON strings
  const cleaned = rows.map(row => {
    const out = {};
    for (const [k, v] of Object.entries(row)) {
      if (typeof v === 'bigint') {
        out[k] = Number(v);
      } else if (v === null || v === undefined) {
        // skip nulls to let API defaults apply
      } else {
        out[k] = v;
      }
    }
    return out;
  });

  // Push in batches
  let pushed = 0;
  for (let i = 0; i < cleaned.length; i += BATCH_SIZE) {
    const batch = cleaned.slice(i, i + BATCH_SIZE);
    console.log(`Pushing batch ${Math.floor(i / BATCH_SIZE) + 1} (${batch.length} records)...`);

    try {
      const result = await pushBatch(batch);
      pushed += result.upserted || batch.length;
      if (result.errors && result.errors.length > 0) {
        console.warn(`  Batch had ${result.errors.length} validation errors`);
      }
    } catch (err) {
      console.error(`  Batch failed: ${err.message}`);
      console.error(`  Pushed ${pushed} so far, ${cleaned.length - pushed} remaining`);
      process.exit(1);
    }
  }

  console.log(`Done. ${pushed} customers pushed to CRM.`);
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
