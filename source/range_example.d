/++
レンジの操作についてまとめます。

## レンジ(Range)とは

レンジ(Range)とは、配列やリストといった要素を順次アクセスできるものを一般化した概念です。

D言語では、データ構造やアルゴリズムをレンジの仕様に合わせて実装することで、さまざまなメリットが得られます。

* レンジの仕様に合ったデータ構造であれば、`std.algorithm`などの既存ライブラリのアルゴリズムをそのまま適用できます。
* レンジを扱えるようアルゴリズムや関数を実装することで、配列や`std.container`などの既存のデータ構造に対してそのまま使用できます。
* レンジの概念はD言語プログラマーの間に広く浸透しています。
  そのため、自作のデータ構造や関数をレンジの仕様に合わせてあれば、他のD言語プログラマーにも使い方がすぐに伝わります。

## 参考

* `std.range` : https://dlang.org/phobos/std_range.html
* `std.algorithm` : https://dlang.org/phobos/std_algorithm.html

TODO:
* 配列・文字列をレンジとして利用する。
* レンジの種類の紹介
* std.rangeの各関数の紹介

+/
module range_example;

/++
最小のレンジ(InputRange)を作る
+/
unittest
{
    // ここでは、簡単なレンジの構造体を作りながら、レンジの定義を説明します。

    /++
    0からn未満の整数を取り出せるレンジを作ります。

    値を取り出すためのレンジは、最低でも以下の3つが必ず必要です。

        * 要素がもう無いかどうかを示す`range.empty`
        * 現在の先頭要素を取得する`range.front`
        * 次の要素へ移動する`range.popFront()`

    この3つのみを持つレンジをInputRangeと呼びます。
    ほかのより高機能なレンジは、InputRangeを拡張した仕様を備えています。
    (より高機能なレンジとして、位置の保存が行えるForwardRangeや、
     前後の両方に移動が行えるBidirectionalRangeがあります)

    レンジを実装する場合、それぞれの操作を
    メンバ関数や通常の関数(UFCSを利用)として用意する必要があります。
    今回は、メンバ関数として実装します。
    +/
    static struct IntRange
    {
        int i = 0;
        int n;
        invariant(i <= n);

        /// nを指定するコンストラクタ
        this(int n) 
        {
            this.n = n;
        }

        /// nに達していたら終了
        @property bool empty() const
        {
            return i == n;
        }

        /// 現在の値を返す
        @property int front() const
        in (!empty)
        {
            return i;
        }

        /// 次の値に移動する
        void popFront()
        in (!empty)
        {
            ++i;
        }
    }

    // 型がInputRangeであるかは、std.rangeのisInputRangeで確認できます。
    import std.range : isInputRange;
    static assert(isInputRange!IntRange);

    // InputRangeで行える操作は下記の通りです。
    auto r = IntRange(3);

    // 空かどうか確かめられます。
    assert(!r.empty);

    // 現在の先頭要素を取り出せます。
    assert(r.front == 0);

    // 次の要素に移動できます。
    r.popFront();
    assert(r.front == 1);

    // 最後の値まで取り出すと、emptyがtrueになります。
    r.popFront();
    assert(r.front == 2);
    r.popFront();
    assert(r.empty); 

    // 自作のレンジに対して、std.algorithmの関数を適用することができます。
    import std.algorithm : equal, filter;

    // std.algorithmのequal関数でIntRangeと配列を比較します。
    assert(equal(IntRange(5), [0, 1, 2, 3, 4]));

    // std.algorithmのfilter関数で、0から10までの間の奇数のみ取り出します。
    auto odds = filter!"a % 2 != 0"(IntRange(10));
    assert(equal(odds, [1, 3, 5, 7, 9]));

    // レンジはforeachステートメントで巡回することも可能です。
    int i = 0;
    foreach (v; IntRange(5))
    {
        assert(v == i);
        ++i;
    }

    // なお、IntRangeはより高機能なものがstd.rangeのiota関数として用意されています。
    // 自作せずにこちらを使用しましょう。
    import std.range : iota;
    assert(equal(iota(0, 5), IntRange(5)));
    assert(equal(filter!"a % 2 != 0"(iota(0, 10)), [1, 3, 5, 7, 9]));
}

