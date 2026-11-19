import { expect, test } from 'claude-code/testing'
import type { TestBody } from 'claude-code/testing'

type Option = { label: string; description: string; preview?: string }
type Question = { question: string; header: string; multiSelect: boolean; options: Option[] }
type On = Parameters<TestBody>[1]
// テストの環境にはあるが、mod の型定義には載っていない
declare const setTimeout: (run: () => void, ms: number) => unknown

const asking = (header: string, change: Partial<Question> = {}): Question => ({
  question: `${header} はどうする？`,
  header,
  multiSelect: false,
  options: [
    { label: 'する', description: 'キーで弾く' },
    { label: 'しない', description: '現状のまま' },
  ],
  ...change,
})

const USAGE = { input_tokens: 0, output_tokens: 0, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 }
const SLEPT = { exitCode: 0, stdout: '', stderr: '', isStdoutTruncated: false, isStderrTruncated: false }
const explained = (...headers: string[]): string =>
  headers
    .map(
      (header, i) =>
        `=== ${i + 1} ===\n**要するに** ${header}の話\n--- 1 ---\n${header}をする場合\n--- 2 ---\n${header}をしない場合`,
    )
    .join('\n')

const PANE = {
  plugin: 'ask-context',
  component: 'Pane',
  requestId: 'ask-context',
  surface: 'terminal',
  props: {
    title: '質問',
    isFocused: true,
    bodyColumns: 60,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 30 },
    view: {},
  },
} as const

// サイドバーを出せる広い端末。標準の質問画面が出たら記録する
const wideTerminal = (on: On, explanation: string | (() => Promise<never>)) => {
  const seen = { opened: 0, closed: 0, dialogs: 0 }
  let markOpened = (): void => undefined
  const opened = new Promise<void>(resolve => (markOpened = resolve))
  on('ui.open', () => {
    seen.opened += 1
    markOpened()

    return { value: { isPlaced: true as const } }
  })
  on('ui.close', () => {
    seen.closed += 1

    return { value: undefined }
  })
  on('model.fork', () =>
    typeof explanation === 'string'
      ? { value: { isAnswered: true as const, text: explanation, usage: USAGE } }
      : explanation(),
  )
  // 本物の sleep と同じく、ほかの処理に順番を回してから返す。即座に返すと待ちループが回り続けて、テストの操作が進まない
  on('process.run', () => new Promise(resolve => setTimeout(() => resolve({ value: SLEPT }), 10)))
  on('tool.call', (_, e) => {
    seen.dialogs += 1

    return e.tool === 'AskUserQuestion' ? { result: { questions: e.questions, answers: {} } } : { result: {} }
  })

  return { seen, opened }
}

test('サイドバーで選んだ答えが Claude に返り、標準の質問画面は出ない', async ($, on) => {
  const { seen, opened } = wideTerminal(on, explained('罰金', '延長'))

  const ran = $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金'), asking('延長')] })
  await opened
  const ui = await $.ui.mount(PANE)

  expect((await ui.find({ type: 'Text', text: /罰金 はどうする/ }))?.text).toBe('罰金 はどうする？')
  await ui.press({ key: 'opt:0:1' })
  expect((await ui.find({ type: 'Text', text: /延長 はどうする/ }))?.text).toBe('延長 はどうする？')
  await ui.press({ key: 'opt:1:0' })

  const result = (await ran).result as { answers: Record<string, string> }
  expect(result.answers).toEqual({ '罰金 はどうする？': 'しない', '延長 はどうする？': 'する' })
  expect(seen.dialogs).toBe(0)
  expect(seen.closed).toBe(1)
  await ui.unmount()
})

test('サイドバーには質問の解説が出る', async ($, on) => {
  const { opened } = wideTerminal(on, explained('罰金'))

  const ran = $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金')] })
  await opened
  const ui = await $.ui.mount(PANE)

  // 太字の記号は外して出す
  expect((await ui.find({ type: 'Text', text: /要するに/ }))?.text).toBe('要するに 罰金の話')
  await ui.press({ key: 'opt:0:0' })
  await ran
  await ui.unmount()
})

