/++
レンジ

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


Source: $(LINK_TO_SRC source/_range_example.d)
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

    より詳細なInputRangeの仕様・規則については、
    std.rangeのisInputRangeのドキュメントに記載があります。
    https://dlang.org/phobos/std_range_primitives.html#isInputRange

    レンジを実装する場合、それぞれの操作を
    メンバ関数や通常の関数(UFCSを利用)として用意する必要があります。
    今回は、メンバ関数として実装します。
    +/
    static struct IntRange
    {
        int i = 0;
        int n;
        invariant (i <= n);

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

/++
連番のレンジを作る`iota`の例です。
+/
unittest
{
    import std.range : iota;
    import std.algorithm : equal;

    // 0〜4の5つの要素を持つレンジを作る例です。
    assert(iota(5).equal([0, 1, 2, 3, 4]));

    // [1, 5) の4つの要素を持つレンジを作る例です。
    assert(iota(1, 5).equal([1, 2, 3, 4]));

    // [1, 10) の範囲で2つおきの要素を持つレンジを作る例です。
    assert(iota(1, 10, 2).equal([1, 3, 5, 7, 9]));
}

/++
引数に指定した要素だけのレンジを作る`only`の例です。
+/
unittest
{
    import std.range : only;
    import std.algorithm : equal;

    // 指定要素だけを持つレンジを作れます。
    assert(only(1).equal([1]));

    // 複数指定も可能です。
    assert(only(1, 2, 3).equal([1, 2, 3]));

    // onlyでは動的メモリ確保無しでレンジを生成できます。
    // ただし要素のコピーが発生するので、
    // サイズが巨大になる場合は注意が必要です。
    assert((() @nogc nothrow pure @safe => only(1, 2, 3))().equal([1, 2, 3]));
}

/++
引数に指定した要素を無限に繰り返す`repeat`の例です。
+/
unittest
{
    import std.range : repeat;
    import std.algorithm : equal;

    // 5を繰り返すレンジを作ります。
    auto r = repeat(5);
    assert(r.front == 5);
    assert(!r.empty);

    // 次の要素も5です。
    r.popFront();
    assert(r.front == 5);

    // ランダムアクセスも可能です。
    assert(r[0] == 5);
    assert(r[1024] == 5);

    // スライスも可能です。
    assert(r[0 .. 5].equal([5, 5, 5, 5, 5]));
}

/++
指定された関数を使ってレンジを生成する`generate`の例です。
+/
unittest
{
    import std.range : generate, take;
    import std.algorithm : equal;

    // 関数(クロージャ)の戻り値をレンジにします。
    int value = 1;
    auto r = generate!(() => value *= 2);

    // 生成時に一度関数が実行されます。
    assert(r.front == 2);

    // popFrontのたびに関数が実行されます。
    r.popFront();
    assert(r.front == 4);

    // std.rangeのtakeで先頭から指定した数だけ要素を取り出せます。
    assert(r.take(4).equal([4, 8, 16, 32]));
}

/++
漸化式のレンジを生成する`recurrence`の例です。
+/
unittest
{
    import std.range : recurrence, take;
    import std.algorithm : equal;

    // recurrenceを使って階乗を計算します。
    // 漸化式を文字列で指定可能です。
    // aは状態を表す変数で、以前の実行結果が格納されます。
    // nには現在の実行回数が格納されます。
    // 関数の引数には初期状態を渡します。(漸化式が必要とする分だけ必要です)
    // 以下のように書くと、
    // 前回の実行結果 * 現在の実行回数(つまり階乗)を計算するレンジになります。
    auto r = recurrence!"a[n - 1] * n"(1);
    assert(r.front == 1); // 0!

    // popFrontで漸化式の関数が実行されます。
    r.popFront();
    assert(r.front == 1); // 1!
    r.popFront();
    assert(r.front == 2); // 2!
    r.popFront();
    assert(r.front == 6); // 3!
    r.popFront();
    assert(r.front == 24); // 4!

    // 複数の状態を持つ漸化式も表現可能です。
    // 以下ではフィボナッチ数の計算を行います。
    auto fib = recurrence!((a, n) => a[n - 2] + a[n - 1])(1, 1);
    assert(fib.take(7).equal([1, 1, 2, 3, 5, 8, 13]));
}
