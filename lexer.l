%{
    #include<stdio.h>
    #include<string.h>
    #include<stdlib.h>
    #include "y.tab.h"

    #define stack_size 100

    int sp = 0;
    int stack[stack_size];
    int bt_iden = 0;
    int linenumber = 1;
    int prevTabs = 0;
    int currTabs = 0;
    int prevScope = 0;
    int currScope = 0;
    int totalScopes = 0;
    int flag = 1;
    int backtrack[100][2];
    int numexp = 0;
    int depth;

    void check()
    {
        if(prevTabs < currTabs)
        {
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

    void initStack()
    {
        stack[sp] = 0;
        for(int i=1;i<stack_size;++i)
            stack[i] = -1;
    }
    
    void push (int i) 
 	{
   		if (++sp<stack_size) 
           stack[sp]= i;
   		else 
        {
            printf("\033[1;31m Error: Stack Overflow\033[0m\n");  
            exit(1);
        }
 	}
 	
 	int pop() 
 	{
   		if (sp>-1) 
           return stack[sp--];
   		else 
        {   
            printf("\033[1;31m Error: Stack Underflow\033[0m\n"); 
            exit(1);
        }
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
				break;
		}
		return tab_count;
	}	
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
comment #.*

%%
["\t"]* {
    printf("\033[0;32mToken Found:\033[0m TAB\n");
    currTabs = currTabs + yyleng;
    depth = indent_depth(yytext);
    depth = yyleng;

	if(depth < top())
	{
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
["\n"]+ { 
    printf("\033[0;32mToken Found:\033[0m NEW LINE\n");
    flag = 1;
    prevScope = currScope; 
    prevTabs = currTabs; 
    currTabs = 0; 
    linenumber = linenumber + yyleng;
    numexp = 0;
    return T_NL;
}
["\n"]+/{identifier} {
    printf("\033[0;32mToken Found:\033[0m NEW LINE\n");
    flag = 1;
    prevScope = currScope;
    prevTabs = currTabs;
    currTabs = 0;
    linenumber = linenumber + yyleng;
    if(prevTabs > currTabs) {
        depth = currTabs;
        if(depth < top())
		{
            while (depth < top()) 
                pop();
            return T_DD;
		}   
    }
    return T_NL;
}
["\n"]+["\t"]+/{comment} ;
def {
    printf("\033[0;32mToken Found:\033[0m DEF\n");
    if(flag==1){
        check();
        flag = 0;
    }
    return T_DEF;
} 
if {
    printf("\033[0;32mToken Found:\033[0m IF\n");
    if(flag==1){
        check();
        flag = 0;
    }
    return T_IF;
}
elif {
    printf("\033[0;32mToken Found:\033[0m ELIF\n");
        if(flag==1){
        check();
        flag = 0;
    }
    return T_ELIF;
}
else {
    printf("\033[0;32mToken Found:\033[0m ELSE\n");
    if(flag == 1){
        check();
        flag = 0;
    }
    return T_ELSE;
}
for {
    printf("\033[0;32mToken Found:\033[0m FOR\n");
    if(flag == 1){
        check();
        flag = 0;
    }
    return T_FOR;
}
in {
     printf("\033[0;32mToken Found:\033[0m IN\n");
    return T_IN;
}
range {
     printf("\033[0;32mToken Found:\033[0m RANGE\n");
    return T_RANGE;
}
print {
     printf("\033[0;32mToken Found:\033[0m PRINT\n");
    if(flag==1){
        check();
    flag = 0;
    }
    return T_PRINT;
}
{digits} {
    printf("\033[0;32mToken Found:\033[0m %s\n",yytext);
    yylval.text = strdup(yytext);
    return T_INT;
    }
import {
    printf("\033[0;32mToken Found:\033[0m IMPORT\n");
    return T_IMPORT;
}
pass {
    printf("\033[0;32mToken Found:\033[0m PASS\n");
    return T_PASS;
}
break {
    printf("\033[0;32mToken Found:\033[0m BREAK\n");
    return T_BREAK;
}
return {
      printf("\033[0;32mToken Found:\033[0m RETURN\n");
    return T_RETURN;
}
and {
    printf("\033[0;32mToken Found:\033[0m AND\n");
    return T_AND;
}
or {
     printf("\033[0;32mToken Found:\033[0m OR\n");
    return T_OR;
}
not {
    printf("\033[0;32mToken Found:\033[0m NOT\n"); 
    return T_NOT;
} 
True {
    printf("\033[0;32mToken Found:\033[0m TRUE\n"); 
    return T_TRUE;
}
False {
     printf("\033[0;32mToken Found:\033[0m FALSE\n"); 
    return T_FALSE;
}
"+" {
     printf("\033[0;32mToken Found:\033[0m +\n"); 
    return T_PLUS;
}
"-" {
     printf("\033[0;32mToken Found:\033[0m -\n"); 
    return T_MINUS;
}
":" {
    printf("\033[0;32mToken Found:\033[0m :\n"); 
    return T_COLON;
}
"*" {
    printf("\033[0;32mToken Found:\033[0m *\n"); 
    return T_MUL;
}
"/" {
     printf("\033[0;32mToken Found:\033[0m /\n"); 
    return T_DIV;
}
">" {
     printf("\033[0;32mToken Found:\033[0m >\n"); 
    return T_GT;
}
"<" {
     printf("\033[0;32mToken Found:\033[0m <\n"); 
    return T_LT;
}
"=" {
     printf("\033[0;32mToken Found:\033[0m =\n"); 
    return T_EQUAL;
}
"==" {
     printf("\033[0;32mToken Found:\033[0m ==\n"); 
    return T_EQ;
}
"<=" {
     printf("\033[0;32mToken Found:\033[0m <=\n"); 
    return T_LE;
}
"!=" {
     printf("\033[0;32mToken Found:\033[0m !=\n"); 
    return T_NE;
}
">=" {
     printf("\033[0;32mToken Found:\033[0m >=\n"); 
    return T_GE;
}
"(" {
     printf("\033[0;32mToken Found:\033[0m (\n"); 
    return T_LBRACE;
}
")" {
    printf("\033[0;32mToken Found:\033[0m )\n"); 
    return T_RBRACE;  
}
"[]" {
    printf("\033[0;32mToken Found:\033[0m []\n");
    return T_LRBRKT;
} 
"[" {
     printf("\033[0;32mToken Found:\033[0m [\n"); 
    return T_LBRKT;
}
"]" {
     printf("\033[0;32mToken Found:\033[0m ]\n"); 
    return T_RBRKT;
}

"," {
     printf("\033[0;32mToken Found:\033[0m ,\n"); 
    return T_COMMA;
}
" " ;
#.* ;
{float} {
    printf("\033[0;32mToken Found:\033[0m %s\n",yytext); 
    yylval.text = strdup(yytext);
    return T_FLOAT;
    }

{identifier} {
    printf("\033[0;32mToken Found:\033[0m %s\n", yytext); 
    if(flag == 1) {
        check();
        flag = 0;
    }
    if(strlen(yytext)>79){
    	printf("\033[1;31mSyntax Error: Identifier length exceeded 79 characters\033[0m\n");
    	yytext[79] = '\0';
    	char trunc[79];
    	for(int i=0;i<79;++i)
    		trunc[i] = yytext[i];
    	trunc[79] = '\0';
    	yylval.text = strdup(trunc);
    	return T_IDENTIFIER;
    }

    yylval.text = strdup(yytext);
    return T_IDENTIFIER;
}
\"([^\"])*\" {
    printf("\033[0;32mToken Found:\033[0m %s\n", yytext); 
    char s[yyleng];
    int j = 0;
    for(int i=0 ; i<yyleng ; i++){
    	if(yytext[i] != '\n')
    		s[j++] = yytext[i];
    }
    s[j] = '\0';
    if(j != yyleng)
    	printf("\033[1;31mSyntax Error: New Line is found in a string\033[0m\n");
    yylval.text = strdup(s);
    return T_STRING;
}
\'([^\'])*\' {
            printf("\033[0;32mToken Found:\033[0m %s\n", yytext); 
            char s[yyleng];
            int j=0;
            for(int i=0 ; i<yyleng ; i++){
            	if(yytext[i] != '\n')
            		s[j++] = yytext[i];
            }
            s[j] = '\0';
            if(j != yyleng)
            	printf("\033[1;31mSyntax Error: New Line is found in a string\033[0m\n");
            yylval.text = strdup(s);
            return T_STRING;
                }
\"\"\"(.|[\n^\"])*?\"\"\" ;  
\'\'\'(.|[\n^\'])*?\'\'\' ;
. {printf("\033[0;31mError: Found Unmatched Token\033[0m\n");}
%%