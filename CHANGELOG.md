# 変更履歴

## 0.15.0 — 未リリース
- Droid（Factory）: ブラウザCookieでStandard/Premium使用量を取得する新プロバイダを追加。ダッシュボード/ステータスリンクも追加。Thanks @shashank-factory!
- メニュー: プロバイダ副題に複数行エラー（最大4行）を許可。
- メニュー: 複数行エラー時の副題サイズを修正。
- メニュー: 複数行エラー副題のクリップを回避。
- メニュー: 7プロバイダ以上有効時にメニューカード幅を拡大。
- プロバイダ: Codex / Claude Code / Cursor / Gemini / Antigravity / z.ai。
- Codex: OpenAI Webダッシュボードを使用量+クレジットの主ソースに変更。対応Cookieがない場合のみCLIフォールバック。
- Claude: Cookieによるclaude.ai Web APIを優先し、Cookieがない場合のみCLIフォールバック。OAuthはデバッグ専用。
- CLI: `--web`/`--claude-source` を `--source`（auto/web/cli/oauth）に置換。autoはCookieがない場合のみフォールバック。
- Cursor: ブラウザCookie認証（cursor.com + cursor.sh）の新しい使用量プロバイダ、オンデマンドバー対応、ダッシュボードアクセスを追加。
- Cursor: 一時的な失敗では保存セッションを保持し、認証無効時のみクリア。
- z.ai: トークン+MCPの使用量バーとMCP詳細サブメニューを追加。APIトークンは設定に移動（Keychain保存）。使用量バーは「使用済み表示」トグルに対応。Thanks @uwe-schwarz!
- 設定: 高度な表示チェックボックスを修正し、終了ボタンを一般タブ下部へ移動。
- 設定: ClaudeソースがCLIのときのみ「WebでClaudeを補完」を表示。コストトグル名を「コスト概要を表示」に変更。
- 設定: Codexクレジット + Claude Extra使用量セクションの表示/非表示トグルを高度な設定に追加（既定オン）。
- ウィジェット: プロバイダ切替と選択記憶ができる「CodexBar Switcher」を追加。
- メニュー: スイッチャーを鮮明なブランドアイコンに変更し、等幅セグメント + 週残量インジケータを追加。
- メニュー: スイッチャーのサイズを引き締め、ラベルと週インジケータの間隔を拡大。
- メニュー: 多数プロバイダ時もメニュー幅を強制拡張せず、セグメントをメニュー幅にクランプ。
- メニュー: 余裕がある場合、スイッチャーの横パディングをメニューカードと揃える。
- Dev: `compile_and_run.sh` が旧インスタンスを強制終了して重複起動を回避。
- Dev: `compile_and_run.sh` が遅い起動を待機（プロセスをポーリング）。
- CI: Linux向けCodexBarCLI（x86_64 + aarch64）をビルド/テストし、`CodexBarCLI-<tag>-linux-<arch>.tar.gz`（+`.sha256`）を公開。
- CLI: PATH解決失敗時にCodex/Claude検出のエイリアスフォールバックを追加。
- プロバイダ: Factory/Droid向けにArcブラウザCookie取り込みをサポート（他のChromium系にも適用）。
- プロバイダ: Factory/Droidログイン検出でAuth.jsのsecure session Cookieを許容。
- プロバイダ: Droid向けにFactoryのauthセッションCookie（session/access-token）を許容。
- Droid: Factory APIエラーをセッション欠如として隠さず表示。
- Droid: Factoryが古いトークンを示した場合、access-token Cookieなしで再認証。
- Droid: 検出した全ブラウザプロファイルを試す。
- Droid: Cookieがauthホストにある場合、auth.factory.aiエンドポイントへフォールバック。
- Droid: Cookie失敗時にローカルストレージのWorkOSリフレッシュトークンを利用。
- プロバイダ: APIキー設定までz.aiをメニューから非表示。
- メニュー: 開くと自動更新（短いリトライ付き）。更新行は削除。
- メニュー: ステータスURLがないプロバイダではStatus Page行を非表示。
- メニュー: スイッチャーバーを「使用済み表示」トグルと整列。
- Antigravity: lsofのポートフィルタをlisten+pid条件のANDで修正。Thanks @shaw-baobao!
- Claude: Claude Code OAuth usage APIを既定に（Keychainまたは`~/.claude/.credentials.json`）。Debug選択 + `--claude-source` CLI上書き（OAuth/Web/CLI）。
- OpenAI Web: Codexメール不明時でも任意のサインイン済みブラウザセッションを取り込み可能に（初回向け）。
- Core: Linux CLIビルドがコンパイル可能に（macのみWebKit/ログをガードし、必要に応じてFoundationNetworkingを導入）。
- Core: Claude信頼プロンプトのCIフレークを修正（PTY書き込みの信頼性を改善）。
- Core: CursorプロバイダはmacOSのみ（Linux CLIはスタブ）。
- Core: `RateWindow` をEquatableに（OpenAIダッシュボードスナップショット/テスト用）。
- Tests: Codex/Claudeのエイリアスフォールバック解決とLinuxプラットフォームゲートをテスト。
- Tests: 高度なトグルでCodexクレジット + Claude Extra使用量を非表示にする挙動をテスト。
- Docs: LinuxインストールとフラグのCLIドキュメントを拡充。

