---
summary: "プロバイダ作成ガイド：共有ホストAPI、プロバイダ境界、追加手順。"
read_when:
  - 新しいプロバイダを追加するとき（使用量 + ステータス + 識別情報）
  - プロバイダアーキテクチャや共有ホストAPIをリファクタするとき
  - プロバイダ境界（識別情報の混入禁止）を確認するとき
---

# プロバイダ作成ガイド

目標: プロバイダ追加が次の感覚でできること。
- フォルダを1つ追加
- フェッチャを1つ実装
- ディスクリプタを1つ登録
- 完了（テスト + ドキュメント）

このドキュメントは以下の両方を扱います。
- **今の仕組み**（CodexBar 2025-12）
- **目指す形**（今後リファクタで到達したい形）

## 用語
- **プロバイダ**: 使用量/クォータ/ステータスのデータソース（Codex、Claude、Gemini、Antigravity、Cursor など）。
- **ホストAPI**: プロバイダに提供する共通機能（Keychain、ブラウザCookie、PTY、HTTP、WebViewスクレイプ、トークンコスト）。
- **識別情報フィールド**: email/org/plan/loginMethod。**必ずプロバイダごとに分離**する。

## 現在のアーキテクチャ（今）
- `Sources/CodexBarCore`: プローブ + フェッチャ + 解析 + 共有ユーティリティ。
- `Sources/CodexBar`: レジストリ + 設定 + UI。
- プロバイダIDはコンパイル時に固定: `UsageProvider` enum。
- プロバイダ配線:
  - メタデータ: `ProviderDefaults.metadata`
  - 取得: `ProviderRegistry.specs(...)` → `ProviderSpec.fetch` が `UsageSnapshot` を生成

共通ビルディングブロック:
- PTY: `TTYCommandRunner`
- サブプロセス: `SubprocessRunner`
- Cookie取り込み: `SafariCookieImporter`, `ChromeCookieImporter`, `FirefoxCookieImporter`
- OpenAIダッシュボードWebスクレイプ: `OpenAIDashboardFetcher`（WKWebView + JS）
- トークンコスト: `CCUsageFetcher`

現状の痛み:
- プロバイダ追加時に多数の `switch provider` を触る必要がある（UI + アイコン + 設定 + メニューアクション）。
- 共有プリミティブはあるが、明確な「ホストAPIの面」として整理されていない。

## 目標アーキテクチャ（リファクタ後）

### 1) 「プロバイダディスクリプタ」をSSOTにする
プロバイダごとに単一のディスクリプタを導入する。
- `id`（安定した文字列またはenumラッパ）
- 表示/ラベル/URL
- 能力（supportsCredits, supportsStatusPolling, supportsTokenCost, supportsWebLogin など）
- ステータス戦略（Statuspage / Workspace製品フィード / リンクのみ）
- アイコン/ブランディング情報

UIと設定はディスクリプタ駆動にする。
- ラベル/リンク/トグル文言のプロバイダ分岐をなくす
- 本当に必要な場合のみプロバイダ専用UIを許可

### 2) ホストAPIを明示し、小さく、テスト可能に
プロバイダ実装が使うプロトコル/構造体を狭く定義する。
- `KeychainAPI`: 読み取り専用、許可済みのサービス/アカウントのみ
- `BrowserCookieAPI`: ドメインリストでCookie取得。Cookieヘッダ + 診断情報を返す
- `PTYAPI`: タイムアウト + 「部分一致送信」 + 停止ルールを備えたCLI実行
- `HTTPAPI`: URLSessionラッパ（ドメイン許可 + 標準ヘッダ + トレース）
- `WebViewScrapeAPI`: WKWebViewリース + `evaluateJavaScript` + スナップショット保存
- `TokenCostAPI`: `ccusage` 連携（現状はCodex/Claude、後で拡張）
- `StatusAPI`: ステータス取得ヘルパ（Statuspage + Workspaceインシデント）
- `LoggerAPI`: スコープ付きロガー + マスキング補助

