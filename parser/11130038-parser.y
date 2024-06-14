%{
#include "main.h"

SymbolNode *symbolTable=NULL;
string code;
bool isError=false;
int arrayOperation=0;
int lineno=1;
extern ofstream outFile;

void yyerror(const char *s);
extern int yylex();
extern int yyparse();
std::string get_type_name(Type type);
void assign_initial(string ID, Type type, bool isVal);
void assign_expr(string ID, Type type, TOTAL_TYPE* expr, bool isVal);
void create_symbol(Symbol* token);
std::variant<int, double, char> get_value(TOTAL_TYPE* value, Type targetType);
TOTAL_TYPE* get_type_from_id(const char* name);
void total_print(TOTAL_TYPE* value,bool isPrint);
void assign_value(const char* name, TOTAL_TYPE* value);
void create_int_array(const char* name, int def_size, IntElement items, bool isVal);
void modify_int_array(const char* name, IntElement items);
void array_print(string ID,Type type,TOTAL_TYPE* expr);
void array_print(string ID,Type type,TOTAL_TYPE* expr,IntElement elements);
TOTAL_TYPE* operate(TOTAL_TYPE* value1, TOTAL_TYPE* value2, char symbol);
TOTAL_TYPE* get_negative_value(TOTAL_TYPE* value);
%}


%union {
    int intNum;
    char charType;
    char* stringType;
    double realNum;
    bool boolean;
    TOTAL_TYPE* allValue;
    IntElement intElement;
	Type types;
};

%type <allValue> stmt
%type <allValue> assign_stmt
%type <allValue> expr
%type <allValue> value
%type <intElement> value_list
%type <types> basic_type;

%token <intNum> INTEGER 
%token <realNum>DOUBLE 
%token <stringType> ID
%token <stringType> STRING
%token <charType> CHARACTER
%token <types>BOOL
%token <types>CHAR 
%token <types>INT 
%token <types>REAL 

%token FUN
%token RET
%token MAIN
%token VAR VAL 
%token TRUE FALSE 
%token CLASS DOT
%token IF ELSE FOR WHILE DO 
%token SWITCH CASE

%token PRINT PRINTLN

%token EQJ NE GT GE LT LE


%token NEWLINE

%start program

%left GT GE LT LE
%left EQJ NE
%left '+' '-'
%left '*' '/'
%right UMINUS

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

program:
    { code+="#include <stdio.h>\n\n"; }
    function_definition program { printf("%s\n",code.c_str()); outFile<<code; }
    |
    ;

function_definition:
    FUN ID '(' { code+="("; }  ')' { code+=")"; } '{' { code+="{"; } stmts '}' { code+="}"; }
    | FUN MAIN { code+="int main()"; } '('  ')' { code+="{"; } '{' stmts '}' { code+="\treturn(0);\n}"; }
    | NEWLINE { code+="\n"; }
    ;

stmts:
    stmt stmts
    |
    ;

stmt:
    '{' stmts '}'               { judge;}
    | expr ';'                  { $$=$1;judge;}
    | assign_stmt               { $$=$1;judge;}
	| print_stmt				{ judge; }
    | RET expr ';'              { judge; }
    | NEWLINE { code+="\n"; }   { judge; }
    | if_stmt                   { judge; }
    | WHILE '(' expr ')' DO stmt{ judge; }
    | FOR '(' expr ';' expr ';' expr ')' stmt   { judge; }   
    ;

print_stmt:
	PRINT '(' expr ')' ';'    	{ total_print($3,true);  }
    | PRINTLN '('  expr ')' ';' { total_print($3,false); }
    | PRINT '(' STRING ')' ';'  { std::string temp($3);code+="\tprintf(\"%s\", \""+temp+"\");"; }
	| PRINTLN '(' STRING ')' ';'{ std::string temp($3);code+="\tprintf(\"%s\n\", \""+temp+"\");"; }
	;
	
