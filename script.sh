#!/bin/bash
yacc -d parser.y --debug --verbose
# yacc -d parser.y
lex lexer.l
gcc y.tab.c lex.yy.c -ll
./a.out < input.txt