# CodexBar 🎚️ - トークンが切れませんように。

Codex / Claude Code / Cursor / Gemini / Antigravity / z.ai の上限（セッション + 週間、対応する場合）と各ウィンドウのリセット時刻を表示する、macOS 15+ 向けの小さなメニューバーアプリです。プロバイダごとにステータス項目を表示し、設定で使うものだけ有効化できます。Dockアイコンなし、最小UI、メニューバー内の動的バー表示に対応します。

## インストール
- Homebrew（UIアプリ／Sparkle無効）: `brew install --cask steipete/tap/codexbar`（更新は `brew upgrade --cask steipete/tap/codexbar`）
- または GitHub Releases から実行済みzipをダウンロード: <https://github.com/steipete/CodexBar/releases>

ログイン周り
- **Codex** — ローカルの codex app-server RPC を優先して、5時間/週間の制限 + クレジットを取得します。RPCが使えない場合は `codex /status` のPTYスクレイプにフォールバックします（認証/メール/プランは RPC か `~/.codex/auth.json`）。すべて端末内で完結し、ブラウザは不要です。
- **Codex（任意の OpenAI Web）** — 設定 → 一般 → 「WebでOpenAIにアクセス」を有効にすると、既存の `chatgpt.com` ログインセッション（Safari → Chrome → Firefox のCookie取り込み）を再利用し、**コードレビュー残量**、**使用量内訳**、**クレジット使用履歴**を表示します（取得できる場合）。パスワードは保存しません。SafariのCookie取り込みにはフルディスクアクセス許可が必要な場合があります。
- **Claude Code** — Claude CLI の `/usage` + `/status` をローカルPTYで実行（tmux不要）し、セッション/週間/Sonnetのみの週間使用量を取得します。メール/組織/ログイン方法はCLI出力から直接表示します。CLI以外のブラウザ/ネットワークアクセスは不要です。
- **Cursor** — cursor.com のAPIをブラウザCookie（Safari → Chrome → Firefox）で利用して、プラン使用量とオンデマンド使用量を取得します。cursor.com + cursor.sh のCookieが必要です。プラン内使用率、オンデマンド消費、請求サイクルのリセット時刻を表示します。Pro/Enterpriseなどに対応。CLI不要、ブラウザでサインインしておくだけです。
- **Gemini** — Gemini CLI の `/stats` からクォータを取得し、OAuthベースのAPI取得でプラン/上限を補完します。
- **Antigravity** — ローカルの Antigravity 言語サーバーをプローブします。控えめなパースで外部認証はありません。
- **z.ai** — z.ai のクォータAPIを呼び出します（APIトークンは設定 → プロバイダからKeychainに保存）。トークン + MCP ウィンドウを表示します。ダッシュボード: https://z.ai/manage-apikey/subscription
- **プロバイダ検出** — 初回起動時にインストール済みCLIを検出し、Codexを既定で有効化します（`claude` バイナリがあればClaudeも有効化）。設定 → プロバイダで切替、またはCLIインストール後に再検出できます。
- **プライバシー注意** — CodexBarがディスクをスキャンするのか？しません。議論と監査メモは [issue #12](https://github.com/steipete/CodexBar/issues/12) を参照してください。

アイコンバーの意味（グレースケール）
- 上のバー: 5時間ウィンドウ（対応時）。週間が枯渇すると上のバーが太いクレジットバー（1k上限に正規化）に切り替わり、残りの有料クレジットを表示します。
- 下のバー: 週間ウィンドウ（細い線）。週間が0のときはクレジットバーの下が空になります。週間に余裕がある場合は割合に応じて埋まります。
- エラー/不明時はアイコンが暗くなります。アイコン内に文字は描画しないため可読性が保たれます。Codexのアイコンはまぶたの点滅を維持し、Claudeを有効化すると同じバー表示のままClaudeのノッチ/脚付きシルエットに切り替わります。

![CodexBar Screenshot](codexbar.png)

## 機能
- マルチプロバイダ: Codex / Claude Code / Cursor / Gemini / Antigravity / z.ai を同時表示できます。設定 → プロバイダで必要なものだけ有効化。
- Codexの取得: codex app-server RPC（`-s read-only -a untrusted` で起動）を優先し、レート制限とクレジットを取得します。RPCが使えない場合は `codex /status` のPTYスクレイプにフォールバックし、クレジットのキャッシュを維持します。
- Codex（任意）: 「WebでOpenAIにアクセス」で、コードレビュー残量 + 使用量内訳 + クレジット使用履歴（ダッシュボードスクレイプ）を追加します。パスワードは保存しません。
- Claude: `claude /usage` と `/status` をローカルPTYで実行（tmux不要）し、セッション/週間/Sonnetのみの割合、リセット文字列、アカウント情報（メール/組織/ログイン方法）を解析します。デバッグ画面から最新の生ログをコピーできます。
- アカウント情報はプロバイダごとに分離: Codexのプラン/メールはRPCまたはauth.jsonのみ、Claudeのプラン/メールはCLI出力のみ。プロバイダ間で混ぜません。
- Sparkleで自動更新（自動チェック + 自動ダウンロード）。ダウンロード後はメニューに「更新の準備ができました。今すぐ再起動？」を表示します。フィードはGitHub Releasesのappcastが既定です（SUPublicEDKeyは自分のEd25519公開鍵に差し替え）。

## ビルドと起動
```bash
swift build -c release          # または開発用にdebug
./Scripts/package_app.sh        # CodexBar.app をその場でビルド
open CodexBar.app
```

## プロバイダ追加
- まずはこちら: `docs/provider.md`（プロバイダ作成ガイド + 目標アーキテクチャ）。

## CLI
- macOS: 設定 → 高度な設定 → 「CLIをインストール」で `codexbar` を `/usr/local/bin` と `/opt/homebrew/bin` に配置します。
- Linux: GitHub Releases から `CodexBarCLI-<tag>-linux-<arch>.tar.gz`（x86_64 + aarch64）を取得し、`./codexbar` を実行します。
- ドキュメント: `docs/cli.md` を参照。

要件:
- macOS 15+。
- Codex: Codex CLI ≥ 0.55.0 をインストールしログイン済み（`codex --version`）。アカウントに使用実績がない場合、メニューは「使用量なし」と表示されます。
- Claude: Claude Code CLI をインストールし `claude login` でログイン済み。少なくとも一度 `/usage` を実行してセッション/週間の数字を作成してください。
- OpenAI Web（任意）: Safari/Chrome/Firefox で `chatgpt.com` にサインイン済みであること。SafariのCookie取り込みにはフルディスクアクセスが必要な場合があります（システム設定 → プライバシーとセキュリティ → フルディスクアクセス → CodexBarを有効化）。

## 更新間隔
メニュー → 「…ごとに更新」プリセット: 手動、1分、2分、5分（既定）、15分。手動でも「今すぐ更新」は使えます。

## 署名とノータライズ
```bash
export APP_STORE_CONNECT_API_KEY_P8="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
export APP_STORE_CONNECT_KEY_ID="ABC123XYZ"
export APP_STORE_CONNECT_ISSUER_ID="00000000-0000-0000-0000-000000000000"
./Scripts/sign-and-notarize.sh
```
`CodexBar-<version>.zip` が出力されます。必要ならスクリプト内の `APP_IDENTITY` を調整してください。

## アカウント情報の取得方法
アカウント情報は端末内で完結し、プロバイダごとに分離されます。
- Codex: メール/プランは codex RPC から取得。RPCが使えない場合は `~/.codex/auth.json`（JWTのみ）をデコードします。
- Claude: メール/組織/ログイン方法は Claude CLI の `/status` 出力から取得します。
- プロバイダ間の情報は混ぜません（例: Codex表示でClaudeの組織を出さない）。外部送信もしません。

## 制約 / 注意点
- Codex: レート制限がまだ返っていない場合、メニューに「使用量なし」と表示されます。Codexを1回実行して更新してください。
- Codex: イベントスキーマが変わると割合の解析に失敗する可能性があります。その場合、メニューにはエラー文字列が表示され、クレジットはキャッシュを維持します。
- Claude: CLIが未インストール/未ログインの場合、CLIのエラー（例: 「Claude CLI is not installed」や「claude login」）を表示します。
- Claude: リセット文字列にタイムゾーンが含まれない場合があり、解析に失敗すると原文を表示します。
- arm64ビルドのみスクリプト化されています。ユニバーサルにする場合は `--arch x86_64` を追加してください。

## リリースチェックリスト
署名/ノータライズ/appcast生成/アセット検証を含むCodexBarのリリース手順は `docs/RELEASING.md` を参照してください。

## 変更履歴
[CHANGELOG.md](CHANGELOG.md) を参照。

## 関連
- ✂️ [Trimmy](https://github.com/steipete/Trimmy) — 「1回貼り付けて1回実行」。複数行のシェルスニペットを1行に整形して貼り付けやすくします。
- 🧳 [MCPorter](https://mcporter.dev) — Model Context Protocol 向けの TypeScript ツールキット + CLI。
- 相互紹介: CodexBar は [codexbar.app](https://codexbar.app)、Trimmy は [trimmy.app](https://trimmy.app) からダウンロードできます。

[ccusage](https://github.com/ryoppippi/ccusage)（MIT）のコスト追跡にインスパイアされています。

ライセンス: MIT • Peter Steinberger（[steipete](https://twitter.com/steipete)）
