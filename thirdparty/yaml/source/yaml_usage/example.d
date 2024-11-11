/++
YAMLの使用例

YAML形式のデータを取り扱う方法について、主に `mir-ion` というライブラリの使い方をまとめます。
また `mir-ion` の大部分が `mir-core` や `mir-algorithm` などの関連ライブラリに依存しているため、それも含めて説明します。

## mir-ion 公式リポジトリ
https://github.com/libmir/mir-ion

## 主な内容
- YAMLのデシリアライズ
    - 構造体への変換
    - 動的なデシリアライズ
    - ファイルからのデシリアライズ
- YAMLのシリアライズ
    - 構造体からの変換
    - 様々な型の取り扱い（日付、時間、時間間隔など）
    - シリアライズオプションの指定
        - ブロックスタイルとフロースタイルでのYAMLのシリアライズ
        - インデントの指定
    - ユーザー定義型におけるカスタマイズ
        - フィールドの除外（既定値の除外）
        - フィールド名の変更
        - 必須フィールドの指定（エラー）
- YamlAlgebraicと関連型の利用
    - 構築方法およびデータの取り扱い
    - メタプログラミングによる簡便なデータ構築

TODO:
- バリデーション

Source: $(LINK_TO_SRC thirdparty/yaml/source/yaml_usage/_example.d)
+/
module yaml_usage.example;

/++
YAML 形式の文字列を `Person` 構造体にデシリアライズする例です。

`deserializeYaml` 関数を使用して、YAML データを静的な型に変換し、各フィールドが正しくマッピングされていることを検証します。

ポイント:
- デシリアライズには `deserializeYaml` 関数を使用する
- 構造体を定義して、`deserializeYaml` 関数のテンプレート引数に指定すると、YAML データが構造体に変換される
+/
unittest
{
    // デシリアライズに必要な関数は mir-ion の mir.deser.yaml モジュールにあります。
    import mir.deser.yaml : deserializeYaml;

    // 解析するYAML形式の文字列
    string yaml = `
        name: "Alice"
        age: 20
        height: 160.5
        isStudent: true
    `;

    // マッピングする構造体
    struct Person
    {
        string name;
        int age;
        double height;
        bool isStudent;
    }

    // デシリアライズおよび検証
    Person person = deserializeYaml!Person(yaml);

    assert(person.name == "Alice");
    assert(person.age == 20);
    assert(person.height == 160.5);
    assert(person.isStudent == true);
}

/++
`YamlMap` を使用してオブジェクト型（キー・バリュー）のデータを動的にデシリアライズする例です。

`deserializeYaml` 関数を使用してYAML データを `YamlMap` に変換し、その後、キーを指定してデータを取得します。

ポイント:
- オブジェクト型（キー・バリュー）を元にした動的なデシリアライズには `YamlMap` を使用する
- `YamlMap` は `mir.algebraic_alias.yaml` モジュールで提供される
+/
unittest
{
    // デシリアライズに必要な関数は mir-ion の mir.deser.yaml モジュールにあります。
    import mir.deser.yaml : deserializeYaml;
    import mir.algebraic_alias.yaml : YamlMap;

    // 解析するYAML形式の文字列
    string yaml = `
        name: "Alice"
        age: 20
        height: 160.5
        isStudent: true
    `;

    // デシリアライズおよび検証
    YamlMap json = deserializeYaml!YamlMap(yaml);

    assert(json["name"] == "Alice");
    assert(json["age"] == 20);
    assert(json["height"] == 160.5);
    assert(json["isStudent"] == true);
}

/++
`YamlAlgebraic` と `YamlMap` を利用して、複雑なYAML文字列を動的にデシリアライズする例です。

`match` 関数を用いて異なる型を処理し、データの正確性を検証します。

ポイント:
- 動的なデシリアライズでは、`YamlAlgebraic` または `YamlMap` を使用する
- `YamlAlgebraic` と `YamlMap` は `mir.algebraic_alias.yaml` モジュールで提供される
- `match` 関数を使って型を分岐しながら判定する
+/
unittest
{
    import mir.deser.yaml : deserializeYaml;
    import mir.algebraic_alias.yaml : YamlAlgebraic, YamlMap;

    // 解析するYAML形式の文字列
    string yaml = `
        type: "VALUES"
        obj: null
        flag: true
        count: 3
    `;

    // デシリアライズおよび検証
    YamlAlgebraic json = deserializeYaml!YamlAlgebraic(yaml);

    // YamlAlgebraicは、mir-coreで提供されるAlgebraic型に基づく厳密な代数的データ型です。
    // そのため、match関数を使って型を分岐しながら判定する必要があります。一度YamlMapにすると扱いが楽です。
    import mir.algebraic : match;

    // dfmt off
    assert(json.match!(
        (YamlMap m) {
            return m["type"] == "VALUES" && m["obj"] == null && m["flag"] && m["count"] == 3;
        },
        _ => false
    ));
    // dfmt on

    // get関数を使うと、YamlMapに変換できます。
    YamlMap map = json.get!YamlMap();
    assert(map["type"] == "VALUES");
    assert(map["obj"] == null);
    assert(map["flag"] == true);
    assert(map["count"] == 3);

    // .object でも同じ結果が得られます。
    YamlMap map2 = json.object;
    assert(map2["type"] == "VALUES");
    assert(map2["obj"] == null);
    assert(map2["flag"] == true);
    assert(map2["count"] == 3);
}

