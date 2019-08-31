/++
ファイル・パス操作についてまとめます。

+/
module file_example;

/++
テキストファイル操作の例です。
+/
unittest
{
    import std.file;

    // 指定した文字列でテキストファイルを作成します。
    string textFile = "test.txt";
    string content = "Hello, world!";
    textFile.write(content);

    // ファイルの存在を確認します。
    assert(textFile.exists);

    // ファイルの中身を読み込みます。
    string loadedContent = readText(textFile);
    assert(content == loadedContent);

    // ファイル名を変更します。
    string newTextFile = "test2.txt";
    textFile.rename(newTextFile);
    assert(!textFile.exists);
    assert(newTextFile.exists);

    // ファイルに追記します。
    string additionalContent = "This is D world!!!!";
    newTextFile.append(additionalContent);

    // ファイルの中身を再度確認します。
    string loadedContent2 = readText(newTextFile);
    assert(loadedContent2 == content ~ additionalContent);

    // ファイルを削除します。
    remove(newTextFile);
    assert(!newTextFile.exists);
}

/++
ディレクトリ操作の例です。
+/
unittest
{
    import std.algorithm : map, filter, sort;
    import std.array : array;
    import std.file;
    import std.path;

    // ディレクトリを作成します。
    mkdir("test");

    // ディレクトリを再帰的に作成します。
    mkdirRecurse("test/foo/bar");

    // 処理の最後にディレクトリを再帰的に削除します。
    scope (exit) rmdirRecurse("test");

    // ファイルをディレクトリ内に作成します。
    write("test/a.txt", "This is File A.");
    write("test/b.txt", "I am File B.");
    write("test/foo/c.txt", "My name is File C.");
    write("test/foo/bar/d.txt", "Please call me File D.");

    // ディレクトリ内のファイルを列挙します。
    auto paths = dirEntries("test", SpanMode.breadth).map!(d => d.name).array.sort.array;
    assert(paths == ["test/a.txt", "test/b.txt", "test/foo", "test/foo/bar", "test/foo/bar/d.txt", "test/foo/c.txt"]);

    // ファイルのみを抽出します。
    auto filePaths = paths.filter!(isFile).array;
    assert(filePaths == ["test/a.txt", "test/b.txt", "test/foo/bar/d.txt", "test/foo/c.txt"]);

    // ファイル名のみを抽出します。
    auto fileNames = filePaths.map!(baseName).array;
    assert(fileNames == ["a.txt", "b.txt", "d.txt", "c.txt"]);

    //拡張子のみを抽出します。
    auto extensions = filePaths.map!(extension).array;
    assert(extensions == [".txt", ".txt", ".txt", ".txt"]);
}
