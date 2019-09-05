/++
連想配列の操作についてまとめます。
+/
module assoc_array_example;

/++
# データ操作
+/
unittest
{
    import std : assertThrown;
    import core.exception : RangeError;

    // Keyの型が`K`, Valueの型が`V`の連想配列の型は`V[K]`と表されます。
    int[string] data;

    // `[key]`で対応するValueにアクセスできます。
    data["x"] = -3;
    data["y"] = +2;
    assert(data["x"] == -3);
    assert(data["y"] == +2);

    // 既に存在するKeyに対して代入した場合、Valueが更新されます。
    data["x"] = -4;
    assert(data["x"] == -4);

    // 存在しないKeyに対応するValueを得ようとすると`RangeError`が発生します。
    assertThrown!RangeError(data["z"]);

    // `.length`で挿入されているデータの数を取得できます。
    assert(data.length == 2);

    // `in`であるKeyが挿入されているかどうかが判定できます。
    assert("x" in data);
    assert("y" in data);
    assert("z" !in data);

    // `.remove`で指定したKeyに対応したデータを削除できます。
    data.remove("x");
    assert("x" !in data);
    assert("y" in data);
    assert("z" !in data);

    // `[key : value, ...]`でリテラルとしての連想配列を扱うことができます。
    data = ["a": 100, "b": 200];
    assert(data["a"] == 100);
    assert(data["b"] == 200);
    assert("x" !in data);

    // `in`は参照した値のポインタを返しているので、`if`と組み合わせるのが有効です。
    if (auto p = "a" in data)
    {
        assert(*p == 100);
    }
    if (auto p = "c" in data)
    {
        assert(false);
    }
}

/++
# プロパティ
+/
unittest
{
    import std : sort, equal, map, array;

    string[string] data = ["key0" : "value0", "key1" : "value1",];

    // `.keys`でKey一覧を配列として取得できます。
    // ただし順序は実装依存であり、挿入/宣言順とは限りません。
    assert(data.keys.sort.equal(["key0", "key1"]));

    // `.values`でValue一覧を配列として取得できます。
    assert(data.values.sort.equal(["value0", "value1"]));

    // `.byKeyValue()`でKeyとValueのペア一覧をForward Rangeとして取得できます。
    assert(data.byKeyValue().map!(pair => pair.key ~ " : " ~ pair.value)
            .array.sort.equal(["key0 : value0", "key1 : value1"]));

    // `null`でない連想配列を代入するとshallow copyが発生しますが、`dup`を使うことでdeep copyができます。
    string[string] data2 = data.dup;
    data["key2"] = "value2";
    assert("key2" !in data2);

    // `.get(key, defval)`で、もし`key`が存在したら対応するValueを、なければ`defval`を取得できます。
    assert(data.get("key0", "") == "value0");
    assert(data.get("key", "") == "");

    // `.require(key,value)`で、もし`key`が存在したら対応するValueを、なければ`key`と`value`のペアを追加した上で`value`を返します。
    assert(data.require("key0", "newValue") == "value0");
    assert(data.require("newKey", "newValue") == "newValue");
    assert(data["newKey"] == "newValue");

    // `.update(key,create,update)`で、もし`key`が存在したら`update`で上書きを、なければ`create`でValueを代入します。
    data.update("key0",   () => "value100", (ref string oldValue) => "new " ~ oldValue);
    assert(data["key0"] == "new value0");

    data.update("key100", () => "value100", (ref string oldValue) => "new " ~ oldValue);
    assert(data["key100"] == "value100");

    // `.clear()`で全要素を削除できます。
    data.clear();
    assert(data.length == 0);
}

/++
## 空連想配列とnull
+/
unittest
{
    string[int] data, data2;

    // 宣言時、連想配列は`null`になっています。
    assert(data is null);

    // 連想配列間での代入操作は基本的にshallow copyとなりますが、代入元が`null`の時に限り参照値は同期されません。
    data2 = data; // `data`は`null`なので、shallow copyは発生しない。
    data[0] = "value";
    assert(data2.length == 0); // `data2`は`data`と同期していない。

    // 代入元が`null`でない場合はshallow copyとなります。
    data2 = data; // `data`は`null`ではないので、shallow copyが発生。
    data[0] = "newValue";
    assert(data2[0] == "newValue"); // `data2`は`data`と同期している。

    // 要素なしの連想配列と`null`は厳密には異なります。要素なしの配列の場合にはshallow copyが発生します。
    data.clear(); // `.clear()`を用いて要素なしの連想配列を作成
    assert(data.length == 0);
    data2 = data; // `data`は要素はないが`null`ではないため、shallow copyが発生。
    data[0] = "newNewValue";
    assert(data2[0] == "newNewValue");
}
