/++
SumTypeの例

SumTypeを使用すると、複数の型を複合した型を形成することができます。
タグ付き共用体の1形態です。

See_Also:
    - https://dlang.org/phobos/std_sumtype.html
Macros:
    TITLE=SumType（タグ付き共用体）の例
+/
module sumtype_example;


/++
SumTypeの初期化と値の取り出し方

値の設定はコンストラクタか、代入によって行います。
値の取り出しは、matchテンプレートを使用します。

See_Also:
    - https://dlang.org/phobos/std_sumtype.html#.match
    - https://dlang.org/phobos/std_sumtype.html#.SumType.this
    - https://dlang.org/phobos/std_sumtype.html#.SumType.opAssign
+/
@safe unittest
{
    import std.sumtype: SumType, match;
    // intとdoubleを入れることのできるSumTypeを作成します。
    // 初期値はintの10。
    auto val = SumType!(int, double)(10);

    // valにはint型の10が入っているので、 (int a) にマッチします。
    auto dat1 = val.match!(
        (int a) => a,
        (double a) => 0);
    assert(dat1 == 10);

    // 再代入はこのように行います。
    // int型かdouble型なら代入可能です。
    val = 3.1416;
    // 今度は (double a) にマッチします。
    auto dat2 = val.match!(
        (int a) => a,
        (double a) => 0);
    assert(dat2 == 0);
}
