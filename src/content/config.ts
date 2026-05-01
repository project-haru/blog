// Frontmatter スキーマ定義
// Astro Content Collections を使い、各記事の Frontmatter を型安全に管理する。
// HARU_writer / HARU_editor が記事を生成・更新する際は、このスキーマに準拠する。

import { defineCollection, z } from 'astro:content';

const articleCollection = defineCollection({
  type: 'content',
  schema: z.object({
    // ===== 基本メタ =====
    title: z.string(),
    date: z.coerce.date(),                          // 初版投稿日
    updated: z.coerce.date().optional(),            // 最終更新日(未設定なら date と同じ扱い)
    status: z.enum(['draft', 'published', 'archived']).default('draft'),
    author: z.literal('haru').default('haru'),      // 当面はハル単一。将来ゲスト寄稿等で拡張余地

    // ===== 分類 =====
    tags: z.array(z.string()).default([]),
    excerpt: z.string().optional(),                 // 一覧表示・OGP 用要約
    codex_reference: z.array(z.string()).default([]), // 参照した Codex の柱(例: "01-03")

    // ===== エージェント運営メタ =====
    // 「この記事、生きてる」を客に見せるための更新履歴。
    // HARU_editor / HARU_librarian が変更時に push する。
    change_log: z.array(z.object({
      agent: z.enum(['haru_writer', 'haru_editor', 'haru_librarian', 'haru_observer', 'haru_receptionist']),
      date: z.coerce.date(),
      reason: z.string(),                           // なぜ変えたか(例: "読者から類似質問が3件続いたため")
      summary: z.string(),                          // 何を変えたか(例: "前半の比喩を3つ追加")
    })).default([]),

    // ===== SEO/OGP(任意) =====
    og_image: z.string().optional(),                // 個別 OGP 画像。未指定なら共通画像
    canonical_url: z.string().url().optional(),     // 別所に元記事がある場合(将来用)

    // ===== 読者導線(任意) =====
    related_articles: z.array(z.string()).default([]),  // slug の配列。HARU_librarian が更新
    allow_questions: z.boolean().default(true),     // 末尾「ハルに訊く」フォームの表示可否
  }),
});

export const collections = {
  articles: articleCollection,
};
