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

スタックは、後入れ先出し（LIFO: Last In, First Out）のデータ構造です。
要素の追加順に対し、後から追加した最も新しい要素が取り出されます。

汎用データ構造である `std.container` の `SList` を利用して実現します。
SListは「単方向リンクリスト（Single Linked List）」であり、先頭要素の追加や削除が高速（定数時間）です。
これはスタックの動作に沿っており、パフォーマンスの面からも優れています。

See_Also: https://dlang.org/phobos/std_container_slist.html
+/
unittest
{
    import std.container : SList;

    SList!int stack;

    // insertで要素を追加します。これは一般にpushとも呼ばれます。
    // これらのメソッドはコンテナ共通インターフェースの一部で、SListではすべて先頭に要素を追加する操作になります
    stack.insert(1);               // 1
    stack.insertFront(2);          // 2 -> 1
    stack.stableInsert(3);         // 3 -> 2 -> 1
    stack.stableInsertFront(4);    // 4 -> 3 -> 2 -> 1

    // スライス演算で全体をレンジとして取得し、中身を確認します。
    // レンジは要素のシーケンスを表し、equal関数で比較できます。
    import std.algorithm : equal;

    assert(equal(stack[], [4, 3, 2, 1]));

    // 先頭要素を取り除かずに確認します
    assert(stack.front == 4);

    // removeAnyで要素を取り除きます。これは一般にpopとも呼ばれ、先頭要素を取り除く操作になります。
    // これらのメソッドもコンテナ共通インターフェースの一部で、SListではすべて先頭要素を取り除く操作になります
    auto elem_4 = stack.removeAny();        // 4が取り除かれる: 3 -> 2 -> 1
    auto elem_3 = stack.stableRemoveAny();  // 3が取り除かれる: 2 -> 1
    assert(elem_4 == 4);
    assert(elem_3 == 3);

    // 要素をクリアします
    stack.clear();
    assert(stack.empty);
}

/+
スタック(SList)の初期化方法

初期データを指定してスタック(SList)を初期化します。

コンストラクタや`make`テンプレート関数を利用します。
+/
unittest
{
    import std.container : SList, make;

    // 要素を引数に渡すことで初期化します。要素を並べるか、レンジを渡します。
    SList!int stack1 = SList!int(1, 2, 3, 4, 5);
    SList!int stack2 = SList!int([10, 20, 30, 40, 50]);
    // makeテンプレート関数を使うことで、要素型を推論させることができます。
    SList!int stack3 = make!SList([100, 200, 300, 400, 500]);

    import std.algorithm : equal;

    assert(equal(stack1[], [1, 2, 3, 4, 5]));
    assert(equal(stack2[], [10, 20, 30, 40, 50]));
    assert(equal(stack3[], [100, 200, 300, 400, 500]));
}

/++
キューを構成する例です

キューは、先入れ先出し（FIFO: First In, First Out）のデータ構造です。
要素の追加順に対し、最初に追加した最も古い要素が取り出されます。

汎用データ構造である `std.container` の `DList` を利用して実現します。
DListは「双方向リンクリスト（Double Linked List）」であり、先頭と末尾に対する追加や削除が高速（定数時間）です。
これはキューの動作に沿っており、パフォーマンスの面からも優れています。

See_Also: https://dlang.org/phobos/std_container_dlist.html
+/
unittest
{
    import std.container : DList;

    DList!int queue;

    // insertで要素を追加します。これは一般にenqueueとも呼ばれます。
    // これらのメソッドはコンテナ共通インターフェースの一部で、DListではすべて先頭に要素を追加する操作になります
    queue.insertFront(1);          // 1
    queue.stableInsertFront(2);    // 2 -> 1

    // removeAnyで要素を取得します。これは一般にdequeueとも呼ばれ、後ろの要素を取り出す操作になります
    // コンテナ共通インターフェースが利用でき、DListではすべて同じ意味になります
    int elem_1 = queue.removeAny();          // 2
    int elem_2 = queue.stableRemoveAny();    // empty
    assert(elem_1 == 1);
    assert(elem_2 == 2);

    // スライス演算で全体をレンジとして取得し、中身を確認します。
    queue.insertFront(10);    // 10
    queue.insertFront(20);    // 20 -> 10
    queue.insertFront(30);    // 30 -> 20 -> 10
    queue.insertFront(40);    // 40 -> 30 -> 20 -> 10

    // レンジは要素のシーケンスを表し、equal関数で比較できます。
    import std.algorithm : equal;

    assert(equal(queue[], [40, 30, 20, 10]));

    // 先頭要素を取り除かずに確認します
    assert(queue.back == 10);
    // 最後に追加した要素を確認します
    assert(queue.front == 40);

    // removeAnyで要素を取り除きます。末尾要素を取り除く操作になります。
    // これらのメソッドもコンテナ共通インターフェースの一部で、DListではすべて先頭要素を取り除く操作になります
    auto elem_10 = queue.removeAny();          // 10が取り除かれる: 40 -> 30 -> 20
    auto elem_20 = queue.stableRemoveAny();    // 20が取り除かれる: 40 -> 30
    assert(elem_10 == 10);
    assert(elem_20 == 20);

    // 要素をクリアします
    queue.clear();
    assert(queue.empty);
}

/+
キュー(DList)の初期化方法

初期データを指定してキュー(DList)を初期化します。

コンストラクタや`make`テンプレート関数を利用します。
+/
unittest
{
    import std.container : DList, make;

    // 要素を引数に渡すことで初期化します。要素を並べるか、レンジを渡します。
    DList!int queue1 = DList!int(1, 2, 3, 4, 5);
    DList!int queue2 = DList!int([10, 20, 30, 40, 50]);
    // makeテンプレート関数を使うことで、要素型を推論させることができます。
    DList!int queue3 = make!DList([100, 200, 300, 400, 500]);

    import std.algorithm : equal;

    assert(equal(queue1[], [1, 2, 3, 4, 5]));
    assert(equal(queue2[], [10, 20, 30, 40, 50]));
    assert(equal(queue3[], [100, 200, 300, 400, 500]));
}