## 0.14.0 — 2025-12-25
- Antigravity: ローカルプロバイダを追加（Claude + Geminiのクォータ）。実験トグル、プラン表示/デバッグ強化、not-running/ポートエラー明確化、アカウント切替非表示。
- Status: Gemini + Antigravity向けにGoogle Workspaceインシデントをポーリング。Status PageはWorkspaceページを開く。
- 設定: Providersタブを追加。ccusage + statusトグルを一般に移動。表示制御は高度な設定へ。
- メニュー/UI: 4プロバイダ向けにメニュー幅を拡大。カード/チャートが幅に追従。スイッチャー/トグル間隔を最適化。メニュー開放中の更新を維持。
- Gemini: 未対応時はダッシュボードアクションを非表示。
- Claude: Extra usageの金額/上限単位（セント）を修正。CLIプローブ安定化。DebugにWebセッション情報を表示。
- OpenAI Web: デスクトップでのダッシュボード幽霊オーバーレイを修正（WebKitキープアライブ）。
- Debug: トラブルシュート向けのdebug-lldbビルドモードを追加。

## 0.13.0 — 2025-12-24
- Claude: Safari/Chrome CookieによるWeb優先使用量（CLIフォールバックなし）を追加。Extra usageの予算バーも表示。
- Claude: Webの識別情報を `/api/account` から取得（rate_limit_tier使用）。
- 設定: Codex/Claudeの「Webで補完」文言を統一。
- Debug: ClaudeダンプにWeb戦略、Cookie検出、HTTPステータス、解析サマリを表示。
- Dev: ブラウザCookieを使ったClaude WebプローブCLIを追加（エンドポイント/フィールド列挙）。
- Tests: Claude Web APIの使用量/超過/アカウント解析を追加。
- メニュー: 選択ハイライト色をネイティブに合わせ、選択時の文字/トラック色も調整。
- チャート: クレジット/使用履歴のホバー強調を改善。
- メニュー: Codexブロックの順序を「クレジット → コスト」に変更。
- メニュー: Claudeの「Extra usage」（サブメニューなし）と「Cost」（履歴サブメニュー）を分離し、冗長な補足を削減。

## 0.12.0 — 2025-12-23
- ウィジェット: アプリグループの使用量スナップショットを使うWidgetKit拡張を追加。
- 新しいローカルコスト使用量（Codex + Claude）。ccusageに着想を得た軽量スキャナでJSONLログからコストを算出（Node CLI不要）。Thanks @ryoppippi!
- コスト概要に過去30日トークンを追加。週間ペースの実行予測は枯渇時に非表示。Thanks @Remedy92!
- Claude: PTYプローブがアイドルで停止、再起動時に自動クリーン、ウォッチドッグで暴走プロセスを防止。
- メニューの磨き込み: 履歴をカード内でグループ化、履歴ラベルを簡素化、開いている間の更新を維持。
- パフォーマンス: 使用ログスキャン + コスト解析を高速化。メニューアイコンをキャッシュしOpenAIダッシュボード解析を高速化。
- Sparkle: 自動チェック時に自動ダウンロードし、更新準備ができたら再起動メニューを表示。
- ウィジェット: 実験的なWidgetKit拡張（ウィジェットギャラリー/Dockの再起動が必要な場合あり）。
- クレジット: 進捗バー表示 + OpenAI Webデータがある場合はクレジット履歴チャートを追加。
- クレジット: 「クレジットを購入…」を独立メニューに移し、自動開始の購入フローを改善。

