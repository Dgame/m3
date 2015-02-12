module m3.Array;

private:

static import m3.m3;
debug alias printf = m3.m3.printf;

public:

/* Static Array */

@safe
@nogc
T[n] s(T, size_t n)(auto ref T[n] values) pure nothrow if (!is(T : U[], U)) {
    return values;
}

@safe
@nogc
unittest {
    auto arr1 = [1, 2, 3].s;
    assert(typeof(arr1).stringof == "int[3]");
    assert(arr1.length == 3);
}

/* Dynamic Array */

struct DynamicArray(T) {
    static assert(!is(T : U[], U), "DynamicArray cannot be used with an array");

    enum size_t OFFSET = 3;
    static assert(OFFSET > 0);

    alias PtrType = m3.m3.PointerTypeOf!(T);

private:
    static if (is(T == class))
        PtrType* _data;
    else
        T* _data;

    size_t _length;
    size_t _capacity;

public:

    @safe
    @nogc
    this(size_t size) nothrow {
        this.reserve(size);
    }

    @trusted
    @nogc
    this(T[] items) nothrow {
        _length = items.length;
        this.reserve(_length);

        for (size_t i = 0; i < _length; i++) {
            static if (is(T == class))
                _data[i] = cast(PtrType) items[i];
            else
                _data[i] = items[i];
        }
    }

    @safe
    @nogc
    ~this() {
        m3.m3.destruct(_data);
    }

    @safe
    @nogc
    void clear() pure nothrow {
        _length = 0;
    }

    @trusted
    @nogc
    T[] release() pure nothrow {
        scope(exit) {
            _data = null;
            this.clear();
        }

        static if (is(T == class))
            return cast(T[]) _data[0 .. _length];
        else
            return _data[0 .. _length];
    }

    @trusted
    @nogc
    DynamicArray!(T) copy() nothrow {
        static if (is(T == class))
            return DynamicArray!(T)(cast(T[]) _data[0 .. _length]);
        else
            return DynamicArray!(T)(_data[0 .. _length]);
    }

    @safe
    @nogc
    @property
    size_t length() const pure nothrow {
        return _length;
    }

    @safe
    @nogc
    @property
    size_t capacity() const pure nothrow {
        return _capacity;
    }

    @safe
    @nogc
    @property
    inout(PtrType) front() inout pure nothrow {
        return _data;
    }

    @trusted
    @nogc
    @property
    inout(PtrType) back() inout pure nothrow {
        return _data + _length - 1;
    }

    @trusted
    @nogc
    @property
    const(PtrType) begin() const pure nothrow {
        return _data - 1;
    }

    @trusted
    @nogc
    @property
    const(PtrType) end() const pure nothrow {
        return _data + _length;
    }

    @safe
    @nogc
    void reserve(size_t size) nothrow {
        if (size > _length) {
            _capacity += size;
            _data = m3.m3.reserve(_data, _capacity);
        }
    }

    @trusted
    @nogc
    void append(U : T)(auto ref U item) nothrow {
        if (_length == _capacity)
            this.reserve(_capacity + OFFSET);

        static if (is(T == class))
            _data[_length] = cast(PtrType) item;
        else
            _data[_length] = item;

        _length++;
    }

    @safe
    @nogc
    void append(U : T)(U[] items) nothrow {
        if ((_length + items.length) > _capacity)
            this.reserve(_capacity + items.length + OFFSET);

        foreach (ref U item; items) {
            this.append(item);
        }
    }

    @trusted
    @nogc
    auto ref inout(T) opIndex(size_t index) inout pure nothrow in {
        assert(index < _length);
    } body {
        static if (is(T == class))
            return cast(T) _data[index];
        else
            return _data[index];
    }

    @trusted
    @nogc
    void opIndexAssign(U : T)(auto ref U item, size_t index) pure nothrow in {
        assert(index < _length);
    } body {
        _data[index] = item;
    }

