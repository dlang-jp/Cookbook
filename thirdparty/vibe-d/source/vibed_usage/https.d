/++
HTTPSサーバー

Source: $(LINK_TO_SRC thirdparty/vibe-d/source/vibed_usage/_https.d)
+/
module vibed_usage.https;

import vibed_usage._common;

/++
HTTPSサーバー

サーバー設定時に、 HTTPServerSettings の tlsContext を設定します。

準備するもの：
- サーバー側
  - サーバー証明書(チェーン)
  - サーバー証明書発行時の秘密鍵
- クライアント側
  - サーバー証明書を発行したCAの証明書

See_Also:
- https://vibed.org/docs#http-https
- https://vibed.org/api/vibe.stream.tls/TLSContext
+/
unittest
{
    import std.conv;
    import vibe.vibe;
    import vibe.stream.tls;

    auto router = new URLRouter;
    router.get("/", (scope req, scope res) => res.writeBody("Hello world."));

    // サーバー設定
    auto serverSettings = new HTTPServerSettings;
    auto port = getUnusedPort();
    serverSettings.port = port;
    serverSettings.bindAddresses = ["localhost"];
    // TLSの設定
    serverSettings.tlsContext = createTLSContext(TLSContextKind.server);
    // サーバー証明書から発行したルートCA認証局まで連なるチェーン証明書を指定する。
    serverSettings.tlsContext.useCertificateChainFile("thirdparty/vibe-d/certs/server-cert-chain.pem.crt");
    // サーバー証明書の秘密鍵を指定する。
    serverSettings.tlsContext.usePrivateKeyFile("thirdparty/vibe-d/certs/server-private.pem.key");

    // サーバー起動
    immutable serverAddr = listenHTTP(serverSettings, router).bindAddresses[0];

    Throwable thrown;
    runTask({
        scope (exit)
            exitEventLoop();
        try
        {
            // クライアント側の記述
            auto clientSettings = new HTTPClientSettings;
            clientSettings.tlsContextSetup = (ctx) nothrow @safe
            {
                try
                {
                    // サーバー証明書のチェーンを検証できるルートCA認証局や、
                    // 中間CA認証局～ルートCA認証局までのチェーン証明書を指定する。
                    ctx.useTrustedCertificateFile("thirdparty/vibe-d/certs/root-ca-cert.pem.crt");
                    // useTrustedCertificateFileで指定したTLSPeerValidationMode.requireCertを指定することで、
                    // CA証明書で正しく検証可能なサーバー認証を要求する。trustedCertだとさらにそれを検証する。
                    // TLSPeerValidationMode.checkPeerはサーバー証明書のDNSやIPアドレスを検証する。
                    // 今回使用する証明書はDNS指定もIP指定もない証明書なので、これを無視する。
                    ctx.peerValidationMode = TLSPeerValidationMode.trustedCert & ~TLSPeerValidationMode.checkPeer;
                }
                catch (Exception e)
                    thrown = e;
            };

            auto res = requestHTTP("https://".text(serverAddr), (scope req) {}, clientSettings);
            assert(res.statusCode == 200, res.toString);
            assert(res.bodyReader.readAllUTF8() == "Hello world.");
        }
        catch (Throwable e)
            thrown = e;
    });

    auto exitCode = runEventLoop();
    assert(exitCode == 0, "exit code: ".text(exitCode));
    assert(!thrown, thrown.toString());
}


/++
クライアント認証を要求するHTTPSサーバー

サーバー設定時に、 HTTPServerSettings の tlsContext を設定します。
特に tlsContext.peerValidationMode で TLSPeerValidationMode.requireCert を指定することで、クライアントに対してクライアント証明書を要求するようになります。

準備するもの：
- サーバー側
  - サーバー証明書(チェーン)
  - サーバー証明書発行時の秘密鍵
  - クライアント証明書を発行したCAの証明書
- クライアント側
  - クライアント証明書(チェーン)
  - クライアント証明書発行時の秘密鍵
  - サーバー証明書を発行したCAの証明書

