/++
Windowsにおける標準API(Win32API)の呼び出しについてまとめます。

概要
1. C言語では多くの場合 `#include <windows.h>` と記述しますが、Dでは `import core.sys.windows.windows;` と記述します。
2. あとは利用する関数が含まれるlibファイルをリンクすればシステム関数が利用できます。
    - dubでは設定ファイルの `libs` セクションにファイル名を拡張子まで含めて書きます。

なおライブラリ等でWindows以外のプラットフォームと共用するためには `version (Windows) { } else { }` で別々に書きます。$(BR)
以下の例ではLinux等の環境でもビルドできるようにするためversionで囲って表記しています。

See_Also:
    関数に対応するヘッダーとlibファイルはMicrosoft Docsのサイトから検索して見つけることができます。$(BR)
    $(LINK https://docs.microsoft.com/en-us/windows/win32/api/_winmsg/)
+/
module windows.basic;

/++
`GetSystemMetrics`関数を使ってシステム情報（マウスのボタン数）を取得する例です。
+/
unittest
{
    version (Windows)
    {
        import core.sys.windows.windows;

        auto n = GetSystemMetrics(SM_CMOUSEBUTTONS);
        assert(n >= 0);
    }
}

/++
GetComputerNameEx関数を使ってコンピューター名を取得する例です。

Windowsのシステム関数には末尾にAかWが付くものがあり、それぞれchar向けかwchar向けを表します。

Aが付く関数はシステムロケールに従って結果を返すため、多くはASCII文字列ですが日本語環境ではShift_JISになることがあります。$(BR)
Wが付く関数はUnicodeで結果を返すため、そのままwcharの文字列として扱うことができます。
+/
unittest
{
    version (Windows)
    {
        import core.sys.windows.windows;

        // 適当な長さのバッファを確保しておきます。
        DWORD length = 256;
        wchar[256] buf;

        BOOL ret = GetComputerNameExW(COMPUTER_NAME_FORMAT.ComputerNamePhysicalNetBIOS,
                buf.ptr, &length);

        assert(ret != 0);
        assert(0 < length && length <= 256);

        // 結果をスライスで取り出すことでwchar[]の文字列として利用できます。
        wchar[] computerName = buf[0 .. length];

        // wchar[]で確保したものはstd.convのtoでstringに変換することができます。
        import std.conv : to;

        string strComputerName = computerName.to!string();
        assert(0 < strComputerName.length && strComputerName.length <= 256);
    }
}
