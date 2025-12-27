---
summary: "CodexBarウィジェットのWidgetKitスナップショット経路と表示トラブルシュート。"
read_when:
  - WidgetKit拡張の挙動やスナップショット形式を変更するとき
  - ウィジェット更新タイミングを調査するとき
  - ウィジェットギャラリーにCodexBarが出ないとき
---

# ウィジェット

## スナップショットの流れ
- `WidgetSnapshotStore` がアプリグループのコンテナにコンパクトなJSONスナップショットを書き込みます。
- ウィジェットはスナップショットを読み、使用量/クレジット/履歴を描画します。

## 拡張
- `Sources/CodexBarWidget` にタイムライン + ビューがあります。
- メインアプリ側の `WidgetSnapshot` とデータ形状を常に同期してください。

## 表示トラブルシュート（macOS 15+）
ウィジェットがギャラリーに全く出ない場合、原因はほぼ登録/署名/デーモンキャッシュです（SwiftUIコードではないことが多い）。

### 1) 拡張バンドルが想定パスにあるか確認
```
APP="/Applications/CodexBar.app"
WAPPEX="$APP/Contents/PlugIns/CodexBarWidget.appex"

ls -la "$WAPPEX" "$WAPPEX/Contents" "$WAPPEX/Contents/MacOS"
```

### 2) PlugInKit登録（pkd）
```
pluginkit -m -p com.apple.widgetkit-extension -v | grep -i codexbar || true
pluginkit -m -p com.apple.widgetkit-extension -i com.steipete.codexbar.widget -vv
```
メモ:
- `+` = 使用対象、`-` = 無視（PlugInKitの選出）。
- 欠落や無視の場合、強制追加して再選出:
```
pluginkit -a "$WAPPEX"
pluginkit -e use -p com.apple.widgetkit-extension -i com.steipete.codexbar.widget
```
- 重複がないか確認（古いインストール/優先順位）:
```
pluginkit -m -D -p com.apple.widgetkit-extension -i com.steipete.codexbar.widget -vv
```
複数パスが出る場合、古いものを削除し `CFBundleVersion` を上げてください。

### 3) コード署名 + Gatekeeperチェック
ウィジェットはシステムデーモンで読み込まれます。署名失敗で非表示になることがあります。
```
codesign --verify --deep --strict --verbose=4 /Applications/CodexBar.app
codesign --verify --strict --verbose=4 "$WAPPEX"
codesign --verify --strict --verbose=4 "$WAPPEX/Contents/MacOS/CodexBarWidget"
spctl --assess --type execute --verbose=4 /Applications/CodexBar.app
```

### 4) 正しいデーモンの再起動（NotificationCenterだけでは不十分）
```
killall -9 pkd || true
sudo killall -9 chronod || true
killall Dock NotificationCenter || true
```

### 5) ウィジェットギャラリーを開きながらログを監視
```
log stream --style compact --predicate '(process == "pkd" OR process == "chronod" OR subsystem CONTAINS "PlugInKit" OR subsystem CONTAINS "WidgetKit")'
```

### 6) パッケージングの確認
- ウィジェットのBundle IDは `com.steipete.codexbar.widget` であること。
- `NSExtensionPointIdentifier` は `com.apple.widgetkit-extension` であること。
- フォルダ名は `CodexBarWidget.appex` に一致すること。

任意: LaunchServicesの再シード（稀に効くが低リスク）:
```
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -seed
```

## よくある表示後の問題: データが古い
ウィジェットが出るがプレビューのままの場合:
- アプリがフォールバックパスにスナップショットを書き、ウィジェットがアプリグループのコンテナを読んでいる可能性。
- アプリ/ウィジェットが同じアプリグループコンテナを解決しているか検証してください。

関連: `docs/ui.md`, `docs/packaging.md`。
