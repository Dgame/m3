module m3.m3;

private:

static import core.stdc.stdlib;
alias malloc = core.stdc.stdlib.malloc;
alias realloc = core.stdc.stdlib.realloc;
alias free = core.stdc.stdlib.free;

static import std.traits;
alias isArray = std.traits.isArray;

static import std.typecons;
alias TypeTuple = std.typecons.TypeTuple;

enum CTOR = "__ctor";
enum DTOR = "__dtor";

package:

debug static import core.stdc.stdio;
debug alias printf = core.stdc.stdio.printf;

public:

/* Class and Struct */

template DimOf(T) {
    static assert(!is(T : V[K], V, K), "Cannot figure out the dimension of an assocative array.");

    static if (is(T : U[], U))
        enum size_t DimOf = 1 + DimOf!(U);
    else static if (is(T : U*, U))
        enum size_t DimOf = 1 + DimOf!(U);
    else
        enum size_t DimOf = 0;
}

unittest {
    static assert(DimOf!(void) == 0);
    static assert(DimOf!(void[]) == 1);
    static assert(DimOf!(void[][]) == 2);

    static assert(DimOf!(int) == 0);
    static assert(DimOf!(int[]) == 1);
    static assert(DimOf!(int[][]) == 2);
    static assert(DimOf!(int[][][]) == 3);

    static assert(DimOf!(string) == 1);
    static assert(DimOf!(string[]) == 2);

    static assert(DimOf!(int*) == 1);
    static assert(DimOf!(int**) == 2);
    static assert(DimOf!(int[]**) == 3);
    static assert(DimOf!(int[]*[]*) == 4);
}

template BasicTypeOf(T) {
    static assert(!is(T : V[K], V, K), "Cannot figure out the basic type of an assocative array.");

    static if (is(T : U[], U))
        alias BasicTypeOf = BasicTypeOf!(U);
    else
        alias BasicTypeOf = T;
}

unittest {
    static assert(is(BasicTypeOf!(void) == void));
    static assert(is(BasicTypeOf!(void[]) == void));
    static assert(is(BasicTypeOf!(void[][]) == void));

    static assert(is(BasicTypeOf!(int) == int));
    static assert(is(BasicTypeOf!(int[]) == int));
    static assert(is(BasicTypeOf!(int[][]) == int));
    static assert(is(BasicTypeOf!(int[][][]) == int));

    static assert(is(BasicTypeOf!(string) == immutable(char)));
    static assert(is(BasicTypeOf!(string[]) == immutable(char)));
}

template NextTypeOf(T) {
    static assert(!is(T : V[K], V, K), "Cannot figure out the next type of an assocative array.");

    static if (is(T : U[], U))
        alias NextTypeOf = U;
    else
        alias NextTypeOf = T;
}

unittest {
    static assert(is(NextTypeOf!(void) == void));
    static assert(is(NextTypeOf!(void[]) == void));
    static assert(is(NextTypeOf!(void[][]) == void[]));

    static assert(is(NextTypeOf!(int) == int));
    static assert(is(NextTypeOf!(int[]) == int));
    static assert(is(NextTypeOf!(int[][]) == int[]));
    static assert(is(NextTypeOf!(int[][][]) == int[][]));

    static assert(is(NextTypeOf!(string) == immutable(char)));
    static assert(is(NextTypeOf!(string[]) == string));
}

template SizeOf(T) {
    static assert(!is(T : V[K], V, K), "Cannot figure out the size of an assocative array.");

    static if (is(T == class))
        enum size_t SizeOf = __traits(classInstanceSize, T);
    else
        enum size_t SizeOf = T.sizeof;
}

unittest {
    static assert(SizeOf!(void) == 1);
    static assert(SizeOf!(void[]) == 8);
    static assert(SizeOf!(void[][]) == 8);

    static assert(SizeOf!(int) == 4);
    static assert(SizeOf!(int[]) == 8);
    static assert(SizeOf!(int[][]) == 8);
    static assert(SizeOf!(int[][][]) == 8);

    static assert(SizeOf!(string) == 8);
    static assert(SizeOf!(string[]) == 8);
}

enum TypeOfClass : ubyte {
    AsClass,
    AsVoid
}