if_stmt:
    IF '(' expr ')' stmt %prec LOWER_THAN_ELSE
    | IF '(' expr ')' stmt ELSE stmt
    ;
        
assign_stmt:
    VAR ID  ':' basic_type ';'	{ assign_initial($2,$4,false); free($2); }
	| VAR ID ':' basic_type '=' expr ';'	{ assign_expr($2,$4,$6,false); free($2); delete $6; }
	| VAR ID  ':' basic_type '[' expr ']' '=' '{' value_list '}' ';'    { create_int_array($2, ((IntValue*)$6)->value, $10, false); array_print($2,$4,$6,$10); free($2); } 
    | VAR ID  ':' basic_type '[' expr ']' ';'                           { create_symbol(new Symbol(strdup($2), new IntArray(((IntValue*)$6)->value), false, false));array_print($2,$4,$6); free($2);}
    | VAL ID  ':' basic_type ';'	{ assign_initial($2,$4,true); free($2); }
	| VAL ID ':' basic_type '=' expr ';'	{ assign_expr($2,$4,$6,true); free($2); delete $6; }
	| VAL ID  ':' basic_type '[' expr ']' '=' '{' value_list '}' ';'    { create_int_array($2, ((IntValue*)$6)->value, $10, true); array_print($2,$4,$6,$10); free($2); } 
    | VAL ID  ':' basic_type '[' expr ']' ';'                           { create_symbol(new Symbol(strdup($2), new IntArray(((IntValue*)$6)->value), false, true)); array_print($2,$4,$6); free($2); }
	| ID '=' expr ';'					{ assign_value($1, $3); delete $3; }
	| ID '=' '{' value_list '}' ';'	    { modify_int_array($1, $4);  }
    ;
basic_type:
    INT                     { $$ = INT_TYPE; }
    | REAL                  { $$ = REAL_TYPE; }
    | BOOL                  { $$ = BOOL_TYPE; }
    | CHAR                  { $$ = CHAR_TYPE; }
    ;

value_list:
    expr                    { IntElement items; items.size = 1; items.elements = (int*)malloc(sizeof(int)); items.elements[0] = ((IntValue*)$1)->value; $$=items; }
    | value_list ',' expr   { $$.size = $1.size + 1; $$.elements = (int*)realloc($1.elements, $$.size * sizeof(int)); $$.elements[$$.size - 1] = ((IntValue*)$3)->value; }
    ;

expr:
    expr '+' expr	        { $$ = operate($1, $3, '+'); if($1->type!=INT_ARRAY_TYPE) $$->name= $1->name+" + "+$3->name; }
    | expr '-' expr         { $$ = operate($1, $3, '-'); $$->name= $1->name+" - "+$3->name;}
    | expr '*' expr         { $$ = operate($1, $3, '*'); if($1->type!=INT_ARRAY_TYPE) $$->name= $1->name+" * "+$3->name; }
    | expr '/' expr         { $$ = operate($1, $3, '/'); $$->name= $1->name+" / "+$3->name;}
    | expr EQJ expr         {}
    | expr NE expr          {}
    | expr LT expr          {}
    | expr LE expr          {}
    | expr GT expr          {}
    | expr GE expr          {}
    | '-' expr %prec UMINUS { $$ = get_negative_value($2); }
    | '(' expr ')'          { $$ = $2; $$->name= "("+$2->name+")"; }
    | ID '[' expr ']'       {}
    | ID '(' value_list ')' {} 
    | value                 { $$=$1; }  
    ;

value:
    INTEGER         { $$ = new IntValue($1); $$->name=to_string($1); } 
    | DOUBLE        { $$ = new RealValue($1); $$->name=to_string($1); }
    | CHARACTER     { $$ = new CharValue($1); $$->name=to_string($1); }
    | TRUE          { $$ = new IntValue(1); $$->name=to_string(1); }
    | FALSE         { $$ = new IntValue(0); $$->name=to_string(0); }
    | ID            { $$ = get_type_from_id($1); $$->name=$1; }
    ;
