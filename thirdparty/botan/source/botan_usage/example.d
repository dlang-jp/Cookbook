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

/++
証明書の作成

以下の例では、ルートCA証明書と、それにより署名された中間CA証明書、中間CA証明書で署名したサーバー証明書、
中間CA証明書で署名したクライアント証明書をそれぞれ作成します。

- botan.pubkey.algo.rsa.RSAPrivateKey;
- botan.cert.x509.x509self.createCertReq

1. ルートCA証明書の作成
   1. 秘密鍵(root)の作成$(BR)
      OpenSSLだと
      ```
      openssl genrsa -out private-root.key 2048
      ```
   2. 秘密鍵(root)を使用して証明書要求(CSR)(root)の作成$(BR)
      OpenSSLだと
      ```
      openssl req -new -key private-root.key -out public-root.ca.pem.csr
      ```
   3. 秘密鍵(root)と証明書要求(root)を使用してルートCA証明書(root)作成$(BR)
      OpenSSLだと
      ```
      openssl x509 -req -days 3650 -signkey private-root.key -in public-root.ca.pem.csr -out public-root.ca.pem.crt
      ```
      なお、self-signedな証明書(=オレオレのルート証明書)であれば、2の工程をすっ飛ばし、以下のコマンドで秘密鍵(root)を使用してルートCA証明書(root)を直接生成可能。
      ```
      openssl req -x509 -new -key private-root.key -out public-root.ca.pem.crt
      ```
2. 中間CA証明書の作成
   1. 秘密鍵(inter)の作成
      OpenSSLだと
      ```
      openssl genrsa -out private-inter.key 2048
      ```
   2. 秘密鍵(inter)を使用して証明書要求(CSR)(inter)の作成$(BR)
      OpenSSLだと
      ```
      openssl req -new -key private-inter.key -out public-inter.ca.pem.csr
      ```
   3. 秘密鍵(root)とルートCA証明書(root)と証明書要求(inter)を使用して中間CA証明書(inter)作成$(BR)
      OpenSSLだと
      ```
      openssl ca -keyfile private-root.key -cert public-root.ca.pem.crt -in public-inter.ca.pem.csr -out public-inter.ca.pem.crt
      ```
3. サーバー証明書の作成
   1. 秘密鍵(server)の作成$(BR)
      OpenSSLだと
      ```
      openssl genrsa -out private-server.key 2048
      ```
   2. 秘密鍵(server)を使用して証明書要求(CSR)(server)の作成$(BR)
      OpenSSLだと
      ```
      openssl req -new -key private-server.key -out public-server.ca.pem.csr
      ```
   3. 秘密鍵(inter)と中間CA証明書(inter)と証明書要求(server)を使用してサーバー証明書(server)作成$(BR)
      OpenSSLだと
      ```
      openssl ca -keyfile private-inter.key -cert public-inter.ca.pem.crt -in public-server.ca.pem.csr -out public-server.ca.pem.crt
      ```
4. クライアント証明書の作成
   1. 秘密鍵(client)の作成
   2. 秘密鍵(client)を使用して証明書要求(CSR)(client)の作成
   3. 秘密鍵(inter)と中間CA証明書(inter)と証明書要求(client)を使用してクライアント証明書(client)作成
5. サーバー証明書(server)を検証
   OpenSSLだと
   ```
   openssl verify -CApath cacert public.server.pem.crt
   ```
6. クライアント証明書(client)を検証
   OpenSSLだと
   ```
   openssl verify -CApath cacert public.client.pem.crt
   ```

See_Also:
    - https://github.com/etcimon/botan/wiki/X.509-Certificates-and-CRLs

