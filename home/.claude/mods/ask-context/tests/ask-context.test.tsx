import { expect, test } from 'claude-code/testing'
import type { TestBody } from 'claude-code/testing'

type Option = { label: string; description: string; preview?: string }
type Question = { question: string; header: string; multiSelect: boolean; options: Option[] }

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
// 端末が狭くてサイドバーが出せない状態。標準の質問画面のプレビュー欄に解説を入れる道を通る
const narrowTerminal = (on: Parameters<TestBody>[1]): void => {
  on('ui.open', () => ({ value: { isPlaced: false as const, reason: '144 桁未満' } }))
  on('ui.close', () => ({ value: undefined }))
}

const answering = (text: string) => () => ({ value: { isAnswered: true as const, text, usage: USAGE } })

test('選択肢ごとのプレビュー欄に、その選択肢の結果と質問の解説が入り、質問文と選択肢は変わらない', async ($, on) => {
  narrowTerminal(on)
  let shown: Question[] = []

  on('model.fork', answering(explained('罰金', '延長')))
  on('process.run', () => ({ value: SLEPT }))
  on('tool.call', (_, e) => {
    if (e.tool !== 'AskUserQuestion') return { result: {} }
    shown = e.questions

    return { result: { questions: e.questions, answers: { '罰金 はどうする？': 'する' } } }
  })

  const ran = await $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金'), asking('延長')] })

  expect(shown.map(q => q.options.map(o => o.preview))).toEqual([
    ['**これを選ぶと** 罰金をする場合\n\n**要するに** 罰金の話', '**これを選ぶと** 罰金をしない場合\n\n**要するに** 罰金の話'],
    ['**これを選ぶと** 延長をする場合\n\n**要するに** 延長の話', '**これを選ぶと** 延長をしない場合\n\n**要するに** 延長の話'],
  ])
  expect(shown.map(q => q.question)).toEqual(['罰金 はどうする？', '延長 はどうする？'])
  expect(shown.map(q => q.options.map(o => [o.label, o.description]))).toEqual([
    [
      ['する', 'キーで弾く'],
      ['しない', '現状のまま'],
    ],
    [
      ['する', 'キーで弾く'],
      ['しない', '現状のまま'],
    ],
  ])
  expect((ran.result as { answers: unknown }).answers).toEqual({ '罰金 はどうする？': 'する' })
})

test('複数選択の質問はそのままにして、同じ画面の単一選択の質問にだけ解説を入れる', async ($, on) => {
  narrowTerminal(on)
  let shown: Question[] = []

  on('model.fork', answering(explained('罰金', '通知先')))
  on('process.run', () => ({ value: SLEPT }))
  on('tool.call', (_, e) => {
    if (e.tool !== 'AskUserQuestion') return { result: {} }
    shown = e.questions

    return { result: { questions: e.questions, answers: {} } }
  })

  await $.tool.call({
    tool: 'AskUserQuestion',
    questions: [asking('罰金'), asking('通知先', { multiSelect: true })],
  })

  expect(shown[0]?.options.every(o => o.preview !== undefined)).toBe(true)
  expect(shown[1]?.options.map(o => o.preview)).toEqual([undefined, undefined])
})

test('Claude が付けたプレビューは残し、解説はその下に足す', async ($, on) => {
  narrowTerminal(on)
  let shown: Question[] = []

  on('model.fork', answering(explained('罰金')))
  on('process.run', () => ({ value: SLEPT }))
  on('tool.call', (_, e) => {
    if (e.tool !== 'AskUserQuestion') return { result: {} }
    shown = e.questions

    return { result: { questions: e.questions, answers: {} } }
  })

  await $.tool.call({
    tool: 'AskUserQuestion',
    questions: [
      asking('罰金', {
        options: [
          { label: 'する', description: 'キーで弾く', preview: '画面の案A' },
          { label: 'しない', description: '現状のまま' },
        ],
      }),
    ],
  })

  expect(shown[0]?.options[0]?.preview).toBe('画面の案A\n\n---\n\n**これを選ぶと** 罰金をする場合\n\n**要するに** 罰金の話')
})

test('解説が選択肢ごとに分かれていない質問は、どの選択肢にもその質問の解説を全部出す', async ($, on) => {
  narrowTerminal(on)
  let shown: Question[] = []

  on('model.fork', answering('=== 1 ===\n罰金の解説だけ'))
  on('process.run', () => ({ value: SLEPT }))
  on('tool.call', (_, e) => {
    if (e.tool !== 'AskUserQuestion') return { result: {} }
    shown = e.questions

    return { result: { questions: e.questions, answers: {} } }
  })

  await $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金')] })

  expect(shown[0]?.options.map(o => o.preview)).toEqual(['罰金の解説だけ', '罰金の解説だけ'])
})

