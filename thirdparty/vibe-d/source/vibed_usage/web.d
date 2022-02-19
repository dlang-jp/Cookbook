/++
Webインターフェースの利用

Source: $(LINK_TO_SRC thirdparty/vibe-d/source/vibed_usage/_web.d)
+/
module vibed_usage.web;

import vibed_usage._common;

/++
Webインターフェースを利用する

Webインターフェースを利用すると、D言語のメタプログラミングを使って、クラスのメソッド名からURLへのルーティングやPOSTパラメーターの自動生成などができます。

See_Also:
- https://vibed.org/docs#web-interface-generator
- https://vibed.org/api/vibe.web.web/
- https://vibed.org/api/vibe.web.common/ (利用できるUDAが記載されている)
- https://vibed.org/api/vibe.web.web/registerWebInterface
+/
unittest
{
    import std.string: outdent, strip;
    import std.conv;
    import vibe.vibe;
    import vibe.stream.tls;

    class Web
    {
        // "/" にGETでアクセスしたときのふるまい
        void index(HTTPServerRequest req, HTTPServerResponse res)
        {
            res.writeBody(`
                <html><body>Hello, World</body></html>
            `.strip.outdent, "text/html");
        }
        // "/test" にGETでアクセスしたときのふるまい
        void getTest(HTTPServerRequest req, HTTPServerResponse res)
        {
            res.writeBody(`
                Test
            `.strip.outdent, "text/plain");
        }
    }

    auto port = getUnusedPort();
    auto router = new URLRouter;
    // Webインターフェースを元に、URLRouterに自動的に登録してくれる
    // 今回の場合は、"/"と"/test"の登録が自動的に行われる
    router.registerWebInterface(new Web);

    // サーバー起動
    immutable serverAddr = listenHTTP("localhost:".text(port), router).bindAddresses[0];

    Throwable thrown;
    runTask({
        scope (exit)
            exitEventLoop();
        try
        {
            // クライアント側の記述
            // "/"をGETする
            auto res = requestHTTP("http://".text(serverAddr), (scope req) {});
            assert(res.statusCode == 200, res.toString);
            assert(res.contentType == "text/html");
            assert(res.bodyReader.readAllUTF8() == "<html><body>Hello, World</body></html>");

            // "/test"をGETする
            res = requestHTTP("http://".text(serverAddr) ~ "/test", (scope req) { req.method = HTTPMethod.GET; });
            assert(res.statusCode == 200, res.toString);
            assert(res.contentType == "text/plain");
            assert(res.bodyReader.readAllUTF8() == "Test");
        }
        catch (Throwable e)
            thrown = e;
    });

    auto exitCode = runEventLoop();
    assert(exitCode == 0, "exit code: ".text(exitCode));
    assert(!thrown, thrown.toString());
}