+/
unittest
{
import std;
    import core.time;
    import botan.all;
    import botan.pubkey.algo.rsa: RSAPrivateKey, PEM_encode;
    import botan.cert.x509.key_constraint: KeyConstraints;
    import botan.cert.x509.x509self: X509CertOptions, createCertReq, createSelfSignedCert;
    import botan.cert.x509.x509cert: X509Certificate;
    import botan.cert.x509.x509_ca: X509CA;
    import botan.cert.x509.x509path: x509PathValidate, PathValidationRestrictions, PathValidationResult;
    import botan.cert.x509.certstor: CertificateStore, CertificateStoreInMemory;
    
    // 乱数機
    auto rng = new AutoSeededRNG;
    
    // 1. ルートCA自己証明書作成
    // 1-1 秘密鍵(root)の作成
    auto rootPrivateKey = RSAPrivateKey(rng, 2048);
    // 1-2 秘密鍵(root)を使用して証明書要求(CSR)(root)の作成
    auto rootCertOpts = X509CertOptions("", 3650.days);
    with (rootCertOpts)
    {
        common_name  = "dlang-jp-root CA";
        dns          = "dlang-jp.github.io";
        country      = "JP";
        organization = "dlang-jp";
        email        = "dlang-jp@example.com";
        constraints  = KeyConstraints.CRL_SIGN | KeyConstraints.KEY_CERT_SIGN;
        // 下位に中間CAとエンドエンティティ(サーバー/クライアント)が存在するため、2
        CAKey(2);
    }
    auto rootCsr = createCertReq(rootCertOpts, rootPrivateKey, "SHA-256", rng);
    auto rootCsrPEM = rootCsr.PEM_encode();
    // 1-3 秘密鍵(root)と証明書要求(root)を使用してルートCA証明書(root)作成
    //     ルートCA証明書は絶対self-signed(オレオレ証明書)なので、要求とか実は不要
    //     多分がんばれば証明書要求(CSR)からでも発行できるが、
    //     createSelfSignedCert 相当の関数を自分で記載する必要がある。
    auto rootCert = createSelfSignedCert(rootCertOpts, rootPrivateKey, "SHA-256", rng);
    string rootCertPEM = rootCert.PEM_encode();
    
    // ルート認証局設立
    auto rootCA = X509CA(rootCert, rootPrivateKey, "SHA-256");
    
    // 2. 中間CA証明書作成
    // 2-1 秘密鍵(inter)の作成
    auto interPrivateKey = RSAPrivateKey(rng, 2048);
    // 2-2 秘密鍵(inter)を使用して証明書要求(CSR)(inter)の作成
    auto interCertOpts = X509CertOptions("", 3650.days);
    with (interCertOpts)
    {
        common_name  = "dlang-jp-inter CA";
        dns          = "inter.dlang-jp.github.io";
        country      = "JP";
        organization = "dlang-jp";
        email        = "dlang-jp@example.com";
        constraints  = KeyConstraints.CRL_SIGN | KeyConstraints.KEY_CERT_SIGN;
        CAKey(1); // 下位にエンドエンティティ(サーバー/クライアント)が存在するため、1
    }
    auto interCsr = createCertReq(interCertOpts, interPrivateKey, "SHA-256", rng);
    auto interCsrPEM = interCsr.PEM_encode();
    // 2-3 秘密鍵(root)とルートCA証明書(root)と証明書要求(inter)を使用して中間CA証明書(inter)作成
    auto interCert = rootCA.signRequest(interCsr, rng, interCertOpts.start, interCertOpts.end);
    string interCertPEM = interCert.PEM_encode();
    
    // 中間認証局設立
    auto interCA = X509CA(interCert, interPrivateKey, "SHA-256");
    
    // 3. サーバー証明書作成
    // 3-1 秘密鍵(server)の作成
    auto serverPrivateKey = RSAPrivateKey(rng, 2048);
    // 3-2 秘密鍵(server)を使用して証明書要求(CSR)(server)の作成
    auto serverCertOpts = X509CertOptions("", 3650.days);
    with (serverCertOpts)
    {
        common_name  = "dlang-jp server";
        dns          = "server.dlang-jp.github.io";
        country      = "JP";
        organization = "dlang-jp";
        email        = "dlang-jp@example.com";
        constraints  = KeyConstraints.DIGITAL_SIGNATURE | KeyConstraints.KEY_ENCIPHERMENT;
        addExConstraint("PKIX.ServerAuth");
    }
    auto serverCsr = createCertReq(serverCertOpts, serverPrivateKey, "SHA-256", rng);
    auto serverCsrPEM = serverCsr.PEM_encode();
    // 3-3 秘密鍵(inter)と中間CA証明書(inter)と証明書要求(server)を使用してサーバー証明書(server)作成
    auto serverCert = interCA.signRequest(serverCsr, rng, serverCertOpts.start, serverCertOpts.end);
    string serverCertPEM = serverCert.PEM_encode();
    
    // 4. クライアント証明書作成
    // 4-1 秘密鍵(client)の作成
    auto clientPrivateKey = RSAPrivateKey(rng, 2048);
    // 4-2 秘密鍵(client)を使用して証明書要求(CSR)(client)の作成
    auto clientCertOpts = X509CertOptions("", 3650.days);
    with (clientCertOpts)
    {
        common_name  = "dlang-jp userA";
        country      = "JP";
        organization = "dlang-jp";
        email        = "userA@dlang-jp.example.com";
        constraints  = KeyConstraints.DIGITAL_SIGNATURE | KeyConstraints.KEY_ENCIPHERMENT;
        addExConstraint("PKIX.ClientAuth");
        addExConstraint("PKIX.CodeSigning");
        addExConstraint("PKIX.EmailProtection");
        addExConstraint("PKIX.TimeStamping");
    }
    auto clientCsr = createCertReq(clientCertOpts, clientPrivateKey, "SHA-256", rng);
    auto clientCsrPEM = clientCsr.PEM_encode();
    // 4-3 秘密鍵(server)とサーバー証明書(server)と証明書要求(client)を使用してクライアント証明書(client)作成
    auto clientCert = interCA.signRequest(clientCsr, rng, clientCertOpts.start, clientCertOpts.end);
    string clientCertPEM = clientCert.PEM_encode();
    
    // 証明書ストアを作成
    auto store = new CertificateStoreInMemory();
    store.addCertificate(rootCert);
    store.addCertificate(interCert);
    
    // 5. サーバー証明書(server)を検証
    auto serverCertValidation = x509PathValidate(serverCert, PathValidationRestrictions(false), store);
    assert(serverCertValidation.successfulValidation);
    
    // 6. クライアント証明書(client)を検証
    auto store2 = new CertificateStoreInMemory();
    auto clientCertValidation = x509PathValidate(clientCert, PathValidationRestrictions(false), store);
    assert(clientCertValidation.successfulValidation);
}
