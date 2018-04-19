-- We're not normalising seeds into a table of their own on purpose.

CREATE TABLE IF NOT EXISTS user_account (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  identifier VARCHAR NOT NULL UNIQUE
);
CREATE INDEX IF NOT EXISTS idx_user_account_identifier ON user_account(identifier);

CREATE TABLE IF NOT EXISTS user_address (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_account INTEGER NOT NULL,
  seed CHAR(81) NOT NULL,
  seed_uuid TEXT NOT NULL,
  seed_idx INTEGER DEFAULT (0) NOT NULL,
  sec_level INTEGER DEFAULT(2) NOT NULL,
  FOREIGN KEY (user_account) REFERENCES user_account(id)
);

CREATE TABLE IF NOT EXISTS hub_address (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seed CHAR(81) NOT NULL,
  -- used for tracking with Multi-Signature party
  seed_uuid TEXT NOT NULL,
  seed_idx INTEGER DEFAULT (0) NOT NULL,
  sec_level INTEGER DEFAULT (2) NOT NULL,
  is_cold_storage INTEGER DEFAULT 0 NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- reason: 0 INBOUND 1 OUTBOUND
CREATE TABLE IF NOT EXISTS hub_address_balance (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  hub_address INTEGER NOT NULL,
  amount INTEGER NOT NULL,
  reason INTEGER NOT NULL,
  sweep INTEGER NOT NULL,
  occured_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (reason >= 0 and reason < 2),
  FOREIGN KEY (hub_address) REFERENCES hub_address(id),
  FOREIGN KEY (sweep) REFERENCES sweep(id)
);

CREATE INDEX IF NOT EXISTS idx_hub_address_reason ON hub_address_balance(hub_address, reason);

CREATE TABLE IF NOT EXISTS sweep (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bundle_hash CHAR(81) NOT NULL UNIQUE,
  trytes TEXT NOT NULL,
  into_hub_address INTEGER NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
  FOREIGN KEY (into_hub_address) REFERENCES hub_address(id)
);

-- reason: 0 DEPOSIT 1 SWEEP
-- if user_address_balance is NE 0 for a given user_account, then this user_account's funds have not been swept yet.
CREATE TABLE IF NOT EXISTS user_address_balance (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_address INTEGER NOT NULL,
  amount INTEGER NOT NULL,
  reason INTEGER NOT NULL,
  -- confirmed tail's hash
  tail_hash CHAR(81) DEFAULT NULL UNIQUE,
  -- nullable if not swept yet
  sweep INTEGER DEFAULT NULL,
  occured_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (reason = 0 and tail_hash not null),
  CHECK (reason = 1 and sweep not null),
  CHECK (reason >= 0 and reason < 2),
  FOREIGN KEY (user_address) REFERENCES user_address(id),
  FOREIGN KEY (sweep) REFERENCES sweep(id)
);

CREATE INDEX IF NOT EXISTS idx_user_address_reason ON user_address_balance(user_address, reason);

CREATE TABLE IF NOT EXISTS withdrawal (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_account INTEGER NOT NULL,
  amount INTEGER NOT NULL,
  -- payout address
  to_address CHAR(81) NOT NULL,
  -- sweep that processes this withdrawal
  sweep INTEGER DEFAULT NULL,
  requested_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CHECK (amount > 0),
  FOREIGN KEY (sweep) REFERENCES sweep(id),
  FOREIGN KEY (user_account) REFERENCES user_account(id)
);
-- reason: 0 SWEEP 1 WITHDRAWAL 2 TRADE
CREATE TABLE IF NOT EXISTS user_account_balance (
  user_account INTEGER NOT NULL,
  amount INTEGER NOT NULL,
  reason INTEGER NOT NULL,
  sweep INTEGER,
  withdrawal INTEGER CHECK (reason = 1 and withdrawal not null),
  occured_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CHECK (reason = 0 and sweep not null),
  CHECK (reason >= 0 and reason < 3),
  FOREIGN KEY (user_account) REFERENCES user_account(id),
  FOREIGN KEY (sweep) REFERENCES sweep(id),
  FOREIGN KEY (withdrawal) REFERENCES withdrawal(id)
);

CREATE INDEX IF NOT EXISTS idx_user_account_balance_by_user_account ON user_account_balance(user_account);

CREATE TABLE IF NOT EXISTS sweep_tails (
  hash CHAR(81) PRIMARY KEY NOT NULL,
  sweep INTEGER NOT NULL,
  confirmed INTEGER DEFAULT (0) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
  FOREIGN KEY (sweep) REFERENCES sweep(id)
);

CREATE INDEX IF NOT EXISTS idx_pending_tails_by_sweep ON sweep_tails(sweep);