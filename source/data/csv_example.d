/++
CSV操作

CSVファイル/CSVデータの読み書き等操作を扱います。
ここでは、標準で備えているstd.csvモジュールを用いたCSVファイルの読み込みと、
CSVファイルへの書き出しについて説明します。

Source: $(LINK_TO_SRC source/data/_csv_example.d)
+/
module data.csv_example;




/++
ヘッダー無しCSVテキストを2次元配列(string[][])としてパースする方法
+/
@safe unittest
{
    import std.csv;
    import std.algorithm, std.array, std.string;
    // サンプルのCSV
    enum string csv1 = `
        a,b,c,d,e
        1,2,3,4,5
        6,7,8,9,10
    `.outdent.strip;

    // 文字列からをCSVとしてパースして、文字列の2次元配列にします
    // 以下はワンライナーで取れるようにしていますが、
    // csvReader(csv1)した各レコード(1行ごとに各列(Range)が格納されたRange)を、
    // mapとarrayで配列に変換しているだけです。
    auto mat = csvReader(csv1).map!array.array;
    assert(mat[0][0] == "a");
    assert(mat[0][1] == "b");
    assert(mat[1][0] == "1");
}

/++
ヘッダー付きCSVテキストを2次元配列(string[][])としてパースする方法
+/
@safe unittest
{
    import std.csv;
    import std.algorithm, std.array, std.string, std.exception;
    // サンプルのCSV
    // 今回はヘッダ付きです。
    enum string csv1 = `
        Name,Height,BloodType
        Cocoa,154,B
        Chino,144,AB
        Rize,160,A
    `.outdent.strip;

    // 配列に直すのはこうしておくと楽
    alias toMat = r => r.map!array.array;

    // 文字列からをCSVとしてパースして、文字列の2次元配列にします
    // 何もしないとヘッダも読み込まれてしまいます
    auto mat = toMat(csv1.csvReader);
    assert(mat[0][0] == "Name");
    assert(mat[0][1] == "Height");
    assert(mat[1][0] == "Cocoa");
    assert(mat[1][2] == "B");
}

/++
ヘッダー付きCSVテキストから特定の列だけ配列として読み込む方法
+/
@safe unittest
{
    // importとデータの準備をします
    import std.csv;
    import std.algorithm, std.array, std.string, std.exception;

    // 今回はヘッダ付きです。
    enum string csv1 = `
        Name,Height,BloodType
        Cocoa,154,B
        Chino,144,AB
        Rize,160,A
    `.outdent.strip;

    // 配列に直す処理を簡略化
    alias toMat = r => r.map!array.array;

    // 今回のCSVにはヘッダが付与されていますが、
    // csvReaderの2つ目の引数にnullを指定するとヘッダー行を無視することができます。
    // あるいは、取得するデータをピックアップすることもできます。
    // ※列はファイル上の順序に従う必要があります。
    //   右列のデータを左列に持ってくるような並べ替え、入れ替えはできません。
    auto mat2 = toMat(csv1.csvReader(null));
    assert(mat2[0][0] == "Cocoa");
    assert(mat2[0][1] == "154");
    assert(mat2[1][0] == "Chino");
    assert(mat2[1][2] == "AB");

    // 特定の列だけを抜き出します
    auto mat3 = toMat(csv1.csvReader(["Name", "BloodType"]));
    assert(mat3[0][0] == "Cocoa");
    assert(mat3[0][1] == "B");
    assert(mat3[1][0] == "Chino");
    assert(mat3[1][1] == "AB");

    // 注意: 並べ替えようとすると、HeaderMismatchException という例外が発生します。
    assertThrown!HeaderMismatchException(
        toMat(csv1.csvReader(["Name", "BloodType", "Height"])));
}

/++
ヘッダー付きCSVテキストを構造体の配列としてパースする方法
+/
@safe unittest
{
    import std.csv;
    import std.array, std.string;
    // サンプルのCSV
    // さっきと同じ
    enum string csv1 = `
        Name,Height,BloodType
        Cocoa,154,B
        Chino,144,AB
        Rize,160,A
    `.outdent.strip;

    // 次は各行のレコードをこの構造体のデータとして一括読み込みします
    struct CharactorData
    {
        enum BloodType { A, B, AB, O }
        string    name;
        BloodType bloodType;
        int       height;
    }

    // csvReaderの1つ目のテンプレート引数に構造体を渡すと、
    // そのメンバー変数のレイアウトでCSVを解釈します。
    // 構造体のメンバー変数はそれぞれstd.conv.toによって文字列と相互に変換可能
    // でなければなりません。
    // また、CSVの先頭行にヘッダ情報があるので、構造体の場合並び替えが可能です。
    // csvRaderの2つ目の引数に文字列の配列を渡してやることで、CSVの1行目を
    // ヘッダとして解釈し、並び替えを行って読み込むことができます。
    auto order = ["Name", "BloodType", "Height"];
    auto charactors = csv1.csvReader!CharactorData(order).array;
    assert(charactors[0].name == "Cocoa");
    assert(charactors[1].height == 144);
    assert(charactors[2].bloodType == CharactorData.BloodType.A);
}

