%{
 #include <stdlib.h>
 #include <stdio.h>
 #include <string.h>
 #include "struct.h"
 #include "prog.tab.h"
 char* copy_str(const char* s);
%}

%option noyywrap
%option nounput
%option noinput

%%

"\\begin{algo}" 			{ return PROG_BEGIN;}
"\\end{algo}" 				{ return PROG_END;} 
"\\SET" 					{ return SET;}
"\\IF" 						{ return IF;}
"\\ELSE" 					{ return ELSE;}
"\\FI" 						{ return FI;}
"\\DOWHILE"  				{ return DOWHILE;}
"\\OD" 						{ return OD;}
"\\RETURN" 					{ return RETURN;}
"\\CALL" 					{ return CALL;}

"," 						{return VIRGULE;}
"{" 						{return OPEN_ACCO;}
"}" 						{return CLOSE_ACCO;}
"(" 						{return OPENING_PARENT;}
")" 						{return CLOSING_PARENT;}

"true"						{ yylval.integer = 1; return BOOLEAN; }
"TRUE"						{ yylval.integer = 1; return BOOLEAN; }
"false"						{ yylval.integer = 0; return BOOLEAN; }
"FALSE"						{ yylval.integer = 0; return BOOLEAN; }


[+\-()/*{},] 	{return yytext[0];}
"=="				{ return EQ;}
"!="				{ return NEQ;}
"<"					{ return LT;}
">"					{ return GT;}
"<="				{ return LE;}
">="				{ return GE;}
"!"					{ return NOT;}
"||"				{ return OR;}
"&&"				{ return AND;}

[0-9]+ {yylval.integer=atoi(yytext);return INT;}
[a-zA-Z]+ {yylval.id=copy_str(yytext);return ID;}

. {}
%%

char* copy_str(const char* s) {
  char * id = malloc ((strlen(s) + 1) * sizeof(char));
  if (id == NULL) {
    fprintf(stderr,"Erreur malloc\n");
    exit(EXIT_FAILURE);
  }
  strcpy(id,s);
  return id;
}