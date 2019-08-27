# D言語クックブック

処理内容から書き方を逆引きするための資料です。

実際に動くプログラム、そこから生成されるHTMLをまとめます。

# 目次
ドキュメント : [https://dlang-jp.github.io/Cookbook](https://dlang-jp.github.io/Cookbook)

1. [文字列操作](/source/string_example.d)
2. [配列操作](/source/array_example.d)
3. [引数解析](/source/getopt_example.d)

# 使い方
## リポジトリ構成
- docs
    - `*.html` 生成ドキュメント 
- source
    - `*.d` 目的別のサンプルソース

### 補足
- 誤字などなく常に実行できることを保証するため、HTMLはコードから生成する構造としています。
- dubを使って単体テストが通るようにしてあります。

## 実行方法

```bash
dub test
```

# 予定
- 配列操作
- ファイル操作, パス操作
- プロセス操作
- ネットワーク通信
- 日付操作
- 正規表現
- ファイル別操作(JSON, XML, etc.)
- レンジ操作(Range)
- コンテナ・データ構造
- メタプログラミング
- システムコール（Win32API, Posix）
- 引数解析(`std.getopt`)
- ガベージコレクションの制御
- DUBコマンド、設定
- サードパーティ製ライブラリの使用
- 高度なアルゴリズム類

# その他
## ローカルで出力結果を確認する方法

```bash
dub run gendoc
```
