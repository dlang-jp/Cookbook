/++
ファイルシステム

ファイル・パス操作についてまとめます。

+/
module file_example;

/++
テキストファイル操作の例です。
+/
unittest
{
    // 注: 以下の関数は他のmoduleの関数名と被っているためrename importしています。
    import std.file : fwrite = write, fremove = remove, fappend = append;
    import std.file;

    // 指定した文字列でテキストファイルを作成します。
    string textFile = "test.txt";
    string content = "Hello, world!";
    fwrite(textFile, content);

    // ファイルの存在を確認します。
    assert(textFile.exists);

    // ファイルの中身を読み込みます。
    string loadedContent = readText(textFile);
    assert(content == loadedContent);

    // ファイル名を変更します。
    string newTextFile = "test2.txt";
    rename(textFile, newTextFile);
    assert(!textFile.exists);
    assert(newTextFile.exists);

    // ファイルに追記します。
    string additionalContent = "This is D world!!!!";
    fappend(newTextFile, additionalContent);

    // ファイルの中身を再度確認します。
    string loadedContent2 = readText(newTextFile);
    assert(loadedContent2 == content ~ additionalContent);

    // ファイルを削除します。
    fremove(newTextFile);
    assert(!newTextFile.exists);
}

/++
ディレクトリ操作の例です。
+/
unittest
{
    // 注: 以下の関数は他のmoduleの関数名と被っているためrenamed importしています。
    import std.file : fwrite = write;

    import std.algorithm : map, filter, sort;
    import std.array : array;
    import std.file;
    import std.path : buildPath;

    // ディレクトリを作成します。
    mkdir("test");

    // ディレクトリを再帰的に作成します。
    //
    // パス操作を行うときはOS間の移植をあらかじめ想定するようにしましょう。
    // std.path.buildPathはOSに依存したパスセパレータを使用してくれます。
    mkdirRecurse(buildPath("test", "foo", "bar"));

    // 処理の最後にディレクトリを再帰的に削除します。
    scope (exit) rmdirRecurse("test");

    // ファイルをディレクトリ内に作成します。
    fwrite(buildPath("test", "a.txt"), "This is File A.");
    fwrite(buildPath("test", "b.txt"), "I am File B.");
    fwrite(buildPath("test", "foo", "c.txt"), "My name is File C.");
    fwrite(buildPath("test", "foo", "bar", "d.txt"), "Please call me File D.");

    // ディレクトリ内のファイルを列挙します。
    string[] paths;
    foreach (path; dirEntries("test", SpanMode.breadth)) {
        paths ~= path.name;
    }
    sort(paths);
    assert(paths == [buildPath("test", "a.txt"),
                     buildPath("test", "b.txt"),
                     buildPath("test", "foo"),
                     buildPath("test", "foo", "bar"),
                     buildPath("test", "foo", "bar", "d.txt"),
                     buildPath("test", "foo", "c.txt")]);
}

/++
パスに関する操作の例です。
+/
unittest
{
    import std.path;

    string filePath = buildPath("test", "foo", "bar.txt");

    // ファイル名のみを抽出します。
    string fileName = filePath.baseName;
    assert(fileName == "bar.txt");

    // ディレクトリ名を抽出します。
    string fileDir = filePath.dirName;
    assert(fileDir == buildPath("test", "foo"));

    // 拡張子のみを抽出します。
    string fileExtension = filePath.extension;
    assert(fileExtension == ".txt");
}

/++
ディレクトリ階層をまとめて作成および削除する例です
+/
unittest
{
    import std.file : mkdirRecurse, rmdirRecurse, exists;

    // mkdirRecurse を使うとディレクトリ階層をまとめて作成することができます
    mkdirRecurse("temp/t1/t2");
    assert(exists("temp/t1/t2"));

    // rmdirRecurs を使うとディレクトリ階層をまとめて削除することができます
    // ファイルやディレクトリが含まれていても削除できます
    rmdirRecurse("temp");
    assert(!exists("temp"));
}

/++
ディレクトリに含まれるファイルを別のディレクトリへ移動、コピーする例です。
この例では階層構造を考慮せず、ディレクトリ直下のファイルのみを処理します。
+/
unittest
{
    import std.file : fwrite = write, mkdirRecurse, rmdirRecurse;

    // テストに必要なファイルを準備します
    mkdirRecurse("temp");
    scope (exit) rmdirRecurse("temp");
    fwrite("temp/test1.txt", "TEST");
    fwrite("temp/test2.txt", "TEST");

    mkdirRecurse("copied");
    scope (exit) rmdirRecurse("copied");

    mkdirRecurse("moved");
    scope (exit) rmdirRecurse("moved");

    import std.file : dirEntries, SpanMode, fcopy = copy, frename = rename, exists;
    import std.path : buildPath, baseName;

    // copy関数によりコピーになります。既存ファイルは上書きされます。
    foreach (entry; dirEntries("temp", SpanMode.shallow))
    {
        fcopy(entry.name, buildPath("copied", baseName(entry.name)));
    }
    assert(exists("temp/test1.txt"));
    assert(exists("temp/test2.txt"));
    assert(exists("copied/test1.txt"));
    assert(exists("copied/test2.txt"));

    // rename関数により移動になります。既存ファイルは上書きされます。
    foreach (entry; dirEntries("temp", SpanMode.shallow))
    {
        frename(entry.name, buildPath("moved", baseName(entry.name)));
    }
    assert(!exists("temp/test1.txt")); // 元ファイルは存在しません
    assert(!exists("temp/test2.txt"));
    assert(exists("moved/test1.txt"));
    assert(exists("moved/test2.txt"));
}