## 0.11.2 — 2025-12-21
- ccusage-codex のコスト取得を高速/安定化（セッションスキャンの範囲を制限）。
- 大きなCodex履歴でハングする問題を修正（コマンド実行中に出力を排出）。
- 統合アイコンの読み込みアニメーションが他プロバイダ取得中に動く問題を修正（選択中のみアニメ）。
- CLIのPATH取得が対話的ログインシェルを使うようになり、NVM系インストールでのNode/Codex/Claude/Gemini検出を改善。

## 0.11.1 — 2025-12-21
- GeminiのOAuthトークン更新がBun/npmインストールをサポート。Thanks @ben-vargas!

## 0.11.0 — 2025-12-21
- メニューに任意のコスト表示（セッション + 過去30日）を追加。ccusageがベース。Thanks @Xuanwo!
- ローディング時のカード間隔を修正（ダブル区切り回避）。

## 0.10.0 — 2025-12-20
- Geminiプロバイダ対応（使用量/プラン検出/ログインフロー）。Thanks @381181295!
- プロバイダスイッチャー付きの統合メニューバーアイコンモードを追加（複数有効時に既定オン）。Thanks @ibehnam!
- 0.9.1で一部環境のCLI検出が失敗する退行を修正（対話的ログインシェルPATH取得に戻す）。

## 0.9.1 — 2025-12-19
- CLI解決がログインシェルPATHを直接使うように変更（ヒューリスティックなPATHスキャンを削除）。

## 0.9.0 — 2025-12-19
- 新しいOpenAI Webアクセス: サインイン済みSafari/Chromeセッションを再利用し、**コードレビュー残量**、**使用量内訳**、**クレジット使用履歴**を表示（認証情報は保存しない）。
- クレジットはCodex CLI由来のまま。OpenAI Webは上記のダッシュボード追加分のみ。
- OpenAI WebセッションをCodex CLIメールに自動同期。複数アカウント対応。アカウント切替時にCookieを再取得し、アカウント間の古いデータを回避。
- Chrome Cookie取り込みを修正（macOS 10）。サインイン済みChromeセッションを確実に検出。Thanks @tobihagemann!
- 使用量内訳サブメニュー: 日別/サービス別の詳細をホバーで表示するコンパクトチャート。
- 「使用量を使用済みとして表示」トグルを追加（既定は「残り%」のまま。高度な設定）。
- セッション（5時間）のリセットが、Codex/Claudeのメニューカードで相対カウントダウン表示（「Resets in 3h 31m」）。
- Claude: リセット解析を修正し、誤ったウィンドウ（セッション/週間）への紐付けを防止。

## 0.8.1 — 2025-12-17
- Claudeの信頼プロンプト（「このフォルダのファイルを信頼しますか？」）をプローブ中に自動承認し、更新停止を防止。Thanks @tobihagemann!

## 0.8.0 — 2025-12-17
- CodexBarをHomebrewで提供開始: `brew install --cask steipete/tap/codexbar`（更新: `brew upgrade --cask steipete/tap/codexbar`）。
- 5時間のスライディングセッション枠の通知を追加（Codex + Claude）。0%到達時と回復時に通知（起動時に枯渇している場合も含む）。Thanks @GKannanDev!

## 0.7.3 — 2025-12-17
- Claude Enterpriseアカウントで`/usage`が「Current session」だけ表示されるケースの解析失敗を修正。週間使用量は未対応扱い（#19修正）。

## 0.7.2 — 2025-12-13
- Claudeの「Open Dashboard」がサブスク系アカウント（Max/Pro/Ultra/Team）ではAPI請求ページではなく使用量ページを開くように変更。Thanks @auroraflux!
- Codex/Claudeのバイナリ解決がmise/rtxインストール（shimと最新版）に対応し、CLI検出失敗を修正。Thanks @philipp-spiess!
- Claude使用量/ステータスの初回プロンプト（Finder起動時の「Ready to code here?」）を自動承認し、タイムアウト/解析エラーを防止。Thanks @alexissan!
- 一般設定にCodex/Claudeの取得エラーを全文コピー/展開付きで表示し、初回混乱を軽減。
- メニューバーの「critter」アイコンを調整: Claudeはブロック状のピクセルカニに、Codexは目のボケを抑えてよりシャープに。

