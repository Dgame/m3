module m3.m3;

private:

static import core.stdc.stdlib;
alias malloc = core.stdc.stdlib.malloc;
alias calloc = core.stdc.stdlib.calloc;
alias realloc = core.stdc.stdlib.realloc;
alias free = core.stdc.stdlib.free;

static import core.stdc.string;
alias memset = core.stdc.string.memset;

enum CTOR = "__ctor";
enum DTOR = "__dtor";

package:

debug static import core.stdc.stdio;
debug alias printf = core.stdc.stdio.printf;

public:

/* Class and Struct */

@nogc
template SizeOf(T) {
    static if (is(T == class))
        enum size_t SizeOf = __traits(classInstanceSize, T);
    else
        enum size_t SizeOf = T.sizeof;
}

@nogc
template TypeOf(T) {
    static if (is(T == class))
        alias TypeOf = T;
    else
        alias TypeOf = T*;
}

@nogc
template PointerTypeOf(T) {
    static if (is(T == class))
        alias PointerTypeOf = void*;
    else
        alias PointerTypeOf = T*;
}

@nogc
auto emplace(T, Args...)(void[] buf, auto ref Args args) if (is(T == class) || is(T == struct)) {
    enum size_t SIZE = SizeOf!(T);
    assert(buf.length == SIZE);
    alias Type = TypeOf!(T);

    static if (is(T == class)) {
        buf[] = typeid(T).init[];
        debug printf("Emplace class %s\n", &T.stringof[0]);
    } else {
        memset(buf.ptr, 0, SIZE);
        debug printf("Emplace struct %s\n", &T.stringof[0]);
    }

    Type tp = cast(Type) buf.ptr;
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
auto make(T, Args...)(auto ref Args args) if (!is(T : U[], U) && !is(T == class) && !is(T == struct)) {
    enum size_t SIZE = SizeOf!(T);

    static if (args.length == 0)
        return cast(T*) calloc(SIZE, 1);
    else {
        static assert(args.length == 1, "Too many parameter!");

        T* p = cast(T*) malloc(SIZE);
        *p = args[0];

        return p;
    }
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
T make(T : U[], U)(size_t n) nothrow {
    enum size_t SIZE = SizeOf!(T);

    return (cast(U*) calloc(SIZE, n))[0 .. n];
}

@nogc
T* reserve(T)(T* ptr, size_t size) nothrow if (!is(T : U[], U) && !is(T == class)) {
    enum size_t SIZE = SizeOf!(T);

    ptr = cast(T*) realloc(ptr, size * SIZE);
    return ptr;
}

@nogc
T append(T : U[], U, Args...)(ref T arr, auto ref Args args) nothrow {
    if (arr.length != 0 && args.length != 0) {
        immutable size_t olen = arr.length;
        immutable size_t nlen = olen + args.length;
        
        arr = reserve(arr.ptr, nlen)[0 .. nlen];
        
        size_t i = olen;
        foreach (arg; args) {
            arr[i++] = arg;
        }
    }
               
    return arr;
}

@nogc
void destruct(T : U[], U)(ref T arr) nothrow {
    if (arr.ptr) {
        static if (__traits(hasMember, U, DTOR)) {
            foreach (ref U item; arr) {
                item.__dtor();
            }
        }
        
        free(arr.ptr);
        arr = null;
    }
}

version (unittest) {
    class A {
    @nogc:

        int id;

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

        int id;
        
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
    int[] arr = make!(int[])(42);
    assert(arr.length == 42);

    int[] slice = arr[10 .. 20];
    assert(slice.length == 10);

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

    scope(exit) destruct(arr);
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
    assert(c.id == 0 && c.getId() == 0);
    
    destruct(c);

    void[__traits(classInstanceSize, A)] buf = void;
    A as = emplace!(A)(buf[]);
    assert(as.id == 0 && as.getId() == 0);

    void[__traits(classInstanceSize, A)] buf2 = void;
    A as2 = emplace!(A)(buf2[], 42);
    assert(as2.id == 42 && as2.getId() == 42);

    void[SizeOf!(A)] buf3 = void;
    A as3 = emplace!(A)(buf3[], 23);
    assert(as3.id == 23 && as3.getId() == 23);
}