template TypeOf(T, TypeOfClass toc = TypeOfClass.AsClass) {
    static assert(!is(T : V[K], V, K), "Cannot figure out the type of an assocative array.");

    static if (isArray!(T)) {
        enum size_t DIM = DimOf!(T);
        static assert(DIM < 5, "Too high dimension");

        alias Base = BasicTypeOf!(T);
        static if (is(Base == class))
            alias Bases = TypeTuple!(void**, void**, void***, void****, void*****);
        else
            alias Bases = TypeTuple!(Base*, Base*, Base**, Base***, Base****);

        alias TypeOf = Bases[DIM];
    } else static if (is(T == class)) {
        static if (toc == TypeOfClass.AsVoid)
            alias TypeOf = void*;
        else
            alias TypeOf = T;
    } else
        alias TypeOf = T*;
}

unittest {
    static assert(is(TypeOf!(void) == void*));
    static assert(is(TypeOf!(void[]) == void*));
    static assert(is(TypeOf!(void[][]) == void**));

    static assert(is(TypeOf!(int) == int*));
    static assert(is(TypeOf!(int[]) == int*));
    static assert(is(TypeOf!(int[][]) == int**));
    static assert(is(TypeOf!(int[][][]) == int***));

    static assert(is(TypeOf!(string) == immutable(char)*));
    static assert(is(TypeOf!(string[]) == immutable(char)**));
}

template ArrayPtrTypeOf(T) {
    static if (isArray!(T))
        alias ArrayPtrTypeOf = TypeOf!(T);
    else static if (is(T == class))
        alias ArrayPtrTypeOf = void**;
    else
        alias ArrayPtrTypeOf = T*;
}

unittest {
    class _C { }
    struct _D { }

    static assert(is(ArrayPtrTypeOf!(_C) == void**));
    static assert(is(ArrayPtrTypeOf!(_D) == _D*));
    static assert(is(ArrayPtrTypeOf!(int) == int*));
    static assert(is(ArrayPtrTypeOf!(void) == void*));
    static assert(is(ArrayPtrTypeOf!(int[]) == int*));
    static assert(is(ArrayPtrTypeOf!(void[]) == void*));
}

@nogc
auto emplace(T, Args...)(void[] buf, auto ref Args args) if (is(T == class) || is(T == struct)) {
    enum size_t SIZE = SizeOf!(T);
    assert(buf.length == SIZE, "No enough space in buf");
    alias Type = TypeOf!(T);

    static if (is(T == class)) {
        buf[] = typeid(T).init[];
        debug printf("Emplace class %s\n", &T.stringof[0]);
    }

    Type tp = cast(Type) buf.ptr;

    static if (is(T == struct)) {
        *tp = T.init;
        debug printf("Emplace struct %s\n", &T.stringof[0]);
    }

    static if (args.length != 0) {
        static assert(__traits(hasMember, T, CTOR), "No CTor for type " ~ T.stringof);
        tp.__ctor(args);
    }

    return tp;
}

@nogc
auto make(T, Args...)(auto ref Args args) if (is(T == class) || is(T == struct)) {
    enum size_t SIZE = SizeOf!(T);
    void* p = malloc(SIZE);

    debug printf("Make %s : %p\n", &T.stringof[0], p);
        
    return emplace!(T)(p[0 .. SIZE], args);
}

@nogc
auto make(T, Args...)(auto ref Args args) if (!isArray!(T) && !is(T == class) && !is(T == struct)) {
    enum size_t SIZE = SizeOf!(T);
    T* p = cast(T*) malloc(SIZE);

    static if (!is(T == void)) {
        static if (args.length == 0)
            *p = T.init;
        else {
            static assert(args.length == 1, "Too many parameters!");
            *p = args[0];
        }
    } else {
        static assert(args.length == 0, "void cannot have arguments");
    }

    return p;
}

@nogc
void destruct(T)(T obj) if (is(T == class)) {
    if (obj) {
        static if (__traits(hasMember, T, DTOR))
            obj.__dtor();
        debug printf("Release class %s : %p\n", &T.stringof[0], cast(void*) obj);
        
        free(cast(void*) obj);
        obj = null;
    }
}

@nogc
void destruct(T)(T* p) if (!is(T == class)) {
    if (p) {
        static if (is(T == struct)) {
            static if (__traits(hasMember, T, DTOR))
                p.__dtor();
            debug printf("Release struct %s: %p\n", &T.stringof[0], p);
        }

        free(p);
        p = null;
    }
}

/* Array */

