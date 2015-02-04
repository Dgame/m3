# m3
###manual memory management for the D programming language

**m3 is an attempt to use the most important parts of the language without a GC.**

Currently you can

 - read and write to and from files
 - convert your data to UTF16 and UTF32.
 - cuse a shared and a unique pointer which manage the lifetimes
 - use a dynamic array (similar to std::vector from C++)
 - use a double linked list
 - use a stack
 - allocate arrays
 - append existing arrays
 - allocate and assign structs and basic types
 - allocate classes on stack and heap
