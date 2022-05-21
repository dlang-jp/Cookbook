/++
OpenSSLの使用例

OpenSSLはベースがCの暗号化ライブラリです。インターフェースもそのままC言語のAPIを利用します。 $(BR)
[Deimos](https://github.com/D-Programming-Deimos)という公式のC言語のバインディングプロジェクトがあり、OpenSSLもその対象になっています。

OpenSSLのライセンスはバージョン3.0.0未満の場合、OpenSSL LicenseとSSLeay Licenseの両方のライセンス下で公開されています。3.0.0以降の場合はApache License Version 2.0のライセンスです。$(BR)
ここで紹介するDeimos版の対応バージョンは現在3.0.0未満ですので、OpenSSL LicenseとSSLeay Licenseということになります。

## ドキュメント
    - 公式サイト: https://www.openssl.org
    - APIドキュメント: https://www.openssl.org/docs/man1.1.1/man7/
    - リポジトリ(Deimos): https://github.com/D-Programming-Deimos/openssl
    - dubパッケージ(Deimos): https://code.dlang.org/packages/openssl

Source: $(LINK_TO_SRC thirdparty/openssl/source/openssl_usage/_example.d)
+/
module openssl_usage.example;


/++
AES-128-CBCによる共通鍵暗号化/復号の例です。

See_Also:
    - https://www.openssl.org/docs/man1.1.1/man3/EVP_CIPHER_CTX_new.html
    - https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57Pt3r1.pdf P13
    - https://www.ipa.go.jp/security/ipg/documents/ipa-cryptrec-gl-3001-3.0.1.pdf P26, P37
+/
unittest
{
    import std.exception: enforce, assumeUnique;
    import deimos.openssl.evp;

    // 暗号化
    immutable(ubyte)[] encryptAES128(in ubyte[] src, in ubyte[128/8] key, in ubyte[16] iv)
    {
        // 暗号化のコンテキスト作成・破棄
        auto encctx = EVP_CIPHER_CTX_new().enforce("Cannot cretae OpenSSL cipher context.");
        scope (exit)
            encctx.EVP_CIPHER_CTX_free();

        // 初期化
        encctx.EVP_EncryptInit_ex(EVP_aes_128_cbc(), null, key.ptr, iv.ptr)
            .enforce("Cannot initialize OpenSSL cipher context.");

        // 暗号化されたデータの格納先として、十分な量のバッファを用意。
        // 暗号化のロジックによって異なる。
        // AES128だったら元のデータよりブロックサイズ分の16バイト大きければ十分格納できる。
        ubyte[] encrypted = new ubyte[src.length + 16];

        // 暗号化
        // ここでは一回で暗号化を行っているが、分割することもできる。
        int encryptedLen;
        int padLen;
        encctx.EVP_EncryptUpdate(encrypted.ptr, &encryptedLen, src.ptr, cast(int)src.length)
            .enforce("Cannot encrypt update OpenSSL cipher context.");
        // 暗号化完了
        encctx.EVP_EncryptFinal_ex(encrypted.ptr + encryptedLen, &padLen)
            .enforce("Cannot finalize OpenSSL cipher context.");

        return encrypted[0 .. encryptedLen + padLen].assumeUnique();
    }

    // 複合
    immutable(ubyte)[] decryptAES128(in ubyte[] src, in ubyte[128/8] key, in ubyte[16] iv)
    {
        // 暗号化のコンテキスト作成・破棄
        auto decctx = EVP_CIPHER_CTX_new().enforce("Cannot cretae OpenSSL cipher context.");
        scope (exit)
            decctx.EVP_CIPHER_CTX_free();

        // 初期化・終了処理
        decctx.EVP_DecryptInit_ex(EVP_aes_128_cbc(), null, key.ptr, iv.ptr)
            .enforce("Cannot initialize OpenSSL cipher context.");

        // 複合されたデータの格納先として、十分な量のバッファを用意。
        // 暗号化のロジックによって異なる。
        // AES128だったら元のデータよりブロックサイズ分の16バイト大きければ十分格納できる。
        ubyte[] decrypted = new ubyte[src.length + 16];

        // 複合
        // ここでは一回で複合を行っているが、分割することもできる。
        int decryptedLen;
        int padLen;
        decctx.EVP_DecryptUpdate(decrypted.ptr, &decryptedLen, src.ptr, cast(int)src.length)
            .enforce("Cannot encrypt update OpenSSL cipher context.");
        // 複合完了
        decctx.EVP_DecryptFinal_ex(decrypted.ptr + decryptedLen, &padLen)
            .enforce("Cannot finalize OpenSSL cipher context.");

        return decrypted[0 .. decryptedLen + padLen].assumeUnique();
    }

    import std.conv: hexString;
    import std.string: representation;
    // ここでは以下のデータを暗号化して、複合します。
    static immutable ubyte[] sourceData = "あいうえお"c.representation;
    // 鍵とIVには以下を使用。
    // 鍵は128bit(16バイト), IVはブロックサイズの16バイト
    static immutable ubyte[128/8] key = cast(ubyte[128/8])hexString!"9F86D081884C7D659A2FEAA0C55AD015";
    static immutable ubyte[16]    iv  = cast(ubyte[16])hexString!"A3BF4F1B2B0B822CD15D6C15B0F00A08";
    // 暗号化
    auto encryptedData = encryptAES128(sourceData, key, iv);
    // 複合
    auto decryptedData = decryptAES128(encryptedData, key, iv);
    // 確認
    assert(decryptedData == sourceData);
}
