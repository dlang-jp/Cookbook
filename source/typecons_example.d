/++
型を作るユーティリティ

様々な型テンプレートを提供する`std.typecons`パッケージについて解説します。
+/
module typecons_example;

/++
Nullableの例です

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
NullableRefの例です

NullableRefは、ポインタを格納する場合に利用できるNullableです。
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

