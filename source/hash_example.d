/++
ハッシュ値（ダイジェスト）の計算

`std.digest` の使い方についてまとめます。

文字列やバイナリデータに対してハッシュ値（ダイジェスト）を求めたり16進数の文字列に変換する手順を整理します。

Source: $(LINK_TO_SRC source/_hash_example.d)
+/

module hash_example;

/++
様々なデータから `ubyte[N]` なハッシュ値（ダイジェスト）を計算する方法

アルゴリズム毎に提供される便利関数や `digest` 関数を使います。
なおアルゴリズムによって生成されるハッシュ値のサイズは決まっているため、これに応じて戻り値の型も変わります。
+/
unittest
{
    import std.digest;
    import std.digest.md;
    import std.digest.sha;
    import std.digest.murmurhash;
    import std.digest.hmac;

    // 基礎的なアルゴリズムでは、`<アルゴリズム名>Of`という名前の簡便なテンプレート関数が利用できます
    ubyte[16] result1 = md5Of("Hello");
    ubyte[20] result2 = sha1Of("Hello", "world");
    ubyte[32] result3 = sha256Of("Hello", "world", "!");

    // murmurhashなど、用途に合わせてパラメータを変えるようなアルゴリズムでは`digest`関数を使います
    ubyte[4] result4 = digest!(MurmurHash3!32)("Hello", ", world!");

    // HMACはシークレット値を持つ機構があり、独自に計算する必要があります。
    import std.string: representation;

    immutable(ubyte)[] data1 = "Hello".representation();
    immutable(ubyte)[] data2 = ", world!".representation();
    immutable(ubyte)[] secret = "mysecret".representation();
    ubyte[32] hmacResult1 = hmac!SHA256(data1, data2, secret);
    ubyte[32] hmacResult2 = hmac!SHA256("Hello, world!".representation(), secret);
    assert(hmacResult1 == hmacResult2);
}

/++
求めたハッシュ値から16進数の文字列(`string`)を取得する方法

`toHexString` を利用します。

`toHexString` : $(LINK https://dlang.org/phobos/std_digest.html#.toHexString)
+/
unittest
{
    import std.digest;
    import std.digest.sha;
    import std.digest.hmac;
    import std.string: representation;

    // toHexStringは、引数に ubyte[N] を受け取り char[N*2] を返すものと、 ubyte[] を受け取り string を返すものがあります。
    // stringとするためには戻り値に対してidupプロパティを取るか、引数を可変長配列とするため1度スライスを取ってから渡します。
    // なお静的に処理できる範囲が多い分、idupのほうが効率的になりやすいです。
    string result1 = sha256Of("Hello", "world", "!").toHexString().idup;
    string result2 = hmac!SHA256("Hello, world!".representation(), "mysecret".representation())[].toHexString();

    // toHexStringのテンプレート引数により、16進数の英字が大文字小文字を切り替えられます
    // 指定しない場合は大文字となっています。
    // 943a702d06f34599aee1f8da8ef9f7296031d699
    string lowerText = sha1Of("Hello, world!").toHexString!(LetterCase.lower)().idup;
    // 943A702D06F34599AEE1F8DA8EF9F7296031D699
    string upperText = sha1Of("Hello, world!").toHexString!(LetterCase.upper)().idup;

    import std.uni: isUpper, isLower;
    import std.algorithm: all;
    
    assert(lowerText.all!(c => !isUpper(c)));
    assert(upperText.all!(c => !isLower(c)));
}