## 0.7.1 — 2025-12-09
- メニューバーアイコンを18pt/2×の正しいバックで描画し、ピクセル整列バーでよりシャープに。
- PTYランナーが呼び出し元の環境（HOME/TERM/bun）を保持しつつPATHを拡張し、bun/nvmインストールでのCLI失敗を回避。
- 環境拡張の挙動を固定する回帰テストを追加。
- macOS 26での初回クラッシュ（1×1キープアライブウィンドウの制約ループ）を修正。安全なサイズに変更し、SwiftUI警告を抑制。
- メニューアクション行にSF Symbolsアイコン（更新/ダッシュボード/ステータス/設定/About/終了/エラーコピー）を追加。
- Codex CLIが無い場合、メニューとCLIにインストールヒント（`npm i -g @openai/codex` / bun）を表示。
- Nodeマネージャ（nvm/fnm）解決を修正し、fnmエイリアスやnvm既定でもcodex/claudeのバイナリと`node`が確実に見つかるように。Thanks @aliceisjustplaying!
- ログインメニューにフェーズ別サブタイトルを追加。CLI起動中は「Requesting login…」、認証URL表示後は「Waiting in browser…」。成功時はmacOS通知。
- ログイン状態をプロバイダ別に追跡し、アカウント切替時にCodex/Claudeのアイコン/メニューが共通の状態にならないように。
- ClaudeログインPTYランナーが認証URLをバッファを消さずに検出し、確認までセッションを維持。Sendableなフェーズコールバックをメニューへ提供。
- Claude CLI検出にClaude Codeの自動更新パス（`~/.claude/local/claude`, `~/.claude/bin/claude`）を追加し、バンドルインストーラのみでもPTYプローブが動くように。

## 0.7.0 — 2025-12-07
- ✨ リッチなメニューカードを追加。各プロバイダの進捗バーとリセット時刻をインライン表示し、ひと目で分かるダッシュボード風に（credit: Anton Sotkov @antons）。

## 0.6.1 — 2025-12-07
- Claude CLIプローブから `--dangerously-skip-permissions` を削除し、既定の権限プロンプトに合わせて初回失敗を回避。

## 0.6.0 — 2025-12-04
- 新しい同梱CLI（`codexbar`）を追加。単一の `usage` コマンド、`--format text|json`、`--status`、高速な `-h/-V`。
- CLI出力のヘッダを統一（`Codex 0.x.y (codex-cli)`, `Claude Code <ver> (claude)`）し、JSONに `source` + `status` を追加。
- 高度な設定のインストールボタンが `codexbar` を /usr/local/bin と /opt/homebrew/bin にシンボリックリンク。ドキュメント更新。

## 0.5.7 — 2025-11-26
- Status PageとUsage Dashboardのメニューアクションがクリックしたアイコンのプロバイダに従うよう修正（CodexがClaudeのステータスを開く問題を解消）。

## 0.5.6 — 2025-11-25
- たまに点滅/傾き/揺れを入れる「Surprise me」オプションを追加（1回につき1種）。デバッグに「今すぐ点滅」も追加。
- 設定に高度なタブを追加（更新間隔/Surprise me/デバッグ表示）。ウィンドウ高さを約20%削減。
- 点滅/揺れのモーションを滑らかに、やや長めに調整。

## 0.5.5 — 2025-11-25
- Claude使用量スクレイプが新しい「Current week (Sonnet only)」バーに対応。旧Opusラベルはフォールバック。
- メニュー/ドキュメントでClaudeの第3枠をSonnet表記に更新。
- PATHシードを決定的なバイナリ探索 + 起動時ログインシェルキャプチャに変更（nvmのグロブ探索を削除）。Debugタブに解決済みCodexバイナリとPATHを表示。

## 0.5.4 — 2025-11-24
- 「Status Page」下のステータス文言から「Status:」プレフィックスを削除し、簡潔化。
- PTYランナーが起動前にクリーンアップを登録し、`Process.run()` 失敗時でもTTY両端/プロセスグループを解放（fdリーク回避）。