/++
動的にデシリアライズした後、様々なデータ型を抽出する方法の例です。

配列やマップからデータを取り出し、各要素が期待通りであることを確認します。

ポイント:
- YamlAlgebraic から配列を取り出すには array プロパティを使う
- YamlAlgebraic からマップを取り出すには object プロパティを使う
- マップからキーと値のペアを取り出すには pairs プロパティを使う
+/
unittest
{
    import mir.deser.yaml : deserializeYaml;
    import mir.algebraic_alias.yaml : YamlAlgebraic, YamlMap, YamlPair;

    // 解析するYAML形式の文字列
    string yaml = `
        tags: ["tag1", "tag2", "tag3"]
        data:
            - "value1"
            - 100
        props:
            key1: "value1"
            key2: 100
    `;

    // デシリアライズおよび検証
    YamlAlgebraic json = deserializeYaml!YamlAlgebraic(yaml);

    // 配列やマップを取り出すために、いくつか専用の関数が用意されています。
    // オブジェクトであれば object プロパティ、配列であれば array プロパティを使います。

    // 配列の場合は、array プロパティを使って配列を取り出します。
    YamlAlgebraic tagsObj = json.object["tags"];
    assert(tagsObj.kind == YamlAlgebraic.Kind.array);
    YamlAlgebraic[] tags = tagsObj.array;
    assert(tags.length == 3);
    assert(tags == ["tag1", "tag2", "tag3"]);

    // ブロックスタイルの配列も同様に array プロパティを使います。
    YamlAlgebraic dataObj = json.object["data"];
    assert(dataObj.kind == YamlAlgebraic.Kind.array);
    YamlAlgebraic[] data = dataObj.array;
    assert(data.length == 2);
    assert(data[0] == "value1");
    assert(data[1] == 100);

    // マップの場合は、pairs プロパティを使ってキーと値のペアを取り出します。
    YamlAlgebraic propsObj = json.object["props"];
    assert(propsObj.kind == YamlAlgebraic.Kind.object);
    YamlMap props = propsObj.object;
    YamlPair[] propsPairs = props.pairs; // .object.pairs でも良い
    assert(propsPairs.length == 2);
    assert(propsPairs[0].key == "key1");
    assert(propsPairs[0].value == "value1");
    assert(propsPairs[1].key == "key2");
    assert(propsPairs[1].value == 100);
}

/++
ファイルからYAMLデータをデシリアライズして `Person` 構造体に変換する例です。

ポイント:
- `deserializeYaml` 関数にファイル名を渡す
+/
unittest
{
    import mir.deser.yaml : deserializeYaml;
    import std.file;

    // テスト用ファイルの作成
    string yamlFileName = "example.yaml";
    string yamlFileText = `
        name: "Alice"
        age: 20
        height: 160.5
        isStudent: true
    `;
    write(yamlFileName, yamlFileText);
    scope (exit)
        remove(yamlFileName);

    // ファイルからデシリアライズ
    struct Person
    {
        string name;
        int age;
        double height;
        bool isStudent;
    }

    // ファイルを読み込んでテキストを取得し、デシリアライズする。
    // デシリアライズの際は、できればファイル名も渡す。
    Person person = readText(yamlFileName).deserializeYaml!Person(yamlFileName);
    assert(person.name == "Alice");
    assert(person.age == 20);
    assert(person.height == 160.5);
    assert(person.isStudent == true);
}

/++
構造体をYAML形式の文字列にシリアライズする例です。

`serializeYaml` 関数を使用して、構造体をYAML形式の文字列に変換します。

ポイント:
- `mir.ser.yaml` モジュールの `serializeYaml` 関数を使ってシリアライズする
- `serializeYaml` 関数の既定のフォーマットはフロースタイル
+/
unittest
{
    import mir.ser.yaml : serializeYaml;

    // 構造体
    struct Person
    {
        string name;
        int age;
        double height;
        bool isStudent;
    }

    // 構造体のインスタンス
    auto person = Person("Bob", 25, 170.5, false);

    // 構造体をYAML形式の文字列に変換
    string yaml = serializeYaml(person);

    // シリアライズしたYAML形式の文字列を検証
    assert(yaml == "{name: Bob, age: 25, height: 170.5, isStudent: false}\n", "'" ~ yaml ~ "'");
}

/++
ネストされた構造体をシリアライズする例です。

複数の構造体を含むデータについても、階層構造が正しく保持されます。

ポイント:
- ネストされた構造体もシリアライズできる
+/
unittest
{
    import mir.ser.yaml : serializeYaml;

    // 構造体
    struct Person
    {
        string name;
        int age;
        double height;
        bool isStudent;
    }

    struct Group
    {
        string groupName;
        Person[] members;
    }

    // 構造体のインスタンス
    auto person1 = Person("Alice", 20, 160.5, true);
    auto person2 = Person("Bob", 25, 170.5, false);
    auto group = Group("Group1", [person1, person2]);

    // 構造体をYAML形式の文字列に変換
    string yaml = serializeYaml(group);

    // シリアライズしたYAML形式の文字列を検証
    assert(yaml == "groupName: Group1\nmembers:\n- {name: Alice, age: 20, height: 160.5, isStudent: true}\n- {name: Bob, age: 25, height: 170.5, isStudent: false}\n", yaml);
}

