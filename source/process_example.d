/++
プロセス操作についてまとめます。
+/
module process_example;

version (unittest) import std.process;

/++
基本的なプロセス起動を行う操作の例です。
+/
unittest
{
    // プロセス起動を行うもっとも簡潔な方法はexecute関数もしくは
    // executeShell関数を用いることです。
    //
    // シェルを経由して文字列を出力するコマンドを実行します。
    // shellを経由したい場合はexecuteShell関数を使います。
    auto result = executeShell("echo hello");
    assert(result.status == 0);
    assert(result.output == "hello\n");
}

/++
パイプでコマンドをつなげる例です。
+/
unittest
{
    version (Posix)
    {
        // pipeProcessを使うとパイプでコマンドをつなげることができます
        //
        import std.array : array;
        static import std.file;
        import std.path : buildPath;

        // テスト用のディレクトリを作成します
        string dirName = "std_process_testdir";
        assert(!std.file.exists(dirName));
        std.file.mkdir(dirName);
        scope (exit)
        {
            assert(std.file.exists(dirName));
            std.file.rmdirRecurse(dirName);
        }

        // ファイルをディレクトリ内に作成します。
        std.file.write(buildPath(dirName, "a.txt"), "This is File A.");
        std.file.write(buildPath(dirName, "b.txt"), "I am File B.");

        // `ls -1 | sort -r` 相当の処理を行います
        //
        auto ls = pipeProcess(["ls", "-1", dirName]);
        // コマンドの終了待ちをしないので明示的に待つ必要があります
        scope (exit)  wait(ls.pid);
        auto sort = pipeProcess(["sort", "-r"]);
        scope (exit) wait(sort.pid);

        // lsコマンドの標準出力をsortコマンドの標準入力に渡しています
        foreach (line; ls.stdout.byLine)
            sort.stdin.writeln(line);
        ls.stdout.close();
        // stdioバッファに渡されたデータがファイルディスクリプタに書き込まれて
        // いるか自明ではないので明示的にflushする必要があります
        sort.stdin.flush();
        sort.stdin.close();

        auto arr = sort.stdout.byLineCopy.array;
        assert(arr[0] == "b.txt");
        assert(arr[1] == "a.txt");
    }
}

/++
標準出力をファイルにリダイレクトする例です
+/
unittest
{
    static import std.file;
    import std.stdio;

    auto deleteme = "dub_list.txt";
    assert(!std.file.exists(deleteme));
    auto dubList = File(deleteme, "w");
    scope (exit)
    {
        dubList.close();
        assert(std.file.exists(deleteme));
        std.file.remove(deleteme);
    }
    // ジェネリックなプリミティブであるspawnProcess関数を使っています
    auto pid = spawnProcess(["dub", "list"],
                            std.stdio.stdin,
                            dubList);
    // コマンドの終了待ちをしないので明示的に待つ必要があります
    scope (exit) wait(pid);
}


/++
環境変数を扱う例です。
+/
@safe unittest
{
    import std.exception;

    auto name = "TEST_NEW_ENV";

    // 環境変数と値の組を追加します。
    environment[name] = "123";
    assert(environment[name] == "123");
    assert(name in environment);
    // 環境変数から `name` を削除します。
    environment.remove(name);
    assert(name !in environment);
    // 環境変数がみつからない場合は例外を吐きます。
    assertThrown(environment[name]);

    // `get()` を使った場合、指定した環境変数の値を返します。
    // 空だった場合は第二引数で指定しているデフォルトの値を返します。
    auto dmd = environment.get("DMD", "dmd");
    assert(dmd == "dmd");

}
