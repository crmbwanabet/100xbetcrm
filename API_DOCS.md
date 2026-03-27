# 100xBet CRM — Customer Data API

## Endpoint
```
POST https://<your-vercel-url>/api/customers
```

## Authentication
Include the API key in the header:
```
x-api-key: <provided-api-key>
```

## Request
- Content-Type: `application/json`
- Body: a single object or an array of up to 5,000 objects
- Each object **must** include an `id` field

## Example
```json
POST /api/customers
x-api-key: your-key

[
  {
    "id": "123",
    "phone_number": "+35312345678",
    "email": "player@example.com",
    "username": "player123",
    "name": "John Doe",
    "status": "active",
    "currency": "EUR",
    "registration_date": "2025-06-15T10:00:00Z",

    "deposit_amount": 1500.00,
    "deposit_count": 12,
    "first_deposit_date": "2025-06-15T10:30:00Z",
    "first_deposit_amount": 50.00,
    "last_deposit_date": "2026-03-20T14:00:00Z",
    "avg_deposit_amount": 125.00,
    "deposit_method": "card",

    "withdrawal_amount": 800.00,
    "withdrawal_count": 3,
    "last_withdrawal_date": "2026-03-18T09:00:00Z",
    "pending_withdrawal_amount": 200.00,
    "withdrawal_rejection_count": 0,
    "net_deposit": 700.00,

    "sport_bet_amount": 3000.00,
    "sport_win_amount": 2700.00,
    "sport_bet_count": 85,
    "sport_win_count": 40,

    "casino_bet_amount": 5000.00,
    "casino_win_amount": 4600.00,
    "casino_bet_count": 200,
    "casino_win_count": 90,

    "ggr": 700.00,
    "preferred_channel": "casino",
    "top_provider": "Pragmatic Play",
    "favorite_games": ["Sweet Bonanza", "Gates of Olympus"],

    "last_activity": "2026-03-25T18:30:00Z",
    "last_login_date": "2026-03-25T18:00:00Z",
    "days_since_last_login": 2,
    "login_count_30d": 18,
    "bet_frequency_7d": 12,
    "bet_frequency_30d": 45,

    "vip_level": "VIP Level 3",
    "kyc_status": "verified",
    "affiliate_id": 55,

    "bonus_amount": 120.00,
    "total_bonuses_claimed": 5,
    "active_bonus": true,
    "wagering_progress_pct": 72.5,
    "last_bonus_date": "2026-03-20T14:00:00Z",
    "cashback_received_total": 45.00,
    "freespins_received": 30,

    "failed_login_count": 1,
    "high_value_flag": false,
    "segment_codes": ["high_value", "casino_lover"],
    "mission_completion_count": 3,
    "mystery_box_wins": 1,
    "affiliate_earnings": 0.00
  }
]
```

## Accepted Fields

### Required
| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique player ID from your platform |

### Identity
| Field | Type | Description |
|-------|------|-------------|
| `phone_number` | string | International format |
| `email` | string | Auto-lowercased and trimmed |
| `username` | string | |
| `name` | string | Full name |
| `status` | string | e.g. "active", "banned", "suspended" |
| `currency` | string | Default: "EUR" |
| `registration_date` | datetime | Account creation date |
| `affiliate_id` | integer | ID of the user who referred this player |
| `vip_level` | string | e.g. "VIP Level 1", "Gold", etc. |
| `kyc_status` | string | "verified", "pending", or "unverified" |

### Financial
| Field | Type | Description |
|-------|------|-------------|
| `deposit_amount` | number | Total confirmed deposits |
| `deposit_count` | integer | Number of confirmed deposits |
| `first_deposit_date` | datetime | Date of first deposit |
| `first_deposit_amount` | number | Amount of first deposit |
| `last_deposit_date` | datetime | Date of most recent deposit |
| `avg_deposit_amount` | number | Average deposit size |
| `deposit_method` | string | Most used method (e.g. "card", "pix", "crypto") |
| `withdrawal_amount` | number | Total confirmed withdrawals |
| `withdrawal_count` | integer | Number of confirmed withdrawals |
| `last_withdrawal_date` | datetime | Date of most recent withdrawal |
| `pending_withdrawal_amount` | number | Amount currently pending |
| `withdrawal_rejection_count` | integer | Number of rejected withdrawals |
| `net_deposit` | number | deposits minus withdrawals |
| `ggr` | number | Gross Gaming Revenue (total bets - total wins) |

### Sports Betting
| Field | Type | Description |
|-------|------|-------------|
| `sport_bet_amount` | number | Total sports bet amount |
| `sport_win_amount` | number | Total sports win amount |
| `sport_bet_count` | integer | Number of sports bets |
| `sport_win_count` | integer | Number of sports wins |

### Casino
| Field | Type | Description |
|-------|------|-------------|
| `casino_bet_amount` | number | Total casino bet amount |
| `casino_win_amount` | number | Total casino win amount |
| `casino_bet_count` | integer | Number of casino bets |
| `casino_win_count` | integer | Number of casino wins |

### Engagement
| Field | Type | Description |
|-------|------|-------------|
| `last_activity` | datetime | Last known activity |
| `last_login_date` | datetime | Last login timestamp |
| `days_since_last_login` | integer | Days since last login |
| `login_count_30d` | integer | Logins in last 30 days |
| `preferred_channel` | string | Must be "sports", "casino", or "hybrid" |
| `top_provider` | string | Most played casino provider name |
| `favorite_games` | array | JSON array of game names |
| `bet_frequency_7d` | integer | Bets placed in last 7 days |
| `bet_frequency_30d` | integer | Bets placed in last 30 days |

### Bonuses
| Field | Type | Description |
|-------|------|-------------|
| `bonus_amount` | number | Total bonus value received |
| `total_bonuses_claimed` | integer | Number of bonuses claimed |
| `active_bonus` | boolean | Has an active bonus right now |
| `wagering_progress_pct` | number | 0-100, % of wagering requirement completed |
| `last_bonus_date` | datetime | Date of last bonus |
| `cashback_received_total` | number | Total cashback received |
| `freespins_received` | integer | Total free spins received |

### Risk & Compliance
| Field | Type | Description |
|-------|------|-------------|
| `failed_login_count` | integer | Failed login attempts |
| `high_value_flag` | boolean | Flagged for high-value activity |
| `segment_codes` | array | JSON array of segment tags |

### Gamification & Affiliates
| Field | Type | Description |
|-------|------|-------------|
| `mission_completion_count` | integer | Completed missions |
| `mystery_box_wins` | integer | Mystery box prizes won |
| `affiliate_earnings` | number | Commissions earned as an affiliate |

## Behavior
- Duplicate `id` values are **merged** (upsert), not rejected
- Unknown fields are silently dropped
- Missing optional fields keep their existing value (or default)
- Send data as often as you like — hourly, daily, or on every event

## Response
```json
{ "success": true, "upserted": 150, "errors": [] }
```

Errors array contains any rows that failed validation:
```json
{ "errors": [{ "index": 3, "error": "Missing required field: id" }] }
```
