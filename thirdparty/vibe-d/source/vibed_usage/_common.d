/++
vibe.dのCookbookのサンプルで共通して利用する関数群

Source: $(LINK_TO_SRC thirdparty/vibe-d/source/vibed_usage/__common.d)
+/
module vibed_usage._common;

/++
利用していないポート番号を取得する

単にポートに0を指定してlistenHTTPすることで、未使用のポートが割り当てられる。
実際に割り当てられたポートはlistenHTTPの戻り値のbindAddressesを見ることで確認できる。
+/
ushort getUnusedPort() @safe
{
    return 0;
}