/++
`DateTime` や `SysTime` を含む構造体のシリアライズとデシリアライズの例です。

各種日時型のデータは、YAML形式の文字列に変換される際に適切に処理されます。

ポイント:
- 日時型には `!!timestamp` タグが付く
- `DateTime` と `SysTime` の取り扱い方法（定義すれば自動的に処理される）
+/
unittest
{
    import mir.ser.yaml : serializeYaml;
    import mir.deser.yaml : deserializeYaml;
    import std.datetime : DateTime, SysTime, UTC;

    // 構造体
    struct Event
    {
        string name;
        DateTime startAt;
        SysTime endAt;
    }

    // 構造体のインスタンス
    auto event = Event("Event", DateTime(2021, 1, 1, 0, 0, 0), SysTime(DateTime(2022, 2, 3, 10, 20, 30), UTC()));

    // 構造体をYAML形式の文字列に変換
    string yaml = serializeYaml(event);

    // シリアライズしたYAML形式の文字列を検証
    // 日時型は !!timestamp というタグが付与されます。また、SysTimeにはUTCのZが付与されます。
    assert(yaml == "{name: Event, startAt: !!timestamp '2021-01-01T00:00:00-00:00', endAt: !!timestamp '2022-02-03T10:20:30.0000000Z'}\n", yaml);

    // YAML形式の文字列を構造体に変換
    Event event2 = deserializeYaml!Event(yaml);
    assert(event2.name == "Event");
    assert(event2.startAt == DateTime(2021, 1, 1, 0, 0, 0));
    assert(event2.endAt == SysTime(DateTime(2022, 2, 3, 10, 20, 30), UTC()));
}

/++
`Date` と `TimeOfDay` を含む構造体のシリアライズとデシリアライズの例です。

日付や時刻のデータは、YAML形式の文字列に変換される際に適切に処理されます。

ポイント:
- 日付型には `!!date` タグが付かない
- 時刻型には `!!timestamp` タグが付く
- `Date` と `TimeOfDay` は定義すれば自動的に処理される
+/
unittest
{
    import mir.ser.yaml : serializeYaml;
    import mir.deser.yaml : deserializeYaml;
    import std.datetime : Date, TimeOfDay;

    // 構造体
    struct Event
    {
        string name;
        Date date;
        TimeOfDay time;
    }

    // 構造体のインスタンス
    auto event = Event("Event", Date(2021, 1, 1), TimeOfDay(10, 20, 30));

    // 構造体をYAML形式の文字列に変換
    string yaml = serializeYaml(event);

    // シリアライズしたYAML形式の文字列を検証
    // 時刻型は !!timestamp というタグが付与されます。
    assert(yaml == "{name: Event, date: 2021-01-01, time: !!timestamp '10:20:30-00:00'}\n", yaml);

    // YAML形式の文字列を構造体に変換
    Event event2 = deserializeYaml!Event(yaml);
    assert(event2.name == "Event");
    assert(event2.date == Date(2021, 1, 1));
    assert(event2.time == TimeOfDay(10, 20, 30));
}

/++
`Duration` を含む構造体のシリアライズとデシリアライズの例です。

時間間隔のデータは、YAML形式の文字列に変換される際に適切に処理されます。

ポイント:
- `Duration` 型は `!!timestamp` タグが付与される
+/
unittest
{
    import mir.ser.yaml : serializeYaml;
    import mir.deser.yaml : deserializeYaml;
    import std.datetime : Duration, seconds;

    // 構造体
    struct Event
    {
        string name;
        Duration duration;
    }

    // 構造体のインスタンス
    auto event = Event("Event", 10.seconds);

    // 構造体をYAML形式の文字列に変換
    string yaml = serializeYaml(event);

    // シリアライズしたYAML形式の文字列を検証
    // Duration型は !!timestamp というタグが付与されます。
    assert(yaml == "{name: Event, duration: !!timestamp '0000-00-88T00:00:10.0000000-00:00'}\n", yaml);

    // YAML形式の文字列を構造体に変換
    Event event2 = deserializeYaml!Event(yaml);
    assert(event2.name == "Event");
    assert(event2.duration == 10.seconds);
}

/++
enum型を含む構造体のシリアライズとデシリアライズの例です。

enum型のフィールドは、YAML形式の文字列に変換される際に適切に処理されます。

ポイント:
- enum型はそのまま文字列に変換される
- enum型のフィールド名を変更する場合は `serdeKeys` 属性を使う（debugやversionなどの予約語で必要）
+/
unittest
{
    import mir.ser.yaml : serializeYaml;
    import mir.deser.yaml : deserializeYaml;
    import mir.serde : serdeKeys;

    // enum型
    enum TraceLvel
    {
        none,
        error,
        warn,
        info,
        @serdeKeys("debug") debug_,
        trace
    }

    // 構造体
    struct LogConfig
    {
        string filePath;
        TraceLvel level;
    }

    // 構造体のインスタンス
    auto logConfig = LogConfig("logs/app.log", TraceLvel.debug_);

    // 構造体をYAML形式の文字列に変換
    string yaml = serializeYaml(logConfig);

    // シリアライズしたYAML形式の文字列を検証
    assert(yaml == "{filePath: logs/app.log, level: debug}\n", yaml);

    // YAML形式の文字列を構造体に変換
    LogConfig logConfig2 = deserializeYaml!LogConfig(yaml);
    assert(logConfig2.filePath == "logs/app.log");
    assert(logConfig2.level == TraceLvel.debug_);
}

