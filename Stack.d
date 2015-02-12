module m3.Stack;

private:

static import m3.m3;

debug alias printf = m3.m3.printf;

public:

struct Stack(T) {
    static assert(!is(T : U[], U), "Stack cannot be used with an array");

static struct Node {
    T value;
    Node* previous = null;
}

private:
    Node* _end;
    size_t _length;

public:

    @trusted
    @nogc
    ~this() {
        Node* cur = _end;
        while (cur) {
            debug printf("Destroy Stack\n");
            Node* tmp = cur;
            cur = tmp.previous;
            m3.m3.destruct(tmp);
        }
    }

    @trusted
    @nogc
    @property
    size_t length() const pure nothrow {
        return _length;
    }

    @trusted
    @nogc
    @property
    inout(Node*) top() inout pure nothrow {
        return _end;
    }

    @trusted
    @nogc
    void push(U : T)(auto ref U item) nothrow {
        Node* newEnd = m3.m3.make!(Node);
        newEnd.value = item;
        newEnd.previous = _end;

        _end = newEnd;
        _length++;
    }

    @trusted
    @nogc
    void pop() nothrow {
        if (_end) {
            Node* oldEnd = _end;
            _end = _end.previous;
            m3.m3.destruct(oldEnd);

            _length--;
        }
    }
}

@trusted
@nogc
unittest {
    Stack!(char) stack;

    stack.push('H');
    assert(stack.top.value == 'H');

    stack.push('a');
    assert(stack.top.value == 'a');

    stack.pop();
    assert(stack.top.value == 'H');

    stack.pop();
    assert(!stack.top);
}