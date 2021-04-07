%{
    #include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <stdarg.h>

    #define MAXRECST 200
	#define MAXST 100
	#define MAXCHILDREN 100
	#define MAXLEVELS 20
	#define MAXQUADS 1000

    extern int yylineno;
	extern int depth;
	extern int top();
	extern int pop();
	extern int currScope;
	extern int prevScope;
	int currentScope = 1, previousScope = 1;
  
	int yydebug = 1;  
	int yylex();

	typedef struct record
	{
		char *type;
		char *name;
		int decLineNo;
		int STableScope;
		int lastUseLine;
	} record;

	typedef struct STable
	{
		int no;
		int noOfElems;
		int scope;
		record *Elements;
		int Parent;
	} STable;

	typedef struct ASTNode
	{
		int nodeNo;
    	char *NType;	/*Operator*/
   		int noOps;
    	struct ASTNode** NextLevel;
    	record *id;		/*Identifier or Const*/
	
	} node;

	typedef struct Quad
	{
		char *R;
		char *A1;
		char *A2;
		char *Op;
		int I;
	} Quad;
	
	int *arrayScope = NULL;
	STable *symbolTables = NULL;
	int sIndex = -1, aIndex = -1, tabCount = 0, tIndex = 0, lIndex = 0, qIndex = 0, nodeCount = 0;
	node *rootNode;
	char *argsList = NULL;
	char *tString = NULL, *lString = NULL;
	Quad *allQ = NULL;
	node ***Tree = NULL;
	int *levelIndices = NULL;
	
	/* Function definitions */
	record* findRecord(const char *name, const char *type, int scope);
  	node *createID_Const(char *value, char *type, int scope);
  	int power(int base, int exp);
  	void updateCScope(int scope);
  	void resetDepth();
	int scopeBasedTableSearch(int scope);
	void initNewTable(int scope);
	void init();
	int searchRecordInScope(const char* type, const char *name, int index);
	void insertRecord(const char* type, const char *name, int lineNo, int scope);
	void checkList(const char *name, int lineNo, int scope);
	void printSTable();
	void freeAll();
	void addToList(char *newVal, int flag);
	void clearArgsList();
	int checkIfBinOperator(char *Op);

	int scopeBasedTableSearch(int scope)
	{
		int i = sIndex;
		for(i; i > -1; i--)
		{
			if(symbolTables[i].scope == scope)
			{
				return i;
			}
		}
		return -1;
	}

	void init()
	{
		int i = 0;
		symbolTables = (STable*)calloc(MAXST, sizeof(STable));
		arrayScope = (int*)calloc(10, sizeof(int));
		initNewTable(1);
		argsList = (char *)malloc(100);
		strcpy(argsList, "");
		tString = (char*)calloc(10, sizeof(char));
		lString = (char*)calloc(10, sizeof(char));
		allQ = (Quad*)calloc(MAXQUADS, sizeof(Quad));
		
		levelIndices = (int*)calloc(MAXLEVELS, sizeof(int));
		Tree = (node***)calloc(MAXLEVELS, sizeof(node**));
		for(i = 0; i<MAXLEVELS; i++)
		{
			Tree[i] = (node**)calloc(MAXCHILDREN, sizeof(node*));
		}
	}

	void initNewTable(int scope)
	{
		arrayScope[scope]++;
		sIndex++;
		symbolTables[sIndex].no = sIndex;
		symbolTables[sIndex].scope = power(scope, arrayScope[scope]);
		symbolTables[sIndex].noOfElems = 0;		
		symbolTables[sIndex].Elements = (record*)calloc(MAXRECST, sizeof(record));
		symbolTables[sIndex].Parent = scopeBasedTableSearch(currentScope);
	}

	
	int power(int base, int exp)
	{
		int i =0, res = 1;
		for(i; i<exp; i++)
		{
			res *= base;
		}
		return res;
	}

	int searchRecordInScope(const char* type, const char *name, int index)
	{
		int i =0;
		for(i=0; i<symbolTables[index].noOfElems; i++)
		{
			if((strcmp(symbolTables[index].Elements[i].type, type)==0) && (strcmp(symbolTables[index].Elements[i].name, name)==0))
			{
				return i;
			}	
		}
		return -1;
	}
	
	void insertRecord(const char* type, const char *name, int lineNo, int scope)
	{ 
		int FScope = power(scope, arrayScope[scope]);
		int index = scopeBasedTableSearch(FScope);
		int recordIndex = searchRecordInScope(type, name, index);
		if(recordIndex==-1)
		{
			symbolTables[index].Elements[symbolTables[index].noOfElems].type = (char*)calloc(30, sizeof(char));
			symbolTables[index].Elements[symbolTables[index].noOfElems].name = (char*)calloc(20, sizeof(char));

			strcpy(symbolTables[index].Elements[symbolTables[index].noOfElems].type, type);	
			strcpy(symbolTables[index].Elements[symbolTables[index].noOfElems].name, name);
			symbolTables[index].Elements[symbolTables[index].noOfElems].decLineNo = lineNo;
			symbolTables[index].Elements[symbolTables[index].noOfElems].STableScope = currScope;
			symbolTables[index].Elements[symbolTables[index].noOfElems].lastUseLine = lineNo;
			symbolTables[index].noOfElems++;
			// printf("CSCOPE: %d\n", currScope);
		}
		else
		{
			symbolTables[index].Elements[recordIndex].lastUseLine = lineNo;
		}
	}
	
	record* findRecord(const char *name, const char *type, int scope)
	{
		int i =0;
		int index = scopeBasedTableSearch(scope);
		printf("FR: %d, %s\n", scope, name);
		if(index==0)
		{
			for(i=0; i<symbolTables[index].noOfElems; i++)
			{
				
				if(strcmp(symbolTables[index].Elements[i].type, type)==0 && (strcmp(symbolTables[index].Elements[i].name, name)==0))
				{
					return &(symbolTables[index].Elements[i]);
				}	
			}
			printf("\n%s '%s' at line %d Not Found in Symbol Table\n", type, name, yylineno);
			exit(1);
		}
		
		for(i=0; i<symbolTables[index].noOfElems; i++)
		{
			if(strcmp(symbolTables[index].Elements[i].type, type)==0 && (strcmp(symbolTables[index].Elements[i].name, name)==0))
			{
				return &(symbolTables[index].Elements[i]);
			}	
		}
		return findRecord(name, type, symbolTables[symbolTables[index].Parent].scope);
	}

	void printSTable()
	{
		int i = 0, j = 0;
		
		printf("\n----------------------------All Symbol Tables----------------------------");
		printf("\nScope\tName\tType\t\tDeclaration\tLast Used Line\n");
		for(i=0; i<=sIndex; i++)
		{
			for(j=0; j<symbolTables[i].noOfElems; j++)
			{
				printf("%d \t%s\t%s\t%d\t\t%d\n", symbolTables[i].Elements[j].STableScope, symbolTables[i].Elements[j].name, symbolTables[i].Elements[j].type, symbolTables[i].Elements[j].decLineNo,  symbolTables[i].Elements[j].lastUseLine);
			}
		}
		
		printf("-------------------------------------------------------------------------\n");
		
	}
	
	void updateCScope(int scope)
	{
		printf("Updating scope! %d", scope);
		currentScope = scope;
	}

	void resetDepth()
	{
		while(top()) pop();
		depth = 10;
	}

	void modifyRecordID(const char *type, const char *name, int lineNo, int scope)
	{
		int i =0;
		printf("MODIFYSCOPE %d\n", scope);
		int index = scopeBasedTableSearch(scope);
		printf("MODIFY1 %d\n", index);
		if(index==0)
		{
			for(i=0; i<symbolTables[index].noOfElems; i++)
			{
				
				if(strcmp(symbolTables[index].Elements[i].type, type)==0 && (strcmp(symbolTables[index].Elements[i].name, name)==0))
				{
					symbolTables[index].Elements[i].lastUseLine = lineNo;
					return;
				}	
			}
			printf("%s '%s' at line %d Not Declared\n", type, name, yylineno);
			exit(1);
		}
		
		for(i=0; i<symbolTables[index].noOfElems; i++)
		{
			if(strcmp(symbolTables[index].Elements[i].type, type)==0 && (strcmp(symbolTables[index].Elements[i].name, name)==0))
			{
				symbolTables[index].Elements[i].lastUseLine = lineNo;
				return;
			}	
		}
		return modifyRecordID(type, name, lineNo, symbolTables[symbolTables[index].Parent].scope);
	}
	
	void checkList(const char *name, int lineNo, int scope)
	{
		int index = scopeBasedTableSearch(scope);
		int i;
		if(index==0)
		{
			
			for(i=0; i<symbolTables[index].noOfElems; i++)
			{
				
				if(strcmp(symbolTables[index].Elements[i].type, "ListTypeID")==0 && (strcmp(symbolTables[index].Elements[i].name, name)==0))
				{
					symbolTables[index].Elements[i].lastUseLine = lineNo;
					return;
				}	

				else if(strcmp(symbolTables[index].Elements[i].name, name)==0)
				{
					printf("Identifier '%s' at line %d Not Indexable\n", name, yylineno);
					exit(1);

				}

			}
			printf("Identifier '%s' at line %d Not Indexable\n", name, yylineno);
			exit(1);
		}
		
		for(i=0; i<symbolTables[index].noOfElems; i++)
		{
			if(strcmp(symbolTables[index].Elements[i].type, "ListTypeID")==0 && (strcmp(symbolTables[index].Elements[i].name, name)==0))
			{
				symbolTables[index].Elements[i].lastUseLine = lineNo;
				return;
			}
			
			else if(strcmp(symbolTables[index].Elements[i].name, name)==0)
			{
				printf("Identifier '%s' at line %d Not Indexable\n", name, yylineno);
				exit(1);

			}
		}
		
		return checkList(name, lineNo, symbolTables[symbolTables[index].Parent].scope);
	}

	node *createID_Const(char *type, char *value, int scope)
  	{
		node *newNode;
		newNode = (node*)calloc(1, sizeof(node));
		newNode->NType = NULL;
		newNode->noOps = -1;
		newNode->id = findRecord(value, type, scope);
		newNode->nodeNo = nodeCount++;
		return newNode;
  	}

	node *createOp(char *oper, int noOps, ...)
	{
	
			va_list params;
			node *newNode;
			int i;
			newNode = (node*)calloc(1, sizeof(node));
			
			newNode->NextLevel = (node**)calloc(noOps, sizeof(node*));
			
			newNode->NType = (char*)malloc(strlen(oper)+1);
			strcpy(newNode->NType, oper);
			newNode->noOps = noOps;
			va_start(params, noOps);
			
			for (i = 0; i < noOps; i++)
				newNode->NextLevel[i] = va_arg(params, node*);
			
			va_end(params);
			newNode->nodeNo = nodeCount++;
			return newNode;
	}

	void addToList(char *newVal, int flag)
	{
		if(flag==0)
		{
			strcat(argsList, ", ");
			strcat(argsList, newVal);
			}
			else
			{
				strcat(argsList, newVal);
			}
		//printf("\n\t%s\n", newVal);
	}
  
	void clearArgsList()
	{
		strcpy(argsList, "");
	}

  	void freeAll()
	{
		// deadCodeElimination();
		// printQuads();
		// printf("\n");
		int i = 0, j = 0;
		for(i=0; i<=sIndex; i++)
		{
			for(j=0; j<symbolTables[i].noOfElems; j++)
			{
				free(symbolTables[i].Elements[j].name);
				free(symbolTables[i].Elements[j].type);	
			}
			free(symbolTables[i].Elements);
		}
		free(symbolTables);
		// free(allQ);
	}


	void ASTToArray(node *root, int level)
	{
	  if(root == NULL )
	  {
	    return;
	  }
	  
	  if(root->noOps <= 0)
	  {
	  	Tree[level][levelIndices[level]] = root;
	  	levelIndices[level]++;
	  }
	  
	  if(root->noOps > 0)
	  {
	 		int j;
	 		Tree[level][levelIndices[level]] = root;
	 		levelIndices[level]++; 
	    for(j=0; j<root->noOps; j++)
	    {
	    	ASTToArray(root->NextLevel[j], level+1);
	    }
	  }
	}

	int IsValidNumber(char * string)
	{
		for(int i = 0; i < strlen( string ); i ++)
		{
			//ASCII value of 0 = 48, 9 = 57. So if value is outside of numeric range then fail
			//Checking for negative sign "-" could be added: ASCII value 45.
			if (string[i] < 48 || string[i] > 57)
				return 0;
		}
		
		return 1;
	}


	void printAST(node *root)
	{
		printf("\n-------------------------Abstract Syntax Tree--------------------------\n");
		ASTToArray(root, 0);
		int j = 0, p, q, maxLevel = 0, lCount = 0;
		
		while(levelIndices[maxLevel] > 0) maxLevel++;
		
		while(levelIndices[j] > 0)
		{
			for(q=0; q<lCount; q++)
			{
				printf(" ");
			
			}
			for(p=0; p<levelIndices[j] ; p++)
			{
				if(Tree[j][p]->noOps == -1)
				{
					printf("%s  ", Tree[j][p]->id->name);
					lCount+=strlen(Tree[j][p]->id->name);
				}
				else if(Tree[j][p]->noOps == 0)
				{
					printf("%s  ", Tree[j][p]->NType);
					lCount+=strlen(Tree[j][p]->NType);
				}
				else
				{
					printf("%s(%d) ", Tree[j][p]->NType, Tree[j][p]->noOps);
				}
			}
			j++;
			printf("\n");
		}
	}

	void Xitoa(int num, char *str)
	{
		if(str == NULL)
		{
			 printf("Allocate Memory\n");
		   return;
		}
		sprintf(str, "%d", num);
	}

	int checkIfBinOperator(char *Op)
	{
		if((!strcmp(Op, "+")) || (!strcmp(Op, "*")) || (!strcmp(Op, "/")) || (!strcmp(Op, ">=")) || (!strcmp(Op, "<=")) || (!strcmp(Op, "<")) || (!strcmp(Op, ">")) || 
			 (!strcmp(Op, "in")) || (!strcmp(Op, "==")) || (!strcmp(Op, "and")) || (!strcmp(Op, "or")))
			{
				return 1;
			}
			
			else 
			{
				return 0;
			}
	}

	

%}

