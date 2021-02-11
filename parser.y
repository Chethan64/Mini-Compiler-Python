%{
     #include<stdio.h>
     #include<string.h>
     #include<stdlib.h>
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
     extern void initSymbolTable();
     extern void initStack();
%}

%token T_EOF T_ND T_DD T_RETURN T_BREAK T_PLUS T_MINUS T_MUL T_DIV T_GT T_LT T_LBRACE T_RBRACE T_LBRKT T_RBRKT T_COMMA T_EQUAL T_NL T_IMPORT T_PASS T_DEF T_TAB T_IF T_ELIF T_ELSE T_FOR T_IN T_RANGE T_PRINT T_TRUE T_FALSE T_COLON T_EQ T_LE T_NE T_GE T_INT T_FLOAT T_IDENTIFIER T_STRING T_AND T_OR T_NOT 

%%
StartParse : T_NL StartParse 
           | finalStatements T_NL StartParse 
           | finalStatements T_NL 
           ;
           
constant : T_INT | T_FLOAT | T_STRING 
         ;

term : T_IDENTIFIER | constant 
     ;

finalStatements : basic_stmt | cmpd_stmt | func_def | func_call ;

basic_stmt : pass_stmt | break_stmt | import_stmt | assign_stmt 
           | arith_exp | bool_exp | print_stmt | return_stmt 
           ;

func_def : T_DEF T_IDENTIFIER T_LBRACE args T_RBRACE T_COLON start_suite ;

func_call : T_IDENTIFIER T_LBRACE call_args T_RBRACE ;

args : T_IDENTIFIER args_list  
     | ;

args_list : T_COMMA T_IDENTIFIER args_list | ;

call_list : T_COMMA term call_list | ;

call_args : T_IDENTIFIER call_list | T_INT | T_FLOAT | T_STRING  
          | ;

arith_exp : term
          | arith_exp  T_PLUS  arith_exp 
          | arith_exp  T_MINUS  arith_exp 
          | arith_exp  T_MUL  arith_exp 
          | arith_exp  T_DIV  arith_exp 
          | T_MINUS arith_exp 
          | T_LBRACE arith_exp T_RBRACE 
          ;
		    
bool_exp : bool_term T_OR bool_term 
         | arith_exp T_LT arith_exp
         | bool_term T_AND bool_term 
         | arith_exp T_GT arith_exp 
         | arith_exp T_LE arith_exp 
         | arith_exp T_GE arith_exp 
         | arith_exp T_IN T_IDENTIFIER 
         | bool_term ; 

bool_term : bool_factor 
          | arith_exp T_EQ arith_exp 
          | T_TRUE 
          | T_FALSE ; 
          
bool_factor : T_NOT bool_factor
            | T_LBRACE bool_exp T_RBRACE ;

import_stmt : T_IMPORT T_IDENTIFIER ;

pass_stmt : T_PASS ;

break_stmt : T_BREAK ;

return_stmt : T_RETURN ;
 
assign_stmt : T_IDENTIFIER T_EQUAL arith_exp  
            | T_IDENTIFIER T_EQUAL bool_exp 
            | T_IDENTIFIER  T_EQUAL func_call 
            | T_IDENTIFIER T_EQUAL T_LBRKT T_RBRKT ;
	      
print_stmt : T_PRINT T_LBRACE term T_RBRACE ;

cmpd_stmt : if_stmt | for_stmt ;

start_suite : basic_stmt 
            | T_NL T_TAB finalStatements suite
            | T_NL T_ND finalStatements suite
            ;

suite : T_NL T_ND finalStatements suite 
      | T_NL end_suite ;

end_suite : T_DD finalStatements
          | T_DD
          | finalStatements
          |
          ;

if_stmt : T_IF bool_exp T_COLON start_suite 
        | T_IF bool_exp T_COLON start_suite elif_stmts ;

elif_stmts : else_stmt 
           | T_ELIF bool_exp T_COLON start_suite elif_stmts ;

else_stmt : T_ELSE T_COLON start_suite ;

for_stmt : ;

%%
void yyerror(char *s)
{
	printf("%s\n",s);
}

int main()
{
     initSymbolTable();
     yyparse();    
     displaySymbolTable();
     return 0;
}

