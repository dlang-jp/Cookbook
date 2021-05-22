/++
ZIP走査

`std.zip`を用いてZIP形式のデータの圧縮・解凍を取り扱います。
ディレクトリ階層の再現、日本語ファイル名の取り扱いについても取り扱います。
+/
module data.zip_example;

/++
ZIP圧縮ファイルの作成と解凍

See_Also: https://dlang.org/phobos/std_zip.html
+/
@system unittest
{
    import std.zip;
    import std.string: representation;
    // ZIPファイルは、ZIPアーカイブに、アーカイブメンバー(ファイル)
    // を追加していくことで作成します
    auto zip = new ZipArchive;

    // a.txt ファイルを作成してZIPに詰めます
    // 基本は`name`と`expandedData`に非圧縮のデータを指定して
    // `compressionMethod`に`deflate`を指定すると、
    // ZIPアーカイブに`addMember`で追加する際に圧縮されます
    auto file_a = new ArchiveMember;
    file_a.name = "a.txt";
    file_a.expandedData = "File A".dup.representation;
    file_a.compressionMethod = CompressionMethod.deflate;
    zip.addMember(file_a);

    // b.txt ファイルを作成してZIPに詰めます
    auto file_b = new ArchiveMember;
    file_b.name = "b.txt";
    file_b.expandedData = "File B".dup.representation;
    // ファイルには更新日時などを付与することもできます
    import std.datetime: Clock;
    file_b.time = Clock.currTime;
    // `compressionMethod`に`none`を指定すると、無圧縮になります
    // ※圧縮率を指定することはできません。
    file_b.compressionMethod = CompressionMethod.none;
    zip.addMember(file_b);

    // c.txt ファイルをtestディレクトリの中に作成して、ZIPに詰めます
    // ディレクトリの表現は、単に `<dirname>/`という感じに、/で区切ります
    auto file_c = new ArchiveMember;
    file_c.name = "test/c.txt";
    file_c.expandedData = "File C".dup.representation;
    file_c.compressionMethod = CompressionMethod.deflate;
    zip.addMember(file_c);

    // ZIPファイルのデータを作成します
    auto zippedData = zip.build();

    // ファイルに書き出します
    static import std.file;
    std.file.write("std_zip_example.zip", zippedData);
    scope (exit)
    {
        assert(std.file.exists("std_zip_example.zip"));
        std.file.remove("std_zip_example.zip");
    }


    // ファイルを読み込んで解凍します
    /+ zippedData = std.file.read("std_zip_example.zip"); +/
    // ZipArchiveの引数に圧縮されたZIPファイルの内容を渡します
    auto zip2 = new ZipArchive(zippedData);

    // アーカイブメンバーは、ZipArchiveの`directory`にて、
    // ファイル名をキーとして連想配列と同じようにアクセスできます
    auto file_a2 = zip2.directory["a.txt"];
    assert(file_a2.name == "a.txt");

    // ZipArchiveの`expand`関数を実行することでアーカイブメンバーの圧縮データ
    // を解凍し、ファイルの中身を確認することができます
    assert(cast(const(char)[])zip2.expand(file_a2) == `File A`);
}

/++
日本語ファイル名の保存方法

日本語のファイル名を保存し、かつプラットフォーム依存をなくすには、工夫が必要です。

具体的には、各`ArchiveMemver`の`extra`に、Info-ZIP Unicode Path Extra Field、というものを使用します。このExtra Fieldが設定されている場合、`ArchiveMemver`の`name`より優先してこのパス名が使用されます。

ただし、Unicode Path Extra Field非対応のツールでは`name`に指定したパスが利用されてしまうので、その対応のため、`ArchiveMemver`の`name`にはShift_JISのファイル名を指定します。

