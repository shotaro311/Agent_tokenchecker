---
summary: "CodexBarにおけるCursor対応：CookieベースのAPI取得とUX。"
read_when:
  - Cursor使用量の解析をデバッグするとき
  - CursorプロバイダのUI/メニュー挙動を調整するとき
  - Cookie取り込みの問題を調査するとき
---

# Cursor対応（CodexBar）

Cursorは実装済みで、CodexBarは他のプロバイダと並べてCursorの使用量を表示できます。CLIベースのプロバイダとは違い、CursorはWebベースのCookie認証を使います。

## UX
- 設定 → プロバイダ: 「Cursorの使用量を表示」トグル。
- CLI検出は不要。ブラウザCookieがあれば動作します。
- メニュー: プラン使用量、オンデマンド使用量、請求サイクルのリセット時刻を表示します。

### Cursorのメニューバーアイコン
- 他のプロバイダと同じ2本バーのメタファを使用。
- ブランドカラー: ティール（#00BFA5）。

## データ経路（Cursor）

### 使用量取得の方法（Cookieベース）

1. **主要: ブラウザCookie取り込み**
   - Safari: `~/Library/Cookies/Cookies.binarycookies`
   - Chrome: `~/Library/Application Support/Google/Chrome/*/Cookies` の暗号化SQLite
   - Firefox: `~/Library/Application Support/Firefox/Profiles/*/cookies.sqlite`
   - `cursor.com` と `cursor.sh` のCookieが必要

2. **フォールバック: 保存済みセッション**
   - ブラウザCookieが無い場合、「アカウント追加」ログインフローで保存されたセッションを使用
   - WebKitベースのブラウザウィンドウでログイン後にCookieを取得
   - セッションは `~/Library/Application Support/CodexBar/cursor-session.json` に保存

### 使用するAPIエンドポイント
- `GET /api/usage-summary` — プラン使用量、オンデマンド使用量、請求サイクル
- `GET /api/auth/me` — ユーザーのメールアドレスと名前

### 表示内容
- **プラン**: 含まれる使用量の割合とリセットまでのカウントダウン
- **オンデマンド**: プラン上限を超えた使用量（該当時）
- **アカウント**: メールアドレスとメンバーシップ種別（Pro / Enterprise / Team / Hobby）

## Cookie取り込みの詳細

### Safari
- `binarycookies` 形式を解析（ビッグエンディアンのヘッダ + リトルエンディアンのページ）
- フルディスクアクセスの許可が必要な場合があります

### Chrome
- macOS Keychainの「Chrome Safe Storage」キーでCookieを復号
- 初回はKeychainアクセスの許可を求められます
- 複数のChromeプロファイルに対応

### Firefox
- `cookies.sqlite` を読み込み（Keychainプロンプトなし）
- 複数のFirefoxプロファイルに対応

## 注意点
- CLIは不要。Cursorは完全にWebベースです。
- セッションCookieは通常長期間有効で、再ログインは稀です。
- 識別情報は分離: Cursorのメール/プランは他のプロバイダに漏れません。

## デバッグのヒント
- ブラウザログイン確認: Safari/Chrome/Firefox で `https://cursor.com/dashboard` を開き、サインイン状態を確認。
- SafariのCookie権限: システム設定 → プライバシーとセキュリティ → フルディスクアクセス → CodexBarを有効化。
- ChromeのKeychainプロンプト: 「Chrome Safe Storage」へのアクセスを許可。
- 設定 → プロバイダで、Cursorトグルの下に最新エラーが表示されます。
- Cookie取り込みに失敗した場合、「アカウント追加」でWebKitログインを開きます。

## メンバーシップ種別
| API値 | 表示 |
|-----------|---------|
| `pro` | Cursor Pro |
| `hobby` | Cursor Hobby |
| `team` | Cursor Team |
| `enterprise` | Cursor Enterprise |
