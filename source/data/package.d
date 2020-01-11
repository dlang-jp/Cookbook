/++
データ形式

特定のデータ形式を取り扱う例をまとめました

$(DL
    $(DT $(A cookbook--_data.csv_example.html, CSV))
    $(DD
        `std.csv`を用いてCSV形式のデータを取り扱います。 $(BR)
        また、`std.csv`ではサポートされていないCSVの書き出し方についても取り扱います。
    )
    $(DT $(A cookbook--_data.json_example.html, JSON))
    $(DD
        `std.json`を用いてJSON形式のデータを取り扱います。 $(BR)
        数値型や文字列型、真偽値型、配列や連想配列と、JSONデータ型との相互変換やJSONファイルの読み書きを行います。
    )
)

+/
module data;

public import data.csv_example;
public import data.json_example;
