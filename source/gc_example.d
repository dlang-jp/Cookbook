/++
ガベージコレクション

ガベージコレクション(GC)の制御についてまとめます。

Source: $(LINK_TO_SRC source/_gc_example.d)
+/
module gc_example;

/++
GCの有効化・無効化を行う例です。

D言語のGCは、現状では保守的なマーク＆スイープ型GCとなっています。
GCによるスキャンおよびメモリ回収は、動的メモリの要求が行われた時のみ実行されます。
事前にGC.disableを呼び出しておくことで、自動的なGCの実行を抑制することができます。
ただし、不要メモリの回収が行われなくなることで、メモリ不足のエラー(Out of memory)が発生する可能性も高くなります。
+/
@system unittest
{
    import core.memory : GC;

    /// core.memory.GCにより、GCの有効化・無効化等の制御が行えます。
    // GC.disableにより、ガベージコレクションの自動実行を停止することができます。
    // ただし、実装によっては、メモリ不足時などで引き続きGCが実行される場合があります。
    GC.disable();

    // GC.enableにより、停止したガベージコレクションが再開されます。
    // GC.enableは1回のGC.disableにつき必ず1回だけ呼び出す必要があります。
    scope(exit) GC.enable();

    // GC.disable中に動的メモリの確保が可能です。
    // メモリ不足などでない限り、基本的にGCは発生しません。
    int[] values = new int[1000];
    assert(values.length == 1000);
}

/++
明示的にGCを行う例です。

大量のオブジェクトの利用が終了した後に呼び出す、
GCを避けたい処理の前に呼び出しておく、等の用途が考えられます。
+/
@system unittest
{
    import core.memory : GC;

    // GC.profileStatsによりGC実行回数・GCにかかった時間を確認できます。
    auto beforeProfile = GC.profileStats;

    // Full collectを行います。
    // GCの実装により実際の処理は異なります。
    // 一般的には、レジスタやスタックやグローバル変数等のルート集合から
    // 使用中のメモリブロックを辿り、未使用のメモリブロックを回収します。
    GC.collect();

    // GC.collectによりGCが行われ、実行回数・GC処理時間等が増加します。
    auto afterProfile = GC.profileStats;
    assert(beforeProfile.numCollections <= afterProfile.numCollections);
    assert(beforeProfile.totalCollectionTime <= afterProfile.totalCollectionTime);
    assert(beforeProfile.totalPauseTime <= afterProfile.totalPauseTime);
}

/++
GCが確保しているメモリをOSに返却して最小化する例です。

GC.minimizeにより、GCが確保している未使用の物理メモリをOSに返却することができます。
+/
@system unittest
{
    import core.memory : GC;

    // GCが確保・利用しているメモリ量はGC.statsで取得可能です。
    auto beforeStats = GC.stats;

    // 一般的に、未使用メモリをGCにより回収しても、
    // 物理メモリはGCの中でプールされたままになっています。
    GC.collect();

    auto afterStats = GC.stats;
    assert(afterStats.usedSize <= beforeStats.usedSize);
    assert(afterStats.freeSize >= beforeStats.freeSize);

    // GC.minimizeにより、未使用の物理メモリがOSに返却されます。
    // ただし、実際に返却されるかどうか・返却されるサイズはGCの実装に依存します。
    GC.minimize();
}

/++
Dの実行ファイルでは、 GC関連のパラメーターを
コマンドラインオプション--DRT-gcoptまたは環境変数DRT_GCOPTにより設定できます。

Examples:
----
# --DRT-gcoptパラメーターによる指定
$ app "--DRT-gcopt=profile:1 minPoolSize:16" arguments to app

# 環境変数による指定
$ DRT_GCOPT="profile:1 minPoolSize:16" app arguments to app
----

GC関連パラメーターの一覧は以下で定義されています。
https://dlang.org/spec/garbage.html#gc_config

また、実行ファイルで--DRT-gcopt=helpパラメーターを指定して起動すると、
現在の設定内容とデフォルト値を確認できます。

Examples:
----
$ app --DRT-gcopt=help arguments to app
----

--DRT-gcoptパラメーターは、Dのmain関数の引数からは除外されます。
元々のコマンドラインパラメーターは、 rt.configモジュールの
rt_argsから参照することができます。

--DRTのパラメーターは、ソースコード内でrt_optionsグローバル変数を定義する事によって
デフォルト値を指定することが可能です。
+/
@system unittest
{
    // GC関連のオプションを、rt_optionsにより定義します。
    // (実際はグローバルスコープで定義を行う必要があります)
    extern(C) __gshared string[] rt_options = [
        "gcopt="
            ~ "disable:0" // 起動時にGCを無効化するかどうかを指定します。
            ~ " profile:0" // GCのプロファイリングを有効にするかどうか指定します。
            ~ " gc:conservative" // 使用するGCの種類を指定します。
                                // conservative = デフォルトで使用される保守的GCです。
                                // precise = 型情報に従った正確なスキャンを行うGCです。
                                //           誤ってポインタとみなす事によるメモリリークは防げますが
                                //           逆に、ポインタとして認識されていない場合の誤回収のリスクがあります。
                                // manual = 自動的なメモリ回収は行いません。
                                //          未使用領域はGC.freeにより明示的に解放する必要があります。
            ~ " initReserve:0B" // 起動時に確保するメモリのサイズを指定します。
                                // なお、メモリサイズの指定ではB,K,M,Gと単位を付けて指定できます。
            ~ " minPoolSize:1M" // 最小のプールサイズを指定します。
            ~ " maxPoolSize:64M" // 最大のプールサイズを指定します。
            ~ " incPoolSize:3M" // プールサイズの増加量を指定します。
            ~ " parallel:0" // GCのマーキングに使用する追加スレッド数です。
                            // デフォルトでは、利用可能なCPUコアを全て利用して並列マーキングを行います。
                            // parallel:0と指定する事で並列マーキングは行われなくなります。
            ~ " heapSizeFactor:2" // ヒープサイズ伸長時、使用済みメモリの何倍を確保していくか指定します。
            ~ " cleanup:collect" // 実行終了時、生存オブジェクトをどう扱うか指定します。
                                 // collect = 回収を行います。
                                 //           ルート領域(スタックを除く)から参照されているオブジェクトは
                                 //           デストラクタが呼ばれません。
                                 //           後方互換性のためデフォルトになっています。
                                 // none = 何もしません。
                                 // finalize = 無条件でデストラクタを呼び出します。
    ];

    // --DRT-xxxも含むコマンドライン引数は、rt_args関数により取得できます。
    // (実際はグローバルスコープでextern宣言が必要です)
    // extern extern(C) string[] rt_args() @nogc nothrow @system;

    // コマンドライン引数・環境変数によるパラメーター指定は、
    // 以下のグローバル変数を定義することで有効・無効を切り替えられます。
    // (実際はグローバルスコープで定義を行う必要があります)

    // コマンドライン引数でのDRTオプション指定の有効/無効化
    extern(C) __gshared bool rt_cmdline_enabled = false;

    // 環境でのDRTオプション指定の有効/無効化
    extern(C) __gshared bool rt_envvars_enabled = false;
}

