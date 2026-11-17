# 記事を公開するとき

Zenn や Qiita などに公開する記事を書くときは、本文の規範に加えてここを読む。

## 書く前に決めること

- 想定読者の前提知識
- 公開先（Zenn、Qiita、社内 Wiki など）

## 公開前の確認

- [ ] 主題が1つに絞られている
- [ ] タイトルと中身が合っている
- [ ] コード例を実際に動かして確かめた
- [ ] コード例にセキュリティ上の問題がない
- [ ] 英単語の前後に半角スペースを入れている（正: `React を使う` 誤: `Reactを使う`）

## ファイルの形式と出力先

| 公開先 | 出力先 |
|--------|--------|
| Zenn | `articles/YYYY-MM-DD-slug.md` |
| Qiita | `qiita/YYYY-MM-DD-title.md` |

Zenn:

```markdown
---
title: "タイトル"
emoji: "📝"
type: "tech" # tech or idea
topics: ["topic1", "topic2"]
published: false
---
```

Qiita:

```markdown
---
title: タイトル
tags:
  - tag1
  - tag2
private: false
---
```
