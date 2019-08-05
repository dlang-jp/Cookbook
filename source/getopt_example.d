/++
`std.getopt` の使い方についてまとめます。

実行プログラムの引数を解析することができ、柔軟なプログラム作成を助けます。
+/
module getopt_example;

/++
基本的な引数解析の例です
+/
unittest
{
    // 以下のようにプログラムを実行した場合の例です
    // app --format=json
    string[] args = ["app.exe", "--format=json"];

    import std.getopt;

    // 
    string format;

    // 引数の名前、引数を受け付ける変数、説明、で1セットの指定になります
    // 説明は省略可能です
    auto result = getopt(args, "format", "format引数の説明になります", &format);

    // --helpなどの引数が指定されたかどうかで分岐することができます
    if (result.helpWanted)
    {
        // 自動的に引数の説明などを表示します
        std.getopt.defaultGetoptPrinter("プログラム説明", result.options);
        return;
    }

    assert(format == "json");
}

/++
適度な折り返しを入れてコードフォーマッターでも可読性を保つ例です。
+/
unittest
{
    string[] args = ["app.exe", "--format=json"];

    import std.getopt;

    string format;

    // 以下の記述によってdfmtの有効無効を切り替えることができます
    // dfmt off
    auto result = getopt(
        args,
        "format", "format引数の説明になります", &format,
    );
    // dfmt on

    if (result.helpWanted)
    {
        std.getopt.defaultGetoptPrinter("プログラム説明", result.options);
        return;
    }

    assert(format == "json");
}
