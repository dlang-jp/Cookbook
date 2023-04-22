/++
配列

動的配列と静的配列の操作についてまとめます。

要素の初期化、要素の追加、要素の削除、ソート(WIP)、ループ操作(WIP)

Source: $(LINK_TO_SRC source/_array_example.d)
Macros:
    TITLE=配列を扱う例
+/
module array_example;

/++
初期化の例です
+/
unittest
{
    // 簡単な配列は new T[N] という形式で初期化できます
    int[] data = new int[100];
    assert(data.length == 100);

    // 型に対しコンストラクタを呼ぶような記法でも初期化できます
    data = new int[](100);
    assert(data.length == 100);
}

/++
二次元以上の多次元配列を一括で確保する例です
+/
unittest
{
    // 4要素の配列を要素に持つ2要素の配列を初期化します
    // 型に対してコンストラクタのように初期化でき、引数の順序は外側から（使うときにアクセスする順）指定するイメージになります
    int[][] data = new int[][](2, 4);

    assert(data.length == 2);
    assert(data[0].length == 4);

    int[][][] data2 = new int[][][](2, 3, 4);
    assert(data2.length == 2);
    assert(data2[1].length == 3);
    assert(data2[1][2].length == 4);
}

/++
要素のインデックス、または条件式を指定した値の削除

`std.algorithm` の `remove` を使います

