%{
    #include<stdio.h>
    #include<string.h>
    #include<stdlib.h>
    #include "y.tab.h"
    
    int ind = 0;
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
        SymbRecord Records[100];
    };
    typedef struct SymbTable SymbTable;
    
    SymbTable STable;
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
        printf("Sl No. \t Name \t Scope \t lineno\n");
        for(int i=0;i<ind;i++)
        {
            printf("%d\t%s\t%d\t%d\n", STable.Records[i].idx, STable.Records[i].name, STable.Records[i].scope, STable.Records[i].lineno);
        }
    }

    void insertIntoSymbolTable(int currScope, char* name, char* type)
    {
        for(int i=0; i<ind; i++)
        {
            if((!strcmp(STable.Records[i].name, name) && STable.Records[i].scope == currScope))
                return;
        }        
        
        STable.Records[ind].scope = currScope;
        strcpy(STable.Records[ind].name , name);
        strcpy(STable.Records[ind].dtype , type);
        STable.Records[ind].idx = ind;
        STable.Records[ind].lineno = linenumber;
        ind++;
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
%}

digit [0-9]
letter [a-zA-Z]
identifier {letter}({letter}|{digit})*
digits {digit}+
opFraction (\.{digits})?
number {digits}{opFraction}{opExponent}
delimiter [\n|\t|' ']
whitespace {delimiter}+
%%

"\t" {
    currTabs = currTabs + 1;
    }
":\n" {
    flag = 1;
    prevScope = currScope; 
    currScope = totalScopes;
    prevTabs = currTabs;
    currTabs = 0;
    linenumber = linenumber + 1; 
}
"\n" { 
    flag = 1;
    prevScope = currScope; 
    prevTabs = currTabs; 
    currTabs = 0; 
    linenumber = linenumber + 1;
}
def {
    return DEF;
} 
if {
    if(flag==1){
        check();
        flag = 0;
    }
    return IF;
}
elif {
        if(flag==1){
        check();
        flag = 0;
    }
    return ELIF;
}
else {
    if(flag==1){
        check();
        flag = 0;
    }
    return ELSE;
}
for {
    if(flag==1){
        check();
        flag = 0;
    }
    return FOR;
}
in return IN;
range return RANGE;
print {
    if(flag==1){
        check();
    flag = 0;
    }
    return PRINT;
}
True return TRUE;
False return FALSE;
"=" return EQUAL;
":" return COLON;
"==" return EQ;
"<=" return LE;
"!=" return NE;
">" return GT;
">=" return GE;
"<" return LT;
"+" return PLUS;
"-" return MINUS;
"/" return DIV;
"(" return LBRACE;
")" return RBRACE;
"[" return LBRKT;
"]" return RBRKT;
" " ;
#.* ;
{digits} return TK_NUMBER;
{identifier} {
                if(flag == 1) {
                    check();
                    flag = 0;
            }
            yylval = strdup(yytext);
            insertIntoSymbolTable(currScope, yytext, "identifier");
            return TK_IDENTIFIER;
    }
\"([^\"\n])*\" {
            yylval = strdup(yytext);
            return TK_STRING;
                }
\'([^\'\n])*\' {
            yylval = strdup(yytext);
            return TK_STRING;
                }
\"\"\"(.|[\n^\"])*\"\"\" ;  
\'\'\'(.|[\n^\'])*\'\'\' ;
. return *yytext;
%%


