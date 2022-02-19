/++
正規表現

正規表現の操作についてまとめます。

Source: $(LINK_TO_SRC source/_regex_example.d)
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

    // `escaper`の戻り値は、`Escaper`という遅延評価を行うレンジになります。
    // 実行時にstringと連結して新たなパターン文字列を作るような場合、`std.conv.to`や`std.conv.text`を使うと効率的です。
    import std.conv : to, text;

    string s4 = "^" ~ escaper("https://dlang.org").to!string() ~ "$";
    string s5 = text("^", escaper("https://dlang.org"), "$");
    assert(s4 == `^https\:\/\/dlang\.org$`);
    assert(s5 == `^https\:\/\/dlang\.org$`);
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

    // `[1]`以降にキャプチャ(カッコでくくったパターンの部分マッチ)結果が格納されています。
    assert(matchFirstResult[1] == "192");
    assert(matchFirstResult[2] == "168");
    assert(matchFirstResult[3] == "1");
    assert(matchFirstResult[4] == "255");

    // `?P<name>`でキャプチャに対して名前を付けられます。
    // また、キャプチャ不要の場合は (?:xxx)としてグルーピングが可能です。
    auto namedMatchResult = matchFirst("My IP is 192.168.1.255 !!!",
            regex(`(?P<first>\d{1,3})\.(?:\d{1,3})\.(\d{1,3})\.(?P<last>\d{1,3})`));
    assert(namedMatchResult["first"] == "192");
    assert(namedMatchResult["last"] == "255");
    // 数字でもキャプチャした部分にアクセスできます。
    assert(namedMatchResult[1] == "192");
    // 168の部分はキャプチャしていないので、[2]は"1"になります。
    assert(namedMatchResult[2] == "1");

    // if文と組み合わせると便利です。
    if (auto capt = matchFirst("My IP is 192.168.1.255 !!!", regex(`(\d\d\d)\.(\d\d\d)\.(\d\d\d)\.(\d\d\d)`)))
    {
        // マッチしなかった場合にこの添え字アクセスはよくありませんね。
        assert(capt[1] == "192");
        assert(capt[2] == "168");
        assert(capt[3] == "1");
        assert(capt[4] == "255");
        // 安心してください。
        // ifで囲うことでマッチした場合にのみここが実行されます。
        // ですので安心して添え字を使えます。
        assert(0);
    }

    // matchFirstにはregexオブジェクトか、もしくは、ただの文字列でパターンを指定しても大丈夫です。
    // 2回以上同じパターンを使う場合ではregexオブジェクトにすると効率がよさそうです。
    if (auto capt = matchFirst("My IP is 192.168.1.255 !!!", `(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})`))
    {
        assert(capt[1] == "192");
        assert(capt[2] == "168");
        assert(capt[3] == "1");
        assert(capt[4] == "255");
    }

    // 繰り返しの最小量指定子もサポートしています。
    auto s = "Ubuntu(Linux)/Debian(Linux)/FreeBSD(BSD)";
    assert(s.matchFirst(regex(`\w+\(.*\)`)).hit == s);
    assert(s.matchFirst(regex(`\w+\(.*?\)`)).hit == "Ubuntu(Linux)");
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

    // foreach文と組み合わせると便利です。
    // また、matchAllも２つ目の引数にはregexオブジェクトのほかに、文字列でパターンを渡せます。
    size_t count;
    foreach (capt; matchAll("import core.thread, std.regex, std.stdio, core.stdio", `std\.(\w+)`))
    {
        // マッチしなかった場合にはここは実行されないので、
        // emptyのチェックや添え字の範囲チェックを省くことができて便利です。
        if (capt[1] == "stdio")
            break;
        count++;
    }
    assert(count == 1);
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