test('解説がまだ届いていなくても、質問はすぐサイドバーに出て答えられる', async ($, on) => {
  const { opened } = wideTerminal(on, () => new Promise<never>(() => undefined))

  const ran = $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金')] })
  await opened
  const ui = await $.ui.mount(PANE)

  expect((await ui.find({ type: 'Text', text: /解説を作っている/ }))?.text).toBe('解説を作っている…')
  await ui.press({ key: 'opt:0:0' })
  expect(((await ran).result as { answers: unknown }).answers).toEqual({ '罰金 はどうする？': 'する' })
  await ui.unmount()
})

test('複数選択は選んだものをカンマ区切りで返す', async ($, on) => {
  const { opened } = wideTerminal(on, explained('通知先'))

  const ran = $.tool.call({ tool: 'AskUserQuestion', questions: [asking('通知先', { multiSelect: true })] })
  await opened
  const ui = await $.ui.mount(PANE)

  await ui.press({ key: 'opt:0:0' })
  await ui.press({ key: 'opt:0:1' })
  await ui.press({ key: 'submit' })

  expect(((await ran).result as { answers: unknown }).answers).toEqual({ '通知先 はどうする？': 'する, しない' })
  await ui.unmount()
})

test('「その他」に書いた答えが返る', async ($, on) => {
  const { opened } = wideTerminal(on, explained('罰金'))

  const ran = $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金')] })
  await opened
  const ui = await $.ui.mount(PANE)

  await ui.input({ key: 'other:0', text: '  半額にする  ' })

  expect(((await ran).result as { answers: unknown }).answers).toEqual({ '罰金 はどうする？': '半額にする' })
  await ui.unmount()
})

test('前の質問に戻って答え直すと、答え直した方が返る', async ($, on) => {
  const { opened } = wideTerminal(on, explained('罰金', '延長'))

  const ran = $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金'), asking('延長')] })
  await opened
  const ui = await $.ui.mount(PANE)

  await ui.press({ key: 'opt:0:0' })
  await ui.press({ key: 'back' })
  await ui.press({ key: 'opt:0:1' })
  await ui.press({ key: 'opt:1:1' })

  expect(((await ran).result as { answers: unknown }).answers).toEqual({
    '罰金 はどうする？': 'しない',
    '延長 はどうする？': 'しない',
  })
  await ui.unmount()
})

test('サイドバーを開けなかった質問は標準の画面に出し、次の質問ではまたサイドバーを使う', async ($, on) => {
  let opens = 0
  let dialogs = 0
  let markOpened = (): void => undefined
  const secondOpened = new Promise<void>(resolve => (markOpened = resolve))
  // 1回目は別の plugin が同じ id のペインを持っていて開けない
  on('ui.open', () => {
    opens += 1
    if (opens === 1) return { deny: 'ask-context は別の plugin が開いている' }
    markOpened()

    return { value: { isPlaced: true as const } }
  })
  on('ui.close', () => ({ value: undefined }))
  on('ui.status', () => ({ value: undefined }))
  on('model.fork', () => ({ value: { isAnswered: true as const, text: explained('罰金'), usage: USAGE } }))
  on('process.run', () => new Promise(resolve => setTimeout(() => resolve({ value: SLEPT }), 10)))
  on('tool.call', (_, e) => {
    dialogs += 1

    return e.tool === 'AskUserQuestion' ? { result: { questions: e.questions, answers: {} } } : { result: {} }
  })

  await $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金')] })
  expect(dialogs).toBe(1)

  const ran = $.tool.call({ tool: 'AskUserQuestion', questions: [asking('延長')] })
  await secondOpened
  const ui = await $.ui.mount(PANE)
  await ui.press({ key: 'opt:0:0' })

  expect(((await ran).result as { answers: unknown }).answers).toEqual({ '延長 はどうする？': 'する' })
  expect(dialogs).toBe(1)
  await ui.unmount()
})

