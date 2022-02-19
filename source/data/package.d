/++
データ形式

特定のデータ形式を取り扱う例をまとめました

$(DL
    $(DT $(A cookbook--_data.base64_example.html, Base64))
    $(DD
        `std.base64`を用いてBase64形式でのデータのエンコード/デコードを取り扱います。
    )
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
    $(DT $(A cookbook--_data.zip_example.html, ZIP))
    $(DD
        `std.zip`を用いてZIP形式のデータの圧縮・解凍を取り扱います。 $(BR)
        ディレクトリ階層の再現、日本語ファイル名の取り扱いについても取り扱います。
    )
)

Source: $(LINK_TO_SRC source/_data/package.d)
+/
module data;

public import data.csv_example;
public import data.json_example;
public import data.zip_example;
