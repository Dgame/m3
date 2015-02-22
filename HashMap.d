private:

static import m3.m3;

debug alias printf = m3.m3.printf;

@safe
@nogc
size_t indexFor(size_t h, size_t size) pure nothrow {
    assert(size > 0);

    return h % (size - 1);
}

@trusted
@nogc
size_t hashOf(T)(auto ref const T data) pure nothrow if (!is(T : U[], U) && !is(T == class)) {
    return cast(size_t) &data;
}

unittest {
    struct A { }
    A a;

    assert(cast(size_t) &a == hashOf(a));

    const int b = 42;

    assert(cast(size_t) &b == hashOf(b));
}

@trusted
@nogc
size_t hashOf(T)(auto ref const T data) pure nothrow if (!is(T : U[], U) && is(T == class)) {
    return cast(size_t) cast(void*) &data;
}

unittest {
    class A { }
    A a = new A();

    assert(cast(size_t) cast(void*) &a == hashOf(a));
}

@safe
@nogc
size_t hashOf(T : U[], U)(auto ref const T data) pure nothrow {
    size_t hash = 0;
    for (size_t i = 0; i < data.length; i++) {
        hash = 5 * hash + cast(size_t)(data[i]);
    }

    return hash;
}

struct Entry(T) {
    T data;
    size_t hash;

    @nogc
    this(T d, size_t h) pure nothrow {
        this.data = d;
        this.hash = h;
    }
}

public:

struct HashMap(K, V, alias HashOf = hashOf, size_t INIT_CAPACITY = 16, float REHASH_PERCENT = 0.75f) {
    static assert(INIT_CAPACITY > 0);
    static assert(REHASH_PERCENT > 0);

private:
    Entry!(V)*[] _entries;
    size_t _length;
    size_t _capacity;

    @nogc
    void _rehash(size_t newCapacity) {
        if (newCapacity == 0)
            return;

        debug printf("Rehash: %d\n", newCapacity);

        immutable size_t old_capacity = _capacity;
        _capacity = newCapacity;

        _entries = m3.m3.reserve(_entries, _capacity);
        for (size_t i = 0; i < old_capacity; i++) {
            if (!_entries[i])
                continue;

            immutable size_t ni = indexFor(_entries[i].hash, _capacity);
            debug printf("Move hash %d from index %d to index %d\n", _entries[i].hash, i, ni);
            if (ni != i) {
                _entries[ni] = _entries[i];
                _entries[i] = null;
            }
        }
    }

    @nogc
    void _putEntry(size_t hash, size_t index, V value) {
        assert(_entries[index] is null);
        _entries[index] = m3.m3.make!(Entry!(V))(value, hash);
        _length++;
        
        debug printf("Put entry with hash %d on index %d\n", hash, index);
    }

public:
    @nogc
    ~this() {
        for (size_t i = 0; i < _capacity; i++) {
            if (_entries[i])
                m3.m3.destruct(_entries[i]);
        }

        m3.m3.destruct(_entries);
    }

    @nogc
    void clear() {
        _length = 0;

        for (size_t i = 0; i < _capacity; i++) {
            if (_entries[i])
                m3.m3.destruct(_entries[i]);
        }
    }

    @nogc
    inout(V*) get(K key) inout pure nothrow {
        if (_length == 0)
            return null;
        
        immutable size_t h = HashOf(key);
        immutable size_t i = indexFor(h, _capacity);
        
        debug printf("Get entry with hash %d on index %d\n", h, i);
        
        auto e = _entries[i];
        if (e)
            return &e.data;

        return null;
    }

    @nogc
    void put(K key, V value) {
        if (_length == 0)
            _rehash(INIT_CAPACITY);

        immutable size_t h = HashOf(key);
        immutable size_t i = indexFor(h, _capacity);

        auto e = _entries[i];
        if (e) { // collision -> override
            debug printf("Replace index %d with hash %d. Was before hash %d. Data: %d <-> %d\n", i, h, e.data, value);

            e.data = value;
            e.hash = h;
        } else {
            _putEntry(h, i, value);
            
            immutable float percent = float(_length) / _capacity;
            if (percent > REHASH_PERCENT)
                _rehash(_capacity * 2);
        }
    }

    @safe
    @property
    @nogc
    size_t length() const pure nothrow {
        return _length;
    }

    @safe
    @property
    @nogc
    size_t capacity() const pure nothrow {
        return _capacity;
    }

    @nogc
    void opIndexAssign(V value, K key) {
        this.put(key, value);
    }

    @nogc
    ref inout(V) opIndex(K key) inout pure nothrow {
        auto p = this.get(key);
        if (p)
            return *p;

        assert(0, "No such key found");
    }

    @nogc
    inout(V*) opBinaryRight(string op : "in")(K key) inout pure nothrow {
        return this.get(key);
    }
}

@nogc
unittest {
    // small rehash percent for testing
    HashMap!(string, size_t, hashOf, 16, 0.2f) telNr;

    assert(telNr.length == 0);
    assert(telNr.capacity == 0);

    telNr.put("Foo", 123);
    telNr.put("Bar", 456);

    assert(telNr.length == 2);
    assert(telNr.capacity == 16);

    auto a = telNr.get("Foo");
    auto b = telNr.get("Bar");

    assert(a);
    assert(b);
    assert(*a == 123);
    assert(*b == 456);
    
    telNr.put("Quatz", 753);
    telNr.put("Abc", 159);

    debug printf("Length = %d\n", telNr.length);
    debug printf("Capacity = %d\n", telNr.capacity);

    assert(telNr.length == 4);
    assert(telNr.capacity == 32);

    a = "Quatz" in telNr;
    assert(a);
    assert(*a == 753);

    a = "ABC" in telNr;
    assert(a is null);

    a = "Abc" in telNr;
    assert(a);
    assert(*a == 159);

    assert(telNr["Abc"] == 159);

    try {
        auto _ = telNr["ABC"];
    } catch (Error e) {
        assert(e.msg == "No such key found");
    }
}