%%

void assign_initial(std::string ID,Type type, bool isVal)
{
	switch(type)
	{
		case Type::INT_TYPE:
		    create_symbol(new Symbol(ID, new IntValue(0), false, isVal));
			code=code+"\tint "+ID+";"; 
		    break;
	    case Type::REAL_TYPE:
		    create_symbol(new Symbol(ID, new RealValue(0.0), false, isVal));
			code=code+"\tdouble "+ID+";";
		    break;
	    case Type::CHAR_TYPE:
			create_symbol(new Symbol(ID, new CharValue(0), false, isVal));
			code=code+"\tchar "+ID+";";
		    break;
		case Type::BOOL_TYPE:
			create_symbol(new Symbol(ID, new IntValue(0), false, isVal));
			code=code+"\tint "+ID+";";
		    break;
	    default:
		    yyerror("invalid operation with negative value");
		    isError=true;
			return;
	}
}

void assign_expr(std::string ID,Type type,TOTAL_TYPE* expr, bool isVal)
{
	switch(type)
	{
		case Type::INT_TYPE:
		{
            int intValue = std::get<int>(get_value(expr, INT_TYPE));
            create_symbol(new Symbol(ID, new IntValue(intValue), true, isVal)); 
            code += "\tint " + ID + " = " + expr->name + ";";
            break;
        }
	    case Type::REAL_TYPE:
		{
			double value = std::get<double>(get_value(expr,REAL_TYPE));
			create_symbol(new Symbol(ID, new RealValue(value), true, isVal));
			code=code+"\tdouble "+ID+" = "+expr->name+";";
		    break;
		}
		    
	    case Type::CHAR_TYPE:
		{
			char value = std::get<char>(get_value(expr,CHAR_TYPE));
			create_symbol(new Symbol(ID, new CharValue(value), true, isVal));
			code=code+"\tchar "+ID+" = "+expr->name+";";
		    break;
		}
		case Type::BOOL_TYPE:
		{
			int value = std::get<int>(get_value(expr,INT_TYPE));
			create_symbol(new Symbol(ID, new IntValue(value), true, isVal));
			code=code+"\tint "+ID+" = "+expr->name+";";
		    break; 
		}
	    default:
		    yyerror("invalid operation with negative value");
		    isError=true;
			return;
	}
}

string get_type_name(Type type){
	switch(type){
		case INT_TYPE:
			return "int";
		case REAL_TYPE:
			return "double";
		case CHAR_TYPE:
			return "char";
		case STRING_TYPE:
			return "string";
		case INT_ARRAY_TYPE:
			return "int";
		default:
			return "unknown";
	}
}

TOTAL_TYPE* get_negative_value(TOTAL_TYPE* v)
{
	TOTAL_TYPE* result;
	switch(v->type)
	{
	    case Type::INT_TYPE:
		    result = new IntValue(- ((IntValue*)v)->value);
		    break;
	    case Type::REAL_TYPE:
		    result = new RealValue(- ((RealValue*)v)->value);
		    break;
	    case Type::CHAR_TYPE:
		    result = new CharValue(- ((CharValue*)v)->value);
		    break;
	    default:
		    yyerror("invalid operation with negative value");
		    isError=true;
	}
	return result;
}
std::variant<int, double, char> get_value(TOTAL_TYPE* value, Type targetType)
{
	switch(targetType){
		case Type::INT_TYPE:
			switch(value->type) 
    		{
        		case Type::INT_TYPE:
		    		return ((IntValue*)value)->value;
	    		case Type::REAL_TYPE:
		    		return (int)((RealValue*)value)->value;
	    		case Type::CHAR_TYPE:
		    		return (int)(((IntValue*)value)->value);
	    		default:
		    		yyerror("invalid operation with int value");
		    		isError=true;
					return -1;
			}
			break;
		case Type::REAL_TYPE:
			switch(value->type) 
    		{
        		case Type::INT_TYPE:
		    		return (double)(((IntValue*)value)->value);
	    		case Type::REAL_TYPE:
		    		return ((RealValue*)value)->value;
	    		case Type::CHAR_TYPE:
		    		return (double)(((IntValue*)value)->value);
	    		default:
		    		yyerror("invalid operation with real value");
		    		isError=true;
					return -1.0;
			}
			break;
		case Type::CHAR_TYPE:
			switch(value->type)
    		{
        		case Type::INT_TYPE:
		    		return (char)((IntValue*)value)->value;
	    		case Type::REAL_TYPE:
		    		return (char)((RealValue*)value)->value;
	    		case Type::CHAR_TYPE:
		    		return (char)(((IntValue*)value)->value);
	    		default:
		    		yyerror("invalid operation with char value");
		    		isError=true;
					return ' ';
			}
			break;
		default:
			yyerror("invalid operation with char value");
		    isError=true;
			return ' ';
	}
}

