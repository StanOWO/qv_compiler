%{
    #include<stdio.h>
    enum token{
        VAR = 256, VAL, IDENTIFIER, INT, INTEGER,
        REAL,  FLOAT, CHAR, CHARACTER, BOOL,
        TRUE, FALSE, STRING, CLASS, IF,
        ELSE, FOR, WHILE, EQ, NE,
        GE, LE, DO,
        SWITCH, CASE, FUN, RET, MAIN,PRINTLN
    };
    const char* tokenName[]={
        "VAR", "VAL",  "IDENTIFIER", "INT","INTEGER",
        "REAL", "FLOAT", "CHAR", "CHARACTER", "BOOL", 
        "TRUE", "FALSE", "STRING", "CLASS", "IF",
        "ELSE", "FOR", "WHILE", "EQ", "NE",
        "GE", "LE", "DO", "SWITCH", "CASE", 
        "FUN", "RET","MAIN", "PRINTLN"
        };
    int lineno = 1;
    union type{
        int d;
        char c;
        char* s;
        float f;
    } yylval;
    char stringBuffer[1024];
    void yyerror(const char *s);
%}

%x CHARSTART    
%x CHARESCAPE   
%x MULTIPLECOMMENT
%x SINGLECOMMENT
%x STRINGSTATE
%x STRINGESCAPE 

%%
"main"                  { return MAIN;}
"var"                   { return VAR; }
"val"                   { return VAL; }
"bool"                  { return BOOL; }
"char"                  { return CHAR; }
"int"                   { return INT; }
"real"                  { return REAL; }
"true"                  { return TRUE; }
"false"                 { return FALSE; }
"class"                 { return CLASS; }
"if"                    { return IF; }
"else"                  { return ELSE; }
"for"                   { return FOR; }
"while"                 { return WHILE; }
"do"                    { return DO; }
"switch"                { return SWITCH; }
"case"                  { return CASE; }
"fun"                   { return FUN; }
"ret"                   { return RET; }

[a-zA-Z_][a-zA-Z0-9_]*  { yylval.s=yytext;return IDENTIFIER; }
[0-9]+                  { yylval.d = atoi(yytext); return INTEGER; }
[0-9]+[a-zA-Z_\'\"]     {yyerror("invalid integer definition");yyterminate();}    
[0-9]+\.[0-9]+           { yylval.f = atof(yytext); return FLOAT; }

[(),\[\]{};,:\+\-\*\/<>=]   { return yytext[0]; }
"=="                    { return EQ; }
"!="                    { return NE; }
">="                    { return GE; }
"<="                    { return LE; }
[\n\r]+                 { lineno++;}
[\t ]                    { ; }
"\\"                    {yyerror("invalid escape character");yyterminate();}

\'                      {BEGIN(CHARSTART);}
<CHARSTART>[\'\"\n]     {yyerror("invalid character");yyterminate();}
<CHARSTART><<EOF>>      {yyerror("missing terminating ' character");yyterminate();}
<CHARSTART>\\\'         {yyerror("missing terminating ' character");yyterminate();}
<CHARSTART>\\\'\'       {yylval.c='\'';BEGIN(INITIAL);return CHARACTER;}
<CHARSTART>\\           {BEGIN(CHARESCAPE);}
<CHARSTART>.\'          {yylval.c=*yytext;BEGIN(INITIAL);return CHARACTER;}
<CHARESCAPE>(\\|\'|\"|\?)\' { yylval.c=yytext[0]; BEGIN(INITIAL);return CHARACTER;}
<CHARESCAPE>t\'         {yylval.c=9;BEGIN(INITIAL);return CHARACTER;}
<CHARESCAPE>n\'         {yylval.c=10;BEGIN(INITIAL);return CHARACTER;}
<CHARESCAPE><<EOF>>     {yyerror("invalid escape character");yyterminate();}
<CHARESCAPE>.           {yyerror("invalid escape character");yyterminate();}

\"                       { BEGIN(STRINGSTATE); stringBuffer[0] = '\0'; }  
<STRINGSTATE>\"          { yylval.s = strdup(stringBuffer); BEGIN(INITIAL); return STRING; }  
<STRINGSTATE>\\          { BEGIN(STRINGESCAPE); }
<STRINGSTATE>[^\\\n\"]+  { strcat(stringBuffer, yytext); }
<STRINGSTATE>\n          { yyerror("missing terminating \" character"); yyterminate(); }
<STRINGESCAPE>n          { strcat(stringBuffer, "\n"); BEGIN(STRINGSTATE); }
<STRINGESCAPE>t          { strcat(stringBuffer, "\t"); BEGIN(STRINGSTATE); }
<STRINGESCAPE>\"         { strcat(stringBuffer, "\""); BEGIN(STRINGSTATE); }
<STRINGESCAPE>\\         { strcat(stringBuffer, "\\"); BEGIN(STRINGSTATE); }
<STRINGESCAPE>\'         { strcat(stringBuffer, "\'"); BEGIN(STRINGSTATE); }
<STRINGESCAPE>\?         { strcat(stringBuffer, "\?"); BEGIN(STRINGSTATE); }
<STRINGESCAPE>.          { yyerror("invalid escape character"); yyterminate(); }
<STRINGESCAPE><<EOF>>    { yyerror("EOF in string constant"); yyterminate(); }


"//"                    { BEGIN SINGLECOMMENT; }
<SINGLECOMMENT>[^\n]*        { ; }
<SINGLECOMMENT>\n            { lineno++;BEGIN 0; }

"/*"                    { BEGIN(MULTIPLECOMMENT); }
<MULTIPLECOMMENT>"*/"           { BEGIN(INITIAL); }
<MULTIPLECOMMENT>.              { ; }
<MULTIPLECOMMENT>\n             { lineno++; }
<MULTIPLECOMMENT><<EOF>>        { yyerror("Unclosed comment at end of file."); yyterminate(); }

.                       {yyerror("scanner error");yyterminate();}
%%

int yywrap(void) {
    return 1;
}

void yyerror(const char *s) {
    printf("scanner error. line %d: %s at yytext:(%s)\n", lineno, s, yytext);
}

int main(void) {
    
    int mode;
    while(1){
        printf("input 1 to input mode and input 2 to file mode:");
        scanf("%d",&mode);
        if(mode==1||mode==2) break;
        else printf("invalid input to choose the mode\n");
    }
    while (mode == 2) {
        char sFile[256];
        printf("Input the path of the file: ");
        scanf("%255s", sFile); 
        FILE *fp = fopen(sFile, "r");
        if (fp == NULL) {
            printf("Cannot open %s\n", sFile);
        } 
        else {
            yyin = fp;
            break;
        }
    }
    int token;
    while(token = yylex())
    {
        if(token>255){
            printf("<%d,%s", token, tokenName[token-256]);
            switch(token){
            case IDENTIFIER:
                printf(",%s>\n",yylval.s);
                break;
            case INTEGER:
                printf(",%d>\n",yylval.d);
                break;
            case FLOAT:
                printf(",%f>\n",yylval.f);
                break;
            case CHARACTER:
                printf(",%c>\n",yylval.c);
                break;
            case STRING:
                printf(",%s>\n",yylval.s);
                break;
            default:
                printf(">\n");
                break;
            }
        }
        else if(token<=255){
            printf("<%d,%c>\n", token,(char)token);
        }
    }
}