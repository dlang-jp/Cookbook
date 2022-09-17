/++
POSIX

POSIXの呼び出しについてまとめます。

概要
2022年現在の公式ドキュメントには記載がありませんが、`core.sys.posix`パッケージにはPOSIXの関数宣言・構造体定義が存在し、
`import core.sys.posix.unistd;` のように`import`を行うことで各関数を利用できます。

`core.sys.posix`パッケージはPOSIX環境でのみ利用できるため、
利用する場合は `version (Posix) { } else { }` といった形で`version`によるプラットフォームの明記を行うことをお勧めします。$(BR)
以下の例ではWindows等の環境でもビルドできるようにするためversionで囲って表記しています。

See_Also:
    必要な関数・構造体が利用できるかは、DMDのソースコードを確認する必要があります。$(BR)
    $(LINK https://github.com/dlang/dmd/tree/master/druntime/src/core/sys/posix)

Source: $(LINK_TO_SRC posix/source/posix/_basic.d)
+/
module posix.basic;

/++
POSIXのAPIを直接利用したechoサーバー・クライアントの例です。
+/
unittest
{
    version (Posix)
    {
        
    }
}
