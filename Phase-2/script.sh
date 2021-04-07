#!/bin/bash
# yacc -d parser.y -v --debug --verbose
yacc -d parser.y -v
lex lexer.l
gcc y.tab.c lex.yy.c -ll 
# echo "Enter the name of input file: "
# read filename
# ./a.out < $filename