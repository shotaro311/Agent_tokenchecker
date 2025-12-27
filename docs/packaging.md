---
summary: "パッケージング、署名、同梱CLIのメモ。"
read_when:
  - ビルドのパッケージング/署名を行うとき
  - バンドル構成やCLI同梱方式を更新するとき
---

# パッケージング & 署名

## スクリプト
- `Scripts/package_app.sh`: arm64ビルド、`CodexBar.app` 出力、Sparkleのキー/フィードを埋め込み。
- `Scripts/sign-and-notarize.sh`: 署名、ノータライズ、ステープル、zip作成。
- `Scripts/make_appcast.sh`: Sparkleのappcast生成とHTMLリリースノート埋め込み。
- `Scripts/changelog-to-html.sh`: バージョン別の変更履歴をSparkle用HTMLに変換。

## バンドル内容
- `CodexBarWidget.appex`（アプリグループのエンタイトルメント付き）を同梱。
- `CodexBarCLI` を `CodexBar.app/Contents/Helpers/` にコピーし、シンボリックリンクに使用。

## リリース
- 完全なチェックリストは `docs/RELEASING.md` を参照。

関連: `docs/sparkle.md`。
