/++
乱数

乱数操作についてまとめます。
+/
module random_example;

/++
基本的な乱数を生成する例です。
+/
@safe unittest
{
    // 乱数を使うには std.random をimportして使います。
    // 最も簡単な乱数を得る方法は、一様乱数を生成する uniform を使う方法です。
    import std.random : uniform;

    // 0.0以上、1.0未満の乱数を生成します。
    auto p = uniform(0.0, 1.0);
    assert(0.0 <= p && p < 1.0);

    // 結果の型は引数から推論されるため、floatが必要な場合は引数をfloat型にします。
    auto fp = uniform(0.0f, 1.0f);
    assert(0.0f <= fp && fp < 1.0f);

    // 半開区間ではなく閉区間（両端を含む）で乱数の値域を設定する場合、uniformのテンプレートパラメーターを使います。
    auto q = uniform!"[]"(-1.0, 1.0);
    assert(-1.0 <= q && q <= 1.0);

    // 0以上1未満の乱数を生成する場合は uniform01 という関数が使えます。
    import std.random : uniform01;

    auto r = uniform01();
    auto fr = uniform01!float();

    assert(0.0 <= r && r < 1.0);
    assert(0.0 <= fr && fr < 1.0);
}

/++
配列を乱数で初期化する例です。
+/
@safe unittest
{
    import std.random : uniform;
    import std.algorithm.iteration : each;

    // 任意の長さを持つ配列に対して、std.algorithmのeachを使うことで全要素を参照することができます。
    auto data = new double[](1000);
    data.each!((ref x) { x = uniform!"[]"(-10.0, 10.0); });

    foreach (x; data)
    {
        assert(-10.0 <= x && x <= 10.0);
    }
}

/++
シミュレーション用途など、再現可能な乱数を作るためにシードを指定する例です。

実行時に毎回異なるシードを使う場合は、 unpredictableSeed を使用します。
+/
@safe unittest
{
    // メルセンヌツイスター法による Random のほかに Xorshift の乱数生成器も使うことができます。
    import std.random : Random, Xorshift, uniform;

    Random rndGen1;
    Xorshift rndGen2;

    // シードを設定することで何度やっても同じ値が取得可能になります。
    // 実験などではこのrndGenをベースに乱数を作ることになります。
    rndGen1.seed = 1000;
    rndGen2.seed = 1000;

    assert(rndGen1.front == 2807145907u);
    assert(rndGen2.front == 2096656543u);

    // 乱数生成器は無限Rangeであるため、次の要素を取り出す前にpopFrontします。
    rndGen2.popFront();

    // uniformなどの乱数を取得するための関数は、最後の引数に乱数生成器を指定することができます。
    // これらは呼び出すたびに内部的にpopFrontされるため、取得の度に新しい乱数が取得できます。
    auto p = uniform(-1.0f, 1.0f, rndGen1);
    auto q = uniform(-1.0f, 1.0f, rndGen1);

    import std.math : approxEqual;

    assert(p.approxEqual(0.307179));
    assert(q.approxEqual(-0.588957));
}

/++
標準正規分布に基づく乱数を生成する例です。

std.mathspecial にある normalDistributionInverse を使うことで確率変数から逆変換できます。

`normalDistributionInverse` : $(LINK https://dlang.org/phobos/std_mathspecial.html#normalDistributionInverse)
+/
@safe unittest
{
    import std.random : uniform;
    import std.mathspecial : normalDistributionInverse;

    // 0と1は-infとinfに振り切れてしまうため、値域を指定することで除外できます。
    auto p = normalDistributionInverse(uniform!"()"(0.0, 1.0));
    assert(-double.infinity < p && p < double.infinity);
}