test('PATH に sleep が無い Windows でも、Git for Windows の sleep.exe で待ってサイドバーで答えられる', async ($, on) => {
  let markOpened = (): void => undefined
  const opened = new Promise<void>(resolve => (markOpened = resolve))
  const started: string[] = []
  on('ui.open', () => (markOpened(), { value: { isPlaced: true as const } }))
  on('ui.close', () => ({ value: undefined }))
  on('model.fork', () => ({ value: { isAnswered: true as const, text: explained('罰金'), usage: USAGE } }))
  // Windows 版 claude.exe で実測した動き: sleep は起動できず、フルパスの sleep.exe は動く
  on('process.run', (_, e) => {
    started.push(e.argv[0] ?? '')
    if (e.argv[0] === 'sleep') return { deny: "ENOENT: Command 'sleep' not found" }

    return new Promise(resolve => setTimeout(() => resolve({ value: SLEPT }), 10))
  })
  on('tool.call', () => ({ result: {} }))

  const ran = $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金')] })
  await opened
  const ui = await $.ui.mount(PANE)
  await ui.press({ key: 'opt:0:1' })

  expect(((await ran).result as { answers: unknown }).answers).toEqual({ '罰金 はどうする？': 'しない' })
  // 起動できなかった sleep は最初の1回だけ試し、あとは sleep.exe を使い続ける
  expect(started.filter(command => command === 'sleep').length).toBe(1)
  await ui.unmount()
})

test('「答えずに閉じる」を押すと、答えなしとして Claude に返す', async ($, on) => {
  const { seen, opened } = wideTerminal(on, explained('罰金'))

  const ran = $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金')] })
  await opened
  const ui = await $.ui.mount(PANE)
  await ui.press({ key: 'dismiss' })

  expect((await ran).deny).toBe('ユーザーは質問に答えずに閉じた')
  expect(seen.dialogs).toBe(0)
  await ui.unmount()
})

test('サイドバーを開いたら通知を鳴らし、Esc で閉じるペインにはしない', async ($, on) => {
  const notified: string[] = []
  const openedWith: { closeOnEscape?: true }[] = []
  let markOpened = (): void => undefined
  const opened = new Promise<void>(resolve => (markOpened = resolve))
  on('ui.open', (_, e) => (openedWith.push(e), markOpened(), { value: { isPlaced: true as const } }))
  on('ui.close', () => ({ value: undefined }))
  on('ui.notify', (_, e) => (notified.push(e.text), { value: { isSent: true as const, channel: 'terminal_bell' as const } }))
  on('model.fork', () => ({ value: { isAnswered: true as const, text: explained('罰金'), usage: USAGE } }))
  on('process.run', () => new Promise(resolve => setTimeout(() => resolve({ value: SLEPT }), 10)))
  on('tool.call', () => ({ result: {} }))

  const ran = $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金')] })
  await opened
  const ui = await $.ui.mount(PANE)
  await ui.press({ key: 'opt:0:0' })
  await ran

  expect(notified).toEqual(['質問に答えてください'])
  // 本人が Esc で閉じると「本人が開いたペイン」の扱いが消え、狭い端末で出なくなるため
  expect(openedWith[0]?.closeOnEscape).toBeUndefined()
  await ui.unmount()
})

test('/ask-context でサイドバーを開ける', async ($, on) => {
  const openedIds: string[] = []
  on('ui.open', (_, e) => (openedIds.push(e.id), { value: { isPlaced: true as const } }))

  const ran = await $.command.run({
    command: 'ask-context',
    args: '',
    origin: { kind: 'composer' },
    presentation: { isFullscreen: false, columns: 124 },
  })

  expect(openedIds).toEqual(['ask-context'])
  expect(ran.text).toContain('サイドバーを開いた')
})
