/++
ネットワーク(cURL)

ネットワークモジュール、特に `std.net.curl` の使い方についてまとめます。

HTTP通信などができます。

Source: $(LINK_TO_SRC source/_network_example.d)
Macros:
    TITLE=cURLを使ったネットワーク処理の例
+/
module network_example;

/++
HTTPでGET
+/
@system unittest
{
    import std.net.curl;
    import std.array: appender;
    import std.algorithm: countUntil;

    // ごく単純なGET
    auto contents1 = get("https://dlang.org");


    // 細かな設定を行うGET
    auto client = HTTP();
    // こんな感じでいろいろクライアントの設定を行う
    // (ちなみにこの設定はリダイレクトを30回まで行う設定)
    client.maxRedirects = 30;
    // get関数の２番目の引数に指定する
    auto contents2 = get("https://dlang.org", client);
    assert(contents2 == contents1);


    // 生データをGET
    auto contents3 = appender!(char[])();
    client = HTTP();
    client.url = "https://dlang.org";
    // データが分割して送られてくるのをコールバックでハンドリング
    client.onReceive = (void[] buf)
    {
        contents3 ~= cast(byte[])buf;
        return buf.length;
    };
    // GET
    client.method = HTTP.Method.get;
    // ここでネットワークと接続
    client.perform();

    // getで得たcontents1～2と、contents3の生データの内容は同一ではありません。
    // getで得たものは、文字コードのエンコードが行われています。
    // このため、エンコーダがデフォルトで存在していないShift_JISなどの
    // 文字コードのWEBページをGETしようとすると例外が発生します。
    /* ※ 一致するかどうかが不明のため
          ここではコンパイルできるかどうかだけチェックします */
    static assert(__traits(compiles,
        assert(contents1 == cast(const char[])contents3.data)));
}

/++
独自のHeaderを付けてGETリクエストを送る方法

外部APIを呼ぶ場合など、AuthorizationヘッダーでBearerトークンを渡す例です。
+/
@system unittest
{
    import std.net.curl : get, HTTP;

    const token = "0123456789";

    // HTTPオブジェクトを作り、addRequestHeaderを呼ぶことで任意のヘッダーが付けられます
    auto http = HTTP();
    http.addRequestHeader("Authorization", "Bearer " ~ token);

    auto content = get("http://httpbin.org/headers", http);

    // 以下、応答からリクエスト内容を検証します。
    import std.json : parseJSON;

    const response = parseJSON(content).object();
    const headers = response["headers"].object();
    assert(headers["Authorization"].str == "Bearer " ~ token);
}

/++
www-form-urlencoding 形式でデータをPOSTする方法
+/
@system unittest
{
    import std.net.curl : post;

    // post 関数と第2引数にデータを指定して呼び出します。
    // 第2引数にはForm形式のデータとして連想配列を指定でき、連想配列のキーと値がそのままペアでエンコードされます
    auto content = post("http://httpbin.org/anything", ["username" : "user", "password" : "pass"]);

    // 以下、応答からリクエスト内容を検証します。
    import std.json : parseJSON;

    const response = parseJSON(content).object();

    assert(response["method"].str == "POST");

    const headers = response["headers"].object();
    assert(headers["Content-Type"].str == "application/x-www-form-urlencoded");

    const forms = response["form"].object();
    assert(forms["username"].str == "user");
    assert(forms["password"].str == "pass");
}

/++
JSON 形式のデータをPOSTする方法
+/
@system unittest
{
    import std.net.curl : post, HTTP;
    import std.json : JSONValue, toJSON;

    // HTTPヘッダーに application/json を設定します。
    auto http = HTTP();
    http.addRequestHeader("Content-Type", "application/json");

    // 送信内容は文字列とするため、オブジェクトは文字列に一度変換します。
    const request = JSONValue([
        "name": JSONValue("Item"),
        "value": JSONValue(1.5)
    ]);
    const data = toJSON(request);

    // あとは通常のPOST操作と同じく、URL、データ、ヘッダーなどの情報をつけて post 関数を呼び出します。
    auto content = post("http://httpbin.org/anything", data, http);

    // 以下、応答からリクエスト内容を検証します。
    import std.json : parseJSON;

    const response = parseJSON(content).object();

    const headers = response["headers"].object();
    assert(headers["Content-Type"].str == "application/json");

    const json = response["json"].object();
    assert(json["name"].str == "Item");
    assert(json["value"].floating == 1.5);
}

