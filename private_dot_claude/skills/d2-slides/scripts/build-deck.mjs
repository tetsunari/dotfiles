#!/usr/bin/env node
// Markdown 1 枚 → 自己完結の HTML スライド（オフラインで開ける）。d2 の CLI は使わない。
//
//   node build-deck.mjs <deck.md> [--out <dir>] [--shots]
//
// - frontmatter（title / subtitle / author / date）と、行頭の `---` で区切ったスライド
// - 単独の `# 見出し` で始まるスライドはタイトルスライド。`##` が通常のスライドの見出し
// - ```d2（```d2 elk でエンジン指定）/ ```mermaid のフェンスは、ビルド時に SVG へ描画する
// - ローカル画像は data URI に、![説明](x.d2) / (x.mmd) は図として埋め込む
// - 出力は <out>/index.html（既定 <deck のディレクトリ>/built）。←/→/Space で送る。印刷は 1 枚 1 ページ
//
// 検査（どれかがあれば exit 1）: 図の描画失敗 / スライド枠からのはみ出し / 図の縮小率 0.5 未満
// --shots で <out>/.shots/deck.png（全スライドを縦に並べた 1 枚）を残す。目で見る用
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { parseArgs } from 'node:util';
import { inlineImages, mdSource, render, shell } from '../../explainer/scripts/render.mjs';

const { values: opt, positionals } = parseArgs({
  allowPositionals: true,
  options: { out: { type: 'string' }, shots: { type: 'boolean', default: false } },
});
if (!positionals[0]) {
  console.error('usage: node build-deck.mjs <deck.md> [--out <dir>] [--shots]');
  process.exit(2);
}
const deckFile = resolve(positionals[0]);
const outDir = resolve(opt.out ?? join(dirname(deckFile), 'built'));
let text = readFileSync(deckFile, 'utf8');

const meta = {};
const fm = text.match(/^---\n([\s\S]*?)\n---\n/);
if (fm) {
  for (const line of fm[1].split('\n')) {
    const m = line.match(/^(\w+):\s*(.*)$/);
    if (m) meta[m[1]] = m[2].trim();
  }
  text = text.slice(fm[0].length);
}

// コードフェンスの中の `---` では区切らない
const slides = [];
let cur = [];
let fence = false;
for (const line of text.split('\n')) {
  if (/^```/.test(line)) fence = !fence;
  if (!fence && /^---\s*$/.test(line)) { slides.push(cur.join('\n')); cur = []; continue; }
  cur.push(line);
}
slides.push(cur.join('\n'));
const bodies = slides.map((s) => s.trim()).filter(Boolean);

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');
const sections = bodies.map((md, i) => {
  const isTitle = /^#\s/.test(md) && !/^##/m.test(md);
  const extra = isTitle
    ? ['subtitle', 'author', 'date'].filter((k) => meta[k]).map((k) => `<p class="meta ${k}">${esc(meta[k])}</p>`).join('')
    : '';
  return `<section class="slide${isTitle ? ' title' : ''}" id="s${i + 1}">${mdSource(inlineImages(md, dirname(deckFile)), { cls: 'slide-body' })}${extra}<span class="no">${i + 1} / ${bodies.length}</span></section>`;
});

const CSS = `
* { box-sizing: border-box; }
body { margin: 0; background: #2b2b2e; font-family: "Hiragino Sans", "Noto Sans JP", "Yu Gothic", system-ui, sans-serif; color: #1d1d1f; }
.slide { position: relative; width: 1280px; height: 720px; margin: 0 auto 24px; padding: 48px 72px; background: #fff;
  display: flex; flex-direction: column; overflow: visible; }
.slide-body { flex: 1; display: flex; flex-direction: column; min-height: 0; }
.slide h1 { font-size: 56px; margin: auto 0 16px; line-height: 1.3; }
.slide h2 { font-size: 40px; margin: 0 0 24px; line-height: 1.3; }
/* Mermaid のラベルは foreignObject の中の <p> なので、本文の直下だけに効かせる（図の中に効くと文字が枠から切れる） */
.slide-body > p, .slide-body > ul > li, .slide-body > ol > li { font-size: 28px; line-height: 1.6; margin: 0 0 12px; }
.slide pre { font-size: 20px; background: #f5f5f7; padding: 16px 20px; border-radius: 8px; margin: 0 0 12px; }
.slide-body > p > img { max-width: 100%; max-height: 480px; }
.slide table { border-collapse: collapse; font-size: 24px; } .slide th, .slide td { border: 1px solid #d2d2d7; padding: 6px 12px; }
.slide .fig { flex: 1; min-height: 0; display: flex; align-items: center; justify-content: center; }
.slide .fig svg { max-width: 100%; max-height: 100%; height: auto; }
.slide.title .meta { font-size: 28px; color: #6e6e73; margin: 0 0 8px; }
.slide.title .meta:last-of-type { margin-bottom: auto; }
.slide .no { position: absolute; right: 24px; bottom: 16px; font-size: 16px; color: #a1a1a6; }
body.present { overflow: hidden; height: 100vh; display: flex; align-items: center; justify-content: center; }
body.present .slide { display: none; margin: 0; flex-shrink: 0; }
body.present .slide.on { display: flex; }
@media print { body { background: none; } body.present { display: block; height: auto; overflow: visible; }
  .slide, body.present .slide { display: flex; margin: 0; break-after: page; transform: none !important; } @page { size: 1280px 720px; margin: 0; } }
`;

// 閲覧時の送り操作。ビルド中（data-build のスクリプトが残っている間）は動かさない。検査は全スライドを並べた状態で行う
// このスクリプトは描画スクリプトより前にあるため、パース完了を待ってから data-build の有無を見る
const NAV = `<script>
addEventListener('DOMContentLoaded', () => {
  if (document.querySelector('script[data-build]')) return;
  const s = [...document.querySelectorAll('.slide')];
  let i = Math.max(0, s.findIndex((x) => '#' + x.id === location.hash));
  document.body.classList.add('present');
  const fit = () => { const k = Math.min(innerWidth / 1280, innerHeight / 720); s.forEach((x) => (x.style.transform = 'scale(' + k + ')')); };
  const show = (n) => { i = Math.max(0, Math.min(s.length - 1, n)); s.forEach((x, j) => x.classList.toggle('on', j === i)); history.replaceState(null, '', '#' + s[i].id); };
  addEventListener('keydown', (e) => {
    if (['ArrowRight', 'PageDown', ' '].includes(e.key)) show(i + 1);
    if (['ArrowLeft', 'PageUp'].includes(e.key)) show(i - 1);
  });
  addEventListener('click', (e) => show(i + (e.clientX > innerWidth / 2 ? 1 : -1)));
  addEventListener('resize', fit);
  fit(); show(i);
});
</script>`;

const title = meta.title ?? bodies[0]?.match(/^#\s+(.+)$/m)?.[1] ?? 'slides';
const outFile = join(outDir, 'index.html');
const { problems, figures } = await render({
  html: shell({ title, css: CSS, body: sections.join('\n'), script: NAV }),
  outFile, mode: 'slides',
  shots: opt.shots ? join(outDir, '.shots') : undefined,
  viewports: [[1340, 760, 'deck']],
});
if (problems.length) {
  console.log(`✗ ${outFile}: ${bodies.length} slides, ${figures.length} figure(s)`);
  for (const p of problems) console.log(`  ✗ ${p}`);
  process.exit(1);
}
console.log(`✓ ${outFile}: ${bodies.length} slides, ${figures.length} figure(s)${opt.shots ? ` — 目で見る: ${join(outDir, '.shots/deck.png')}` : ''}`);
