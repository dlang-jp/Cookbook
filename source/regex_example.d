/++
正規表現の操作についてまとめます。
+/
module regex_example;

/++
# 正規表現オブジェクトの生成
+/
@safe unittest
{
    import std.regex : regex, ctRegex;

    // 実行時に正規表現オブジェクトを作成するには`regex`関数を用います。
    auto r0 = regex(`(d|D)(lang|language)`);

    // コンパイル時に正規表現オブジェクトを作成するには`ctRegex`関数を用います。
    enum r1 = ctRegex!(`(d|D)(lang|language)`);
}

/++
# 正規表現用の文字列
+/
@safe unittest
{
    import std.algorithm : equal;
    import std.regex : escaper;

    // 正規表現では`\\.`や`\\d`など通常のエスケープ文字と異なる表記をするため、通常の文字列は使えないことがあります。
    /*
    auto s0 = "\."; // undefined escape sequence \.
    */

    // `\\`を二重にすれば問題ありませんが、冗長になってしまいます。
    auto s0 = "\\.";
    
    // このような場合、Wysiwyg(what you see is what you get)文字列が有効です。
    // Wysiwyg文字列は`\``で囲うことで表記できます。
    auto s1 = `\.`;
    assert(s0 == s1);

    // 通常の文字列の前に`r`を置くことでも表記できます。
    auto s2 = r"\.";
    assert(s0 == s2);

    // また、全体をエスケープする場合なら`escaper`も有効です。
    auto s3 = escaper(".");
    assert(s0.equal(s3));
}

/++
# 部分文字列の検索
+/
@safe unittest
{
    // 正規表現を用いた部分文字列の検索には以下の関数を用います。
    import std.regex : matchFirst, matchAll;
}

/++
## 部分文字列の検索 (matchFirst)
+/
@safe unittest
{
    import std.regex : regex, matchFirst;

    // 最初にマッチした場所を検索するには`matchFirst`を用います。
    auto matchFirstResult = matchFirst("My IP is 192.168.1.255 !!!", regex(`(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})`));

    // `.pre`でマッチ箇所より前の部分文字列を取得できます。
    assert(matchFirstResult.pre == "My IP is ");

    // `.post`でマッチ箇所より後ろの部分文字列を取得できます。
    assert(matchFirstResult.post == " !!!");

    // `.hit`でマッチ箇所を取得できます。
    assert(matchFirstResult.hit == "192.168.1.255");

    // `.hit`は`[0]`の糖衣構文です。
    assert(matchFirstResult.hit == matchFirstResult[0]);

    // `[1]`以降に部分マッチ結果が格納されています。
    assert(matchFirstResult[1] == "192");
    assert(matchFirstResult[2] == "168");
    assert(matchFirstResult[3] == "1");
    assert(matchFirstResult[4] == "255");
}

/++
## 部分文字列の検索 (matchAll)
+/
@safe unittest
{
    import std.regex : regex, matchAll;

    // マッチ箇所を全検索するには`matchAll`を用います。
    auto matchAllResult = matchAll("import std.regex, std.stdio, core.stdio", regex(`std\.(\w+)`));

    // `matchAll`の返り値は`matchFirst`の返り値がRangeになったものです。
    // `.pre`, `.post`, `.hit`は`front.*`の糖衣構文です。
    assert(matchAllResult.pre == matchAllResult.front.pre);
    assert(matchAllResult.post == matchAllResult.front.post);
    assert(matchAllResult.hit == matchAllResult.front.hit);

    // `.pre`, `.post`, `.hit`, `[*]`は`matchFirst`のものと同様です。
    assert(matchAllResult.pre == "import ");
    assert(matchAllResult.post == ", std.stdio, core.stdio");
    assert(matchAllResult.hit == "std.regex");
    assert(matchAllResult.front[1] == "regex");

    // `.popFront`で次のマッチ結果に移動します。
    matchAllResult.popFront();
    assert(matchAllResult.pre == "import std.regex, ");
    assert(matchAllResult.post == ", core.stdio");
    assert(matchAllResult.hit == "std.stdio");
    assert(matchAllResult.front[1] == "stdio");

    // 空になったら`.empty`がtrueになります。
    matchAllResult.popFront();
    assert(matchAllResult.empty);
}

/++
# 文字列の置換
+/
@safe unittest
{
    import std.regex : regex, replaceFirst, replaceAll;
    import std.conv : to;

    // 最初のマッチ結果のみを置換するときは`replaceFirst`を用います。
    // $nでn番目のマッチ結果を表します。
    assert(replaceFirst("4 x 3 = 6 x 2", regex(`(\d) x (\d)`), "$2 x $1") == "3 x 4 = 6 x 2");

    // $&でマッチ結果全体を表します。
    assert(replaceFirst("4 x 3 = 6 x 2", regex(`(\d) x (\d)`), "($&)") == "(4 x 3) = 6 x 2");

    // ラムダ式を用いたより柔軟な置換も可能です。
    alias replacer = c => to!string(c[1].to!int * c[2].to!int) ~ " x 1";
    assert(replaceFirst!(replacer)("4 x 3 = 6 x 2", regex(`(\d) x (\d)`)) == "12 x 1 = 6 x 2");

    // `replaceAll`を用いることで全マッチ結果を置換できます。
    assert(replaceAll!(replacer)("4 x 3 = 6 x 2", regex(`(\d) x (\d)`)) == "12 x 1 = 12 x 1");
}

/++
# 文字列の分割
+/
@safe unittest
{
    import std.algorithm : equal;
    import std.regex : regex, split, splitter;
    import std.typecons : Yes;

    // 最もシンプルな分割は、`split`関数を用いることです。
    assert(split("C/C++, Python or D", regex(`, | or `)) == ["C/C++", "Python", "D"]);

    // Separatorも残したい場合は、`splitter`関数を用います。
    assert(splitter!(Yes.keepSeparators)("C/C++, Python or D", regex(`, | or `))
            .equal(["C/C++", ", ", "Python", " or ", "D"]));
}
