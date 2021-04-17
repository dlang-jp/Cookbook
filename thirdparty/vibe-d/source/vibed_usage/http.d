/++
HTTPサーバー
+/
module vibed_usage.http;

import vibed_usage._common;

/++
ふつうのHTTPサーバー

基本的な流れは、以下。
- URLRouterでパスとハンドラの割り付けを行う
- HTTPServerSettingsで接続のための情報を設定する
- listenHTTP でサーバーを起動する
- runEventLoop または runApplication でイベントループを開始する

加えて、今回はクライアント側からのアクセスでサーバーの動作を検証しています。$(BR)
さらに、Cookbookのサンプルはテストケースとして動作するように作っているため、exitEventLoopでサーバーを終了しています。
- runTask で非同期的な処理を実行する
- requestHTTP でクライアントからのリクエストを行う
- exitEventLoop でイベントループを終了する

See_Also:
- https://vibed.org/docs#http
- https://vibed.org/api/vibe.http.router/URLRouter
- https://vibed.org/api/vibe.http.server/listenHTTP
- https://vibed.org/api/vibe.http.server/HTTPServerSettings
- https://vibed.org/api/vibe.http.server/HTTPServerRequest
- https://vibed.org/api/vibe.http.server/HTTPServerResponse
- https://vibed.org/api/vibe.core.core/runTask
- https://vibed.org/api/vibe.http.client/requestHTTP
- https://vibed.org/api/vibe.core.core/runEventLoop
- https://vibed.org/api/vibe.core.core/runApplication
- https://vibed.org/api/vibe.core.core/exitEventLoop
+/
unittest
{
    import std.conv: text;
    import vibe.vibe;

    // サーバールート("/")でアクセスした際に何を表示するかを記述するハンドラーを設定する。
    // ハンドラーではHTTPServerRequest reqと、HTTPServerResponse resを使える。
    auto router = new URLRouter;
    router.get("/", (scope req, scope res) => res.writeBody("Hello world."));

    // サーバーの設定を行う。
    // 今回のようなポートとバインドするアドレスだけの単純な設定の場合は、
    // listenHTTP("localhost:80", router)
    // 等でもよい。
    auto serverSettings = new HTTPServerSettings;
    auto port = getUnusedPort();
    serverSettings.port = port;
    serverSettings.bindAddresses = ["localhost"];

    // サーバー起動
    immutable serverAddr = listenHTTP(serverSettings, router).bindAddresses[0];

    Throwable thrown;
    // runTaskで非同期処理の開始。この処理は runEventLoop の中で捌かれます。
    // ドキュメントに記載はありませんが、実装は軽量スレッド
    // (ファイバー/コルーチン/マイクロスレッド)だと思います。
    runTask({
        scope (exit)
            exitEventLoop();
        try
        {
            // クライアント側の記述
            // vibe.dにはrequestHTTPという関数があり、これでHTTPクライアントでの
            // リクエストを行うことができる。
            auto res = requestHTTP("http://".text(serverAddr), (scope req) {});
            assert(res.statusCode == 200, res.toString);
            assert(res.bodyReader.readAllUTF8() == "Hello world.");
        }
        catch (Throwable e)
            thrown = e;
    });

    // runEventLoop() でHTTPサーバーへのリクエストなどを捌く。
    auto exitCode = runEventLoop();
    assert(exitCode == 0, "exit code: ".text(exitCode));
    assert(!thrown, thrown.toString());
}


/++
dietテンプレートを使用する例

vibe.dはHTML生成のためのテンプレートライブラリを使用しています。
dietテンプレートは、PUGテンプレートと互換性の高いテンプレートライブラリです。

See_Also:
- https://vibed.org/templates/diet
- https://vibed.org/api/vibe.http.server/render : dietテンプレートファイルをコンパイルしてレスポンスヘッダに設定する
- https://vibed.org/api/diet.html/compileHTMLDietFileString : dietテンプレートファイルをコンパイルしてOutputRangeに入れる
- https://vibed.org/api/diet.html/compileHTMLDietString : 文字列をコンパイルしてOutputRangeに入れる
+/
unittest
{
    import std.conv: text;
    import vibe.vibe;
    import diet.html;
    import core.atomic: atomicOp;
    shared int counter;

    auto router = new URLRouter;
    router.get("/", (scope req, scope res){
        import std.array: appender;
        import std.string: chompPrefix, outdent;
        // アクセスカウンター+1
        int cnt = counter.atomicOp!"+="(1);
        auto contents = appender!string;
        // compileHTMLDietStringで文字列のdietテンプレートをコンパイルできる。
        // 今回はstring importを使わないで行う例を紹介したが、
        // string importが使える場合は res.render を利用した方が素直。
        // res.render!("hello.dt", cnt);
        contents.compileHTMLDietString!(`
            doctype html
            html
                head
                    title Hello
                body
                    h1 Hello, world!
                    div あなたは #{cnt} 人目の訪問者です！
        `.chompPrefix("\n").outdent, cnt);
        res.writeBody(contents.data, "text/html");
    });

    // サーバーの設定
    auto serverSettings = new HTTPServerSettings;
    auto port = getUnusedPort();
    serverSettings.port = port;
    serverSettings.bindAddresses = ["localhost"];

    // サーバー起動
    immutable serverAddr = listenHTTP(serverSettings, router).bindAddresses[0];

    Throwable thrown;
    runTask({
        scope (exit)
            exitEventLoop();
        try
        {
            import std.algorithm: canFind;
            // クライアント側の記述
            // 1回目のアクセス
            auto res = requestHTTP("http://".text(serverAddr), (scope req) {});
            assert(res.statusCode == 200, res.toString);
            auto contents = res.bodyReader.readAllUTF8();
            assert(contents.canFind("<h1>Hello, world!</h1>"));
            assert(contents.canFind("<div>あなたは 1 人目の訪問者です！</div>"));
            // 2回目のアクセス
            contents = requestHTTP("http://".text(serverAddr), (scope req) {}).bodyReader.readAllUTF8();
            assert(contents.canFind("<div>あなたは 2 人目の訪問者です！</div>"));
        }
        catch (Throwable e)
            thrown = e;
    });

    auto exitCode = runEventLoop();
    assert(exitCode == 0, "exit code: ".text(exitCode));
    assert(!thrown, thrown.toString());
}
