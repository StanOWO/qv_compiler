#ifndef MAIN_H
#define MAIN_H

#define judge if(isError) YYABORT 

#include <iostream>
#include <cstring>
#include <ctype.h>
#include <fstream>
#include <variant>

using namespace std;

typedef enum {
    INT_TYPE,
    REAL_TYPE,
    CHAR_TYPE,
    BOOL_TYPE,
    STRING_TYPE,
    INT_ARRAY_TYPE
} Type;


class TOTAL_TYPE{
public:
    Type type;
    string name;
    TOTAL_TYPE(Type t) : type(t) {}
};

class IntValue : public TOTAL_TYPE{
public:
    int value;
    IntValue(int v) : TOTAL_TYPE(Type::INT_TYPE), value(v) {}
};

class RealValue : public TOTAL_TYPE{
public:
    double value;
    RealValue(double v) : TOTAL_TYPE(Type::REAL_TYPE), value(v) {}
};

class CharValue : public TOTAL_TYPE{
public:
    char value;
    CharValue(char v) : TOTAL_TYPE(Type::CHAR_TYPE), value(v) {}
};

class IntArray : public TOTAL_TYPE{
public:
    const int SIZE;
    int* data;
    IntArray(int s) : TOTAL_TYPE(Type::INT_ARRAY_TYPE), SIZE(s)
    {
        data = NULL;
    }
    IntArray(int s, int* d) : TOTAL_TYPE(Type::INT_ARRAY_TYPE), SIZE(s)
    {
        changeData(d);
    }
    void changeData(int* d)
    {
        if(data == NULL)
            data = (int*)malloc(SIZE * sizeof(int));
        
        data = d;
    }
    ~IntArray() { free(data); }
};

class Symbol{
public:
    string name;
    TOTAL_TYPE* data;
    bool valid;
    bool isVal;
    Symbol(string n, TOTAL_TYPE* d, bool v, bool v2) : name(n), data(d), valid(v), isVal(v2) {}
    Symbol(Type t, string n) : name(n), data(NULL) {}
    ~Symbol() { delete(data); }
};

struct SymbolNode{
    Symbol *symbol;
    SymbolNode* next;
};

struct IntElement{
    int size;
    int* elements;
};

extern SymbolNode *symbolTable;

#endif
