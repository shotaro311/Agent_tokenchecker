---
summary: "Scripts/build_icon.sh と ictool で macOS .icon を CodexBar .icns に変換する手順。"
read_when:
  - CodexBarアプリアイコンやアセットパイプラインを更新するとき
  - リリース用にicnsを更新するとき
---

# アイコンパイプライン（macOS .icon → .icns、Xcodebuild不要）

Icon Composer/IconStudio の macOS 26「glass」`.icon` バンドルを、Xcodeに内蔵された非公開CLI（ictool/icontool）で `.icns` に変換します。Xcodeプロジェクトは不要です。

## スクリプト
`Scripts/build_icon.sh ICON.icon CodexBar [outdir]`

処理内容:
1) `/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/` から `ictool`（または `icontool`）を見つける。
2) `.icon` のmacOS既定外観を 824×824 PNG にレンダリング（内部アート + ガラス効果）。
3) 透明パディングで 1024×1024 に拡張（Tahoeの角丸余白を復元し、白いプレートを回避）。
4) すべての必要サイズにダウンスケールして `.iconset` を作成。
5) `iconutil -c icns` で `Icon.icns` を生成。

要件:
- Xcode 26+ がインストール済み（ICツールはXcodeバンドル内）。
- `sips` と `iconutil`（システムツール）。

使い方:
```bash
./Scripts/build_icon.sh Icon.icon CodexBar
```
リポジトリルートに `Icon.icns` が出力されます。

この方式の理由:
- PNGから素直に `sips` / `iconutil` を使うと、内部アートが全面描画のため白/灰色のプレートが残ることがあります。ictoolのレンダリング + 透明パディングはXcodeのアセットパイプラインと一致します。

注意:
- Xcodeが標準パス以外にある場合は、実行前に `XCODE_APP=/path/to/Xcode.app` を設定してください。
- スクリプトはCIで利用可能。Xcodeプロジェクトは不要です。