void total_print(TOTAL_TYPE* value,bool isPrint)
{
    if(isPrint){
        switch(value->type) 
        {
            case Type::INT_TYPE:
                code+="\tprintf(\"%d\", "+value->name+");";
		        break;
	        case Type::REAL_TYPE:
                code+="\tprintf(\"%lf\", "+value->name+");";
		        break;
	        case Type::CHAR_TYPE:
                code+="\tprintf(\"%c\", "+value->name+");";
		        break;
			case Type::INT_ARRAY_TYPE:
				code+="\tfor(int i=0; i < "+to_string(((IntArray*)value)->SIZE)+"; i++){\n";
				code+="\t\tprintf(\"%d \","+value->name+"[i]);\n\t}";
				break;
	        default:
		        yyerror("printing invalid value");
		        isError=true;
	    }
    }
	else
    {
        switch(value->type)
	    {
            case Type::INT_TYPE:
                code+="\tprintf(\"%d\\n\", "+value->name+");";
		        break;
	        case Type::REAL_TYPE:
                code+="\tprintf(\"%lf\\n\", "+value->name+");";
		        break;
	        case Type::CHAR_TYPE:
                code+="\tprintf(\"%c\\n\", "+value->name+");";
		        break;
			case Type::INT_ARRAY_TYPE:
				code+="\tfor(int i=0; i < "+to_string(((IntArray*)value)->SIZE)+"; i++){\n";
				code+="\t\tprintf(\"%d\\n\","+value->name+"[i]);\n\t}";
				break;
	        default:
		        yyerror("Cannot print the value");
		        isError=true;
				return;
	    }
    }
}

Symbol* findSymbol(const char* name)
{
	SymbolNode* nowSymbolNode = symbolTable;
	while(nowSymbolNode != NULL && strcmp(nowSymbolNode->symbol->name.c_str(), name) != 0)
	{
		nowSymbolNode = nowSymbolNode->next;
	}
	if(nowSymbolNode == NULL)
	{
		yyerror("Cannot find symbol");
		isError=true;
	}
	else if(strcmp(nowSymbolNode->symbol->name.c_str(), name) == 0)
	{
		return nowSymbolNode->symbol;
	}
	yyerror("unknown error");
	isError=true;
	return NULL;
}

TOTAL_TYPE* get_type_from_id(const char* name)
{
	Symbol* symbol = findSymbol(name);
	return symbol->data;
}

void assign_value(const char* name, TOTAL_TYPE* value)
{
	Symbol* symbol = findSymbol(name);
	
	if(symbol->valid && symbol->isVal)
	{
		yyerror("Val cannot be reassigned");
		isError=true;
		return;
	}

	symbol->valid=true;

	switch(symbol->data->type)
	{
	case Type::INT_TYPE:
	{
		int int_value = std::get<int>(get_value(value,INT_TYPE));
		((IntValue*)symbol->data)->value = int_value;
        code=code+"\t"+name+" = "+value->name+";";
		break;
	}
	case Type::REAL_TYPE:
	{
		double real_value = std::get<double>(get_value(value,REAL_TYPE));
		((RealValue*)symbol->data)->value = real_value;
        code=code+"\t"+name+" = "+value->name+";";
		break;
	}
	case Type::CHAR_TYPE:
	{
		char char_value = std::get<char>(get_value(value,CHAR_TYPE));
		((CharValue*)symbol->data)->value = char_value;
        code=code+"\t"+name+" = "+value->name+";";
		break;
	}
	default:
		yyerror("Cannot assign number value");
		isError=true;
	}
}