/++
文字コードの話
+/
@system unittest
{
    import std.net.curl;
    import std.array: appender;
    import std.exception: assertThrown;
    import std.algorithm: countUntil;

    // 試しに今どき珍しいEUC-JPを使用しているSeesaa WikiをGET!
    get("https://wiki.seesaa.jp/").assertThrown();

    auto client = HTTP();
    auto contents = appender!(char[])();
    client.url = "https://wiki.seesaa.jp/";
    client.onReceive = (void[] buf)
    {
        contents ~= cast(byte[])buf;
        return buf.length;
    };
    client.perform();
    auto buf = contents.data;
    // 生データならEUC-JPでもちゃんと受信できます。
    // UTF-8ではないので、バイト列にEUC-JPが含まれるか検索してみます。
    assert(countUntil(cast(const ubyte[])buf,
                      cast(const ubyte[])"charset=EUC-JP"c) < buf.length);
    version (Windows)
    {
        // Windowsだとこのようにして文字コードを変換できます。
        import std.windows.charset;
        // EUC-JPだと例外を投げるような文字列の検索も
        buf.countUntil("</body>").assertThrown;
        contents ~= "\0";
        buf = contents.data;
        // 文字コード変換(EUC-JP(20932)からUTF-8)することで
        auto contents2 = fromMBSz(cast(immutable char*)buf.ptr, 20_932);
        // 検索できるようになります
        assert(contents2.countUntil("</body>") < contents2.length);
    }
    // TODO: Linuxなどでの文字コード変換方法
    // TODO: std.encodingへの文字コード変換器登録方法
}

/++
認証付きProxyを通す
+/
@system unittest
{
    import etc.c.curl: CurlAuth, CurlOption, CurlProxy;
    import std.net.curl;

    auto client = HTTP();
    // Proxyのホスト名を指定します
    client.proxy = "proxy.host.name";
    // Proxyのポート番号を指定します
    client.proxyPort = 8080;
    // Proxyの種類を指定します。デフォルトはhttpです。
    client.proxyType = CurlProxy.http;
    // Proxyの認証データのユーザー名を指定します。
    client.setProxyAuthentication("username", "password");
    // 認証方式を指定する場合はこう
    client.handle.set(CurlOption.proxyauth, CurlAuth.basic);

    // あとはgetするなど、ほかの操作と同じです
    /* ※ ここでは実在のURLやパスワードを指定していないので、
          コンパイルできるかどうかだけチェックします */
    static assert(__traits(compiles,
        get("http://hogehoge.net", client)));
}

/++
クライアント認証する

CurlOption.sslcertなどのオプションを使用します。

-  WindowsではDMDやLDCにOpenSSLがリンクされていないlibcurl.dllが使われているようですが
   クライアント認証にはOpenSSLが必要となりますので、OpenSSLがリンクされたlibcurl.dllを使用する必要があります。$(BR)
-  さらに、cURLの公式で配布している64bitのDLLは libcurl-x64.dll という名称ですが、`std.net.curl`が使用するDLLの名称は`libcurl.dll`または`curl.dll`固定です。
   このため、ファイル名を変更する必要があります。
-  また、OpenSSLのDLL`libcrypto-1_1-x64.dll`、`libssl-1_1-x64.dll`なども用意します。

なお、CA証明書、クライアント証明書や秘密鍵の生成方法・変換方法はここでは解説いたしません。
+/
@system unittest
{
    import etc.c.curl: CurlAuth, CurlOption, CurlProxy;
    import std.net.curl;

    auto client = HTTP();
    // CA証明書のPEM形式ファイルを指定します
    client.caInfo = "cacert.pem";

    // クライアント証明書に暗号化された秘密鍵がついている場合
    {
        // 秘密鍵付きのクライアント証明書のPEM形式ファイルを指定します
        client.handle.set(CurlOption.sslcert,     "clcert.pem");
        // 形式はPEMです(デフォルトはPEM)
        client.handle.set(CurlOption.sslcerttype, "PEM");
        // クライアント証明書に秘密鍵がついている場合、パスワードを指定します
        client.handle.set(CurlOption.keypasswd,   "password");
    }

    // クライアント証明書に秘密鍵が含まれておらず
    // 別途暗号化された秘密鍵を指定する場合
    {
        // クライアント証明書のPEM形式ファイルを指定します
        client.handle.set(CurlOption.sslcert,     "clcert.pem");
        // クライアント証明書の形式を指定(デフォルトはPEM)
        client.handle.set(CurlOption.sslcerttype, "PEM");
        // 暗号化された秘密鍵のPEM形式ファイルを指定します
        client.handle.set(CurlOption.sslkey,      "key.pem");
        // 秘密鍵の形式を指定(デフォルトはPEM)
        client.handle.set(CurlOption.sslkeytype,  "PEM");
        // 暗号化した秘密鍵を指定した場合、パスワードを指定
        client.handle.set(CurlOption.keypasswd,   "password");
    }

    // クライアント証明書に秘密鍵が含まれておらず
    // 復号化された秘密鍵を指定する場合
    {
        // クライアント証明書のPEM形式ファイルを指定します
        client.handle.set(CurlOption.sslcert,     "clcert.pem");
        // クライアント証明書の形式を指定(デフォルトはPEM)
        client.handle.set(CurlOption.sslcerttype, "PEM");
        // 復号化された秘密鍵のPEM形式ファイルを指定します
        client.handle.set(CurlOption.sslkey,      "decrypted-key.pem");
        // 秘密鍵の形式を指定(デフォルトはPEM)
        client.handle.set(CurlOption.sslkeytype,  "PEM");
        // 復号化された秘密鍵を指定した場合、パスワードは不要
        //client.handle.set(CurlOption.keypasswd,   "不要");
    }

    // あとはgetするなど、ほかの操作と同じです
    /* ※ ここでは実在のファイルを指定していないので、
          コンパイルできるかどうかだけチェックします */
    static assert(__traits(compiles,
        get("http://hogehoge.net", client)));
}
