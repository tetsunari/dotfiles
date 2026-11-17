#!/usr/bin/env node
// D2 の図を描画し、「描かれたもの」を事実シートと突き合わせる。d2 の CLI は使わない
// （explainer の render.mjs で、ブラウザ上の公式 WASM 版 @d2lang/d2 に描かせる）。
//
//   node d2-check.mjs <x.d2> [--expect <x.facts.json>] [--layout dagre|elk] [--svg <out.svg>] [--shots <dir>]
//
// シート無しでも落とすもの:
//   - 描画の失敗（構文エラー）
//   - 同じ名前の箱が 2 つ（スコープ外の名前を書くと、D2 は黙って新しい箱を作る）
// 警告: どの辺もつながっていない箱（allowOrphans で除外）
//
// シート（JSON）:
//   { "boxes": ["gateway"], "deps": ["gateway->orders"], "forbidden": ["orders->billing"],
//     "containers": { "cluster": ["orders"] }, "exhaustive": true, "allowOrphans": ["legend"] }
//   名前は id の末尾 → ラベルの完全一致 → id かラベルの部分一致（1 つに絞れるときだけ）の順で探す。
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { parseArgs } from 'node:util';
import { render, shell } from '../../explainer/scripts/render.mjs';

const { values: opt, positionals } = parseArgs({
  allowPositionals: true,
  options: { expect: { type: 'string' }, layout: { type: 'string' }, svg: { type: 'string' }, shots: { type: 'string' } },
});
if (!positionals[0]) {
  console.error('usage: node d2-check.mjs <x.d2> [--expect x.facts.json] [--layout dagre|elk] [--svg out.svg] [--shots dir]');
  process.exit(2);
}
const file = resolve(positionals[0]);
const src = readFileSync(file, 'utf8');
const layout = opt.layout ?? src.match(/layout-engine:\s*(elk|dagre)/)?.[1] ?? 'dagre';

let failures = 0;
const ok = (m) => console.log(`  ✓ ${m}`);
const ng = (m, fix) => { failures++; console.log(`  ✗ ${m}${fix ? `\n    → ${fix}` : ''}`); };
const warn = (m) => console.log(`  △ ${m}`);

const esc = (s) => s.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;');
const css = 'body{margin:0;padding:16px;background:#fff} .fig svg{max-width:100%;height:auto}';
const outHtml = join(mkdtempSync(join(tmpdir(), 'd2-check-')), 'fig.html');
const { problems, figures } = await render({
  html: shell({ title: 'd2-check', css, body: `<div class="fig" data-kind="d2" data-layout="${layout}" data-src="${esc(src)}"></div>` }),
  outFile: outHtml, shots: opt.shots, viewports: [[1280, 800, 'desktop'], [390, 844, 'mobile']],
});
console.log(`${file} (layout: ${layout})`);
for (const p of problems.filter((p) => !p.includes('ページが横にはみ出している'))) ng(p);
const facts = figures[0]?.facts;
if (!facts) { console.log(`\nverdict: NOT CLEAN`); process.exit(1); }

if (opt.svg) {
  const html = readFileSync(outHtml, 'utf8');
  writeFileSync(opt.svg, html.slice(html.indexOf('<svg'), html.lastIndexOf('</svg>') + 6));
  ok(`SVG → ${opt.svg}`);
}

const shapes = facts.shapes;
const last = (id) => id.split('.').at(-1);
const isContainer = (id) => shapes.some((s) => s.id.startsWith(id + '.'));
// sa / da は src / dst 側に矢印があるか。a <- b は src=a, dst=b, sa=true（向きは b->a）
const edges = facts.edges.map(([a, b, label, sa, da]) => ({ a, b, label, sa, da }));
// 辺が表す向き付きの対。向きなし（--）は空
const arrows = (e) => [...(e.da ? [[e.a, e.b]] : []), ...(e.sa ? [[e.b, e.a]] : [])];
const show = (e) => `${e.a}${e.sa && e.da ? '<->' : e.da ? '->' : e.sa ? '<-' : '--'}${e.b}`;

// ---- シート無しの検査 ----------------------------------------------------------
const byName = new Map();
for (const s of shapes) byName.set(last(s.id), [...(byName.get(last(s.id)) ?? []), s.id]);
for (const [name, ids] of byName)
  if (ids.length > 1) ng(`「${name}」の箱が ${ids.length} つある: ${ids.join(', ')}`,
    'スコープ外の名前を書いて新しい箱ができた可能性が高い。コンテナをまたぐ辺はルートでフルパス（edge.gateway -> cluster.orders）か、内側から _. で書く');