void modify_int_array(const char* name, IntElement items)
{
	Symbol* symbol = findSymbol(name);
	if(symbol->valid && symbol->isVal)
	{
		yyerror("Val cannot be reassigned");
		isError=true;
		return;
	}
	if(symbol->data->type != Type::INT_ARRAY_TYPE)
	{
		yyerror("Cannot assign different type value to a vector");
		isError=true;
		return;
	}

	int def_size = ((IntArray*)(symbol->data))->SIZE;


	if(items.size > def_size)
	{
		yyerror("Too Many Dimensions");
		isError=true;
		return;
	}
	else if(items.size < def_size)
	{
		items.elements = (int*)realloc(items.elements, def_size * sizeof(int));
		for(int i = items.size; i < def_size; i++)
		{
			items.elements[i] = 0;
		}
	}
	((IntArray*)(symbol->data))->changeData(items.elements);
	symbol->valid=true;
}

void create_int_array(const char* name, int def_size, IntElement items, bool isVal)
{
	if(items.size > def_size)
	{
		yyerror("Too Many Dimensions");
		isError=true;
		return;
	}
	else if(items.size < def_size)
	{
		items.elements = (int*)realloc(items.elements, def_size * sizeof(int));
		for(int i = items.size; i < def_size; i++)
		{
			items.elements[i] = 0;
		}
	}
	create_symbol(new Symbol(strdup(name), new IntArray(def_size, items.elements), true, isVal));
}

void array_print(string IDs,Type type,TOTAL_TYPE* expr,IntElement elements)
{
	code=code + "\t" +get_type_name(type)+" "+ (string) IDs+ "[" + expr->name  + "] = { "+ to_string(elements.elements[0]);
	for(int i=1;i<elements.size;i++)
	{
		code = code + ", " + to_string(elements.elements[i]);
	}
	code+=" };";
}
void array_print(string IDs,Type type,TOTAL_TYPE* expr)
{
	code=code +get_type_name(type)+" "+ (string) IDs+ "[" + expr->name  + "];";
}

void create_symbol(Symbol* symbol)
{
	SymbolNode* nowSymbolNode = symbolTable;
	SymbolNode* prevSymbolNode = NULL;
	while(nowSymbolNode != NULL && strcmp(nowSymbolNode->symbol->name.c_str(), symbol->name.c_str()) != 0)
	{
		prevSymbolNode = nowSymbolNode;
		nowSymbolNode = nowSymbolNode->next;
	}
	if(nowSymbolNode == NULL)
	{
		SymbolNode* newSymbolNode = new SymbolNode;
		newSymbolNode->symbol = symbol;
		newSymbolNode->next = NULL;
		if(prevSymbolNode != NULL)
		{
			prevSymbolNode->next = newSymbolNode;
		}
		else
		{
			symbolTable = newSymbolNode;
		}
	}
	else if(strcmp(nowSymbolNode->symbol->name.c_str(), symbol->name.c_str()) == 0)
	{
		yyerror("Duplicate Declaration");
		isError=true;
	}
}