/++
Nullableなフィールドを含む構造体のシリアライズとデシリアライズの例です。

`std.typecons` の `Nullable` 型を使用して、null値を持つフィールドを扱います。
`mir.algebraic` で定義されている `Nullable` 型を使用することもできます。

ポイント:
- `Nullable` 型は、`std.typecons` または `mir.algebraic` のいずれかからimportして使う
- `Nullable` 型の `null` 値は、`Nullable!int.init` で取得する（std.typecons でも mir.algebraic でも同じ）
- `null` を許容することと、省略を許容することは異なる。省略を許容する場合は `@serdeOptional` 属性が必要
+/
unittest
{
    import mir.ser.yaml : serializeYaml;
    import mir.deser.yaml : deserializeYaml;

    // いずれかのNullable型をimportする
    import std.typecons : Nullable;

    // import mir.algebraic : Nullable; // 異なる型だが、実用上はどちらも大差ない

    // 構造体
    struct Person
    {
        string name;
        Nullable!int age;
    }

    // 値を持つ場合
    auto person = Person("Bob", Nullable!int(25));
    string yaml = serializeYaml(person);

    assert(yaml == "{name: Bob, age: 25}\n", yaml);

    // null値を持つ場合
    auto person2 = Person("Alice", Nullable!int.init);
    string yaml2 = serializeYaml(person2);

    assert(yaml2 == "{name: Alice, age: null}\n", yaml2);

    auto person3 = deserializeYaml!Person(yaml2); // null値のYAMLも逆変換できる
    assert(person3.name == "Alice");
    assert(person3.age.isNull);

    // フィールドが省略されている場合はエラーになる
    import mir.ion.exception : IonException;

    string yaml3 = "{name: Alice}\n";
    try
    {
        Person _person3 = deserializeYaml!Person(yaml3);
        assert(false);
    }
    catch (IonException e)
    {
        assert(e.msg == "mir.ion: non-optional member 'age' in Person is missing.", e.msg);
    }

    // 省略を認める場合は、追加で @serdeOptional が必要
    import mir.serde : serdeOptional;

    struct Person2
    {
        string name;

        @serdeOptional // 追加
        Nullable!int age;
    }

    Person2 person4 = deserializeYaml!Person2(yaml3);
    assert(person4.name == "Alice");
    assert(person4.age.isNull);
}

/++
様々な属性を使って構造体をシリアライズおよびデシリアライズする例です。

`serdeOptional`、`serdeIgnore`、`serdeIgnoreDefault`、`serdeKeys`、`serdeRequired` などの属性を使って、シリアライズ時の挙動を制御します。

ポイント:
- `serdeOptional` 属性でフィールドを省略可能にする
- `serdeIgnore` 属性でフィールドをシリアライズから除外する
- `serdeIgnoreDefault` 属性で既定値のフィールドを省略する
- `serdeKeys` 属性でフィールド名やenumのキー名を変更する
- `serdeRequired` 属性で必須フィールドを指定する
+/
unittest
{
    import mir.ser.yaml : serializeYaml;
    import mir.deser.yaml : deserializeYaml;

    import std.typecons : Nullable;
    import mir.serde : serdeIgnoreUnexpectedKeys, serdeIgnore, serdeIgnoreDefault, serdeOptional, serdeKeys, serdeRequired;

    enum LogLevel
    {
        Trance,
        Debug,
        Info,
        Warn,
        Error
    }

    @serdeIgnoreUnexpectedKeys
    struct ToolConfig
    {
        @serdeRequired
        string toolName;

        @serdeRequired
        string environment;

        @serdeOptional
        @serdeKeys("version")
        string version_;

        @serdeOptional
        @serdeKeys("max_connections")
        int maxConnections;

        @serdeOptional
        @serdeIgnoreDefault
        Nullable!int timeout;

        @serdeIgnore
        string internalPath;

        struct DatabaseConfig
        {
            @serdeRequired
            string host;

            @serdeRequired
            int port;

            @serdeOptional
            string username;

            @serdeOptional
            string password;
        }

        @serdeRequired
        DatabaseConfig database;

        struct LoggingConfig
        {
            @serdeOptional
            LogLevel level;

            string filePath = "logs/app.log";
        }

        @serdeOptional
        LoggingConfig logging;
    }

    ToolConfig config;
    config.toolName = "MyTool";
    config.environment = "production";
    config.version_ = "1.0.0";
    config.maxConnections = 100;
    config.timeout = Nullable!int.init;
    config.internalPath = "/usr/local/mytool";
    config.database = ToolConfig.DatabaseConfig("localhost", 5432, "admin", "<secret>");
    config.logging = ToolConfig.LoggingConfig(LogLevel.Debug, "logs/debug.log");

    string yaml = serializeYaml(config);

    ToolConfig deserializedConfig = deserializeYaml!ToolConfig(yaml);
    assert(deserializedConfig.toolName == "MyTool");
    assert(deserializedConfig.environment == "production");
    assert(deserializedConfig.version_ == "1.0.0");
    assert(deserializedConfig.maxConnections == 100);
}

