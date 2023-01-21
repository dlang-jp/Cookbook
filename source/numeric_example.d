/++
数値計算

標準ライブラリで提供される数値計算の関数などについてまとめます。

主に `std.math` や `std.mathspecial`、 `std.numeric` を使った例を対象とします。

Source: $(LINK_TO_SRC source/_numeric_example.d)
Macros:
    TITLE=数値計算でよく利用される関数などの使用例
+/
module numeric_example;

/++
浮動小数点数の同値判定の例です。

浮動小数点数は計算の過程で誤差が出るため、相対誤差や絶対誤差を考慮して比較します。

`std.math` の `isClose` を利用します。

std.math.isClose : $(LINK https://dlang.org/phobos/std_math.html#.isClose)$(BR)
+/
unittest
{
    import std.math : isClose;

    // float の場合と double の場合で異なる相対誤差が用いられます
    assert(isClose(1.0f, 0.999_99f));
    assert(!isClose(1.0, 0.999_99));
    assert(isClose(1.0, 0.999_999_999));

    // isClose は、第3引数で相対誤差、第4引数で絶対誤差をそれぞれ指定します。
    // 相対誤差は型によって異なり、絶対誤差の既定値は 0.0 です。
    assert(isClose(1.0, 1.1, 0.1)); // 相対誤差10%まで許容し、絶対誤差は考慮しない
}

/++
内積を計算する例です。

`std.numeric` の `dotProduct` を利用します。
+/
unittest
{
    import std.numeric : dotProduct;

    auto a = [1.0, 2.0, 3.0];
    auto b = [-1.0, 2.0, -3.0];

    auto s = dotProduct(a, b);
    assert(s == -6.0);
}

/++
コサイン類似度を計算する例です。

2つのレンジを受け取って、その類似度を0-1で返します。
+/
unittest
{
    import std.math : isClose;
    import std.numeric : cosineSimilarity;

    auto a = [3.0, 2.0, 1.0, 1.0];
    auto b = [2.0, 2.0, 1.0, 0.0];

    auto s = cosineSimilarity(a, b);
    assert(s.isClose(0.9467292624062573));
}

/++
標準正規分布の累積分布関数とその逆関数を計算する例です。

それぞれ `std.mathspecial` モジュールの `normalDistribution` と `normalDistributionInverse` という関数で提供されます。

正規分布 : $(LINK https://ja.wikipedia.org/wiki/%E6%AD%A3%E8%A6%8F%E5%88%86%E5%B8%83)

累積分布関数 : $(LINK https://ja.wikipedia.org/wiki/%E7%B4%AF%E7%A9%8D%E5%88%86%E5%B8%83%E9%96%A2%E6%95%B0)
+/
unittest
{
    import std.math : isClose;
    import std.mathspecial : normalDistribution, normalDistributionInverse;

    // 引数は real 型で提供されます。
    real x = 0.5;

    // 標準正規分布であり、平均は0、分散は1となります。
    // 累積分布関数なので、戻り値は確率であり [0, 1] となります。
    auto p = normalDistribution(x);
    assert(p.isClose(0.691462461));

    // 累積分布の逆関数を計算します。引数に確率を指定し、対応する値を得ます。
    auto x_inv = normalDistributionInverse(p);
    assert(x_inv.isClose(x));
}
