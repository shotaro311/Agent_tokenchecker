---
summary: "プロバイダのステータス確認、ソース、指標の対応表。"
read_when:
  - ステータスソースやUIを変更するとき
  - ステータスポーリングやインシデント解析をデバッグするとき
---

# ステータスチェック

## ソース
- OpenAI + Claude + Cursor: Statuspage.io の `api/v2/status.json`。
- Gemini + Antigravity: Gemini製品のGoogle Workspaceインシデントフィード。

## 挙動
- トグル: 設定 → 高度な設定 → 「プロバイダのステータスを確認」。
- `UsageStore` がステータスをポーリングし、指標/説明用に `ProviderStatus` を保存。
- メニューにインシデント概要 + 新鮮度を表示し、アイコンに指標オーバーレイを表示します。

## Workspaceインシデント
- フィード: `https://www.google.com/appsstatus/dashboard/incidents.json`。
- プロバイダメタデータのGemini製品IDを使用。
- 該当プロバイダの最も深刻なアクティブインシデントを選択。

## リンク
- `statusPageURL` があればポーリングとメニューアクションの両方に使用。
- `statusLinkURL` のみある場合はポーリングせず、メニューアクションでリンクを開くだけ。

関連: `docs/providers.md`。
