---
summary: "Antigravityプロバイダのメモ：ローカルLSPプローブ、クォータ解析、UIマッピング。"
read_when:
  - Antigravityプロバイダを追加/変更するとき
  - Antigravityのポート検出やクォータ解析をデバッグするとき
  - Antigravityのメニューラベルやモデル対応を調整するとき
---

# Antigravityプロバイダのメモ

CodexBarはAntigravityをローカルプロバイダのクォータソースとして扱います。データは端末で動作するAntigravity言語サーバーから取得します（Google/GeminiのAPIは使いません）。APIは内部仕様のため変更リスクがあり、挙動は保守的にしています。

## データソース概要
- プロセス検出: `ps -ax -o pid=,command=` から `language_server_macos` を検索し、Antigravityのマーカーを確認。
  - マーカー判定: `--app_data_dir antigravity` または `/antigravity/` を含むパス。
  - 抽出フラグ: `--csrf_token`（必須）、`--extension_server_port`（HTTPフォールバック）。
- ポート探索: `lsof -nP -iTCP -sTCP:LISTEN -p <pid>` で待受ポートを列挙。
- 接続ポートの決定: すべての待受ポートに対して以下を送信:
  - POST `https://127.0.0.1:<port>/exa.language_server_pb.LanguageServerService/GetUnleashData`
  - ヘッダ: `X-Codeium-Csrf-Token: <token>` + `Connect-Protocol-Version: 1`
  - 最初に200 OKが返ったポートをHTTPSの「connect」ポートとして採用。
- クォータ取得（主）:
  - connectポートに対して POST `.../GetUserStatus`。
  - 失敗時は POST `.../GetCommandModelConfigs` にフォールバック。
  - HTTPS優先、`extension_server_port` のHTTPにフォールバック。

## リクエストボディ（概要）
- `GetUserStatus` / `GetCommandModelConfigs` は最小メタデータのみ:
  - `ideName: antigravity`, `extensionName: antigravity`, `locale: en`, `ideVersion: unknown`。
- `GetUnleashData` のプローブは軽量なコンテキストのみ（認証なしで200を返す程度）。

## 解析とモデル対応
- 参照フィールド:
  - `userStatus.cascadeModelConfigData.clientModelConfigs[].quotaInfo.remainingFraction`
  - `userStatus.cascadeModelConfigData.clientModelConfigs[].quotaInfo.resetTime`
- CodexBar内のクォータ対応:
  - Primary: Claude（`claude` を含み、`thinking` を含まないモデル）。
  - Secondary: Gemini Pro Low（ラベルに `pro` + `low`）。
  - Tertiary: Gemini Flash（ラベルに `gemini` + `flash`）。
  - どれも一致しない場合は、残量が最も少ないものを採用。
- `resetTime` の解析:
  - 可能ならISO-8601、それ以外はUNIXエポック秒を試す。
- `accountEmail` と `planName` は GetUserStatus でのみ取得可能（CommandModelConfigsでは不可）。

## UIマッピング
- プロバイダメタデータ:
  - 表示名: `Antigravity`
  - ラベル: `Claude`（primary）、`Gemini Pro`（secondary）、`Gemini Flash`（tertiary）
- メニューカード + メニュー一覧は他プロバイダと同じ `UsageSnapshot` 形状を使用。
- アイコンスタイル:
  - Geminiのスパークル目に小さな「軌道」ドットを追加して区別。

## 設定とトグル
- 一般: 「Antigravityの使用量を表示」トグル。
- 自動検出: Antigravity言語サーバーが動作中の場合に有効化。
- ステータスチェック: Google WorkspaceのGeminiステータスインシデントを使用。
- Webスクレイプやログインフローはなし。アカウント切替ボタンはガイダンスのアラートを表示。

## CLI挙動
- `codexbar` CLIは `antigravity` をプロバイダとして受け付けます。
- 出力形式は他プロバイダと同じ。バージョン文字列は `nil`（「動作中」しか分からない）。

## 制約とリスク
- 内部プロトコル: エンドポイントやフィールドは非公開で変更される可能性あり。
- ポート検出に macOS の `lsof` が必要。
- TLS信頼: ローカルHTTPSは自己署名証明書のため、CodexBarは非厳格なセッションで通信。
- Antigravityが起動していない場合、プロバイダは利用不可扱い。

## デバッグチェックリスト
1. Antigravityが起動しており、言語サーバープロセスが存在することを確認。
2. `lsof` が利用可能であることを確認。
3. プロセスのコマンドラインに `--csrf_token` があることを確認。
4. デバッグ画面でプロバイダ自動検出を再実行。
5. 設定 → 一般でプロバイダエラーを確認。

## 参照
- 実装: `Sources/CodexBarCore/AntigravityStatusProbe.swift`
- プロバイダ配線: `Sources/CodexBar/ProviderRegistry.swift`
- UIトグル: `Sources/CodexBar/PreferencesGeneralPane.swift`
- 変更履歴: `CHANGELOG.md`
