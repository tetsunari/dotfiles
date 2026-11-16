// 一枚絵の機械検査。agent-browser で開いたページに `agent-browser eval --stdin < check.js` で流す。
// 結果の n が 0 なら合格。0 でも、最後に画像を1枚目で見て確かめる（色・絵の崩れは測れない）。
(() => {
  const BOTTOM_MARGIN = 24;
  const MIN_FONT = 18;
  const R = e => e.getBoundingClientRect();
  const skip = ['title', 'desc', 'style', 'script', 'defs'];
  const name = e => {
    const t = (e.textContent || '').trim().replace(/\s+/g, '').slice(0, 12);
    const c = e.getAttribute('class');
    return e.tagName.toLowerCase() + (c ? '.' + c.split(' ')[0] : '') + (t ? '「' + t + '」' : '');
  };
  const overlap = (a, b) => {
    const x = Math.min(a.right, b.right) - Math.max(a.left, b.left);
    const y = Math.min(a.bottom, b.bottom) - Math.max(a.top, b.top);
    return x > 4 && y > 4 ? Math.round(x) + 'x' + Math.round(y) : null;
  };
  // 文字を直接持つ要素と、その字面（テキストノードだけ。子のアイコンは含めない）
  const texts = [...document.querySelectorAll('body *')].filter(e =>
    !skip.includes(e.tagName.toLowerCase()) && !e.closest('defs') &&
    [...e.childNodes].some(n => n.nodeType === 3 && n.textContent.trim()) && R(e).width > 0);
  const glyphs = e => [...e.childNodes].filter(n => n.nodeType === 3 && n.textContent.trim()).flatMap(n => {
    const r = document.createRange(); r.selectNodeContents(n); return [...r.getClientRects()];
  });
  const visibleBox = e => {
    const cs = getComputedStyle(e);
    return parseFloat(cs.borderTopWidth) > 0 || parseFloat(cs.borderBottomWidth) > 0 ||
      (cs.backgroundColor !== 'rgba(0, 0, 0, 0)' && cs.backgroundColor !== 'transparent');
  };
  const out = [];

  // 1. 画面外・下余白
  for (const t of texts) for (const g of glyphs(t)) {
    if (g.left < 0 || g.top < 0 || g.right > innerWidth || g.bottom > innerHeight - BOTTOM_MARGIN) {
      out.push('画面外または下余白不足 ' + name(t) + ' bottom=' + Math.round(g.bottom));
      break;
    }
  }
  // 2. 枠からのはみ出し（枠線か背景のある箱だけ）
  const boxes = [...document.querySelectorAll('body *')].filter(e =>
    !skip.includes(e.tagName.toLowerCase()) && !(e instanceof SVGElement) && R(e).width > 40 && visibleBox(e));
  for (const box of boxes) {
    const b = R(box);
    if (b.width >= innerWidth - 1 && b.height >= innerHeight - 1) continue; // キャンバス全体
    const kids = [...box.querySelectorAll('*')].filter(e => !skip.includes(e.tagName.toLowerCase()) && R(e).height > 0);
    const over = kids.filter(e => { const r = R(e); return r.bottom > b.bottom + 1 || r.right > b.right + 1 || r.left < b.left - 1 || r.top < b.top - 1; });
    if (over.length) out.push('枠外 ' + name(box) + ' ← ' + over.slice(0, 3).map(name).join(', '));
  }
  // 2b. 枠どうしの重なり（入れ子でない箱。付箋をわざと重ねる場合も検出されるので、目視で判断する）
  for (let i = 0; i < boxes.length; i++) for (let j = i + 1; j < boxes.length; j++) {
    const a = boxes[i], b = boxes[j];
    if (a.contains(b) || b.contains(a)) continue;
    const h = overlap(R(a), R(b));
    if (h) out.push('枠×枠 ' + name(a) + ' / ' + name(b) + ' ' + h);
  }
  // 3. 隠れ（各行の中心で最前面の要素がその文字か）
  for (const t of texts) for (const g of glyphs(t)) {
    const top = document.elementFromPoint(g.left + g.width / 2, g.top + g.height / 2);
    if (top && !(t === top || t.contains(top) || top.contains(t))) { out.push('隠れ ' + name(t) + ' ← ' + name(top)); break; }
  }
  // 4. 文字×絵（インライン SVG のルート単位）
  const svgs = [...document.querySelectorAll('svg')].filter(s => !s.parentElement.closest('svg') && R(s).width > 0);
  for (const t of texts) for (const s of svgs) {
    if (s.contains(t)) continue;
    const h = glyphs(t).map(g => overlap(g, R(s))).find(Boolean);
    if (h) out.push('文字×絵 ' + name(t) + ' / ' + name(s) + ' ' + h);
  }
  // 5. 文字×文字
  for (let i = 0; i < texts.length; i++) for (let j = i + 1; j < texts.length; j++) {
    const a = texts[i], b = texts[j];
    if (a.contains(b) || b.contains(a)) continue;
    const h = glyphs(a).flatMap(ga => glyphs(b).map(gb => overlap(ga, gb))).find(Boolean);
    if (h) out.push('文字×文字 ' + name(a) + ' / ' + name(b) + ' ' + h);
  }
  // 6. 文字サイズ
  for (const t of texts) {
    const fs = parseFloat(getComputedStyle(t).fontSize);
    if (fs < MIN_FONT) out.push('小さい文字 ' + name(t) + ' ' + fs + 'px');
  }
  // 7. 絵文字（フォントが無く豆腐になる）
  if (/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B50}]/u.test(document.body.innerText)) out.push('絵文字あり');

  const uniq = [...new Set(out)];
  return JSON.stringify({ size: [document.documentElement.scrollWidth, document.documentElement.scrollHeight], n: uniq.length, out: uniq.slice(0, 40) });
})()
