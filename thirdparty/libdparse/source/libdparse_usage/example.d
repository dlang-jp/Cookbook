/++
libdparse

libdparseの使い方についてまとめます。

## 概要
libdparseはD言語のソースコードを解析するのに用いられるライブラリです。

## ドキュメント
https://libdparse.dlang.io/

## 利用例
- [ddox](https://code.dlang.org/packages/ddox) : このライブラリでシンボルやコメントを抽出してドキュメントを生成します
- [dcd](https://code.dlang.org/packages/dcd) : このライブラリでシンボル等を抽出してIDEでオートコンプリートを行うために使われます
- [dfmt](https://code.dlang.org/packages/dfmt) : このライブラリで構文を分解・再構築することでコードスタイルの俗人性を排除します
- [dscanner](https://code.dlang.org/packages/dscanner) : このライブラリで構文を読み取り、静的解析することで、バグを生みやすいコードを警告してくれます

Source: $(LINK_TO_SRC thirdparty/libdparse/source/libdparse_usage/_example.d)
+/
module libdparse_usage.example;

/++
`dparse.lexer`モジュールを用いてソースコードをトークン分解する例です。

See_Also: https://libdparse.dlang.io/dparse/lexer.html
+/
unittest
{
    import std : isInputRange, ElementType;
    import dparse.lexer : DLexer, LexerConfig, StringCache, Token, tok, str;

    string sourceCode = q{
        int x; // this is x
    };

    // DLexer構造体を作成します。
    LexerConfig config;
    auto cache = StringCache(StringCache.defaultBucketCount);
    auto lexer = DLexer(sourceCode, config, &cache, false);

    // lexerはinput rangeとして振る舞います。
    static assert(isInputRange!DLexer);
    static assert(is(ElementType!DLexer == const Token));

    // Token.typeはtok!"something"と比較可能です。
    assert(lexer.front.type == tok!"whitespace");
    lexer.popFront();

    // Token.typeはstrでstringに変換できます。
    assert(lexer.front.type == tok!"int");
    assert(str(lexer.front.type) == "int");
    lexer.popFront();

    assert(lexer.front.type == tok!"whitespace");
    lexer.popFront();

    // 識別子などの情報はToken.textから取得できます。
    assert(lexer.front.type == tok!"identifier");
    assert(lexer.front.text == "x");
    lexer.popFront();

    assert(lexer.front.type == tok!";");
    lexer.popFront();

    assert(lexer.front.type == tok!"whitespace");
    lexer.popFront();

    // コメントの内容もToken.textから取得できます。
    assert(lexer.front.type == tok!"comment");
    assert(lexer.front.text == "// this is x");
    lexer.popFront();
}

version(none)
{
/++
`dparse.parser`モジュールを用いてトークン列をASTに変換する例です。
ASTを全てtraverseする場合にはここで得られたASTを直接利用してもよいかもしれません。

See_Also: https://libdparse.dlang.io/dparse/parser.html
+/
unittest
{
    import std : array;
    import dparse.lexer : getTokensForParser, LexerConfig, StringCache, tok;
    import dparse.parser : parseModule;
    import dparse.rollback_allocator : RollbackAllocator;

    string sourceCode = q{
        int func(double x, char y) {
            return 1;
        }
    };

    // parseする際はgetTokensForParserを用います。
    // これは、DLexerからToken列を得た後でコメントに関する情報を加工するものです。
    LexerConfig config;
    auto cache = StringCache(StringCache.defaultBucketCount);
    auto tokens = getTokensForParser(sourceCode, config, &cache);

    // Token列をparseし、ASTを取得します。
    // parseModuleの第2引数に与えるファイル名は、parseに失敗した際のエラー出力文に使われます。
    RollbackAllocator rba;
    auto m = parseModule(tokens.array, "test.d", &rba);

    // 例として宣言された関数について調べてみます。
    auto f = m.declarations[0].functionDeclaration;
    assert(f.name.text == "func");
    assert(f.returnType.type2.builtinType == tok!"int");
    assert(f.parameters.parameters[0].type.type2.builtinType == tok!"double");
    assert(f.parameters.parameters[0].name.text == "x");
    assert(f.parameters.parameters[1].type.type2.builtinType == tok!"char");
    assert(f.parameters.parameters[1].name.text == "y");
}

/++
`dparser.ast`モジュールを用いてASTを処理する例です。
ASTの一部を見たい場合は効果的です。

See_Also: https://libdparse.dlang.io/dparse/ast.html
+/
unittest
{
    import std : array;
    import dparse.ast : ASTVisitor, VariableDeclaration;
    import dparse.lexer : LexerConfig, StringCache, getTokensForParser;
    import dparse.parser : parseModule;
    import dparse.rollback_allocator : RollbackAllocator;

    auto sourceCode = q{
        int x;

        void f() {
            int y;
        }

        class C {
            int z;

            this() {
                int a;
            }
        }
    };

    // 通常どおりparseします。
    LexerConfig config;
    auto cache = StringCache(StringCache.defaultBucketCount);
    RollbackAllocator rba;
    auto tokens = getTokensForParser(sourceCode, config, &cache);
    auto m = parseModule(tokens.array, "test.d", &rba);

    // 変数宣言を抽出するclassを作成します。
    class VariableExtractor : ASTVisitor
    {
        // 注目しないNodeに関するvisitorはaliasで委譲します。
        alias visit = ASTVisitor.visit;

        string[] varNames;

        override void visit(const VariableDeclaration decl)
        {
            varNames ~= decl.declarators[0].name.text;
        }
    }
    auto extractor = new VariableExtractor();
    extractor.visit(m);

    assert(extractor.varNames == ["x", "y", "z", "a"]);
}
}
