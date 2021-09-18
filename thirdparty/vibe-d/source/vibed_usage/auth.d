/++
認証・権限

認証や権限といった、ユーザー情報を取り扱ったりアクセスを規制したりする方法について説明します。
+/
module vibed_usage.auth;

import vibed_usage._common;

/++
ベーシック認証

平文でパスワードをやり取りする認証方式です。

Attention:
HTTP通信では使用すると重大なセキュリティリスクがあるので、必ずHTTPS通信と一緒に使いましょう。

See_Also:
- https://vibed.org/docs#http-authentication
- https://vibed.org/api/vibe.http.auth.basic_auth/performBasicAuth
- https://github.com/vibe-d/vibe.d/blob/master/examples/auth_basic/source/app.d
+/
unittest
{
    import vibe.vibe;
    import std.conv: text;

    bool checkPassword(string user, string password)
    {
        return user == "admin" && password == "secret";
    }
    void index(HTTPServerRequest req, HTTPServerResponse res)
    {
        res.writeBody(`
            <html><body>Hello, World</body></html>
        `.strip.outdent, "text/html");
    }

    auto port = getUnusedPort();
    auto router = new URLRouter;
    // 以降Routerに追加されるパスに対してBasic認証をかける
    router.any("*", performBasicAuth("Basic Auth Test", toDelegate(&checkPassword)));
    // GET /
    router.get("/", toDelegate(&index));


    // サーバー起動
    immutable serverAddr = listenHTTP("localhost:".text(port), router).bindAddresses[0];

    Throwable thrown;
    runTask({
        scope (exit)
            exitEventLoop();
        try
        {
            // クライアント側の記述
            // 認証なしで"/"をGETする
            auto res = requestHTTP("http://".text(serverAddr), (scope req) {});
            assert(res.statusCode == 401, res.toString);
            res.dropBody();

            // Basic認証ありで"/"をGETする
            import std.base64: Base64;
            import std.string: representation;
            res = requestHTTP("http://".text(serverAddr), (scope req) {
                req.method = HTTPMethod.GET;
                immutable(ubyte)[] authData = "admin:secret".representation;
                req.headers.addField("Authorization", "Basic " ~ Base64.encode(authData).idup);
            });
            assert(res.statusCode == 200, res.toString);
            assert(res.contentType == "text/html");
            assert(res.bodyReader.readAllUTF8() == "<html><body>Hello, World</body></html>");
            res.dropBody();
        }
        catch (Throwable e)
            thrown = e;
    });

    auto exitCode = runEventLoop();
    assert(exitCode == 0, "exit code: ".text(exitCode));
    assert(!thrown, thrown.toString());
}


/+
ダイジェスト認証

HTTPSが使えない場合や、パスワードをなんとしても通信に乗せたくないしサーバーに教えたくないって場合に有効な認証方式です。

Attention:
vibe.dでのダイジェスト認証で利用されるMD5はセキュリティリスクがある(頑張れば逆変換できる)ので、Basic認証と同程度か多少マシってくらいの方式です。
また、中間者攻撃に対しても脆弱です。この点から見てもBasic認証と同程度か多少マシってくらいの方式です。
どちらにしろやはりHTTPS通信と一緒に使えという話になります。

See_Also:
- https://vibed.org/api/vibe.http.auth.digest_auth/performDigestAuth
- https://github.com/vibe-d/vibe.d/blob/master/examples/auth_digest/source/app.d

