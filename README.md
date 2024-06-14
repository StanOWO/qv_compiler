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
# Scanner
- Scanner can scan every token aforementioned. If the token have value. It will also output
- The scanner will scan some scanner error, such as single backslash, character or string without end apostroph or quotation marks, and so forth
- There is an sh file  ``` make.sh ``` in scanner folder. You can compile it by inputting the following
```
sh make.sh
```

Example
```
fun main(){
    var length : int = 5;
}
```
It will output the following in the scanner
```
<281,FUN>
<283,MAIN>
<40,(>
<41,)>
<123,{>
<256,VAR>
<258,IDENTIFIER,length>
<58,:>
<259,INT>
<61,=>
<260,INTEGER,5>
<59,;>
<125,}>
```
# Parser
- Parser contains c code generator, and all the codes are put in an variable ```code```
- In qv language, there are some special expression in qv. In array addition, it will do Dimension-wise addition. In array multiplication, it will do inner product.
- There is a Makefile in parser folder. You can compiler it by inputting the following
```
make
```

Example
```
fun main () {
	var i: real = 1.5;
	var j: real = 3.14;
	var k: real = 2.8;
	print(i + j * k);
	print("\n");
	print(i * (j + k));
	print("\n");
}
```
It will generate the following c code
```
#include <stdio.h>

int main(){
        double i = 1.500000;
        double j = 3.140000;
        double k = 2.800000;
        printf("%lf", i + j * k);
        printf("%s", "\n");
        printf("%lf", i * (j + k));
        printf("%s", "\n");
        return(0);
}
```
Advanced example
```
fun main () {
	var vi1: real[5] = {5, 3, 4, 1, 2}; // vi1[0]~vi1[4]
	var vi2: real[5] = {2, -2, 4}; // Missing dimensions assumed 0s
	print( vi1 * vi2 ); // Inner product, output: "20"
	print( "\n" );
	print( vi1 + vi2 ); // Dimension-wise addition, output: "{7, 1, 8, 1, 2}"
	print( "\n" );
}
```
It will generate the following c code
```
#include <stdio.h>

int main(){
	double vi1[5] = { 5, 3, 4, 1, 2 };
	double vi2[5] = { 2, -2, 4 };
	int temp1 = 0;
	for(int i = 0; i < 5; i++){
		temp1 += vi1[i] * vi2[i]; //value is 20
	}
	printf("%d", temp1);
	printf("%s", "\n");
	int temp2[5];
	for(int i = 0; i < 5; i++){
		temp2[i] = vi1[i] + vi2[i]; //value is { 7, 1, 8, 1, 2}
	}
	for(int i=0; i < 5; i++){
		printf("%d ",temp2[i]);
	}
	printf("%s", "\n");
	return(0);
}
```
