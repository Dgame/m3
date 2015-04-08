module m3.Stack;

private:

static import m3.m3;

debug(m3) {
    static import core.stdc.stdio;
    alias printf = core.stdc.stdio.printf;
}

static import std.traits;
alias isArray = std.traits.isArray;

public:

struct Stack(T) {
    static assert(!isArray!(T), "Stack cannot be used with an array");

static struct Node {
    T value;
    Node* previous = null;
}

private:
    Node* _end;
    size_t _length;

public:
    @nogc
    ~this() {
        Node* cur = _end;
        while (cur) {
            debug(m3) printf("Destroy Stack\n");
            
            Node* tmp = cur;
            cur = tmp.previous;
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
    inout(Node*) top() inout pure nothrow {
        return _end;
    }

    @nogc
    void push(U : T)(auto ref U item) nothrow {
        Node* newEnd = m3.m3.make!(Node);
        newEnd.value = item;
        newEnd.previous = _end;

        _end = newEnd;
        _length++;
    }

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