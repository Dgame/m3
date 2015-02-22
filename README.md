# m3
###manual memory management for the D programming language

**m3 is an attempt to use the most important parts of the language without a GC**

Currently you can

 - use a shared and a unique pointer which manage the lifetimes
 - use a dynamic array (similar to D's builtin dynamic arrays or std::vector from C++)
 - use a double linked list
 - use a stack
 - use a HashMap (similar to D's builtin associative arrays or std::map from C++)
 - allocate arrays
 - append existing arrays
 - allocate and assign structs and basic types
 - allocate classes on stack and heap
 - convert basic types from and to strings
 - format strings
 - read from files and write to files
 - convert your data to UTF16 and UTF32
