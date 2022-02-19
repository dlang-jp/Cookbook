/++
単体テスト

様々な単体テストの記法についてまとめます。

Source: $(LINK_TO_SRC source/_unittests_example.d)
+/
module unittests_example;

/++
unittestとassert

実行時ロジックについては、`assert` を使ってテストを記述します。

unittestとassertは両方共debugビルドのときにのみ使われ、releaseビルドのときには除去されます。
+/
unittest
{
    int n = 100;
    // 満たすべき条件式をassertを使って書きます。
    assert(n == 100);

    // 文字列（配列）は直接比較が可能です。
    string s = "TEST";
    assert(s == "TEST");

    // 失敗したときのメッセージは第2引数で指定します。
    // サンプルのため、コメントを解除する必要があります。
    //assert(s != "TEST", "'TEST'である必要があります！ (" ~ s ~ ")");
}

/++
unittestとstatic assert

コンパイル時に確定する内容については、`static assert`を使ってテストを記述します。

このテストに失敗するとコンパイルエラーになります。
+/
unittest
{
    // 型の特性やコンパイル時定数についてテストできます
    // ここでは型が整数型かどうかをテストします
    import std.traits : isIntegral;

    static assert(isIntegral!int);
    static assert(!isIntegral!float);
}

/++
例外が発生することをテストする方法

`assertThrown` 関数を使い、対象の関数が例外を発生させることを確認します。
ここでは関数の事前条件チェックでAssertErrorが起きることを確認します。

core.exception : $(LINK https://dlang.org/phobos/core_exception.html)$(BR)
std.exception : $(LINK https://dlang.org/phobos/std_exception.html)$(BR)
+/
unittest
{
    // AssertError は言語機能の一部であるため core.exception に属します
    import core.exception : AssertError;

    // assertThrown はライブラリ機能であるため std.exception に属します
    import std.exception : assertThrown;

    // テスト対象の関数を用意します
    void test(int n)
    in(n > 0, "引数 n は正の数である必要があります")
    do
    {
        // 実装は省略
    }

    // assertThrownは「対象の式が例外を発生させない」ときにAssertErrorを発生させます。
    // 対象の式は lazy 引数となっているため即時評価されず、内部でtry-catchされています。
    assertThrown!AssertError(test(0));

    // これをライブラリ機能を使わずに書くと以下のようになります。
    try
    {
        test(0);
    }
    catch (AssertError)
    {
        return;
    }
    assert(false);
}

/++
@safe や @nogc 、nothrowであることを保証する方法

属性をテストするには unittest自体を当該属性で修飾する方法が多く使われます。
このテストサンプルは `nothrow` 属性で修飾されています。

`std.traits` の機能で関数属性を取り出すことも可能ですが、ブロック全体を修飾することで漏れがなくなります。
+/
nothrow unittest
{
    // nothrowを付けたローカル関数を定義します
    void test() nothrow
    {
    }

    // このサンプルは nothorow で修飾されているため、
    // これがコンパイルできればtest関数もnothrowということになります。
    test();
}

/++
浮動小数点数をテストする方法

数値計算の結果は厳密なテストが難しいため `isClose` を使い相対誤差などを利用した比較を行います。

std.math.isClose : $(LINK https://dlang.org/phobos/std_math.html#.isClose)$(BR)

類似の `approxEqual` はDMDのバージョンで非推奨となったため、 `isClose` を使うことが推奨されています。
+/
unittest
{
    import std.numeric : secantMethod;
    import std.math : isClose, cos;

    float f(float x)
    {
        return cos(x) - x * x * x;
    }

    // セカント法を用いて区間内で関数fの結果が0になる引数（根）を探索します
    auto x = secantMethod!(f)(0f, 1f);
    assert(isClose(x, 0.865474));

    // isClose は、第3引数で相対誤差、第4引数で絶対誤差をそれぞれ指定します。
    // 相対誤差は型によって異なり、絶対誤差の既定値は 0.0 です。
    assert(isClose(x, 0.865474, 0.0001, 1e-6));

    // その他、こういった数値計算では結果の性質をテストすることも有効です。
    // これは一般に `Propety-based testing` と呼ばれる方法です。
    // 結果は関数の根であり0になるため、少しずれた位置で結果を2乗すれば必ず大きくなるという性質を確認します。
    auto min = f(x);
    auto min_1p = f(x + 0.001f);
    auto min_1n = f(x - 0.001f);
    assert(min ^^ 2 < min_1p ^^ 2);
    assert(min ^^ 2 < min_1n ^^ 2);
}

/++
一般的なRangeの内容をテストする方法

std.algorithm 内の equal 関数を使ってRange同士を比較します。

std.algorithm : $(LINK https://dlang.org/phobos/std_algorithm_comparison.html)
+/
unittest
{
    import std.algorithm : filter, equal;

    int[] source = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    auto filtered = source.filter!"a % 2 == 0"();

    // filterの戻り値は遅延評価するRangeオブジェクトであり、配列と直接比較することはできません
    // dfmt off
    static assert(!__traits(compiles, {
        assert(filtered == [0, 2, 4, 6, 8]);
    }));
    // dfmt on

    // equal関数を使うと任意のRangeが配列と比較できます
    assert(equal(filtered, [0, 2, 4, 6, 8]));
}

/++
ファイルの生成などを確認する方法

単体テストはそれぞれが独立し、順不同および繰り返し実行できることが重要です。

最初と `scope(exit)` でファイルの破棄を行うとテストの再現性や独立性が高まります。
+/
@system unittest
{
    import std.file : write, readText, exists, remove;

    enum path = "test.txt";
    if (path.exists())
        remove(path);

    scope (exit)
        if (path.exists())
            remove(path);

    write(path, "TEST");
    assert(readText(path) == "TEST");
}