@nogc
T make(T)(size_t n) if (isArray!(T)) {
    alias Base = BasicTypeOf!(T);
    alias Next = NextTypeOf!(T);
    enum size_t SIZE = SizeOf!(Next);

    void* p = malloc(n * SIZE);

    static if (is(Base == class)) {
        alias Type = TypeOf!(T);

        T arr = cast(T) (cast(Type) p)[0 .. n];
    }  else
        T arr = (cast(Next*) p)[0 .. n];

    static if (!is(Base == void))
        arr[0 .. n] = Next.init;

    return arr;
}

@nogc
T* reserve(T)(T* ptr, size_t size) if (!isArray!(T) && !is(T == class)) {
    enum size_t SIZE = SizeOf!(T);

    return cast(T*) realloc(ptr, size * SIZE);
}

@nogc
T reserve(T)(ref T arr, size_t size) if (isArray!(T)) {
    alias Base = BasicTypeOf!(T);
    alias Next = NextTypeOf!(T);
    
    immutable size_t olen = arr.length;
    immutable size_t nlen = olen + size;

    static if (is(Base == class)) {
        alias Type = TypeOf!(T);

        arr = cast(T) reserve(cast(Type) arr.ptr, nlen)[0 .. nlen];
    } else
        arr = reserve(arr.ptr, nlen)[0 .. nlen];

    for (size_t i = olen; i < nlen; i++) {
        arr[i] = Next.init;
    }

    return arr;
}

@nogc
T append(T, Args...)(ref T arr, auto ref Args args) if (isArray!(T)) {
    if (arr.length != 0 && args.length != 0) {
        immutable size_t olen = arr.length;
        immutable size_t nlen = olen + args.length;
        
        alias Base = BasicTypeOf!(T);
        static if (is(Base == class)) {
            alias Type = TypeOf!(T);

            arr = reserve(cast(Type) arr.ptr, nlen)[0 .. nlen];
        } else
            arr = reserve(arr.ptr, nlen)[0 .. nlen];
        
        size_t i = olen;
        foreach (arg; args) {
            arr[i++] = arg;
        }
    }
               
    return arr;
}

@nogc
void destruct(T)(ref T arr) if (isArray!(T)) {
    if (arr.ptr) {
        alias Base = BasicTypeOf!(T);

        static if (__traits(hasMember, Base, DTOR)) {
            enum size_t DIM = DimOf!(T);

            static if (DIM > 1) {
                for (size_t i = 0; i < DIM; i++) {
                    foreach (ref Base item; arr[i]) {
                        item.__dtor();
                    }
                }
            } else {
                foreach (ref Base item; arr) {
                    item.__dtor();
                }
            }
        }
        
        free(arr.ptr);
        arr = null;
    }
}

version (unittest) {
    class A {
    @nogc:
        int id = 23;

        this(int i) {
            this.id = i;
        }
        
        ~this() {
            debug printf("DTor A\n");
        }
        
        int getId() const {
            return this.id;
        }
    }

    class B : A {
    @nogc:
        this(int i) {
            super(i);
        }
        
        ~this() {
            debug printf("DTor B\n");
        }
    }

    struct C {
    @nogc:
        int id = 42;
        
        this(int i) {
            this.id = i;
        }

        ~this() {
            debug printf("DTor C\n");
        }
        
        int getId() const {
            return this.id;
        }
    }
}