%union {
	char* text;
	int depth;
	struct ASTNode* node;
};
%locations

%token T_EQ T_PLUS T_MINUS T_MUL T_DIV T_EOF T_ND T_DD T_RETURN T_BREAK T_GT T_LT T_LBRACE T_RBRACE T_LBRKT T_RBRKT T_COMMA T_EQUAL T_NL T_IMPORT T_PASS T_DEF T_TAB T_FOR T_IN T_RANGE T_PRINT T_TRUE T_FALSE T_COLON T_LE T_NE T_GE T_INT T_FLOAT T_IDENTIFIER T_STRING T_AND T_OR T_NOT T_LRBRKT

%right T_EQUAL
%left T_PLUS T_MINUS
%left T_MUL T_DIV
%nonassoc T_IF
%nonassoc T_ELIF
%nonassoc T_ELSE

%type<node> StartDebugger for_stmt args start_suite suite end_suite func_call call_args StartParse finalStatements arith_exp bool_exp term constant basic_stmt cmpd_stmt func_def list_index import_stmt pass_stmt break_stmt print_stmt if_stmt elif_stmts else_stmt  return_stmt assign_stmt bool_term bool_factor

%%

StartDebugger : {init();} StartParse T_EOF {printf("\nValid python syntax!\n"); printAST($2); printSTable(); freeAll(); exit(0);};