TOTAL_TYPE* operate(TOTAL_TYPE* value1, TOTAL_TYPE* value2, char symbol)
{
	TOTAL_TYPE* result = nullptr;
	
	if(value1->type == Type::INT_ARRAY_TYPE || value2->type == Type::INT_ARRAY_TYPE)
	{
		int value1_size = ((IntArray*)value1)->SIZE;
		int value2_size = ((IntArray*)value2)->SIZE;
		int dimension = value1_size ;

		if(value1_size!=value2_size)
		{
			yyerror("Mismatched Dimensions");
			isError=true;
		}
		
		int* data1 = ((IntArray*)value1)->data;
		int* data2 = ((IntArray*)value2)->data;
		string finalValue="{ ";
		if(symbol == '+')
		{
			arrayOperation+=1;
			result = new IntArray(dimension, (int*)malloc(dimension * sizeof(int)));
			result->name="temp"+to_string(arrayOperation);
			for(int count = 0; count < dimension; count++)
			{
				((IntArray*)result)->data[count] = data1[count] + data2[count];
				if(count!=0) finalValue+=", "+ to_string(((IntArray*)result)->data[count]);
				else finalValue+= to_string(((IntArray*)result)->data[count]);
			}
			finalValue+="}";

			code+="\tint "+result->name+"["+to_string(dimension)+"];\n";
			code+="\tfor(int i = 0; i < "+to_string(dimension)+"; i++){\n";
			code+="\t\t"+result->name+"[i] = ";
			code+=value1->name + "[i] + " + value2->name + "[i]; //value is "+finalValue+"\n\t}\n";
		}
		else if(symbol == '*')
		{
			arrayOperation+=1;
			result = new IntValue(0);
			result->name="temp"+to_string(arrayOperation);
			for(int i = 0; i < dimension; i++)
			{
				((IntValue*)result)->value += data1[i] * data2[i];
			}

			code+="\tint "+result->name+" = 0;\n";
			code+="\tfor(int i = 0; i < "+to_string(dimension)+"; i++){\n";
			code+="\t\t"+result->name+" += ";
			code+=value1->name + "[i] * " + value2->name + "[i]; //value is "+to_string(((IntValue*)result)->value)+"\n\t}\n";
		}
	}
	else if(value1->type == Type::REAL_TYPE || value2->type == Type::REAL_TYPE)
	{
		result = new RealValue(0.0);
		double value1_value = std::get<double>(get_value(value1,REAL_TYPE));
		double value2_value = std::get<double>(get_value(value2,REAL_TYPE));
		switch(symbol)
		{
			case '+':
				((RealValue*)result)->value = value1_value + value2_value;
				break;
			case '-':
				((RealValue*)result)->value = value1_value - value2_value;
				break;
			case '*':
				((RealValue*)result)->value = value1_value * value2_value;
				break;
			case '/':
				((RealValue*)result)->value = value1_value / value2_value;
				break;
		}
	}
	else if(value1->type == Type::INT_TYPE || value2->type == Type::INT_TYPE)
	{
		result = new IntValue(0);
		int value1_value = std::get<int>(get_value(value1,INT_TYPE));
		int value2_value = std::get<int>(get_value(value2,INT_TYPE));
		switch(symbol)
		{
			case '+':
				((IntValue*)result)->value = value1_value + value2_value;
				break;
			case '-':
				((IntValue*)result)->value = value1_value - value2_value;
				break;
			case '*':
				((IntValue*)result)->value = value1_value * value2_value;
				break;
			case '/':
				((IntValue*)result)->value = value1_value / value2_value;
				break;
		}
	}
	else if(value1->type == Type::CHAR_TYPE && value2->type == Type::CHAR_TYPE)
	{
		result = new CharValue(0);
		char value1_value = ((CharValue*)value1)->value;
		char value2_value = ((CharValue*)value2)->value;
		switch(symbol)
		{
			case '+':
				((CharValue*)result)->value = value1_value + value2_value;
				break;
			case '-':
				((CharValue*)result)->value = value1_value - value2_value;
				break;
			case '*':
				((CharValue*)result)->value = value1_value * value2_value;
				break;
			case '/':
				((CharValue*)result)->value = value1_value / value2_value;
				break;
		}
	}
	else
	{
		yyerror("Unknown operation");
		isError=true;
	}
	return result;
}