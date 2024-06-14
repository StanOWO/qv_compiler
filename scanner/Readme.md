# qv: A Minimal Experimental Language for Learning Compilers
# Introduction

- qv is a minimal experimental language with modern syntax, targeting vector, matrix, and string operations.
- qv is case sensitive; *VECTOR*, *Vector*, and *vector* are all different identifiers.
- All keywords in qv are reserved words:
    - Define variables and constants: *var*, *val*
    - Reserved words for scalar types: *bool*, *char*, *int*, *real.* We will define *vectorized* types later.
    - Reserved words for values: *true*, *false*
    - Reserved words for customized types: *class*
    - Reserved words for program flow control: *if*, *else*, *for*, *while*, *do*, *switch*, *case*
    - Reserved words related to functions: *fun* (for declaring/defining functions), *ret* (return results of functions)
- Literal constants
    - Integer literal constant, e.g., 0, 123456, and -123456, of type *int*.
        - The minus sign ‘-’ cannot be distinguished from the subtract operator ‘-’ in flex, because they use the same character. We leave the handling of ‘-’ to the parser.
    - Real number literal constant, e.g., 0.0, 123.456, and -12.2345, of type real.
    - Boolean literal constants, i.e., true and false.
- Variable names (identifiers) follow the same rule as C/C++. They start with a-z, A-Z, or underscore, followed by a-z, A-Z, underscore, or 0-9.
- Other tokens:
    - ‘, “
    - (, ), [, ], {, }
    - ,, ;, :
    - +, -, *, /
    - = (assignment)
    - == (equality comparison), != (inequality comparison)
    - \> (larger-than), < (smaller-than), >= (larger-than-or-equal-to), <= (smaller-than-or-equal-to)
    - Escape sequences: ‘\n’, ‘\t’, ‘\\’, ‘\'’, ‘\"’, ‘\?’