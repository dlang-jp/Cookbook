/++
JSON操作

JSONファイル/JSONデータの読み書き等操作を扱います。
ここでは、標準で備えているstd.jsonモジュールと、その中のJSONValueについて説明します。
このモジュールは、あくまでもJSONが最低限取り扱える程度の機能があって、速度や利便性は二の次です。
ほかにもサードパーティのライブラリとして、asdfを代表として、より高度な取り扱いができるライブラリがあります。
+/
module data.json_example;


/++
# 文字列⇔JSON
+/
@safe unittest
{
    import std.json;
    // 文字列からJSONValueを作成します。
    auto jv = JSONValue("文字列");

    // JSONValueからJSONの文字列表現を取得したい場合は
    // `.toString()`メソッドを使用します。
    assert(jv.toString() == `"文字列"`);
    // JSONValueが文字列であることを確認するには、`.type`プロパティを使用して
    // 以下のように`JSONType.string`と比較します。
    assert(jv.type == JSONType.string);
    // JSONValueから文字列を取り出す場合は、`.str`プロパティを使用して
    // 以下のようにします。
    assert(jv.str == "文字列");
}

/++
# 数値⇔JSON
+/
@safe unittest
{
    import std.json;
    import std.exception: assertThrown;
    // 数値(符号あり・符号なし)からJSONValueを作成します。
    int  x = -128;
    uint y = 0xff;
    auto jvx = JSONValue(x);
    auto jvy = JSONValue(y);

    // JSONValueからJSONの文字列表現を取得したい場合は
    // `.toString()`メソッドを使用します。
    assert(jvx.toString() == `-128`);
    assert(jvy.toString() == `255`);

    // JSONValueが数値であることを確認するには、`.type`プロパティを使用して、
    // 以下のように`JSONType.integer`や`JSONType.uinteger`と比較します。
    assert(jvx.type == JSONType.integer);
    assert(jvy.type == JSONType.uinteger);
    // JSONValueから数値を取り出す場合は、以下のように
    // `.integer`/`.uinteger`プロパティを使用します。
    assert(jvx.integer == -128);
    assert(jvy.uinteger == 255);

    // ちなみに、型を符号ありとなしで間違ってしまうと例外が投げられます
    assertThrown(jvx.uinteger == cast(uint)-128);

    // 符号ありのつもりなんだけど(十分格納可能な範囲の)符号なしも
    // 受け付けたい場合は以下のようにします (とても面倒)
    long z = jvy.type == JSONType.integer  ? jvy.integer
           : jvy.type == JSONType.uinteger ? jvy.uinteger : 0;
}

/++
# 真偽値・null⇔JSON

真偽値(true / false)とnullの状態は、上記文字列や数値とは異なり、
それぞれ個別にJSONTypeが存在します。
+/
@safe unittest
{
    import std.json;
    import std.exception: assertThrown;

    // JSONValueを作る
    auto jvf = JSONValue(false);
    auto jvt = JSONValue(true);
    auto jvn = JSONValue(null);

    // JSONValueからJSONの文字列表現を取得したい場合は
    // `.toString()`メソッドを使用します。
    assert(jvf.toString() == `false`);
    assert(jvt.toString() == `true`);
    assert(jvn.toString() == `null`);

    // 真偽は`.type`で調べます
    assert(jvf.type == JSONType.false_);
    assert(jvt.type == JSONType.true_);
    // さすがに↑だけではつらい(というか不格好な)ので、
    // ↓でOKなようにプロパティがあります
    assert(!jvf.boolean);
    assert( jvt.boolean);

    // nullかどうかも`.type`で調べます
    assert(jvn.type == JSONType.null_);
    // is nullでは調べられません(コンパイルエラーが出ます)
    assert(!__traits(compiles, {
        assert(jvn is null);
    }));

}


/++
# 配列⇔JSON
+/
@safe unittest
{
    import std.json;
    import std.exception: assertThrown;
    import std.string: chompPrefix, outdent;

    // JSONValueを作る
    auto jv1 = JSONValue([1,2,3,4,5]);
    // 値にはJSONValueを使うことで、数値と文字列などを混成できます。
    auto jv2 = JSONValue([JSONValue(1), JSONValue("弐")]);

    // JSONの文字列表現は、`.toString()`メソッドで得られます。
    assert(jv1.toString() == `[1,2,3,4,5]`);
    assert(jv2.toString() == `[1,"弐"]`);

    // 配列ともなると文字列表現は整形したくなってきます。
    // `toPrettyString()`メソッドで整形された文字列が得られます。
    assert(jv2.toPrettyString() ==`
    [
        1,
        "弐"
    ]`.chompPrefix("\n").outdent());

    // 連想配列かどうかは、`.type`と`JSONType.array`を比較します
    assert(jv1.type == JSONType.array);
    assert(jv2.type == JSONType.array);

    // 値へのアクセスは`[]`演算子オーバーロードを使うか、
    // `.array`プロパティを使います
    // ただし、`.array`プロパティはなぜか`@system`らしいです
    () @trusted {
        assert(jv1.array[0].type == JSONType.integer);
        assert(jv1.array[0].integer == 1);
    } ();
    assert(jv2[1].type == JSONType.string);
    assert(jv2[1].str == "弐");
}