## 0.5.3 — 2025-11-22
- プロバイダ別の「Status Page」メニュー項目をUsage下に追加（OpenAI/Claude）。
- ステータスAPIが使用量更新と同時に更新され、インシデント状態はステータスアイコンにドット/!オーバーレイとメニュー下の説明文で表示。
- 一般設定に「プロバイダのステータスを確認」トグルを追加（既定オン）。

## 0.5.2 — 2025-11-22
- リリースパッケージにdSYMアーカイブを同梱してクラッシュシンボリケーションを支援（方針は共通macリリースガイドに記載）。
- ClaudeのPTYフォールバックを削除: Claudeプローブは `script` のstdout解析に統一し、一般TTYランナーはCodex `/status` のみに縮小。
- codex RPCのstderrパイプがビジーループになる問題を修正（EOFでハンドラを解除）。issue #9の高CPUスピンを解消。

## 0.5.1 — 2025-11-22
- デバッグペインにClaudeの解析ダンプトグルを追加し、生スクレイプをメモリ保持。
- Claude About/Debugに現在のgitハッシュを埋め込み、ビルド識別を可能に。
- PTYランナーと使用量フェッチャの軽微な堅牢性改善。

## 0.5.0 — 2025-11-22
- Codexの使用量/クレジットをcodex app-server RPCで既定取得（RPC不可時はPTY `/status` フォールバック）し、安定性と速度を改善。
- Codex CLI起動時にHomebrew/bun/npm/nvm/fnmのPATHをシードし、Hardened/ReleaseでのENOENTを回避。TTYプローブも同じPATHを使用。
- Claude CLIプローブが `/usage` と `/status` を並列実行（模擬入力なし）、リセット文字列を取得、堅牢なパーサ（ラベル優先 + 順序フォールバック）を使用し、組織/メールはプロバイダ分離。
- TTYランナーがプロセスグループを確実に終了（Claudeログインプロンプト途中でもリークしない）。
- 既定の更新間隔を5分に変更し、15分オプションを追加。
- Claudeプローブ/バージョン検出は `--allowed-tools ""` で開始（ツールアクセス無効）しつつ対話PTYを維持。
- Codexプローブ/バージョン検出を `-s read-only -a untrusted` で起動しPTYをサンドボックス化。
- Codexのウォームアップ画面（データ未取得）を安全に処理し、クレジットはキャッシュ維持、恐い解析エラーを回避。
- Codexのリセット時刻をRPC/TTY双方で表示し、プランラベルはキャピタライズ、メールは原文のまま。

## 0.4.3 — 2025-11-21
- macOS 15でのステータス項目作成タイミングを修正（起動後にNSStatusItemを作成）。回帰テストを追加。
- 使用量不明時のメニューバーアイコンが空トラックを描画するよう修正（装飾時に全バーになるのを回避）。

## 0.4.2 — 2025-11-21
- リリースビルドでSparkle更新を再有効化（debug bundle IDのみ無効）。

## 0.4.1 — 2025-11-21
- Codex/Claudeプローブをメインスレッド外で実行し、`/status`/`/usage` 中のUI停止を回避。
- Codexクレジットは `/status` タイムアウトでもキャッシュを保持し、エラーを別途表示。
- Codex/Claudeの自動検出を初回起動で実行（どちらも無ければCodex既定）。デバッグ用リセットボタンを追加。
- リリースビルドでSparkle更新を再有効化（debug bundle IDのみ無効）。
- Claudeプローブが `/usage` を直接叩いてUsageタブに遷移し、パレット誤動作を回避。

## 0.4.0 — 2025-11-21
- Claude Code対応: 専用Claudeメニュー/アイコン + 両方有効時の二重メニュー。メール/組織/プランとSonnet使用量を表示し、クリック可能なエラーを追加。
- 新しい設定ウィンドウ: 一般/Aboutタブ、プロバイダトグル、更新間隔、ログイン時起動、常時Quit。
- Codexクレジット（Web不要）: `codex /status` をPTYで読み、更新プロンプトを自動スキップし、セッション/週間/クレジットを解析。クレジットはキャッシュ保持。
- 堅牢性: PTYタイムアウトを延長し、クレジットキャッシュフォールバック、1行エラー、解析/更新メッセージの改善。

