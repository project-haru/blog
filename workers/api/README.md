# Workers API 層(Phase 2 着手後に実装)

このディレクトリには、Cloudflare Workers 上で動く API ハンドラと Durable Object 定義を置く。

## 予定エンドポイント

| ルート | 役割 | Phase |
|---|---|---|
| `POST /api/ask` | 読者の質問を受け、HARU_receptionist へ繋ぐ | 2 |
| `GET /api/live-status` | 現在の活動を返す(Live Operations Panel 用) | 2 |
| `GET /api/article/:slug/history` | 記事の更新履歴 | 2 |
| `GET /api/agent/:name/log` | 特定エージェントの活動ログ | 3 |

## 予定 Durable Objects

- `HaruWriter` — 文芸記事執筆
- `HaruEditor` — 推敲・矛盾チェック
- `HaruLibrarian` — タグ付け・関連リンク
- `HaruReceptionist` — 読者対話
- `HaruObserver` — 観測・題材提案

## 予定 Cron Triggers

- 毎日 03:00 UTC: HARU_observer がアクセス・対話を集計
- 毎日 04:00 UTC: HARU_librarian が古記事のタグ・関連リンク見直し
- 週1回(土曜深夜): HARU_editor が直近公開記事を再推敲(Opus 発火)

実装は Phase 2 着手時。当面は placeholder。
