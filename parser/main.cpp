#include "main.h"
#include "11130038-parser.tab.h"

extern int yyparse(void);
extern FILE* yyin;
ofstream outFile;
extern string code;
int main()
{
    int mode;

    string sFile;
    printf("Please input the path of the file: ");
    cin >> sFile;
    FILE* fp = fopen(sFile.c_str(), "r");
    if (fp == NULL) {
        printf("Cannot open %s\n", sFile.c_str());
    }
    else {
        yyin = fp;
    }

    outFile.open("output.c");

    if (yyparse() == 0) {
        printf("Parsing successful!\n");
    }
    else {
        printf("Parsing failed!\n");
    }

    return 0;

}