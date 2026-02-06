#!/usr/bin/env node
/**
 * Genera sitemap.xml incluyendo las rutas del blog.
 * Ejecutar: node scripts/generate-sitemap.js
 * O agregar a package.json: "generate-sitemap": "node scripts/generate-sitemap.js"
 */

const fs = require('fs');
const path = require('path');

const BASE_URL = 'https://courthub.co';
const BLOG_POSTS_PATH = path.join(__dirname, '../src/app/features/blog/data/blog-posts.data.ts');

const staticPages = [
    { loc: `${BASE_URL}/`, changefreq: 'weekly', priority: '1.0' },
    { loc: `${BASE_URL}/blog`, changefreq: 'weekly', priority: '0.9' },
    { loc: `${BASE_URL}/privacidad`, changefreq: 'monthly', priority: '0.5' },
    { loc: `${BASE_URL}/terminos`, changefreq: 'monthly', priority: '0.5' }
];

function extractBlogSlugs() {
    const content = fs.readFileSync(BLOG_POSTS_PATH, 'utf8');
    const slugMatches = content.matchAll(/slug:\s*['"]([^'"]+)['"]/g);
    const slugs = [...slugMatches].map((m) => m[1]);
    const publishedAtMatches = content.matchAll(/publishedAt:\s*['"]([^'"]+)['"]/g);
    const dates = [...publishedAtMatches].map((m) => m[1]);
    return slugs.map((slug, i) => ({ slug, lastmod: dates[i] || '' }));
}

function generateSitemap() {
    const blogPosts = extractBlogSlugs();
    let urls = [
        ...staticPages.map((p) =>
            `  <url>\n    <loc>${p.loc}</loc>\n    <changefreq>${p.changefreq}</changefreq>\n    <priority>${p.priority}</priority>\n  </url>`
        ),
        ...blogPosts.map((p) => {
            const lastmod = p.lastmod ? `\n    <lastmod>${p.lastmod}</lastmod>` : '';
            return `  <url>\n    <loc>${BASE_URL}/blog/${p.slug}</loc>\n    <changefreq>monthly</changefreq>\n    <priority>0.8</priority>${lastmod}\n  </url>`;
        })
    ];

    const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.join('\n')}
</urlset>
`;

    const outPath = path.join(__dirname, '../public/sitemap.xml');
    fs.writeFileSync(outPath, sitemap);
    console.log(`Sitemap generado: ${outPath} (${staticPages.length + blogPosts.length} URLs)`);
}

generateSitemap();
