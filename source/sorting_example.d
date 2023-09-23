/++
データの並び替え・応用

各種ソートアルゴリズムやその応用例をまとめます。
主に std.algoritm (std.algorithm.sorting) を取り扱います。

Source: $(LINK_TO_SRC source/_sorting_example.d)
Macros:
    TITLE=データの並び替え・応用
+/
module sorting_example;


/++
順序比較が可能なデータの配列を並び替える方法

ここではint型の配列を例にしていますが、他の比較可能な型の配列でも同様に使用できます。
+/
@safe unittest
{
    import std.algorithm : sort; // sort関数をインポート

    // 値の書き換えが可能な配列
    int[] data = [8, 3, 6, 9, 1, 5];

    // 昇順
    sort!"a < b"(data);
    assert(data == [1, 3, 5, 6, 8, 9]);

    // 降順
    sort!"a > b"(data);
    assert(data == [9, 8, 6, 5, 3, 1]);

    // 比較はラムダ式を使って同じ処理を記述することができます。
    // 文字列指定のほうが比較的短く済みますが、複雑になる場合は関数に抜き出すなどを検討してください。
    sort!((a, b) => a < b)(data);

    // UFCS (Unified Function Call Syntax) を使って以下のように記述できます。
    // これにより、関数呼び出しをメソッド呼び出しのように記述できます。
    data.sort!"a < b"();

    // カスタム比較関数の例: 偶数が先、奇数が後ろに来るようなソート
    auto evenFirst(int a, int b)
    {
        return (a % 2 == 0) == (b % 2 == 0) ? a < b : a % 2 == 0;
    }
    sort!evenFirst(data);
    assert(data == [6, 8, 1, 3, 5, 9]);
}

/++
上位N個だけソートし、処理を高速化する方法 (topN)

`topN` 関数は、配列の上位N個の要素を効率的にソートする関数です。他の要素の並び順は保証されません。
+/
@system unittest
{
    import std.algorithm : topN;

    int[] data = [8, 3, 6, 9, 1, 5];
    int N = 3;

    // 上位からN位まで正確に降順にソートします
    data.topN!((a, b) => a > b)(N);

    assert(data[0 .. N] == [9, 8, 6]);
}

/++
partialSort を使って効率よく中央値を求める方法
+/
@system unittest
{
    import std.algorithm : partialSort;

    // この関数は、引数として与えられた配列の中央値を計算し返します。
    // ただし、partialSortを使用して配列を部分的に並び替えるため、配列が変更されることに注意してください。
    float calculateMedianWithSideEffects(float[] arr)
    {
        float result;
        if (arr.length % 2 == 0)
        {
            arr.partialSort(arr.length / 2 + 1);
            result = (arr[arr.length / 2 - 1] + arr[arr.length / 2]) / 2;
        }
        else
        {
            arr.partialSort(arr.length / 2);
            result = arr[arr.length / 2];
        }
        return result;
    }

    import std.math : isClose;

    // データが偶数個の場合
    float[] data = [8.0f, 3, 6, 9, 1, 5];

    float calculatedMedian = calculateMedianWithSideEffects(data);
    assert(calculatedMedian.isClose(5.5)); // 中央2個の平均

    // データが奇数個の場合
    data ~= 7;
    float calculatedMedian2 = calculateMedianWithSideEffects(data);
    assert(calculatedMedian2.isClose(6)); // 丁度中央に位置する要素の値
}

/++
重い評価/比較関数を使ったソートを高速化する方法 (schwartzSort)

`schwartzSort` は、「シュワルツ変換」と呼ばれるアルゴリズムを使い、処理に時間のかかる比較をキャッシュして処理負荷を軽減するソートアルゴリズムです。
+/
@safe unittest
{
    import std.algorithm : schwartzSort;

    struct Heavy
    {
        int value;
        int heavyFunction() const
        {
            return value * value;
        }
    }

    Heavy[] data = [Heavy(8), Heavy(3), Heavy(6), Heavy(9), Heavy(1), Heavy(5)];

    // schwartzSort関数を使ってHeavy構造体の配列をソート
    // テンプレート引数として比較する値を得るラムダ関数 (a) => a.heavyFunction を渡す
    data.schwartzSort!((a) => a.heavyFunction);

    // map関数を使ってdata配列の各要素のvalueプロパティを取り出し、
    // 新しい配列を作成し、それが正しくソートされていることを確認する
    import std : map, equal;
    assert(equal(data.map!(a => a.value), [1, 3, 5, 6, 8, 9]));
}

