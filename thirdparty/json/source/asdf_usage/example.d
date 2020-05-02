/++
Asdfの使用例

JSON形式のデータを取り扱う Asdf の使い方についてまとめます。

## ドキュメント
http://docs.asdf.dlang.io/index.html

+/
module asdf_usage.example;

/++
JSON文字列の解析例です。

`parseJson` 関数を使って解析し、汎用的な `Asdf` オブジェクトに変換します。
+/
unittest
{
    import asdf;

    auto source = `{ "type": "VALUES", "obj": null, "flag": true, "count": 3 }`;
    Asdf json = source.parseJson();

    // 文字と真偽値、nullは直接比較が可能です
    assert(json["type"] == "VALUES");
    assert(json["obj"] is null);
    assert(json["flag"]);

    // 数値は既定値を指定して取得後に比較します
    assert(json["count"].get(0) == 3);

    // 単純に値を取り出す場合はキャストするのが簡単です
    string type = cast(string) json["type"];
    bool flag = cast(bool) json["flag"];
    size_t count = cast(size_t) json["count"];
}

/++
JSON文字列を独自の構造体にデシリアライズする例です。

1度 Asdf オブジェクトに変換した後、 `deserialize` 関数を使うことで独自構造体に変換できます。
+/
unittest
{
    import asdf;

    static struct Constant
    {
        string name;
        double value;
    }

    auto source = `{ "name": "PI", "value": 3.1415 }`;
    Asdf json = source.parseJson();

    Constant c = json.deserialize!Constant();
    assert(c.name == "PI");
    import std.math;
    assert(isClose(c.value, 3.1415));
}

/++
オブジェクトのJSON文字列化（シリアライズ）の例です。
+/
unittest
{
    import asdf;

    static struct Data
    {
        string name;
        int value;
    }

    auto data = Data("count", 10);
    auto text = data.serializeToJson();

    assert(text == `{"name":"count","value":10}`);

    // インデントを含む人が読みやすい形式にするには `serializeToJsonPretty` を使います
    auto pretty = data.serializeToJsonPretty();

    assert(pretty == "{\n\t\"name\": \"count\",\n\t\"value\": 10\n}");
}

/++
Unix timestampである数値をSysTimeとして扱う場合の変換方法です。

データ型に合わせたProxyを定義して変換ロジックを書き、 `serializedAs` を対象フィールドに属性として付与します。

参考 : http://docs.asdf.dlang.io/asdf_serialization.html
+/
unittest
{
    import std.datetime;
    import asdf;

    // 変換ロジックを持ったProxyを定義します
    static struct SysTimeProxy
    {
        SysTime systime;
        alias systime this;

        static SysTimeProxy deserialize(Asdf data) pure
        {
            ulong unixtime;
            deserializeValue(data, unixtime);
            return SysTimeProxy(SysTime.fromUnixTime(unixtime, UTC()));
        }

        void serialize(S)(ref S serializer) pure
        {
            serializer.putValue(systime.toUnixTime());
        }
    }

    static struct Data
    {
        // 必要なフィールドに属性として付与します
        @serializedAs!SysTimeProxy SysTime date;
    }

    // 2020-01-01T00:00:00+00:00
    auto source = `{ "date": 1577836800 }`;
    auto json = source.parseJson();
    auto data = json.deserialize!Data();

    assert(data.date == SysTime(Date(2020, 1, 1), UTC()));
}

/++
特定のキーが複数の形式を取り得る場合の解析例です。

データ型を `SumType` で定義することで安全に取り扱います。
解析ではAsdfの `kind` を用いて分岐します。

sumtype : $(LINK http://code.dlang.org/packages/sumtype)
+/
unittest
{
    import asdf;
    import sumtype;

    alias StringOrInt = SumType!(string, int);

    static struct StringOrIntProxy
    {
        StringOrInt value;
        alias value this;

        static StringOrIntProxy deserialize(Asdf asdf) pure
        {
            switch (asdf.kind)
            {
            case Asdf.Kind.number:
                return StringOrIntProxy(StringOrInt(cast(int) asdf));
            case Asdf.Kind.string:
                return StringOrIntProxy(StringOrInt(cast(string) asdf));
            default:
                assert(false);
            }
        }

        void serialize(S)(ref S serializer) pure
        {
            // dfmt off
            value.match!(
                (string value) { serializer.putValue(value); },
                (int value) { serializer.putValue(value); },
            );
            // dfmt on
        }
    }

    static struct Data
    {
        @serializedAs!StringOrIntProxy StringOrInt value;
    }

    auto s1 = `{ "value": "TEST" }`;
    assert(s1.parseJson().deserialize!Data().value == StringOrInt("TEST"));

    auto s2 = `{ "value": 1000 }`;
    assert(s2.parseJson().deserialize!Data().value == StringOrInt(1000));
}

/++
特定のキーが複数のオブジェクト形式を取り得る場合の解析例です。

データ型を `SumType` で定義することで安全に取り扱います。
解析ではオブジェクトがtypeキーを持つと想定し、キーを確認して形式を切り替えます。

sumtype : $(LINK http://code.dlang.org/packages/sumtype)
+/
unittest
{

    import asdf;
    import sumtype;

    static struct MyNumber
    {
        string type;
        double number;
    }

    static struct MyString
    {
        string type;
        string text;
    }

    alias MyData = SumType!(MyNumber, MyString);

    static struct MyDataProxy
    {
        MyData value;
        alias value this;

        static MyDataProxy deserialize(Asdf asdf) pure
        {
            // 特定のキーで分岐する
            if (asdf.kind == Asdf.Kind.object)
            {
                auto type = cast(string) asdf["type"];
                if (type == "number")
                    return MyDataProxy(MyData(MyNumber("number", cast(double) asdf["value"])));
                if (type == "string")
                    return MyDataProxy(MyData(MyString("string", cast(string) asdf["text"])));
            }
            assert(false);
        }

        void serialize(S)(ref S serializer) pure
        {
            // dfmt off
            value.match!(
                (MyNumber value) { serializer.putValue(value.value); },
                (MyString value) { serializer.putValue(value.text); },
            );
            // dfmt on
        }
    }

    static struct Data
    {
        @serializedAs!MyDataProxy MyData data;
    }

    auto s1 = `{ "data": { "type": "number", "value": 10.5 } }`;
    assert(s1.parseJson().deserialize!Data().data == MyData(MyNumber("number", 10.5)));

    auto s2 = `{ "data": { "type": "string", "text": "TEST" } }`;
    assert(s2.parseJson().deserialize!Data().data == MyData(MyString("string", "TEST")));
}
