/++
例外

D言語は「例外機構」をもつ言語です。
ここでいう例外は、発生したら関数が最後まで終わるのを待たずに強制終了して、
例外を捕まえるまで関数呼び出し元をたどっていってスタックをロールバックして…
といった、いわゆる大域ジャンプを伴う、プログラムの特殊なフローのことです。
ここでは例外の使い方についてまとめます。

Source: $(LINK_TO_SRC source/_exception_example.d)
Macros:
    TITLE=例外処理の例
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
    import std.math: isClose, isNaN;
    assert(str2real("100").isClose(100));
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
        import core.exception;
        import std.conv, std.exception;
        try
        {
            auto y = to!ulong(x);
            if (y == 0)
                throw new Exception("Invalid number");
            enforce!InvalidMemoryOperationError(y <= 0xffffffffUL, "Cannot allocate memory");
            buf = new ubyte[cast(size_t)y];
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
    assert(createBuf("274877906943") == "Fatal Error");
}

/++
# try-catch-finally
Java等と同じように、finallyブロックが利用できます。
しかし、D言語ではメジャーな機能ではありません。これと同等のことを行いたい場合は`scope (exit)`を使用することが多いです。
+/
@safe unittest
{
    import core.stdc.stdlib: malloc, free;
    import std.algorithm, std.range;
    // try-catchの例と違ってGCで管理しない＝解放が必要なメモリを確保します
    // 割り当てが発生したら、解放が必要です。
    void* buf;
    string createBuf(string x) @trusted
    {
        import core.exception;
        import std.conv, std.exception;
        try
        {
            auto y = to!ulong(x);
            if (y == 0)
                throw new Exception("Invalid number");
            enforce!InvalidMemoryOperationError(y <= 0xffffffffUL, "Cannot allocate memory");
            buf = malloc(cast(size_t)y);
            return "Converted!";
        }
        catch (ConvException e)
            return "Cannot convert";
        catch (Exception e)
            return "Unknown Exception[" ~ e.msg ~ "]";
        catch (Throwable e)
            return "Fatal Error";
        finally
        {
            free(buf);
            buf = null;
        }
    }
    // どんな呼び出しでも、確実に解放されている
    assert(createBuf("1") == "Converted!");
    assert(buf is null);
    assert(createBuf("0.1") == "Cannot convert");
    assert(buf is null);
    assert(createBuf("0") == "Unknown Exception[Invalid number]");
    assert(buf is null);
    assert(createBuf("274877906943") == "Fatal Error");
    assert(buf is null);
}

/++
# スコープガード文： `scope (success)` / `scope (failure)` / `scope (exit)`
スコープガード文です。try-catch-finallyの代わりに利用できます。
それぞれ以下の文が利用できます。
- `scope (success)`は成功した(例外が発生しなかった)ときだけ実行されるブロックです
- `scope (failure)`は失敗した(例外が発生した)ときだけ実行されるブロックです
- `scope (exit)`は成否にかかわらず(例外が発生有無にかかわらず)_必ず_実行されるブロックです

