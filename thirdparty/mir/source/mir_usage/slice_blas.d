/**
mirのSliceとBLASを合わせて使う方法を整理します

BLASを利用するには、環境に合わせて適切なライブラリを用意する必要があります。

Windowsでは既定で Intel MKL が使われます。
Posixでは既定で Open BLAS が使われます。
*/
module mir_usage.slice_blas;

version (MIRUSAGE_INCLUDE_BLAS):

/**
行列積を計算する方法

mir-blasの gemm 関数を利用します
*/
unittest
{
    import mir.ndslice : slice, sliced, transposed;
    import mir.blas : gemm;

    // B = A.x を計算します
    auto A = [
        1f, 2, 3,
        4, 5, 6
    ].sliced(2, 3);

    auto x = [
        1f, 2, 3
    ].sliced(1, 3);

    auto B = slice!float(A.shape[0], x.shape[0]);

    // 通常のgemmには転置フラグがありますが、transposedの有無を見て適切に処理されます
    gemm(1, A, x.transposed, 0, B);

    assert(B[0, 0] == 14);
    assert(B[1, 0] == 32);
}