/++
単純な docker-compose.yml の例を使って、複雑なYAMLデータをデシリアライズする例です。

`DockerComposeConfig` 構造体を定義し、`services` キーのデータを取り出して検証します。

ポイント:
- service のキーは動的なため、定義には連想配列を使う
+/
unittest
{
    import mir.deser.yaml : deserializeYaml;
    import mir.serde : serdeRequired, serdeKeys;

    // 解析するYAML形式の文字列
    string yaml = `
        version: '3.8'
        services:
            web:
                image: nginx:latest
                ports:
                    - "8080:80"
            db:
                image: postgres:latest
                ports:
                    - "5432:5432"
    `;

    // docker-compose.yml に相当する構造体（簡易版）
    struct DockerComposeConfig
    {
        @serdeRequired
        @serdeKeys("version")
        string version_;

        struct DockerComposeServiceConfig
        {
            @serdeRequired
            string image;

            @serdeRequired
            string[] ports;
        }

        @serdeRequired
        DockerComposeServiceConfig[string] services;
    }

    // デシリアライズおよび検証
    DockerComposeConfig config = deserializeYaml!DockerComposeConfig(yaml);

    // サービスのデータを取り出す
    auto services = config.services;
    assert(services.length == 2);
    assert("web" in services);
    assert("db" in services);

    auto web = services["web"];
    assert(web.image == "nginx:latest");
    assert(web.ports == ["8080:80"]);

    auto db = services["db"];
    assert(db.image == "postgres:latest");
    assert(db.ports == ["5432:5432"]);
}

/++
ブロックスタイルでYAMLをシリアライズする際のオプション設定の例です。

インデントやコレクションスタイルを指定して、出力されるYAMLのフォーマットを制御します。

ポイント:
- `YamlSerializationParams` オプションで設定を行い、`serializeYaml` 関数に渡す
- `YamlCollectionStyle.block` でブロックスタイルになる
+/
unittest
{
    import mir.ser.yaml : serializeYaml, YamlSerializationParams;
    import mir.algebraic_alias.yaml : YamlAlgebraic, YamlCollectionStyle;

    YamlAlgebraic value = YamlAlgebraic([
        YamlAlgebraic("tag1"),
        YamlAlgebraic("tag2"),
        YamlAlgebraic("tag3")
    ]);

    // シリアライズオプションを使って、ブロックスタイルでYAMLをシリアライズします。
    YamlSerializationParams params;
    params.defaultCollectionStyle = YamlCollectionStyle.block;

    string yaml = serializeYaml(value, params);
    assert(yaml == "- tag1\n- tag2\n- tag3\n", yaml);
}

/++
フロースタイルでYAMLをシリアライズする際のオプション設定の例です。

コレクションスタイルを指定して、出力されるYAMLのフォーマットを制御します。

ポイント:
- `YamlSerializationParams` オプションで設定を行い、`serializeYaml` 関数に渡す
- `YamlCollectionStyle.flow` でフロースタイルになる
+/
unittest
{
    import mir.ser.yaml : serializeYaml, YamlSerializationParams;
    import mir.algebraic_alias.yaml : YamlAlgebraic, YamlCollectionStyle;

    YamlAlgebraic value = YamlAlgebraic([
        YamlAlgebraic("tag1"),
        YamlAlgebraic("tag2"),
        YamlAlgebraic("tag3")
    ]);

    // シリアライズオプションを使って、フロースタイルでYAMLをシリアライズします。
    YamlSerializationParams params;
    params.defaultCollectionStyle = YamlCollectionStyle.flow;

    string yaml = serializeYaml(value, params);
    assert(yaml == "[tag1, tag2, tag3]\n", yaml);
}

/++
インデントを設定してブロックスタイルでYAMLをシリアライズする例です。

複雑なネスト構造を持つYAML出力時に、可読性を高めるためのインデント設定を行います。

ポイント:
- `YamlSerializationParams.indent`
+/
unittest
{
    import mir.ser.yaml : serializeYaml, YamlSerializationParams;
    import mir.algebraic_alias.yaml : YamlAlgebraic, YamlMap, YamlPair, YamlCollectionStyle;

    YamlAlgebraic value = YamlMap([
        YamlPair("props", YamlAlgebraic([
            YamlPair("key1", "value1"),
            YamlPair("key2", 100)
        ]))
    ]);

    // インデントは YamlSerializationParams オプションを使って指定します。
    YamlSerializationParams params;
    params.defaultCollectionStyle = YamlCollectionStyle.block;
    params.indent = 4;

    string yaml = serializeYaml(value, params);
    assert(yaml == "props:\n    key1: value1\n    key2: 100\n", yaml);
}

/++
属性 `@serdeIgnore` を使用して特定のフィールドをシリアライズから除外する例です。

シリアライズおよびデシリアライズ時に不要なフィールドを無視し、セキュリティを高めたり転送効率を改善します。