Bug:
現在バグのためダイジェスト認証はうまく動作しない。
- https://github.com/vibe-d/vibe.d/issues/2597
+/
version (none) unittest
{
    import vibe.vibe;
    import std.conv: text;

    enum serverRealm = "Digest Auth Test";

    // あらかじめRealmごとにユーザー名とパスワードからダイジェスト値を計算しておく
    auto digestList = [
        "user": createDigestPassword(serverRealm, "user", "secret"),
        "admin": createDigestPassword(serverRealm, "admin", "password"),];

    // Realmとユーザー名からダイジェスト値を返す
    string digestPassword(string realm, string user) @safe nothrow
    {
        if (realm != serverRealm)
            return "";
        if (auto digest = user in digestList)
            return *digest;
        return "";
    }
    void index(HTTPServerRequest req, HTTPServerResponse res)
    {
        res.writeBody(`
            <html><body>Hello, World</body></html>
        `.strip.outdent, "text/html");
    }

    auto port = getUnusedPort();
    auto router = new URLRouter;
    auto authInfo = new DigestAuthInfo;
    authInfo.realm = serverRealm;
    // 以降Routerに追加されるパスに対してBasic認証をかける
    router.any("*", performDigestAuth(authInfo, &digestPassword));
    // GET /
    router.get("/", toDelegate(&index));

    // サーバー起動
    immutable serverAddr = listenHTTP("localhost:".text(port), router).bindAddresses[0];

    Throwable thrown;
    runTask({
        scope (exit)
            exitEventLoop();
        try
        {
            // クライアント側の記述
            // 認証なしで"/"をGETする
            auto res = requestHTTP("http://".text(serverAddr), (scope req) {});
            assert(res.statusCode == 401, res.toString);
            import std.regex;
            auto r = regex(`Digest realm="(.+?)", nonce="(.+?)",`);
            auto m = matchFirst(res.headers["WWW-Authenticate"], r);
            res.dropBody();

            // Digest認証ありで"/"をGETする
            import std.digest.md: md5Of, toHexString, LetterCase;
            import std.base64: Base64;
            import std.uuid: randomUUID;
            import std.string: representation;
            res = requestHTTP("http://".text(serverAddr), (scope req) {
                req.method = HTTPMethod.GET;
                alias lo = LetterCase.lower;
                auto ha1 = md5Of("user:" ~ m[1] ~ ":secret").toHexString!lo();
                auto ha2 = md5Of("GET:/").toHexString!lo();
                auto authRes = md5Of(format!`%s:%s:%s`(ha1, m[2], ha2)).toHexString!lo();
                req.headers.addField("Authorization", "Digest "
                    ~ `realm="` ~ m[1] ~ `", `
                    ~ `nonce="` ~ m[2] ~ `", `
                    ~ `username="user", `
                    ~ `uri="/", `
                    ~ `response="` ~ authRes.idup ~ `"`);
            });
            assert(res.statusCode == 200, res.toString);
            assert(res.contentType == "text/html");
            assert(res.bodyReader.readAllUTF8() == "<html><body>Hello, World</body></html>");
            res.dropBody();
        }
        catch (Throwable e)
            thrown = e;
    });

    auto exitCode = runEventLoop();
    assert(exitCode == 0, "exit code: ".text(exitCode));
    assert(!thrown, thrown.toString());
}

/++
セッション

ログインなど、セッション情報を残してデータを管理したい場合の説明です。

See_Also:
- https://vibed.org/docs#http-sessions
- https://vibed.org/api/vibe.http.server/HTTPServerRequest.session
- https://vibed.org/api/vibe.http.server/HTTPServerResponse.startSession
- https://vibed.org/api/vibe.http.server/HTTPServerResponse.terminateSession
- https://vibed.org/api/vibe.http.session/
- https://vibed.org/api/vibe.http.session/Session
- https://vibed.org/api/vibe.web.web/SessionVar
- https://github.com/vibe-d/vibe.d/blob/master/examples/web/source/app.d

