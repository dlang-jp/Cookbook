/++
例外

D言語は「例外機構」をもつ言語です。
ここでいう例外は、発生したら関数が最後まで終わるのを待たずに強制終了して、
例外を捕まえるまで関数呼び出し元をたどっていってスタックをロールバックして…
といった、いわゆる大域ジャンプを伴う、プログラムの特殊なフローのことです。
ここでは例外の使い方についてまとめます。
+/
module exception_example;

/++
# 従来の方法とその欠点

従来の例外機構のない言語では、関数の戻り値をチェックするのが一般的でした。
しかし、戻り値のチェックは、以下のような欠点を抱えていました。

1.  戻り値が無視されがち
    戻り値でエラーが発生したことを伝えても、その戻り値が無視されてしまった場合、
    失敗しても何事もなかったかのように処理が継続してしまいます。
2.  プログラムの流れが汚れがち
    たとえif文でエラーチェックをしても、同じ関数内で2回3回とチェックをするうち、
    ネストが深くなったり、gotoで関数末尾のエラー処理部へジャンプしたり、
    エラー処理のための本来行うべき処理とは関係の浅いフラグ変数が生じたりと、
    プログラムが汚くなる場合が多く存在しました。
3.  エラー処理分散しがち
    同じエラーに対処しているはずなのに、呼び出した関数すべてにエラー処理を仕込む
    必要があったり、様々なエラーをまとめて処理するのが難しい場合がありました。
4.  nullを参照してしまう問題
    1の場合とかぶりますが、nullが返る可能性のあるものでチェックを省くと、所謂
    ぬるぽ(Null Pointer Exception)や、AV(Access Violation)、
    SEGV(セグフォ/Segmentation Fault/Segmentation Violation)が発生します。
    ぬるぽが一昔前にネットスラングにまでなったように、プログラムのユーザーが目に
    する深刻な問題になりやすい異常です。しっかりガッ(対処)する必要がありますが、
    プログラムの本来の処理に手一杯になると対処を怠ってしまうことも。

