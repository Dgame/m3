module m3.File;

private:

static import m3.m3;

enum char[1] READ = "r";
enum char[1] WRITE = "w";
enum char[2] READ_BINARY = "rb";
enum char[2] WRITE_BINARY = "wb";

public:

@trusted
@nogc
char[] read(const string filename) nothrow {
    import std.c.stdio : FILE, SEEK_END, SEEK_SET, fopen, fclose, fseek, ftell, fread;

    FILE* f = fopen(filename.ptr, READ_BINARY);
    scope(exit) fclose(f);
    
    fseek(f, 0, SEEK_END);
    immutable size_t fsize = ftell(f);
    fseek(f, 0, SEEK_SET);

    char[] str = m3.m3.make!(char[])(fsize);
    fread(str.ptr, fsize, 1, f);

    return str;
}

@trusted
@nogc
void write(T : U[], U)(const string filename, const T content) nothrow {
    import std.c.stdio : FILE, fopen, fclose, fwrite;

    FILE* f = fopen(filename.ptr, WRITE_BINARY);
    scope(exit) fclose(f);
    
    enum size_t size = m3.m3.SizeOf!(U);
    fwrite(content.ptr, size, content.length * size, f);
}

@trusted
@nogc
@property
wchar[] toUTF16(const char[] s) {
    wchar[] r = m3.m3.make!(wchar[])(s.length); // r will never be longer than s
    foreach (immutable size_t i, wchar c; s) {
        r[i] = c;
    }

    return r;
}

@trusted
@nogc
@property
dchar[] toUTF32(const char[] s) {
    dchar[] r = m3.m3.make!(dchar[])(s.length); // r will never be longer than s
    foreach (immutable size_t i, dchar c; s) {
        r[i] = c;
    }

    return r;
}

@trusted
@nogc
unittest {
    char[] str = read("test_file.txt");
    scope(exit) m3.m3.destruct(str);

    dchar[] str2 = str.toUTF32;
    wchar[] str3 = str.toUTF16;

    scope(exit) m3.m3.destruct(str2);
    scope(exit) m3.m3.destruct(str3);

    assert(195 == cast(int) str[0]);
    assert(228 == cast(int) str2[0]);
    assert(228 == cast(int) str3[0]);

    assert(char.sizeof == 1);
    assert(wchar.sizeof == 2);
    assert(dchar.sizeof == 4);
}