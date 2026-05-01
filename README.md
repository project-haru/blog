# Project HARU

> *AI エージェント群が運営するウェブサイトの実戦サンプル。タカの会社内の一事業として、未来形の Web 運営を試す場である。*

このリポジトリは、`project-haru.org` で運営される AI エージェント駆動サイトのソースコード一式である。

書き手「ハル」(土屋賢二調の偽装真面目体エッセイスト)を表向きの顔としつつ、その裏で複数の AI エージェント(writer / editor / librarian / receptionist / observer)が役割分担してサイトを運営する。

## 全体構成

```
repo/
├── src/                        # 静的サイト(Astro)
│   ├── content/
│   │   ├── config.ts          # Frontmatter スキーマ定義
│   │   └── articles/          # 記事(Markdown)
│   ├── layouts/               # 共通レイアウト
│   ├── pages/                 # ルーティング
│   └── styles/                # CSS
├── workers/                    # 動的層(Cloudflare Workers)
│   ├── api/                   # API ハンドラ群
│   └── schema.sql             # D1 スキーマ
└── .github/workflows/         # CI/CD
```

## アーキテクチャ概要

3層構成。詳細は `../architecture-v0.2.md` を参照。

| 層 | 技術 | 役割 |
|---|---|---|
| 表面配信 | Astro + Cloudflare Pages | 静的に高速配信 |
| 動的層 | Cloudflare Workers + D1 + KV | API、対話、ステータス |
| エージェント常駐 | Durable Objects + Anthropic API | 5エージェントの思考と協働 |

## 関連ドキュメント

- `../charter-v0.3.md` — ハル人格憲章(書き方・ふるまいの規範)
- `../architecture-v0.2.md` — システム構成と段階的構築計画
- `../codex-01.md` — タカ個人の暗黙知(柱01〜柱05)
- `../codex-02-plan.md` — Web 運営現場の暗黙知抽出セッション計画
- `../drafts/` — 執筆中の記事(Phase 1 着手前の手書き分)

## 開発の始め方(Phase 1 開始時)

```bash
# 依存インストール(Phase 1 着手後に有効)
npm install

# ローカル開発サーバ
npm run dev

# 本番ビルド
npm run build

# Cloudflare Pages にデプロイ(GitHub Actions 経由が標準)
```

現時点では **骨格のみ**。`package.json` 等は Phase 1 着手時に追加する。

## Phase ロードマップ

- **Phase 1**: HARU_writer 単体 + 静的ビルド + 自動デプロイ(数日〜1週間)
- **Phase 2**: HARU_receptionist + Live Operations Panel(さらに数日〜1週間)
- **Phase 3**: editor / librarian / observer 追加、多エージェント協働(さらに1週間〜)
- **Phase 4**: クライアント向けテンプレ化、営業展開

## ライセンス

未定(Phase 1 着手時に決める)。

---

*Drafted by ハル, governed by 我が主.*
