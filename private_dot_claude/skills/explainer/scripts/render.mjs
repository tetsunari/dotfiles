// ビルド時の描画器。HTML の殻を一時 http サーバで配信し、agent-browser で開いて
// Markdown・Mermaid・D2 を描画させ、描画後の DOM を静的 HTML として書き出す。
//
// file:// では D2 の WASM Worker が起動しないため、描画は必ず http 経由で行う。
// 書き出した HTML は CDN もスクリプトも使わないので、オフラインで開ける。
//
//   import { render } from './render.mjs';
//   const r = await render({ body, css, title, outFile, mode: 'doc' | 'slides', shots: '<dir>' });
//   r.problems: 文字列の配列（空なら合格）, r.figures: 図ごとの { kind, layout, render, error, facts }
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { createServer } from 'node:http';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, extname, join } from 'node:path';

export const TIMEOUT_MS = 30000;

const MIME = { '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.webp': 'image/webp', '.svg': 'image/svg+xml' };
// ![説明](path) と ![説明](path "題")。verify-doc の存在確認と build の埋め込みで同じものを使う
export const IMAGE_RE = /(!\[[^\]]*\]\()([^)\s]+)((?:\s+"[^"]*")?\))/g;
// [文字](x.md) / (x.md#a)。日本語のファイル名も含む
export const MD_LINK_RE = /\]\(([^)\s#:]+?)\.md(#[^)\s]*)?\)/g;

// Markdown の中のローカル画像を data URI にし、.d2 / .mmd はフェンスに展開する（dir は Markdown のあるディレクトリ）
export function inlineImages(md, dir) {
  return md.replace(IMAGE_RE, (all, a, src, b) => {
    if (/^(https?:|data:)/.test(src)) return all;
    const file = join(dir, src);
    if (!existsSync(file)) return all; // verify-doc が落とす
    if (/\.(d2|mmd)$/.test(src)) {
      const text = readFileSync(file, 'utf8').trimEnd();
      if (src.endsWith('.mmd')) return '\n```mermaid\n' + text + '\n```\n';
      const layout = text.match(/layout-engine:\s*(elk|dagre)/)?.[1] ?? 'dagre';
      return '\n```d2 ' + layout + '\n' + text + '\n```\n';
    }
    const mime = MIME[extname(src).toLowerCase()];
    return mime ? `${a}data:${mime};base64,${readFileSync(file).toString('base64')}${b}` : all;
  });
}
const SESSION = `explainer-render-${process.pid}`;

// ブラウザで動く描画スクリプト。data-build 付きなので書き出し時に取り除かれる
const CLIENT = String.raw`
const esc = (s) => s.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;');
const sources = document.querySelectorAll('script.md-src');
if (sources.length) {
  const { marked } = await import('https://esm.sh/marked@16');
  marked.use({ renderer: { code({ text, lang }) {
    const [kind, layout] = (lang || '').split(/\s+/);
    if (kind === 'mermaid' || kind === 'd2')
      return '<div class="fig" data-kind="' + kind + '" data-layout="' + (layout || 'dagre') + '" data-src="' + esc(text) + '"></div>';
    return false;
  } } });
  for (const el of sources) {
    const box = document.createElement(el.dataset.tag || 'div');
    box.className = el.dataset.class || 'content';
    box.innerHTML = marked.parse(JSON.parse(el.textContent));
    el.replaceWith(box);
  }
}
let d2, mermaid;
const dark = document.body.dataset.dark === 'auto';
for (const el of document.querySelectorAll('.fig')) {
  try {
    if (el.dataset.kind === 'd2') {
      if (!d2) { const { D2 } = await import('https://esm.sh/@d2lang/d2'); d2 = new D2(); }
      // 資料（data-dark=auto）ではダーク用の配色を SVG に同梱する。SVG 内の media query で切り替わる
      const r = await d2.compile(el.dataset.src, { layout: el.dataset.layout || 'dagre', pad: 20, ...(dark ? { darkThemeId: 200 } : {}) });
      el.dataset.facts = JSON.stringify({
        shapes: (r.diagram.shapes || []).map((s) => ({ id: s.id, label: s.label })),
        // 矢印の向きは srcArrow / dstArrow で決まる（a <- b は src=a, dst=b, srcArrow 付き）。'none' は矢印なし
        edges: (r.diagram.connections || []).map((c) => [c.src, c.dst, c.label || '', c.srcArrow !== 'none', c.dstArrow !== 'none']),
      });
      el.innerHTML = await d2.render(r.diagram, r.renderOptions);
      // D2 の SVG は width を持たず親の幅まで拡大されるため、自然サイズに止める（狭い画面では CSS の max-width で縮む）
      const svg = el.querySelector('svg');
      const vb = svg && svg.viewBox.baseVal;
      if (vb && vb.width) svg.style.width = vb.width + 'px';
    } else {
      if (!mermaid) mermaid = (await import('https://esm.sh/mermaid@11')).default;
      const draw = async (theme) => {
        mermaid.initialize({ startOnLoad: false, theme });
        return (await mermaid.render('m' + Math.random().toString(36).slice(2), el.dataset.src)).svg;
      };
      // Mermaid の SVG は背景が透明で、ライトの配色のままダークのページに置くと線と文字が背景に沈む。両方描いて CSS で切り替える
      el.innerHTML = dark
        ? '<div class="theme-light">' + await draw('default') + '</div><div class="theme-dark">' + await draw('dark') + '</div>'
        : await draw('default');
    }
    el.dataset.render = 'ok';
  } catch (e) {
    el.dataset.render = 'error';
    el.dataset.error = String(e && e.message || e).slice(0, 300);
  }
}
document.body.dataset.rendered = 'done';
`;

// 描画後の検査。mode=slides ではスライド枠からのはみ出しと図の縮小率も見る
const CHECK = (mode) => `(() => {
  const out = { figures: [], overflowX: false, outside: [], small: [] };
  document.querySelectorAll('.fig').forEach((el, i) => out.figures.push({
    i, kind: el.dataset.kind, layout: el.dataset.layout, render: el.dataset.render || 'none',
    error: el.dataset.error || null, facts: el.dataset.facts ? JSON.parse(el.dataset.facts) : null }));
  out.overflowX = document.documentElement.scrollWidth > window.innerWidth + 1;
  if (${JSON.stringify(mode)} === 'slides') {
    document.querySelectorAll('section.slide').forEach((s, n) => {
      const f = s.getBoundingClientRect();
      for (const el of s.querySelectorAll('h1,h2,h3,p,li,pre,table,img,.fig')) {
        const r = el.getBoundingClientRect();
        if (r.width === 0 && r.height === 0) continue;
        if (r.left < f.left - 1 || r.right > f.right + 1 || r.top < f.top - 1 || r.bottom > f.bottom + 1)
          out.outside.push({ slide: n + 1, el: el.tagName.toLowerCase() + (el.className ? '.' + el.className : ''),
            text: (el.textContent || '').trim().slice(0, 40) });
      }
      s.querySelectorAll('.fig > svg, .fig > .theme-light > svg').forEach((svg) => {
        const vb = svg.viewBox && svg.viewBox.baseVal;
        if (!vb || !vb.width || !vb.height) return;
        // 幅と高さのどちらで縮んだかに関わらず、描画される倍率は小さい方で決まる
        const r = svg.getBoundingClientRect();
        const ratio = Math.min(r.width / vb.width, r.height / vb.height);
        if (ratio < 0.5) out.small.push({ slide: n + 1, ratio: Math.round(ratio * 100) / 100 });
      });
    });
  } else {
    // 資料では本文の幅に縮められる。D2 の文字は自然サイズで約 16px なので、0.7 倍（約 11px）を下限にする
    document.querySelectorAll('.fig > svg, .fig > .theme-light > svg').forEach((svg, n) => {
      const vb = svg.viewBox && svg.viewBox.baseVal;
      if (!vb || !vb.width) return;
      const ratio = svg.getBoundingClientRect().width / vb.width;
      if (ratio < 0.7) out.small.push({ fig: n + 1, ratio: Math.round(ratio * 100) / 100 });
    });
  }
  return out;
})()`;

const EXPORT = `(() => {
  document.querySelectorAll('[data-build]').forEach((el) => el.remove());
  document.querySelectorAll('.fig').forEach((el) => el.removeAttribute('data-src'));
  return '<!doctype html>\\n' + document.documentElement.outerHTML;
})()`;

// http サーバと同じプロセスで動くため、同期実行するとサーバが応答できず固まる。必ず非同期で呼ぶ
async function ab(args, { allowFail = false } = {}) {
  let stdout = '';
  try {
    ({ stdout } = await promisify(execFile)('agent-browser', ['--session', SESSION, '--json', ...args], { encoding: 'utf8', maxBuffer: 256 << 20 }));
  } catch (e) {
    stdout = e.stdout ?? '';
  }
  let j = null;
  try { j = JSON.parse(stdout); } catch { /* 下で扱う */ }
  if (!j || !j.success) {
    if (allowFail) return null;
    throw new Error(`agent-browser ${args[0]} failed: ${j?.error ?? stdout.trim().slice(0, 300)}`);
  }
  return j.data?.result ?? j.data;
}

// Markdown を、描画時に展開される <script> として埋め込む。</script> を含んでも壊れないよう JSON で包む
export function mdSource(md, { cls = 'content', tag = 'div' } = {}) {
  return `<script type="application/json" class="md-src" data-class="${cls}" data-tag="${tag}">${JSON.stringify(md).replace(/</g, '\\u003c')}</script>`;
}

// dark: true で、図をライト・ダーク両方の配色で描く（閲覧側の prefers-color-scheme で切り替わる）
export function shell({ title, css = '', body, script = '', dark = false }) {
  return `<!doctype html>
<html lang="ja"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title.replace(/</g, '&lt;')}</title>
<style>${css}</style></head>
<body${dark ? ' data-dark="auto"' : ''}>
${body}
${script}
<script type="module" data-build>${CLIENT}</script>
</body></html>`;
}

// viewports: [[幅, 高さ, 名前], …]。各幅でスクショを撮り、はみ出しを検査する
export async function render({ html, outFile, mode = 'doc', shots, viewports = [[1280, 800, 'desktop'], [390, 844, 'mobile']] }) {
  // 前提：agent-browser が無ければ、スタックトレースではなく 1 行で止める
  try {
    await promisify(execFile)('agent-browser', ['--version']);
  } catch {
    console.error('✗ agent-browser が見つからない。描画には agent-browser が要る（WSL 側でのみ動作確認済み）。インストールは提案せず、ユーザーに伝えて止まる');
    process.exit(2);
  }
  const server = createServer((req, res) => {
    res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
    res.end(html);
  });
  await new Promise((ok) => server.listen(0, '127.0.0.1', ok));
  const url = `http://127.0.0.1:${server.address().port}/`;
  const problems = [];
  let figures = [];
  try {
    await ab(['set', 'viewport', String(viewports[0][0]), String(viewports[0][1])]);
    await ab(['open', url]);
    if (await ab(['wait', 'body[data-rendered="done"]', '--timeout', String(TIMEOUT_MS)], { allowFail: true }) === null) {
      problems.push(`描画が ${TIMEOUT_MS / 1000} 秒で終わらなかった → ネット接続（esm.sh）か、描画スクリプトの初期化失敗を疑う`);
      return { problems, figures };
    }
    for (const [w, h, name] of viewports) {
      await ab(['set', 'viewport', String(w), String(h)]);
      const c = await ab(['eval', CHECK(mode)]);
      figures = c.figures;
      if (c.overflowX) problems.push(`${name}(${w}px): ページが横にはみ出している → 幅の広い表・コード・図に overflow-x:auto を付けるか、内容を減らす`);
      for (const o of c.outside) problems.push(`${name}: スライド ${o.slide} の ${o.el}「${o.text}」が枠からはみ出している → 内容を減らすかスライドを分ける`);
      for (const s of c.small) {
        if (s.slide) problems.push(`${name}: スライド ${s.slide} の図が ${s.ratio} 倍まで縮小されている（0.5 未満）→ 図を分割するか向きを変える`);
        // 資料ではスマホ幅で縮むのは避けられないため、最初の（デスクトップの）幅でだけ判定する
        else if (name === viewports[0][2]) problems.push(`${name}: 図 ${s.fig} が ${s.ratio} 倍まで縮小され、文字が潰れる（0.7 未満）→ 図を絞る・向きを変える・ラベルを短くする`);
      }
      if (shots) {
        mkdirSync(shots, { recursive: true });
        await ab(['screenshot', join(shots, `${name}.png`), '--full']);
      }
    }
    // ダーク配色を持つ資料は、ダークモードでも 1 枚撮る（ライトだけ見ていると、暗い背景に沈む線や文字を見落とす）
    if (shots && html.includes('data-dark="auto"')) {
      await ab(['set', 'viewport', String(viewports[0][0]), String(viewports[0][1])]);
      await ab(['set', 'media', 'dark']);
      await ab(['screenshot', join(shots, `${viewports[0][2]}-dark.png`), '--full']);
    }
    figures.forEach((f) => {
      if (f.render !== 'ok') problems.push(`図 ${f.i + 1}（${f.kind}）の描画に失敗: ${f.error ?? f.render} → ソースの構文を直す`);
    });
    if (outFile) {
      mkdirSync(dirname(outFile), { recursive: true });
      writeFileSync(outFile, await ab(['eval', EXPORT]));
    }
  } finally {
    await ab(['close'], { allowFail: true });
    server.close();
  }
  return { problems, figures };
}