特に `scope (exit)` は、リソースの確保と解放のコードを近くに記載することができるのが便利です。
+/
@safe unittest
{
    import core.stdc.stdlib: malloc, free, realloc;
    import std.algorithm, std.range;
    // try-catchの例と違ってGCで管理しない＝解放が必要なメモリを確保します
    // 割り当てが発生したら、解放が必要です。
    void* buf;
    string createBuf(string x) @trusted
    {
        string msg;
        import core.exception;
        import std.conv, std.exception;
        try
        {
            // scope文は、後に記述されたものから逆順で実行されます
            // わかりやすいように実行順に番号を振ります
            scope (exit)
                buf = null;
            // 割り当ての直後にscope (exit)を記載することで、
            // 解放を忘れることなく安全に終了することができます
            buf = malloc(100).enforce!InvalidMemoryOperationError("Cannot allocate memory");
            scope (exit)
                free(buf);
            // 例外なく終了した場合
            scope (success)
                msg = "Converted!";
            // 途中で例外が発生した場合
            scope (failure)
                msg = "Failed...";
            auto y = to!ulong(x);
            if (y == 0)
                throw new Exception("Invalid number");
            enforce!InvalidMemoryOperationError(y <= 0xffffffffUL, "Cannot allocate memory");
            buf = realloc(buf, cast(size_t)y).enforce!InvalidMemoryOperationError("Cannot allocate memory");
        }
        catch (ConvException e)
            msg ~= " Cannot convert";
        catch (Exception e)
            msg ~= " Unknown Exception[" ~ e.msg ~ "]";
        catch (Throwable e)
            msg ~= " Fatal Error";
        return msg;
    }
    // スコープガード文によってどんな呼び出しでも、確実に解放されています。
    // また、例外が発生しない場合は`"Converted!"`が、
    // そうでない場合は`msg`の先頭に`"Failed..."`がつきます
    assert(createBuf("1") == "Converted!");
    assert(buf is null);
    assert(createBuf("0.1") == "Failed... Cannot convert");
    assert(buf is null);
    assert(createBuf("0") == "Failed... Unknown Exception[Invalid number]");
    assert(buf is null);
    assert(createBuf("274877906943") == "Failed... Fatal Error");
    assert(buf is null);
}

/++
# 例外とエラー
D言語では、修復可能な問題を例外と呼び、ExceptionやExceptionを継承したクラスのオブジェクトをthrowすることによって発生させます。
一方で、修復不可能な問題の場合はエラーといって、ErrorやErrorを継承したクラスのオブジェクトをthrowします。
基本的にはErrorは修復不可能であるため、catchする必要はありません。
ExceptionもErrorもThrowableというインターフェースを継承しているので、ExceptionもErrorもcatchしたいという場合はThrowableをcatchすることができます(が、推奨されません)。

なお、safeコードの中では、ErrorやThrowableをcatchすることはできません。
+/
@system unittest
{
    void someErr() { throw new Error("Error"); }
    void someEx() { throw new Exception("Exception"); }

    bool thrown = false;

    // 例外を投げる場合
    try
        someEx();
    catch (Exception e)
        thrown = true;
    catch (Error e)
        assert(0);

    assert(thrown);
    thrown = false;

    // エラーを投げる場合
    try
        someErr();
    catch (Exception e)
        assert(0);
    catch (Error e)
        thrown = true;

    assert(thrown);
    thrown = false;

    // Throwableをcatchすればどちらでも捕捉できる
    try
        someEx();
    catch (Throwable e)
        thrown = true;

    assert(thrown);
    thrown = false;
}

/++
# nothrow
例外を投げない関数はnothrowをつけることができます。
ただし、nothrowとついていても、Errorは投げることができるので注意が必要です。
+/
@system unittest
{
    import std.exception: assertThrown;
    void someErr() { throw new Error("Error"); }
    void someEx() { throw new Exception("Exception"); }
    bool thrown = false;

    void foo() nothrow
    {
        // nothrow内では、例外を投げる可能性のある関数を呼ぶ場合はtry-catchして、
        // すべての例外に対処する必要があります。
        static assert(!__traits(compiles, someEx()));
        try
            someEx();
        catch (Exception e)
            thrown = true;
        assert(thrown);
        thrown = false;
    }
    foo();

    void bar() nothrow
    {
        // nothrow内では、エラーなら投げられる
        someErr();
    }
    assertThrown!Error(bar());
}

/++
# 例外の自作
例外クラスはExceptionを継承したクラスを自分で定義することができます。

See_Also:
    - https://dlang.org/phobos/std_exception.html#basicExceptionCtors

