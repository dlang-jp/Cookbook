/++
Botanの使用例

BotanはベースがC++の暗号化ライブラリです。そのためD言語っぽくないインターフェースが多々見受けられます。 $(BR)
Botanのライセンスは2条項BSDライセンスで、ApacheライセンスのOpenSSLとあまり変わらない条件になっています。

## ドキュメント
    - APIドキュメント: http://etcimon.github.io/botan/index.html
    - Wiki: https://github.com/etcimon/botan/wiki
    - C++のほうの公式: https://botan.randombit.net/
+/
module botan_usage.example;

/++
AES-128-CBCによる共通鍵暗号化/復号の例です。

getCipherのファクトリ関数で「フィルター」として変換器を作成します。 $(BR)
Pipeはストリームのように、さまざまなロジックを組み合わせることができます。 $(BR)
例えばBase64デコード→AES-128-CBCでエンコード→AES-256-CBCでエンコード→Base64エンコードする…といったことも可能です。

See_Also:
    - https://github.com/etcimon/botan/wiki/Pipe-and-Filter-Message-Processing
    - https://github.com/etcimon/botan#recommended-algorithms
    - https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57Pt3r1.pdf P13
    - https://www.ipa.go.jp/security/ipg/documents/ipa-cryptrec-gl-3001-3.0.1.pdf P26, P37
+/
unittest
{
    // importはbotan.allでだいたいのものがimportできます。
    // (allという割に全部じゃないので、たまにこれだけだとサンプルが動きません)
    // そういう時はgitリポジトリを丸ごとcloneしてgrepかけるのが捜しやすいです(力技)。
    import botan.all;
    // AES共通鍵と初期化ベクトル(IV)の生成
    auto key = SymmetricKey("9F86D081884C7D659A2FEAA0C55AD015");
    auto iv = InitializationVector("A3BF4F1B2B0B822CD15D6C15B0F00A08");

    // 暗号化
    auto encoder = Pipe(getCipher("AES-128/CBC", key, iv, ENCRYPTION));
    encoder.startMsg();
    encoder.write("TEST");
    encoder.endMsg();
    auto encrypted = encoder.readAll();

    // 復号
    auto decoder = Pipe(getCipher("AES-128/CBC", key, iv, DECRYPTION));
    decoder.startMsg();
    decoder.write(encrypted);
    decoder.endMsg();
    auto decrypted = decoder.readAll();

    // 元のデータに復元される
    assert(cast(const char[])decrypted[] == "TEST");
}


/++
RSAによる公開鍵での暗号化と秘密鍵での復号

See_Also:
    - https://github.com/etcimon/botan/wiki/Public-Key-Cryptography
    - https://github.com/etcimon/botan/blob/master/examples/pubkey/source/app.d
    - https://github.com/etcimon/botan#recommended-algorithms
    - https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57Pt3r1.pdf P13
    - https://www.ipa.go.jp/security/ipg/documents/ipa-cryptrec-gl-3001-3.0.1.pdf P26, P37
+/
unittest
{
    import botan.all;
    import botan.pubkey.pubkey: PKEncryptorEME, PKDecryptorEME;
    import botan.pubkey.algo.rsa: RSAPrivateKey, RSAPublicKey;

    // 乱数機
    auto rng = new AutoSeededRNG;
    // 新しいRSA秘密鍵/RSA公開鍵の生成
    auto privateKey = RSAPrivateKey(rng, 2048);
    auto publicKey = RSAPublicKey(privateKey);
    // 暗号化と復号を行うオブジェクトの生成
    auto enc = new PKEncryptorEME(publicKey, "EME-PKCS1-v1_5");
    auto dec = new PKDecryptorEME(privateKey, "EME-PKCS1-v1_5");

    // 暗号化と復号
    auto data = "ほげほげ";
    auto buf = Vector!ubyte(data);
    auto encrypted = enc.encrypt(buf, rng);
    auto decrypted = dec.decrypt(encrypted);

    // 復号できてるか確認
    assert(cast(const char[])decrypted[] == data);

    // PEM形式に"password"付きで変換＆"password"を使って読み込み
    import botan.pubkey.pkcs8: PEM_encode, loadKey;
    import botan.filters.data_src: DataSource, DataSourceMemory;
    auto privateKeyPEM = PEM_encode(privateKey, rng, "password");
    auto privateKeyPEMSrc = cast(DataSource)DataSourceMemory(privateKeyPEM);
    auto publicKeyLoaded = loadKey(privateKeyPEMSrc, rng, "password");
    auto dec2 = new PKDecryptorEME(publicKeyLoaded, "EME-PKCS1-v1_5");

    // PEMに一度変換したものを再読み込みしたキーで復号
    auto decrypted2 = dec2.decrypt(encrypted);
    // PEMに変換しても鍵が損なわれていないことを確認
    assert(decrypted[] == decrypted2[]);
}


/++
RSAによる秘密鍵での署名と公開鍵での検証

See_Also:
    - https://github.com/etcimon/botan/wiki/Public-Key-Cryptography#signatures
    - https://github.com/etcimon/botan#recommended-algorithms
    - https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57Pt3r1.pdf P13
    - https://www.ipa.go.jp/security/ipg/documents/ipa-cryptrec-gl-3001-3.0.1.pdf P26, P37
+/
unittest
{
    import botan.all;
    import botan.pubkey.pubkey: PKSigner, PKVerifier;
    import botan.pubkey.algo.rsa: RSAPrivateKey, RSAPublicKey;

    // 乱数機
    auto rng = new AutoSeededRNG;
    // 新しいRSA秘密鍵/RSA公開鍵の生成
    auto privateKey = RSAPrivateKey(rng, 2048);
    auto publicKey  = RSAPublicKey(privateKey);

    // RSA秘密鍵による署名/RSA公開鍵による検証を行うオブジェクトの生成
    auto signer   = PKSigner(privateKey, "EMSA4(SHA-256)");
    auto verifier = PKVerifier(publicKey, "EMSA4(SHA-256)");

    // 署名と検証
    auto data = "ほげほげ";
    auto buf = Vector!ubyte(data);
    auto signature = signer.signMessage(buf, rng);
    auto result    = verifier.verifyMessage(buf, signature);

    // 検証結果確認
    assert(result);
}
