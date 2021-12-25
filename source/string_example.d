/++
文字列

文字列操作についてまとめます。

TODO: 置換(replace), 削除(remove), 分割(split)

Source: $(LINK_TO_SRC source/_string_example.d)
+/
module string_example;

/++
D言語の文字列の種類

D言語の文字列は、基本的に文字の配列で、特別な型やクラスがあるわけではありません。ただし、文字型はchar(UTF-8), wchar(UTF-16), dchar(UTF-32)があり、それぞれ修飾子がありますので、種類は多いです。
また、UTF-8, UTF-16, UTF-32 以外の文字コードは「バイト列(符号なし8bit整数の配列)」という扱いです。ただし、一部のライブラリや、C言語との受け渡しインターフェースなどには便宜上char型を使うことがあります。

| 型修飾               | UTF-8                      | UTF-16                      | UTF-32                      | それ以外                    |
|:--------------------:|:--------------------------:|:---------------------------:|:---------------------------:|:---------------------------:|
| (none)               | char[]                     | wchar[]                     | dchar[]                     | ubyte[]                     |
| const型              | const(char)[]              | const(wchar)[]              | const(dchar)[]              | const(ubyte)[]              |
| inout型              | inout(char)[]              | inout(wchar)[]              | inout(dchar)[]              | inout(ubyte)[]              |
| shared型             | shared(char)[]             | shared(wchar)[]             | shared(dchar)[]             | shared(ubyte)[]             |
| const shared型       | const shared(char)[]       | const shared(wchar)[]       | const shared(dchar)[]       | const shared(ubyte)[]       |
| inout shared型       | inout shared(char)[]       | inout shared(wchar)[]       | inout shared(dchar)[]       | inout shared(ubyte)[]       |
| const inout型        | const inout(char)[]        | const inout(wchar)[]        | const inout(dchar)[]        | const inout(ubyte)[]        |
| const inout shared型 | const inout(shared char)[] | const inout shared(wchar)[] | const inout shared(dchar)[] | const inout shared(ubyte)[] |
| immutable型          | immutable(char)[]          | immutable(wchar)[]          | immutable(dchar)[]          | immutable(ubyte)[]          |

この中でも、特に利用頻度が高いのが`immutable(char)[]`型で、これは文字列リテラルの型であり、特別に`string`という別名が利用できます。
同様に、`immutable(wchar)[]`には`wstring`という別名が、`immutable(dchar)[]`には`dstring`という別名が、それぞれ利用できます。

immutableはマルチスレッド間でクリティカルセクションなしに同時アクセスできたり、寿命を考えなくてもよい点、const型への暗黙変換ができる点などが便利です。

以下のサンプルでは文字コード(UTF-8, UTF-16, UTF-32)のそれぞれの変換について説明します
+/
unittest
{
    import std.utf: toUTF8, toUTF16, toUTF32, toUTF16z;
    // 日本語のあいうえおはUTF-8で15バイト
    string str1 = "あいうえお";
    assert(str1.length == 15);

    // "あいうえお"を5要素で扱いたい場合は、dstringを使用する
    dstring str2 = "あいうえお"d;
    assert(str2.length == 5);

    // UTF-8からUTF-32への変換は toUTF32 でできます
    dstring str3 = str1.toUTF32();
    assert(str3 == str2);
    // 逆に、UTF-32からUTF-8は、toUTF8()
    assert(str2.toUTF8() == str1);

    // char型(UTF-8)の配列であるstr1でも、foreachで
    // dchar型(UTF-32)に変換して要素アクセスできます。
    size_t idx = 0;
    foreach (dchar c; str1)
    {
        assert(str2[idx] == c);
        idx++;
    }

    // UTF-16型へは toUTF16 を使います。
    wstring str4 = str1.toUTF16();
    wstring str5 = str2.toUTF16();

    // string型(immutable(char)[]型)をchar[]型にする場合は、
    // .dupでコピーを行います。
    char[] str6 = str1.dup;

    // char[]型をstring型(immutable(char)[]型)にする場合は、
    // .idupで破壊されないメモリとしてコピーします
    string str7 = str6.idup;
}

/++
文字列型の使い分け

文字列の型は、おおむね次のような使い分けをします。

- 普段使いは`string`
- 関数引数で、関数が終わった後はメモリが破壊されてもいいなら`const(char)[]`
- 関数引数で、関数が終わった後にメモリが破壊されて困るなら`string`
- 1文字が1要素であってほしい場合は`dchar[]`や`dstring`
- N文字目を書き換えたい場合は`dchar[]`
- Windows APIに渡すなら`wchar[]`や`const(wchar)[]`