$(WORKAROUND_ISSUE22230)
+/
@safe unittest
{
    // Exceptionを継承したTestExceptionを定義
    class TestException: Exception
    {
        /+
        // コンストラクタでメッセージ、ファイル名、行数を渡せるようにします
        this(string msg, string file = __FILE__, size_t line = __LINE__)
        {
            super(msg, file, line);
        }
        +/
        // 上記のようなコンストラクタを毎回書くのは面倒なので、
        // 以下のような便利テンプレートがあります。
        import std.exception: basicExceptionCtors;
        ///
        mixin basicExceptionCtors;
    }

    void someEx() { throw new TestException("TestException"); }
    bool thrown = false;

    // TestExceptionが発生したときだけに対処することができます。
    try
        someEx();
    catch (TestException e)
        thrown = true;
    assert(thrown);
}

/++
# エラー時に例外を投げる便利関数 [std.exception.enforce]
もしエラーだったら例外を投げる…というユースケースを簡単にしたい場合は、enforceが便利です。

```d
auto res = foo();
if (!res)
    throw new Exception("hogehoge");
```
を、
```d
auto res = enforce(foo(), "hogehoge");
```
と書くことのできる関数です。さらに、UFCSを使うと `auto res = foo().enforce("hogehoge");` と書くこともできます。

エラーかどうかを関数の戻り値などで判定するケースは多いですが、いちいちめったに起こらない例外のために
`if (!res) throw new Exception(....)`
等と書くと本流のロジックが分断され読みづらいからあんまり書きたくないし、もし例外が起こったら呼び出し側の関数に対処してほしい…という場合に使います。

特に例外を使わずに戻り値でエラーコードの通知を行うC言語のプログラムや、Nullが帰る可能性のある関数、ダイナミックキャストの結果などで使用します。

使い方は、1個目の引数にtrueに判定されることを期待しているもの、2個目の引数にfalseに判定された時の例外メッセージを指定します。メッセージは省略可能です。
おおむね `assert()` と同じです。

`assert()` は、「絶対こうなるはず。こうならなきゃおかしい。」という場合に使って、
`enforce()` は、「うまくいけばこうなるはず。こうならなきゃ私の手に負えない何らかの例外が起こっている。」という場合に使います。

See_Also:
    - https://dlang.org/phobos/std_exception.html#enforce

$(WORKAROUND_ISSUE22230)
+/
@system unittest
{
    import std.exception: enforce;
    import core.stdc.stdlib: malloc, free;
    // mallocはnullチェックしないといけない。
    // nullだったら読み書きできないし、freeに渡してもダメなので、
    // 戻り値はnullじゃないことを強制したい。
    // そんな時にenforceを使います。
    auto ptr = malloc(1024).enforce("Memory allocation error.");
    // 以降、enforceでnullじゃないことを「強制」しているので、
    // ptrがnullかどうかは考えなくていい。
    scope (exit)
        free(ptr);

    import std.socket: Socket;
    // TcpSocketはstd.socketで多分定義されているよね
    auto tcpsock = Object.factory("std.socket.TcpSocket").enforce("TcpSocket is not declared.");

    // TcpSocketがうまく取れてれば Socket にキャストできるはずだよね
    auto sock = enforce(cast(Socket)tcpsock, "TcpSocket is not deriving from the Socket.");
}

/++
# 発生した例外を取得する便利関数 [std.exception.collectException]

もし呼び出した関数で例外が発生する可能性がある場合で、その場で例外に対処できる場合、collectExceptionが便利です。

```d
try
{
    foo();
}
catch (Exception e)
{
    // エラー処理
}
```
を、
```d
if (auto e = collectException(foo()))
{
    // エラー処理
}
```
と書くことのできる関数です。

1つの関数呼び出しのためにtry-catch構文を使うと読みづらくなりそうな場合や、
例外に対して何もしなくてよい時に握りつぶしたい場合、
例外が発生する可能性が高く、例外に対処するためのプログラムを書く場合などに、ロジックを整理しやすくすることができます。

See_Also:
    - https://dlang.org/phobos/std_exception.html#collectException

