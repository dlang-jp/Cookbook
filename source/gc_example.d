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

