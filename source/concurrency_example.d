/++
`std.concurrency` を使った並行処理の例をまとめます。
+/
module concurrency_example;

/++
ファイルの書き込みを専用のスレッドで処理することで、大量の書き込みを効率良く行う例です。

これは主に大量の繰り返し計算に伴うログの記録や計算の途中経過を保存する場合のパターンとして役立ちます。
+/
unittest
{
    /+
    概要:
        std.concurrency は、spawn,send,receiveという関数を用いてスレッド間でメッセージのやり取りができます。
        それぞれ以下のように使用します。

        1. spawn で処理のためのスレッドを起動し、Tidと呼ばれるスレッドのIDを表す構造体を取得します。
        2. send でTidに対応したスレッドへメッセージを送ります。
        3. receive を使い、起動された処理の中でメッセージの到着を待機します。
    +/

    import std.concurrency : ownerTid, spawn, send, receive, receiveOnly;
    import std.file : remove;

    enum LogFilePath = "./concurrencylog.txt";

    scope (exit)
        remove(LogFilePath);

    // 書き込みの処理を行うスレッドを起動します。
    // 処理の内容は同期的に記述でき、ファイルのopen/closeは最低限で済みます。
    auto writerTid = spawn(() {
        // テストのため、ファイルを閉じるスコープは明示的に分けておきます。
        {
            import std.stdio : File;

            auto f = File(LogFilePath, "w");

            // 処理をループしながら、receive関数を使ってメッセージの到着を待ちます。
            // stringが渡されたら書き込み、boolが渡されたら処理を抜けます。
            // なお、send/receiveで送受信可能な型はスレッド間で安全に共有できる型に限られます。
            // 詳細は以下を参照してください
            // - https://dlang.org/phobos/std_traits.html#hasUnsharedAliasing
            bool shutdown = false;
            while (!shutdown)
            {
                // メッセージの型毎にハンドラーを記述することができます。
                // dfmt off
                receive(
                    (string text) {
                        f.writeln(text);
                    },
                    (bool _) {
                        shutdown = true;
                    },
                );
                // dfmt on
            }
        }

        // 処理が終わったことを起動元のスレッドに通知します。
        send(ownerTid, true);
    });

    // 何か計算をしながら必要なデータを書き込み用スレッドに送ります。
    foreach (i; 0 .. 1000)
    {
        import std.math : sin;
        import std.format : format;

        send(writerTid, format!"data : %f"(sin(cast(real)i)));
    }

    // 書き込みたいデータは送り終わったため、シャットダウン用のメッセージを送ります。
    send(writerTid, true);

    // 書き込み用スレッドの処理が完了するまで待ちます。
    // これはテストなので、ログを削除するためにファイルの書き込みを待機しています。
    receiveOnly!bool();
}

/++
前述の大量書き込みの例に対し、起動する処理を汎化/抽象化する例です。

具体的な処理を関数として定義し、実行に必要なパラメーターを引数として宣言しておくとspawnの際に渡すことができます。
+/
unittest
{
    import std.concurrency : Tid, thisTid, spawn, send, receive, receiveOnly;
    import std.file : remove;

    // 汎用的な書き込みを行う関数を定義します。
    // ここで付与するstaticは、unittest内の変数をキャプチャしないことを明示しています。
    static void writer(Tid reportTid, string filepath)
    {
        // 前述の例とほぼ同じです。
        {
            import std.stdio : File;

            auto f = File(filepath, "w");

            bool shutdown = false;
            while (!shutdown)
            {
                // dfmt off
                receive(
                    (string text) {
                        f.writeln(text);
                    },
                    (bool _) {
                        shutdown = true;
                    }
                );
                // dfmt on
            }
        }

        send(reportTid, true);
    }

    enum LogFilePath = "concurrencylog.txt";

    // spawnの際に引数を指定することができます。
    // 今回は、ファイルパスと報告先のスレッドとして単体テストを行う現在のスレッドIDを指定します。
    auto writerTid = spawn(&writer, thisTid, LogFilePath);
    scope (exit)
        remove(LogFilePath);

    foreach (i; 0 .. 1000)
    {
        import std.math : sin;
        import std.format : format;

        send(writerTid, format!"data : %f"(sin(cast(real)i)));
    }

    // 書き込みたいデータは送り終わったため、シャットダウン用のメッセージを送ります。
    send(writerTid, true);

    // 書き込み用スレッドの処理が完了するまで待ちます。
    // これはテストなので、ログを削除するためにファイルの書き込みを待機しています。
    receiveOnly!bool();
}
