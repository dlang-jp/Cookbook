# D言語クックブック
[![CircleCI](https://circleci.com/gh/dlang-jp/Cookbook.svg?style=svg)](https://circleci.com/gh/dlang-jp/Cookbook)
[![Actions Status](https://github.com/dlang-jp/Cookbook/workflows/master/badge.svg)](https://github.com/dlang-jp/Cookbook/actions)

ドキュメント : [https://dlang-jp.github.io/Cookbook](https://dlang-jp.github.io/Cookbook)

処理内容から書き方を逆引きするための資料です。

実際に動くプログラム、そこから生成されるHTMLをまとめます。

言語機能や文法などの疑問があれば、日本語で実行しながら学べる入門資料の「D言語ツアー」もあわせて参照してみてください。

- D言語ツアー
[https://tour.dlang.org/tour/ja/welcome/welcome-to-d](https://tour.dlang.org/tour/ja/welcome/welcome-to-d)

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

```console
dub test
```

# 運用方針
- 欲しいドキュメントや変更はIssueで管理します。
    - これは書けそうだ、と思った方はIssueのAssigneesに自分を割り当ててください。直接Pull Requestしてもらっても構いません。
- masterへのCommitは行わず、変更はすべてPull Requestで行うようにしています。


# その他
## ローカルで出力結果を確認する方法

```console
dub run gendoc
```
