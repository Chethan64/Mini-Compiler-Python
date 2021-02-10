%{
     #include<stdio.h>

     int yydebug = 1;
     int yylex();	
     void yyerror(char *s);
     extern char* yytext;
     extern int linenumber;
     extern int prevTabs;
     extern int currTabs;
     extern int prevScope;
     extern int currScope;
     extern int totalScopes;
     extern void displaySymbolTable();

%}

%token DEF EQUAL TAB IF ELIF ELSE FOR IN RANGE PRINT TRUE FALSE COLON EQ LE NE GT GE LT PLUS MINUS MUL DIV LBRACE RBRACE LBRKT RBRKT TK_NUMBER TK_IDENTIFIER TK_STRING 

%%
Prog : TK_IDENTIFIER Prog
     | 
     ;
%%
void yyerror(char *s)
{
	printf("%s\n",s);
}

int main()
{
    yyparse();
     displaySymbolTable();
    return 0;
}
