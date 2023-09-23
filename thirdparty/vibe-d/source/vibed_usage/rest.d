/++
RESTインターフェースの利用

Source: $(LINK_TO_SRC thirdparty/vibe-d/source/vibed_usage/_rest.d)
+/
module vibed_usage.rest;

import vibed_usage._common;

/++
REST APIに対応する

D言語のメタプログラミングを使って、リクエストのJSONからオブジェクトへシリアライズしてマッピングしたり、戻り値からレスポンスのJSONへのデシリアライズしたり、URLへのルーティングなどを自動化します。

主に以下を行います。
- interfaceでREST APIを定義します。
- classで上記interfaceを実装します。
- registerRestInterfaceで、interfaceを実装したclassを使って、URLRouterへの設定を自動的に行います。
  - パスの設定が自動的に行われます。
  - 受信したJSONをHTTPサーバーリクエストから分析してパラメータに割り振る、
    returnした構造体をJSONにシリアライズしてHTTPサーバーレスポンスに設定するなどのふるまいが自動的に生成され、
    ハンドラとして登録されます。
- 必須ではありませんが、 serveRestJSClient でクライアント側のJavascriptで実行できるスクリプトを自動生成でき、それをURLRouterに設定できます。

vibe.dではクライアント側についても楽できる機能 RestInterfaceClient を持っています。
RestInterfaceClient を使うと、サーバー側のinterfaceで定義したREST APIを使って、以下のようなことができます。
- interfaceの各仮想関数に対して、HTTPリクエストを行ってデータをもらってくる実装を自動的に生成します。
- リクエスト先のパスの設定も自動的に行われます。
- 引数のオブジェクトをJSONにシリアライズし、リクエストのボディに設定します。
- レスポンスのJSONをデシリアライズし、戻り値のオブジェクトにマッピングします。

See_Also:
- https://vibed.org/docs#rest-interface-generator
- https://vibed.org/api/vibe.web.rest/
- https://vibed.org/api/vibe.web.rest/registerRestInterface
- https://vibed.org/api/vibe.web.common/ (利用できるUDAが記載されている)
- https://vibed.org/api/vibe.web.rest/RestInterfaceClient
- https://vibed.org/api/vibe.web.rest/serveRestJSClient

$(WORKAROUND_ISSUE22230)
+/
unittest
{
    import std.conv;
    import vibe.vibe;

    // 未使用ポート取得
    auto port = getUnusedPort();

    // API用のインターフェースを作る
    interface MyApi
    {
        struct GetData
        {
            int a;
            string b;
        }
        struct PostData
        {
            string foo;
            int    bar;
        }
        // GET "/hoge"
        // レスポンスのボディは以下のような形式になる(実際にはスペースや改行は含まれません)
        // {
        //     "a": 42,
        //     "b": "some string"
        // }
        GetData getHoge() @safe;
        // POST "/fuga"
        // リクエストのボディは以下のような形式になる
        // {
        //     "dat": {
        //         "foo": "some string",
        //         "bar": 42
        //     }
        // }
        Json postFuga(PostData dat) @safe;
    }

    // インターフェースを実装する
    class MyApiImpliment: MyApi
    {
        GetData getHoge() @safe
        {
            return GetData(123, "hogehoge");
        }
        Json postFuga(PostData dat) @safe
        {
            return Json("Succeeded: " ~ dat.foo ~ text(dat.bar));
        }
    }

    auto router = new URLRouter;
    // 実装されたREST用のインターフェースを元に、URLRouterに自動的に登録してくれる
    router.registerRestInterface(new MyApiImpliment);
    // serveRestJSClientはJavascript用のAPIを自動生成してくれる
    router.get("/myapi.js", serveRestJSClient!MyApi());
    // サーバー起動
    immutable serverAddr = listenHTTP("localhost:".text(port), router).bindAddresses[0];

    Throwable thrown;
    runTask({
        scope (exit)
            exitEventLoop();
        try
        {
            // クライアント側の記述
            // RestInterfaceClient でインターフェースを継承したクラスを利用できる
            auto client = new RestInterfaceClient!MyApi("http://".text(serverAddr));
            auto gdat = client.getHoge();
            assert(gdat.a == 123);
            assert(gdat.b == "hogehoge");
            auto pdat = client.postFuga(MyApi.PostData("test", 32));
            assert(pdat.get!string == "Succeeded: test32");

            // 生のリクエストだと以下のような感じ。
            auto res = requestHTTP("http://".text(serverAddr) ~ "/hoge");
            assert(res.bodyReader.readAllUTF8() == `{"a":123,"b":"hogehoge"}`);
            res = requestHTTP("http://".text(serverAddr) ~ "/fuga", (scope req) {
                req.method = HTTPMethod.POST;
                req.writeBody(cast(const ubyte[])`{"dat": {"foo": "hoge", "bar": 456}}`, "application/json");
            });
            assert(res.bodyReader.readAllUTF8() == `"Succeeded: hoge456"`);

            // std.net.curlだとこんなかんじ
            // runTask内だとうまくいかないのでコメントアウト。
            // (runTaskはマイクロスレッドだからデッドロックする)
            //import std.net.curl: get, post;
            //assert(get("http://".text(serverAddr, "/hoge")) == `{"a":123,"b":"hogehoge"}`);
            //assert(post("http://".text(serverAddr, "/fuga"), `{"dat": {"foo": "hoge", "bar": 456}}`) == `"Succeeded: hoge456"`);

            // curlのコマンドラインだとこんな感じ
            // curl http://localhost:50004/fuga -X POST -H "Content-Type: application/json" -d "{\"dat\":{\"hoge\":\"xxx\",\"bar\":456}}"
        }
        catch (Throwable e)
            thrown = e;
    });

    auto exitCode = runEventLoop();
    assert(exitCode == 0, "exit code: ".text(exitCode));
    assert(!thrown, thrown.toString());

}



