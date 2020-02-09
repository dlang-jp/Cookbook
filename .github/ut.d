module ut;

version (DubTest)
{

}
else
{
    void main() {}
}

static this()
{
    import core.runtime;
    import std.file, std.path;
    enum rootDir = __FILE__.dirName.dirName.buildNormalizedPath();
    enum covDir  = rootDir.buildNormalizedPath(".cov");
    dmd_coverDestPath(covDir);
    dmd_coverSourcePath(rootDir);
    dmd_coverSetMerge(true);
}
