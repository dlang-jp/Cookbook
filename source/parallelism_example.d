/++
並列処理

`std.parallelism` を使った並列処理の例をまとめます。
+/
module parallelism_example;

/++
配列データなどを元に、値毎の処理を並列で行い高速化する例です。

これは「データ並列」と呼ばれ、 `parallel` 関数を使うことで簡単に行えます。
+/
unittest
{
    import std.parallelism : parallel;

    auto data = [50, 100, 150];

    // 配列データを元に既定の TaskPool を使って並列処理を行います
    foreach (time; parallel(data))
    {
        import core.thread : Thread;
        import core.time : msecs;

        Thread.sleep(time.msecs); // 重い処理を想定
    }
    // すべての処理が完了すると foreach を抜けます
    // この例では、並列化によって最も長い 150msec の待機時間で終わることが期待できます
}

/++
`parallel` で実行する処理で一部同期が必要となる場合の例です。

いくつか実現方法はありますが、ここでは組み込みの `synchronized` 文を使い、複数のスレッドが同時に処理できない区間（クリティカルセクション）を定義します。
これは排他処理とも呼ばれます。
+/
unittest
{
    import std.parallelism : parallel;
    import std.range : iota;

    // 更新に同期が必要なオブジェクトを用意します
    size_t count;
    // 更新の処理を100回分、並列に実行します
    foreach (i; parallel(iota(100)))
    {
        // ここで synchronized を使い同期を取ります
        synchronized
        {
            // ここは synchronized の中なので処理が排他され、複数スレッドから実行されません
            count++;
        }
    }

    // 更新が排他されるため、100回適切に更新されます
    assert(count == 100);
}

/++
並列処理の基本となる `task` の使い方をまとめます。

これは何らかの「処理」を抽象化したオブジェクトであり、指定した処理を別スレッドで処理させることができます。

- 新しくスレッドを起動して実行する
- TaskPoolとして用意しておいたスレッドで実行する

以下は、処理を定義して新しいスレッドで実行、完了を待機する例です。
+/
unittest
{
    import std.parallelism : task;

    // delegate をその場で指定してタスクオブジェクトを作成
    auto t = task({
        import core.thread : Thread;
        import core.time : msecs;

        Thread.sleep(10.msecs); // 重い処理を想定
    });

    // 新しくスレッドを起動して実行します
    t.executeInNewThread();

    // 処理が終わるのを待機します
    t.yieldForce();
}

/++
ランタイムが用意したスレッドを使って `task` を実行する例です。

実行の際に `taskPool` を使うことでスレッドを使いまわし、実行の度に新しくスレッドを起動するコストが削減できます。

処理の実行は、`taskPool` に `task` を `put` することにより行えます。

なお、`taskPool` が起動するスレッド数は環境によって異なり、`CPU数 - 1` として計算されます。
この `CPU数` は `totalCPUs` という定数によって得ることができます。
+/
unittest
{
    import std.parallelism : task, taskPool;

    // delegate をその場で指定してタスクオブジェクトを作成
    auto t = task({
        import core.thread : Thread;
        import core.time : msecs;

        Thread.sleep(10.msecs);
    });

    // 用意しておいたスレッドプールで実行します
    taskPool.put(t);

    // 処理が終わるのを待機します
    t.yieldForce();

    // 環境毎のCPU数を確認します
    import std.parallelism : totalCPUs;

    assert(totalCPUs() > 0);
}

/++
戻り値を持つ `task` の使用例です。

`task` で実行する処理は戻り値を持つことができ、処理の結果は `yieldForce` の戻り値として得られます。

これを `executeInNewThread` と組み合わせると、簡便な「戻り値を持つスレッド」として使うことができます。
+/
unittest
{
    import std.parallelism : task;

    auto t = task({
        import std.file : readText;

        // 戻り値を返す
        return readText("dub.sdl");
    });

    // 新しくスレッドを起動して実行します
    t.executeInNewThread();

    // yieldForce の戻り値として結果が返ってくる
    const text = t.yieldForce();

    assert(text.length > 0);
}

/++
スレッド数を指定した独自の TaskPool を作る例です。

処理が通信などCPUを使わない処理を含む場合、CPUより多くのスレッドを起動しておくことで処理の高速化が期待できます。
+/
unittest
{
    import std.parallelism : TaskPool, task;
    import std : iota, map, array;

    // 16スレッドで処理するプールを作成します
    auto customPool = new TaskPool(16);
    // 利用が済んだら finish を呼んでワーカースレッドを解放します。
    // これを行わないとワーカースレッドの待機によりプログラムが終了しない場合があります。
    scope (exit) customPool.finish();

    // 50-150msの待機時間を100個用意します。
    auto times = iota(100).map!"a + 50".array();

    // parallel による並列でプールを指定することができます
    foreach (time; customPool.parallel(times))
    {
        import core.thread : Thread;
        import core.time : msecs;

        Thread.sleep(time.msecs);
    }
    // すべての処理が終わったら foreach を抜けます

    // task を作って処理させることもできます
    auto t = task({
        import core.thread : Thread;
        import core.time : msecs;

        Thread.sleep(50.msecs);
    });
    customPool.put(t);

    t.yieldForce();
}
