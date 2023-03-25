/++
Linux

LinuxのAPIの呼び出しについてまとめます。

概要
2023年現在の公式ドキュメントには記載がありませんが、`core.sys.linux`パッケージにはLinuxの関数宣言・構造体定義が存在し、
`import core.sys.linux.io_uring;` のように`import`を行うことで各関数を利用できます。

`core.sys.linux`パッケージはLinux環境でのみ利用できるため、
利用する場合は `version (linux) { } else { }` といった形で`version`によるプラットフォームの明記を行うことをお勧めします。$(BR)
以下の例ではWindows等の環境でもビルドできるようにするためversionで囲って表記しています。

See_Also:
    必要な関数・構造体が利用できるかは、DMDのソースコードを確認する必要があります。$(BR)
    $(LINK https://github.com/dlang/dmd/tree/master/druntime/src/core/sys/linux)

Source: $(LINK_TO_SRC posix/source/linux/_basic.d)
+/
module linux.basic;

