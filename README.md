**🌐 Languages:** **日本語** · [English](README.en.md) · [한국어](README.ko.md)

# claude-code-statusline

[Claude Code](https://docs.claude.com/en/docs/claude-code) 用のカスタムステータスライン。以下を1行に表示します:

- 現在のユーザー・作業ディレクトリ・git ブランチ（PS1 風）
- Claude バージョン・モデル名
- トークン使用量（`12.8k` 形式で整形）
- コンテキストウィンドウ使用率（色分け: 🟢 ≤60% / 🟡 61–80% / 🔴 >80%）
- セッション中のコード変更量（`+追加行 / -削除行`）

## プレビュー

```
myuser:/home/myuser/proj (main) | Claude 2.1.140 | Claude Opus 4.7 | 🪙 12.8k toks | 🧠 42.5% | ✏️ +127/-43
```

## 必要なもの

- `jq` — JSON パーサー（ステータスラインは stdin から JSON を読み取ります）
- `awk` — 数値整形と色しきい値処理用
- Bash 4+（WSL および Git Bash on Windows で動作。ネイティブの cmd/PowerShell は**非対応**）

```bash
# Ubuntu/WSL
sudo apt install -y jq

# macOS
brew install jq
```

---

## インストール方法

3 つのインストールパスをサポートしています。多くの場合 **方式 B**（curl ワンライナー）が推奨です。

### 方式 A — ファイル手動コピー

すべての行を読んでから入れたい方向け。

1. スクリプトをダウンロード:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/slo-oww/claude-code-statusline/main/statusline.sh \
     -o ~/.claude/statusline.sh
   chmod +x ~/.claude/statusline.sh
   ```

2. `~/.claude/settings.json` に以下のブロックを追加（既存設定がある場合はマージ）:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash $HOME/.claude/statusline.sh"
     }
   }
   ```

3. Claude Code を再起動するか、新しいセッションを開きます。

### 方式 B / C-1 — curl ワンライナー（推奨）

1 コマンドで完結。スクリプトを自動インストールし、settings の `statusLine` をマージ（既存ファイルはバックアップ）、出力を検証します。

```bash
curl -fsSL https://raw.githubusercontent.com/slo-oww/claude-code-statusline/main/install.sh | bash
```

このインストーラが行うこと:

- `~/.claude/statusline.sh` を作成（実行権限付与込み）
- `~/.claude/settings.json` の `statusLine` キーをマージ — **他のキーは保持**
- 既存 `settings.json` は `settings.json.bak.YYYYMMDDHHMMSS` 形式でバックアップ
- 既存 `settings.json` が無効な JSON の場合は安全に中止
- 新セッションを開く前に動作確認の出力を表示

環境変数でインストール先をカスタマイズ:

```bash
CLAUDE_DIR=$HOME/my-claude curl -fsSL https://raw.githubusercontent.com/slo-oww/claude-code-statusline/main/install.sh | bash
```

### 方式 C-2 — マーケットプレイス経由のプラグイン

スクリプト更新を `/plugin update` で自動取得したい場合に使用。**ただし `settings.json` は手動編集が必要**です — Claude Code のプラグイン仕様ではメインの `statusLine` は宣言できず、`subagentStatusLine` のみがプラグイン作者に公開されているためです。

1. Claude Code セッション内でマーケットプレイスを追加:

   ```text
   /plugin marketplace add slo-oww/claude-code-statusline
   ```

2. プラグインをインストール:

   ```text
   /plugin install statusline@slo-oww-claude-code-statusline
   ```

3. Claude Code がプラグインを配置したパスを確認:

   ```bash
   find ~/.claude/plugins -name 'statusline.sh' 2>/dev/null
   ```

4. `~/.claude/settings.json` に絶対パスを追加:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash /手順3で取得した絶対パス"
     }
   }
   ```

5. Claude Code を再起動。

今後の更新: `/plugin update` でスクリプトが自動更新されますが、`settings.json` の再編集は不要です。

---

## 色分け

コンテキスト使用率に応じて色が変わります:

| 範囲   | 色      | 意味                                |
|--------|---------|------------------------------------|
| ≤ 60%  | 🟢 緑   | 余裕あり                           |
| 61–80% | 🟡 黄   | 注意、`/compact` を検討            |
| > 80%  | 🔴 赤   | 高使用率、compact かセッション終了 |

しきい値は `statusline.sh` 内（`awk -v p="$context_pct"` ブロック）にあり、好みに合わせて調整可能です。

## 使用する JSON フィールド

スクリプトは Claude Code が stdin に渡す JSON から以下のフィールドを読み取ります（v2.1.132+ スキーマ）:

- `.cwd`
- `.model.display_name`
- `.version`
- `.context_window.used_percentage`
- `.context_window.current_usage.input_tokens`
- `.context_window.current_usage.output_tokens`
- `.cost.total_lines_added`
- `.cost.total_lines_removed`

すべてのフィールドは jq の `// 0` または `// "default"` でデフォルト値が設定されているため、Claude Code のスキーマが変更されても安全に動作します。

## アンインストール

```bash
# スクリプトを削除
rm ~/.claude/statusline.sh

# settings.json から statusLine キーのみ削除（他の設定は保持）
tmp=$(mktemp) && jq 'del(.statusLine)' ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json

# プラグインマーケットプレイスからインストールした場合
# /plugin uninstall statusline@slo-oww-claude-code-statusline
# /plugin marketplace remove slo-oww/claude-code-statusline
```

## トラブルシューティング

| 症状 | 原因 / 解決策 |
|------|--------------|
| ステータスラインが空 | `jq` 未インストール → `apt install jq` または `brew install jq` |
| コンテキスト % が `0%` | セッションでまだ API 呼び出しが行われていない（`current_usage` は初回応答まで null） |
| 色が表示されない | ターミナルが ANSI エスケープ非対応 — `TERM` 環境変数を確認 |
| settings.json で `~` が展開されない | `~` の代わりに `$HOME` を使用 — どちらもシェルで動作しますが `$HOME` の方が確実 |
| `is not valid JSON`（インストーラ） | `~/.claude/settings.json` に構文エラー — 手動修正後に再実行 |

## コントリビューション

ステータスラインスクリプトは 3 つのインストール方式をサポートするために 3 箇所に複製されています。**スクリプトの動作を変更する場合は 3 箇所すべて更新**してコミットしてください:

- `statusline.sh` (リポジトリルート、方式 A 直接ダウンロード用)
- `install.sh` (heredoc 本体、方式 B curl ワンライナー用)
- `plugins/statusline/bin/statusline.sh` (方式 C-2 プラグイン用)

シンプルな同期確認:

```bash
diff statusline.sh plugins/statusline/bin/statusline.sh && echo "✅ in sync"
```

PR 歓迎です。

## ライセンス

MIT — [LICENSE](LICENSE) 参照。