以下に挙げる例は例外を使用しない場合の問題になりやすい記述方法です。
+/
@system unittest
{
    static import std.stdio;
    static import std.file;
    import core.stdc.stdio, core.stdc.stdlib;
    // 1. 戻り値が無視されがち
    char[32] buf;
    sprintf(buf.ptr, "%3s %2.1f, %3d", "abcde\0".ptr, 123.4, 1234, 9876);
    // アウト！変換されてないかも！(sprintfはエラーの場合負値を返す)
    // printf(buf);

    // 2. プログラムの流れが汚れがち
    //    以下のfooの例で、gotoや複数returnでプログラムの流れが
    ///   追いにくくなっている点に注目。
    //    (とはいえ、以下は異常処理としては比較的まっとう。)
    //    (gotoの唯一まともな使い方と言われています。)

    // 1以上の値を入力して、10より大きければ2乗+10する。
    // ただし、入力の2乗が10を超えないこと。
    // 入力が10以下なら+10して返す。
    // 正しい結果が得られない場合は負の値を返す。
    int foo(int a)
    {
        int ret = a;
        // 入力をチェックして、0なら-1, 負の値なら-2を返す
        if (a == 0)
        {
            ret = -1;
            goto L_ERR;
        }
        else if (a < 0)
        {
            ret = -2;
            goto L_ERR;
        }
        else if (a > 10)
        {
            // 入力が10以上なら aを二乗する
            ret *= a;
            // 結果をチェックして10より大きければ-3を返す
            if (ret > 10)
            {
                ret = -3;
                goto L_ERR;
            }
        }
        // 10加算する
        return ret + 10;
    L_ERR:
        return ret;
    }


    // 3. エラー処理分散しがち
    //    以下のbarの例で、fcloseが複数出ている点に注目
    //    (ひどい例の紹介なので、雰囲気だけみて適度に読み飛ばしてください)

    // fooの結果をファイルに書き込み、数値部分のファイルサイズを返す。
    // 数値書き込み時点でファイルサイズが0なら異常。
    // ファイルには数字に続けてOKと記載。
    // 正しい結果が得られない場合は負の値を返す。
    // ファイルは関数の最後に削除する。
    size_t bar(int a)
    {
        size_t ret = 0;
        int foo_result = foo(a);
        if (foo_result < 0)
        {
            // fooの結果が不正なら-1を返す
            ret = -1;
        }
        else
        {
            // ファイルを開く
            FILE* f = fopen("test.txt", "w");
            // ファイルが開けたら数値を書き込む
            if (f == null)
            {
                // ファイルが開けなければ-2を返す
                ret = -2;
            }
            else
            {
                // ファイルに数値を書き込む
                if (fprintf(f, "%d", foo_result) < 0)
                {
                    // 数値の書き込み失敗なら-3を返す
                    ret = -3;
                    if (fclose(f) == EOF)
                    {
                        // 数値の書き込み失敗後、
                        // さらにファイルが閉じられなければ-13を返す
                        ret = -13;
                    }
                }
                else
                {
                    // 数値の書き込み成功ならファイルサイズを確認
                    size_t fsize = ftell(f);
                    // ファイルサイズが1以上ならその値を返し、さもなくば-4
                    if (fsize < 1)
                    {
                        ret = -4;
                        if (fclose(f) == EOF)
                        {
                            // ファイルサイズが1未満で、
                            // さらにファイルが閉じられなければ-14を返す
                            ret = -14;
                        }
                    }
                    else
                    {
                        ret = fsize;
                        if (fprintf(f, "OK\n") < 0)
                        {
                            // OK書き込み失敗したら、-5を返してファイルを閉じる
                            ret = -5;
                            if (fclose(f) == EOF)
                            {
                                // OK書き込み失敗後、
                                // さらにファイルが閉じられなければ-15を返す
                                ret = -15;
                            }
                        }
                        else
                        {
                            // OK書き込み成功したらファイルを閉じる
                            if (fclose(f) == EOF)
                            {
                                // ファイルが閉じられなければ-6を返す
                                ret = -6;
                            }
                        }
                    }
                }
            }
        }
        return ret;
    }
    assert(bar(1) == 2);
    assert(bar(0) == -1);
    assert(bar(-10) == -1);
    assert(bar(100) == -1);
    // ファイルが開けない・閉じれない系のエラーは起こすのが難しい

    // 4. nullを参照してしまう問題
    char* ptr = cast(char*)malloc(cast(size_t)0xFFFFFFFFUL);
    // アウト！メモリ確保できてなくてnullが返ってるかも！
    // ptr[0] = 0;


    // 後処理
    if (ptr)
        free(ptr);
    if (std.file.exists("test.txt"))
        std.file.remove("test.txt");
}

/++
# 例外のメリット

例外機構を用いるメリットは、明示しない限り例外が無視されず、例外処理に対応する
箇所をまとめて記述することができるため、本来のプログラムに集中した記述ができる
という点です。

