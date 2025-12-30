---
summary: "CodexBarリリースチェックリスト：パッケージング、署名、ノータライズ、appcast、アセット検証。"
read_when:
  - CodexBarのリリースを開始するとき
  - 署名/ノータライズやappcast手順を更新するとき
  - リリースアセットやSparkleフィードを検証するとき
---

# リリース手順（CodexBar）

SwiftPMのみ。パッケージ/署名/ノータライズは手動（Xcodeプロジェクトなし）。SparkleフィードはGitHub Releasesから配信します。チェックリストはTrimmyのリリースフローにCodexBar固有の内容を統合しています。

**必読:** まず `~/Projects/agent-scripts/docs/RELEASING-MAC.md` のmacOSリリースガイドを本ファイルと並行で開き、CodexBar固有の内容を優先して差分を解消してから開始してください。

## 期待値
- 「CodexBarをリリースして」と言われたら、エンドツーエンドで完遂する: バージョン/CHANGELOG更新、ビルド、署名/ノータライズ、GitHubリリースにzipアップロード、appcast生成/更新（新しい署名込み）、タグ/リリース公開、enclosure URLの200/OK確認、Sparkleでインストール確認（404や古いフィードは不可）。

### リリース自動化メモ（Scripts/release.sh）
- 公開前に必ずフレッシュビルド/ノータライズを実行（キャッシュ成果物は使わない）。
- 次の場合は即失敗: gitが汚れている／CHANGELOG先頭が「Unreleased」／appcastに同じバージョンがある／ビルド番号がappcast最新より大きくない。
- Sparkleキーの事前検証を実施。appcastエントリ + 署名も生成後に自動検証。
- リリースノートは現行CHANGELOGセクションから自動抽出し、GitHubリリースに渡す（手動指定不要）。
- Sparkleのappcastノートは同じCHANGELOGセクションからHTML生成し、エントリに埋め込み。
- 必要ツール/環境変数: `swiftformat`, `swiftlint`, `swift`, `sign_update`, `generate_appcast`, `gh`, `python3`, `zip`, `curl`, と `APP_STORE_CONNECT_*`, `SPARKLE_PRIVATE_KEY_FILE`。

## 前提
- Xcode 26+ が `/Applications/Xcode.app` にインストール済み（ictool/iconutil とSDK）。
- Developer ID Application証明書がインストール済み: `Developer ID Application: Peter Steinberger (Y5PE65HELJ)`。
- ASC API資格情報が環境変数に設定済み: `APP_STORE_CONNECT_API_KEY_P8`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`。
- Sparkleキー: 公開鍵はInfo.plistに設定済み。appcast生成時は `SPARKLE_PRIVATE_KEY_FILE` に秘密鍵パスを設定。
- `Scripts/release.sh` を動かす前にシェルへ環境変数を読み込む（通常 `source ~/.profile`）。

## アイコン（glass .icon → .icns）
```
./Scripts/build_icon.sh Icon.icon CodexBar
```
Xcodeの `ictool` + 透明パディング + iconset → Icon.icns。

## ビルド/署名/ノータライズ（arm64）
```
./Scripts/sign-and-notarize.sh
```
処理内容:
- `swift build -c release --arch arm64`
- Info.plistとIcon.icnsを含めて `CodexBar.app` を作成
- Sparkle.framework / Updater / Autoupdate / XPC を埋め込み
- すべてをruntime + timestamp付きでcodesign（deep）し、rpathを追加
- `CodexBar-<version>.zip` を作成
- notarytoolに送信 → 待機 → ステープル → 検証

注意点（解決済みの罠）:
- Sparkleはframework/Autoupdate/Updater/XPC（Downloader/Installer）を署名しないとノータライズに失敗。
- アプリ署名時に `--timestamp` と `--deep` を使用して署名エラーを回避。
- `unzip` はAppleDouble `._*` を作る可能性があり署名破損で「アプリが壊れています」が出る。Finderか `ditto -x -k CodexBar-<ver>.zip /Applications` を使用。Gatekeeperが警告する場合はアプリを削除して `ditto` で再展開し、`spctl -a -t exec` で検証。
- アップロード前の簡易チェック: `find CodexBar.app -name '._*'` が空であること。`spctl --assess --type execute --verbose CodexBar.app` と `codesign --verify --deep --strict --verbose CodexBar.app` がパッケージ済みバンドルで通ること。

## Appcast（Sparkle）
ノータライズ後:
```
SPARKLE_PRIVATE_KEY_FILE=/path/to/ed25519-priv.key \
./Scripts/make_appcast.sh CodexBar-0.1.0.zip \
  https://raw.githubusercontent.com/steipete/CodexBar/main/appcast.xml
