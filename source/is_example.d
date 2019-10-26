/++
is式

is式についてまとめます。
+/
module is_example;

/++
# 正当性の検証
+/
@safe unittest
{
    // `is( Type )`でTypeが正当な型であるかを検査します。

    // 通常の型に対しては`true`を返します。
    static assert(is(int));
    static assert(is(void));
    static assert(is(string[]));

    // 存在しない型に対しては`false`を返します。
    static assert(!is(Int));

    // まだ定義されていない型にも`false`を返します。
    static assert(!is(Foo));
    struct Foo {}
    static assert( is(Foo));

    // 関数は型として正当ですが、関数の配列は不正な型です。
    alias func = int(int);
    static assert( is(func));
    static assert(!is(func[]));

    // is式は構文的に正しいものしか検査できません。
    // static assert(!is(*int));
    // static assert(!is([][]));

    // `is(typeof({ statement; }))`でstatementの正当性を検査できます。
    static assert( is(typeof({ int x = 3; })));
    static assert(!is(typeof({ int x = null; })));

    // これは`__traits(compiles, { statement })`に近い動作となります。
    static assert( __traits(compiles, { int x = 3; }));
    static assert(!__traits(compiles, { int x = null; }));

    // `is (Type identifier)`で`Type`の正当性を検証した後、正当であった場合には`identifier`が`Type`のaliasとして機能します。
    // これは`static if`と組み合わせるのが有効です。
    alias T = ulong;
    static if (is(T[] TArray)) {
        alias A = TArray;
    } else {
        alias A = void[];
    }
    // `A`は、`T[]`が正当な型であった場合には`T[]`を、そうでなければ`void[]`を表します。
}

/++
# 暗黙の型変換可能かどうかの検証
+/
@safe unittest
{
    // `is(Src : Dst)`で`Src`が`Dst`に暗黙の型変換可能であるかどうかを検査します。
    static assert( is(int : double));
    static assert(!is(double : int));
    static assert( is(char : char));

    // `alias`に対しても有効です。
    alias Foo = float;
    static assert(is(byte : Foo));

    // `alias this`に対しても有効です。
    struct Bar {
        int x;
        alias x this;
    }
    static assert(is(Bar : int));

    // `is(Src identifier : Dst)`で検査結果が`true`だった場合に`identifier`が`Dst`を示すようになります。
    alias T = ulong*;
    static if (is(T L : L*)) {
        // `T`がポインタ型であったとき、`L`はポインタを外した型として宣言されます。
    }

    // `is(Src : Dst, parameters)`で`Src`や`Dst`のためのtemplateパラメータをつけられます。
    struct MyStruct(Type) {
        Type[] mem;
        alias mem this;
    }
    alias IntStruct = MyStruct!int;
    static assert (is(IntStruct : T[], T));

    // static if と組み合わせることであるtemplateパラメータを含む型からパラメータを抽出することができます。
    static if (is(IntStruct : S[], S)) {
        // `IntStruct`がなんらかの配列型に暗黙の型変換可能である場合、その要素型として`S`が宣言されます。
    }

    // `is(Src identifier : Dst, parameters)`でそれらを組み合わせることができます。
    static if (is(IntStruct UArray : U[], U)) {
        // ここで`UArray`は`int[]`を表します。
    }
}

/++
# 型の分類
+/
@safe unittest
{
    import std.typecons;
    import std.traits;

    // `is(Type == Type2)`で`Type`が`Type2`と等しいかどうかを検証します。
    static assert( is(int == int));
    static assert(!is(int == const int));

    // `is(Type != Type2)`は使えないので注意が必要です。
    // static assert( is(int != double));

    // `alias`に対しても有効です。
    alias Foo = string;
    static assert(is(Foo == string));

    // `is(Type == Keyword)`で`Type`が特定の条件を満たすかどうかを検証できます。

    // 構造体であるかどうかの検証には`struct`を用います。
    struct MyStruct {}
    static assert(is(MyStruct == struct));

    // 共用体であるかどうかの検証には`union`を用います。
    union MyUnion {}
    static assert(is(MyUnion == union));

    // その他にも`class`, `interface`, `enum`, `function`, `delegate`が使えます。
    class MyClass {}
    interface MyInterface {}
    enum MyEnum { Member }
    alias MyDelegate = void delegate();
    static assert(is(MyClass == class));
    static assert(is(MyInterface == interface));
    static assert(is(MyEnum == enum));
    static assert(is(MyDelegate == delegate));

    // `function`は関数そのものを表しており、関数ポインタに対しては`false`を返します。
    alias MyFunction = void();
    alias MyFunctionPtr = void function();
    static assert( is(MyFunction == function));
    static assert(!is(MyFunctionPtr == function));

    // `const`, `immutable` `shared`によって型の修飾子も判定できます。
    static assert(is(const int == const));
    static assert(is(immutable int == immutable));
    static assert(is(shared int == shared));
    static assert(is(const shared int == shared));
    static assert(is(const shared int == const));

    // `is(Type identifier == Keyword)`で検査後に`identifier`をaliasとして扱えます。
    static if (is(const int T == const))
        static assert(is(T == const int));
    else
        static assert(false);

    // このとき、`Keyword`として新たに`super`, `return`, `__parameters`が使えるようになります。

    // `is(Type identifier == super)`は`Type`が親クラス(インターフェース)を持つ場合`true`を返し、その際`identifier`として親クラス(インターフェース)のリストを宣言します。
    interface ParentInterface {}
    class ParentClass {}
    class ChildClass : ParentClass, ParentInterface {}
    static if (is(ChildClass S == super))
    {
        static assert(is(S[0] == ParentClass));
        static assert(is(S[1] == ParentInterface));
    }
    else
    {
        static assert(false);
    }

    // `is(Type identifier == return)`は`Type`が関数、関数ポインタ、delegateだったときに`true`を返し、その際`identifier`として返り値の型を宣言します。
    alias F1 = void();
    static if (is(F1 R == return))
        static assert(is(R == void));
    else
        static assert(false);

    // `is(Type identifier == __parameters)`は`Type`が関数だったときに`true`を返し、その際`identifier`としてパラメータ型のリストを宣言します。
    int func(int x, double y, string z = "def") { return 100; }
    static if (is(typeof(func) Ps == __parameters))
    {
        // パラメータの型一覧を取得できます。
        static assert(is(Ps[0] == int));
        static assert(is(Ps[1] == double));
        static assert(is(Ps[2] == string));

        // パラメータ名一覧を取得できます。
        static assert(__traits(identifier, Ps[0..1]) == "x");
        static assert(__traits(identifier, Ps[1..2]) == "y");
        static assert(__traits(identifier, Ps[2..3]) == "z");

        // デフォルト値の情報も取得できますが、トリッキーな書き方をする必要があります。
        static assert(((Ps[2..3] p) => p[0])() == "def");

        // `ParameterDefaults`を使ったほうが楽でしょう。
        static assert(ParameterDefaults!(func)[2] == "def");
    }
    else
    {
        static assert(false);
    }

    // `is(Type == TypeSpecifier, parameters)`や`is(Type identifier == TypeSpecifier, parameters)`で`Type`や`TypeSpecifier`に用いるtemplateパラメータをつけられます。
    enum ColorFlags { Red = 0, Blue = 1, Green = 2}
    alias Color = BitFlags!ColorFlags;
    static if(is(Color == BitFlags!E, E))
        static assert(is(E == ColorFlags));
    else
        static assert(false);
}
