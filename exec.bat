yacc -v -d yacc_07.y
lex -l lex_07.l
gcc yacc_07.tab.c lex.yy.c