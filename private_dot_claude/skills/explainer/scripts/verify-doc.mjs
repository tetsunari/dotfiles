#!/usr/bin/env node
// 解説資料の「主張」を道具で検査する。Node 標準ライブラリと agent-browser だけで動く。
//
//   node verify-doc.mjs <doc-dir> [--pages README.md,01-x.md,…] [--skip-html] [--shots]
//
// 1. checks  <doc-dir>/checks.json のコマンドを再実行し、終了コード（既定 0、"exit" で指定）と、
//            expect の各行が出力に順に現れるかを見る
// 2. prose   <!-- output: name --> 直後のコードブロックが、その check の実出力にあるか
//            <!-- source: path --> 直後のコードブロックが、そのファイルの一部と一致するか
//            画像リンクとページ間リンク（*.md）の参照先が存在するか
// 3. figures figures/<name>.d2 に <name>.facts.json があれば、d2-check.mjs で照合する
// 4. page    build-html.mjs で HTML に組み、図の描画失敗・横のはみ出しを見る（--skip-html で省略）
//
// どれか 1 つでも落ちれば exit 1。落ちた項目ごとに「何が・どこで・どう直すか」を出す。
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';
import { IMAGE_RE, MD_LINK_RE } from './render.mjs';

const { values: opt, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    'skip-html': { type: 'boolean', default: false },
    shots: { type: 'boolean', default: false },
    pages: { type: 'string', default: 'README.md' },
  },
});
const docDir = resolve(positionals[0] ?? '.');
const here = dirname(fileURLToPath(import.meta.url));
const env = { ...process.env, NO_COLOR: '1', FORCE_COLOR: '0' };

let failures = 0;
const ok = (msg) => console.log(`  ✓ ${msg}`);
const ng = (msg, fix) => { failures++; console.log(`  ✗ ${msg}${fix ? `\n    → ${fix}` : ''}`); };

