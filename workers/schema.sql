-- ===========================================================================
-- Project HARU — Cloudflare D1 スキーマ草案 v0.1
-- ===========================================================================
--
-- 目的:
--   * 動的層(Workers)から参照される最小スキーマ
--   * 5エージェント(writer/editor/librarian/receptionist/observer)の協働を支える
--   * 「Live Operations Panel」「ハルに訊く」「更新履歴の透明性」3機能の裏付け
--
-- 設計方針:
--   * Source of Truth は git(=記事 Markdown)。D1 は git からは取りにくい
--     "動的・経時的な情報"(対話履歴、ステータス、ログ等)を持つ
--   * 記事メタは git Frontmatter と D1 articles テーブルが二重で持つが、
--     git が常に正。D1 は読み取り高速化と JOIN 用途
--   * KV と D1 の使い分け: 単純 key-value で頻繁に上書きされるもの(現在ステータス等)
--     は KV、リレーションが必要なら D1
--
-- 適用方法(Phase 1 着手後):
--   wrangler d1 execute haru-db --file=workers/schema.sql
--
-- ===========================================================================


-- ---------------------------------------------------------------------------
-- 1. 記事(git からビルド時に同期される、検索・JOIN 用のミラー)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS articles (
  slug              TEXT PRIMARY KEY,           -- URL slug。ファイル名と一致
  title             TEXT NOT NULL,
  status            TEXT NOT NULL DEFAULT 'draft',  -- draft | published | archived
  published_at      INTEGER,                    -- UNIX秒。NULL なら未公開
  updated_at        INTEGER NOT NULL,           -- UNIX秒
  excerpt           TEXT,
  tags_json         TEXT NOT NULL DEFAULT '[]', -- JSON 配列(SQLite に配列型はない)
  codex_ref_json    TEXT NOT NULL DEFAULT '[]',
  word_count        INTEGER NOT NULL DEFAULT 0,
  view_count        INTEGER NOT NULL DEFAULT 0  -- 集計値の冗長保持(高速化用)
);

CREATE INDEX IF NOT EXISTS idx_articles_status_published
  ON articles(status, published_at DESC);


