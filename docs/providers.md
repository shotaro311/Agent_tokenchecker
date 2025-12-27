---
summary: "プロバイダのデータソースと解析の概要（Codex、Claude、Gemini、Antigravity、Cursor、Droid/Factory）。"
read_when:
  - プロバイダ取得/解析を追加・変更するとき
  - プロバイダのラベル/トグル/メタデータを調整するとき
  - 各プロバイダのデータソースを確認するとき
---

# プロバイダ

## Codex
- 主要（OpenAI Web有効時）: OpenAIのWebダッシュボードで使用量上限 + クレジットを取得。
- CLIフォールバックは、対応するWeb Cookieがない場合のみ（5時間/週間の制限 + クレジットはRPC）。
- 二次フォールバック: RPCが使えない場合は `codex /status` をPTYスクレイプ。
- アカウント識別: Web有効時はWeb優先、その他はRPC、最後に `~/.codex/auth.json`。
- OpenAI Web連携はブラウザCookieを使い、CLIデータを置き換え可能（`docs/web-integration.md`）。
- ステータス: Statuspage.io（OpenAI）。

## Claude
- 主要: ClaudeのWeb API（Cookie）。
- CLIフォールバックは、Claude WebのCookieが見つからない場合のみ。
- デバッグ専用の上書き: OAuth usage API（`https://api.anthropic.com/api/oauth/usage`）をClaude CLI認証情報で使用
  （Keychain優先、次に `~/.claude/.credentials.json`）。
- 任意（デバッグ）: CLIソース強制時のWeb Cookie補完でExtra usageの支出/上限を取得（`docs/claude.md`）。
- Sonnet専用の週間バーがある場合に対応。旧Opusラベルはフォールバック。
- ステータス: Statuspage.io（Anthropic）。

## z.ai
- API: `https://api.z.ai/api/monitor/usage/quota/limit`（APIトークンはKeychainに保存／設定 → プロバイダ → z.ai）。
- クォータレスポンスからトークン/MCP使用量ウィンドウを表示。
- ダッシュボード: `https://z.ai/manage-apikey/subscription`
- ステータス: 公開ステータス連携はまだなし。

## Gemini
- CLI `/stats` 解析でクォータを取得。OAuthベースのAPI取得でプラン/上限を補完。
- ステータス: Gemini製品のGoogle Workspaceインシデント。

## Antigravity
- ローカルのAntigravity言語サーバープローブ。内部プロトコルで保守的に解析。
- ステータス: Gemini向けGoogle Workspaceインシデント（同一フィード）。
- 詳細は `docs/antigravity.md`。

## Cursor
- Webベース: cursor.com APIからブラウザセッションCookieで使用量を取得。
- Cookie取り込み: Safari（Cookies.binarycookies）→ Chrome（暗号化SQLite）→ Firefox（cookies.sqlite）。cursor.com + cursor.sh のCookieが必要。
- フォールバック: 「アカウント追加」WebKitログインフローで保存したセッション。
- プラン使用率、オンデマンド使用量、請求サイクルのリセットを表示。
- Pro / Enterprise / Team / Hobby のメンバーシップに対応。
- ステータス: Statuspage.io（Cursor）。
- 詳細は `docs/cursor.md`。

## Droid（Factory）
- Webベース: app.factory.ai（必要に応じてauth/apiホスト）からブラウザセッションCookieまたはローカルストレージのWorkOSリフレッシュトークンで使用量を取得。
- Cookie取り込み: Safari → Chrome → Firefox。factory.ai / app.factory.ai のCookieが必要。
- フォールバック: CodexBarが保存したセッションCookie。
- Standard + Premiumの使用量と請求期間リセットを表示。
- ステータス: `https://status.factory.ai`。

関連: `docs/claude.md`, `docs/antigravity.md`, `docs/cursor.md`。
