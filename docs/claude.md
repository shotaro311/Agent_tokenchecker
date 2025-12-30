---
summary: "CodexBarのClaude Code対応：PTYプローブ、解析、UX。"
read_when:
  - Claude使用量/ステータスの解析をデバッグするとき
  - ClaudeプロバイダのUI/メニュー挙動を調整するとき
  - Claude CLI検出パスやプロンプト対応を更新するとき
---

# Claude Code対応（CodexBar）

Claude Code対応は実装済みです。CodexBarはCodexとClaudeを並べて表示でき（プロバイダごとに1ステータス項目）、識別情報は分離されます（CodexにClaudeの組織/プランが混ざることはありません）。

## UX
- 起動時にCLIを検出:
  - Codex: `codex --version`
  - Claude Code: `claude --version`
- 設定 → 一般: 「Codexの使用量を表示」「Claude Codeの使用量を表示」のトグル（Claudeは検出時に既定で有効）。
- メニュー: 有効な各プロバイダに専用のステータス項目/メニューカードが表示されます。

### Claudeのメニューバーアイコン（カニのノッチ風）
- 2本バーのメタファは共通で、テンプレートがClaudeの“カニ”スタイルに切り替わります。

## データ経路（Claude）

### Web API（既定）
- ブラウザセッションCookie（Safari → Chrome → Firefox）を使って claude.ai API を呼び出します。
- セッション + 週間使用量、Opusの週間（存在時）、Extra usageのコスト、アカウントメタデータを提供します。
- Claude WebのCookieが無い場合はCLIプローブにフォールバックします。

### CLI PTYフォールバック（Cookieなし）
- 単一のClaude CLIセッションを擬似TTY内で起動し、更新間は維持してウォームアップの揺らぎを避けます。
- ドライバ手順:
  1) TUIヘッダを待ち、初回プロンプトを処理:
     - 「Do you trust the files in this folder」→ `1` + Enter
     - 「Select a workspace」→ Enter
     - テレメトリー `(y/n)` → `n` + Enter
     - ログインプロンプト → きれいなエラーで中断（「claude login」）
  2) `/usage` スラッシュコマンドを直接送信（`/usage` を入力しEnter）。
  3) 約1.5秒ごとにEnterを再送（負荷時に最初のEnterが落ちることがあるため）。
  4) 数秒経っても使用量が出ない場合、`/usage` + Enterを最大3回まで再送。
  5) バッファに「Current session」と「Current week (all models)」が両方出たら停止。
  6) さらに約2秒読み取り、割合行を確実に取得して終了。
- 解析:
  - ANSIコードを除去し、次のヘッダの前後4行以内で割合行を探す:
    - `Current session`
    - `Current week (all models)`
    - `Current week (Sonnet only)`（任意）
  - `X% used` は `% left = 100 - X` に変換、`X% left` はそのまま使用。
  - CLIが `Failed to load usage data` とJSON（例: `authentication_error` + `token_expired`）を返す場合は、
    一般的な「Missing Current session」ではなく、そのメッセージを直接表示（例: 「Claude CLI token expired. Run `claude login`」）。
  - `Account:` と `Org:` 行も取得（存在時）。
- 厳格さ: Session/Weeklyブロックが欠けると解析は失敗（黙って「100% left」は出さない）。
- しぶとさ: `ClaudeStatusProbe` はやや長いタイムアウト（20秒 + 6秒）で1回リトライし、描画遅延やEnter無視に対応。

### OAuth API（デバッグ専用）
- Claude CLIのOAuth認証情報を使用（Keychainの `Claude Code-credentials` 優先、次に `~/.claude/.credentials.json`）。
- `GET https://api.anthropic.com/api/oauth/usage`（`anthropic-beta: oauth-2025-04-20`）を呼ぶ。
- `five_hour` → セッション、`seven_day` → 週間、`seven_day_sonnet`/`seven_day_opus` → モデル別週間に対応。
- Extra usageのクレジット（存在時）はメニューで `ProviderCostSnapshot` として表示。
- デバッグタブのデータソースピッカー、または `codexbar --claude-source oauth` で有効化。
- 自動フォールバックはなし。エラーはそのまま表示。

### Web Cookie補完（任意、デバッグ）
- ClaudeソースをCLIに固定し「WebでClaudeを補完」を有効にした場合、Safari/Chrome/FirefoxのCookieからExtra usageの支出/上限を取得します。最善努力であり、識別情報は上書きしません。

### 表示内容
- セッション/週間の使用量バー。Sonnet専用の週間上限があれば表示。
- アカウント行はClaude CLIデータ（メール + 組織 + ログイン方法）。識別情報はプロバイダごとに分離。

## メモ
- リセット解析: Claudeのリセット行は曖昧な場合があるため、「Current session / Current week …」のヘッダで紐付け、誤ったウィンドウに割り当てない。
- デバッグ: デバッグタブから最新のCLI生スクレイプをコピーでき、CLIフォーマット変更の調査に役立つ。

## 未決定事項 / 判断
- Claudeアイコンのテンプレート素材（カラーかモノクロ）。既定は20×18のモノクロPDF。
- 初回検出時にClaudeを自動有効化するか。案: 既定オフで「Claude 2.0.44を検出（設定で有効化）」を表示。
- 週間/セッションのリセット表示: CLIから取得した文字列を表示し、ローカル計算はしない。

## デバッグのヒント
- 簡易ライブプローブ: `LIVE_CLAUDE_FETCH=1 swift test --filter liveClaudeFetchPTY`（失敗時にPTY生出力を表示）。
- 手動ドライバ: `swift run claude-probe`（一時ターゲット追加時）またはSwift REPLでTTYCommandRunnerを再利用。
- 生テキスト確認: 解析失敗時はANSI除去前のバッファを記録し、Usageペインではなく自動補完リストで詰まっていないか確認。
- デバッグのデータソース選択: 設定 → デバッグ → 「Claudeデータソース」（OAuth/Web/CLI）。
- よくある破綻:
  - Claude CLIが未ログイン（`claude login` が必要）。
  - 認証トークン期限切れ: Usageペインに `Error: Failed to load usage data: {"error_code":"token_expired", …}` が出る。
    `claude login` で更新し、CodexBarはこのメッセージを直接表示する。
  - Enterが無視される（CLIが「Thinking」や忙しい状態）。タイムアウト延長やEnter再送回数で対応。
  - tmux/screen内で実行: PTYドライバは単独動作のため、この経路ではtmuxを無効化する。
  - 設定 → 一般では、Claudeの最終取得エラーがトグル直下に表示される（使用量が古い理由が分かる）。
- Codex側の補足: Codex CLIが更新プロンプトを出してクレジットが取れない場合、PTYドライバはDown+Enterを自動送信し `/status` を再実行。さらに長いタイムアウトで1回リトライし、失敗時は `LIVE_CODEX_STATUS=1 swift test --filter liveCodexStatus` で生画面を出力。
- コード変更後にメニューバーアプリを再ビルド/再読み込みする場合: `./scripts/compile_and_run.sh`。新しいPTYドライバが使われるよう、アプリを再起動してください。