/++
複数の配列を1つとみなしてソートする方法 (chain)
+/
@safe unittest
{
    import std.algorithm : sort;
    import std.range : chain;

    int[] data1 = [8, 3, 6];
    int[] data2 = [9, 1, 5];

    // chain関数を使って複数の配列を連結し、1つの範囲として扱えるようにします。
    auto combined = chain(data1, data2);
    // sort関数を使って、連結された範囲内の要素を昇順に並び替えます。
    sort(combined);

    assert(data1 == [1, 3, 5]);
    assert(data2 == [6, 8, 9]);
}

/++
ソート済みの配列と未ソートの配列をまとめてソートすることで高速化する方法 (completeSort)
+/
@safe unittest
{
    import std.algorithm : completeSort;
    import std.range : SortedRange, assumeSorted;

    // 既にソートされたデータ
    int[] sortedData = [1, 3, 5, 7, 9];

    // 新しい未ソートのデータ
    int[] newData = [8, 6, 4, 2, 0];

    // completeSortを使用して、既存のソートされたデータと新しいデータを組み合わせて全体をソートします
    // 1つ目はソート済みを示すため、assumeSortedを噛ませるのがポイントです
    completeSort(assumeSorted(sortedData), newData);

    // 結果の確認
    assert(sortedData == [0, 1, 2, 3, 4]);
    assert(newData == [5, 6, 7, 8, 9]);
}

/++
複数のキーを条件にソートする方法 (multiSort)
+/
@safe unittest
{
    import std.algorithm : multiSort;

    static struct Point
    {
        int x, y;
    }

    // ソートする Point の配列
    Point[] points = [
        Point(0, 0),
        Point(5, 5),
        Point(0, 1),
        Point(0, 2),
        Point(2, 3),
        Point(2, 1)
    ];

    // multiSortは、複数のキーで要素をソートするための関数です。
    // 引数には、比較条件を表す文字列を与えることでソート条件を指定できます。
    // ここでは、まず x の昇順で並び替え、もし x が同じ場合は y の昇順、で並び替えています
    multiSort!("a.x < b.x", "a.y < b.y")(points);

    // ソート後に期待される配列
    Point[] expectedPoints = [
        Point(0, 0),
        Point(0, 1),
        Point(0, 2),
        Point(2, 1),
        Point(2, 3),
        Point(5, 5)
    ];

    assert(points == expectedPoints);
}

/++
const や immutable の配列を疑似的に並び替える方法

直接 sort 関数で並び替えられないデータに対して、
makeIndex 関数を使って並び替え後のインデックス情報を構築することにより間接的に並び替えを実現します。

この構築されたインデックス情報は、順位をインデックスとして、元の配列の位置を得るために使用することができます。
+/
@safe unittest
{
    import std.algorithm : isSorted, makeIndex;
    import std.range : SortedRange;

    // 書き換え不可能な整数配列を定義します。
    const int[] data = [5, 3, 8, 1, 7, 2, 4, 6];

    // 配列を直接ソートするのではなく、ソート後のインデックス情報を作成します。

    // 昇順のインデックス情報を生成します。
    // 引数 "a < b" は昇順にソートするための比較条件を示します。
    size_t[] ascendingIndices = new size_t[data.length];
    makeIndex!("a < b")(data, ascendingIndices);
    // ascendingIndices[0] は、昇順で最上位(最小値となる要素)のインデックスを示します。
    assert(data[ascendingIndices[0]] == 1);
    // isSorted 関数でインデックス情報が正しくソートされていることを確認します。
    assert(isSorted!((size_t a, size_t b) => data[a] < data[b])(ascendingIndices));

    // 降順のインデックス情報を生成します。
    // 引数 "a > b" は降順にソートするための比較条件を示します。
    size_t[] descendingIndices = new size_t[data.length];
    makeIndex!("a > b")(data, descendingIndices);
    // descendingIndices[0] は、降順で最上位(最大値となる要素)のインデックスを示します。
    assert(data[descendingIndices[0]] == 8);
    // isSorted 関数でインデックス情報が正しくソートされていることを確認します。
    assert(isSorted!((size_t a, size_t b) => data[a] > data[b])(descendingIndices));
}