/++
Slice基本操作

mirでは多次元配列（いわゆるテンソル）を扱うための型として `Slice` 型を提供します。
ここでは `Slice` の基本操作について、数値計算で扱う内容を主に整理します。

- Slice型の宣言方法
- Sliceの構築
- Sliceの変更
- Sliceの変形
- Slice同士の基本的な演算

Source: $(LINK_TO_SRC thirdparty/mir/source/mir_usage/slice_common.d)
Macros:
    TITLE=mirのSlice基本操作
+/
module mir_usage.slice_common;

/**
Slice型のインポート、型宣言の利用方法
*/
unittest
{
    // 多次元配列を扱うには、`mir.ndslice` から `Slice` という定義をインポートします。
    // なお今後扱う操作は mirパッケージのモジュール構成上 `mir.ndslice.*` として多数出てきますが、それらは `mir.ndslice` からもインポート可能です。
    // `Slice`を扱うだけであれば、import は基本的に `mir.ndslice` だけ覚えれば十分、ということです。
    import mir.ndslice : Slice;

    // `Slice` 型の変数宣言を行います。
    // 簡単に扱う範囲では、テンプレートの第1引数に要素型のポインタ、第2引数にテンソルの階数、を指定すればOKです。
    // 厳密にはメモリ上の要素レイアウトによって第3引数を指定できますが、ここでは省略します。
    // 省略した場合は `contiguous` というレイアウトになり、全要素が連続なメモリ上に1列に整列された高速な計算に向くレイアウトとなります。

    // たとえば以下の変数は 1階のテンソル であり、つまり要素が1次元に並んだベクトルとなります。
    // なお、型宣言の時点ではベクトルの長さ、つまり「形状（shape）」の情報を持っていません。
    // テンソルの形状は、実際にメモリを確保して初期化する時に決定します。
    Slice!(float*, 1) vector;

    // 第3引数は、省略しているだけで同じ意味です
    import mir.ndslice : SliceKind;

    static assert(is(Slice!(float*, 1) == Slice!(float*, 1, SliceKind.contiguous)));

    // 階数に2を指定した場合、縦横に要素を持った行列になります。
    Slice!(float*, 2) matrix;

    // 3以上を指定して任意のテンソル型を表現することもできます。
    Slice!(float*, 3) tensor;
}

/**
Slice型に新たなメモリを割り当てて初期化する方法
*/
unittest
{
    // slice型の初期化には、主に `slice` 関数を使います。
    import mir.ndslice : Slice, slice;

    // `slice` 関数はテンプレート引数として要素型を受け取り、
    // 関数としての引数で次元ごとの大きさを指定します。
    Slice!(float*, 1) vec3f = slice!float(3);
    Slice!(int*, 1) vec4i = slice!int(4);

    // 引数の数が階数に対応付けられます
    Slice!(int*, 2) mat22i = slice!int(2, 2);

    // 16x16の8bit1チャンネルなアイコン画像を保持するのであれば以下のように初期化します
    Slice!(ubyte*, 2) icon = slice!ubyte(16, 16);

    // アイコン画像を4枚束ねて保持するのであれば次のようになります
    Slice!(ubyte*, 3) icons = slice!ubyte(4, 16, 16);
}

/**
既存の配列データからSliceを構築する方法

sliced 関数を利用します。
*/
unittest
{
    // 既存の配列から Slice 型を構築するには、 `sliced` という関数を使います。
    import mir.ndslice : Slice, sliced;

    // 6要素の配列を2x3行列だと思ってSlice型を構築します。
    // この操作はメモリ確保を行わず、単にビューとして働きます。
    int[] arr = [1, 2, 3, 4, 5, 6];

    // ビューの大きさに指定する部分は、すべて掛け合わせた値が配列の長さと一致する必要があります
    Slice!(int*, 2) view = sliced(arr, 2, 3);
}