@nogc
unittest {
    void[] mem = make!(void[])(23);
    scope(exit) destruct(mem);

    assert(mem.length == 23);

    int[] arr = make!(int[])(42);
    scope(exit) destruct(arr);

    assert(arr.length == 42);

    int[] slice = arr[10 .. 20];
    assert(slice.length == 10);

    string[] arr2 = make!(string[])(2);
    scope(exit) destruct(arr2);

    assert(arr2.length == 2);

    assert(arr2[0].length == 0);
    assert(arr2[1].length == 0);

    arr2[0] = "Foo";
    arr2[1] = "Quatz";

    assert(arr2[0].length == 3);
    assert(arr2[1].length == 5);

    assert(arr2[0] == "Foo");
    assert(arr2[1] == "Quatz");

    int* p1 = make!(int)();
    int* p2 = make!(int)(1);
    int** p3 = make!(int*)(make!(int)(42));

    assert(p1);
    assert(p2);
    assert(p3);
    assert(*p3);

    assert(*p1 == 0);
    assert(*p2 == 1);
    assert(**p3 == 42);

    debug printf("A.sizeof = %d, B.sizeof = %d, C.sizeof = %d\n",
        __traits(classInstanceSize, A), __traits(classInstanceSize, B), C.sizeof);

    arr[0] = 42;
    assert(arr.length == 42);
    assert(arr[0] == 42);

    arr.append(23);
    assert(arr.length == 43);
    assert(arr[0] == 42);
    assert(arr[$ - 1] == 23);

    arr.append(4, 2, 3);
    assert(arr.length == 46);
    assert(arr[0] == 42);
    assert(arr[$ - 1] == 3);
    assert(arr[$ - 2] == 2);
    assert(arr[$ - 3] == 4);
    assert(arr[$ - 4] == 23);
    
    A a = make!(A)(42);
    assert(a.id == 42 && a.getId() == 42);
    
    B b = make!(B)(23);
    assert(b.id == 23 && b.getId() == 23);
    
    destruct(a);
    destruct(b);
    
    C* c = make!(C);
    assert(c.id == 42 && c.getId() == 42);
    
    destruct(c);

    void[__traits(classInstanceSize, A)] buf = void;
    A as = emplace!(A)(buf[]);
    assert(as.id == 23 && as.getId() == 23);

    void[__traits(classInstanceSize, A)] buf2 = void;
    A as2 = emplace!(A)(buf2[], 42);
    assert(as2.id == 42 && as2.getId() == 42);

    void[SizeOf!(A)] buf3 = void;
    A as3 = emplace!(A)(buf3[], 23);
    assert(as3.id == 23 && as3.getId() == 23);

    /** class array #1 */

    A[] aarr;
    aarr.reserve(42);
    scope(exit) destruct(aarr);

    debug printf("aarr.length = %d\n", aarr.length);

    assert(aarr.length == 42);
    for (size_t i = 0; i < 42; i++) {
        assert(aarr[i] is null);
    }

    aarr[0] = as;
    aarr[1] = as2;
    aarr[2] = as3;

    assert(aarr[0] is as);
    assert(aarr[0] !is null);

    assert(aarr[1] is as2);
    assert(aarr[1] !is null);

    assert(aarr[2] is as3);
    assert(aarr[2] !is null);

    assert(aarr.length == 42);
    for (size_t i = 3; i < 42; i++) {
        assert(aarr[i] is null);
    }

    /** class array #2 */

    A[] aarr2 = make!(A[])(42);
    scope(exit) destruct(aarr2);

    debug printf("aarr2.length = %d\n", aarr2.length);

    assert(aarr2.length == 42);
    for (size_t i = 0; i < 42; i++) {
        assert(aarr2[i] is null);
    }

    aarr2[0] = as;
    aarr2[1] = as2;
    aarr2[2] = as3;

    assert(aarr2[0] is as);
    assert(aarr2[0] !is null);

    assert(aarr2[1] is as2);
    assert(aarr2[1] !is null);
    
    assert(aarr2[2] is as3);
    assert(aarr2[2] !is null);

    assert(aarr2.length == 42);
    for (size_t i = 3; i < 42; i++) {
        assert(aarr2[i] is null);
    }

    /** struct array #1 */

    C[] carr;
    carr.reserve(23);
    scope(exit) destruct(carr);

    debug printf("carr.length = %d\n", carr.length);

    assert(carr.length == 23);
    for (size_t i = 0; i < 23; i++) {
        assert(carr[i].id == 42);
    }

    carr[0].id = 1;
    carr[1].id = 2;
    carr[2].id = 3;

    assert(carr[0].id == 1);
    assert(carr[1].id == 2);
    assert(carr[2].id == 3);

    assert(carr.length == 23);
    for (size_t i = 3; i < 23; i++) {
        assert(carr[i].id == 42);
    }
    
    /** struct array #2 */

    C[] carr2 = make!(C[])(23);
    scope(exit) destruct(carr2);

    debug printf("carr2.length = %d\n", carr2.length);

    assert(carr2.length == 23);
    for (size_t i = 0; i < 23; i++) {
        assert(carr2[i].id == 42);
    }

    carr2[0].id = 1;
    carr2[1].id = 2;
    carr2[2].id = 3;

    assert(carr2[0].id == 1);
    assert(carr2[1].id == 2);
    assert(carr2[2].id == 3);

    assert(carr2.length == 23);
    for (size_t i = 3; i < 23; i++) {
        assert(carr2[i].id == 42);
    }
}