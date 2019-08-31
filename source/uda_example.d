/++
UDA(User Defined Attribute)の使用例についてまとめます。
+/
module uda_example;

/++
UDA取得の例です
+/
unittest
{
    import std : hasUDA, AliasSeq;

    // 変数宣言の前にUDAを書くことができます。
    @(1) int x;
    assert(__traits(getAttributes, x) == AliasSeq!(1));

    @("test") string y;
    assert(__traits(getAttributes, y) == AliasSeq!("test"));

    // 無名のenumを作成することでUDAを作成できます。
    enum MyUDA;
    @MyUDA double z;
    assert(hasUDA!(z, MyUDA));
}

/++
特定のUDAを持ったメンバー抽出の例です
+/
unittest
{
    import std : getSymbolsByUDA;

    // 構造体のメンバーにUDAを持たせることも可能です。
    enum MyUDA;
    struct S {
        @MyUDA int x = 3;
        float y = 4;
        @MyUDA ubyte z = 5;
    }

    // 構造体SのメンバのうちMyUDAを持つメンバーはxとzです。
    assert(getSymbolsByUDA!(S, MyUDA)[0].stringof == "x");
    assert(getSymbolsByUDA!(S, MyUDA)[1].stringof == "z");

    // 構造体の各メンバーは通常通りの初期値を持ちます。
    S s;
    assert(s.x == 3);
    assert(s.y == 4);
    assert(s.z == 5);

    // UDAを用いて特定のメンバーにのみ0を代入します。
    static foreach (mem; getSymbolsByUDA!(S, MyUDA))
        __traits(getMember, s, mem.stringof) = 0;
    assert(s.x == 0);
    assert(s.y == 4);
    assert(s.z == 0);
}

/++
toStringの自動生成の例です
+/
unittest
{
    import std : hasUDA, to, join, format;

    template ImplToString()
    {
        string toString()
        {
            string[] strs;
            static foreach (mem; __traits(allMembers, typeof(this)))
            {
                static if (__traits(hasMember, typeof(this), mem)
                        && hasUDA!(__traits(getMember, typeof(this), mem), printable))
                {
                    strs ~= mem ~ ":" ~ __traits(getMember, typeof(this), mem).to!string;
                }
            }
            return strs.join(",").format!"{%s}";
        }
    }

    enum printable;

    struct A
    {
        @printable
        {
            int x;
            float y;
            int[2] z;
        }
        short nonPrintableMember;
        mixin ImplToString;
    }

    A a = {
        x:3,
        y : 4.5,
        z : [1, 2],
        nonPrintableMember : 34
    };
    assert(a.to!string == `{x:3,y:4.5,z:[1, 2]}`);
}