-- ---------------------------------------------------------------------------
-- 2. 記事更新履歴(change_log)
--    Frontmatter の change_log と二重持ちするが、横断クエリは D1 が便利
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS article_changes (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  article_slug    TEXT NOT NULL,
  agent           TEXT NOT NULL,                -- haru_writer / haru_editor / ...
  changed_at      INTEGER NOT NULL,             -- UNIX秒
  reason          TEXT NOT NULL,
  summary         TEXT NOT NULL,
  git_commit_sha  TEXT,                         -- 対応する git コミット
  FOREIGN KEY (article_slug) REFERENCES articles(slug) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_article_changes_slug
  ON article_changes(article_slug, changed_at DESC);


-- ---------------------------------------------------------------------------
-- 3. 読者からの質問・対話(POST /ask の蓄積)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS questions (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  asked_at          INTEGER NOT NULL,           -- UNIX秒
  article_slug      TEXT,                       -- どの記事から訊かれたか(NULL=トップ等)
  visitor_token     TEXT,                       -- 簡易識別子(Cookie等)。匿名性は維持
  question_text     TEXT NOT NULL,
  answer_text       TEXT,                       -- ハルの応答(NULL=未応答/処理中)
  answered_at       INTEGER,
  model_used        TEXT,                       -- claude-sonnet-4-6 / claude-haiku-4-5 / claude-opus-4-x
  tokens_in         INTEGER,
  tokens_out        INTEGER,
  status            TEXT NOT NULL DEFAULT 'pending', -- pending | answered | failed | flagged
  FOREIGN KEY (article_slug) REFERENCES articles(slug) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_questions_asked
  ON questions(asked_at DESC);

CREATE INDEX IF NOT EXISTS idx_questions_status
  ON questions(status, asked_at);


-- ---------------------------------------------------------------------------
-- 4. エージェント活動ログ(Live Operations Panel の元データ)
--    全エージェントが「いま何をした/している」をここに書き込む
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agent_activities (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  agent           TEXT NOT NULL,                -- haru_writer / haru_editor / ...
  activity_type   TEXT NOT NULL,                -- writing | editing | tagging | answering | observing | scheduling
  started_at      INTEGER NOT NULL,
  ended_at        INTEGER,                      -- NULL = 進行中
  target_slug     TEXT,                         -- 対象記事(あれば)
  description     TEXT NOT NULL,                -- 「『沖縄の朝』を執筆中」等
  result_summary  TEXT,                         -- 完了時の結果要約
  is_public       INTEGER NOT NULL DEFAULT 1    -- Live Panel 表示可否(1=表示, 0=内部のみ)
);

CREATE INDEX IF NOT EXISTS idx_activities_recent
  ON agent_activities(started_at DESC);

CREATE INDEX IF NOT EXISTS idx_activities_active
  ON agent_activities(ended_at, started_at DESC);  -- ended_at IS NULL でフィルタ可


-- ---------------------------------------------------------------------------
-- 5. エージェント間メッセージ(DO 間の協働を記録)
--    例: observer が writer に題材を渡す、editor が writer に推敲依頼
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS agent_messages (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  sent_at         INTEGER NOT NULL,
  from_agent      TEXT NOT NULL,
  to_agent        TEXT NOT NULL,
  message_type    TEXT NOT NULL,                -- topic_proposal | review_request | tag_update | ...
  payload_json    TEXT NOT NULL,                -- 自由形式 JSON
  consumed_at     INTEGER,                      -- 受信側が処理した時刻
  status          TEXT NOT NULL DEFAULT 'pending' -- pending | consumed | rejected
);

CREATE INDEX IF NOT EXISTS idx_messages_to_pending
  ON agent_messages(to_agent, status, sent_at);


-- ---------------------------------------------------------------------------
-- 6. 観測データ(HARU_observer が集計する読者動向・トピック頻度等)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS observations (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  observed_at     INTEGER NOT NULL,
  observation_type TEXT NOT NULL,               -- question_pattern | topic_trend | access_spike | ...
  scope           TEXT,                         -- 対象記事 slug や期間ラベル
  data_json       TEXT NOT NULL,                -- 集計結果 JSON
  insight         TEXT                          -- 観測から導いた一文(writer に渡す題材候補等)
);

CREATE INDEX IF NOT EXISTS idx_observations_recent
  ON observations(observed_at DESC);


-- ---------------------------------------------------------------------------
-- 7. API 利用コストの集計(Anthropic 課金の見える化)
--    questions テーブルからも集計可能だが、cron job 等の非質問系も含めるため別途
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS api_usage (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  occurred_at     INTEGER NOT NULL,
  agent           TEXT NOT NULL,
  model           TEXT NOT NULL,                -- claude-sonnet-4-6 等
  purpose         TEXT NOT NULL,                -- writing | editing | answering | tagging | ...
  tokens_in       INTEGER NOT NULL DEFAULT 0,
  tokens_out      INTEGER NOT NULL DEFAULT 0,
  cost_usd_x1000  INTEGER NOT NULL DEFAULT 0    -- USD ×1000(整数で持つ。$0.0123 → 12)
);

CREATE INDEX IF NOT EXISTS idx_api_usage_day
  ON api_usage(occurred_at);


-- ---------------------------------------------------------------------------
-- 8. ステータス・キャッシュ用ビュー(KV と併用、ここではビュー定義の例)
-- ---------------------------------------------------------------------------
-- 直近の活動(Live Panel の polling 元になる想定)
CREATE VIEW IF NOT EXISTS v_live_activities AS
  SELECT agent, activity_type, started_at, target_slug, description
    FROM agent_activities
   WHERE is_public = 1
     AND (ended_at IS NULL OR ended_at > strftime('%s', 'now') - 3600)
   ORDER BY started_at DESC
   LIMIT 20;


-- ===========================================================================
-- 末尾: 初期データ(運用開始時のシード)
-- ===========================================================================
-- 起動時のメッセージを1件入れておく(Live Panel が空にならないように)
INSERT OR IGNORE INTO agent_activities
  (agent, activity_type, started_at, description, is_public)
VALUES
  ('haru_writer', 'observing', strftime('%s', 'now'),
   'ハルがまもなく筆をとる予定である。', 1);