```
`CHANGELOG.md` からHTMLリリースノートを生成し（`Scripts/changelog-to-html.sh`）、appcastエントリに埋め込みます。
アップロードは自動化されていません。appcast + zip をフィードの場所へコミット/公開してください（GitHub Releases / raw URL）。

## タグ & リリース
```
git tag v<version>
./Scripts/make_appcast.sh ...
# upload zip + appcast to Releases
# then create GitHub release (gh release create v<version> ...)
```

## Homebrew（Cask）
CodexBarは `../homebrew-tap` にHomebrew **Cask** を提供します。Homebrewインストール時はSparkleを無効化するため、更新は `brew` で行います。

GitHubリリース公開後、tap caskを更新（`docs/releasing-homebrew.md` を参照）。

## チェックリスト（簡易）
- [ ] 本ファイルと `~/Projects/agent-scripts/docs/RELEASING-MAC.md` を読んだ上で、差分はCodexBarの内容を優先して解消。
- [ ] バージョン更新（scripts/Info.plist, CHANGELOG, About文言）— 先頭のCHANGELOGは確定済みであること（リリーススクリプトが自動取得）。
- [ ] `swiftformat`, `swiftlint`, `swift test`（警告/エラーなし）
- [ ] アイコン変更時は `./Scripts/build_icon.sh`
- [ ] `./Scripts/sign-and-notarize.sh`
- [ ] Sparkle appcastを秘密鍵で生成
  - Sparkle ed25519秘密鍵パス: `/Users/steipete/Library/CloudStorage/Dropbox/Backup/Sparkle/sparkle-private-key-KEEP-SECURE.txt`（主）と `/Users/steipete/Library/CloudStorage/Dropbox/Backup/Sparkle-VibeTunnel/sparkle-private-key-KEEP-SECURE.txt`（古いバックアップ）
  - dSYMアーカイブをアプリzipと一緒にGitHubリリースへアップロード（リリーススクリプトが自動化、未アップロードだと失敗）。
  - 公開後に `Scripts/check-release-assets.sh <tag>` でアプリzipとdSYM zipが揃っていることを確認。
  - appcast + HTMLリリースノート生成: `./Scripts/make_appcast.sh CodexBar-<ver>.zip https://raw.githubusercontent.com/steipete/CodexBar/main/appcast.xml`
  - enclosure署名 + サイズ確認: `SPARKLE_PRIVATE_KEY_FILE=... ./Scripts/verify_appcast.sh <ver>`
- [ ] zip + appcast をフィードにアップロードし、タグ + GitHubリリースを公開（Sparkle URLが生きていること）
- [ ] Homebrew tap: `../homebrew-tap/Casks/codexbar.rb` を更新（url + sha256）、その後確認:
  - `brew uninstall --cask codexbar || true`
  - `brew untap steipete/tap || true; brew tap steipete/tap`
  - `brew install --cask steipete/tap/codexbar && open -a CodexBar`
- [ ] バージョン連続性: 新しいバージョンが連番であること（例: 0.2.0 の次は 0.2.1、0.2.2は飛ばさない）
- [ ] CHANGELOGの整合性: タイトルが1つ、重複バージョンなし、降順で連番
- [ ] リリースページ: タイトル形式 `CodexBar <version>`、ノートはMarkdownの箇条書き（余計な空行なし）
- [ ] CHANGELOG/リリースノートはユーザー向け（内部のみの項目は避け、簡潔に）
- [ ] `CodexBar-<ver>.zip` をダウンロードして `ditto` で展開し実行、署名確認（`spctl -a -t exec -vv CodexBar.app` + `stapler validate`）
- [ ] `appcast.xml` が新しいzip/バージョンを指し、HTMLリリースノートがエスケープされず表示されること
- [ ] GitHub Releasesでアセット（zip/appcast）とノート、バージョン/タグの一致を確認
- [ ] appcast URLをブラウザで開き、新しいエントリが見えることとenclosure URLが到達できることを確認
- [ ] enclosure URLを `curl -I` で手動確認し、200/OK であることを確認
- [ ] appcastのenclosureに `sparkle:edSignature` が含まれていること（`generate_appcast` による生成）
- [ ] GitHubリリース作成時、CHANGELOGエントリをMarkdownの箇条書きで貼り付け（1行1`-`、セクション間は空行）。公開後に表示崩れがないことを確認
- [ ] 以前の署名済みビルドを `/Applications/CodexBar.app` に残し、Sparkleの差分/フル更新をテスト
- [ ] Gatekeeperの手動チェック: パッケージ後に `find CodexBar.app -name '._*'` が空、`spctl --assess --type execute --verbose CodexBar.app` と `codesign --verify --deep --strict --verbose CodexBar.app` が成功
- [ ] Sparkle検証: `/Applications/CodexBar.app` を置き換える場合は終了→置換→再起動→更新テスト
- **リリース完了の定義:** 上記がすべて完了し、appcast/enclosureリンクが解決し、Homebrew caskがインストールでき、既存の公開ビルドからSparkleで更新できること。これに満たない状態は完了ではない。

## トラブルシューティング
- **白いプレートのアイコン**: `build_icon.sh`（ictool）でicnsを再生成し、透明パディングを確認。
- **ノータライズ無効**: deep + timestamp署名を検証（特にSparkleのAutoupdate/Updater/XPC）。再パッケージ + 再署名を実行。
- **アプリが起動しない**: Sparkle.framework が `Contents/Frameworks` 配下にあり、rpathが設定済みか確認。codesign deep。
- **展開後に「アプリが壊れています」**: `ditto -x -k` で再展開し `._*` を削除、`spctl` で再検証。
- **更新のダウンロードが404**: appcastが参照するリリースアセットが存在/公開されているか確認し、`curl -I <enclosure-url>` で検証。