## 0.3.0 — 2025-11-18
- クレジット対応: Codex CLIの `/status` をPTYで読み（ブラウザ不要）、残りクレジットを表示し、履歴はサブメニューへ移動。
- サインインウィンドウとCookie再利用、ログアウト/クッキー削除アクションを追加。ワークスペース選択を待ち、使用量ページへ自動遷移。
- メニュー: クレジット行を太字に。クレジット取得後はログインプロンプトを非表示。デバッグトグルは常に表示（HTMLダンプ）。
- アイコン: 週間が空のとき上バーを太いクレジットバー（1k上限）に変更。通常は5時間/週間の2本バー。

## 0.2.2 — 2025-11-17
- アカウント/使用量が無い場合、メニューバーアイコンは静止。読み込みアニメーションは取得中のみ（12fps）でアイドルCPUを抑制。
- 使用量更新は最新セッションログ（512KB）を先にtailし、全件スキャン前にIOを削減。
- パッケージ/署名を強化: 拡張属性の除去、AppleDouble（`._*`）削除、Sparkle + アプリの再署名でGatekeeperを満たす。

## 0.2.1 — 2025-11-17
- リファクタ/相対時刻変更のパッチ。パッケージスクリプトを0.2.1（5）に設定。
- Codex使用量解析を整理: 新しいレート制限処理、柔軟なリセット時刻解析、アカウントのレート制限更新（Thanks @jazzyalex / https://jazzyalex.github.io/agent-sessions/）。

## 0.2.0 — 2025-11-16
- CADisplayLinkベースの読み込みアニメーション（macOS 15 displayLink API）。ランダムパターン（Knight Rider、Cylon、外側→内側、レース、パルス）とデバッグ再生。
- デバッグ再生トグル（`defaults write com.steipete.codexbar debugMenuEnabled -bool YES`）で全パターンを確認。
- メニューにUsage Dashboardリンクを追加し、レイアウト調整。
- 更新時刻が24時間以内は相対表記に変更。ソースを小さなファイルに分割して保守性を向上。
- バージョンを0.2.0（4）に更新。

## 0.1.2 — 2025-11-16
- 読み込みアニメーション付きアイコン（2本バーが掃引し、使用量取得まで継続）。常にテンプレートアイコンを使用。
- Sparkleの埋め込み/署名を修正（deep + timestamp）。ノータライズのパイプラインを安定化。
- ictoolによるアイコン変換をスクリプト化（ドキュメント追加）。
- メニュー: 設定サブメニュー、GitHub項目の削除、Aboutリンクのクリック対応。

## 0.1.1 — 2025-11-16
- ログイン時起動トグル（SMAppService）と保存済み設定を起動時に適用。
- Sparkle自動更新を配線（SUFeedURLをGitHubに設定、SUPublicEDKeyを設定）。設定サブメニューに自動更新トグル + 更新確認を追加。
- メニュー整理: 設定をグループ化、GitHubメニュー削除、Aboutリンクをクリック可能に。
- 使用量パーサが最新セッションログを走査し、`token_count` イベントを見つけるまで処理。
- アイコンパイプライン修正: ictoolで `.icns` を再生成し透明性を確保（docs/icon.md）。
- lint/format設定、Swift Testing、厳密並行性、使用量パーサテストを追加。
- ノータライズ済みリリースビルド「CodexBar-0.1.0.zip」を現行アーティファクトとして維持。アプリバージョンは0.1.1。

## 0.1.0 — 2025-11-16
- CodexBar初期リリース: macOS 15+ のメニューバーアプリ、Dockアイコンなし。
- Codex CLIのセッションログから最新の `token_count` イベントを読み取り（5時間 + 週間使用量、リセット時刻）。追加ログインやブラウザスクレイプは不要。
- `auth.json` をローカルでデコードし、アカウントのメール/プランを表示。
- 横並び2本バーのアイコン（上=5時間、下=週間）。エラー時は暗く表示。
- 更新間隔の設定、手動更新、Aboutリンク。
- 応答性のためログ解析をメイン外で実行。厳密並行性のビルドフラグを有効化。
- パッケージ/署名/ノータライズのスクリプト（arm64）を追加。`.icon` バンドルから `.icns` への変換も含む。
