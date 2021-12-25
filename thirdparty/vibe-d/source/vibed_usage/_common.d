/++
vibe.dのCookbookのサンプルで共通して利用する関数群

Source: $(LINK_TO_SRC thirdparty/vibe-d/source/vibed_usage/__common.d)
+/
module vibed_usage._common;

/++
利用していないポート番号を取得する
+/
ushort getUnusedPort()
{
    import core.atomic;
    shared static ushort _serial = 50_000;
    return _serial.atomicOp!"+="(1);
}