/++
# Unicodeプロパティ
+/
@safe unittest
{
    import std.regex : matchFirst, regex;

    // ひらがなのみにマッチする例です。
    auto matchFirstResult = matchFirst("abcあいう", regex(`[\pN\p{Hiragana}]+`));
    assert(matchFirstResult.hit == "あいう");
}

/++
# 先読み・後読み
+/
@safe unittest
{
    import std.algorithm : map;
    import std.array : join;
    import std.regex : regex, matchAll, matchFirst;

    // 肯定的先読みで、'H'から始まる連続した大文字を抽出します
    auto matchResults = matchAll("HAraHIrehaRAhoRE", regex(`(?=H)[A-Z]+`));
    auto joined = matchResults.map!(a => a.hit).join();
    assert(joined == "HAHI");

    // 肯定的先読みで、次の文字が'A'になる大文字を抽出します
    matchResults = matchAll("HAraHIrehaRAhoRE", regex(`[A-Z](?=A)`));
    joined = matchResults.map!(a => a.hit).join();
    assert(joined == "HR");

    // 否定的先読みで、"HI"から始まらない大文字2字を抽出します
    matchResults = matchAll("HAraHIrehaRAhoRE", regex(`(?!HI)[A-Z]{2}`));
    joined = matchResults.map!(a => a.hit).join();
    assert(joined == "HARARE");

    // 否定的先読みで、次が"HI"にならない小文字2字を抽出します
    matchResults = matchAll("HAraHIrehaRAhoRE", regex(`[a-z]{2}(?!HI)`));
    joined = matchResults.map!(a => a.hit).join();
    assert(joined == "rehaho");

    // 肯定的後読みで、前が'H'の3字を抽出します
    matchResults = matchAll("HAraHIrehaRAhoRE", regex(`(?<=H)...`));
    joined = matchResults.map!(a => a.hit).join();
    assert(joined == "AraIre");

    // 肯定的後読みで、末尾が'a'の2字を抽出します
    matchResults = matchAll("HAraHIrehaRAhoRE", regex(`..(?<=a)`));
    joined = matchResults.map!(a => a.hit).join();
    assert(joined == "raha");

    // 否定的後読みで、前が'H'じゃない大文字を抽出します
    matchResults = matchAll("HAraHIrehaRAhoRE", regex(`(?<!H)[A-Z]`));
    joined = matchResults.map!(a => a.hit).join();
    assert(joined == "HHRARE");

    // 否定的後読みで、末尾が'a'じゃない小文字2字を抽出します
    matchResults = matchAll("HAraHIrehaRAhoRE", regex(`[a-z]{2}(?<!a)`));
    joined = matchResults.map!(a => a.hit).join();
    assert(joined == "reho");

    // 肯定的後ろ読みと、肯定的先読みの組み合わせ
    // "否定"または"肯定"、次に"的"があってもなくてもよい語句から始まって、
    // 後ろには"読み"が続く、"先"または"後"の文字
    auto reLookAheadAndBhind = regex("(?<=(?:否定|肯定)的?)(?:先|後)(?=読み)");
    string[] matchFirstResults;
    foreach (str; [
        "肯定的先読み", "否定的先読み", "肯定的後読み", "否定的後読み",
        "肯定先読み",   "否定先読み",   "肯定後読み",   "否定後読み",
        "肯定的裏読み", "忌避的先読み", "肯定後ろ読み", "否定読み"
    ])
    {
        // マッチしなければ "x"、マッチしたらヒットした部分の文字
        if (auto capt = matchFirst(str, reLookAheadAndBhind))
        {
            matchFirstResults ~= capt.hit;
            // ちなみに、カッコは使ってるけどキャプチャはしていない
            // capt.lengthはヒットした文字列だけ、という意味の 1 になる
            assert(capt.length == 1);
        }
        else
        {
            matchFirstResults ~= "x";
        }
    }
    assert(matchFirstResults == [
        "先", "先", "後", "後",
        "先", "先", "後", "後",
        "x",  "x",  "x",  "x"
    ]);
}
