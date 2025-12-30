---
summary: "アーキテクチャ概要：モジュール、エントリーポイント、データフロー。"
read_when:
  - 機能開発前にアーキテクチャを確認するとき
  - アプリ構成/ライフサイクル/モジュール境界をリファクタするとき
---

# アーキテクチャ概要

## モジュール
- `Sources/CodexBarCore`: 取得 + 解析（Codex RPC、PTYランナー、Claudeプローブ、OpenAI Webスクレイプ、ステータスポーリング）。
- `Sources/CodexBar`: 状態 + UI（UsageStore、SettingsStore、StatusItemController、メニュー、アイコン描画）。
- `Sources/CodexBarWidget`: 共有スナップショットに接続されたWidgetKit拡張。
- `Sources/CodexBarCLI`: `codexbar` の使用量/ステータス出力用の同梱CLI。

## エントリーポイント
- `CodexBarApp`: SwiftUIのキープアライブ + 設定シーン。
- `AppDelegate`: ステータスコントローラ、Sparkleアップデータ、通知を配線。

## データフロー
- バックグラウンド更新 → `UsageFetcher` / 各プロバイダプローブ → `UsageStore` → メニュー/アイコン/ウィジェット。
- 設定トグル → `SettingsStore` → `UsageStore` の更新間隔 + 機能フラグ。

## 並行性とプラットフォーム
- Swift 6 の厳密な並行性を有効化。Sendableな状態と明示的なMainActor切替を優先。
- macOS 15+ 対応。リファクタ時は非推奨APIを避ける。

関連: `docs/providers.md`, `docs/refresh-loop.md`, `docs/ui.md`。
