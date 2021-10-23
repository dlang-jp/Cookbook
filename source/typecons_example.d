/++
型を作るユーティリティ

様々な型を作れるtemplateを提供する`std.typecons`パッケージについて解説します。
+/
module typecons_example;

/++
nullになる可能性のある値を表現するNullableの例です

Nullableを利用することで、値が存在しない可能性のある型を表現できます。
int等の組み込み型やstructについても、nullとなることを明確に示せます。
+/
unittest
{
    import std.exception : assertThrown;
    import std.typecons : Nullable, nullable;

    // Nullableは格納値の型を指定して利用するテンプレート構造体です。
    // デフォルトコンストラクタでは、空の状態のNullableが生成されます。
    Nullable!int emptyValue;

    // 値が空かどうかはisNullで確認できます。
    assert(emptyValue.isNull);

    // 値を格納したNullableは、Nullableのコンストラクタに値を与えることや、nullable関数で生成できます。
    Nullable!int value1 = nullable(1);
    Nullable!int value2 = Nullable!int(2);

    // 格納されている値はgetで取得できます。
    assert(!value1.isNull);
    assert(value1.get == 1);
    assert(!value2.isNull);
    assert(value2.get == 2);

    // Nullableのまま値の比較を行えます。
    assert(value1 != value2);
    assert(value1 == value1);
    assert(emptyValue == emptyValue);
    assert(emptyValue != value1);
    assert(emptyValue != value2);

    // 代入により値を書き換えることが可能です。
    value1 = 100;
    assert(!value1.isNull && value1.get == 100);

    // nullifyにより値をnullにすることが可能です。
    value1.nullify();
    assert(value1.isNull && emptyValue == value1);

    // 空のNullableへのgetは例外になります。
    assertThrown!Throwable(emptyValue.get);

    // getにデフォルト値を指定することが可能です。
    assert(emptyValue.get(999) == 999);
}

/++
ポインタを格納するためのNullableであるNullableRefの例です

ポインタ型の場合はポインタだけでnullの状態を表現できるため、NullableRefを利用することでサイズを節約できます。
+/
unittest
{
    import std.typecons : NullableRef, nullableRef;

    // デフォルトコンストラクタでは空の状態のNullableRefが生成されます。
    NullableRef!int emptyRef;
    assert(emptyRef.isNull);

    // コンストラクタやnullableRef関数で値を参照するNullableRefを生成できます。
    int value = 100;
    NullableRef!int valueRef1 = NullableRef!int(&value);
    NullableRef!int valueRef2 = nullableRef(&value);

    // getでは、ポインタの参照先の値そのものが取得されます。
    assert(!valueRef1.isNull);
    assert(valueRef1.get == 100);
    assert(!valueRef2.isNull);
    assert(valueRef2.get == 100);

    // Nullableと同様にnullify等が使用可能です。
    valueRef1.nullify();
    assert(valueRef1.isNull);

    // bindにより別の値を参照させることが可能です。
    int value2 = 10000;
    valueRef1.bind(&value2);
    assert(valueRef1.get == value2);
}

/++
constやimmutableの参照型の変数でも再代入可能とするRebindableの例です

constやimmutableの参照型の変数はそのままでは再代入できませんが、Rebindableでラップした変数は再代入可能になります。
+/
unittest
{
    import std.typecons : Rebindable, rebindable;

    // 不変のオブジェクト生成
    immutable class Example
    {
        this(int v) { this.value = v; }
        int value;
    }

    immutable Example value1 = new immutable Example(100);
    immutable Example value2 = new immutable Example(200);

    // 上記の変数はそのままでは再代入不能です。
    // value2 = value1; // compile error

    // Rebindableでラップすることで、通常の変数と同じように再代入可能になります。
    // Rebindableはrebindable関数で生成可能です。
    Rebindable!(immutable Example) rebindableValue1 = rebindable(value1);
    Rebindable!(immutable Example) rebindableValue2 = rebindable(value2);
    assert(rebindableValue1.value == value1.value);
    assert(rebindableValue2.value == value2.value);

    // 再代入実行
    rebindableValue2 = rebindableValue1;
    assert(rebindableValue2.value == value1.value);
}

