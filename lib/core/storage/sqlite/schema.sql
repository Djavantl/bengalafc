PRAGMA foreign_keys = ON;

CREATE TABLE app_users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  avatar_url TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE national_teams (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  flag_url TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE tournament_phases (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phase_type TEXT NOT NULL CHECK (phase_type IN ('group', 'knockout')),
  starts_at TEXT,
  ends_at TEXT,
  transfer_deadline_at TEXT,
  is_active INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE matches (
  id TEXT PRIMARY KEY,
  phase_id TEXT NOT NULL,
  home_team_id TEXT NOT NULL,
  away_team_id TEXT NOT NULL,
  starts_at TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('not_started', 'live', 'finished')),
  home_score INTEGER,
  away_score INTEGER,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (phase_id) REFERENCES tournament_phases(id),
  FOREIGN KEY (home_team_id) REFERENCES national_teams(id),
  FOREIGN KEY (away_team_id) REFERENCES national_teams(id)
);

CREATE TABLE players (
  id TEXT PRIMARY KEY,
  national_team_id TEXT NOT NULL,
  name TEXT NOT NULL,
  position TEXT NOT NULL CHECK (position IN ('GK', 'DEF', 'LAT', 'MID', 'ATA')),
  photo_url TEXT,
  total_points REAL NOT NULL DEFAULT 0,
  selected_percentage REAL NOT NULL DEFAULT 0,
  selected_count INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (national_team_id) REFERENCES national_teams(id)
);

CREATE TABLE coaches (
  id TEXT PRIMARY KEY,
  national_team_id TEXT NOT NULL,
  name TEXT NOT NULL,
  photo_url TEXT,
  total_points REAL NOT NULL DEFAULT 0,
  selected_percentage REAL NOT NULL DEFAULT 0,
  selected_count INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (national_team_id) REFERENCES national_teams(id)
);

CREATE TABLE scoring_rules (
  id TEXT PRIMARY KEY,
  event_code TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  points REAL NOT NULL,
  applies_to TEXT NOT NULL CHECK (applies_to IN ('player', 'coach', 'GK', 'DEF', 'LAT', 'MID', 'ATA')),
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE player_match_stats (
  id TEXT PRIMARY KEY,
  player_id TEXT NOT NULL,
  match_id TEXT NOT NULL,
  goals INTEGER NOT NULL DEFAULT 0,
  assists INTEGER NOT NULL DEFAULT 0,
  clean_sheet INTEGER NOT NULL DEFAULT 0,
  difficult_saves INTEGER NOT NULL DEFAULT 0,
  yellow_cards INTEGER NOT NULL DEFAULT 0,
  red_cards INTEGER NOT NULL DEFAULT 0,
  points REAL NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE (player_id, match_id),
  FOREIGN KEY (player_id) REFERENCES players(id),
  FOREIGN KEY (match_id) REFERENCES matches(id)
);

CREATE TABLE coach_match_stats (
  id TEXT PRIMARY KEY,
  coach_id TEXT NOT NULL,
  match_id TEXT NOT NULL,
  points REAL NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE (coach_id, match_id),
  FOREIGN KEY (coach_id) REFERENCES coaches(id),
  FOREIGN KEY (match_id) REFERENCES matches(id)
);

CREATE TABLE fantasy_teams (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  phase_id TEXT NOT NULL,
  coach_id TEXT,
  captain_player_id TEXT,
  total_points REAL NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE (user_id, phase_id),
  FOREIGN KEY (user_id) REFERENCES app_users(id),
  FOREIGN KEY (phase_id) REFERENCES tournament_phases(id),
  FOREIGN KEY (coach_id) REFERENCES coaches(id),
  FOREIGN KEY (captain_player_id) REFERENCES players(id)
);

CREATE TABLE fantasy_team_players (
  id TEXT PRIMARY KEY,
  fantasy_team_id TEXT NOT NULL,
  player_id TEXT NOT NULL,
  slot_index INTEGER NOT NULL,
  is_captain INTEGER NOT NULL DEFAULT 0,
  points REAL NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE (fantasy_team_id, player_id),
  UNIQUE (fantasy_team_id, slot_index),
  FOREIGN KEY (fantasy_team_id) REFERENCES fantasy_teams(id),
  FOREIGN KEY (player_id) REFERENCES players(id)
);

CREATE TABLE user_phase_scores (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  phase_id TEXT NOT NULL,
  fantasy_team_id TEXT NOT NULL,
  base_points REAL NOT NULL DEFAULT 0,
  captain_bonus_points REAL NOT NULL DEFAULT 0,
  total_points REAL NOT NULL DEFAULT 0,
  calculated_at TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE (user_id, phase_id),
  FOREIGN KEY (user_id) REFERENCES app_users(id),
  FOREIGN KEY (phase_id) REFERENCES tournament_phases(id),
  FOREIGN KEY (fantasy_team_id) REFERENCES fantasy_teams(id)
);

CREATE TABLE leagues (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  invite_code TEXT NOT NULL UNIQUE,
  owner_user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (owner_user_id) REFERENCES app_users(id)
);

CREATE TABLE league_members (
  id TEXT PRIMARY KEY,
  league_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  joined_at TEXT NOT NULL,
  UNIQUE (league_id, user_id),
  FOREIGN KEY (league_id) REFERENCES leagues(id),
  FOREIGN KEY (user_id) REFERENCES app_users(id)
);

CREATE TABLE rankings (
  id TEXT PRIMARY KEY,
  scope TEXT NOT NULL CHECK (scope IN ('global', 'league')),
  league_id TEXT,
  phase_id TEXT,
  user_id TEXT NOT NULL,
  position INTEGER NOT NULL,
  total_points REAL NOT NULL DEFAULT 0,
  calculated_at TEXT NOT NULL,
  UNIQUE (scope, league_id, phase_id, user_id),
  FOREIGN KEY (league_id) REFERENCES leagues(id),
  FOREIGN KEY (phase_id) REFERENCES tournament_phases(id),
  FOREIGN KEY (user_id) REFERENCES app_users(id)
);

CREATE TABLE player_popularity_snapshots (
  id TEXT PRIMARY KEY,
  player_id TEXT NOT NULL,
  phase_id TEXT,
  selected_count INTEGER NOT NULL DEFAULT 0,
  selected_percentage REAL NOT NULL DEFAULT 0,
  captured_at TEXT NOT NULL,
  FOREIGN KEY (player_id) REFERENCES players(id),
  FOREIGN KEY (phase_id) REFERENCES tournament_phases(id)
);