+/
// TODO: Redisを使った分散ストアなど専用ページを設けて認証と分ける
unittest
{
    import vibe.vibe;
    import std.conv: text;

    class Web
    {
    @safe:
        // セッション情報と紐づく変数を定義します
        SessionVar!(string, "username") _username;
    public:
        // GET /
        void index(scope HTTPServerRequest req, scope HTTPServerResponse res)
        {
            // セッション情報を読み取ります
            // 以下のコードとおおむね同等
            // string username = req.session.get!string("username");
            string username = _username;
            if (username.length == 0)
            {
                // ログイン前
                res.writeBody("Please login.", "text/plain");
            }
            else
            {
                // ログイン後
                res.writeBody("Hello, " ~ username ~ ".", "text/plain");
            }
        }

        // POST /login
        // 認証API風ですが、本サンプルではセッション情報の記録に主眼を置いて
        // いるため、パスワード等のセキュリティは考慮していません。
        void postLogin(string username, scope HTTPServerRequest req, scope HTTPServerResponse res)
        {
            // セッション情報を保存します。
            // 以下のコードとおおむね同等
            //auto session = res.startSession();
            //session.set("username", username);
            _username = username;
            redirect("/");
        }
    }

    auto port = getUnusedPort();
    auto router = new URLRouter;
    router.registerWebInterface(new Web);
    auto settings = new HTTPServerSettings;
    settings.port = port;
    settings.bindAddresses = ["localhost"];
    // ログイン認証用にセッションの準備
    settings.sessionStore = new MemorySessionStore;

    // サーバー起動
    immutable serverAddr = listenHTTP(settings, router).bindAddresses[0];

    Throwable thrown;
    runTask({
        scope (exit)
            exitEventLoop();
        try
        {
            // クライアント側の記述
            import std.algorithm: map;
            // セッション情報をCookieに記録するため、レスポンスヘッダから保存して
            // クライアント呼び出し時にリクエストヘッダに付与する。
            string cookies;
            alias saveCookie = (res) => cookies = res
                .byKeyValue
                .map!(pair => pair.key ~ "=" ~ pair.value.rawValue)
                .join(";");

            // ログイン前に"/"をGETする
            auto res = requestHTTP("http://".text(serverAddr, "/"), (scope req) {});
            assert(res.statusCode == 200, res.toString);
            assert(res.contentType == "text/plain");
            assert(res.bodyReader.readAllUTF8() == "Please login.");
            res.dropBody();

            // ログインする
            res = requestHTTP("http://".text(serverAddr, "/login"), (scope req) {
                req.method = HTTPMethod.POST;
                req.writeFormBody(["username": "Alice"]);
            });
            assert(res.statusCode == 302, res.toString);
            // セッション情報のあるCookieを保存
            saveCookie(res.cookies);
            res.dropBody();

            // ログイン後に"/"をGETする
            res = requestHTTP("http://".text(serverAddr, "/"), (scope req) {
                // リクエストヘッダにCookieを設定
                req.headers["Cookie"] = cookies;
            });
            assert(res.statusCode == 200, res.toString);
            assert(res.contentType == "text/plain");
            assert(res.bodyReader.readAllUTF8() == "Hello, Alice.");
            res.dropBody();
        }
        catch (Throwable e)
            thrown = e;
    });

    auto exitCode = runEventLoop();
    assert(exitCode == 0, "exit code: ".text(exitCode));
    assert(!thrown, thrown.toString());
}


/++
権限

ユーザーによってアクセスできるページの範囲を変えたい、という場合のやり方について説明します。

See_Also:
- https://vibed.org/api/vibe.web.auth/
- https://github.com/vibe-d/vibe.d/blob/master/examples/web-auth/source/app.d

