// Frontmatter スキーマ定義
import { defineCollection, z } from 'astro:content';

const articleCollection = defineCollection({
  type: 'content',
  schema: z.object({
    // 基本メタ
    title: z.string(),
    date: z.coerce.date(),
    updated: z.coerce.date().optional(),
    status: z.enum(['draft', 'published', 'archived']).default('draft'),
    author: z.literal('haru').default('haru'),

    // 分類
    tags: z.array(z.string()).default([]),
    excerpt: z.string().optional(),
    codex_reference: z.array(z.string()).default([]),

    // エージェント運営メタ
    change_log: z.array(z.object({
      agent: z.enum(['haru_writer', 'haru_editor', 'haru_librarian', 'haru_observer', 'haru_receptionist']),
      date: z.coerce.date(),
      reason: z.string(),
      summary: z.string(),
    })).default([]),

    // ビジュアル / SEO
    // hero_image: 未指定なら /images/articles/[slug].png を自動で使う
    hero_image: z.string().optional(),
    og_image: z.string().optional(),
    canonical_url: z.string().url().optional(),

    // 読者導線
    related_articles: z.array(z.string()).default([]),
    allow_questions: z.boolean().default(true),
  }),
});

export const collections = {
  articles: articleCollection,
};
