/++
文字列操作についてまとめます。

TODO: 置換(replace), 削除(remove), 分割(split)
+/
module string_example;


/++
文字列の連結

事前に長さの分からない文字列を構築する場合、`std.array` の `appender` を使います。

`appender` : https://dlang.org/phobos/std_array.html#appender
+/
unittest
{
    assert("ABC" ~ "DEF" == "ABCDEF");

    // 多くの文字を連結するときはappenderを使います

    import std.array : appender;

    auto buffer = appender!string;

    buffer.put("https://");
    buffer.put("github.com");
    buffer.put("/dlang");

    assert(buffer.data == "https://github.com/dlang");
}

/++
書式化文字列

`std.format` の `format` を使います。

https://dlang.org/phobos/std_format.html#.format
+/
unittest
{
    import std.format : format;

    int n = 10;
    float f = 1.5;
    string url = "https://github.com";

    auto text = format!"%d, %f, %s"(n, f, url);

    assert(text == "10, 1.500000, https://github.com", text);
}

/++
完全一致、辞書順での比較
+/
unittest
{
    auto text = "ABC";
    assert(text == "ABC");
    assert(text < "abc");
}

/++
大文字小文字を無視して比較

`std.uni` の `icmp` を使います

`icmp` : https://dlang.org/phobos/std_uni.html#icmp
+/
unittest
{
    import std.uni;

    auto text = "ABC";
    assert(icmp(text, "abc") == 0);
    assert(icmp(text, "ab") == 1);
    assert(icmp(text, "abcd") == -1);

    // 使い方、戻り値のイメージ
    // "ABC" > "ab"
    // "ABC" - "ab" > 0
    assert(icmp(text, "abc") == 0);
    assert(icmp(text, "ab") > 0);
    assert(icmp(text, "abcd") < 0);
}

/++
「で始まる」「で終わる」の例

`std.algorithm` の `startsWith`, `endsWith` を使います。

`startsWith` : $(LINK https://dlang.org/phobos/std_algorithm_searching.html#.startsWith)$(BR)
`endsWith` : $(LINK https://dlang.org/phobos/std_algorithm_searching.html#.endsWith)
+/
unittest
{
    import std.algorithm : startsWith, endsWith;

    auto text = "std.algorithm";

    // ～で始まる
    assert(startsWith(text, "std."));
    assert(text.startsWith("std."));

    // ～で終わる
    assert(endsWith(text, ".algorithm"));
    assert(text.endsWith(".algorithm"));
}

/++
文字列が出現する位置を検索します。

`std.string` の `indexOf` を使用します。

`indexOf` : https://dlang.org/phobos/std_string.html#.indexOf
+/
unittest
{
    import std.string : indexOf;

    auto text = "std.algorithm.searching";

    assert(indexOf(text, "search") == 14);
    assert(text.indexOf("search") == 14);

    // 大文字小文字を無視することもできます
    // std.typeconsからYesやNoをimportして使います
    import std.typecons : Yes, No;
    import std.string : CaseSensitive;

    auto url = "https://github.com/dlang/dmd";
    assert(url.indexOf("GITHUB", No.CaseSensitive));
}
