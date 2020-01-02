/++
メタプログラミング

メタプログラミングに出てくるイディオム等についてまとめます。
+/
module meta_example;

/++
モジュールの定義一覧を取得する例です。

`__traits(allMembers, モジュール名)`と書きます。
+/
@safe unittest
{
    import std.stdio;

    alias StdMembers = __traits(allMembers, std.stdio);

    static assert(StdMembers.length > 0);
}

/++
任意のモジュール名から定義一覧を取得するイディオムです。

モジュールの参照を`mixin`と`std.meta.Alias`を使って取得します。
+/
@safe unittest
{
    template Module(string moduleName)
    {
        mixin("private import " ~ moduleName ~ ";");
        import std.meta : Alias;

        private alias mod = Alias!(mixin(moduleName));

        alias ModuleMembers = __traits(allMembers, mod);
    }

    alias MetaMembers = Module!(__MODULE__).ModuleMembers;
    static assert(MetaMembers.length > 0);

    alias ArrayMembers = Module!"array_example".ModuleMembers;
    static assert(ArrayMembers.length > 0);
}
