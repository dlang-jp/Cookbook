# D言語クックブック
[![CircleCI](https://circleci.com/gh/dlang-jp/Cookbook.svg?style=svg)](https://circleci.com/gh/dlang-jp/Cookbook)

処理内容から書き方を逆引きするための資料です。

実際に動くプログラム、そこから生成されるHTMLをまとめます。

言語機能や文法などの疑問があれば、日本語で実行しながら学べる入門資料の「D言語ツアー」もあわせて参照してみてください。

- D言語ツアー
[https://tour.dlang.org/tour/ja/welcome/welcome-to-d](https://tour.dlang.org/tour/ja/welcome/welcome-to-d)

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

# 運用方針
- 欲しいドキュメントや変更はIssueで管理します。
    - これは書けそうだ、と思った方はIssueのAssigneesに自分を割り当ててください。直接Pull Requestしてもらっても構いません。
- masterへのCommitは行わず、変更はすべてPull Requestで行うようにしています。


# その他
## ローカルで出力結果を確認する方法

```bash
dub run gendoc
```