const sheet = opt.expect ? JSON.parse(readFileSync(resolve(opt.expect), 'utf8')) : {};
for (const s of shapes) {
  if (isContainer(s.id)) continue;
  if (!edges.some((e) => e.a === s.id || e.b === s.id) && !(sheet.allowOrphans ?? []).includes(last(s.id)))
    warn(`${s.id} にはどの辺もつながっていない（意図したものなら allowOrphans に書く）`);
}

// ---- シート照合 ----------------------------------------------------------------
function find(name) {
  let hit = shapes.filter((s) => last(s.id) === name);
  if (hit.length === 1) return { id: hit[0].id };
  hit = shapes.filter((s) => s.label === name);
  if (hit.length === 1) return { id: hit[0].id, how: `ラベル "${hit[0].label}" に一致` };
  hit = shapes.filter((s) => s.id.includes(name) || (s.label ?? '').includes(name));
  if (hit.length === 1) return { id: hit[0].id, how: `${hit[0].id} の id かラベルの部分一致` };
  return { id: null, how: hit.length ? `${hit.length} 個に一致して絞れない` : '一致なし' };
}
const via = (r) => (r.how ? `（${r.how}）` : '');
const pair = (dep) => dep.split('->').map((x) => x.trim());
const drawn = (a, b) => edges.some((e) => arrows(e).some(([x, y]) => x === a && y === b));
const undirected = (a, b) => edges.some((e) => !e.sa && !e.da && ((e.a === a && e.b === b) || (e.a === b && e.b === a)));

if (opt.expect) {
  for (const name of sheet.boxes ?? []) {
    const r = find(name);
    r.id ? ok(`箱 ${name}${via(r)}`) : ng(`箱 ${name} が図に無い（${r.how}）`);
  }
  const listed = new Set();
  for (const dep of sheet.deps ?? []) {
    const [x, y] = pair(dep).map(find);
    if (!x.id || !y.id) { ng(`辺 ${dep}: 端の箱が見つからない ${via(x)}${via(y)}`); continue; }
    listed.add(`${x.id}->${y.id}`);
    if (drawn(x.id, y.id)) ok(`辺 ${dep}${via(x)}${via(y)}`);
    else if (drawn(y.id, x.id)) ng(`辺の向きが逆: シートは ${dep}、図は ${y.id}->${x.id}`);
    else if (undirected(x.id, y.id)) ng(`辺 ${dep} が向きなし（--）で描かれている`, `${x.id} -> ${y.id} にする`);
    else ng(`辺 ${dep} が図に無い`, `${x.id} -> ${y.id} を書く`);
  }
  for (const dep of sheet.forbidden ?? []) {
    const [x, y] = pair(dep).map(find);
    if (x.id && y.id && drawn(x.id, y.id)) ng(`描いてはいけない辺がある: ${dep}${via(x)}${via(y)}`);
  }
  for (const [c, members] of Object.entries(sheet.containers ?? {})) {
    const cr = find(c);
    if (!cr.id) { ng(`コンテナ ${c} が図に無い`); continue; }
    for (const m of members) {
      const r = find(m);
      r.id?.startsWith(cr.id + '.') ? ok(`${m} は ${c} の中`) : ng(`${m} が ${c} の中に無い（${r.id ?? r.how}）`);
    }
  }
  if (sheet.exhaustive)
    for (const e of edges) {
      const extra = arrows(e).filter(([x, y]) => !listed.has(`${x}->${y}`));
      if (extra.length || (!e.sa && !e.da)) ng(`シートに無い辺が描かれている: ${show(e)}`);
    }
}

console.log(`\nshapes: ${shapes.map((s) => s.id).join(', ')}`);
console.log(`edges:  ${edges.map((e) => `${show(e)}${e.label ? `(${e.label})` : ''}`).join(', ')}`);
if (opt.shots) console.log(`shots:  ${opt.shots}/{desktop,mobile}.png — 目で見る`);
console.log(`\nverdict: ${failures ? `NOT CLEAN (${failures} 件)` : 'CLEAN'}`);
process.exit(failures ? 1 : 0);