$(WORKAROUND_ISSUE22230)
+/
@system unittest
{
    import std.file;
    import std.exception: collectException, enforce;
    // std.file.removeはダメだったら例外投げる。投げたら、存在チェックする。
    if (auto e = std.file.remove("test.txt").collectException)
        enforce(!std.file.exists("test.txt"));

}

/++
# 例外発生時にデフォルト値を返すようにする便利関数 [std.exception.ifThrown]

もしかしたら例外が発生するかもしれない場合に、例外が発生した際の代替値を指定するために使用します。
See_Also:
    - https://dlang.org/phobos/std_exception.html#ifThrown
+/
@safe unittest
{
    import std.conv: to;
    import std.exception: ifThrown;
    enum teststr1 = "hogehoge";
    enum teststr2 = "42";
    // (ここではすぐ上に見えるけれども)もしかしたら数値以外が
    // 入っているかもしれない文字列を数値に変換する場合、
    // ここで数値変換時に例外を発生させず、もし例外が出た場合は
    // 0を代替として使用するようにします。
    auto num1 = teststr1.to!int.ifThrown(0);
    auto num2 = teststr2.to!int.ifThrown(0);
    assert(num1 == 0);
    assert(num2 == 42);
}

/++
# 例外が起きることをテストする便利関数 [std.exception.assertThrown / std.exception.assertNotThrown]
この関数をこの条件で呼び出すと必ず例外を発生させるはずだ、という状況をテストで検証する場合、通常ならば以下のようにcatchしてassert文で検証します。

```d
bool exthrown;
try
{
    auto num = "hogehoge".to!int();
}
catch (ConvException e)
{
    exthrown = true;
}
assert(exthrown, "hogehoge is not a number, but exception is not caught.");
```

毎回これをやるのは手間なので、 assertThrown や assertNotThrown を使って楽をすることができます。
assertThrown や assertNotThrownは、例外の型をテンプレート引数で指定することもできます。
(指定しなければExceptionがキャッチされるかどうかを確認します)

See_Also:
    - https://dlang.org/phobos/std_exception.html#assertThrown
    - https://dlang.org/phobos/std_exception.html#assertNotThrown

+/
@safe unittest
{
    import std.conv: to, ConvException;
    import std.exception: assertThrown, assertNotThrown;
    // 「数値以外入っているならこの関数は絶対失敗するはずだ」
    assertThrown!ConvException("hogehoge".to!int());
    // 「数値が入っているならこの関数は絶対失敗しないはずだ」
    assertNotThrown!ConvException("42".to!int());
}

/++
# Range操作中の例外発生要素のハンドリングをする便利関数 [std.exception.handle]

Rangeを使用した処理では、mapなど要素一つ一つに対して処理を行うような操作が多いですが、要素に対する操作中例外が発生することも少なくありません。
handle関数では要素の操作中に例外が発生した場合に、その例外への対処を行うことができます。ifThrownのRange版のような関数です。

See_Also:
    - https://dlang.org/phobos/std_exception.html#handle

$(WORKAROUND_ISSUE22230)
+/
@safe unittest
{
    import std.algorithm: equal, map, splitter;
    import std.conv: to, ConvException;
    import std.exception: handle, RangePrimitive;

    // 以下のようなCSVの中の1行を入力
    auto csvLine = "1,1,2,3,NaN,8,13,21";
    // カンマ区切りで、intに変換するが…NaNで例外が発生する。
    // このようなデータ化けはロガーなど計測器から出力されたCSVなんかで往々にして起こる…
    auto res = csvLine.splitter(',').map!(a => to!int(a));

    // handle関数で、ConvExceptionが発生した時に
    // 例外exと例外発生時のRangeのfrontを使って
    // (使えるけれどそれを無視して) -1 を結果とする
    auto handled = res.handle!(ConvException, RangePrimitive.front,
        (ex, frontValue) => -1);

    assert(handled.equal([1,1,2,3,-1,8,13,21]));
}
