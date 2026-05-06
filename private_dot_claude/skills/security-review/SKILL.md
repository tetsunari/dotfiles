---
name: security-review
description: Use this skill when adding authentication, handling user input, working with secrets, creating API endpoints, or implementing payment/sensitive features. Provides comprehensive security checklist and patterns.
context: fork
allowed-tools: Read, Grep
---

# Security Review Skill

This skill ensures all code follows security best practices and identifies potential vulnerabilities.

See **`references/security-patterns.md`** for detailed code examples and implementation patterns.

## When to Activate

- Implementing authentication or authorization
- Handling user input or file uploads
- Creating new API endpoints
- Working with secrets or credentials
- Implementing payment features
- Storing or transmitting sensitive data
- Integrating third-party APIs

## Security Checklist

### 1. Secrets Management
- [ ] No hardcoded API keys, tokens, or passwords
- [ ] All secrets in environment variables
- [ ] `.env.local` in .gitignore
- [ ] No secrets in git history
- [ ] Production secrets in hosting platform (Vercel, Railway)

### 2. Input Validation
- [ ] All user inputs validated with schemas (Zod recommended)
- [ ] File uploads restricted (size, type, extension)
- [ ] No direct use of user input in queries
- [ ] Whitelist validation (not blacklist)
- [ ] Error messages don't leak sensitive info

### 3. SQL Injection Prevention
- [ ] All database queries use parameterized queries
- [ ] No string concatenation in SQL
- [ ] ORM/query builder used correctly
- [ ] Supabase queries properly sanitized

### 4. Authentication & Authorization
- [ ] Tokens stored in httpOnly cookies (not localStorage)
- [ ] Authorization checks before sensitive operations
- [ ] Row Level Security enabled in Supabase
- [ ] Role-based access control implemented
- [ ] Session management secure

### 5. XSS Prevention
- [ ] User-provided HTML sanitized
- [ ] CSP headers configured
- [ ] No unvalidated dynamic content rendering
- [ ] React's built-in XSS protection used

### 6. CSRF Protection
- [ ] CSRF tokens on state-changing operations
- [ ] SameSite=Strict on all cookies
- [ ] Double-submit cookie pattern implemented

### 7. Rate Limiting
- [ ] Rate limiting on all API endpoints
- [ ] Stricter limits on expensive operations
- [ ] IP-based rate limiting
- [ ] User-based rate limiting (authenticated)

### 8. Sensitive Data Exposure
- [ ] No passwords, tokens, or secrets in logs
- [ ] Error messages generic for users
- [ ] Detailed errors only in server logs
- [ ] No stack traces exposed to users

### 9. Dependency Security
- [ ] Dependencies up to date
- [ ] No known vulnerabilities (npm audit clean)
- [ ] Lock files committed
- [ ] Dependabot enabled on GitHub
- [ ] Regular security updates

## Pre-Deployment Security Checklist

Before ANY production deployment:

- [ ] **Secrets**: No hardcoded secrets, all in env vars
- [ ] **Input Validation**: All user inputs validated
- [ ] **SQL Injection**: All queries parameterized
- [ ] **XSS**: User content sanitized
- [ ] **CSRF**: Protection enabled
- [ ] **Authentication**: Proper token handling
- [ ] **Authorization**: Role checks in place
- [ ] **Rate Limiting**: Enabled on all endpoints
- [ ] **HTTPS**: Enforced in production
- [ ] **Security Headers**: CSP, X-Frame-Options configured
- [ ] **Error Handling**: No sensitive data in errors
- [ ] **Logging**: No sensitive data logged
- [ ] **Dependencies**: Up to date, no vulnerabilities
- [ ] **Row Level Security**: Enabled in Supabase
- [ ] **CORS**: Properly configured
- [ ] **File Uploads**: Validated (size, type)
- [ ] **Wallet Signatures**: Verified (if blockchain)

### 10. AI固有リスク（OWASP LLM Top 10 2025）

- [ ] ユーザー入力をシステムプロンプトに直接連結していない（LLM01: プロンプトインジェクション）
- [ ] LLM出力をHTMLに埋め込む前にサニタイズしている（LLM02: インセキュアな出力処理）
- [ ] RAGデータ・外部ドキュメントからの機密情報漏洩チェック済み（LLM06: 機密情報漏洩）
- [ ] エージェントの権限が最小限に絞られている（LLM08: 過剰エージェント権限）
- [ ] ループ内でLLM APIを無制限呼び出ししていない（コスト暴走防止）
- [ ] `NEXT_PUBLIC_` プレフィックスにシークレットを格納していない

## 深刻度判定基準（CVSS v3.1）

| 深刻度 | スコア | 対応期限 |
|--------|--------|---------|
| 🔴 致命的 | 9.0–10.0 | 即時修正 |
| 🟠 高 | 7.0–8.9 | 24時間以内 |
| 🟡 中 | 4.0–6.9 | 次PR時 |
| 🟢 低/問題なし | 0–3.9 | 任意 |

## コミット可否判定

| 状態 | 判定 |
|------|------|
| 🔴 致命的が1件以上 | 🚫 NG — 即時修正必須 |
| 🟠 高が3件以上 | 🚫 NG |
| 🟠 高が1〜2件 | ⚠️ 要修正後コミット |
| 🟡 中のみ | ✅ OK（修正推奨） |
| 問題なし | ✅ OK |

## AI生成コード特有の注意点

AIが修正・追加時に混入しやすいパターン：

- 既存認証パターンを無視した認証なしエンドポイント追加
- Secret Manager実装を無視したAPIキーベタ書き
- LLM出力の未エスケープHTML埋め込み
- 差分レビュー時の急速な脆弱性混入

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP LLM Top 10 (2025)](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
- [Next.js Security](https://nextjs.org/docs/security)
- [Supabase Security](https://supabase.com/docs/guides/auth)
- [Web Security Academy](https://portswigger.net/web-security)

---

**Remember**: Security is not optional. One vulnerability can compromise the entire platform. When in doubt, err on the side of caution.
