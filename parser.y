%{
     #include<stdio.h>
     #include<string.h>
     #include<stdlib.h>
     #define MAX 100
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

     int flag_ID = 0;
     char* value_ID;
     char expression[100][100];
     extern int numexp;

     struct SymbRecord {
        int scope;
        char name[1000];
        char dtype[1000];
        int lineno;
        int idx;
        char* val;
    };
    typedef struct SymbRecord SymbRecord;

    struct SymbTable {
        SymbRecord Records[MAX];
        int ind;
    };
    typedef struct SymbTable SymbTable;
    
    SymbTable STable[MAX];

    void displaySymbolTable()
    {
        for(int j=0; j<MAX; j++)
        {   
            if(STable[j].ind != -1)
            {
                printf("\033[1;31mScope: %d\033[0m\n", j);
                printf("\033[0;34mSl No. \tName \tlineno\tval\tData_Type\033[0m\n");
                for(int i=0;i<=STable[j].ind;i++)
                {
                    printf("%d\t%s\t%d\t%s\t%s\n", STable[j].Records[i].idx+1, STable[j].Records[i].name, STable[j].Records[i].lineno,STable[j].Records[i].val,STable[j].Records[i].dtype);
                }
                printf("\n");
            }
        }
    }

    void insertIntoSymbolTable(char* name)
    {
        if(numexp == 0)
        {
          for(int i=0; i<=STable[currScope].ind; i++)
          {
              if((!strcmp(STable[currScope].Records[i].name, name) && STable[currScope].Records[i].scope == currScope))
                  return;
          }

          STable[currScope].ind++;
          STable[currScope].Records[STable[currScope].ind].scope = currScope;
          strcpy(STable[currScope].Records[STable[currScope].ind].name, name);
          
          if(flag_ID == 1)
            strcpy(STable[currScope].Records[STable[currScope].ind].dtype,"Integer");
          else if(flag_ID ==2)
            strcpy(STable[currScope].Records[STable[currScope].ind].dtype,"Float");
          else if(flag_ID == 3)
            strcpy(STable[currScope].Records[STable[currScope].ind].dtype,"String");
          else if(flag_ID == 4)
          	strcpy(STable[currScope].Records[STable[currScope].ind].dtype,"List");
          
          STable[currScope].Records[STable[currScope].ind].idx = STable[currScope].ind;
          STable[currScope].Records[STable[currScope].ind].lineno = linenumber;


          if(value_ID == NULL)
            STable[currScope].Records[STable[currScope].ind].val = "";
          else
            STable[currScope].Records[STable[currScope].ind].val = strdup(value_ID);
        }
        else
        {
          for(int j=0;j<numexp;++j)
          {
            int present = 0;
            for(int i=0; i<=STable[currScope].ind; i++)
            {
              if((!strcmp(STable[currScope].Records[i].name, expression[j]) && STable[currScope].Records[i].scope == currScope))
                  present = 1;
            }

            if(!present)
            {
              STable[currScope].ind++;
              STable[currScope].Records[STable[currScope].ind].scope = currScope;
              strcpy(STable[currScope].Records[STable[currScope].ind].name, expression[j]);
              STable[currScope].Records[STable[currScope].ind].idx = STable[currScope].ind;
              STable[currScope].Records[STable[currScope].ind].lineno = linenumber;
              STable[currScope].Records[STable[currScope].ind].val = "";
            }
          }

          int present = 0;
          for(int i=0; i<=STable[currScope].ind; i++)
          {
              if((!strcmp(STable[currScope].Records[i].name, name) && STable[currScope].Records[i].scope == currScope))
              {
                  STable[currScope].Records[STable[currScope].ind].lineno = linenumber;
                  STable[currScope].Records[STable[currScope].ind].val = "";
                  present = 1;
              }
          }

          if(!present)
          {
              STable[currScope].ind++;
              STable[currScope].Records[STable[currScope].ind].scope = currScope;
              strcpy(STable[currScope].Records[STable[currScope].ind].name, name);
              STable[currScope].Records[STable[currScope].ind].idx = STable[currScope].ind;
              STable[currScope].Records[STable[currScope].ind].lineno = linenumber;
              STable[currScope].Records[STable[currScope].ind].val = "";
          }
        }

        value_ID = strdup("");
        flag_ID = 0;
        numexp = 0;
    }

    void initSymbolTable()
    {
        for(int i=0;i<MAX;++i)
            STable[i].ind = -1;
        initStack();
    }


%}

%union { char *text;};

%token T_EOF T_ND T_DD T_RETURN T_BREAK T_GT T_LT T_LBRACE T_RBRACE T_LBRKT T_RBRKT T_COMMA T_EQUAL T_NL T_IMPORT T_PASS T_DEF T_TAB T_FOR T_IN T_RANGE T_PRINT T_TRUE T_FALSE T_COLON T_LE T_NE T_GE T_INT T_FLOAT T_IDENTIFIER T_STRING T_AND T_OR T_NOT T_LRBRKT

%right T_EQ                                         
%left T_PLUS T_MINUS
%left T_MUL T_DIV
%nonassoc T_IF
%nonassoc T_ELIF
%nonassoc T_ELSE