    @trusted
    @nogc
    inout(T[]) opSlice(size_t from, size_t too) inout pure nothrow in {
        assert(from < _length);
        assert(too < _length);
        assert(too > from);
    } body {
        static if (is(T == class))
            return cast(inout T[]) _data[from .. too];
        else
            return _data[from .. too];
    }

    @trusted
    @nogc
    inout(T[]) opSlice() inout pure nothrow {
        static if (is(T == class))
            return cast(inout T[]) _data[0 .. _length];
        else
            return _data[0 .. _length];
    }

    @trusted
    @nogc
    void opSliceAssign(U : T)(auto ref U item, size_t from, size_t too) pure nothrow in {
        assert(from < _length);
        assert(too < _length);
        assert(too > from);
    } body {
        _data[from .. too] = item;
    }

    @trusted
    @nogc
    void opSliceAssign(U : T)(auto ref U item) pure nothrow {
        _data[0 .. _length] = item;
    }

    @trusted
    @nogc
    void opSliceAssign(U : T)(auto ref U[] items, size_t from, size_t too) pure nothrow in {
        assert(from < _length);
        assert(too < _length);
        assert(too > from);
    } body {
        for (int i = from, j = 0; i < too; i++, j++) {
            _data[i] = items[j];
        }
    }
}

version (unittest) {
    class A {
    @nogc:
    @safe:

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
}

@trusted
@nogc
unittest {
    DynamicArray!(char) myStr;

    assert(myStr.length == 0);
    assert(myStr.capacity == 0);

    myStr.append('H');

    assert(myStr.length == 1);
    assert(myStr.capacity == 3);

    myStr.append('a');

    assert(myStr.length == 2);
    assert(myStr.capacity == 3);

    myStr.append('l');

    assert(myStr.length == 3);
    assert(myStr.capacity == 3);

    myStr.append('l');

    assert(myStr.length == 4);
    assert(myStr.capacity == 9);

    myStr.append('o');

    assert(myStr.length == 5);
    assert(myStr.capacity == 9);

    const char[5] hello = "Hallo";
    const char[5] meep = "-----";
    const char[2] moep = "++";

    for (int i = 0; i < 5; i++) {
        assert(myStr[i] == hello[i]);
    }

    assert(myStr[] == hello);
    assert(myStr[1 .. 4] == hello[1 .. 4]);

    myStr[] = '-';
    assert(myStr[] == meep);

    myStr[1 .. 3] = '+';
    assert(myStr[1 .. 3] == moep);

    myStr.append(hello[]);
    assert(myStr.length == 10);
    assert(myStr.capacity == 26);

    myStr[0 .. 5] = hello[];

    int i = 0;
    for (; i < 5; i++) {
        assert(myStr[i] == hello[i]);
    }

    for (int j = 0; i < 10; j++, i++) {
        assert(myStr[i] == hello[j]);
    }

    myStr[0] = 'h';
    assert(myStr[0] == 'h');

    assert(!__traits(compiles, { DynamicArray!(int[]) _; }));

    // Class test

    void[m3.m3.SizeOf!(A)] buf = void;
    A a1 = m3.m3.emplace!(A)(buf[], 42);
    assert(a1.id == 42 && a1.getId() == 42);

    // as void*

    DynamicArray!(void*) as;
    as.append(buf.ptr);

    assert(as.length == 1);
    assert(as.capacity == 3);

    A a2 = cast(A) as[0];
    assert(a2 is a1);
    assert(a2.id == 42 && a2.getId() == 42);

    // as class reference

    assert(__traits(compiles, { DynamicArray!(A) _; }));

    DynamicArray!(A) as2;

    as2.append(a1);

    assert(as2.length == 1);
    assert(as2.capacity == 3);

    A a3 = as2[0];
    assert(a3 is a1);
    assert(a3.id == 42 && a3.getId() == 42);
}