ポイント:
- 不要なフィールドに `@serdeIgnore` 属性を付ける
- デシリアライズ時にフィールドが省略されていると例外が発生する
- フィールドの省略を認めたい場合は、追加で構造体やクラスに `@serdeIgnoreUnexpectedKeys` 属性を付ける
+/
unittest
{
    import mir.ser.yaml : serializeYaml;
    import mir.deser.yaml : deserializeYaml;
    import mir.algebraic_alias.yaml : YamlAlgebraic, YamlMap, YamlPair;
    import mir.serde : serdeIgnore; // mir.serde は mir-algorithm で定義されています

    // 構造体
    struct Person
    {
        string name;
        int age;

        // @serdeIgnore を付けるとシリアライズとデシリアライズの対象外になります。
        @serdeIgnore
        string memo;
    }

    // 構造体のインスタンス
    auto person = Person("Bob", 25, "memo");

    // 構造体をYAML形式の文字列に変換
    string yaml = serializeYaml(person);
    assert(yaml == "{name: Bob, age: 25}\n", yaml); // memoフィールドが除外されている

    // YAML形式の文字列を構造体に変換
    string yaml2 = "{name: Bob, age: 25, memo: \"MyMemo\"}\n"; // memoフィールドが含まれていると例外が発生することに注意
    try
    {
        Person _person2 = deserializeYaml!Person(yaml2);
        assert(false);
    }
    catch (Exception e)
    {
        assert(e.msg == "Unexpected key when deserializing Person");
    }

    // 未知のフィールドが含まれるデータをデシリアライズする場合は、@serdeIgnoreUnexpectedKeysを付けておくことで例外を回避できます
    import mir.serde : serdeIgnoreUnexpectedKeys;

    @serdeIgnoreUnexpectedKeys
    struct Person2
    {
        string name;
        int age;

        @serdeIgnore
        string memo;
    }

    Person2 person2 = deserializeYaml!Person2(yaml2);
    assert(person2.name == "Bob");
    assert(person2.age == 25);
    assert(person2.memo == ""); // memoフィールドがデシリアライズされない
}

/++
属性 `@serdeIgnoreDefault` を使用して既定値のフィールドをシリアライズ時に省略する例です。

デフォルト値を持つフィールドを効率的に扱い、YAML出力を簡潔に保ちます。

ポイント:
- 既定値の場合に省略したいフィールドは、`@serdeIgnoreDefault` を指定する
+/
unittest
{
    import mir.ser.yaml : serializeYaml;
    import mir.deser.yaml : deserializeYaml;
    import mir.algebraic_alias.yaml : YamlAlgebraic, YamlMap, YamlPair;
    import mir.serde : serdeIgnoreDefault; // mir.serde は mir-algorithm で定義されています

    // 構造体
    struct Person
    {
        string name;
        int age;

        // @serdeIgnoreDefault を付けると既定値の時にフィールドを省略します。
        @serdeIgnoreDefault
        string memo = "default";
    }

    // 構造体のインスタンス
    auto person = Person("Bob", 25, "default");

    // 構造体をYAML形式の文字列に変換
    string yaml = serializeYaml(person);
    assert(yaml == "{name: Bob, age: 25}\n", yaml); // memoフィールドが既定値のため省略される

    // YAML形式の文字列を構造体に変換
    string yaml2 = "{name: Bob, age: 25, memo: \"MyMemo\"}\n"; // memoフィールドが含まれている
    Person person2 = deserializeYaml!Person(yaml2);
    assert(person2.name == "Bob");
    assert(person2.age == 25);
    assert(person2.memo == "MyMemo"); // memoフィールドがデシリアライズされる
}

/++
属性 `@serdeKeys` を使用してフィールド名を変更してシリアライズする例です。

YAML出力時にフィールド名をカスタマイズし、外部仕様に合わせたデータ形式を実現します。

ポイント:
- フィールド名を変更する場合は、`@serdeKeys("keyName")` を指定する
+/
unittest
{
    import mir.ser.yaml : serializeYaml;
    import mir.deser.yaml : deserializeYaml;
    import mir.algebraic_alias.yaml : YamlAlgebraic, YamlMap, YamlPair;
    import mir.serde : serdeKeys; // mir.serde は mir-algorithm で定義されています

    // 構造体
    struct Person
    {
        string name;
        int age;

        // @serdeKeys を付けるとフィールド名を変更できます。
        @serdeKeys("memo")
        string note;
    }

    // 構造体のインスタンス
    auto person = Person("Bob", 25, "memo");

    // 構造体をYAML形式の文字列に変換
    string yaml = serializeYaml(person);
    assert(yaml == "{name: Bob, age: 25, memo: memo}\n", yaml); // noteフィールドがmemoに変更されている

    // YAML形式の文字列を構造体に変換
    string yaml2 = "{name: Bob, age: 25, memo: \"MyMemo\"}\n"; // noteフィールドがmemoに変更されている
    Person person2 = deserializeYaml!Person(yaml2);
    assert(person2.name == "Bob");
    assert(person2.age == 25);
    assert(person2.note == "MyMemo"); // noteフィールドがmemoに変更されている
}