test('解説が質問の数どおりに分かれていないときは、何も足さずに質問を出す', async ($, on) => {
  narrowTerminal(on)
  let shown: Question[] = []

  on('model.fork', answering(explained('罰金')))
  on('process.run', () => ({ value: SLEPT }))
  on('ui.toast', () => ({ value: undefined }))
  on('tool.call', (_, e) => {
    if (e.tool !== 'AskUserQuestion') return { result: {} }
    shown = e.questions

    return { result: { questions: e.questions, answers: {} } }
  })

  await $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金'), asking('延長')] })

  expect(shown).toEqual([asking('罰金'), asking('延長')])
})

test('解説を作れなかったときは、何も足さずに質問を出す', async ($, on) => {
  narrowTerminal(on)
  let shown: Question[] = []

  on('model.fork', () => ({ value: { isAnswered: false, reason: 'nothing-to-fork' } }))
  on('process.run', () => ({ value: SLEPT }))
  on('ui.toast', () => ({ value: undefined }))
  on('tool.call', (_, e) => {
    if (e.tool !== 'AskUserQuestion') return { result: {} }
    shown = e.questions

    return { result: { questions: e.questions, answers: {} } }
  })

  await $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金')] })

  expect(shown).toEqual([asking('罰金')])
})

test('解説が60秒たっても返らなければ、待つのをやめて何も足さずに質問を出す', async ($, on) => {
  narrowTerminal(on)
  let shown: Question[] = []
  let sleeps = 0

  on('model.fork', () => new Promise<never>(() => undefined))
  // 0.25 秒の sleep が 240 回で 60 秒
  on('process.run', () => {
    sleeps += 1

    return { value: SLEPT }
  })
  on('ui.toast', () => ({ value: undefined }))
  on('tool.call', (_, e) => {
    if (e.tool !== 'AskUserQuestion') return { result: {} }
    shown = e.questions

    return { result: { questions: e.questions, answers: {} } }
  })

  await $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金')] })

  expect(sleeps).toBe(240)
  expect(shown).toEqual([asking('罰金')])
})

test('待つための sleep が使えない環境では、解説が返るまで待ってから解説付きで出す', async ($, on) => {
  narrowTerminal(on)
  let shown: Question[] = []

  on('model.fork', answering(explained('罰金')))
  on('process.run', () => ({ deny: 'sleep: command not found' }))
  on('tool.call', (_, e) => {
    if (e.tool !== 'AskUserQuestion') return { result: {} }
    shown = e.questions

    return { result: { questions: e.questions, answers: {} } }
  })

  await $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金')] })

  expect(shown[0]?.options.every(o => o.preview !== undefined)).toBe(true)
})

test('サブエージェントが出した質問には手を付けず、解説も作らない', async ($, on) => {
  narrowTerminal(on)
  let shown: Question[] = []
  let forks = 0

  on('model.fork', () => {
    forks += 1

    return { value: { isAnswered: true as const, text: explained('罰金'), usage: USAGE } }
  })
  on('process.run', () => ({ value: SLEPT }))
  on('tool.call', (_, e) => {
    if (e.tool !== 'AskUserQuestion') return { result: {} }
    shown = e.questions

    return { result: { questions: e.questions, answers: {} } }
  })

  await $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金')], agentId: 'a1' })

  expect(forks).toBe(0)
  expect(shown).toEqual([asking('罰金')])
})

test('解説役には、全部の質問と、質問・選択肢ごとに区切る指示が渡る', async ($, on) => {
  narrowTerminal(on)
  let forkPrompt = ''

  on('model.fork', (_, e) => {
    forkPrompt = e.prompt

    return { value: { isAnswered: true as const, text: explained('罰金', '延長'), usage: USAGE } }
  })
  on('process.run', () => ({ value: SLEPT }))
  on('tool.call', (_, e) => (e.tool === 'AskUserQuestion' ? { result: { questions: e.questions, answers: {} } } : { result: {} }))

  await $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金'), asking('延長')] })

  expect(forkPrompt).toContain('罰金 はどうする？')
  expect(forkPrompt).toContain('延長 はどうする？')
  expect(forkPrompt).toContain('=== 番号 ===')
  expect(forkPrompt).toContain('--- 番号 ---')
})

