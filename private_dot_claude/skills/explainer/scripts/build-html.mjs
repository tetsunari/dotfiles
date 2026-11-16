#!/usr/bin/env node
// Markdown → 自己完結 HTML（オフラインで開ける）。
//
//   node build-html.mjs <doc-dir>/README.md [<doc-dir>/01-x.md …] [--out <dir>] [--shots]
//
// - 出力先は既定で <doc-dir>/dist/。README.md は index.html、それ以外は <名前>.html
// - ```mermaid / ```d2（```d2 elk でエンジン指定）のフェンスは、ビルド時に SVG へ描画する
// - 画像はビルド時に data URI にして埋め込む（dist から相対パスが切れないように）
// - ![説明](figures/x.d2) / ![説明](figures/x.mmd) は、そのファイルを図として描画する
//   （D2 のエンジンはファイル内の `layout-engine: elk` を見る。無ければ dagre）
// - ページ間リンク（x.md / x.md#a）は x.html に書き換える
// - --shots で dist/.shots/<ページ>/{desktop,mobile}.png を残す。目で見る用
//
// 描画・はみ出し・図の失敗のどれかがあれば exit 1。
import { readFileSync } from 'node:fs';
import { basename, dirname, join, resolve } from 'node:path';
import { parseArgs } from 'node:util';
import { MD_LINK_RE, inlineImages, mdSource, render, shell } from './render.mjs';

const { values: opt, positionals } = parseArgs({
  allowPositionals: true,
  options: { out: { type: 'string' }, shots: { type: 'boolean', default: false } },
});
if (!positionals.length) {
  console.error('usage: node build-html.mjs <page.md> [...] [--out <dir>] [--shots]');
  process.exit(2);
}

const CSS = `
:root { color-scheme: light dark; --fg: #1d1d1f; --bg: #fff; --muted: #6e6e73; --line: #d2d2d7; --code: #f5f5f7; }
@media (prefers-color-scheme: dark) { :root { --fg: #f5f5f7; --bg: #161617; --muted: #a1a1a6; --line: #424245; --code: #232325; } }
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--fg);
  font: 16px/1.8 "Hiragino Sans", "Noto Sans JP", "Yu Gothic", system-ui, sans-serif; }
.content { max-width: 46rem; margin: 0 auto; padding: 2rem 1.25rem 4rem; }
h1 { font-size: 1.8rem; line-height: 1.4; } h2 { margin-top: 2.5rem; border-bottom: 1px solid var(--line); }
a { color: #0a66d8; }
pre, table { display: block; overflow-x: auto; }
pre { background: var(--code); padding: .9rem 1rem; border-radius: 6px; font-size: .88rem; line-height: 1.6; }
code { font-family: ui-monospace, "SFMono-Regular", Menlo, Consolas, monospace; }
:not(pre) > code { overflow-wrap: anywhere; } /* 長いパスがスマホ幅で横にはみ出さないように */
table { border-collapse: collapse; } th, td { border: 1px solid var(--line); padding: .35rem .7rem; vertical-align: top; }
img { max-width: 100%; height: auto; }
blockquote { margin: 1rem 0; padding: .1rem 1rem; border-left: 4px solid var(--line); color: var(--muted); }
details { border: 1px solid var(--line); border-radius: 6px; padding: .5rem .9rem; margin: .6rem 0; }
.fig { margin: 1.5rem 0; overflow-x: auto; text-align: center; }
.fig svg { max-width: 100%; height: auto; }
/* 図はライト・ダーク両方の配色で描いてある。閲覧側の設定で片方だけ見せる */
.theme-dark { display: none; }
@media (prefers-color-scheme: dark) { .theme-light { display: none; } .theme-dark { display: block; } }
`;

function inline(md, dir) {
  return inlineImages(md, dir).replace(MD_LINK_RE, (all, name, hash = '') =>
    `](${basename(name) === 'README' ? name.replace(/README$/, 'index') : name}.html${hash})`);
}

const outName = (page) => (basename(page) === 'README.md' ? 'index.html' : basename(page).replace(/\.md$/, '.html'));

let failed = 0;
for (const p of positionals) {
  const page = resolve(p);
  const dir = dirname(page);
  const outDir = resolve(opt.out ?? join(dir, 'dist'));
  const md = readFileSync(page, 'utf8');
  const title = md.match(/^#\s+(.+)$/m)?.[1] ?? basename(page);
  const html = shell({ title, css: CSS, body: mdSource(inline(md, dir), { tag: 'main' }), dark: true });
  const outFile = join(outDir, outName(page));
  const { problems } = await render({
    html, outFile, mode: 'doc',
    shots: opt.shots ? join(outDir, '.shots', outName(page).replace(/\.html$/, '')) : undefined,
  });
  if (problems.length) {
    failed++;
    console.log(`✗ ${outFile}`);
    for (const x of problems) console.log(`  ✗ ${x}`);
  } else console.log(`✓ ${outFile}`);
}
process.exit(failed ? 1 : 0);
