/++
動的配列と静的配列の操作についてまとめます。

要素の初期化、要素の追加(WIP)、要素の削除、ソート(WIP)、ループ操作(WIP)
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

- `remove` : $(LINK https://dlang.org/phobos/std_algorithm_mutation.html#.remove)
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
