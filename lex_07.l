%{
    #include "yacc_07.tab.h"

    #include<stdio.h>
    #include<stdlib.h>
    #include<string.h>

    extern int line_no = 1;
    extern YYSTYPE yylval;

%}


%%

\n  															{   line_no++;   }

\"[^\"]*\"                                                      { 
                                                                    char *start= &yytext[1];
                                                                    char *end = &yytext[strlen(yytext)-1];
                                                                    yylval.str_val = strdup(yytext); 
                                                                    memcpy(yylval.str_val, start, end-start);
                                                                    yylval.str_val[strlen(yytext)-2] = '\0';
                                                                    return T_STRING; 
                                                                }

\'(.|\\n|\\t|\\a|\\b|\\r)\'                                     { 
                                                                    char *start= &yytext[1];
                                                                    char *end = &yytext[strlen(yytext)-1];
                                                                    yylval.str_val = strdup(yytext); 
                                                                    memcpy(yylval.str_val, start, end-start);
                                                                    yylval.str_val[strlen(yytext)-2] = '\0';
                                                                    return T_CHAR; 
                                                                }


"//".*\n                                                        {   ;   }

"/*"[^*/]*"*/"                                                  {   ;   }


"bool"|"void"|"short int"|"unsigned short int"|"unsigned int"|"int"|"long int"|"unsigned long int"|"long long int"|"unsigned long long int"|"signed char"|"unsigned char"|"char"|"float"|"double"|"long double"|"wchar_t"           {   yylval.str_val = strdup(yytext); return T_DATATYPE;   }


"true"|"false"                                                  {   yylval.str_val = strdup(yytext); return T_BOOL;   }


"if"       														{   return T_IF;   }
"else"                                                          {   return T_ELSE;   }
"for"       													{   return T_FOR;   }
"while"       													{   return T_WHILE;   }

"return"       													{   return T_RETURN;   }
     
"std"[ \t]*"::"[ \t]*"cout"                                     {   return T_STD_COUT;   }

"std"[ \t]*"::"[ \t]*"endl"                                     {   return T_STD_ENDL;   }

main                                                            {   return T_MAIN;   }

[a-zA-Z_][a-zA-Z_0-9]*	                                        {   yylval.str_val = strdup(yytext); return T_ID;   }


"{"                                                             {   return T_OPEN_SCOPE;   }

"}"                                                             {   return T_CLOSE_SCOPE;   }

"("	                                                            {   return T_OPEN_PARAN;   }

")"	                                                            {   return T_CLOSE_PARAN;   }

";"	                                                            {   return T_SEMICOLON;   }

","                                                             {   return T_COMMA;   }

"<<"                                                            {   yylval.str_val = strdup(yytext); return T_INS_OP;   }


"="                                                             {   yylval.str_val = strdup(yytext); return T_ASGN_EQ_OP;   }
"+="|"-="|"*="|"/="|"%="|"&="|"^="|"|="                         {   yylval.str_val = strdup(yytext); return T_ASGN_NEQ_OP;   }
"||"                                                            {   yylval.str_val = strdup(yytext); return T_OR_OP;  }
"&&"                                                            {   yylval.str_val = strdup(yytext); return T_AND_OP;   }
"|"                                                             {   yylval.str_val = strdup(yytext); return T_BITWISE_OR_OP;   }      
"^"                                                             {   yylval.str_val = strdup(yytext); return T_BITWISE_XOR_OP;   }
"&"                                                             {   yylval.str_val = strdup(yytext); return T_BITWISE_AND_OP;   }
"=="|"!="                                                       {   yylval.str_val = strdup(yytext); return T_EQ_OP;   }
"<"|"<="|">"|">="                                               {   yylval.str_val = strdup(yytext); return T_REL_OP;   }


"+"|"-"                                                         {   yylval.str_val = strdup(yytext); return T_PLUS_MINUS_OP;   }
"*"|"/"|"%"                                                     {   yylval.str_val = strdup(yytext); return T_MUL_DIV_MOD_OP;   }
"!"                                                             {   yylval.str_val = strdup(yytext); return T_NOT_OP;    }
"~"                                                             {   yylval.str_val = strdup(yytext); return T_BITWISE_NOT_OP;   }
"++"|"--"                                                       {   yylval.str_val = strdup(yytext); return T_INC_DEC_OP;   }


[0-9]+\.[0-9]+                                                  {   yylval.str_val = strdup(yytext); return T_FLOAT;   }

[0-9]+	                                                        {   yylval.str_val = strdup(yytext); return T_INTEGER;   }




[0-9@#$%]+[a-zA-Z_]+	                                        {  yylval.str_val = strdup(yytext); return T_ERR_ID;   }



\t|" "	                                                        {}

%%

int yywrap()
{
    return 1;
}