+/
unittest
{
    import vibe.vibe, vibe.web.auth;
    import std.conv: text;

    enum Authority
    {
        guest,
        user,
        admin,
    }
    // 権限管理の構造体
    struct AuthInfo
    {
    @safe:
        Authority authority;
        bool isAdmin() { return authority >= Authority.admin; }
        bool isUser()  { return authority >= Authority.user; }
        bool isGuest() { return authority >= Authority.guest; }
    }

    struct UserInfo
    {
        string username;
        Authority authority;
    }
    UserInfo[string] userDB = [
        "patchouli": UserInfo("patchouli", Authority.admin),
        "alice":     UserInfo("alice", Authority.user),
        "marisa":    UserInfo("marisa", Authority.guest),];

    // 権限を管理したい場合、 @requiresAuth というUDAを
    // Webインターフェースを定義するクラスに付与します。
    // また、メソッドには @noAuth / @anyAuth / @auth(Role.xxx)
    // というUDAを付与することでアクセス権限を管理します。
    @requiresAuth
    class Web
    {
    @safe:
    private:
        SessionVar!(UserInfo, "userinfo")  _userinfo;
    public:
        // 権限管理に必要な関数。
        // AuthInfoで isXxx という関数を定義していると、
        // Role.xxx というUDAが利用可能になる。
        // @auth(Role.xxx) のUDAをつけた関数は、リクエストされた
        // ときに authenticate() を呼んで AuthInfo を取得し、
        // isXxx() を呼んでtrueのときだけアクセスできるようになる。
        @noRoute
        AuthInfo authenticate(scope HTTPServerRequest req, scope HTTPServerResponse res)
        {
            return AuthInfo(_userinfo.authority);
        }

        // GET /
        // 権限不要
        @noAuth
        void index(scope HTTPServerResponse res)
        {
            res.writeBody("Index", "text/plain");
        }

        // POST /login
        // ログイン 権限不要
        @noAuth
        void postLogin(string username)
        {
            import std.algorithm;
            auto uinfo = enforceHTTP(username in userDB, HTTPStatus.forbidden, "Invalid username");
            _userinfo = *uinfo;
            redirect("/");
        }

        // GET /overview
        // 権限不要
        @anyAuth
        void getOverview(scope HTTPServerRequest req, scope HTTPServerResponse res)
        {
            res.writeBody("Overview", "text/plain");
        }

        // GET /entrance
        // user以上の権限が必要
        @auth(Role.admin | Role.user)
        void getEntrance(scope HTTPServerRequest req, scope HTTPServerResponse res)
        {
            res.writeBody("Entrance", "text/plain");
        }

        // GET /control_room
        // admin以上の権限が必要
        @auth(Role.admin)
        void getControlRoom(scope HTTPServerRequest req, scope HTTPServerResponse res)
        {
            res.writeBody("ControlRoom", "text/plain");
        }
    }

    auto port = getUnusedPort();
    auto router = new URLRouter;
    router.registerWebInterface(new Web);
    auto settings = new HTTPServerSettings;
    settings.port = port;
    settings.bindAddresses = ["localhost"];
    // ログイン認証用にセッションの準備
    settings.sessionStore = new MemorySessionStore;

    // サーバー起動
    immutable serverAddr = listenHTTP(settings, router).bindAddresses[0];

    Throwable thrown;
    runTask({
        scope (exit)
            exitEventLoop();
        try
        {
            // クライアント側の記述
            import std.algorithm: map;
            string cookies;
            alias saveCookie = (res) => cookies = res
                .byKeyValue
                .map!(pair => pair.key ~ "=" ~ pair.value.rawValue)
                .join(";");

            // 認証なしで"/"をGETする
            auto res = requestHTTP("http://".text(serverAddr, "/"), (scope req) {});
            assert(res.statusCode == 200, res.toString);
            assert(res.contentType == "text/plain");
            assert(res.bodyReader.readAllUTF8() == "Index");
            res.dropBody();

            // 認証なしでuser権限が必要なところを閲覧
            res = requestHTTP("http://".text(serverAddr, "/entrance"), (scope req) {});
            assert(res.statusCode == 403, res.toString);
            res.dropBody();

            // guest権限のユーザーでログインする
            res = requestHTTP("http://".text(serverAddr, "/login"), (scope req) {
                req.method = HTTPMethod.POST;
                req.writeFormBody(["username": "marisa"]);
            });
            assert(res.statusCode == 302, res.toString);
            saveCookie(res.cookies);
            res.dropBody();

            // guest権限で誰でも見れるところを閲覧
            res = requestHTTP("http://".text(serverAddr, "/overview"), (scope req) {
                req.headers["Cookie"] = cookies;
            });
            assert(res.statusCode == 200, res.toString);
            assert(res.contentType == "text/plain");
            assert(res.bodyReader.readAllUTF8() == "Overview");
            res.dropBody();

            // guest権限でadmin権限でしか見れないところを閲覧
            res = requestHTTP("http://".text(serverAddr, "/control_room"), (scope req) {
                req.headers["Cookie"] = cookies;
            });
            assert(res.statusCode == 403, res.toString);
            res.dropBody();

            // admin権限のユーザーでログインする
            res = requestHTTP("http://".text(serverAddr, "/login"), (scope req) {
                req.method = HTTPMethod.POST;
                req.writeFormBody(["username": "patchouli"]);
            });
            assert(res.statusCode == 302, res.toString);
            saveCookie(res.cookies);
            res.dropBody();

            // admin権限でuser以上なら見れるところを閲覧
            res = requestHTTP("http://".text(serverAddr, "/entrance"), (scope req) {
                req.headers["Cookie"] = cookies;
            });
            assert(res.statusCode == 200, res.toString);
            assert(res.contentType == "text/plain");
            assert(res.bodyReader.readAllUTF8() == "Entrance");
            res.dropBody();

            // admin権限でadmin権限でしか見れないところを閲覧
            res = requestHTTP("http://".text(serverAddr, "/control_room"), (scope req) {
                req.headers["Cookie"] = cookies;
            });
            assert(res.statusCode == 200, res.toString);
            assert(res.contentType == "text/plain");
            assert(res.bodyReader.readAllUTF8() == "ControlRoom");
            saveCookie(res.cookies);
            res.dropBody();
        }
        catch (Throwable e)
            thrown = e;
    });

    auto exitCode = runEventLoop();
    assert(exitCode == 0, "exit code: ".text(exitCode));
    assert(!thrown, thrown.toString());
}