constant : T_INT {insertRecord("Constant", $<text>1, @1.first_line, currentScope); $$ = createID_Const("Constant", $<text>1, currentScope);}
	     | T_FLOAT {insertRecord("Constant", $<text>1, @1.first_line, currentScope); $$ = createID_Const("Constant", $<text>1, currentScope);}
		 | T_STRING {insertRecord("Constant", $<text>1, @1.first_line, currentScope); $$ = createID_Const("Constant", $<text>1, currentScope);}
		 ;


term : T_IDENTIFIER { printf("Identifier!\n"); modifyRecordID("Identifier", $<text>1, @1.first_line, currentScope); $$ = createID_Const("Identifier", $<text>1, currentScope);}
	 | constant {$$=$1;}
	 ;

StartParse : T_NL StartParse {$$=$2;}
		   | finalStatements T_NL {resetDepth();} StartParse  {$$ = createOp("NewLine", 2, $1, $4);}
		   | finalStatements T_NL {$$=$1;}
		   | finalStatements {$$=$1;}
		   ;

basic_stmt : pass_stmt {$$=$1;}
		   | break_stmt {$$=$1;}
		   | import_stmt {$$=$1;}
		   | assign_stmt {$$=$1;}
		   | arith_exp {$$=$1;}
	 	   | bool_exp {$$=$1;}
		   | print_stmt {$$=$1;}
	       | return_stmt {$$=$1;}
           ;