/++
コピー不能であったり、デストラクタを持っていたりする構造体を複数の変数で共有、参照する例です。

ポインタでも参照させることは可能ですが、デストラクタの呼び出しを自動で安全に行うために `RefCounted` を使う方法があります。
内部的には参照カウンタで管理されます。
+/
@nogc unittest
{
    import core.memory : pureMalloc, pureFree;
    import std.typecons : refCounted;

    // コピー不能でデストラクタを持つデータ
    struct Payload
    {
        // 最後に破棄された値(デストラクタ呼び出し確認用)
        static int lastDestructedValue;

        @disable this(this);

        // 管理対象のリソース確保
        this(int value) @nogc nothrow @safe scope
        {
            this.pointer = (() @trusted => cast(int*) pureMalloc(int.sizeof))();
            *this.pointer = value;
        }

        // Payload解放処理
        // RefCounted初期化直後などでPayload.initに対しても呼び出される点に注意が必要です。
        // 空のポインタやリソースハンドル等の破棄が安全に行われるようにする必要があります。
        // このため、初期値だったら解放しない、というロジックが必要です。
        ~this() @nogc nothrow @safe scope
        {
            if (pointer)
            {
                lastDestructedValue = *pointer;
                (() @trusted => pureFree(pointer))();
                pointer = null;
            }
        }

        int* pointer;
    }

    // 新しいリソースを保持するRefCounted!Payloadを、refCounted関数で生成します。
    auto rc1 = refCounted(Payload(1234));
    
    // 現在の参照カウントは1です。
    assert(rc1.refCountedStore.refCount == 1);

    // 確保したリソースを共有する別のRefCounted!Payloadを生成します。
    auto rc2 = rc1;

    // 参照カウントは2になります。
    assert(rc1.refCountedStore.refCount == 2);
    assert(rc2.refCountedStore.refCount == 2);
    assert(rc1.pointer is rc2.pointer);

    // rc1を別のRefCounted!Paylodで更新します。
    rc1 = refCounted(Payload(5678));

    // rc2で参照が続いているため、以前のリソースはまだ解放されません。
    assert(Payload.lastDestructedValue == Payload.lastDestructedValue.init);
    assert(rc1.refCountedStore.refCount == 1);
    assert(rc2.refCountedStore.refCount == 1);
    assert(rc1.pointer !is rc2.pointer);

    // rc2も更新することで、最初のリソースの参照カウントが0になり、解放されます。
    rc2 = rc1;
    assert(rc1.refCountedStore.refCount == 2);
    assert(rc2.refCountedStore.refCount == 2);
    assert(rc1.pointer is rc2.pointer);
    assert(*rc1.pointer == 5678);

    // 最初のリソースが解放されていることを確認
    assert(Payload.lastDestructedValue == 1234);
}

/++
複数の値の組を作れる`Tuple`の例です。

