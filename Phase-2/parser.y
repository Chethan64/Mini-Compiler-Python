%{
    #include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <stdarg.h>

    #define RECSTABLEMAX 200
	#define STABLEMAX 100
	#define CHILDRENMAX 100
	#define MAXLEVELS 100
	#define MAXQUADS 1000

    extern int yylineno;
	extern int depth;
	extern int top();
	extern int pop();
	extern void initStack();
	extern int currScope;
	extern int prevScope;
	extern int totalScopes;
	int currentScope = 1, previousScope = 1;
  
	int yydebug = 1;  
	int yylex();

	/*Structure declarations*/
	typedef struct record
	{
		char *type;
		char *name;
		int decLineNo;
		int STableScope;
		int lastUseLine;
		char value[100];
	} record;

	typedef struct STable
	{
		int no;
		int noOfElems;
		int scope;
		record *Elements;
		int ParentScope;
		int ParentSIndex;
	} STable;

	typedef struct ASTNode
	{
		int nodeNo;
    	char *NType;
   		int noOps;
    	struct ASTNode** NextLevel;
    	record *id;
	
	} node;

	typedef struct Quad
	{
		char *R;
		char *A1;
		char *A2;
		char *Op;
		int I;
	} Quad;
	
	STable *symbolTables = NULL;
	int sIndex = -1, aIndex = -1, tabCount = 0, tIndex = 0, lIndex = 0, qIndex = 0, nodeCount = 0;
	node *rootNode;
	char *argsList = NULL;
	char *tString = NULL, *lString = NULL;
	Quad *allQ = NULL;
	node ***Tree = NULL;
	int* levelIndices = NULL;
	int* scopeIndexMap = NULL;
	char value[100];
	int forflag;
	
	record* findRecord(const char *name, const char *type, int scope);
  	node *createID_Const(char *value, char *type, int scope);
  	void resetTabs();
	void initNewTable(int currScope, int prevScope);
	void init();
	int searchRecordInScope(const char* type, const char *name, int index);
	void insertRecordSTable(const char* type, const char *name, int lineNo, int scope,  char *value);
	void validateList(const char *name, int lineNo, int scope);
	void printSymbolTable();
	void freeAll();
	void addToList(char *newVal, int flag);
	void clearArgsList();
	int checkBinaryOperator(char *Op);
	void printAbstractSyntaxTree(node *root);
	void intdCodeGeneration(node *opNode);
	void printQuadraples();
	void inorderEval(node* root);
	void listNodeEval(node* root);
	void yyerror(const char* s);

	void init()
	{
		value[0] = '\0';
		int i = 0;
		forflag = 0;

		symbolTables = (STable*)calloc(STABLEMAX, sizeof(STable));
		scopeIndexMap = (int*)calloc(STABLEMAX, sizeof(int));

		levelIndices = (int*)calloc(MAXLEVELS, sizeof(int));
		Tree = (node***)calloc(MAXLEVELS, sizeof(node**));
		for(i = 0; i<MAXLEVELS; i++)
		{
			Tree[i] = (node**)calloc(CHILDRENMAX, sizeof(node*));
		}

		for(i = 0; i<STABLEMAX; ++i)
		{
			scopeIndexMap[i] = -1;
		}
		scopeIndexMap[1] = 0;

		initNewTable(1,0);

		argsList = (char *)malloc(100);
		strcpy(argsList, "");

		tString = (char*)calloc(10, sizeof(char));
		lString = (char*)calloc(10, sizeof(char));
		allQ = (Quad*)calloc(MAXQUADS, sizeof(Quad));
	}

	void initNewTable(int currScope, int prevScope)
	{
		sIndex++;
		scopeIndexMap[totalScopes+1] = sIndex;
		symbolTables[sIndex].no = sIndex;
		symbolTables[sIndex].scope = currScope;
		symbolTables[sIndex].noOfElems = 0;		
		symbolTables[sIndex].Elements = (record*)calloc(RECSTABLEMAX, sizeof(record));
		symbolTables[sIndex].ParentScope = prevScope;
		symbolTables[sIndex].ParentSIndex = scopeIndexMap[prevScope];
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
	
	void insertRecordSTable(const char* type, const char *name, int lineNo, int scope, char *value)
	{ 
		int index = scopeIndexMap[scope];
		int recordIndex = searchRecordInScope(type, name, index);
		if(recordIndex == -1)
		{
			symbolTables[index].Elements[symbolTables[index].noOfElems].type = (char*)calloc(30, sizeof(char));
			symbolTables[index].Elements[symbolTables[index].noOfElems].name = (char*)calloc(20, sizeof(char));

			strcpy(symbolTables[index].Elements[symbolTables[index].noOfElems].type, type);	
			strcpy(symbolTables[index].Elements[symbolTables[index].noOfElems].name, name);
			symbolTables[index].Elements[symbolTables[index].noOfElems].decLineNo = lineNo;
			symbolTables[index].Elements[symbolTables[index].noOfElems].STableScope = currScope;
			symbolTables[index].Elements[symbolTables[index].noOfElems].lastUseLine = lineNo;
			strcpy(symbolTables[index].Elements[symbolTables[index].noOfElems].value, value);
			symbolTables[index].noOfElems++;
		}
		else
		{
			symbolTables[index].Elements[recordIndex].lastUseLine = lineNo;
			strcpy(symbolTables[index].Elements[symbolTables[index].noOfElems].value, value);	
		}
		
	}
	
	record* findRecord(const char *name, const char *type, int scope)
	{
		int i = 0;
		int index = scopeIndexMap[scope];

		if(index == -1)
		{
			printf("\n%s '%s' at line %d Not Found in Symbol Table\n", type, name, yylineno);
			exit(1);
		}

		if(index == 0)
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
		return findRecord(name, type, symbolTables[index].ParentScope);
	}

	void printSymbolTable()
	{
		int i = 0, j = 0;
		
		printf("\033[1;31m\n			   SYMBOL TABLES						\033[0m\n\n");
		for(i=0; i <= sIndex; i++)
		{
			if(symbolTables[i].noOfElems > -1)
			{
				printf("\033[1;31mScope: %d\033[0m\n", symbolTables[i].Elements[0].STableScope);
				printf("\033[0;34mSlNo.\tName\tType\t\tDeclaration\tLast Used Line\tValue\033[0m\n");
			}
			for(j=0; j<symbolTables[i].noOfElems; j++)
			{
				if(strcmp(symbolTables[i].Elements[j].type,"ICGTempVar") && strcmp(symbolTables[i].Elements[j].type,"ICGTempLabel"))
					printf("%d \t%s\t%s\t%d\t\t%d\t\t%s\n", j+1, symbolTables[i].Elements[j].name, symbolTables[i].Elements[j].type, symbolTables[i].Elements[j].decLineNo,  symbolTables[i].Elements[j].lastUseLine, symbolTables[i].Elements[j].value);
				else
					printf("- \t%s\t%s\t%d\t\t%d\t\t-\n", symbolTables[i].Elements[j].name, symbolTables[i].Elements[j].type, symbolTables[i].Elements[j].decLineNo,  symbolTables[i].Elements[j].lastUseLine);
			}

			printf("\n\n");
		}
				
	}
	
	void resetTabs()
	{
		while(top()) 
			pop();
		depth = 10;
	}

	void modifyRecordID(const char *type, const char *name, int lineNo, int scope, int flag, char *value)
	{
		int i =0;
		int index = scopeIndexMap[scope];

		if(index == -1)
		{
			printf("%s '%s' at line %d Not Declared\n", type, name, yylineno);
			exit(1);
		}
		
		if(index==0)
		{
			for(i=0; i<symbolTables[index].noOfElems; i++)
			{
				
				if(strcmp(symbolTables[index].Elements[i].type, type)==0 && (strcmp(symbolTables[index].Elements[i].name, name)==0))
				{
					symbolTables[index].Elements[i].lastUseLine = lineNo;
					if(flag == 1)
						strcpy(symbolTables[index].Elements[i].value, value);
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
				if(flag == 1)
						strcpy(symbolTables[index].Elements[i].value, value);
				return;
			}	
		}
		return modifyRecordID(type, name, lineNo, symbolTables[index].ParentScope, flag, value);
	}
	
	void validateList(const char *name, int lineNo, int scope)
	{
		int index = scopeIndexMap[scope];
		int i;

		if(index == -1)
		{
			printf("Identifier '%s' at line %d Not Indexable\n", name, yylineno);
			exit(1);
		}

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
			if(strcmp(symbolTables[index].Elements[i].type, "ListTypeID") == 0 && (strcmp(symbolTables[index].Elements[i].name, name) == 0))
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
		
		return validateList(name, lineNo, symbolTables[index].ParentScope);
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
		if(flag == 0)
		{
			strcat(argsList, ", ");
			strcat(argsList, newVal);
		}
		else
		{
			strcat(argsList, newVal);
		}
	}
  
	void clearArgsList()
	{
		strcpy(argsList, "");
	}

  	void freeAll()
	{
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
		free(scopeIndexMap);
		free(allQ);
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
			if (string[i] < 48 || string[i] > 57)
				return 0;
		}
		return 1;
	}

	void printAbstractSyntaxTree(node *root)
	{
		printf("\033[1;31m\n\n\n		ABSTRACT SYNTAX TREE						\033[0m\n\n");
		ASTToArray(root, 0);
		int j = 0;
		int p;
		int q;
		int maxLevel = 0;
		int lCount = 0;

		while(levelIndices[maxLevel] > 0) 
			maxLevel++;
		
		while(levelIndices[j] > 0)
		{
			for(q=0; q<lCount; q++)
			{
				printf("  ");
			
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

	int checkBinaryOperator(char *Op)
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

	char *makeStr(int no, int flag)
	{
		char A[10];
		Xitoa(no, A);
		
		if(flag==1)
		{
			strcpy(tString, "T");
			strcat(tString, A);
			insertRecordSTable("ICGTempVar", tString, -1, 1, "");
			return tString;
		}
		else
		{
			strcpy(lString, "L");
			strcat(lString, A);
			insertRecordSTable("ICGTempLabel", lString, -1, 1, "");
			return lString;
		}
	}
	
	void makeQ(char *R, char *A1, char *A2, char *Op)
	{
		
		allQ[qIndex].R = (char*)malloc(strlen(R)+1);
		allQ[qIndex].Op = (char*)malloc(strlen(Op)+1);
		allQ[qIndex].A1 = (char*)malloc(strlen(A1)+1);
		allQ[qIndex].A2 = (char*)malloc(strlen(A2)+1);
		
		strcpy(allQ[qIndex].R, R);
		strcpy(allQ[qIndex].A1, A1);
		strcpy(allQ[qIndex].A2, A2);
		strcpy(allQ[qIndex].Op, Op);
		allQ[qIndex].I = qIndex;
 
		qIndex++;
		return;
	}
	
	void intdCodeGeneration(node *opNode)
	{
		if(opNode == NULL)
		{
			return;
		}
		
		if(opNode->NType == NULL)
		{
			if((!strcmp(opNode->id->type, "Identifier")) || (!strcmp(opNode->id->type, "Constant")))
			{
				printf("T%d = %s\n", opNode->nodeNo, opNode->id->name);
				makeQ(makeStr(opNode->nodeNo, 1), opNode->id->name, "-", "=");
			}
			return;
		}
		
		if(!strcmp(opNode->NType, "=") && !strcmp(opNode->NextLevel[0]->id->type, "ListTypeID"))
		{
			char temp[5]; 
			char temp_n[5];

			Xitoa(opNode->NextLevel[0]->nodeNo,temp_n);
			strcpy(temp, "T");
			strcat(temp, temp_n);

			int arr[100];
			int arrI = 0;
			node* tempnode = opNode->NextLevel[1];
			while(strcmp(tempnode->NType,"EmptyList"))
			{
				char t_var[5]; 
				char t_n[5];
				Xitoa(tempnode->NextLevel[0]->nodeNo,t_n);
				strcpy(t_var, "T");
				strcat(t_var, t_n);
				arr[arrI++] = tempnode->NextLevel[0]->nodeNo;
		
				printf("%s = %s\n", t_var, tempnode->NextLevel[0]->id->name);
				makeQ(t_var, tempnode->NextLevel[0]->id->name, "-", "=");
				tempnode = tempnode->NextLevel[1];
			}

			char statement[100];
			strcpy(statement,"[");
			printf("%s = ", temp);
			for(int i=0; i<arrI; i++)
			{
				char t_p[5];
				char t_nn[5];
				Xitoa(arr[i],t_nn);
				strcpy(t_p, "T");
				strcat(t_p, t_nn);
				if(i+1 == arrI)
					strcat(statement, t_p);
				else
				{
					strcat(statement, t_p);
					strcat(statement, ",");
				}
			}
			strcat(statement, "]");
			printf("%s\n", statement);
			makeQ(temp, statement ,"-", "=");

			printf("%s = %s\n", opNode->NextLevel[0]->id->name,temp);
			makeQ(opNode->NextLevel[0]->id->name, temp, "-", "=");

		}

		if((!strcmp(opNode->NType, "If")) || (!strcmp(opNode->NType, "Elif")))
		{			
			switch(opNode->noOps)
			{
				case 2 : 
				{
					intdCodeGeneration(opNode->NextLevel[0]);
					int temp = lIndex++;
					printf("If False T%d goto L%d\n", opNode->NextLevel[0]->nodeNo, temp);
					// printf("HERE!\n");
					makeQ(makeStr(temp, 0), makeStr(opNode->NextLevel[0]->nodeNo, 1), "-", "If False");
					// lIndex++;
					intdCodeGeneration(opNode->NextLevel[1]);
					// lIndex--;
					printf("L%d: \n", temp);
					makeQ(makeStr(temp, 0), "-", "-", "Label");
					break;
				}
				case 3 : 
				{
					intdCodeGeneration(opNode->NextLevel[0]);
					int temp = lIndex++;
					printf("If False T%d goto L%d\n", opNode->NextLevel[0]->nodeNo, temp);
					makeQ(makeStr(temp, 0), makeStr(opNode->NextLevel[0]->nodeNo, 1), "-", "If False");					
					intdCodeGeneration(opNode->NextLevel[1]);
					int gototemp = lIndex++;
					printf("goto L%d\n", gototemp);
					makeQ(makeStr(lIndex, 0), "-", "-", "goto");
					printf("L%d: \n", temp);
					makeQ(makeStr(temp, 0), "-", "-", "Label");
					intdCodeGeneration(opNode->NextLevel[2]);
					printf("L%d: \n", gototemp);
					makeQ(makeStr(temp+1, 0), "-", "-", "Label");
					lIndex+=2;
					break;
				}
			}
			return;
		}
		
		if(!strcmp(opNode->NType, "Else"))
		{
			intdCodeGeneration(opNode->NextLevel[0]);
			return;
		}
		
		if(!strcmp(opNode->NType, "While"))
		{
			int temp = lIndex;
			intdCodeGeneration(opNode->NextLevel[0]);
			printf("L%d: If False T%d goto L%d\n", lIndex, opNode->NextLevel[0]->nodeNo, lIndex+1);
			makeQ(makeStr(temp, 0), "-", "-", "Label");		
			makeQ(makeStr(temp+1, 0), makeStr(opNode->NextLevel[0]->nodeNo, 1), "-", "If False");								
			lIndex+=2;			
			intdCodeGeneration(opNode->NextLevel[1]);
			printf("goto L%d\n", temp);
			makeQ(makeStr(temp, 0), "-", "-", "goto");
			printf("L%d: ", temp+1);
			makeQ(makeStr(temp+1, 0), "-", "-", "Label"); 
			lIndex = lIndex+2;
			return;
		}

		if(!strcmp(opNode->NType, "ForRange"))
		{
			int temp = lIndex;
			forflag = 1;
			node* tempnode = createOp("<",2,opNode->NextLevel[0],opNode->NextLevel[1]);
			char temp_n[5];
			Xitoa(opNode->NextLevel[0]->nodeNo, temp_n);
			// char temp_ini[5];
			// strcpy(temp_ini, "T");
			// strcat(temp_ini, temp_n);
			// makeQ(temp_ini, "0", "-", "=");
			// printf("\nL%d: ", lIndex);
			intdCodeGeneration(tempnode);
			forflag = 0;
			// printf("%s = 0\n", temp_ini);
			
			printf("If False T%d goto L%d\n", tempnode->nodeNo, lIndex+1);
			makeQ(makeStr(temp, 0), "-", "-", "Label");		
			makeQ(makeStr(temp+1, 0), makeStr(tempnode->nodeNo, 1), "-", "If False");
			lIndex+=2;			
			intdCodeGeneration(opNode->NextLevel[2]);
			char temp_s[4];
			strcpy(temp_s, "T");
			strcat(temp_s, temp_n);
			makeQ(makeStr(opNode->NextLevel[0]->nodeNo, 1), temp_s, "1", "+");
			printf("%s = %s + 1\n", temp_s, temp_s);
			// makeQ(opNode->NextLevel[0]->id->name,temp_s,"-","=");
			// printf("%s = %s\n", opNode->NextLevel[0]->id->name, temp_s);	
			printf("goto L%d\n", temp);
			makeQ(makeStr(temp, 0), "-", "-", "goto");
			printf("L%d: ", temp+1);
			
			makeQ(makeStr(temp+1, 0), "-", "-", "Label"); 
			lIndex = lIndex+2;
			return;
		}
		
		if(!strcmp(opNode->NType, "Next"))
		{
			intdCodeGeneration(opNode->NextLevel[0]);
			intdCodeGeneration(opNode->NextLevel[1]);
			return;
		}
		
		if(!strcmp(opNode->NType, "BeginBlock"))
		{
			intdCodeGeneration(opNode->NextLevel[0]);
			intdCodeGeneration(opNode->NextLevel[1]);		
			return;	
		}
		
		if(!strcmp(opNode->NType, "EndBlock"))
		{
			switch(opNode->noOps)
			{
				case 0 : 
				{
					break;
				}
				case 1 : 
				{
					intdCodeGeneration(opNode->NextLevel[0]);
					break;
				}
			}
			return;
		}
		
		if(!strcmp(opNode->NType, "ListIndex"))
		{
			printf("T%d = %s[%s]\n", opNode->nodeNo, opNode->NextLevel[0]->id->name, opNode->NextLevel[1]->id->name);
			makeQ(makeStr(opNode->nodeNo, 1), opNode->NextLevel[0]->id->name, opNode->NextLevel[1]->id->name, "=[]");
			return;
		}
		
		if(checkBinaryOperator(opNode->NType)==1 && !forflag)
		{
			intdCodeGeneration(opNode->NextLevel[0]);
			intdCodeGeneration(opNode->NextLevel[1]);
			char *X1 = (char*)malloc(10);
			char *X2 = (char*)malloc(10);
			char *X3 = (char*)malloc(10);
			
			strcpy(X1, makeStr(opNode->nodeNo, 1));
			strcpy(X2, makeStr(opNode->NextLevel[0]->nodeNo, 1));
			strcpy(X3, makeStr(opNode->NextLevel[1]->nodeNo, 1));

			printf("T%d = T%d %s T%d\n", opNode->nodeNo, opNode->NextLevel[0]->nodeNo, opNode->NType, opNode->NextLevel[1]->nodeNo);
			makeQ(X1, X2, X3, opNode->NType);
			free(X1);
			free(X2);
			free(X3);
			return;
		}

		if(checkBinaryOperator(opNode->NType)==1 && forflag)
		{
			char temp_n[5];
			Xitoa(opNode->NextLevel[0]->nodeNo, temp_n);
			char temp_ini[5];
			strcpy(temp_ini, "T");
			strcat(temp_ini, temp_n);
			makeQ(temp_ini, "0", "-", "=");
			printf("%s = 0\n", temp_ini);
			makeQ(opNode->NextLevel[0]->id->name, temp_ini, "-", "=");
			printf("%s = %s\n", opNode->NextLevel[0]->id->name, temp_ini);

			intdCodeGeneration(opNode->NextLevel[1]);
			char *X1 = (char*)malloc(10);
			char *X2 = (char*)malloc(10);
			char *X3 = (char*)malloc(10);
			
			strcpy(X1, makeStr(opNode->nodeNo, 1));
			strcpy(X2, makeStr(opNode->NextLevel[0]->nodeNo, 1));
			strcpy(X3, makeStr(opNode->NextLevel[1]->nodeNo, 1));

			printf("L%d: ", lIndex);
			printf("T%d = T%d %s T%d\n", opNode->nodeNo, opNode->NextLevel[0]->nodeNo, opNode->NType, opNode->NextLevel[1]->nodeNo);
			makeQ(X1, X2, X3, opNode->NType);
			free(X1);
			free(X2);
			free(X3);
			return;
		}
		
		if(!strcmp(opNode->NType, "-"))
		{
			if(opNode->noOps == 1)
			{
				intdCodeGeneration(opNode->NextLevel[0]);
				char *X1 = (char*)malloc(10);
				char *X2 = (char*)malloc(10);
				strcpy(X1, makeStr(opNode->nodeNo, 1));
				strcpy(X2, makeStr(opNode->NextLevel[0]->nodeNo, 1));
				printf("T%d = %s T%d\n", opNode->nodeNo, opNode->NType, opNode->NextLevel[0]->nodeNo);
				makeQ(X1, X2, "-", opNode->NType);	
			}
			
			else
			{
				intdCodeGeneration(opNode->NextLevel[0]);
				intdCodeGeneration(opNode->NextLevel[1]);
				char *X1 = (char*)malloc(10);
				char *X2 = (char*)malloc(10);
				char *X3 = (char*)malloc(10);
			
				strcpy(X1, makeStr(opNode->nodeNo, 1));
				strcpy(X2, makeStr(opNode->NextLevel[0]->nodeNo, 1));
				strcpy(X3, makeStr(opNode->NextLevel[1]->nodeNo, 1));

				printf("T%d = T%d %s T%d\n", opNode->nodeNo, opNode->NextLevel[0]->nodeNo, opNode->NType, opNode->NextLevel[1]->nodeNo);
				makeQ(X1, X2, X3, opNode->NType);
				free(X1);
				free(X2);
				free(X3);
				return;
			
			}
		}
		
		if(!strcmp(opNode->NType, "import"))
		{
			printf("import %s\n", opNode->NextLevel[0]->id->name);
			makeQ("-", opNode->NextLevel[0]->id->name, "-", "import");
			return;
		}
		
		if(!strcmp(opNode->NType, "NewLine"))
		{
			intdCodeGeneration(opNode->NextLevel[0]);
			intdCodeGeneration(opNode->NextLevel[1]);
			return;
		}
		
		if(!strcmp(opNode->NType, "=") && strcmp(opNode->NextLevel[0]->id->type, "ListTypeID"))
		{
			intdCodeGeneration(opNode->NextLevel[1]);
			printf("%s = T%d\n", opNode->NextLevel[0]->id->name, opNode->NextLevel[1]->nodeNo);
			makeQ(opNode->NextLevel[0]->id->name, makeStr(opNode->NextLevel[1]->nodeNo, 1), "-", opNode->NType);
			return;
		}
		
		if(!strcmp(opNode->NType, "Func_Name"))
		{
			printf("Begin Function %s\n", opNode->NextLevel[0]->id->name);
			makeQ("-", opNode->NextLevel[0]->id->name, "-", "BeginF");
			intdCodeGeneration(opNode->NextLevel[2]);
			printf("End Function %s\n", opNode->NextLevel[0]->id->name);
			makeQ("-", opNode->NextLevel[0]->id->name, "-", "EndF");
			return;
		}
		
		if(!strcmp(opNode->NType, "Func_Call"))
		{
			if(!strcmp(opNode->NextLevel[1]->NType, "Void"))
			{
				printf("(T%d)Call Function %s\n", opNode->nodeNo, opNode->NextLevel[0]->id->name);
				makeQ(makeStr(opNode->nodeNo, 1), opNode->NextLevel[0]->id->name, "-", "Call");
			}
			else
			{
				char A[10];
				char* token = strtok(opNode->NextLevel[1]->NType, ","); 
  			int i = 0;
				while (token != NULL) 
				{
						i++; 
				    printf("Push Param %s\n", token);
				    makeQ("-", token, "-", "Param"); 
				    token = strtok(NULL, ","); 
				}
				
				printf("(T%d)Call Function %s, %d\n", opNode->nodeNo, opNode->NextLevel[0]->id->name, i);
				sprintf(A, "%d", i);
				makeQ(makeStr(opNode->nodeNo, 1), opNode->NextLevel[0]->id->name, A, "Call");
				printf("Pop Params for Function %s, %d\n", opNode->NextLevel[0]->id->name, i);
								
				return;
			}
		}		
		
		if(!(strcmp(opNode->NType, "Print")))
		{
			intdCodeGeneration(opNode->NextLevel[0]);
			printf("Print T%d\n", opNode->NextLevel[0]->nodeNo);
			makeQ("-", makeStr(opNode->nodeNo, 1), "-", "Print");
		}

		if(!strcmp(opNode->NType, "return"))
		{
			printf("return\n");
			if(opNode->noOps == 0)
				makeQ("-", "-", "-", "return");
			else
				makeQ(opNode->NextLevel[0]->id->name, "-", "-", "return");
		}

		if(opNode->noOps == 0)
		{
			if(!strcmp(opNode->NType, "break"))
			{
				printf("goto L%d\n", lIndex);
				makeQ(makeStr(lIndex, 0), "-", "-", "goto");
			}

			if(!strcmp(opNode->NType, "pass"))
			{
				makeQ("-", "-", "-", "pass");
			}

		}
		
		
	}

	void printQuadraples()
	{	
		FILE *fp = fopen("./optimization/quads.csv", "w");
		fprintf(fp, "OP,ARG1,ARG2,RES\n");
		printf("\033[1;31m\n\n\n			   ALL QUADS						\033[0m\n\n");
		int i = 0;
		printf("\tOP\tARG1\tARG2\tRES\n\n");
		for(i=0; i<qIndex; i++)
		{
			if(allQ[i].I > -1)
			{
				printf("%d\t%s\t%s\t%s\t%s\n", allQ[i].I, allQ[i].Op, allQ[i].A1, allQ[i].A2, allQ[i].R);
				fprintf(fp, "%s,%s,%s,%s\n", allQ[i].Op, allQ[i].A1, allQ[i].A2, allQ[i].R);
			}
		}
		printf("\n\n");
		fclose(fp);
	}
	
	void inorderEval(node* root)
	{
		if(root->noOps == 2)
		{
			inorderEval(root->NextLevel[0]);
			strcat(value, root->NType);
			inorderEval(root->NextLevel[1]);
		}
		else if(root->noOps == 1)
		{
			strcat(value, root->NextLevel[0]->id->name);
		}
		else if(root->noOps == -1)
		{
			strcat(value, root->id->name);
		}
	}

	void listNodeEval(node* root)
	{
		if(root->noOps == 0)
			return;
		else if(root->noOps == 2)
		{
			strcat(value, root->NextLevel[0]->id->name);
			if(root->NextLevel[1]->noOps != 0)
				strcat(value, ",");
			listNodeEval(root->NextLevel[1]);
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

%type<node> StartDebugger for_stmt args start_suite suite end_suite func_call list_args call_args StartParse finalStatements arith_exp bool_exp term constant basic_stmt cmpd_stmt func_def list_index import_stmt pass_stmt break_stmt print_stmt if_stmt elif_stmts else_stmt  return_stmt assign_stmt bool_term bool_factor temp_


%%
StartDebugger : {initStack(); init();} StartParse T_EOF {printf("\nValid python syntax!\n"); printAbstractSyntaxTree($2); printf("\033[1;31m\n\n\n		INTERMEDIATE CODE	\033[0m\n\n");intdCodeGeneration($2); printQuadraples(); printSymbolTable(); freeAll(); exit(0);};

constant : T_INT {insertRecordSTable("Constant", $<text>1, @1.first_line, currScope, ""); $$ = createID_Const("Constant", $<text>1, currScope);}
	     | T_FLOAT {insertRecordSTable("Constant", $<text>1, @1.first_line, currScope, ""); $$ = createID_Const("Constant", $<text>1, currScope);}
		 | T_STRING {insertRecordSTable("Constant", $<text>1, @1.first_line, currScope, ""); $$ = createID_Const("Constant", $<text>1, currScope);}
		 ;


term : T_IDENTIFIER {modifyRecordID("Identifier", $<text>1, @1.first_line, currScope, 0, ""); $$ = createID_Const("Identifier", $<text>1, currScope);}
	 | constant {$$=$1;}
	 ;

list_index : T_IDENTIFIER T_LBRKT constant T_RBRKT {validateList($<text>1, @1.first_line, currScope); $$ = createOp("ListIndex", 2, createID_Const("ListTypeID", $<text>1, currScope), $3);};

StartParse : T_NL StartParse {$$=$2;}
		   | finalStatements T_NL {$$=$1;}
		   | finalStatements StartParse {$$ = createOp("NewLine", 2, $1, $2);}
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
          | arith_exp  T_PLUS arith_exp {$$ = createOp("+", 2, $1, $3);}
          | arith_exp  T_MINUS arith_exp {$$ = createOp("-", 2, $1, $3);}
          | arith_exp  T_MUL arith_exp {$$ = createOp("*", 2, $1, $3);}
          | arith_exp  T_DIV arith_exp {$$ = createOp("/", 2, $1, $3);}
          | T_MINUS arith_exp {$$ = createOp("-", 1, $2);}
          | T_LBRACE arith_exp T_RBRACE {$$=$2;}
		  ;

bool_exp : bool_term T_OR bool_term {$$ = createOp("or", 2, $1, $3);} 
		 | arith_exp T_OR arith_exp {$$ = createOp("or", 2, $1, $3);} 
         | arith_exp T_LT arith_exp {$$ = createOp("<", 2, $1, $3);}
         | bool_term T_AND bool_term {$$ = createOp("and", 2, $1, $3);}
		 | arith_exp T_AND arith_exp {$$ = createOp("and", 2, $1, $3);}
         | arith_exp T_GT arith_exp {$$ = createOp(">", 2, $1, $3);}
         | arith_exp T_LE arith_exp {$$ = createOp("<=", 2, $1, $3);}
         | arith_exp T_GE arith_exp {$$ = createOp(">=", 2, $1, $3);}
         | arith_exp T_IN T_IDENTIFIER {validateList($<text>3, @3.first_line, currScope); $$ = createOp("in", 2, $1, createID_Const("Constant", $<text>3, currScope));}
         | bool_term {$$=$1;}
		 ;

bool_term : bool_factor {$$=$1;}
          | arith_exp T_EQ arith_exp {$$ = createOp("==", 2, $1, $3);}
          | T_TRUE {insertRecordSTable("Constant", "True", @1.first_line, currScope,""); $$ = createID_Const("Constant", "True", currScope);}
          | T_FALSE  {insertRecordSTable("Constant", "False", @1.first_line, currScope,""); $$ = createID_Const("Constant", "False", currScope);};
		  ;

bool_factor : T_NOT bool_factor {$$ = createOp("!", 1, $2);}
            | T_LBRACE bool_exp T_RBRACE {$$=$2;}
			;

import_stmt : T_IMPORT T_IDENTIFIER {insertRecordSTable("PackageName", $<text>2, @2.first_line, currScope, ""); $$ = createOp("import", 1, createID_Const("PackageName", $<text>2, currScope));}
			;

pass_stmt : T_PASS {$$ = createOp("pass", 0);};
		  ;

break_stmt : T_BREAK {$$ = createOp("break", 0);};
           ;

return_stmt : T_RETURN constant {$$ = createOp("return", 1, $2);}
            | T_RETURN T_IDENTIFIER {insertRecordSTable("Identifier", $<text>2, @2.first_line, currScope ,""); $$ = createOp("return", 1, createID_Const("Identifier", $<text>2, currScope));}
            | T_RETURN {$$ = createOp("return", 0);}
            ;

assign_stmt : T_IDENTIFIER T_EQUAL arith_exp { inorderEval($3); insertRecordSTable("Identifier", $<text>1, @1.first_line, currScope,value); modifyRecordID("Identifier", $<text>1, @1.first_line, currScope, 1, value); value[0]='\0'; $$ = createOp("=", 2, createID_Const("Identifier", $<text>1, currScope), $3);}  
            | T_IDENTIFIER T_EQUAL bool_exp {insertRecordSTable("Identifier", $<text>1, @1.first_line, currScope,"");$$ = createOp("=", 2, createID_Const("Identifier", $<text>1, currScope), $3);} 
            | T_IDENTIFIER T_EQUAL func_call {insertRecordSTable("Identifier", $<text>1, @1.first_line, currScope,""); $$ = createOp("=", 2, createID_Const("Identifier", $<text>1, currScope), $3);} 
            | T_IDENTIFIER T_EQUAL T_LBRKT list_args T_RBRKT { strcat(value,"["); listNodeEval($4); strcat(value,"]"); insertRecordSTable("ListTypeID", $<text>1, @1.first_line, currScope, value); value[0]='\0'; $$ = createOp("=", 2, createID_Const("ListTypeID", $<text>1, currScope), $4);}
            | T_IDENTIFIER T_EQUAL list_index { insertRecordSTable("Identifier", $<text>1, @1.first_line, currScope, value); $$ = createOp("=", 2, createID_Const("Identifier", $<text>1, currScope), $3); }
			;

list_args :   term T_COMMA list_args {$$ = createOp("ListInit", 2, $1, $3);}
			| term {$$ = createOp("ListInit", 2, $1, createOp("EmptyList", 0));}
			| {$$ = createOp("EmptyList", 0);}
			;

print_stmt : T_PRINT T_LBRACE term T_RBRACE {$$ = createOp("Print", 1, $3);}
			;

finalStatements : basic_stmt {$$ = $1;}
				| cmpd_stmt {$$ = $1;}
				| func_def {$$ = $1;}
				| func_call {$$ = $1;}
				;

cmpd_stmt : if_stmt {$$ = $1;}
		  | for_stmt {$$ = $1;}
		  ;

if_stmt : T_IF bool_exp T_COLON start_suite {printf("This!\n"); $$ = createOp("If", 2, $2, $4);}	%prec T_IF;
        | T_IF bool_exp T_COLON start_suite elif_stmts {$$ = createOp("If", 3, $2, $4, $5);}
		;
		
elif_stmts : else_stmt {$$=$1;}
           | T_ELIF bool_exp T_COLON start_suite elif_stmts {$$= createOp("Elif", 3, $2, $4, $5);};
		   ;

else_stmt : T_ELSE T_COLON start_suite {$$ = createOp("Else", 1, $3);};
		  ;

temp_ : T_IDENTIFIER {insertRecordSTable("Identifier", $<text>1, @1.first_line, currScope, ""); $$ = createID_Const("Identifier", $<text>1, currScope);};

for_stmt : T_FOR temp_ T_IN T_RANGE T_LBRACE term T_RBRACE T_COLON start_suite { $$ = createOp("ForRange", 3,$2, $6, $9);}
         | T_FOR temp_ T_IN term T_COLON start_suite {$$ = createOp("ForList", 3, $2, $4, $6);}
		 ;

start_suite : basic_stmt {$$=$1;}
            | T_NLDD T_TAB {initNewTable(currScope, prevScope);}  finalStatements suite {$$ = createOp("BeginBlock", 2, $4, $5);};
			;

T_NLDD : T_NL | T_DD 
	   ;

suite : T_NLDD T_ND finalStatements suite {$$ = createOp("Next", 2, $3, $4);}
	  | T_NLDD end_suite {$$ = $2;};
	  | { $$ = createOp("EndBlock", 0); resetTabs(); }
	  ;

end_suite : T_NLDD finalStatements {$$ = createOp("EndBlock", 1, $2);} 
		  | T_NLDD {$$ = createOp("EndBlock", 0);}			
		  | { $$ = createOp("EndBlock", 0); resetTabs(); }
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

func_def : T_DEF T_IDENTIFIER {insertRecordSTable("Func_Name", $<text>2, @2.first_line, currScope, "");} T_LBRACE args T_RBRACE T_COLON start_suite {$$ = createOp("Func_Name", 3, createID_Const("Func_Name", $<text>2, currScope), $5, $8);};
		 ;

func_call : T_IDENTIFIER T_LBRACE call_args T_RBRACE  {$$ = createOp("Func_Call", 2, createID_Const("Func_Name", $<text>1, currScope), $3);};
		  ;

%%

void yyerror(const char *msg)
{
	printf("\n\033[1;31mSyntax Error at line %d, column %d: Stopped Parsing\033[0m\n", yylineno, yylloc.last_column);
	exit(0);
}

int main()
{
	yyparse();
	return 0;
}