/++
REST APIのレスポンス形式を変更する

vibe.dでは、レスポンスのデータはJSONにシリアライズされて送信されます。JSON以外のデータを応答したい場合には、 `resultSerializer` UDAを使用して変更が可能です。

See_Also: https://vibed.org/api/vibe.web.common/resultSerializer

+/
unittest
{
    import std.conv;
    import vibe.vibe;

    // 未使用ポート取得
    auto port = getUnusedPort();

    // API用のインターフェースを作る
    interface MyApi
    {
        // GET "/hoge"
        // レスポンスのボディは、数値の配列のJSON表現である以下のような形式になる。
        // [1,2,3,4,5,6,7,8]
        immutable(ubyte)[] getHoge() @safe;

        private static void serialize(alias P, R)(ref R output, const ref immutable(ubyte)[] value)
        {
            import std.range: put;
            put(output, value);
        }
        private static immutable(ubyte)[] deserialize(alias P, R)(R input)
        {
            import std.array: array;
            return cast(immutable(ubyte)[])input.array;
        }
        // GET "/hoge2"
        // JSONではなく、バイナリを応答したい場合は以下のように、resultSerializerを指定することができる。
        @resultSerializer!(serialize, deserialize, "application/octet-stream")()
        immutable(ubyte)[] getHoge2() @safe;

        private static void serializeBase64(alias P, R)(ref R output, const ref immutable(ubyte)[] value)
        {
            import std.range: put;
            import std.base64: Base64;
            put(output, cast(ubyte[])Base64.encode(value));
        }
        private static immutable(ubyte)[] deserializeBase64(alias P, R)(R input)
        {
            import std.array: array;
            import std.base64: Base64;
            return Base64.decode(input.array).idup;
        }
        // GET "/hoge3"
        // Acceptリクエストヘッダによって応答を出し分けたい場合は以下のようにできる
        @resultSerializer!(serialize, deserialize, "application/octet-stream")()
        @resultSerializer!(serializeBase64, deserializeBase64, "plain/text")()
        immutable(ubyte)[] getHoge3() @safe;
    }

    // インターフェースを実装する
    class MyApiImpliment: MyApi
    {
        immutable(ubyte)[] getHoge() @safe
        {
            return [1,2,3,4,5,6,7,8];
        }
        immutable(ubyte)[] getHoge2() @safe
        {
            return [1,2,3,4,5,6,7,8];
        }
        immutable(ubyte)[] getHoge3() @safe
        {
            return [1,2,3,4,5,6,7,8];
        }
    }

    auto router = new URLRouter;
    // 実装されたREST用のインターフェースを元に、URLRouterに自動的に登録してくれる
    router.registerRestInterface(new MyApiImpliment);
    // serveRestJSClientはJavascript用のAPIを自動生成してくれる
    router.get("/myapi.js", serveRestJSClient!MyApi());
    // サーバー起動
    immutable serverAddr = listenHTTP("localhost:".text(port), router).bindAddresses[0];

    Throwable thrown;
    runTask({
        scope (exit)
            exitEventLoop();
        try
        {
            // クライアント側の記述
            // hogeはJSONを受信する
            auto res = requestHTTP("http://".text(serverAddr) ~ "/hoge");
            assert(res.bodyReader.readAllUTF8() == `[1,2,3,4,5,6,7,8]`);

            // hoge2はバイナリを受信する
            res = requestHTTP("http://".text(serverAddr) ~ "/hoge2");
            assert(res.bodyReader.readAll() == [1,2,3,4,5,6,7,8]);

            // hoge3はAcceptリクエストヘッダによってバイナリを受信するか
            // Base64のテキストを受信するか選択できる
            res = requestHTTP("http://".text(serverAddr) ~ "/hoge3", (scope req) {
                req.method = HTTPMethod.GET;
                req.headers["Accept"] = "application/octet-stream";
            });
            assert(res.bodyReader.readAll() == [1,2,3,4,5,6,7,8]);
            // plain/textをAcceptで設定して受信する場合は以下
            res = requestHTTP("http://".text(serverAddr) ~ "/hoge3", (scope req) {
                req.method = HTTPMethod.GET;
                req.headers["Accept"] = "plain/text";
            });
            auto hoge3b64res = res.bodyReader.readAllUTF8();
            assert(hoge3b64res == "AQIDBAUGBwg=");
            import std.base64: Base64;
            assert(Base64.decode(hoge3b64res) == [1,2,3,4,5,6,7,8]);
        }
        catch (Throwable e)
            thrown = e;
    });

    auto exitCode = runApplication();
    assert(exitCode == 0, "exit code: ".text(exitCode));
    assert(!thrown, thrown.toString());

}
