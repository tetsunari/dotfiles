// サイドバーで答えている最中の質問。サイドバーは同時に1つしか出せないので、1件だけ持つ
export type AskOption = { label: string; description: string; preview?: string }
export type AskQuestion = { question: string; header: string; options: AskOption[]; multiSelect: boolean }
export type Asking = {
  // どの AskUserQuestion の呼び出しの質問か
  id: string
  questions: AskQuestion[]
  // 質問ごとの解説。undefined は作成中、null は作れなかった
  blocks?: string[] | null
  index: number
  focusedOption?: number
  // 複数選択の質問で、いまチェックが付いている選択肢の番号。質問の順に並ぶ
  picked: number[][]
  answers: Record<string, string>
  outcome?: 'answered' | 'dismissed'
}

declare module 'claude-code' {
  interface PluginState {
    'ask-context': { asking: Shaped<Asking | null> }
  }
}
