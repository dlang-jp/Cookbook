/++
mirパッケージのSlice操作のうち、2次元の行列に関する頻出の操作を整理します。
+/
module mir_usage.slice_matrix;

/**
行列の転置操作を行う方法

`transposed` 関数を使います
*/
unittest
{
    import mir.ndslice : Slice, sliced, transposed;

    // dfmt off
    Slice!(float*, 2) mat23f = [
        1.0f, 2.0f, 3.0f,
        4.0f, 5.0f, 6.0f
    ].sliced(2, 3);
    // dfmt on
    assert(mat23f.shape == [2, 3]);

    // 2x3 の行列を転置すると 3x2 になります
    auto mat32f = mat23f.transposed();
    assert(mat32f.shape == [3, 2]);

    assert(mat32f == [
        [1.0f, 4.0f],
        [2.0f, 5.0f],
        [3.0f, 6.0f]
    ]);
}

/**
行列を1行ずつインデックスを見ながら処理する方法
*/
unittest
{
    import mir.ndslice : sliced;

    auto mat23 = [
        1, 2, 3,
        4, 5, 6
    ].sliced(2, 3);

    // 行情報だけ回すだけならforeachも可
    foreach (row; mat23)
    {
        assert(row.shape == [3]);
    }

    // インデックス付きで回すなら shape から取ると高階の場合でも使えて汎用性は高い
    foreach (i; 0 .. mat23.shape[0])
    {
        assert(mat23[i].shape == [3]);
        assert(mat23[i] == [1 + 3 * i, 2 + 3 * i, 3 + 3 * i]);
    }

    // コードを短くしたり細かい列挙コストを気にする場合は each も利用できる
    import std.algorithm : each;

    mat23.each!((i, row) {
        // i は foreach と同様に 0, 1, 2, ...として行の数だけ渡される
        // row が束縛された状態で評価されるので事故が少ない
        assert(row.shape == [3]);
        assert(row == [1 + 3 * i, 2 + 3 * i, 3 + 3 * i]);
    });
}

/**
行列の一部に別の行列の値をコピーする
*/
unittest
{
    import mir.ndslice : Slice, slice, sliced;

    Slice!(int*, 2) target = slice!int(4, 4);
    Slice!(int*, 2) part = [1, 2, 3, 4].sliced(2, 2);

    // 貼り付けたい位置をスライス構文で指定して代入します
    target[0 .. 2, 0 .. 2] = part;
    assert(target[0 .. 2, 0 .. 2] == [[1, 2], [3, 4]]);

    // offsetが動的に決まるような場合は、lengthと組み合わせます。
    const offset_row = 1;
    const offset_col = 0;

    target[
        offset_row .. offset_row + part.length!0,
        offset_col .. offset_col + part.length!1
    ] = part;
    assert(target[
        offset_row .. offset_row + part.length!0,
        offset_col .. offset_col + part.length!1
    ] == [[1, 2], [3, 4]]);
}