const shownWith = async (
  $: Parameters<TestBody>[0],
  on: Parameters<TestBody>[1],
  text: string,
  questions: Question[],
): Promise<Question[]> => {
  let shown: Question[] = []
  narrowTerminal(on)
  on('model.fork', answering(text))
  on('process.run', () => ({ value: SLEPT }))
  on('ui.toast', () => ({ value: undefined }))
  on('tool.call', (_, e) => {
    if (e.tool !== 'AskUserQuestion') return { result: {} }
    shown = e.questions

    return { result: { questions: e.questions, answers: {} } }
  })
  await $.tool.call({ tool: 'AskUserQuestion', questions })

  return shown
}

test('質問の区切りの番号が順番どおりでないときは、取り違えを避けて何も足さない', async ($, on) => {
  const reversed = '=== 2 ===\n延長の解説\n=== 1 ===\n罰金の解説'

  expect(await shownWith($, on, reversed, [asking('罰金'), asking('延長')])).toEqual([asking('罰金'), asking('延長')])
})

test('選択肢の区切りの番号が順番どおりでないときは、その質問の共通の解説だけを出す', async ($, on) => {
  const reversed = '=== 1 ===\n罰金の共通の解説\n--- 2 ---\nしない場合\n--- 1 ---\nする場合'
  const shown = await shownWith($, on, reversed, [asking('罰金')])

  expect(shown[0]?.options.map(o => o.preview)).toEqual(['罰金の共通の解説', '罰金の共通の解説'])
})

test('選択肢の解説が足りないときは、ほかの選択肢の解説を混ぜずに共通の解説だけを出す', async ($, on) => {
  const oneOfTwo = '=== 1 ===\n罰金の共通の解説\n--- 1 ---\nする場合'
  const shown = await shownWith($, on, oneOfTwo, [asking('罰金')])

  expect(shown[0]?.options.map(o => o.preview)).toEqual(['罰金の共通の解説', '罰金の共通の解説'])
})

test('選択肢の解説が空のときは、空の見出しを出さずに共通の解説だけを出す', async ($, on) => {
  const emptyFirst = '=== 1 ===\n罰金の共通の解説\n--- 1 ---\n\n--- 2 ---\nしない場合'
  const shown = await shownWith($, on, emptyFirst, [asking('罰金')])

  expect(shown[0]?.options.map(o => o.preview)).toEqual(['罰金の共通の解説', '罰金の共通の解説'])
})

test('質問の解説が丸ごと空のときは、その質問には何も足さない', async ($, on) => {
  const shown = await shownWith($, on, '=== 1 ===\n', [asking('罰金')])

  expect(shown[0]?.options.map(o => o.preview)).toEqual([undefined, undefined])
})

test('質問が全部複数選択のときは、解説を作らずにすぐ質問を出す', async ($, on) => {
  narrowTerminal(on)
  let forks = 0

  on('model.fork', () => {
    forks += 1

    return { value: { isAnswered: true as const, text: explained('通知先'), usage: USAGE } }
  })
  on('tool.call', (_, e) => (e.tool === 'AskUserQuestion' ? { result: { questions: e.questions, answers: {} } } : { result: {} }))

  await $.tool.call({ tool: 'AskUserQuestion', questions: [asking('通知先', { multiSelect: true })] })

  expect(forks).toBe(0)
})

test('sleep が失敗で終わる環境では、数えるのをやめて解説が返るまで待つ', async ($, on) => {
  narrowTerminal(on)
  let shown: Question[] = []
  let sleeps = 0
  let answer = (_: { isAnswered: true; text: string; usage: typeof USAGE }): void => undefined

  on(
    'model.fork',
    () =>
      new Promise<{ value: { isAnswered: true; text: string; usage: typeof USAGE } }>(resolve => {
        answer = value => resolve({ value })
      }),
  )
  // 失敗で即座に返る sleep。数え続けると 240 回が一瞬で尽きて、解説を待たずに諦めてしまう
  on('process.run', () => {
    sleeps += 1
    if (sleeps === 1) void Promise.resolve().then(() => Promise.resolve()).then(() => Promise.resolve()).then(() => answer({ isAnswered: true, text: explained('罰金'), usage: USAGE }))

    return { value: { ...SLEPT, exitCode: 1 } }
  })
  on('ui.toast', () => ({ value: undefined }))
  on('tool.call', (_, e) => {
    if (e.tool !== 'AskUserQuestion') return { result: {} }
    shown = e.questions

    return { result: { questions: e.questions, answers: {} } }
  })

  await $.tool.call({ tool: 'AskUserQuestion', questions: [asking('罰金')] })

  expect(sleeps).toBe(1)
  expect(shown[0]?.options.every(o => o.preview !== undefined)).toBe(true)
})
