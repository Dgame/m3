module m3.Transform;

private:

static import core.stdc.stdlib;
alias strtol = core.stdc.stdlib.strtol;
alias strtoul = core.stdc.stdlib.strtoul;
alias strtof = core.stdc.stdlib.strtof;
alias strtod = core.stdc.stdlib.strtod;

static import core.stdc.stdio;
alias sprintf = core.stdc.stdio.sprintf;

static import core.stdc.string;
alias strlen = core.stdc.string.strlen;
alias strtok = core.stdc.string.strtok;

static import std.traits;
alias isNumeric = std.traits.isNumeric;
alias isBoolean = std.traits.isBoolean;
alias isSomeString = std.traits.isSomeString;
alias isSomeChar = std.traits.isSomeChar;

static import m3.m3;

public:

@nogc
T convert(T)(string str) nothrow if (isNumeric!(T) || isBoolean!(T)) {
    static if (is(T : ulong)) {
        immutable ulong value = strtoul(str.ptr, null, 0);
        static if (is(T == ulong))
            return value;
        else
            return cast(T) value;
    } else static if (is(T : long)) {
        immutable long value = strtol(str.ptr, null, 0); 
        static if (is(T == long))
            return value;
        else
            return cast(T) value;
    } else static if (is(T == float))
        return strtof(str.ptr, null);
    else static if (is(T : real)) {
        immutable real value = strtod(str.ptr, null);
        static if (is(T == real))
            return value;
        else
            return cast(T) value;
    } else static if (is(T == bool))
        return strtol(str.ptr, null, 0);
    else
        static assert(0);
}

@nogc
string convert(T)(T value) nothrow if (isNumeric!(T) || isBoolean!(T)) {
    static char[16] buf;

    static if (is(T : ulong))
        sprintf(buf.ptr, "%u", value);
    else static if (is(T : long))
        sprintf(buf.ptr, "%d", value);
    else static if (is(T : real))
        sprintf(buf.ptr, "%f", value);
    else static if (is(T == bool))
        sprintf(buf.ptr, "%d", value);
    else
        static assert(0);

    return cast(immutable) buf[0 .. strlen(buf.ptr)];
}

@nogc
string format(size_t SIZE = 256, Args...)(string format, auto ref Args args) nothrow {
    static assert(SIZE >= (Args.length * 16));

    static char[SIZE] buf = void;

    size_t i = 0, j = 0;
    foreach (immutable size_t ai, arg; args) {
        for (; j < format.length; j++) {
            if (format[j] == '{') {
                if ((j + 1) < format.length && format[j + 1] == '}') {
                    static if (isSomeString!(Args[ai]))
                        immutable string s = arg;
                    else static if (isSomeChar!(Args[ai])) {
                        const char[1] str = arg;
                        immutable string s = cast(immutable) str;
                    } else static if (is(Args[ai] == class))
                        immutable string s = arg ? arg.toString() : null.stringof;
                    else static if (is(Args[ai] == struct))
                        immutable string s = arg.toString();
                    else static if (is(Args[ai] : U[], U))
                        static assert(0, "Arrays cannot be formated.");
                    else
                        immutable string s = convert(arg);

                    buf[i .. i + s.length] = s;

                    i += s.length;
                    j += 2;

                    break;
                }
            }

            buf[i] = format[j];
            i++;
        }
    }

    if (j < format.length) {
        immutable size_t r = format.length - j;
        buf[i .. i + r] = format[j .. $];

        i += r;
    }

    return cast(immutable) buf[0 .. i];
}

@nogc
string[] split(string str, char delim) nothrow {
    size_t count = 0;
    foreach (char c; str) {
        if (c == delim)
            count++;
    }

    if (count == 0)
        return null;

    count++;

    string[] result = m3.m3.make!(string[])(count);
    size_t i = 0;

    char* p = strtok(cast(char*) str.ptr, &delim);
    result[i++] = cast(immutable) p[0 .. strlen(p)];

    while (count > i) {
        p = strtok(null, &delim);
        if (p)
            result[i++] = cast(immutable) p[0 .. strlen(p)];
        else
            break;
    }

    return result;
}

version (unittest) {
    class A {
        @nogc
        override string toString() const pure nothrow {
            return "A";
        }
    }

    struct B {
        @nogc
        string toString() const pure nothrow {
            return "B";
        }
    }
}

@nogc
unittest {
    // Convert to

    assert(convert!(int)("152") == 152);
    assert(convert!(uint)("152") == 152);

    assert(convert!(byte)("152"));
    assert(convert!(ubyte)("152") == 152);

    assert(convert!(short)("152") == 152);
    assert(convert!(ushort)("152") == 152);

    assert(convert!(long)("152") == 152);
    assert(convert!(ulong)("152") == 152);

    assert(convert!(int)("152.52") == 152);

    assert(convert!(float)("152.52") is 152.52f);
    assert(convert!(double)("152.52") == 152.52);
    //assert(convert!(real)("152.52") == real(152.52));

    // Convert from

    assert(convert(152) == "152");
    assert(convert(152.52f) == "152.520004");
    assert(convert(152.52) == "152.520000");
    assert(convert(false) == "0");
    assert(convert(true) == "1");

    // Format

    assert(format("test_{}.png", 1) == "test_1.png");
    assert(format("test_{}.png", '0') == "test_0.png");
    assert(format("{} + {} = {}", 42, 23, 42 + 23) == "42 + 23 = 65");
    assert(format("Erst kommt die {}, dann die {} und am Ende die {}. Nicht zu vergessen die {}, die kommt vor {}.", 11, 12, 42, 23, 42) ==
        "Erst kommt die 11, dann die 12 und am Ende die 42. Nicht zu vergessen die 23, die kommt vor 42.");
    assert(format("Hallo {}, ich bin {} und {} Jahre alt.", "Foo", "Bar", 42) == "Hallo Foo, ich bin Bar und 42 Jahre alt.");

    const int[2] iarr = [1, 2];
    assert(!__traits(compiles, { format("Foo {} Bar", iarr); }));

    A a;
    B b;

    assert(format(" A : {}, B = {}", a, b) == " A : null, B = B");

    // split

    string str = "Foo:Bar:Quatz";
    auto result = str.split(':');

    assert(result.length == 3);
    assert(result[0] == "Foo");
    assert(result[1] == "Bar");
    assert(result[2] == "Quatz");

    m3.m3.destruct(result);
}