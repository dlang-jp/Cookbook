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
classのインスタンスをスタック上に確保するscopedの例です

scopedによりclassのインスタンスを生成した場合、ヒープを使用するnewのオーバーヘッドを回避することができます。
その代わり、インスタンスをスコープの外に移動させることはできません。
+/
unittest
{
    import std.typecons : scoped;

    class A
    {
        this() { this.value = -1; }
        this(int value) { this.value = value; }
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
}