See_Also:
- https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT
- (和訳) http://www.awm.jp/~yoya/cache/www.geocities.jp/awazou_the_8/pkzip-j.txt
+/
@system unittest
{
    import std.zip;
    import std.string: representation;
    // ZIPファイルは、ZIPアーカイブに、アーカイブメンバー(ファイル)
    // を追加していくことで作成します
    auto zip = new ZipArchive;

    // 日本語ファイル名の保存方法です
    auto file_jp = new ArchiveMember;
    file_jp.expandedData = "日本語テスト".dup.representation;

    string file_jp_name = "テスト/日本語.txt";

    // nameにはShiftJISの名称を設定します
    string file_jp_name_sjis;
    // UTF-8 → Shift_JIS 変換
    version (Windows)
    {
        // Windowsでは std.windows.charset.toMBSz() を使用する
        import std.windows.charset;
        import core.stdc.string;
        auto file_jp_name_sjisz = toMBSz(file_jp_name, 932);
        file_jp_name_sjis = cast(string) file_jp_name_sjisz[0..strlen(file_jp_name_sjisz)];
    }
    version (Posix)
    {
        version (none)
        {
            // Posixでは core.sys.posix.iconv を使用する
            import core.sys.posix.iconv: iconv_open, iconv_close, iconv;
            import std.exception: enforce;
            import core.stdc.string;
            auto conv = iconv_open("SHIFT_JIS", "UTF-8").enforce();
            scope (exit)
                iconv_close(conv);
            char* file_jp_name_utf8z = (file_jp_name ~ "\0").dup.ptr;
            size_t file_jp_name_utf8len = file_jp_name.length;
            char[] file_jp_name_sjis_buf = new char[file_jp_name_utf8len + 1];
            size_t file_jp_name_sjislen = file_jp_name_utf8len + 1;
            auto file_jp_name_sjisz = file_jp_name_sjis_buf.ptr;
            auto iconvres = iconv(conv,
                &file_jp_name_utf8z, &file_jp_name_utf8len,
                &file_jp_name_sjisz, &file_jp_name_sjislen);
            enforce(iconvres != -1);
            file_jp_name_sjis = cast(string)file_jp_name_sjis_buf[0..$ - file_jp_name_sjislen];
        }
        else
        {
            // iconvコマンド使った方が楽かも
            import std.process: pipeProcess;
            auto iconv = pipeProcess(["iconv", "-f", "UTF-8", "-t", "SHIFT_JIS"]);
            iconv.stdin.write(file_jp_name);
            iconv.stdin.flush();
            iconv.stdin.close();
            file_jp_name_sjis = iconv.stdout.readln();
        }
    }
    file_jp.name = file_jp_name_sjis;

    // Extra Fieldに、Info-ZIP Unicode Path Extra Field(0x7075)を設定する。
    import std.zlib: crc32;
    auto tsize = cast(ushort)(5 + file_jp_name.length);
    auto crc = crc32(0, file_jp_name_sjis);
    file_jp.extra ~= cast(ubyte[])[
        // タグタイプ: UPath = 0x7075('U', 'P')
        ubyte(0x75), ubyte(0x70),
        // TSize: Version以降のバイト数をLittle Endianで
        (tsize >> 0) & 0xFF, (tsize >> 8) & 0xFF,
        // Version: 現行バージョン1
        1,
        // NameCRC32: nameに指定したShift_JISのCRC32を記載する。
        //            別ツール等でUnicodeパスを無視してnameが書き換えられていたら
        //            そちらを優先するために必要らしい。
        (crc >> 0) & 0xFF, (crc >> 8) & 0xFF, (crc >> 16) & 0xFF, (crc >> 24) & 0xFF,
        ]
        // UTF-8でファイル名
        ~ file_jp_name.dup.representation;

    zip.addMember(file_jp);

    // ZIPファイルのデータを作成します
    auto zippedData = zip.build();

    // ファイルに書き出します
    static import std.file;
    std.file.write("std_zip_example_jp.zip", zippedData);
    scope (exit)
    {
        assert(std.file.exists("std_zip_example_jp.zip"));
        std.file.remove("std_zip_example_jp.zip");
    }
}
