/++
Base64エンコード/デコード

Base64のエンコードとデコードを行うサンプルです

See_Also:
    - https://dlang.org/phobos/std_base64.html
+/
module data.base64_example;

/++
Base64エンコード/デコードを行うサンプルです
+/
@safe unittest
{
    import std.base64;
    immutable ubyte[] decodedData = [0,1,2,3,4,5,6,7];
    // エンコード
    string encodedData = Base64.encode(decodedData);
    assert(encodedData == "AAECAwQFBgc=");
    // デコード
    assert(Base64.decode(encodedData) == decodedData);
}

/++
Base64エンコード/デコードの保存先をOutputRangeにすることもできます
+/
unittest
{
    import std.base64;
    import std.array: appender;
    immutable ubyte[] decodedData = [0,1,2,3,4,5,6,7];
    // エンコード
    auto enc = appender!string;
    Base64.encode(decodedData, enc);
    assert(enc.data == "AAECAwQFBgc=");
    // デコード
    auto dec = appender!(ubyte[]);
    Base64.decode(enc.data, dec);
    assert(dec.data == decodedData);
}

/++
Base64エンコード/デコードの入力元をInputRangeにすることもできます
+/
unittest
{
    import std.base64;
    import std.array: appender;
    import std.range: iota;
    import std.algorithm: equal;
    auto decodedData = iota(ubyte(0), ubyte(8));
    // エンコード
    auto enc = appender!string;
    Base64.encode(decodedData.save, enc);
    assert(enc.data == "AAECAwQFBgc=");
    // デコード
    auto dec = appender!(ubyte[]);
    Base64.decode(enc.data, dec);
    assert(dec.data.equal(decodedData.save));
}