/++
# 連想配列⇔JSON
+/
@safe unittest
{
    import std.json;
    import std.exception: assertThrown;
    import std.string: chompPrefix, outdent;

    // JSONValueを作る
    auto jv1 = JSONValue([
        "いち": 1, "に": 2]);
    // 文字列以外はキーにできません。
    assert(!__traits(compiles, {
        auto jv2 = JSONValue([
            1: "いち", 2: "に"]);
    }));
    assert(!__traits(compiles, {
        auto jv2 = JSONValue([
            true: "真", false: "偽"]);
    }));
    // 値にはJSONValueを使うことで、数値と文字列などを混成できます。
    auto jv2 = JSONValue([
        "いち": JSONValue(1), "に": JSONValue("弐")]);
    // キーは無理です
    assert(!__traits(compiles, {
        auto jv3 = JSONValue([
            JSONValue(true): JSONValue("真"),
            JSONValue(false): JSONValue("偽")]);
    }));


    // JSONの文字列表現は、`.toString()`メソッドで得られます。
    // ただし、キーの並び順は不定(unordered)です。
    auto str = jv1.toString();
    assert(str == `{"いち":1,"に":2}` || str == `{"に":2,"いち":1}`);

    // 連想配列ともなると文字列表現は整形したくなってきます。
    // `toPrettyString()`メソッドで整形された文字列が得られます。
    assert(JSONValue(["壱": 1]).toPrettyString() ==`
    {
        "壱": 1
    }`.chompPrefix("\n").outdent());

    // 連想配列かどうかは、`.type`と`JSONType.object`を比較します
    assert(jv1.type == JSONType.object);
    assert(jv2.type == JSONType.object);

    // 値へのアクセスは`[]`演算子オーバーロードを使うか、
    // `.object`プロパティを使います
    // ただし、`.object`プロパティはなぜか`@system`らしいです
    () @trusted {
        assert(jv1.object["いち"].type == JSONType.integer);
        assert(jv1.object["いち"].integer == 1);
    } ();
    assert(jv2["に"].type == JSONType.string);
    assert(jv2["に"].str == "弐");
}



/++
# JSONファイルの書き込み・読み込み
+/
@safe unittest
{
    import std.json;
    import std.file;
    enum jsonTestFile = "json_example_filerw_test.json";

    // あとしまつ
    scope (exit)
    {
        if (jsonTestFile.exists)
            remove(jsonTestFile);
    }

    // JSONValueを作る
    auto jv1 = JSONValue([
        "aaa": JSONValue([1UL,2UL,3UL]),
        "bbb": JSONValue([
            "bbb-1": 1,
            "bbb-2": 2,
        ]),
        "ccc": JSONValue(null)
    ]);

    // JSONValueをファイルに保存します。
    // 単純に`toString()`メソッドや`toPrettyString()`メソッドで
    // JSONの文字列表現に直した後`std.file`などのファイル書き込みを行います。
    std.file.write(jsonTestFile, jv1.toPrettyString());

    // JSONファイルを読み込んで、JSONValueを得ます
    // というか、ファイルから読み込んだJSONの文字列表現を、`parseJSON()`関数
    // でJSONValueに変換します。
    // curlなどを使って取得したHTTPレスポンスを解析するときも同様に`parseJSON()`
    // 関数でJSONValueに変換できます。
    auto jv2 = std.file.readText(jsonTestFile).parseJSON();

    // ちゃんと読み込まれています
    assert(jv1["aaa"][0] == jv2["aaa"][0]);
    // ただし、注意点。
    // 一度保存された整数は、符号なし→符号ありになることがあります
    assert(jv1["aaa"][0].type != jv2["aaa"][0].type);
    assert(jv1["aaa"][0].type == JSONType.uinteger);
    assert(jv2["aaa"][0].type == JSONType.integer);
}