// checks.json の cmd はシェルで実行する（パイプ等を書けるように）。stderr はシェル全体で stdout に合流させ、出た順を保つ
function sh(cmd, cwd) {
  return run('sh', ['-c', `exec 2>&1\n${cmd}`], cwd);
}
// 内部スクリプトはシェルを通さずに呼ぶ（資料のパスに $() 等があっても展開されない）
function node(args, cwd) {
  return run(process.execPath, args, cwd);
}
function run(bin, args, cwd) {
  const r = spawnSync(bin, args, { cwd, env, encoding: 'utf8', maxBuffer: 64 << 20 });
  const strip = (x) => (x ?? '').replace(/\x1b\[[0-9;]*m/g, '');
  return { code: r.status, out: strip(r.stdout) + strip(r.stderr) };
}
// needles が haystack の行に「順に」部分一致するか。最初に見つからなかった行を返す
function missingInOrder(haystack, needles) {
  const lines = haystack.split('\n');
  let i = 0;
  for (const n of needles) {
    while (i < lines.length && !lines[i].includes(n)) i++;
    if (i === lines.length) return n;
    i++;
  }
  return null;
}

// ---- 1. checks ---------------------------------------------------------------
console.log('checks (checks.json を再実行)');
const outputs = new Map();
const checksFile = join(docDir, 'checks.json');
if (existsSync(checksFile)) {
  for (const c of JSON.parse(readFileSync(checksFile, 'utf8')).checks) {
    const { code, out } = sh(c.cmd, join(docDir, c.cwd ?? '.'));
    outputs.set(c.name, out);
    const want = c.exit ?? 0;
    const tail = out.trim().split('\n').slice(-3).join(' | ');
    if (code !== want) {
      ng(`${c.name}: exit ${code}（期待 ${want}）`,
        `\`${c.cmd}\` が異常終了した。異常終了が正しい結果なら checks.json に "exit": ${code} を書く\n    output tail: ${tail}`);
      continue;
    }
    const miss = missingInOrder(out, c.expect ?? []);
    if (miss === null) ok(c.name);
    else ng(`${c.name}: 期待する行が出ない: ${JSON.stringify(miss)}`,
      `\`${c.cmd}\` を ${c.cwd ?? '.'} で実行して見比べる。道具の答えが変わったなら、それを引用した本文も間違っている\n    output tail: ${tail}`);
  }
} else console.log('  (checks.json なし)');

// ---- 2. prose ----------------------------------------------------------------
console.log('prose (本文の引用が実物と一致するか)');
const pages = opt.pages.split(',').map((x) => x.trim()).filter(Boolean);
for (const page of pages) {
  const md = readFileSync(join(docDir, page), 'utf8');
  const lineOf = (idx) => md.slice(0, idx).split('\n').length;
  for (const m of md.matchAll(/<!--\s*(output|source):\s*([^\s]+)\s*-->\s*\n```[^\n]*\n([\s\S]*?)\n```/g)) {
    const [, kind, ref, body] = m;
    const at = `${page}:${lineOf(m.index)}`;
    if (kind === 'output') {
      const out = outputs.get(ref);
      if (out === undefined) { ng(`${at}: output ブロックが未知の check "${ref}" を指している`, 'checks.json に足す'); continue; }
      const lines = body.split('\n').filter((x) => x.trim() && !x.trim().startsWith('...'));
      const miss = missingInOrder(out, lines);
      miss === null ? ok(`${at}: ${ref} の出力`) : ng(`${at}: 引用した出力を ${ref} が出していない: ${JSON.stringify(miss)}`, '実際の出力を貼る。打ち直さない');
    } else {
      const file = join(docDir, ref);
      if (!existsSync(file)) { ng(`${at}: source ${ref} が存在しない`); continue; }
      const src = readFileSync(file, 'utf8').replace(/\s+$/gm, '');
      src.includes(body.replace(/\s+$/gm, ''))
        ? ok(`${at}: ${ref} の抜粋`)
        : ng(`${at}: 抜粋が ${ref} と食い違う`, 'ファイルが変わったか、抜粋を手で直した。コピーし直す');
    }
  }
  for (const m of md.matchAll(IMAGE_RE)) {
    if (/^(https?:|data:)/.test(m[2])) continue;
    existsSync(join(docDir, m[2])) ? ok(`${page}: 画像 ${m[2]}`) : ng(`${page}: 画像 ${m[2]} が存在しない`);
  }
  for (const m of md.matchAll(MD_LINK_RE))
    if (!existsSync(join(docDir, `${m[1]}.md`))) ng(`${page}: リンク先 ${m[1]}.md が存在しない`);
}

// ---- 3. figures --------------------------------------------------------------
// figures/<name>.d2 に <name>.facts.json があれば、d2-diagram の d2-check.mjs で照合する
const figDir = join(docDir, 'figures');
const sheets = existsSync(figDir) ? readdirSync(figDir).filter((f) => f.endsWith('.d2') && existsSync(join(figDir, f.replace(/\.d2$/, '.facts.json')))) : [];
if (sheets.length) {
  console.log('figures (D2 を事実シートと照合)');
  const checker = join(here, '../../d2-diagram/scripts/d2-check.mjs');
  for (const f of sheets) {
    const r = node([checker, join(figDir, f), '--expect', join(figDir, f.replace(/\.d2$/, '.facts.json'))], docDir);
    const fails = r.out.split('\n').filter((l) => l.trim().startsWith('✗')).map((l) => l.trim().slice(2));
    r.code === 0 ? ok(`${f}: CLEAN`) : ng(`${f}: ${fails.slice(0, 3).join(' / ') || r.out.trim().split('\n').at(-1)}`, `node ${checker} figures/${f} --expect figures/${f.replace(/\.d2$/, '.facts.json')} --shots /tmp/${f}`);
  }
}

// ---- 4. page -----------------------------------------------------------------
if (!opt['skip-html']) {
  console.log('page (HTML に組み、図とはみ出しを検査)');
  const b = node([join(here, 'build-html.mjs'), ...pages.map((x) => join(docDir, x)), ...(opt.shots ? ['--shots'] : [])], docDir);
  for (const line of b.out.trim().split('\n')) {
    const t = line.trim();
    if (t.startsWith('✓')) ok(t.slice(2));
    else if (t.startsWith('✗')) ng(t.slice(2));
    else if (t) ng(`build-html: ${t}`);
  }
  if (b.code !== 0 && !b.out.includes('✗')) ng('build-html が失敗した', b.out.trim().split('\n').at(-1));
}

console.log(`\nverdict: ${failures ? `NOT VERIFIED (${failures} 件)` : 'VERIFIED'}`);
process.exit(failures ? 1 : 0);
