---
summary: "コマンドラインから使用量を取得する CodexBar CLI。"
read_when:
  - "スクリプトやターミナルからCodexBarのデータを使いたいとき"
  - "CommanderベースのCLIコマンドを追加/変更するとき"
  - "メニューバーとCLIの出力/挙動をそろえるとき"
---

# CodexBar CLI

メニューバーアプリのデータ取得経路（Codex Web/RPC → PTYフォールバック、Claude Web既定 + CLIフォールバック + OAuthデバッグ）を再現する、軽量なCommanderベースのCLIです。UIなしでスクリプト/CI/ダッシュボードに使用量を取り込みたいときに使います。

## インストール
- アプリ内: **設定 → 高度な設定 → CLIをインストール**。`CodexBarCLI` を `/usr/local/bin/codexbar` と `/opt/homebrew/bin/codexbar` にシンボリックリンクします。
- リポジトリから: `./bin/install-codexbar-cli.sh`（同じリンク先）。
- 手動: `ln -sf "/Applications/CodexBar.app/Contents/Helpers/CodexBarCLI" /usr/local/bin/codexbar`。

### Linuxインストール
- GitHub Releases から `CodexBarCLI-<tag>-linux-<arch>.tar.gz`（x86_64 + aarch64）をダウンロード。
- 展開して `./codexbar`（シンボリックリンク）または `./CodexBarCLI` を実行。

```
tar -xzf CodexBarCLI-0.14.1-linux-x86_64.tar.gz
./codexbar --version
./codexbar usage --format json --pretty
```

## ビルド
- `./Scripts/package_app.sh`（または `./Scripts/compile_and_run.sh`）で `CodexBarCLI` が `CodexBar.app/Contents/Helpers/CodexBarCLI` に同梱されます。
- 単体ビルド: `swift build -c release --product CodexBarCLI`（出力は `./.build/release/CodexBarCLI`）。
- 依存: Swift 6.2+、Commanderパッケージ（`https://github.com/steipete/Commander`）。

## コマンド
- `codexbar` は既定で `usage` コマンドを実行します。
  - `--format text|json`（既定: text）。
  - `--provider codex|claude|gemini|antigravity|both|all`（既定: アプリ内トグル。なければCodex）。
  - `--no-credits`（テキスト出力でCodexクレジットを非表示）。
  - `--pretty`（JSONを整形）。
  - `--status`（プロバイダのステータスページを取得して出力に含める）。
  - `--antigravity-plan-debug`（デバッグ: AntigravityのplanInfoフィールドをstderrに出力）。
- `--source <auto|web|cli|oauth>`（既定: `auto`）。
    - `auto`（macOSのみ）: Codex + ClaudeはブラウザCookieを使用し、Cookieがない場合のみCLIフォールバック。
    - `web`（macOSのみ）: Webのみ。CLIフォールバックなし。
    - `cli`: CLIのみ（Codex RPC → PTYフォールバック、Claude PTY）。
    - `oauth`: Claude OAuthのみ（デバッグ）。フォールバックなし。Codexでは非対応。
    - Codex Web: OpenAI Webダッシュボード（使用量上限、残りクレジット、コードレビュー残量、使用量内訳）。
        - `--web-timeout <seconds>`（既定: 60）
        - `--web-debug-dump-html`（データが欠落した場合にHTMLスナップショットを `/tmp` に保存）
    - Claude Web: claude.ai API（セッション + 週間使用量、可能ならアカウントメタデータ）。
    - Linux: `web/auto` は未対応。CLIはエラーを出して非ゼロ終了します。
- グローバルフラグ: `-h/--help`, `-V/--version`, `-v/--verbose`, `--log-level <trace|verbose|debug|info|warning|error|critical>`, `--json-output`。

## 使用例
```
codexbar                          # テキスト、アプリのトグルを尊重
codexbar --provider claude        # Claudeを強制
codexbar --provider all           # すべてのプロバイダを問い合わせ（ログイン/トグルを尊重）
codexbar --format json --pretty   # 機械向け出力
codexbar --format json --provider both
codexbar --status                 # ステータス指標/説明を含める
codexbar --provider codex --source web --format json --pretty
```

### 出力例（text）
```
Codex 0.6.0 (codex-cli)
Session: 72% left
Resets today at 2:15 PM
Weekly: 41% left
Resets Fri at 9:00 AM
Credits: 112.4 left

Claude Code 2.0.58 (claude)
Session: 88% left
Resets tomorrow at 1:00 AM
Weekly: 63% left
Resets Sat at 6:00 AM
Sonnet: 95% left
Account: user@example.com
Plan: Pro
```

### 出力例（JSON、整形）
```json
{
  "provider": "codex",
  "version": "0.6.0",
  "source": "codex-cli",
  "status": { "indicator": "none", "description": "Operational", "updatedAt": "2025-12-04T17:55:00Z", "url": "https://status.openai.com/" },
  "primary": { "usedPercent": 28, "windowMinutes": 300, "resetsAt": "2025-12-04T19:15:00Z" },
  "secondary": { "usedPercent": 59, "windowMinutes": 10080, "resetsAt": "2025-12-05T17:00:00Z" },
  "tertiary": null,
  "updatedAt": "2025-12-04T18:10:22Z",
  "accountEmail": "user@example.com",
  "accountOrganization": null,
  "loginMethod": "plus",
  "credits": { "remaining": 112.4, "updatedAt": "2025-12-04T18:10:21Z" },
  "openaiDashboard": {
    "signedInEmail": "user@example.com",
    "codeReviewRemainingPercent": 100,
    "creditEvents": [
      { "id": "00000000-0000-0000-0000-000000000000", "date": "2025-12-04T00:00:00Z", "service": "CLI", "creditsUsed": 123.45 }
    ],
    "dailyBreakdown": [
      {
        "day": "2025-12-04",
        "services": [{ "service": "CLI", "creditsUsed": 123.45 }],
        "totalCreditsUsed": 123.45
      }
    ],
    "updatedAt": "2025-12-04T18:10:21Z"
  }
}
```

## 終了コード
- 0: 成功
- 2: プロバイダ不在（PATHにバイナリがない）
- 3: 解析/フォーマットエラー
- 4: CLIタイムアウト
- 1: 予期しない失敗

## 注意点
- CLIはメニューバートグルを再利用します（`com.steipete.codexbar{,.debug}` のdefaultsがあればそれを優先）。なければCodexのみ。
- CodexはRPC優先 → PTYフォールバック。ClaudeはWeb優先で、Cookieがない場合のみCLIフォールバック。
- OpenAI Webには `chatgpt.com` のサインインセッションが必要です（Safari/Chrome/Firefox）。パスワードは保存せず、Cookieを再利用します。
- SafariのCookie取り込みにはCodexBarのフルディスクアクセスが必要な場合があります（システム設定 → プライバシーとセキュリティ → フルディスクアクセス）。
- `openaiDashboard` のJSONは通常アプリのキャッシュ済みダッシュボードスナップショット由来です。`--source auto|web` はWebKitでライブ更新します。
- 予定: メニューバーのスナップショットを読む `--from-cache` フラグ（将来）。
