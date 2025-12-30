---
summary: "CodexBarのHomebrew Caskリリース手順（Sparkle無効ビルド）。"
read_when:
  - Homebrew経由でCodexBarをリリースするとき
  - Homebrew tapのcask定義を更新するとき
---

# CodexBar Homebrewリリース手順

HomebrewはCask経由でUIアプリを提供します。Homebrewインストール版ではSparkleを無効化し、Aboutに「brewで更新」の案内が表示されます。

## 前提
- Homebrewがインストール済み。
- tapリポジトリへのアクセス: `../homebrew-tap`。

## 1) 通常のCodexBarリリース
`docs/RELEASING.md` に従い、`CodexBar-<version>.zip` をGitHub Releasesへ公開します。

## 2) Homebrew tapのcask更新
`../homebrew-tap` の `Casks/codexbar.rb` を追加/更新します:
- `url` はGitHubのリリースアセットを指す: `.../releases/download/v<version>/CodexBar-<version>.zip`
- `sha256` を対象zipに合わせる。
- `depends_on arch: :arm64` と `depends_on macos: ">= :sequoia"` を維持（CodexBarはmacOS 15+）。

## 3) インストール確認
```sh
brew uninstall --cask codexbar || true
brew untap steipete/tap || true
brew tap steipete/tap
brew install --cask steipete/tap/codexbar
open -a CodexBar
```

## 4) tap変更の反映
tapリポジトリでコミット + push。
