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
基本的なパスに操作の例です。

`baseName` 関数でファイル名の取得、`dirName` 関数でディレクトリパスを取得します。
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
}

/++
ファイルパスの拡張子を操作する例です。

取得、変更、取り除く、といった操作ができます。
+/
unittest
{
    import std.path : extension, setExtension, stripExtension;

    // extension 関数で拡張子を取得します。結果としてピリオド付きの拡張子が得られます。
    // ディレクトリパスなど、拡張子が無い場合は空文字が得られます。
    assert(extension("/temp/hoge/test.txt") == ".txt");
    assert(extension("/data/2021-01-01/records.csv") == ".csv");
    assert(extension("/test/hoge/fuga") == "");

    // setExtension 関数で拡張子を変更したパスが得られます。
    // 設定する拡張子は、先頭にピリオドがあってもなくても構いません。
    assert(setExtension("/temp/hoge/test.txt", ".md") == "/temp/hoge/test.md");
    assert(setExtension("/temp/hoge/test.txt", "md") == "/temp/hoge/test.md");

    // stripExtension 関数で拡張子を取り除いたパスが得られます。
    assert(stripExtension("/temp/hoge/test.txt") == "/temp/hoge/test");
    assert(stripExtension("/data/2021-01-01/records.csv") == "/data/2021-01-01/records");
}


/++
ファイル移動の例です。

`rename` を使い、ファイル名はそのままでディレクトリパスを変更することで移動が実現できます。
+/
unittest
{
    import std.file : rename, mkdir, rmdirRecurse, write;

    // 作業用に temp1 temp2 のディレクトリを作成し、temp1 にファイルを作成しておきます
    mkdir("temp1");
    scope (exit) rmdirRecurse("temp1");

    mkdir("temp2");
    scope (exit) rmdirRecurse("temp2");

    write("temp1/test.txt", "TEST");

    // rename関数で名前を付け替えて移動します
    rename("temp1/test.txt", "temp2/test.txt");

    // 確認
    import std.file : exists, readText;

    assert(!exists("temp1/test.txt"));
    assert(exists("temp2/test.txt"));
    assert(readText("temp2/test.txt") == "TEST");
}

/++
ディレクトリ内のファイル一覧のうち、パターンに合致するものだけを列挙する例です。

`dirEntries` に対して対象とするファイル名の glob パターンを指定します。

See_Also: https://dlang.org/phobos/std_file.html#dirEntries 
See_Also: https://dlang.org/phobos/std_path.html#.globMatch
+/
unittest
{
    import std.file : mkdir, rmdirRecurse, write;

    mkdir("temp");
    scope (exit) rmdirRecurse("temp");

    write("temp/test1.txt", "");
    write("temp/test2-1.txt", "");
    write("temp/test2-2.txt", "");
    write("temp/test2-3.txt", "");
    write("temp/test3.txt", "");

    import std.file : DirEntry, dirEntries, SpanMode;

    // dirEntriesの第2引数で、globと呼ばれるパターンを指定するとファイルの一覧を絞り込めます
    // * を指定すると任意の文字列にマッチします
    string[] testFiles;
    foreach (DirEntry entry; dirEntries("temp", "test*.txt", SpanMode.shallow))
    {
        testFiles ~= entry.name;
    }

    import std.path : buildPath;

    assert(testFiles == [
        buildPath("temp", "test1.txt"),
        buildPath("temp", "test2-1.txt"),
        buildPath("temp", "test2-2.txt"),
        buildPath("temp", "test2-3.txt"),
        buildPath("temp", "test3.txt"),
    ]);

    // ? は任意の1文字にマッチします
    // [] で囲まれた文字はいずれか1文字にマッチします
    string[] test1or2;
    foreach (DirEntry entry; dirEntries("temp", "test?-[12].txt", SpanMode.shallow))
    {
        test1or2 ~= entry.name;
    }

    assert(test1or2 == [
        buildPath("temp", "test2-1.txt"),
        buildPath("temp", "test2-2.txt"),
    ]);

    // [!a] と指定した場合、a以外の1文字にマッチします
    string[] tempNot1;
    foreach (DirEntry entry; dirEntries("temp", "test2-[!1].txt", SpanMode.shallow))
    {
        tempNot1 ~= entry.name;
    }

    assert(tempNot1 == [
        buildPath("temp", "test2-2.txt"),
        buildPath("temp", "test2-3.txt"),
    ]);

    // {A,B}とすると、A または B というパターンも表現できます
    // こちらは文字ではなく任意の文字列が指定できます
    string[] test1or3;
    foreach (DirEntry entry; dirEntries("temp", "{test1,test3}.txt", SpanMode.shallow))
    {
        test1or3 ~= entry.name;
    }

    assert(test1or3 == [
        buildPath("temp", "test1.txt"),
        buildPath("temp", "test3.txt"),
    ]);
}