/++
属性 `@serdeRequired` を使用して必須フィールドを指定し、デシリアライズ時の検証を強化する例です。

必要なデータが欠けている場合に例外を発生させ、データの完全性を保証します。

ポイント:
- 必須フィールドを指定する場合は、`@serdeRequired` を指定する
- デシリアライズ時に必須フィールドが欠けている場合は、例外(IonException)が発生する
+/
unittest
{
    import mir.ser.yaml : serializeYaml;
    import mir.deser.yaml : deserializeYaml;
    import mir.algebraic_alias.yaml : YamlAlgebraic, YamlMap, YamlPair;
    import mir.serde : serdeRequired; // mir.serde は mir-algorithm で定義されています

    // YAML形式の文字列を構造体に変換
    import mir.ion.exception : IonException;

    // 構造体
    struct Person
    {
        string name;
        int age;

        // @serdeRequired を付けると必須フィールドを指定できます。
        @serdeRequired
        string memo;
    }

    // YAML形式の文字列を構造体に変換
    string yaml2 = "{name: Bob, age: 25}\n"; // memoフィールドが欠けている
    try
    {
        Person _person2 = deserializeYaml!Person(yaml2);
        assert(false);
    }
    catch (IonException e) // デシリアライズの失敗時にはIonExceptionが発生します
    {
        assert(e.msg == "mir.ion: non-optional member 'memo' in Person is missing.", e.msg);
    }
}

/++
`YamlAlgebraic` を使用してオブジェクトを構築する例です。

代数的データ型を活用して、動的なYAMLデータをプログラム的に作成・操作します。

ポイント:
- オブジェクトの構築は `YamlAlgebraic` のコンストラクタを使う
- オブジェクトのフィールド指定は、`YamlPair` の配列として構築する
+/
unittest
{
    import mir.algebraic_alias.yaml : YamlAlgebraic, YamlPair;

    // YamlAlgebraicのコンストラクタを使った構築
    // YamlPair[]を使うことでフィールド毎に異なる型の値を指定できます。
    YamlAlgebraic json = YamlAlgebraic([
        YamlPair("name", "Alice"),
        YamlPair("age", 20),
        YamlPair("height", 160.5),
        YamlPair("isStudent", true)
    ]);

    // 構築したデータへのアクセスは .object プロパティを使います。
    assert(json.kind == YamlAlgebraic.Kind.object);
    assert(json.object["name"] == "Alice");
    assert(json.object["age"] == 20);
    assert(json.object["height"] == 160.5);
    assert(json.object["isStudent"] == true);
    YamlAlgebraic name = json.object["name"]; // インデックスアクセス時の型はYamlAlgebraicです。

    // 連想配列を元にした構築も可能です。ただしこれはすべてのフィールドで型が同じ場合に限ります。
    double[string] data = [
        "height": 129.3,
        "weight": 129.3
    ];
    YamlAlgebraic json2 = YamlAlgebraic(data); // 直接YamlAlgebraicのコンストラクタが使えます。
    assert(json2.kind == YamlAlgebraic.Kind.object);
    assert(json2.object["height"] == 129.3);
    assert(json2.object["weight"] == 129.3);
}

/++
`YamlAlgebraic` を使用して配列を構築する例です。

配列データを動的に生成し、YAML形式での表現を確認します。

ポイント:
- 配列の構築は `YamlAlgebraic` のコンストラクタを使う
- 配列データは `YamlAlgebraic` の配列として構築する（そうしないと意図しない型になる場合がある）
+/
unittest
{
    import mir.algebraic_alias.yaml : YamlAlgebraic;

    // YamlAlgebraicのコンストラクタを使った構築
    YamlAlgebraic json = YamlAlgebraic([
        YamlAlgebraic("tag1"),
        YamlAlgebraic("tag2"),
        YamlAlgebraic("tag3")
    ]);

    // 構築したデータへのアクセスは .array プロパティを使います。
    import std.format : format;

    assert(json.kind == YamlAlgebraic.Kind.array);
    YamlAlgebraic[] jsonArray = json.array;
    assert(jsonArray.length == 3);
    assert(jsonArray[0] == "tag1");
    assert(jsonArray[1] == "tag2");
    assert(jsonArray[2] == "tag3");

    // 直接配列から構築するときは、YamlAlgebraicにラップする必要があります。
    // 失敗例:
    YamlAlgebraic json2 = YamlAlgebraic([1, 2, 3]);
    assert(json2.kind == YamlAlgebraic.Kind.string); // arrayではなくstringになってしまう

    YamlAlgebraic json3 = YamlAlgebraic(["tag1", "tag2", "tag3"]);
    assert(json3.kind == YamlAlgebraic.Kind.annotated); // arrayではなくannotatedになってしまう

    // 成功例:
    import std.algorithm : map;
    import std.array : array;

    int[] data = [1, 2, 3];
    YamlAlgebraic json4 = YamlAlgebraic(data.map!(a => YamlAlgebraic(a)).array);
    assert(json4.kind == YamlAlgebraic.Kind.array);

    string[] data2 = ["tag1", "tag2", "tag3"];
    YamlAlgebraic json5 = YamlAlgebraic(data2.map!(a => YamlAlgebraic(a)).array);
    assert(json5.kind == YamlAlgebraic.Kind.array);
}