/++
ファイルパスを指定して、ヘッダー付きCSVファイルを構造体配列として読み込む方法
+/
@safe unittest
{
    // テストデータの準備と破棄
    import std.file : mkdir, rmdirRecurse, write;

    mkdir("temp");
    scope (exit) rmdirRecurse("temp");
    write("temp/test.csv", "Name,Hoge,Value\nA,Fuga,10.0\nB,Foo,1.5\nC,Bar,-12.5");

    // readTextでテキストデータを読み込み、csvReaderで処理します。
    // 結果として欲しい構造体は事前に定義しておきます。
    // 今回は、Name,Hoge,Valueの列を持つCSVからName,Valueのみロードします。
    import std : readText, csvReader, array;

    // 結果として欲しい構造体を定義します。staticはグローバル定義なら不要です。
    static struct Record
    {
        string name;
        double value;
    }

    // ワンライナーでロードできます。ヘッダー名の配列を null にすれば全ての列を読み込みます。
    auto records = readText("temp/test.csv").csvReader!Record(["Name", "Value"]).array();

    import std.math : isClose;

    assert(records[0].name == "A");
    assert(records[0].value.isClose(10.0));
    assert(records[1].name == "B");
    assert(records[1].value.isClose(1.5));
    assert(records[2].name == "C");
    assert(records[2].value.isClose(-12.5));
}

/++
CSVのレコードを1行ずつ1列ずつ独自に処理しながら読み込む方法

stringでロード後にmapで変換しても良いのですが、リソース効率などの観点から独自処理したい場合の方法をまとめます。
+/
@safe unittest
{
    // テストデータの準備と破棄
    import std.file : mkdir, rmdirRecurse, write;

    mkdir("temp");
    scope (exit) rmdirRecurse("temp");

    // ここでは8桁数値を日付として読み込みたい場合の変換を考えます。
    write("temp/test.csv", "Name,Date\nA,20200101\nB,20210101\nC,20220101");

    // あらかじめDate型に変換する簡単な処理を用意します。異常値は考慮していません。
    Date parseDate(string text8Digit)
    {
        import std.conv : to;
        const year = to!ushort(text8Digit[0 .. 4]);
        const month = to!ubyte(text8Digit[4 .. 6]);
        const day = to!ubyte(text8Digit[6 .. 8]);
        return Date(year, month, day);
    }

    // csvReaderで読み込み、1列ずつ処理します。
    import std : readText, csvReader, Date;

    struct Record
    {
        string name;
        Date date;
    }

    // テキストの構造は既に知っているとして、ヘッダーを読み飛ばします。
    // この時点では csvReader の戻り値が配列になっていないのでRangeの状態です。
    auto records = readText("temp/test.csv").csvReader(null);

    // バッファを用意して、1行ずつ処理します。
    import std.array : appender;

    auto results = appender!(Record[]);
    foreach (record; records)
    {
        // record自体が列ごとのRangeになっているため、順次読んで処理します。
        // frontの型はすべてstringです。
        auto name = record.front; record.popFront(); // 最初の列を得て次に進める
        auto date = parseDate(record.front); record.popFront(); // 日付列を処理して先に進める（最終列ならやらなくても良いが、増えたときに楽）

        results.put(Record(name, date));
    }

    Record[] dataset = results.data;
    assert(dataset[0].name == "A");
    assert(dataset[0].date == Date(2020, 1, 1));
    assert(dataset[1].name == "B");
    assert(dataset[1].date == Date(2021, 1, 1));
    assert(dataset[2].name == "C");
    assert(dataset[2].date == Date(2022, 1, 1));
}

/++
# CSVの書き出し

残念ながら、CSVを書き出す機能はありません。自分で作ります。
以下の例では汎用性を高めるため、`",\n`を含むものを変換することを前提とします。
これらが含まれると、各セルをエスケープする必要が出るためです。
数値だけということがあらかじめわかっているときなど、
エスケープする必要がない場合は`format!"%-(%-(%-s,%)\n%)"(mat)`とするだけでOK。
+/
@safe unittest
{
    // CSVは、カンマ区切りで列を、改行で行を表すテキストですが、
    // 細かく言うと、`"`で囲まれた範囲を文字列として処理します。
    // 文字列の中では、改行やカンマが使用できます。ダブルクォーテーションを
    // 文字列内で表現する場合は、2つ連続させます。`""`こんな感じに。
    // つまり、`",\r\n`(ダブルクォーテーションとカンマと改行)が含まれるセルは
    // `"`で囲んで出力し、さらにその中の`"`は`""`に置換してやります。
    string escapeCSV(string txt)
    {
        import std.string, std.array;
        if (txt.indexOfAny(",\"\r\n") != -1)
            return `"` ~ txt.replace("\"", "\"\"") ~ `"`;
        return txt;
    }

    // 文字列の2次元配列(行列)の各セルをエスケープし、
    // 各列をカンマ区切り・各行を改行区切りの文字列にします。
    // ここで、formatが利用できます。`%(%)`という書式で、
    // Rangeをうまいこと展開できます。
    string toCSV(string[][] mat)
    {
        import std.algorithm, std.format;
        return format!"%-(%-(%-s,%)\n%)"(
            mat.map!(row => row.map!escapeCSV));
    }

    // 準備
    import std.algorithm, std.array, std.csv, std.string;
    alias toMat = r => r.map!array.array;

    // 文字列の行列を…
    string[][] mat = [
        ["aaa", "bb,b", "c\nc"],
        ["123", "x\"y", "\"xxx\""]];
    // CSVに変換！
    auto csv = toCSV(mat);
    // 中身はこう
    assert(csv == `
        aaa,"bb,b","c
        c"
        123,"x""y","""xxx"""
    `.outdent.strip);

    // もう一度文字列の行列に戻して比較しても一致！
    assert(equal(toMat(csv.csvReader), mat));
}
