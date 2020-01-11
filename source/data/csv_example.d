/++
CSV操作

CSVファイル/CSVデータの読み書き等操作を扱います。
ここでは、標準で備えているstd.csvモジュールを用いたCSVファイルの読み込みと、
CSVファイルへの書き出しについて説明します。
+/
module data.csv_example;




/++
# CSVのパース
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
もう少し複雑な場合
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


    // 今回のCSVにはヘッダが付与されていますが、
    // csvReaderの2つ目の引数にnullを指定するとその分を無視することができます
    // あるいは、取得するデータをピックアップすることもできます。
    // ※右列のデータを左列に持ってくるような並べ替えはできません
    auto mat2 = toMat(csv1.csvReader(null));
    assert(mat2[0][0] == "Cocoa");
    assert(mat2[0][1] == "154");
    assert(mat2[1][0] == "Chino");
    assert(mat2[1][2] == "AB");
    auto mat3 = toMat(csv1.csvReader(["Name", "BloodType"]));
    assert(mat3[0][0] == "Cocoa");
    assert(mat3[0][1] == "B");
    assert(mat3[1][0] == "Chino");
    assert(mat3[1][1] == "AB");
    // こんな感じの並べ替えはHeaderMismatchExceptionでNG
    assertThrown!HeaderMismatchException(
        toMat(csv1.csvReader(["Name", "BloodType", "Height"])));
}

/++
構造体でデータ構造をレイアウトする場合
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