さらに、D言語では、スライスの型はありません。`string`のスライスは`string`だし、`const(char)[]`のスライスは`const(char)[]`です。
+/
unittest
{
    // ■ 普段使いは string で大丈夫です
    string str1 = "あいうえお";

    // ■ 関数引数で、関数が終わった後はメモリが破壊されてもいいなら
    // `const(char)[]`を使います。
    // サンプルとして、文字列から「あい」を見つける関数
    // 「あい」をさがした後は死んでもかまわないので、
    // 引数は const(char)[] が妥当でしょう。
    bool findLove(const(char)[] str)
    {
        import std.string;
        return str.indexOf("あい") != -1;
    }
    // 関数を読んだ後でも引数が生き続けるケース
    assert(findLove(str1));
    // 関数を読んだ後に引数の寿命が終わり、メモリが破損するケース
    {
        char[15] str2 = "かきくけこ";
        assert(!findLove(str2[]));
    }

    // ■ 関数引数で、関数が終わった後にメモリが破壊されて困るなら`string`
    // 以下のメンバ関数のsetName, のように、関数が終わった後で
    // 寿命が尽きてはいけない場合には、stringや、コピーを保存する必要があります。
    struct Data
    {
        string name;
        void setName(string str)
        {
            name = str;
        }
        void setNameCopy(const(char)[] str)
        {
            // idupをつけるとconst(char)[]やchar[]のコピーを作り、
            // string型にしてくれます。
            name = str.idup;
        }
    }
    Data dat;
    // 関数を読んだ後でも引数が生き続けるケース
    dat.setName(str1);
    assert(dat.name == "あいうえお");
    // 関数を読んだ後に引数の寿命が終わり、メモリが破損するケース
    {
        char[15] str3 = "かきくけこ";
        dat.setNameCopy(str3[]);
    }
    // str3はすでに破棄されているが、コピーを取っているので
    // dat.nameにはアクセスできる
    assert(dat.name == "かきくけこ");

    // ■ 1文字が1要素であってほしい場合は`dchar[]`や`dstring`
    dstring str4 = "さしすせそ";
    // 以下のように文字数やN文字目の文字が欲しい場合、UTF-32を使います。
    assert(str4.length == 5);
    assert(str4[2] == 'す');

    // ■ N文字目を書き換えたい場合は`dchar[]`
    dchar[] str5 = "やかん"d.dup;
    str5[0] = 'ち';
    assert(str5 == "ちかん"d);

    // ■ Windows APIに渡すなら`wchar[]`や`const(wchar)[]`
    // 特にWindowsAPIに渡す場合はtoUTF16z()を呼び出して
    // "\0"終端の文字列の先頭ポインタを得ることができ、
    // そのままLPCWSTR等の型を要求する関数へ渡すことができます
    version (Windows)
    {
        import std.utf: toUTF16z;
        import core.sys.windows.windows: GetEnvironmentVariableW, NULL;
        GetEnvironmentVariableW(str1.toUTF16z(), NULL, 0);
    }
}


/++
文字列の連結➀

文字列は単純な文字の配列なので、`~`演算子で連結できます。
+/
unittest
{
    string str1 = "あいうえお";
    string str2 = "かきくけこ";
    // ~ で連結
    assert(str1 ~ str2 == "あいうえおかきくけこ");

    const(char)[] str3 = "さしすせそ";
    char[] str4 = "たちつてと".dup;

    // ~ による連結は、必ず新規でメモリを確保してコピーを作成するので、
    // char[]型にもstring型にもできます。
    char[] str5 = str1 ~ str3 ~ str4;
    assert(str5 == "あいうえおさしすせそたちつてと");

    // ただし、stringとchar[]型など、違う型修飾子が混じっている場合の
    // 連結後の型はchar[]型となるので、string型にするにはcastが必要です。
    string str6 = cast(immutable)(str1 ~ str3 ~ str4);
    assert(str6 == "あいうえおさしすせそたちつてと");

    // やってることはcast(immutable)と同じですが、assumeUniqueのほうが明示的です。
    // (ユニークと見なす＝ここ以外で参照していないメモリなので、immutableにして問題ないという意味)
    import std.exception: assumeUnique;
    string str7 = assumeUnique(str1 ~ str3 ~ str4);
    assert(str7 == "あいうえおさしすせそたちつてと");

    // 伸展しながら連結する場合、 ~= を使用します。
    // これは、str2 = str2 ~ str3 と同じ意味となります。
    str2 ~= str3;
    assert(str2 == "かきくけこさしすせそ");
    str2 ~= str4;
    assert(str2 == "かきくけこさしすせそたちつてと");
}


/++
文字列の連結➁

事前に長さの分からない文字列を構築する場合、`std.array` の `appender` を使います。

