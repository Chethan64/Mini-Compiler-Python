%{
    #include<stdio.h>
    #include<string.h>
    #include<stdlib.h>
    #include "y.tab.h"
    
    #define MAX 100
    #define stack_size 100

    int bt_iden = 0;

    struct SymbRecord {
        int scope;
        char name[50];
        char dtype[50];
        int lineno;
        int idx;
    };
    typedef struct SymbRecord SymbRecord;

    struct SymbTable {
        SymbRecord Records[MAX];
        int ind;
    };
    typedef struct SymbTable SymbTable;
    
    SymbTable STable[MAX];

    int linenumber = 0;
    int prevTabs = 0;
    int currTabs = 0;
    int prevScope = 0;
    int currScope = 0;
    int totalScopes = 0;
    int flag = 1;
    int backtrack[100][2];

    void displaySymbolTable()
    {
        for(int j=0; j<MAX; j++)
        {   
            if(STable[j].ind != -1)
            {
                printf("Sl No. \t Name \t Scope \t lineno\n");
                for(int i=0;i<=STable[j].ind;i++)
                {
                    printf("%d\t%s\t%d\t%d\n", STable[j].Records[i].idx, STable[j].Records[i].name, STable[j].Records[i].scope, STable[j].Records[i].lineno);
                }
            }
        }
    }

    void insertIntoSymbolTable(int cScope, char* name, char* type)
    {
        for(int i=0; i<=STable[cScope].ind; i++)
        {
            if((!strcmp(STable[cScope].Records[i].name, name) && STable[cScope].Records[i].scope == cScope))
                return;
        }     
        STable[cScope].ind++;
        STable[cScope].Records[STable[cScope].ind].scope = cScope;
        strcpy(STable[cScope].Records[STable[cScope].ind].name, name);
        strcpy(STable[cScope].Records[STable[cScope].ind].dtype, type);
        STable[cScope].Records[STable[cScope].ind].idx = STable[cScope].ind;
        STable[cScope].Records[STable[cScope].ind].lineno = linenumber;

    }
    
    void check()
    {
        if(prevTabs < currTabs){
            totalScopes++;
            currScope = totalScopes;
        }    
        else if(prevTabs > currTabs)
        {
            int i = bt_iden;
            while(i>=0)
            {
                if(currTabs == backtrack[i][1])
                {
                    currScope = backtrack[i][0];
                    break;
                }
                --i;
            }
        }
        else
            currScope =  prevScope; 

        backtrack[bt_iden][0] = currScope;
        backtrack[bt_iden][1] = currTabs;
        bt_iden++;
    }

    int sp = 0, stack[stack_size];

    void initStack()
    {
        stack[sp++] = 0;
    }
    
    void push (int i) 
 	{
   		if (++sp<stack_size) 
           stack[sp]= i;
   		else 
           {printf ("error: stack overflow\n"); exit(1);}
 	}
 	
 	int pop() 
 	{
   		if (sp>-1) 
           return stack[sp--];
   		else 
           {printf ("error: stack underflow\n"); exit(1);}
 	}
 	
 	int top()
 	{
 		if(sp>-1) 
            return stack[sp];
 		else 
            return 1;
 	}
 	
 	static int indent_depth(const char *K)
	{
		int len = strlen(K), i, tab_count=1;
		for(i=0; i< len ; i++)
		{
			if(K[i]=='\t')
			{
				tab_count++;
			}
			else
			{
				printf("Nope");
				break;
			}	
		}
		return tab_count;
	}	

    void initSymbolTable()
    {
        for(int i=0;i<MAX;++i)
            STable[i].ind = -1;
        initStack();
    }
 	int depth;
%}

digit [0-9]
letter [a-zA-Z]
identifier {letter}({letter}|{digit})*
digits {digit}+
delimiter [\n|\t|' ']
whitespace {delimiter}+
opFraction (\.{digits})?
opExponent ([Ee][+-]?{digits})?
float {digits}{opFraction}{opExponent}
%%
["\t"]* {
            currTabs = currTabs + yyleng;
			depth = indent_depth(yytext);
            depth = yyleng;
            printf("\n\n\nTop: %d", top());
            printf("Depth: %d\n\n\n", yyleng);

			if(depth < top())
			{
				printf("\n\n\nDepth less than top\n\n\n");
                while (depth < top()) 
                    pop();
				return T_DD;
			}
			if(depth == top())
            {
				return T_ND;	
            }			
			if(depth > top())
            {
				push(depth);
				return T_TAB;	
            }
}
"\n" { 
    flag = 1;
    prevScope = currScope; 
    prevTabs = currTabs; 
    currTabs = 0; 
    linenumber = linenumber + 1;
    return T_NL;
}
def {
    if(flag==1){
        check();
        flag = 0;
    }
    return T_DEF;
} 
if {
    if(flag==1){
        check();
        flag = 0;
    }
    return T_IF;
}
elif {
        if(flag==1){
        check();
        flag = 0;
    }
    return T_ELIF;
}
else {
    if(flag==1){
        check();
        flag = 0;
    }
    return T_ELSE;
}
for {
    if(flag==1){
        check();
        flag = 0;
    }
    return T_FOR;
}
in return T_IN;
range return T_RANGE;
print {
    if(flag==1){
        check();
    flag = 0;
    }
    return T_PRINT;
}
{digits} return T_INT;
import return T_IMPORT;
pass return T_PASS;
break return T_BREAK;
return return T_RETURN;
and return T_AND;
or return T_OR;
not return T_NOT;
True return T_TRUE;
False return T_FALSE;
"+" return T_PLUS;
"-" return T_MINUS;
":" return T_COLON;
"*" return T_MUL;
"/" return T_DIV;
">" return T_GT;
"<" return T_LT;
"=" return T_EQUAL;
"==" return T_EQ;
"<=" return T_LE;
"!=" return T_NE;
">=" return T_GE;
"(" return T_LBRACE;
")" return T_RBRACE;
\[ return T_LBRKT;
\] return T_RBRKT;
"," return T_COMMA;
" " ;
#.* ;
{float} return T_FLOAT;
{identifier} {
                if(prevTabs>currTabs)
                    pop();
                if(flag == 1) {
                    check();
                    flag = 0;
            }
            yylval = strdup(yytext);
            insertIntoSymbolTable(currScope, yytext, "identifier");
            return T_IDENTIFIER;
    }
\"([^\"\n])*\" {
            yylval = strdup(yytext);
            return T_STRING;
                }
\'([^\'\n])*\' {
            yylval = strdup(yytext);
            return T_STRING;
                }
\"\"\"(.|[\n^\"])*\"\"\" ;  
\'\'\'(.|[\n^\'])*\'\'\' ;
. return *yytext;
%%