arith_exp : term {$$=$1;}
          | arith_exp  T_PLUS  arith_exp {$$ = createOp("+", 2, $1, $3);}
          | arith_exp  T_MINUS  arith_exp {$$ = createOp("-", 2, $1, $3);}
          | arith_exp  T_MUL  arith_exp {$$ = createOp("*", 2, $1, $3);}
          | arith_exp  T_DIV  arith_exp {$$ = createOp("/", 2, $1, $3);}
          | T_MINUS arith_exp {$$ = createOp("-", 1, $2);}
          | T_LBRACE arith_exp T_RBRACE {$$=$2;}
		  ;

bool_exp : bool_term T_OR bool_term {$$ = createOp("or", 2, $1, $3);} 
         | arith_exp T_LT arith_exp {printf("\nHere!\n"); $$ = createOp("<", 2, $1, $3);}
         | bool_term T_AND bool_term {$$ = createOp("and", 2, $1, $3);}
         | arith_exp T_GT arith_exp {$$ = createOp(">", 2, $1, $3);}
         | arith_exp T_LE arith_exp {$$ = createOp("<=", 2, $1, $3);}
         | arith_exp T_GE arith_exp {$$ = createOp(">=", 2, $1, $3);}
         | arith_exp T_IN T_IDENTIFIER {checkList($<text>3, @3.first_line, currentScope); $$ = createOp("in", 2, $1, createID_Const("Constant", $<text>3, currentScope));}
         | bool_term {$$=$1;}
		 ;

