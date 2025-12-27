---
summary: "CodexBarのSparkle連携：アップデータ設定、キー、リリースフロー。"
read_when:
  - Sparkle設定/フィードURL/キーを変更するとき
  - Sparkle appcastを生成/調査するとき
  - 更新トグルやアップデータUIを検証するとき
---

# Sparkle連携

- フレームワーク: Sparkle 2.8.1（SwiftPM）。
- アップデータ: `SPUStandardUpdaterController` を `AppDelegate` が保持（`Sources/CodexBar/CodexbarApp.swift:1`）。
- フィード: Info.plist の `SUFeedURL` は GitHub Releases のappcast（`appcast.xml`）を指す。
- キー: `SUPublicEDKey` は `AGCY8w5vHirVfGGDGc8Szc5iuOqupZSh9pMj/Qs67XI=`。Ed25519秘密鍵は厳重に保管し、appcast生成時に使用する。
- UI: 自動チェックトグル（About）で自動ダウンロードを有効化。更新がダウンロードされた時だけメニューに「更新の準備ができました。今すぐ再起動？」を表示。
- LSUIElement: 使える。チェック時にアップデータウィンドウが表示される。アプリは非サンドボックス。

## リリースフロー
1) 通常通りビルド/ノータライズ（`./Scripts/sign-and-notarize.sh`）し、ノータライズ済み `CodexBar-<ver>.zip` を作成。
2) Ed25519秘密鍵で Sparkle の `generate_appcast` を使いappcastを生成。HTMLリリースノートは `CHANGELOG.md` を `Scripts/changelog-to-html.sh` で変換。
3) `appcast.xml` と zip を GitHub Releases にアップロード（フィードURLは固定）。
4) タグ/リリース。

## 注意点
- HTMLリリースノートはappcastエントリに埋め込まれるため、Sparkleの更新ダイアログは整形済みの箇条書きを表示します（生のタグではない）。
- フィードホストやキーを変更した場合は Info.plist（`SUFeedURL`, `SUPublicEDKey`）を更新し、アプリのバージョンを上げる。
- 自動チェックトグルはSparkleが永続化します。手動の「更新を確認…」はAboutに残る。
- CodexBarはHomebrew版と未署名ビルドではSparkleを無効化します。これらは `brew` かReleasesからの再インストールで更新してください。