ルール: プロバイダは `FileManager` / `Security` / 「ブラウザ内部」に直接触れず、**ホストAPI経由**にする。

### 3) プロバイダ固有コードは1カ所に集約
「プロバイダ」と「ホスト」が見分けやすい構成にする。
- `Sources/CodexBarCore/Host/*`（共有ホストAPI + 実装）
- `Sources/CodexBarCore/Providers/<ProviderID>/*`（プロバイダ固有のプローブ/パーサ/モデル）
- `Sources/CodexBar/Providers/*`（プロバイダ固有UIのみ。原則は汎用UI）

## ガードレール（必須）
- 識別情報の分離: プロバイダAの識別/プラン情報をプロバイダBのUIに出さない。
- プライバシー: 既定は端末内解析。ブラウザCookieはオプトインで、WebKit保存以外に保持しない。
- 信頼性: すべてタイムアウト制御。ネットワーク/PTY/UIに無制限待ちはしない。
- 劣化時の挙動: 揺らぐ取得よりキャッシュ優先。古い場合は明確なエラーを出す。

## 新規プロバイダ追加（現行）

チェックリスト:
- `Sources/CodexBarCore/Providers/Providers.swift` に `UsageProvider` ケースを追加。
- `ProviderDefaults.metadata` に `ProviderMetadata` エントリを追加（アプリ側の既定/ラベル）。
- `Sources/CodexBarCore/Providers/<ProviderID>/` にプローブ/フェッチャ実装を追加し `UsageSnapshot` を返す。
  - `fetch() async throws -> <Snapshot>` を持つ小さな `*Probe` 構造体を推奨。
  - `<Snapshot>.toUsageSnapshot()` のマッピングを追加。
- `Sources/CodexBar/Providers/<ProviderID>/` に `ProviderImplementation` 実装を追加。
- `Sources/CodexBar/Providers/Shared/ProviderCatalog.swift` に登録。
- 任意: `ProviderImplementation.settingsToggles(context:)` で共有トグルを出す（独自ビューは避ける）。
- UIに触れる箇所は最小限（アイコンスタイル + ログインフロー + 本当に必要な専用UXのみ）。
- ステータス: メタデータにステータスURL/製品IDを追加。`UsageStore.refreshStatus` が参照。
- テスト: `Tests/CodexBarTests` に解析 + レジストリ/メタデータのテストを追加。
- ドキュメント: `docs/provider.md` に認証フロー + 注意点を追記。

## 新規プロバイダ追加（目標形）
（リファクタ後を想定）
- `Sources/CodexBarCore/Providers/<id>/` を作成:
  - `<id>Provider.swift`（ディスクリプタ）
  - `<id>Probe.swift` / `<id>Fetcher.swift`
  - `<id>Models.swift`（スナップショット型）
  - `<id>Parser.swift`（テキスト/HTML解析が必要な場合）
- 注入されたホストAPIを使って `ProviderImplementation` を実装（Keychain/Cookie/WKWebViewの直接呼び出しはしない）。
- 単一の `ProviderCatalog` リストにディスクリプタを登録。
- UI/設定はカタログから自動構成し、追加の `switch` は不要。
- テストは以下を追加:
  - スナップショット → `UsageSnapshot` のマッピング
  - エラー変換 / タイムアウト挙動
  - 識別情報の分離（プロバイダが他の状態に書き込めない）

## UIメモ（プロバイダ設定）
現状: プロバイダごとのチェックボックス。

目指す方向: テーブル/リスト行（「セッション一覧」のような見た目）。
- プロバイダ（名前 + 簡易認証ヒント）
- 有効トグル
- 状態（OK/古い/エラー + 最終更新）
- 認証ソース（CLI / Cookie / Web / OAuth）※該当時のみ
- アクション（ログイン / 診断 / デバッグログコピー）

プロバイダが5件を超えても、一覧性を保てる構成が望ましい。