bool_term : bool_factor {$$=$1;}
          | arith_exp T_EQ arith_exp {$$ = createOp("==", 2, $1, $3);}
          | T_TRUE {insertRecord("Constant", "True", @1.first_line, currentScope); $$ = createID_Const("Constant", "True", currentScope);}
          | T_FALSE  {insertRecord("Constant", "False", @1.first_line, currentScope); $$ = createID_Const("Constant", "False", currentScope);};
		  ;

bool_factor : T_NOT bool_factor {$$ = createOp("!", 1, $2);}
            | T_LBRACE bool_exp T_RBRACE {$$=$2;}
			;

import_stmt : T_IMPORT T_IDENTIFIER {insertRecord("PackageName", $<text>2, @2.first_line, currentScope); $$ = createOp("import", 1, createID_Const("PackageName", $<text>2, currentScope));}
			;

pass_stmt : T_PASS {$$ = createOp("pass", 0);};
		  ;

break_stmt : T_BREAK {$$ = createOp("break", 0);};
           ;

return_stmt : T_RETURN constant {$$ = createOp("return", 1, $2);}
            | T_RETURN T_IDENTIFIER {insertRecord("Identifier", $<text>2, @2.first_line, currentScope); $$ = createOp("return", 1, createID_Const("Identifier", $<text>2, currentScope));}
            | T_RETURN {$$ = createOp("return", 0);}
            ;

assign_stmt : T_IDENTIFIER T_EQUAL arith_exp {insertRecord("Identifier", $<text>1, @1.first_line, currentScope); $$ = createOp("=", 2, createID_Const("Identifier", $<text>1, currentScope), $3);}  
            | T_IDENTIFIER T_EQUAL bool_exp {insertRecord("Identifier", $<text>1, @1.first_line, currentScope);$$ = createOp("=", 2, createID_Const("Identifier", $<text>1, currentScope), $3);} 
            | T_IDENTIFIER T_EQUAL func_call {insertRecord("Identifier", $<text>1, @1.first_line, currentScope); $$ = createOp("=", 2, createID_Const("Identifier", $<text>1, currentScope), $3);} 
            | T_IDENTIFIER T_EQUAL T_LBRKT T_RBRKT {insertRecord("ListTypeID", $<text>1, @1.first_line, currentScope); $$ = createID_Const("ListTypeID", $<text>1, currentScope);} ;
            ; 

print_stmt : T_PRINT T_LBRACE term T_RBRACE {$$ = createOp("Print", 1, $3);}
			;

