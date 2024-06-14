%{
    #include "main.h"
    #include "11130038-parser.tab.h"

    extern int lineno;
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
"main"                  { return MAIN; }
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
"println"               { return PRINTLN; }
"print"                 { return PRINT; }

[a-zA-Z_][a-zA-Z0-9_]*  { yylval.stringType = strdup(yytext); return ID; }
[0-9]+                  { yylval.intNum = atoi(yytext); return INTEGER; }
[0-9]+"."[0-9]+         { yylval.realNum = atof(yytext); return DOUBLE; }

"=="                    { return EQJ; }
"!="                    { return NE; }
">"                     { return GT; }
">="                    { return GE; }
"<"                     { return LT; }
"<="                    { return LE; }

[\(\)\[\]\{\};:.,+\-*/=]            { return yytext[0];}



[\n\r]+                 { lineno++; return NEWLINE;}
[\t ]                    { ; }
"\\"                    {yyerror("invalid escape character");yyterminate();}

\'                      {BEGIN(CHARSTART);}
<CHARSTART>[\'\"\n]     {yyerror("invalid character");yyterminate();}
<CHARSTART><<EOF>>      {yyerror("missing terminating ' character");yyterminate();}
<CHARSTART>\\\'         {yyerror("missing terminating ' character");yyterminate();}
<CHARSTART>\\\'\'       {yylval.charType='\'';BEGIN(INITIAL);return CHARACTER;}
<CHARSTART>\\           {BEGIN(CHARESCAPE);}
<CHARSTART>.\'          {yylval.charType=*yytext;BEGIN(INITIAL);return CHARACTER;}
<CHARESCAPE>(\\|\'|\"|\?)\' { yylval.charType=yytext[0]; BEGIN(INITIAL);return CHARACTER;}
<CHARESCAPE>t\'         {yylval.charType=9;BEGIN(INITIAL);return CHARACTER;}
<CHARESCAPE>n\'         {yylval.charType=10;BEGIN(INITIAL);return CHARACTER;}
<CHARESCAPE><<EOF>>     {yyerror("invalid escape character");yyterminate();}
<CHARESCAPE>.           {yyerror("invalid escape character");yyterminate();}

\"                       { BEGIN(STRINGSTATE); stringBuffer[0] = '\0'; }  
<STRINGSTATE>\"          { char* temp = strdup(stringBuffer);
                            if (!temp) {
                                yyerror("Memory allocation failed");
                                yyterminate();
                            }
                        yylval.stringType = temp;
                        BEGIN(INITIAL);
                        return STRING; }  
<STRINGSTATE>\\          { BEGIN(STRINGESCAPE); }
<STRINGSTATE>[^\\\n\"]+  { size_t len = strlen(stringBuffer);
                            size_t max_append = sizeof(stringBuffer) - len - 1; // -1 to leave space for null terminator
                            strncat(stringBuffer, yytext, max_append); }
<STRINGSTATE>\n          { yyerror("missing terminating \" character"); yyterminate(); }
<STRINGESCAPE>n          { strcat(stringBuffer, "\\n"); BEGIN(STRINGSTATE); }
<STRINGESCAPE>t          { strcat(stringBuffer, "\\t"); BEGIN(STRINGSTATE); }
<STRINGESCAPE>\"         { strcat(stringBuffer, "\""); BEGIN(STRINGSTATE); }
<STRINGESCAPE>\\         { strcat(stringBuffer, "\\"); BEGIN(STRINGSTATE); }
<STRINGESCAPE>\'         { strcat(stringBuffer, "\'"); BEGIN(STRINGSTATE); }
<STRINGESCAPE>\?         { strcat(stringBuffer, "\?"); BEGIN(STRINGSTATE); }
<STRINGESCAPE>.          { yyerror("invalid escape character"); yyterminate(); }
<STRINGESCAPE><<EOF>>    { yyerror("EOF in string constant"); yyterminate(); }


"//"                    { BEGIN SINGLECOMMENT; }
<SINGLECOMMENT>[^\n]*        { ; }
<SINGLECOMMENT>\n            { lineno++;BEGIN 0; return NEWLINE; }

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
    printf("error. line %d: %s at yytext:(%s)\n", lineno, s, yytext);
}

