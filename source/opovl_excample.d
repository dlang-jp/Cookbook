/++
演算子オーバーロード

D言語では演算子オーバーロードを定義することができます。

例えばstd.bigintでは、BigIntに対して、整数型のような特徴を持たせるため、四則演算などの演算子オーバーロードを実装しています。

D言語では、演算子オーバーロードを定義する際には、もともとの演算子の意味を損なうような利用方法は非推奨としています。
例えばC++であるように、`std::cout << hogehoge << std::endl;`のような、ビットシフトのための演算子`<<`をストリーム操作のために使用するような利用方法は非推奨です。

See_Also:
    - https://dlang.org/spec/operatoroverloading.html
    - https://dlang.org/dstyle.html#operator_overloading
+/
module opovl_excample;

/++
演算子オーバーロードの活用例: BigInt
+/
@safe unittest
{
    import std.bigint;
    BigInt a = 100_000_000_000;
    BigInt b = 300_000_000_000;

    BigInt c = a + b;
    BigInt d = c * a;
    BigInt e = d - b;
    BigInt f = e / a;
}

/++
opBinary: 二項演算子のオーバーロード

先述のBigIntに代表されるように、組み込み型以外のユーザー定義型であっても、組み込み型と似た特徴を持つ(同じように演算子が使える)ようにすることができるのが、演算子オーバーロードです。
ここでは代表例として、opBinaryという、二項演算子全般をオーバーロードする方法を使って、四則演算できるようにします。
opBinaryはテンプレートのメンバー関数として定義します。これを定義すると、足し算や引き算等二項演算子を使用した際、テンプレート引数に使用された二項演算子の演算子が渡されます。

opBinaryは二項演算子であればよいので、+, -, *, / 以外にも、 ~ や & 等の演算子でも利用できます。

See_Also:
    - https://dlang.org/spec/operatoroverloading.html#binary
+/
@safe unittest
{
    struct Integer
    {
        int data;
        // 足し算の演算子オーバーロード
        // テンプレート制約を使った例
        Integer opBinary(string op)(Integer x) if (op == "+")
        {
            return Integer(data + x.data);
        }
        // 引き算の演算子オーバーロード
        // テンプレートの特殊化を使った例
        Integer opBinary(string op: "-")(Integer x)
        {
            return Integer(data - x.data);
        }
        // 掛け算の演算子オーバーロード
        Integer opBinary(string op)(Integer x) if (op == "*")
        {
            return Integer(data * x.data);
        }
        // 割り算の演算子オーバーロード
        Integer opBinary(string op)(Integer x) if (op == "/")
        {
            return Integer(data / x.data);
        }
    }
    Integer a = Integer(100);
    Integer b = Integer(300);

    Integer c = a + b; /* 100 + 300 */
    assert(c.data == 400);
    Integer d = c * a; /* 400 * 100 */
    assert(d.data == 40_000);
    Integer e = d - b; /* 40000 - 300 */
    assert(e.data == 39_700);
    Integer f = e / a; /* 39700 / 40000 */
    assert(f.data == 397);
}

/++
opUnary: 単項演算子のオーバーロード

` auto b = -a; ` の `-a` (プラスマイナスの符号を逆転する)のように、単項に対する演算子があります。
たとえば、`-`に加えて'+'、`*`(ポインタ外し), `~`(ビット反転), `!`(否定), `++`(インクリメント), `--`(デクリメント)が相当します。

See_Also:
    - https://dlang.org/spec/operatoroverloading.html#unary
+/
@safe unittest
{
    struct Integer
    {
        int data;
        // 符号反転の演算子オーバーロード
        Integer opUnary(string op)() if (op == "-")
        {
            return Integer(-data);
        }
    }
    Integer a = Integer(100);
    Integer b = -a;
    assert(b.data == -100);
}
