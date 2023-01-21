/++
テンプレート

テンプレートについてまとめます。
- テンプレート
- テンプレート関数
- テンプレートクラス・構造体
- mixinテンプレート(TODO)
- enum, aliasのテンプレート(TODO)

See_Also:
    - https://dlang.org/spec/template.html

Source: $(LINK_TO_SRC source/_template_example.d)
Macros:
    TITLE=テンプレートの使用例
+/
module template_example;

/++
テンプレートの例です
+/
unittest
{
    // テンプレートの中には構造体やクラス、関数、定数などが定義できます。
    template Data(T)
    {
        struct X
        {
            T data;
        }
        void copy(X src, ref X dst)
        {
            dst.data = src.data;
        }
    }
    // Data!intで、Tをintに特殊化します。
    // 特殊化されたテンプレートは一種の名前空間として利用されます。
    Data!int.X x;
    Data!int.X y;
    x.data = 10;
    Data!int.copy(x, y);
    assert(y.data == 10);
}

/++
テンプレート関数の例です

テンプレートを使った関数の定義・使い方の例です。
構文糖によって通常のテンプレートを使うよりも見やすく、書きやすく使用することができます。
+/
unittest
{
    import std.math: isClose;

    // +演算子で計算できるならどんな型でも対応可能なadd関数
    T add(T)(T a, T b)
    {
        return a + b;
    }

    int x = 10;
    int y = 20;
    // add関数のTをint型に特殊化して使用する。
    assert(add!int(x, y) == 30);
    // `add!int(x, y)`` と書いてもよいが、
    // add関数は T = int を推論してくれるので、`!int`の部分は不要。
    assert(add(x, y) == 30);

    double t = 3.14;
    double u = 0.001592;
    // add関数をdouble型のために使用する。
    assert(add(t, u).isClose(3.141592, 0.0000001, 0.0000001));
}

/// ditto
unittest
{
    // 前述のadd関数は以下の構文糖となっています
    template add(T)
    {
        T add(T a, T b)
        {
            return a + b;
        }
    }
    int x = 10;
    int y = 20;
    // テンプレートと同名のメンバーがある場合は、
    // 以下のようなアクセスができなくなります
    //assert(add!(int).add(x, y) == 30);

    // 以下3つはすべて同じ意味で、構文糖によって
    // 簡略化された書き方ができます
    assert(add!(int)(x, y) == 30);
    assert(add!int(x, y) == 30);
    assert(add(x, y) == 30);
}

/++
テンプレートクラス・構造体の例です
+/
unittest
{
    // テンプレート構造体
    struct Point(T)
    {
        T x;
        T y;
        Point!T add(Point!T pt)
        {
            return Point(x + pt.x, y + pt.y);
        }
    }
    // Point!intでint型に特殊化
    // 関数と違い、 Point(10, 20) 等として推論はできないので注意。
    Point!int p = Point!int(10, 20);
    Point!int t = Point!int(30, 40);
    Point!int v = p.add(t);
    assert(v.x == 40);
    assert(v.y == 60);

    // floatで特殊化する場合はこう
    Point!float r;
    Point!float s;

    // クラスならこう
    class Vector(T){}
}
