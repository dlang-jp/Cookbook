/++
数値計算

標準ライブラリで提供される数値計算の関数などについてまとめます。

主に `std.math` や `std.mathspecial`、 `std.numeric` を使った例を対象とします。
+/
module numeric_example;

/++
浮動小数点数の同値判定の例です。

浮動小数点数は計算の過程で誤差が出るため、相対誤差や絶対誤差を考慮して比較します。

`std.math` の `isClose` を利用します。
+/
unittest
{
    import std.math : isClose;

    // float の場合と double の場合で異なる相対誤差が用いられます
    assert(isClose(1.0f, 0.999_99f));
    assert(!isClose(1.0, 0.999_99));
    assert(isClose(1.0, 0.999_999_999));

    // 第3引数で相対誤差を指定することができます
    assert(isClose(1.0, 1.1, 0.1)); // 10%まで許容する
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
