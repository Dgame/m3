module m3.List;

private:

static import m3.m3;

static import std.traits;
alias isArray = std.traits.isArray;

public:

struct DoubleLinkedList(T) {
    static assert(!isArray!(T), "Double Linked List cannot be used with an array");

static struct Node {
    T value;
    Node* next = null;
    Node* previous = null;
}

private:
    Node* _front;
    Node* _end;

    size_t _length;

public:
    @nogc
    ~this() {
        Node* cur = _front;
        while (cur) {
            Node* tmp = cur;
            cur = tmp.next;
            m3.m3.destruct(tmp);
        }
    }

    @safe
    @nogc
    @property
    size_t length() const pure nothrow {
        return _length;
    }

    @nogc
    @property
    inout(Node*) front() inout pure nothrow {
        return _front;
    }

    @nogc
    @property
    inout(Node*) end() inout pure nothrow {
        return _end;
    }

    @nogc
    void pushBack(U : T)(auto ref U item) nothrow {
        Node* newEnd = m3.m3.make!(Node);
        newEnd.value = item;
        newEnd.previous = _end;

        if (_end)
            _end.next = newEnd;

        _end = newEnd;

        if (_length == 0)
            _front = _end;

        _length++;
    }

    @nogc
    void pushFront(U : T)(auto ref U item) nothrow {
        Node* newFront = m3.m3.make!(Node);
        newFront.value = item;
        newFront.next = _front;

        if (_front)
            _front.previous = newFront;

        _front = newFront;

        if (_length == 0)
            _end = _front;

        _length++;
    }

    @nogc
    void popBack() nothrow {
        if (_end) {
            Node* oldEnd = _end;

            _end = _end.previous;
            if (_end)
                _end.next = null;

            m3.m3.destruct(oldEnd);
            _length--;
        }
    }

    @nogc
    void popFront() nothrow {
        if (_front) {
            Node* oldFront = _front;

            _front = _front.next;
            if (_front)
                _front.previous = null;

            m3.m3.destruct(oldFront);
            _length--;
        }
    }

    @nogc
    void erase(Node* node) {
        if (!node)
            return;

        if (node is _end)
            return this.popBack();
        if (node is _front)
            return this.popFront();

        Node* next = node.next;
        Node* prev = node.previous;

        next.previous = prev;
        prev.next = next;

        m3.m3.destruct(node);
        _length--;
    }
}

@nogc
unittest {
    DoubleLinkedList!(char) dll;
    dll.pushBack('a');
    dll.pushFront('H');
    dll.pushBack('y');

    auto cur = dll.front;
    assert(cur.value == 'H');
    assert(cur.next.value == 'a');
    assert(cur.next.next.value == 'y');

    dll.popBack();
    cur = dll.front;

    assert(cur.value == 'H');
    assert(cur.next.value == 'a');

    dll.popBack();
    cur = dll.front;

    assert(cur.value == 'H');

    dll.pushBack('a');
    dll.pushBack('y');

    cur = dll.front;
    
    assert(cur.value == 'H');
    assert(cur.next.value == 'a');
    assert(cur.next.next.value == 'y');

    dll.popFront();
    cur = dll.front;
    
    assert(cur.value == 'a');
    assert(cur.next.value == 'y');

    dll.popFront();
    cur = dll.front;
    
    assert(cur.value == 'y');

    dll.pushBack('a');
    dll.pushBack('y');

    cur = dll.front;

    assert(cur.value == 'y');
    assert(cur.next.value == 'a');
    assert(cur.next.next.value == 'y');

    dll.erase(cur.next);
    cur = dll.front;

    assert(cur.value == 'y');
    assert(cur.next.value == 'y');
}