複数の異なる型の値をまとめて扱いたい時や、関数から複数の値を返したい場合などに利用できます。
+/
unittest
{
    import std.typecons : Tuple, tuple;
    import std.math : isClose;

    // stringとintの2つのフィールドを持つTupleを生成します。
    Tuple!(string, int) t1;

    // 各フィールドには配列のようなインデックス指定でアクセスできます。
    t1[0] = "test";
    t1[1] = 123;
    assert(t1[0] == "test");
    assert(t1[1] == 123);

    // ただし、指定するインデックスはコンパイル時に解決できる必要があります。
    // 実行時に値が決まる変数などはインデックスに使用できません。
    static assert(!__traits(compiles, { size_t i = 1; t1[i] = 456; }));

    // Tupleはtuple関数を利用して簡潔に生成することもできます。
    auto t2 = tuple(123, "456", 789.012);
    static assert(is(typeof(t2) == Tuple!(int, string, double)));
    assert(t2[0] == 123);
    assert(t2[1] == "456");
    assert(t2[2].isClose(789.012));

    // Tupleはコンパイル時にも利用可能です。
    enum staticTuple = tuple("test", 123);

    // foreachによりフィールドを順に取り出すことができます。
    foreach (i, e; staticTuple)
    {
        assert(t1[i] == e);
    }

    // フィールドに名前の付いているTupleも作ることができます。
    // テンプレート引数に型・フィールド名のペアを指定すると、名前付きメンバーになります。
    Tuple!(int, "intValue", string, "stringValue") t3;

    // 名前付きフィールドについては、通常のメンバー変数のように名前を指定してアクセスできます。
    t3.intValue = 123;
    t3.stringValue = "abc";
    assert(t3.intValue == 123);
    assert(t3.stringValue == "abc");

    // 名前付きフィールドでもインデックスによるアクセスが可能です。
    assert(t3[0] == 123);
    assert(t3[1] == "abc");

    // 互換性のある型のTupleは比較が行えます。
    // フィールドの順に行っていく比較(辞書式順序)になります。
    assert(tuple(1, 2, 3) == tuple(1, 2, 3));
    assert(tuple(1, 2, 3, 4) != tuple(1, 2, 3, 5));
    assert(tuple(1, 2, 3) < tuple(3, 2, 1));
    assert(tuple(123456L, 2, 0) > tuple(3, 2, 1));

    // Tuple同士の結合が行えます。
    assert(tuple(1, 2, 3) ~ tuple("abc", "def") == tuple(1, 2, 3, "abc", "def"));

    // 指定範囲のフィールドだけを取り出すsliceが行えます。
    assert(tuple("test", 2, 3, 5, "abc").slice!(1, 4) == tuple(2, 3, 5));

    // 参照により取り出すため、値のコピー等は発生しません。値の変更も可能です。
    auto t4 = tuple(1, 2, "foo");
    t4.slice!(0, 2) = tuple(100, 200);
    assert(t4 == tuple(100, 200, "foo"));

    // その代わり、メモリ上のアライメントが変わってしまうようなスライスは行えません。
    static assert(!__traits(compiles, tuple(1, 2, 3, 5, "abc").slice!(1, 5) == tuple(2, 3, 5)));

    // expandにより関数の引数として展開することが可能です。
    void f(int x, string y, double z)
    {
    }

    f(tuple(1, "bar", 0.1).expand);

    // fieldNamesによりフィールド名を取得することが可能です。
    static assert(Tuple!(int, "first", double, "second", string, "third")
            .fieldNames == tuple("first", "second", "third"));
}

/+
classのインスタンスをスタック上に確保するscopedの例です

scopedによりclassのインスタンスを生成した場合、ヒープを使用するnewのオーバーヘッドを回避することができます。
その代わり、インスタンスをスコープの外に移動させることはできません。
+/
unittest
{
    import std.typecons : scoped;

    class A
    {
    @nogc nothrow pure @safe:

        this() scope { this.value = -1; }
        this(int value) scope { this.value = value; }
        int value;
    }

    // scopedによるインスタンス生成
    // インスタンスはスタック上に確保されます。
    // スコープ終了時はデストラクタが呼び出されます。
    // scopedで生成したインスタンスは元の型の変数で直接参照できません。
    // autoを経由する必要があります。
    auto a1 = scoped!A();
    assert(a1.value == -1);

    // 引数ありコンストラクタも使用可能です。
    auto a2 = scoped!A(1234);
    assert(a2.value == 1234);

    // scopedで生成したインスタンスを別の変数で参照することが可能です。
    // ただし、スコープの外では参照は無効になります。
    A aRef = a2;
    assert(aRef.value == 1234);

    {
        // スコープ内で新しいインスタンスを生成
        auto a3 = scoped!A(4567);
        aRef = a3;

        // a3はここでデストラクタが呼ばれ、破棄されます。
    }
    // a3を指していたaRefは無効な参照になっています。

    // なお、scope記憶クラスを利用しても
    // scopedと同様にGC無しでのインスタンス生成・スコープ終了時の破棄が実現できます。
    (() @nogc nothrow pure scope @safe {
       scope a4 = new A(9012);
       assert(a4.value == 9012);

       // a4はここでデストラクタが呼ばれ、破棄されます。
    })();
}