`remove` : $(LINK https://dlang.org/phobos/std_algorithm_mutation.html#.remove)
+/
unittest
{
    import std.algorithm : remove;

    int[] data = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

    // removeは配列を破壊的に編集して結果を返すため、再度使うときは結果を元の変数に代入しなおします
    data = data.remove(1); // インデックス指定（20を削除）
    data = data.remove!(a => a > 50); // 条件式指定（50より大きいものを削除）

    assert(data == [10, 30, 40, 50]);
}

/++
要素の追加の例です。

動的配列に対しては `~=` 演算子で要素を追加することができます。
+/
unittest
{
    int[] data;

    data ~= 10;
    data ~= 20;

    assert(data == [10, 20]);
}

/++
事前にサイズがわからない配列を構築する場合は `std.array` の `appender` を使用すると効率的です。

要素の追加は `~=` または `put` で行います。

`appender` : $(LINK https://dlang.org/phobos/std_array.html#appender)
+/
unittest
{
    import std.array : appender;

    auto buffer = appender!(int[]);

    buffer ~= 10;
    buffer.put(20);

    int[] data = buffer.data;

    assert(data == [10, 20]);
}


/++
配列の一部の要素を置換します

See_Also:
- `replace` : $(LINK https://dlang.org/phobos/std_array.html#replace)
- `replaceInPlace` : $(LINK https://dlang.org/phobos/std_array.html#replaceInPlace)
- `replaceInto` : $(LINK https://dlang.org/phobos/std_array.html#replaceInto)

$(WORKAROUND_ISSUE22230)
+/
unittest
{
    import std.array: replace, replaceInPlace, replaceInto;

    int[] data1 = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

    // replaceの場合：元データは書き変わらず、新しい配列が確保されます
    auto data2 = data1.replace(40, 42);
    assert(data1 == [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]);
    assert(data2 == [10, 20, 30, 42, 50, 60, 70, 80, 90, 100]);

    // 添え字で始まりから終わりの指定方法もあります。
    data2 = data1.replace(3, 4, [42]);
    assert(data2 == [10, 20, 30, 42, 50, 60, 70, 80, 90, 100]);

    // replaceInPlaceの場合：元データも書き換えられます
    // ※InPlace版は値を探して置換する指定方法はありません。
    data2.replaceInPlace(9, 10, [123]);
    assert(data2 == [10, 20, 30, 42, 50, 60, 70, 80, 90, 123]);
    // 値を探してInPlaceで置換する場合は以下のようにします。
    import std.range: iota;
    import std.algorithm: filter;
    foreach (i; iota(0, data2.length).filter!(i => data2[i] == 90))
        data2.replaceInPlace(i, i + 1, [95]);
    assert(data2 == [10, 20, 30, 42, 50, 60, 70, 80, 95, 123]);

    // replaceIntoだとは、置換結果をレンジに格納できます。
    // ※Into版は添え字で始まりから終わりを指定する方法はありません。
    int[10] buffer;
    buffer[].replaceInto(data1, 40, 42);
    assert(buffer[] == [10, 20, 30, 42, 50, 60, 70, 80, 90, 100]);
}

/++
配列の要素をシャッフルします

See_Also:
- `randomShuffle` : $(LINK https://dlang.org/phobos/std_random.html#randomShuffle)
- `Random` : $(LINK https://dlang.org/phobos/std_random.html#Random)
- `unpredictableSeed` : $(LINK https://dlang.org/phobos/std_random.html#unpredictableSeed)

$(WORKAROUND_ISSUE22230)
+/
unittest
{
    import std.random: randomShuffle, Random, Mt19937, unpredictableSeed;
    version (unittest)
    {
        // このサンプルでは結果を一定にするためシードを0に固定し、
        // メルセンヌツイスターを使用した乱数を使う
        auto rnd = Mt19937(0);
    }
    else
    {
        // 実際にはお勧め乱数生成器のRandomを使用して、
        // シードを unpredictableSeed で指定するなどすると良い
        auto rnd = Random(unpredictableSeed);
    }

    int[] data = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

    // シャッフルしたデータにインプレースで更新される。
    data.randomShuffle(rnd);

    // 中身はランダムに変化している
    assert(data != [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]);

    version (X86)
    {
        // randomShuffleの結果は配列のlengthのbit数=ターゲットアーキテクチャのビット数で変わる
        // 32bitだと以下。
        static assert(data.length.sizeof*8 == 32);
        assert(data == [50, 20, 80, 60, 40, 100, 10, 90, 70, 30]);
    }
    version (X86_64)
    {
        // randomShuffleの結果は配列のlengthのbit数=ターゲットアーキテクチャのビット数で変わる
        // 64bitだと以下。
        static assert(data.length.sizeof*8 == 64);
        assert(data == [40, 70, 60, 100, 30, 80, 10, 50, 90, 20]);
    }
}


/++
配列の要素のなかからランダムにピックアップします

※シャッフルの応用です

See_Also:
- `randomShuffle` : $(LINK https://dlang.org/phobos/std_random.html#randomShuffle)
- `uniform` : $(LINK https://dlang.org/phobos/std_random.html#uniform)
- `Random` : $(LINK https://dlang.org/phobos/std_random.html#Random)
- `unpredictableSeed` : $(LINK https://dlang.org/phobos/std_random.html#unpredictableSeed)

$(WORKAROUND_ISSUE22230)
+/
unittest
{
    import std.random: randomShuffle, Random, Mt19937, unpredictableSeed, uniform;
    version (unittest)
    {
        // このサンプルでは結果を一定にするためシードを0に固定し、
        // メルセンヌツイスターを使用した乱数を使う
        auto rnd = Mt19937(0);
    }
    else
    {
        // 実際にはお勧め乱数生成器のRandomを使用して、
        // シードを unpredictableSeed で指定するなどすると良い
        auto rnd = Random(unpredictableSeed);
    }

    int[] data = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

    // シャッフルしたデータにインプレースで更新される。
    // その中から0～(配列長)個取り出す。
    data = data.randomShuffle(rnd)[0..uniform(0, data.length, rnd)];

    // 中身はランダムに変化しているし、長さも変わる
    assert(data.length != 10);
    assert(data != [10, 20, 30, 40, 50, 60, 70, 80, 90, 100][0..data.length]);

    version (X86)
    {
        // randomShuffleの結果は配列のlengthのbit数=ターゲットアーキテクチャのビット数で変わる
        // 32bitだと以下。
        static assert(data.length.sizeof*8 == 32);
        assert(data == [50]);
    }
    version (X86_64)
    {
        // randomShuffleの結果は配列のlengthのbit数=ターゲットアーキテクチャのビット数で変わる
        // 64bitだと以下。
        static assert(data.length.sizeof*8 == 64);
        assert(data == [40, 70, 60, 100, 30]);
    }
}



/++
配列の要素のなかから重複している要素を削除します①

`std.algorithm` の `uniq` を使います。ただし、 `uniq` を使うにはその前にソートが必要です。

See_Also:
- `sort` : $(LINK https://dlang.org/phobos/std_algorithm_sorting.html#.sort)
- `uniq` : $(LINK https://dlang.org/phobos/std_algorithm_iteration.html#.uniq)

$(WORKAROUND_ISSUE22230)
+/
unittest
{
    import std.algorithm: sort, uniq;
    import std.array: array;

    int[] data = [1, 2, 3, 7, 4, 5, 4, 5, 2, 8, 9, 1];
    //    重複 ->                   ^  ^  ^        ^

    // まずソートして
    data.sort();
    // 重複を削除する
    data = data.uniq().array;

    assert(data == [1, 2, 3, 4, 5, 7, 8, 9]);
}

/++
配列の要素のなかから重複している要素を削除します②

ソートしたくない場合にはuniqは使用できません。
そのため、makeIndexでインデックスを一旦経由して重複削除し、mapでインデックスから要素を取り出します

See_Also:
- `sort` : $(LINK https://dlang.org/phobos/std_algorithm_sorting.html#.makeIndex)
- `uniq` : $(LINK https://dlang.org/phobos/std_algorithm_iteration.html#.uniq)

$(WORKAROUND_ISSUE22230)
+/
unittest
{
    import std.algorithm: makeIndex, sort, uniq, map;
    import std.array: array;

    int[] data = [1, 2, 3, 7, 4, 5, 4, 5, 2, 8, 9, 1];
    //    重複 ->                   ^  ^  ^        ^

    // まずソートされたインデックス(ポインタ)の配列を作成し、
    // そのインデックス(ポインタ)の配列を uniq で重複した要素を削除し、
    // インデックス(ポインタ)で sort します
    // そしてインデックス(ポインタ)から元の配列の要素を取り出します
    data = data.makeIndex(new int*[data.length])
        .uniq!((a, b) => *a == *b).array
        .sort()
        .map!(p => *p).array;

    assert(data == [1, 2, 3, 7, 4, 5, 8, 9]);
}

/++
配列の要素のなかから重複している要素を削除します③

ソートしたくない場合にはuniqは使用できません。
先述のアルゴリズムの欠点は、ヒープを使ったり2回ソートしているあたりでしょうか。

ソートしたくない場合、ということはきっとGCとか使いたくないしなるべく効率的なものが望ましいのでしょう。 `@nogc` で成り立つ例を紹介します。
以下のアルゴリズムは `[a,b,c,d]` の配列では、 `a == b, a == c, b == c, a == d, b == d, c == d` の順番で比較し、一致したら都度その要素を末尾に持っていってはじく処理を行っています。
removeでなくbringToFrontを使用する理由は、無駄な要素削除を行わないようにするためです。(内部でswapが行われるので、要素の上書き更新が発生しない)

See_Also:
- `bringToFront`: $(LINK https://dlang.org/phobos/std_algorithm_mutation.html#.bringToFront)

$(WORKAROUND_ISSUE22230)
+/
unittest
{
    int[] data = [1, 2, 3, 7, 4, 5, 4, 5, 2, 8, 9, 1];
    //    重複 ->                   ^  ^  ^        ^

    void uniqWithoutSortInPlace(T)(ref T[] ary) @nogc
    {
        import std.traits: hasElaborateDestructor;
        import std.algorithm: bringToFront, move;
        import std.array: back, popBack;
        //
        if (ary.length == 0)
            return;
        size_t i = 1;
    L_loop_i:
        while (i < ary.length)
        {
            foreach (ref e; ary[0..i])
            {
                if (e == ary[i])
                {
                    bringToFront(ary[i..i+1], ary[i+1..$]);
                    if (hasElaborateDestructor!T)
                        ary.back.move();
                    ary.popBack();
                    continue L_loop_i;
                }
            }
            ++i;
        }
    }
    uniqWithoutSortInPlace(data);
    assert(data == [1, 2, 3, 7, 4, 5, 8, 9]);
}
