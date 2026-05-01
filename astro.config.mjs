// @ts-check
import { defineConfig } from 'astro/config';

// Cloudflare Pages 向け設定。
// Phase 1 では純粋な静的サイトとして動作させ、
// Phase 2 以降で API ルート(/ask, /live-status 等)を Workers 側に分離して構築する。

export default defineConfig({
  site: 'https://project-haru.org',
  output: 'static',                    // 当面は静的配信。動的ルートは workers/ で別管理
  trailingSlash: 'never',
  build: {
    format: 'directory',
  },
  markdown: {
    shikiConfig: {
      theme: 'github-light',
      wrap: true,
    },
  },
  // i18n は当面なし(日本語単一)
  // integrations は Phase 1 着手時に必要に応じ追加
});