/**
既存の多次元配列データから高階のSliceを構築する方法

fuse 関数を利用します。
*/
unittest
{
    // 多次元配列をSliceに変換する場合は fuse 関数を使用します。
    // 元のメモリレイアウトが不明のため、この関数は新しくメモリを確保して要素をコピーします
    import mir.ndslice : Slice, fuse;

    // 多次元データを準備します
    auto src23 = [[1, 2], [3, 4], [5, 6]];

    // fuse を引数なしで呼び出します
    Slice!(int*, 2) mat23 = src23.fuse();
    assert(mat23[0, 0] == 1);

    // これを sliced でやろうとすると以下の解釈になり失敗します。
    import mir.ndslice : sliced;

    version (none)
    {
        // 一見上手くいきそうに期待しますが、要素が配列となる1階のテンソルとなるので型が不一致です
        Slice!(int*, 2) miss = src23.sliced(2, 3);
    }
    // このように解釈されます
    Slice!(int[]*, 1) success = src23.sliced(3);
}

/**
Sliceを多次元配列に変換する方法
*/
unittest
{
    // Slice型をD言語における多次元配列へ変換するには、`ndarray` 関数を利用します
    import mir.ndslice : Slice, slice, ndarray;

    // 階数が1であれば1次元配列が得られます
    Slice!(float*, 1) vec = slice!float(3);
    float[] vec_arr = vec.ndarray();
    assert(vec_arr.length == 3);

    // 行列であれば、すべての配列が同じ長さである整った多次元配列が得られます
    Slice!(float*, 2) mat = slice!float(2, 2);
    float[][] mat_arr = mat.ndarray();
    assert(mat_arr.length == 2);
    assert(mat_arr[0].length == 2);
    assert(mat_arr[1].length == 2);
}

/**
Sliceのデータを読み取ったり書き換えたりする方法
*/
unittest
{
    // Slice型は通常のD言語における標準的な配列とほぼ同じ操作が可能です。
    import mir.ndslice : Slice, slice;

    Slice!(int*, 1) vec3i = slice!int(3);

    // インデックスアクセスによるread/write、配列と同様にスライス操作も可能です。
    assert(vec3i[0] == 0);
    assert(vec3i[1] == 0);
    assert(vec3i[2] == 0);

    vec3i[0 .. 2] = 100;
    vec3i[2] = 1;
    assert(vec3i[0] == 100);
    assert(vec3i[1] == 100);
    assert(vec3i[2] == 1);

    // 2階以上の場合も同様ですが、1つの [] 内にインデックスを並べるようになります
    Slice!(int*, 2) mat33 = slice!int(3, 3);
    // 3x3の行列に対する左上要素の書き換え
    mat33[0, 0] = 10;

    // 複数の次元で同時にスライス操作が可能です。
    // 3x3の行列に対する右下2x2部分の書き換え
    mat33[1 .. 3, 1 .. 3] = 100;

    assert(mat33[0, 0] == 10);
    assert(mat33[1, 1] == 100);
    assert(mat33[2, 2] == 100);

    // 配列と同じで 0 .. $ といった$指定が可能です。
    // 0 .. $ は最初から最後までとなるため、これを使うと行列から列ベクトルを取り出すこともできます。
    auto col1 = mat33[0 .. $, 1];
    assert(col1[0] == 0);
    assert(col1[1] == 100);
    assert(col1[2] == 100);
}

/**
Sliceの値を複数まとめて確認・比較する方法

Sliceの演算は複雑になりやすいため、単体テストで様々な確認がしたくなります。
ここではいくつかの簡便な確認方法を整理します。
*/
unittest
{
    import mir.ndslice : Slice, sliced;

    // 元となるデータを行列らしく用意します
    // dfmt off
    Slice!(int*, 2) mat22 = [
        1, 2,
        3, 4,
    ].sliced(2, 2);
    // dfmt on

    // 2x2のデータは次のように直接多次元配列と比較することができます。
    assert(mat22 == [[1, 2], [3, 4]]);

    // 0行目を取り出す、という指定で2x2の上段が得られます。
    // 加えてレンジに対するopEqualsが提供されるため、配列とそのまま比較できます。
    assert(mat22[0] == [1, 2]);

    // この時は、Sliceの一部を取り出したことで階数が1つ下がったSliceが得られます
    static assert(is(typeof(mat22[0]) == Slice!(int*, 1)));

    // 列ベクトルも階数が落ちるため、配列と同じように比較できます。
    auto col1 = mat22[0 .. $, 1];
    assert(col1 == [2, 4]);
}