`appender` : https://dlang.org/phobos/std_array.html#appender
+/
unittest
{
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

/++
プログラムの整形文字列表現

chompPrefixやstrip、outdent、などを使うことで、プログラム言語などの文字列表現をいい感じに記載することができます。

ポイントはoutdentでインデントを解除することで、その前後にoutdentの入力にマッチするようにいい感じにchompPrefixで先頭の改行を削除したり、outdent結果を欲しい形に合うようにstripで先頭・末尾の改行を含む空白文字を削除するなどの前処理・後処理をします。

パーサーを扱うようなプログラムなどで活躍します。

`outdent`: https://dlang.org/phobos/std_string.html#.outdent$(BR)
`chompPrefix`: https://dlang.org/phobos/std_string.html#.chompPrefix$(BR)
`strip`: https://dlang.org/phobos/std_string.html#.strip
+/
unittest
{
    import std.json;
    import std.string: outdent, chompPrefix, strip;
    auto jv = JSONValue(
        [
            "one": JSONValue(1),
            "two": JSONValue(
            [
                JSONValue(2),
                JSONValue("弐")
            ])
        ]);

    // jvを文字列化したものが正しいことをassertすると
    // 入れ子になっていると以下のようになってしまい、1行だと見づらいですね。
    assert(jv.toString() == `{"one":1,"two":[2,"弐"]}`);

    // まして、整形したものｎあぁああああああああああ！！！！！
    assert(jv.toPrettyString() == "{\n    \"one\": 1,\n    \"two\": [\n        2,\n        \"弐\"\n    ]\n}");

    // しかしながら、改行してしまうと以下のようにインデントが崩れてしまいます。
    assert(jv.toPrettyString() == `{
    "one": 1,
    "two": [
        2,
        "弐"
    ]
}`);

    // これを解決するためには、以下のようにchompPrefix, outdentを使います。
    assert(jv.toPrettyString() == `
    {
        "one": 1,
        "two": [
            2,
            "弐"
        ]
    }`.chompPrefix("\n").outdent);

    string fixLines(string s)
    {
        version (Windows)
        {
            import std.array: replace;
            return s.replace("\r\n", "\n");
        }
        else return s;
    }

    // 最初にoutdent、次にstripでもOK。(この場合最後の改行もなくなる)
    // ついでに以下の例は q{ ... } の文字列表現です。
    // また、fixLinesを通すのは、q{ ... }が改行コードをそのまま拾ってしまうため
    // gitの設定如何でCRLFだったりLFだったりする場合があるのを均すためです。
    assert(jv.toPrettyString() == fixLines(q{
        {
            "one": 1,
            "two": [
                2,
                "弐"
            ]
        }
    }.outdent.strip));
}

/++
16進数文字列の変換

バイト列を16進数の文字列で表現したものをバイト列に変換するのと、その逆を行います。

See_Also:
    - https://dlang.org/phobos/std_conv.html#hexString
    - https://dlang.org/phobos/std_conv.html#to
    - https://dlang.org/phobos/std_range.html#chunks
    - https://dlang.org/phobos/std_algorithm_iteration.html#.map
    - https://dlang.org/phobos/std_array.html#.array
    - https://dlang.org/phobos/std_format.html#.format
    - https://dlang.org/phobos/std_digest.html#.toHexString
+/
@safe unittest
{
    // コンパイル時に、バイト列を16進数の文字列で表現したものをバイト列に変換
    import std.conv: hexString;
    static immutable bindat = hexString!"010203a4b5c6";
    static assert(bindat == [0x01, 0x02, 0x03, 0xa4, 0xb5, 0xc6]);

    // 実行時に、バイト列を16進数の文字列で表現したものをバイト列に変換
    import std.conv: to;
    import std.range: chunks;
    import std.algorithm: map;
    import std.array: array;
    auto hexstr = "010203a4b5c6";
    auto rtbindat = hexstr.chunks(2).map!(a => a.to!ubyte(16)).array;
    assert(rtbindat == [0x01, 0x02, 0x03, 0xa4, 0xb5, 0xc6]);
    // コンパイル時でも行ける
    static immutable ctbindat = "010203a4b5c6".chunks(2).map!(a => a.to!ubyte(16)).array;
    static assert(ctbindat == [0x01, 0x02, 0x03, 0xa4, 0xb5, 0xc6]);

    // 実行時に、バイト列を16進数の文字列で表現したものに変換
    import std.format: format;
    auto rthexstr = format!"%(%02x%)"(rtbindat);
    assert(rthexstr == "010203a4b5c6");
    // コンパイル時でも行ける
    static immutable cthexstr = format!"%(%02x%)"(ctbindat);
    static assert(cthexstr == "010203a4b5c6");

    // 本当はダイジェスト値用ですが、これでも大丈夫です。
    // formatより若干速いはず。
    // ただし、コンパイル時には使えません。
    import std.digest: toHexString, LetterCase;
    assert(rtbindat.toHexString() == "010203A4B5C6");
    assert(rtbindat.toHexString!(LetterCase.lower) == "010203a4b5c6");
}