finalStatements : basic_stmt {$$ = $1;}
				| cmpd_stmt {$$ = $1;}
				| func_def {$$ = $1;}
				| func_call {$$ = $1;}
				| T_NL 
				;

cmpd_stmt : if_stmt {$$ = $1;}
		  | for_stmt {$$ = $1;}
		  ;

if_stmt : T_IF bool_exp T_COLON start_suite {$$ = createOp("If", 2, $2, $4);}    %prec T_IF ;
        | T_IF bool_exp T_COLON start_suite elif_stmts {$$ = createOp("If", 3, $2, $4, $5);}
		;
		
elif_stmts : else_stmt {$$=$1;}
           | T_ELIF bool_exp T_COLON start_suite elif_stmts {$$= createOp("Elif", 3, $2, $4, $5);};
		   ;

else_stmt : T_ELSE T_COLON start_suite {$$ = createOp("Else", 1, $3);};
		  ;

for_stmt : T_FOR T_IDENTIFIER T_IN T_RANGE T_LBRACE term T_RBRACE T_COLON start_suite {insertRecord("Identifier", $<text>2, @2.first_line, currentScope); $$ = createOp("For", 3, createID_Const("Identifier", $<text>2, currentScope), $6, $9);}
         | T_FOR T_IDENTIFIER T_IN term T_COLON start_suite {insertRecord("Identifier", $<text>2, @2.first_line, currentScope); $$ = createOp("For", 3, createID_Const("Identifier", $<text>2, currentScope), $4, $6);}
		 ;

start_suite : basic_stmt {$$=$1;}
            | T_NLDD T_TAB {initNewTable($<depth>2); updateCScope($<depth>2);}  finalStatements suite {$$ = createOp("BeginBlock", 2, $4, $5);};
			;

T_NLDD : T_NL | T_DD 
	   ;

suite : T_NLDD T_ND finalStatements {$$ = createOp("Next", 1, $3);}
	  | T_NLDD T_ND finalStatements suite {$$ = createOp("Next", 2, $3, $4);}
	  | T_NLDD end_suite {$$ = $2;};
	  |
	  ;

end_suite : T_NLDD {updateCScope($<depth>1);} finalStatements {$$ = createOp("EndBlock", 1, $3);} 
		  | T_NLDD {updateCScope($<depth>1);} {$$ = createOp("EndBlock", 0);}
		  | finalStatements {$$ = createOp("EndBlock", 1, $1);}
		  | {$$ = createOp("EndBlock", 0); resetDepth();};
		  ;

args : T_IDENTIFIER  {addToList($<text>1, 1);} args_list {$$ = createOp(argsList, 0); clearArgsList();} 
     | {$$ = createOp("Void", 0);};
	 ;

args_list : T_COMMA T_IDENTIFIER {addToList($<text>2, 0);} args_list 
		  | 
		  ;

call_list : T_COMMA term {addToList($<text>1, 0);} call_list 
          | 
		  ;

call_args : T_IDENTIFIER {addToList($<text>1, 1);} call_list {$$ = createOp(argsList, 0); clearArgsList();}
	      | T_INT {addToList($<text>1, 1);} call_list {$$ = createOp(argsList, 0); clearArgsList();}
		  | T_FLOAT {addToList($<text>1, 1);} call_list {$$ = createOp(argsList, 0); clearArgsList();}	
		  | T_STRING {addToList($<text>1, 1);} call_list {$$ = createOp(argsList, 0); clearArgsList();}
          | {$$ = createOp("Void", 0);};	
		  ;

func_def : T_DEF T_IDENTIFIER {insertRecord("Func_Name", $<text>2, @2.first_line, currentScope);} T_LBRACE args T_RBRACE T_COLON start_suite {$$ = createOp("Func_Name", 3, createID_Const("Func_Name", $<text>2, currentScope), $5, $8);};
		 ;

func_call : T_IDENTIFIER T_LBRACE call_args T_RBRACE  {$$ = createOp("Func_Call", 2, createID_Const("Func_Name", $<text>1, currentScope), $3);};
		  ;

%%

void yyerror(const char *msg)
{
	printf("\nSyntax error at line %d, column %d\n", yylineno, yylloc.last_column);
	exit(0);
}

int main()
{
	yyparse();
	return 0;
}