See_Also:
- https://vibed.org/api/vibe.stream.tls/
- https://vibed.org/api/vibe.stream.tls/TLSPeerValidationMode
- https://github.com/vibe-d/vibe.d/blob/master/tests/tls/source/app.d (vibe.dのTLSのテスト)
+/
unittest
{
    import std.conv;
    import vibe.vibe;
    import vibe.stream.tls;

    auto router = new URLRouter;
    router.get("/", (scope req, scope res) => res.writeBody("Hello world."));

    // サーバー設定
    auto serverSettings = new HTTPServerSettings;
    auto port = getUnusedPort();
    serverSettings.port = port;
    serverSettings.bindAddresses = ["localhost"];
    // TLSの設定
    serverSettings.tlsContext = createTLSContext(TLSContextKind.server);
    // サーバー証明書から発行したルートCA認証局まで連なるチェーン証明書を指定する。
    serverSettings.tlsContext.useCertificateChainFile("thirdparty/vibe-d/certs/server-cert-chain.pem.crt");
    // サーバー証明書の秘密鍵を指定する。
    serverSettings.tlsContext.usePrivateKeyFile("thirdparty/vibe-d/certs/server-private.pem.key");
    // クライアント証明書のチェーンを検証できるルートCA認証局や、
    // 中間CA認証局～ルートCA認証局までのチェーン証明書を指定する。
    // クライアントがチェーン証明書を提示してくれるのであればルートCA証明書だけで良いが、
    // チェーンでないクライアント証明書を提示してくる場合はそれを発行した中間CA～ルートCAの
    // チェーン証明書が必要。できればチェーンを指定したい。
    serverSettings.tlsContext.useTrustedCertificateFile("thirdparty/vibe-d/certs/inter-ca-cert-chain.pem.crt");
    // useTrustedCertificateFileで指定したTLSPeerValidationMode.requireCertを指定することで、
    // クライアント認証を要求する。trustedCertだとさらにそれを検証する。
    // TLSPeerValidationMode.checkPeerはクライアント証明書のDNSやIPアドレスを検証する。
    // 今回使用する証明書はDNS指定もIP指定もない証明書なので、これを無視する。
    serverSettings.tlsContext.peerValidationMode = TLSPeerValidationMode.trustedCert & ~TLSPeerValidationMode.checkPeer;

    // サーバー起動
    immutable serverAddr = listenHTTP(serverSettings, router).bindAddresses[0];

    Throwable thrown;
    runTask({
        scope (exit)
            exitEventLoop();
        try
        {
            // クライアント側の記述
            auto clientSettings = new HTTPClientSettings;
            clientSettings.tlsContextSetup = (ctx) nothrow @safe
            {
                try
                {
                    // クライアント証明書から発行したルートCA認証局まで連なるチェーン証明書を指定する。
                    ctx.useCertificateChainFile("thirdparty/vibe-d/certs/client-cert-chain.pem.crt");
                    // クライアント証明書の秘密鍵を指定する。
                    ctx.usePrivateKeyFile("thirdparty/vibe-d/certs/client-private.pem.key");
                    // サーバー証明書のチェーンを検証できるルートCA認証局や、
                    // 中間CA認証局～ルートCA認証局までのチェーン証明書を指定する。
                    ctx.useTrustedCertificateFile("thirdparty/vibe-d/certs/root-ca-cert.pem.crt");
                    // useTrustedCertificateFileで指定したTLSPeerValidationMode.requireCertを指定することで、
                    // CA証明書で正しく検証可能なサーバー認証を要求する。trustedCertだとさらにそれを検証する。
                    // TLSPeerValidationMode.checkPeerはサーバー証明書のDNSやIPアドレスを検証する。
                    // 今回使用する証明書はDNS指定もIP指定もない証明書なので、これを無視する。
                    ctx.peerValidationMode = TLSPeerValidationMode.trustedCert & ~TLSPeerValidationMode.checkPeer;
                }
                catch (Exception e)
                    thrown = e;
            };

            auto res = requestHTTP("https://".text(serverAddr), (scope req) {}, clientSettings);
            assert(res.statusCode == 200, res.toString);
            assert(res.bodyReader.readAllUTF8() == "Hello world.");
        }
        catch (Throwable e)
            thrown = e;
    });

    auto exitCode = runEventLoop();
    assert(exitCode == 0, "exit code: ".text(exitCode));
    assert(!thrown, thrown.toString());
}
