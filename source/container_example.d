/++
コンテナ

スタックやキューなど、いくつかのデータ構造を実現する方法についてまとめます。

Source: $(LINK_TO_SRC source/_container_example.d)
Macros:
    TITLE=コンテナ（データ構造）の例
+/
module container_example;

/++
スタックを構成する例です。

汎用データ構造である `std.container` の `SList` （単方向リンクリスト）を利用して実現します。

See_Also: https://dlang.org/phobos/std_container_slist.html
+/
unittest
{
    import std.container : SList;

    SList!int stack;

    // insertで要素を追加します
    // コンテナ共通インターフェースが利用でき、SListではすべて同じ意味になります
    stack.insert(1);
    stack.insertFront(2);
    stack.stableInsert(3);
    stack.stableInsertFront(4);

    // スライス演算で全体をレンジとして取得、中身を確認します
    // 結果はレンジになるため、equalで比較します
    import std.algorithm : equal;

    assert(equal(stack[], [4, 3, 2, 1]));

    // 先頭要素を取り除かずに確認します
    assert(stack.front == 4);

    // removeAnyで要素を取り除きます。先頭要素を取り除く操作になります。
    // コンテナ共通インターフェースが利用でき、SListではすべて同じ意味になります
    auto elem_4 = stack.removeAny();
    auto elem_3 = stack.stableRemoveAny();
    assert(elem_4 == 4);
    assert(elem_3 == 3);

    // 要素をクリアします
    stack.clear();
    assert(stack.empty);
}

/+
初期データを指定してスタック(SList)を初期化する例です。

コンストラクタ、または `make` テンプレート関数を使います。
+/
unittest
{
    import std.container : SList, make;

    // 要素を引数に渡すことで初期化できます。要素を並べたりレンジを渡したりできます
    SList!int stack1 = SList!int(1, 2, 3, 4, 5);
    SList!int stack2 = SList!int([10, 20, 30, 40, 50]);
    // makeテンプレート関数を使うことで、要素型を推論させることができます
    SList!int stack3 = make!SList([100, 200, 300, 400, 500]);

    import std.algorithm : equal;

    assert(equal(stack1[], [1, 2, 3, 4, 5]));
    assert(equal(stack2[], [10, 20, 30, 40, 50]));
    assert(equal(stack3[], [100, 200, 300, 400, 500]));
}

/++
Queueを構成する例です

汎用データ構造である `std.container` の `DList` (双方向リンクリスト)を利用します。

See_Also: https://dlang.org/phobos/std_container_dlist.html
+/
unittest
{
    import std.container : DList;

    DList!int queue;

    // insertで要素を追加します
    // コンテナ共通インターフェースが利用でき、DListではすべて同じ意味になります
    queue.insertFront(1);
    queue.stableInsertFront(2);

    // removeAnyで要素を取得します。後ろの要素を取り出す操作になります
    // コンテナ共通インターフェースが利用でき、DListではすべて同じ意味になります
    int elem_1 = queue.removeAny();
    int elem_2 = queue.stableRemoveAny();
    assert(elem_1 == 1);
    assert(elem_2 == 2);

    // スライス演算で全体をレンジとして取得、中身を確認します
    queue.insertFront(10);
    queue.insertFront(20);
    queue.insertFront(30);
    queue.insertFront(40);

    // 結果はレンジになるため、equalで比較します
    import std.algorithm : equal;

    assert(equal(queue[], [40, 30, 20, 10]));

    // 先頭要素を取り除かずに確認します
    assert(queue.back == 10);
    // 最後に追加した要素を確認します
    assert(queue.front == 40);

    // removeAnyで要素を取り除きます。末尾要素を取り除く操作になります。
    // コンテナ共通インターフェースが利用でき、DListではすべて同じ意味になります
    auto elem_10 = queue.removeAny();
    auto elem_20 = queue.stableRemoveAny();
    assert(elem_10 == 10);
    assert(elem_20 == 20);

    // 要素をクリアします
    queue.clear();
    assert(queue.empty);
}

/+
初期データを指定してキュー(DList)を初期化する例です。

コンストラクタ、または `make` テンプレート関数を使います。
+/
unittest
{
    import std.container : DList, make;

    // 要素を引数に渡すことで初期化できます。要素を並べたりレンジを渡したりできます
    DList!int queue1 = DList!int(1, 2, 3, 4, 5);
    DList!int queue2 = DList!int([10, 20, 30, 40, 50]);
    // makeテンプレート関数を使うことで、要素型を推論させることができます
    DList!int queue3 = make!DList([100, 200, 300, 400, 500]);

    import std.algorithm : equal;

    assert(equal(queue1[], [1, 2, 3, 4, 5]));
    assert(equal(queue2[], [10, 20, 30, 40, 50]));
    assert(equal(queue3[], [100, 200, 300, 400, 500]));
}