以下の例は、先述の戻り値のチェックで問題になりやすいものを、例外を使用して解決
する場合を示したものです。
+/
@system unittest
{
    static import std.stdio;
    static import std.file;
    import std.exception;
    import std.format;
    import core.stdc.stdio, core.stdc.stdlib;
    // 1. 戻り値が無視されがち
    //    →例外があるので戻り値があるケースが少ない
    //    →戻り値があってもenforceが利用できてコードの汚れが少ない
    char[32] buf;
    try
    {
        auto buf2 = sformat(buf[], "%3s %2.1f %3d", "abcde", 123.4, 1234, 9876);
        // 例外が出るのでbuf2はノーチェックでも安心して使える
        std.stdio.writeln(buf2);
    }
    catch (Exception e)
    { /* 無視 */ }
    // 例外を生じない関数を使う場合、
    // 条件が満たされなければ例外を投げるenforceが利用可能
    enforce(sprintf(buf.ptr, "%3s %2.1f, %3d", "abcde\0".ptr, 123.4, 1234, 9876) >= 0);

    // 2. プログラムの流れが汚れがち
    //    →例外で処理を本流から分離
    int foo(int a)
    {
        int ret = a;
        // 入力をチェックして、0や負の値なら異常
        if (a == 0)
            throw new Exception("Invalid Input zero");
        // enforceでさらに簡潔に。
        enforce(a >= 0, "Invalid Input minus");
        if (a > 10)
        {
            // 入力が10以上なら aを二乗する
            ret *= a;
            // 結果をチェックして10より大きければ異常
            enforce(ret <= 10, "Invalid Output over10");
        }
        return a + 10;
    }


    // 3. エラー処理分散しがち
    //    →例外で異常時の処理をまとめる
    //    →スコープガード文で後処理も楽々
    //    →enforceでnull, 0チェック
    size_t bar(int a)
    {
        // fooが勝手に例外を投げるからfooの結果を気にしなくてよい
        int foo_result = foo(a);
        // ファイルを開く。開けなければ例外。
        FILE* f = fopen("test.txt", "w").enforce("File cannot be opened.");
        // 開いた後は必ず閉じられるように、その直後にスコープガード文を書く
        scope (exit)
            enforce(fclose(f) != EOF, "File cannot be closed.");
        // ファイルに数値を書き込む。
        enforce(fprintf(f, "%d", foo_result));
        // ファイルサイズが0以上ならそれを返す
        size_t fsize = ftell(f);
        enforce(fsize > 0);
        return fsize;
    }
    assert(bar(1));
    // 例外が起こることをassertチェックするにはassertThrownが使える
    assertThrown(bar(0));
    // これでもOK
    assert(bar(-10).collectException);
    // これなら例外の内容もチェックできる
    assert(bar(100).collectExceptionMsg == "Invalid Output over10");

    // 4. nullを参照してしまう問題
    char* ptr;
    try
    {
        ptr = cast(char*)malloc(cast(size_t)0xFFFFFFFFUL).enforce("Cannot allocate memory!");
        // nullだったら例外発生しているはずだからノーチェックでOK
        ptr[0] = 0;
    }
    catch (Exception e)
    {
        // 何もしない
    }

    // 後処理
    if (ptr)
        free(ptr);
    // std.file.removeはダメだったら例外投げる。投げても無視する。
    std.file.remove("test.txt").collectException;
}

/++
# デメリットと使用を避けるべき時の判断基準

デメリットとしては、例外が発生するとプログラムを途中で切り上げてスタックの
巻戻し処理が行われるといったことが起こるため、処理速度は遅いことが挙げられます。
このため、適切な箇所でのみ例外機構を利用しましょう。
具体的には以下のようなケースでは、例外機構を用いるより、if文による事前チェックや
戻り値のチェック、表明(assert)や契約プログラミング(in/out/invariant)が望ましい
でしょう。

1.  秒間何千何万と繰り返し実行されるような処理の中で例外を発生させたり捕まえたり
    をするのは止めておくのがよいでしょう。
2.  事前のチェックを行うことで容易かつ高速に異常発生を防ぐことができるものは、
    チェックしましょう。
    (例外発生の頻度が著しく低い場合や、チェックが重い場合はとりあえずトライした
    方が速いかも)
3.  外的要因が絡まない場合はassertや、事前条件で代用できるかもしれません。
    外的要因というのは、プログラムの利用者が作成したファイルや、ネットワーク越し
    に渡されるパラメータ、GUIやCUIで入力した値、コマンドライン引数、ハードウェア
    の状態に依存するようなものなどです。
    例えばプログラム自身で作成したファイルを読み込む場合、文法チェック等は
    assertによるチェックが望ましいかもしれません。
4.  ほかの言語の関数呼び出しを行う場合、他言語間での例外のやり取りはできません。
    これは、OSのAPIやシステムコール、C言語の標準関数を使用する場合も同様です。

