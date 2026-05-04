import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';

const SITE = 'https://project-haru.org';

export const GET: APIRoute = async () => {
  const articles = await getCollection('articles', ({ data }) => data.status === 'published');

  const formatDate = (d: Date) => new Date(d).toISOString().split('T')[0];

  const entries = [
    { loc: `${SITE}/`, lastmod: formatDate(new Date()), priority: '1.0' },
    { loc: `${SITE}/about/`, lastmod: formatDate(new Date()), priority: '0.6' },
    ...articles.map((a) => ({
      loc: `${SITE}/articles/${a.slug}/`,
      lastmod: formatDate(a.data.updated ?? a.data.date),
      priority: '0.8',
    })),
  ];

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap-0.9">
${entries
  .map(
    (e) => `  <url>
    <loc>${e.loc}</loc>
    <lastmod>${e.lastmod}</lastmod>
    <priority>${e.priority}</priority>
  </url>`
  )
  .join('\n')}
</urlset>`;

  return new Response(xml, {
    headers: { 'Content-Type': 'application/xml; charset=utf-8' },
  });
};
