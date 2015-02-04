module m3.SmartPointer;

private:

static import m3.m3;

debug alias printf = m3.m3.printf;

public:

/* Unique Ptr */

struct UniquePtr(T) {
	static assert(!is(T : U[], U), "Arrays aren't allowed for UniquePtr");

	alias Type = m3.m3.TypeOf!(T);
	alias Deleter = void function(ref Type) @nogc;

	Type data;
	Deleter deleter;

	@trusted
	@nogc
	this(Type data, Deleter deleter = &m3.m3.destruct!(T)) nothrow {
		this.data = data;
		this.deleter = deleter;
	}

	@disable
	this(this);

	@trusted
	@nogc
	~this() {
		if (this.data)
			this.deleter(this.data);
	}

	@trusted
	@nogc
	Type release() pure nothrow {
		scope(exit) this.data = null;
		return this.data;
	}

	@trusted
	@nogc
	@property
	inout(Type) get() inout pure nothrow {
		return this.data;
	}

	alias get this;
}

@trusted
@nogc
UniquePtr!(T) makeUnique(T)(T* data) {
	return UniquePtr!(T)(data);
}

@trusted
@nogc
UniquePtr!(T) makeUnique(T)(T* data, UniquePtr!(T).Deleter deleter) {
	return UniquePtr!(T)(data, deleter);
}

@trusted
@nogc
UniquePtr!(T) makeUnique(T)(T data) if (is(T == class)) {
	return UniquePtr!(T)(data);
}

@trusted
@nogc
UniquePtr!(T) makeUnique(T)(T data, UniquePtr!(T).Deleter deleter) if (is(T == class)) {
	return UniquePtr!(T)(data, deleter);
}

@trusted
@nogc
UniquePtr!(T) makeUnique(T, Args...)(auto ref Args args) {
	return UniquePtr!(T)(m3.m3.make!(T)(args));
}

@trusted
@nogc
UniquePtr!(T) makeUnique(T, Args...)(UniquePtr!(T).Deleter deleter, auto ref Args args) {
	return UniquePtr!(T)(m3.m3.make!(T)(args), deleter);
}

/* Shared Ptr */

struct SharedPtr(T) {
	static assert(!is(T : U[], U), "Arrays aren't allowed for SharedPtr");

	static if (is(T == class))
		alias Type = T;
	else
		alias Type = T*;

	alias Deleter = void function(ref Type) @nogc;

	Type data;
	Deleter deleter;
	int* useCounter;

	@trusted
	@nogc
	this(Type data, Deleter deleter = &m3.m3.destruct!(T)) nothrow {
		this.data = data;
		this.deleter = deleter;
		this.useCounter = m3.m3.make!(int)(1);
	}

	@trusted
	@nogc
	this(this) {
		if (this.useCounter) {
			this.data = data;
			this.deleter = deleter;
			this.useCounter = useCounter;

			(*this.useCounter)++;
		}
	}

	@trusted
	@nogc
	~this() {
		if (this.useCounter) {
			(*this.useCounter)--;
			
			if (*this.useCounter <= 0) {
				this.deleter(this.data);
				m3.m3.destruct(this.useCounter);
			}
		}
	}

	@trusted
	@nogc
	Type release() pure nothrow {
		scope(exit) this.data = null;
		return this.data;
	}

	@trusted
	@nogc
	@property
	int useCount() const pure nothrow {
		return this.useCounter ? *this.useCounter : 0;
	}

	@trusted
	@nogc
	@property
	inout(Type) get() inout pure nothrow {
		return this.data;
	}

	alias get this;
}

@trusted
@nogc
SharedPtr!(T) makeShared(T)(T* data) {
	return SharedPtr!(T)(data);
}

@trusted
@nogc
SharedPtr!(T) makeShared(T)(T* data, SharedPtr!(T).Deleter deleter) {
	return SharedPtr!(T)(data, deleter);
}

@trusted
@nogc
SharedPtr!(T) makeShared(T)(T data) if (is(T == class)) {
	return SharedPtr!(T)(data);
}

@trusted
@nogc
SharedPtr!(T) makeShared(T)(T data, SharedPtr!(T).Deleter deleter) if (is(T == class)) {
	return SharedPtr!(T)(data, deleter);
}

@trusted
@nogc
SharedPtr!(T) makeShared(T, Args...)(auto ref Args args) {
	return SharedPtr!(T)(m3.m3.make!(T)(args));
}

@trusted
@nogc
SharedPtr!(T) makeShared(T, Args...)(SharedPtr!(T).Deleter deleter, auto ref Args args) {
	return SharedPtr!(T)(m3.m3.make!(T)(args), deleter);
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

@trusted
@nogc
unittest {
	UniquePtr!(C) uc = makeUnique!(C)(42);
	assert(uc.id == 42 && uc.getId() == 42);

	UniquePtr!(A) uc2 = makeUnique(m3.m3.make!(A)(23));
	assert(uc2.id == 23 && uc2.getId() == 23);

	UniquePtr!(A) uc3 = makeUnique!(A)(42);
	assert(uc3.id == 42 && uc3.getId() == 42);

	assert(!__traits(compiles, { auto uc4 = uc3; }));

	C* c = m3.m3.make!(C)(23);
	assert(c.id == 23 && c.getId() == 23);

	UniquePtr!(C) uc4 = makeUnique(c);
	assert(c == uc4.data);
	assert(uc4.id == c.id && uc4.getId() == c.getId());

	int[] arr = m3.m3.make!(int[])(42);
	UniquePtr!(int) uc5 = makeUnique(arr.ptr);
	assert(uc5.data == arr.ptr);
}

@trusted
@nogc
unittest {
	SharedPtr!(C) sc = makeShared!(C)(42);
	assert(sc.id == 42 && sc.getId() == 42);
	assert(sc.useCount == 1);

	SharedPtr!(A) sc2 = makeShared(m3.m3.make!(A)(23));
	assert(sc2.id == 23 && sc2.getId() == 23);
	assert(sc2.useCount == 1);

	SharedPtr!(A) sc3 = makeShared!(A)(42);
	assert(sc3.id == 42 && sc3.getId() == 42);
	assert(sc3.useCount == 1);

	{
		SharedPtr!(A) sc4 = sc3;
		assert(sc4.id == 42 && sc3.getId() == 42);
		assert(sc4.id == sc3.id && sc3.getId() == sc3.getId());
		assert(sc3.useCount == 2);
		assert(sc4.useCount == 2);
	}

	assert(sc3.useCount == 1);

	C* c = m3.m3.make!(C)(23);
	SharedPtr!(C) sc5 = makeShared(c);
	assert(c == sc5.data);
	assert(sc5.id == c.id && sc5.getId() == c.getId());

	int[] arr = m3.m3.make!(int[])(42);
	SharedPtr!(int) sc6 = makeShared(arr.ptr);
	assert(sc6.data == arr.ptr);
}