/**
Sliceの形状（shape）を確認する方法

shape プロパティで完全な形状情報を得る方法と length を使って特定次元のみ確認する方法があります。
*/
unittest
{
    import mir.ndslice : sliced;

    int[] arr = [1, 2, 3, 4, 5, 6];

    // 配列からビューとしていくつか異なる形状のSliceを作成します。
    auto vec6i = arr.sliced(6);
    auto mat23i = arr.sliced(2, 3);

    // 1階のテンソルは長さ1の配列で形状が得られます。
    size_t[1] shape1 = vec6i.shape;
    assert(shape1 == [6]);

    // 2階のテンソルは長さ2の配列で形状が得られます。以下同様です。
    size_t[2] shape2 = mat23i.shape;
    assert(shape2 == [2, 3]);


    // length プロパティを使うと特定の次元のみ確認することができます。
    // 1階の場合は単に length でアクセスします
    assert(vec6i.length == 6);

    // 2階以上の場合はテンプレート引数で階数を指定します
    assert(mat23i.length!0 == 2);
    assert(mat23i.length!1 == 3);
}

/**
Sliceの全要素数がいくつか確認する方法

shapeをすべて掛け合わせる代わりに elementCount が利用できます。
*/
unittest
{
    import mir.ndslice : Slice, slice;

    Slice!(int*, 3) mat = slice!int(2, 2, 3);
    assert(mat.elementCount == 12);
}

/**
要素が初期化されていないSliceの構築方法

自分が望む行列などを構築するにあたり、何も値が初期化されていないSliceを用意したくなることがあります。
そういった場合は、 `uninitSlice` を使うことで用意できます。
*/
unittest
{
    import mir.ndslice : Slice, uninitSlice;

    // slice関数と利用方法は同じですが、確保されたメモリの値が初期化されないため初期化前の読み取りには注意してください
    Slice!(int*, 2) mat23 = uninitSlice!int(2, 3);

    // 0初期化ではなく1で埋めるような場合に利用できます。
    mat23[] = 1;
}

/**
2階以上のSliceを平坦なSliceおよび配列にする方法
*/
unittest
{
    import mir.ndslice : Slice, sliced;

    Slice!(int*, 2) mat23 = [1, 2, 3, 4, 5, 6].sliced(2, 3);

    // flattened を使うことで要素を1列に並べ直した1階のテンソルに変形できます
    import mir.ndslice : flattened;

    auto vec6 = mat23.flattened();

    // このあと ndarray を呼び出すと1次元配列になります
    import mir.ndslice : ndarray;

    int[] arr = vec6.ndarray();
    assert(arr == [1, 2, 3, 4, 5, 6]);
}

/**
Sliceのデータをそのままに形状だけ変更する方法

reshape 関数を利用すると形状を変更できます。
*/
unittest
{
    import mir.ndslice : Slice, sliced, reshape;

    Slice!(int*, 1) x = [1, 2, 3, 4, 5, 6].sliced(6);

    // 要素数が合わないと実行時エラーになるため、エラーフラグを準備します
    int reshapeErr;

    // 形状とエラーフラグを渡して形状を変更します
    Slice!(int*, 2) y = x.reshape([2, 3], reshapeErr);
    assert(y.shape == [2, 3]);
}

/**
新しいメモリを割り当ててSliceをコピーする方法
*/
unittest
{
    import mir.ndslice : slice;

    auto x = slice!int(2, 2);
    x[0, 0] = 10;

    // Slice型をもう一度slice関数に通すとメモリが割り当てられコピーされます。
    auto y = x.slice();
    assert(y[0, 0] == 10); // 元の値が引き継がれています

    y[1, 1] = -1;
    assert(x[1, 1] != -1); // 元の値は書き換わりません
}