/++
RESTで認証

Twitter等のOAuthのような、トークンを用いた認証を行う例です。

RESTでは、セッション情報が使用できません。(そもそも原則としてRESTにはステートレスであることが求められます)
そのため、REST APIとともにアクセス制限やユーザー情報等を扱う場合は、
ここでのアクセストークンのような固有の情報と、
そのトークンの所有者であることを証明する秘密情報を使った認証を行うのがよいでしょう。

今回のアクセストークンを用いたリソースアクセスは以下の手順で行います。

1. リクエストトークンを作成
2. ログイン
3. ログイン済みのユーザーでリクエストトークンからPINの作成
4. リクエストトークンとPINからアクセストークンの作成
5. アクセストークンを用いてリソースにアクセス

Attention:
サンプルコードは適当に作成したものですので、セキュリティ的に十分優れているとは言えません。
トークンの生成方法を工夫したり、nonceを加えてリプレイ攻撃耐性を上げたりと、工夫が必要です。
+/
unittest
{
    import vibe.vibe;
    import std.digest.sha: sha1Of, toHexString;
    import std.conv: text;
    import std.datetime: SysTime, Clock;

    // 未使用ポート取得
    auto port = getUnusedPort();

    // トークン
    struct Token
    {
        string key;
        string secret;
    }
    // 新しいトークンを作成
    Token createNewToken()
    {
        import std.uuid;
        return Token(randomUUID().toString, randomUUID().toString);
    }

    // ユーザー情報
    struct UserInfo
    {
        string username;
        string password;
        Token  accessToken;
        string data;
    }
    // ユーザー情報のデータベース
    UserInfo[] userDataList = [
        UserInfo("hoge", sha1Of("foo").toHexString().idup, Token.init, "あいうえお"),
        UserInfo("fuga", sha1Of("bar").toHexString().idup, Token.init, "かきくけこ"),
        UserInfo("piyo", sha1Of("baz").toHexString().idup, Token.init, "さしすせそ")];
    // アクセストークンからユーザー情報の添え字を引くAA
    size_t[string] userNameMap;
    // 発行されたリクエストトークン
    struct RequestToken
    {
        Token   token;
        string  username;
        string  pin;
        SysTime expire;
    }
    RequestToken[] requestTokens;

    // シグネチャを計算する
    string calcSignature(string method, string requri, Token accessToken, string[string] params) @safe
    {
        import std.uri: encodeComponent;
        import std.digest.hmac, std.digest.sha, std.digest;
        import std.algorithm: sort, map;
        import std.string: representation;
        import std.array: array, join;
        auto query = params.byKey.array.sort.map!(k => k ~ "=" ~ params[k]).join("&");
        auto key = accessToken.secret.encodeComponent();
        auto hmac = HMAC!SHA1(key.representation);
        hmac.put(method.representation);
        hmac.put(requri.representation);
        hmac.put(query.representation);
        return hmac.finish().toHexString().idup;
    }
    // 時間切れのリクエストトークン削除
    void removeExpiredRequestTokens(SysTime now = Clock.currTime)
    {
        import std.algorithm: remove;
        requestTokens = requestTokens.remove!(a => a.expire < now);
    }

    // REST API用のインターフェースを作る
    @path("/api")
    interface MyApi
    {
        // GET /api/create_request_token
        Token getCreateRequestToken() @safe;
        // GET /api/create_access_token?pin=...&reqkey=...&sign=...
        Token getCreateAccessToken(
            @viaQuery("pin")      string pin,
            @viaQuery("reqkey")   string reqkey,
            @viaQuery("sign")     string sign) @safe;
        // GET /api/resource?accesskey=...&sign=...
        string getResource(
            @viaQuery("accesskey") string accesskey,
            @viaQuery("sign")      string sign) @safe;
    }

    // REST APIのインターフェースを実装する
    class MyApiImpliment: MyApi
    {

        // ➀ リクエストトークンを作成
        // GET /api/create_request_token
        Token getCreateRequestToken() @safe
        {
            import std.datetime: seconds;
            auto newToken = createNewToken();
            auto now = Clock.currTime();
            removeExpiredRequestTokens(now);
            requestTokens ~= RequestToken(newToken, null, null, now + 300.seconds);
            return newToken;
        }
        // ➃ リクエストトークンとPINからアクセストークンの作成
        // GET /api/create_access_token?username=...&pin=...&reqkey=...&sign=...
        Token getCreateAccessToken(
            @viaQuery("pin")      string pin,
            @viaQuery("reqkey")   string reqkey,
            @viaQuery("sign")     string sign) @safe
        {
            import std.algorithm: find, countUntil;
            import std.array: front, empty;
            import std.random: uniform;
            removeExpiredRequestTokens();
            // PINが記録されていてユーザーに承認されたリクエストトークンを探す
            auto foundToken = requestTokens.find!(a => a.token.key == reqkey && a.pin == pin)();
            enforceHTTP(!foundToken.empty, HTTPStatus.forbidden, "Invalid request token.");
            // サーバーが持っているリクエストシークレットと、
            // クライアントが持っているリクエストシークレットを照合
            auto mySign = calcSignature("GET", "/api/create_access_token", foundToken.front.token,
                ["pin": pin.to!string]);
            enforceHTTP(mySign == sign, HTTPStatus.forbidden, "Invalid request token.");
            auto idx = userDataList.countUntil!(a => a.username == foundToken.front.username);
            enforceHTTP(idx != -1, HTTPStatus.forbidden, "Invalid user.");
            userDataList[idx].accessToken = createNewToken();
            userNameMap[userDataList[idx].accessToken.key] = idx;
            return userDataList[idx].accessToken;
        }

        // ➄ アクセストークンを用いてリソースにアクセス
        // GET /api/resource?accesskey=...&sign=...
        string getResource(
            @viaQuery("accesskey") string accesskey,
            @viaQuery("sign")      string sign) @safe
        {
            auto idx = enforceHTTP(accesskey in userNameMap, HTTPStatus.forbidden, "Invalid access token.");
            // サーバーが持っているアクセスシークレットと、
            // クライアントが持っているアクセスシークレットを照合
            auto mySign = calcSignature("GET", "/api/resource", userDataList[*idx].accessToken, null);
            enforceHTTP(mySign == sign, HTTPStatus.forbidden, "Invalid access token.");
            return userDataList[*idx].data;
        }
    }

    // ユーザー認証用のWebインターフェース
    class Web
    {
    private:
        SessionVar!(string, "username") _username;
    public:
        // ログイン / PIN発行 & ログアウト
        // GET /
        void index(scope HTTPServerResponse res)
        {
            import diet.html;
            import std.array: appender;
            auto contents = appender!string;
            string username = _username;
            bool authenticated = username.length > 0;
            // ログイン画面
            contents.compileHTMLDietString!(`
                doctype 5
                html
                    head
                        title Welcome
                    body
                        - if (authenticated)
                            h1 Welcome #{username}
                            form(action="create_pin", method="POST")
                                p Request key:
                                    input(type="text", name="reqkey")
                                button(type="submit") Submit
                            form(action="logout", method="POST")
                                button(type="submit") Log out
                        - else
                            h1 Welcome
                            h2 Log in
                            form(action="login", method="POST")
                                p User name:
                                    input(type="text", name="username")
                                p Password:
                                    input(type="password", name="password")
                                button(type="submit") Log in
            `.chompPrefix("\n").outdent, authenticated, username);
            res.writeBody(contents.data, "text/html");
        }
        // ➁ ログイン
        // POST /login
        void postLogin(string username, string password)
        {
            import std.algorithm: find;
            // パスワード認証を行う
            auto foundUser = userDataList.find!(a
                => a.username == username
                && a.password == sha1Of(password).toHexString())();
            enforceHTTP(!foundUser.empty, HTTPStatus.forbidden, "Invalid user name or password.");
            // 認証OKならユーザー名をセッションに記録
            _username = username;
            redirect("/");
        }
        // ログアウト
        // POST /logout
        void postLogout()
        {
            _username = null;
            terminateSession();
            redirect("/");
        }
        // ➂ ログイン済みのユーザーでリクエストトークンからPINの作成
        // POST /create_pin
        void postCreatePin(string reqkey, scope HTTPServerResponse res)
        {
            import std.algorithm: find;
            import std.format: format;
            import std.array: front, empty, popFront;
            import std.random: uniform;
            // ユーザーがログインしているか確認
            string username = _username;
            auto foundUser = userDataList.find!(a => a.username == username)();
            enforceHTTP(!foundUser.empty, HTTPStatus.forbidden, "Invalid user.");
            // トークンが有効か確認
            removeExpiredRequestTokens();
            auto foundKey = requestTokens.find!(a => a.token.key == reqkey)();
            enforceHTTP(!foundKey.empty, HTTPStatus.forbidden, "Invalid request key.");
            // ログインしていて、トークンも有効ならPINを作成し、
            // リクエストトークンにユーザーとPINを紐づける
            auto pin = format("%06d", uniform(0, 1000_000));
            foundKey.front.pin = pin;
            foundKey.front.username = username;
            // クライアントにPINを返す
            res.writeBody(pin, "text/plain");
        }
    }

    auto router = new URLRouter;
    // URLRouterへ登録
    router.registerWebInterface(new Web);
    router.registerRestInterface(new MyApiImpliment);
    auto settings = new HTTPServerSettings;
    settings.port = port;
    settings.bindAddresses = ["localhost"];
    // ログイン認証用にセッションの準備
    settings.sessionStore = new MemorySessionStore;
    // サーバー起動
    immutable serverAddr = listenHTTP(settings, router).bindAddresses[0];

    Throwable thrown;
    runTask({
        scope (exit)
            exitEventLoop();
        try
        {
            import std.algorithm: map;
            import std.uri: encodeComponent;
            string cookies;
            alias saveCookie = (res) => cookies = res
                .byKeyValue
                .map!(pair => pair.key ~ "=" ~ pair.value.rawValue)
                .join(";");
            string username = "hoge";
            // クライアント側の記述
            auto restClient = new RestInterfaceClient!MyApi("http://".text(serverAddr));
            auto webClient = connectHTTP("localhost", port);

            // ➀ リクエストトークンを作成
            auto requestToken = restClient.getCreateRequestToken();

            // ➁ ログイン
            auto res = requestHTTP("http://".text(serverAddr, "/login"), (scope req) {
                req.method = HTTPMethod.POST;
                req.writeFormBody(["username": username, "password": "foo"]);
            });
            saveCookie(res.cookies);
            res.dropBody();

            // ➂ ログイン済みのユーザーでリクエストトークンからPINの作成
            res = requestHTTP("http://".text(serverAddr, "/create_pin"), (scope req) {
                req.method = HTTPMethod.POST;
                req.headers["Cookie"] = cookies;
                req.writeFormBody(["reqkey": requestToken.key]);
            });
            saveCookie(res.cookies);
            auto pin = res.bodyReader.readAllUTF8();
            res.dropBody();

            // ➃ リクエストトークンとPINからアクセストークンの作成
            auto sign = calcSignature("GET", "/api/create_access_token", requestToken,
                ["pin": pin]);
            auto accessToken = restClient.getCreateAccessToken(pin, requestToken.key, sign);

            // ➄ アクセストークンを用いてリソースにアクセス
            sign = calcSignature("GET", "/api/resource", accessToken, null);
            auto resource = restClient.getResource(accessToken.key, sign);
            assert(resource == "あいうえお");
         }
        catch (Throwable e)
            thrown = e;
    });

    auto exitCode = runEventLoop();
    assert(exitCode == 0, "exit code: ".text(exitCode));
    assert(!thrown, thrown.toString());
}