/++
構造体から `YamlAlgebraic` を構築する例です。

静的な型情報を活用して、構造化されたYAMLデータを生成・操作します。

ポイント:
- オブジェクトは一度 `YamlMap` で構築してから `YamlAlgebraic` に代入する
- `static foreach` や `__traits` の `getMember` を使えば、構造体のフィールドを自動的にYamlMapに設定できる
+/
unittest
{
    import mir.algebraic_alias.yaml : YamlAlgebraic, YamlPair, YamlMap;

    // 構造体
    struct Person
    {
        string name;
        int age;
        double height;
        bool isStudent;
    }

    // 構造体のインスタンス
    auto person = Person("Bob", 25, 170.5, false);

    // 一度YamlMapとして構築してからYamlAlgebraicに変換することで、構造体をYamlAlgebraicに変換できます。
    YamlMap jsonTemp;
    jsonTemp["name"] = person.name;
    jsonTemp["age"] = person.age;
    jsonTemp["height"] = person.height;
    jsonTemp["isStudent"] = person.isStudent;

    YamlAlgebraic json = jsonTemp;

    // 構築したデータへのアクセスは .object プロパティを使います。
    assert(json.kind == YamlAlgebraic.Kind.object);
    assert(json.object["name"] == "Bob");
    assert(json.object["age"] == 25);
    assert(json.object["height"] == 170.5);
    assert(json.object["isStudent"] == false);

    // メタプログラミングを使うと、構造体のフィールドを自動的にYamlMapに変換できます。
    YamlMap jsonTemp2;
    static foreach (field; __traits(allMembers, Person))
    {
        jsonTemp2[field] = __traits(getMember, person, field);
    }

    YamlAlgebraic json2 = jsonTemp2;

    assert(json2.kind == YamlAlgebraic.Kind.object);
    assert(json2.object["name"] == "Bob");
    assert(json2.object["age"] == 25);
    assert(json2.object["height"] == 170.5);
    assert(json2.object["isStudent"] == false);
}

/++
`YamlAlgebraic` から静的なデータ型を取得する例です。

YAMLデータを構造体に変換する際に、型情報を活用してデータの整合性を確認します。

ポイント:
- `get` 関数のテンプレート引数に型を指定すれば、その型のデータだったときに取得できる
- `integer` は `long` に変換される（intではない）
- `float_` は `double` に変換される（floatではない）
- `array` は `YamlAlgebraic[]` に変換される
- `object` は `YamlMap` に変換される
+/
unittest
{
    import mir.algebraic_alias.yaml : YamlAlgebraic, YamlPair, YamlMap;

    // YamlAlgebraicのコンストラクタを使った構築
    YamlAlgebraic json = YamlAlgebraic([
        YamlPair("name", "Alice"),
        YamlPair("age", 20),
        YamlPair("height", 160.5),
        YamlPair("isStudent", true),
        YamlPair("tags", YamlAlgebraic([
            YamlAlgebraic("tag1"), YamlAlgebraic("tag2"), YamlAlgebraic("tag3")
        ])),
        YamlPair("data", YamlAlgebraic([
            YamlPair("key1", "value1"),
            YamlPair("key2", 100)
        ])),
    ]);

    // get関数を使うか、型に合わせたプロパティ名で取得できます。
    /*
        - boolを取得する場合は boolean
        - longを取得する場合は integer
        - doubleを取得する場合は float_
        - stringを取得する場合は string
        - Blobを取得する場合は blob
        - Timestampを取得する場合は timestamp
        - 配列を取得する場合は array
        - オブジェクト(YamlMap)を取得する場合は object
    */
    assert(json.object["name"].kind == YamlAlgebraic.Kind.string);
    string name = json.object["name"].get!string();
    string name2 = json.object["name"].string;
    assert(name == "Alice" && name2 == "Alice");

    assert(json.object["age"].kind == YamlAlgebraic.Kind.integer);
    long age = json.object["age"].get!long();
    long age2 = json.object["age"].integer;
    assert(age == 20 && age2 == 20);

    assert(json.object["height"].kind == YamlAlgebraic.Kind.float_);
    double height = json.object["height"].get!double();
    double height2 = json.object["height"].float_;
    assert(height == 160.5 && height2 == 160.5);

    assert(json.object["isStudent"].kind == YamlAlgebraic.Kind.boolean);
    bool isStudent = json.object["isStudent"].get!bool();
    bool isStudent2 = json.object["isStudent"].boolean;
    assert(isStudent == true && isStudent2 == true);

    import std.algorithm : map;
    import std.array : array;

    assert(json.object["tags"].kind == YamlAlgebraic.Kind.array);
    YamlAlgebraic[] tags = json.object["tags"].array;
    string[] tags2 = tags.map!(a => a.string).array();
    assert(tags2 == ["tag1", "tag2", "tag3"]);

    assert(json.object["data"].kind == YamlAlgebraic.Kind.object);
    YamlMap data = json.object["data"].object;
    assert(data["key1"] == "value1"); // YamlAlgebraicは値と直接比較できます
    assert(data["key2"] == 100);
    assert(data["key2"] <= 200); // YamlAlgebraicは比較演算子をサポートしています
}
