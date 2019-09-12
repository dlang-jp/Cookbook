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
    import std.string: chomp, splitLines;
    // プロセス起動を行うもっとも簡潔な方法はexecute関数もしくは
    // executeShell関数を用いることです。
    //
    // シェルを経由して文字列を出力するコマンドを実行します。
    // シェルを経由したい場合はexecuteShell関数を使います。
    auto result = executeShell("echo hello");
    assert(result.status == 0);
    // echoをはじめ、多くの実行結果の文字列(result.output)には改行が含まれます。
    // Linux環境なら\nが、Windows環境なら\r\nが行末に入ります。
    version (Posix)   assert(result.output == "hello\n");
    version (Windows) assert(result.output == "hello\r\n");

    // 単行ならchompで、複数行ならsplitLinesで改行文字を消してしまうと
    // 取り扱いが楽になります。
    assert(result.output.chomp == "hello");
    assert(result.output.splitLines == ["hello"]);

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
たくさんパイプしながら、データを小分けにして渡していく場合
+/
@system unittest
{
    // opensslが使えるか確認します
    bool isOpenSSLAvailable;
    version (Posix)
        isOpenSSLAvailable = executeShell(`which openssl`).status == 0;
    else version (Windows)
        isOpenSSLAvailable = executeShell(`where openssl`).status == 0;

    if (isOpenSSLAvailable)
    {
        import std.range: chunks, repeat;
        import std.algorithm: copy;
        import std.parallelism: scopedTask;
        import std.array: appender, join;

        // このデータを…
        string data = "qawsedrftgyhujikolp".repeat(512).join();
        // 2回エンコードして2回デコードし…
        auto key1 = "9F86D081884C7D659A2FEAA0C55AD015";
        auto iv1  = "A3BF4F1B2B0B822CD15D6C15B0F00A08";
        auto key2 = "9F86D081884C7D659A2FEAA0C55AD015"
                  ~ "A3BF4F1B2B0B822CD15D6C15B0F00A08";
        auto iv2  = "206DFC4E0335FA0AD986B9C1942DD653";
        auto opt1 = ["-K", key1, "-iv", iv1, "-nosalt"];
        auto opt2 = ["-K", key2, "-iv", iv2, "-nosalt", "-base64"];
        // 結果をバッファに格納します。
        auto resultBuf = appender!string;

        // プロセスを起動してパイプを作る
        auto pE1 = pipeProcess(["openssl", "aes-128-cbc", "-e"] ~ opt1);
        auto pE2 = pipeProcess(["openssl", "aes-256-cbc", "-e"] ~ opt2);
        auto pD2 = pipeProcess(["openssl", "aes-256-cbc", "-d"] ~ opt2);
        auto pD1 = pipeProcess(["openssl", "aes-128-cbc", "-d"] ~ opt1);

        // 1段目エンコード→2段目エンコード
        auto tE1toE2 = scopedTask({
            pE1.stdout.byChunk(4096).copy(pE2.stdin.lockingBinaryWriter);
            pE2.stdin.flush();
            pE2.stdin.close();
        });
        tE1toE2.executeInNewThread();

        // 2段目エンコード→2段目デコード
        auto tE2toD2 = scopedTask({
            pE2.stdout.byChunk(4096).copy(pD2.stdin.lockingBinaryWriter);
            pD2.stdin.flush();
            pD2.stdin.close();
        });
        tE2toD2.executeInNewThread();

        // 2段目デコード→1段目デコード
        auto tD2toD1 = scopedTask({
            pD2.stdout.byChunk(4096).copy(pD1.stdin.lockingBinaryWriter);
            pD1.stdin.flush();
            pD1.stdin.close();
        });
        tD2toD1.executeInNewThread();

        // 1段目デコード→(結果は文字列)→結果の格納
        auto tD1toRes = scopedTask({
            pD1.stdout.byChunk(4096).copy(resultBuf);
        });
        tD1toRes.executeInNewThread();

        // データ(文字列)→1段目エンコード
        data.chunks(2048).copy(pE1.stdin.lockingTextWriter);
        pE1.stdin.flush();
        pE1.stdin.close();

        // プロセスの終了を待ちます
        auto sE1 = pE1.pid.wait();
        auto sE2 = pE2.pid.wait();
        auto sD2 = pD2.pid.wait();
        auto sD1 = pD1.pid.wait();

        // スレッドの終了を待ちます
        tE1toE2.yieldForce;
        tE2toD2.yieldForce;
        tD2toD1.yieldForce;
        tD1toRes.yieldForce;

        // 結果確認
        assert(sE1 == 0);
        assert(sE2 == 0);
        assert(sD2 == 0);
        assert(sD1 == 0);
        assert(data == resultBuf.data);
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
    //
    version (DigitalMars) auto dmd = "dmd";
    else version (LDC) auto dmd = "ldmd2";
    else version (GNU) auto dmd = "gdmd";
    else auto dmd = "dmd";  // 他の環境では暫定的に値を埋めています。
    auto command = environment.get("DMD", dmd);
    assert(command == dmd);

}