以下に挙げる例はあえて例外を使用しない方がよい場合の典型的な処理です。
+/
@system unittest
{
    import std.exception;
    // 1. 2重の繰り返し文の中など、繰り返し回数が多くなるケースでは避けるべき
    foreach (i; 0..1000)
    {
        foreach (j; 0..1000)
        {
            // 止めた方がいい
            version (none)
            try
            {
                if ((i * j) % 100 == 0)
                    throw new Exception("100");
            }
            catch (Exception e)
            {
                // 無視
            }
        }
    }

    // 2. 簡単に事前チェックできるならするべき
    // 例えば、3文字以下の文字列を実数に変換する場合、であれば、
    // 3文字以下はチェックが高速に行えますが、
    // 変換処理が成功するかどうかはやってみるのが速そうです。
    real str2real(string str)
    {
        if (str.length > 3)
            return real.nan;
        import std.conv;
        return str.to!real().ifThrown(real.nan);
    }
    import std.math;
    assert(str2real("100").approxEqual(100));
    assert(str2real("1000").isNaN);
    assert(str2real("aiueo").isNaN);


    // 3. 外的要因が絡む場合でチェックが面倒な場合は例外/絡まない場合はassert
    // 外部サイトのファイルサイズは時間的要因などにより変化しますので、
    // 調べてみるまで分かりません。
    // このような場合は例外で良いでしょう。
    import std.net.curl;
    enforce(get("https://dlang.org").length > 100, "Too small");

    // 一方で、このD言語ソースファイルのファイルサイズは、間違いなく100バイト
    // 以上あることがあらかじめわかっています。
    // こういう場合はassertで判定するのがよいでしょう
    import std.file;
    assert(__FILE__.getSize() > 100, "Too small");


    // 4. 他言語間で処理を受け渡す場合はnothrowにする
    // 以下では、C言語のqsortに渡すcompareコールバックをnothrowにしています。
    // といっても、例外発生する要因がないのでtry-catchでは囲んでいませんが。
    import core.stdc.stdlib;
    import std.algorithm, std.math;

    real[] ary = [1.0L, 20.0L, 3.0L, 30.0L, 4.0L];

    static extern (C) int compare(const(void)* a, const(void)* b) nothrow pure @trusted @nogc
    {
        return *cast(const real*)a < *cast(const real*)b;
    }
    qsort(&ary[0], ary.length, real.sizeof, &compare);

    assert(equal!((a, b) => a.approxEqual(b))(
        ary, [30.0L, 20.0L, 4.0L, 3.0L, 1.0L]));
}

/++
# try-catch

基本的な文法は `try {} catch(Exception e){}` です。
tryの中(呼び出した関数を含め)で例外が発生した場合、catchで例外を捕捉できます。
Exceptionと記載しましたが、ここには例外の型を記載でき、よりマッチする条件の型
から順番に記載することで、適切な対処を行うことが可能です。
+/
@safe unittest
{
    import std.algorithm, std.range;
    ubyte[] buf;
    string createBuf(string x) @trusted
    {
        import std.conv;
        try
        {
            auto y = to!size_t(x);
            if (y == 0)
                throw new Exception("Invalid number");
            buf = new ubyte[y];
            return "Converted!";
        }
        catch (ConvException e)
        {
            // 型をピンポイントで指定することで、このエラーが起きた時の処理は
            // これ、という個別の処置が可能です。
            // この場合は変換の際にエラーが生じたら、という処置になります。
            return "Cannot convert";
        }
        catch (Exception e)
        {
            // 例外の型のルートはExceptionです。例外であればこれで捕捉できます。
            return "Unknown Exception[" ~ e.msg ~ "]";
        }
        catch (Throwable e)
        {
            // Exceptionではない、Errorでもこの条件には引っかかります。ただし、
            // これを行うには、関数が@systemまたは@trustedでなければなりません。
            return "Fatal Error";
        }
    }
    assert(createBuf("1") == "Converted!");
    assert(createBuf("0.1") == "Cannot convert");
    assert(createBuf("0") == "Unknown Exception[Invalid number]");
    assert(createBuf("999999999999999") == "Fatal Error");
}

/++
# try-catch-finary
+/
@safe unittest
{
    // todo
}

/++
# scope (success) / scope (failure) / scope (exit)
+/
@safe unittest
{
    // todo
}

/++
# 例外とエラー
+/
@safe unittest
{
    // todo
}

/++
# nothrow
+/
@safe unittest
{
    // todo
}

/++
# 例外の自作
+/
@safe unittest
{
    // todo
}

/++
# std.exception.enforce
+/
@safe unittest
{
    // todo
}

/++
# std.exception.collectException
+/
@safe unittest
{
    // todo
}

/++
# std.exception.ifThrown
+/
@safe unittest
{
    // todo
}

/++
# std.exception.assertThrown / std.exception.assertNotThrown
+/
@safe unittest
{
    // todo
}

/++
# std.exception.handle
+/
@safe unittest
{
    // todo
}