%nonassoc T_NLPSEUDO
%nonassoc T_NL
%nonassoc T_DDPSEUDO
%nonassoc T_DD
%nonassoc T_IDPSEUDO
%nonassoc T_IDENTIFIER
%nonassoc ARITH
%nonassoc ARITHPSEUDO

%%
StartDebugger : StartParse {printf("\n\033[1;32mParsing completed.\033[0m\n");};

StartParse : T_NL StartParse 
           | finalStatements T_NL StartParse 
           | finalStatements T_NL
           | finalStatements
           ; 

T_NLDD : T_NL | T_DD 
       ;

constant : T_INT {flag_ID = 1; value_ID = strdup($<text>1);} 
         | T_FLOAT {flag_ID = 2; value_ID = strdup($<text>1);} 
         | T_STRING {flag_ID = 3; value_ID = strdup($<text>1);} 
         | list {flag_ID = 4;}
         ;

list : T_LBRKT list_values T_RBRKT 
     | T_LRBRKT
     ;

list_values : constant | constant T_COMMA list_values
      ; 

term : T_IDENTIFIER {insertIntoSymbolTable($<text>1);} | constant 
     ;

finalStatements : basic_stmt | cmpd_stmt | func_def | func_call | T_NL ;

basic_stmt : pass_stmt | break_stmt | import_stmt | assign_stmt 
           | arith_exp | bool_exp | print_stmt | return_stmt 
           ;

func_def : T_DEF T_IDENTIFIER {insertIntoSymbolTable($<text>2);} T_LBRACE args T_RBRACE T_COLON start_suite;

func_call : T_IDENTIFIER {insertIntoSymbolTable($<text>1);} T_LBRACE call_args T_RBRACE ;

args : T_IDENTIFIER {insertIntoSymbolTable($<text>1);} args_list  
     | ;

args_list : T_COMMA T_IDENTIFIER {insertIntoSymbolTable($<text>2);} args_list | ;

call_list : T_COMMA term call_list | ;

call_args : T_IDENTIFIER {insertIntoSymbolTable($<text>1);} call_list | T_INT | T_FLOAT | T_STRING  
          | ;

arith_exp : T_IDENTIFIER {insertIntoSymbolTable($<text>1); strcpy(expression[numexp],$<text>1); ++numexp;}
          | constant
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
         | arith_exp T_IN T_IDENTIFIER {insertIntoSymbolTable($<text>3);}
         | bool_term ; 

bool_term : bool_factor 
          | arith_exp T_EQ arith_exp 
          | T_TRUE 
          | T_FALSE ; 
          
bool_factor : T_NOT bool_factor
            | T_LBRACE bool_exp T_RBRACE ;

import_stmt : T_IMPORT T_IDENTIFIER {insertIntoSymbolTable($<text>2);} ;

pass_stmt : T_PASS ;

break_stmt : T_BREAK ;

return_stmt : T_RETURN constant
            | T_RETURN T_IDENTIFIER
            | T_RETURN
            ;
 
assign_stmt : T_IDENTIFIER T_EQUAL arith_exp {insertIntoSymbolTable($<text>1);} ;
            | T_IDENTIFIER T_EQUAL bool_exp  
            | T_IDENTIFIER T_EQUAL func_call 
            | T_IDENTIFIER T_EQUAL T_LBRKT T_RBRKT
            ; 
	      
print_stmt : T_PRINT T_LBRACE term T_RBRACE 
			| T_PRINT T_LBRACE T_RBRACE;

cmpd_stmt : if_stmt | for_stmt ;

start_suite : basic_stmt 
            | T_NLDD T_TAB finalStatements
            | T_NLDD T_TAB finalStatements suite
            ;

suite : T_NL T_ND finalStatements %prec T_NLPSEUDO;
      | T_NL T_ND finalStatements suite 
      | T_DD T_ND finalStatements %prec T_DDPSEUDO;
      | T_DD T_ND finalStatements suite 
      | T_NL %prec T_NLPSEUDO;
      | T_NL end_suite
      | T_DD %prec T_DDPSEUDO;
      | T_DD end_suite
      ;

end_suite : T_NLDD finalStatements 
          | T_NLDD 
          | finalStatements 
          ;

if_stmt : T_IF bool_exp T_COLON start_suite     %prec T_IF ;
        | T_IF bool_exp T_COLON start_suite elif_stmts ;

elif_stmts : else_stmt 
           | T_ELIF bool_exp T_COLON start_suite elif_stmts ;

else_stmt : T_ELSE T_COLON start_suite ;

for_stmt : T_FOR temp T_IN T_RANGE T_LBRACE term T_RBRACE T_COLON start_suite 
         | T_FOR temp T_IN temp T_COLON start_suite;

temp : T_IDENTIFIER { value_ID = strdup(""); insertIntoSymbolTable($<text>1);};     

%%
void yyerror(char *s)
{
	printf("\n\033[1;31mSyntax Error: Stopped Parsing\033[0m\n");
}

int main()
{
     printf("------------Tokens------------\n\n");
     initSymbolTable();
     yyparse();   
     printf("\n\n------------Symbol Tables------------\n\n");
     displaySymbolTable();
     return 0;
}