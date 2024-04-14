%{
 #include <stdlib.h>
 #include <stdio.h>
 #include <string.h>
 #include <stdbool.h>
 #include <limits.h>
 #include <sys/types.h>
 #include <sys/stat.h>
 #include <unistd.h>
 #include <fcntl.h>
 #include "struct.h"

 void yyerror(const char *str);
 int yylex();
 void debut();
 void fin();
 int incr_label();

 int nb_label;
 sym_table *t;
 stack *p;
%}

%union {
 char* id;
 int integer;
 t_synth synth;
}

%type<integer> lst_args lst_params
%token<integer> INT BOOLEAN
%type<synth> EXPR
%token<id> ID

%token PROG_BEGIN PROG_END
%token SET IF FI ELSE
%token GT LE LT NEQ EQ GE NOT OR AND 
%token DOWHILE OD RETURN CALL
%token OPEN_ACCO CLOSE_ACCO VIRGULE OPENING_PARENT CLOSING_PARENT;

%left OR
%left AND
%right NOT
%left EQ NEQ LT GT LE GE
%left '+' '-'
%left '*' '/'

%start PROG

%%

PROG: PROG_BEGIN OPEN_ACCO ID CLOSE_ACCO 
	{
		t = create_sym_tab($3); 
		p = stack_create();  
		printf(":%s\n",$3);
		printf("\tpush bp\n");
		printf("\tcp bp,sp\n");
	} 
        OPEN_ACCO lst_params CLOSE_ACCO 
        { 
        	t->nb_params_var = $7; 
        }  
       	BLOC 
       	{ 
       		printf("\tconst dx,fin\n");
       		printf("\tjmp dx\n"); 
       	} 
       	PROG_END;
          
lst_params :
	lst_params VIRGULE ID 
	{ 
		add_sym(t, $3, PARAM, pos_from_class(t, PARAM), NUM); 
		$$ = $1 + 1;
	}
	|ID 
	{ 
		add_sym(t, $1, PARAM, pos_from_class(t, PARAM), NUM);
		$$ = 1; 
	}
	| 
	{ 
		$$ = 0; 
	}

BLOC: BLOC INST
      |INST;
EXPR:
 	   EXPR '+' EXPR 
	{  
		if ($1 != NUM || $3 != NUM) { 
			yyerror("ERROR: ADD"); 
		} else { 
			printf("\tpop ax\n");
			printf("\tpop bx\n");
			printf("\tadd ax,bx\n");
			printf("\tpush ax\n");
			$$ = NUM;
		}
	}
	| EXPR '-' EXPR 
	{ 
		if ($1 != NUM && $3 != NUM)  {
			yyerror("ERROR: SUB");
		} else { 
			printf("\tpop ax\n");
			printf("\tpop bx\n");
			printf("\tsub bx,ax\n");
			printf("\tpush bx\n"); 
			$$ = NUM;
		}
	}
	| EXPR '*' EXPR 
	{
		if ($1 != NUM || $3 != NUM) { 
			yyerror("ERROR: MUL"); 
		} else { 
			printf("\tpop ax\n");
			printf("\tpop bx\n");
			printf("\tmul ax,bx\n");
			printf("\tpush ax\n"); 
			$$ = NUM;
		}
	}
	| EXPR '/' EXPR 
	{
		if ($1 != NUM || $3 != NUM) { 
			yyerror("ERROR: DIV"); 
		} else { 
			printf("\tpop ax\n");
			printf("\tpop bx\n");
			printf("\tdiv bx,ax\n");
			printf("\tpush bx\n"); 
			$$ = NUM;
		}
	}
	| OPENING_PARENT EXPR CLOSING_PARENT              
	{ 
		$$ = $2; 
	}
	| EXPR AND EXPR 
	{  
		if ($1 != BOOL_T || $3 != BOOL_T) {
			yyerror("ERROR: AND");  
		} else { 
			printf("\tpop ax\n");
			printf("\tpop bx\n");
			printf("\tmul ax,bx\n");
			printf("\tpush ax\n");
			$$ = BOOL_T;
		}
	}
	| EXPR OR EXPR 
	{  
		if ($1 != BOOL_T || $3 != BOOL_T) { 
			yyerror("ERROR: OR"); 
		} else { 
			printf("\tpop ax\n");
			printf("\tpop bx\n");
			printf("\tadd ax,bx\n");
			printf("\tpush ax\n");
			$$ = BOOL_T;
		}
	}
	| NOT EXPR 
	{
		if ($2 != BOOL_T) { 
			yyerror("ERROR: NOT");
		} else {
			printf("\tpop ax\n"); 
			printf("\tdiv ax,ax\n");
			printf("\tconst bx,1\n");
			printf("\tsub bx,ax\n");
			printf("\tpush bx\n");
			$$ = BOOL_T;
		}  
	}
	| EXPR EQ EXPR 
	{
		if (($1 == NUM && $3 == NUM) || ($1 == BOOL_T && $3 == BOOL_T)) { 
			printf("\tpop bx\n");
			printf("\tpop ax\n"); 
			printf("\txor ax,bx\n");
			printf("\tpush ax\n");
			printf("\tpop ax\n");
			printf("\tdiv ax,ax\n");
			printf("\tconst bx,1\n");
			printf("\tsub bx,ax\n");
			printf("\tpush bx\n");
			$$ = BOOL_T;
		}
		 else { 
			yyerror("ERROR: EQ"); 
		}
	}
	| EXPR NEQ EXPR 
	{
		if (($1 == NUM && $3 == NUM) || ($1 == BOOL_T && $3 == BOOL_T)) { 
			printf("\tpop bx\n");
			printf("\tpop ax\n"); 
			printf("\txor ax,bx\n");
			printf("\tpush ax\n");
			$$ = BOOL_T;
		} else { 
			yyerror("ERROR: NEQ"); 
		}
	}
	| EXPR LT EXPR  
	{ 
		if ($1 != NUM || $3 != NUM) {
			yyerror("ERROR: LT");
		} else { 
			int n = incr_label();
			printf("\tpop bx\n");
			printf("\tpop ax\n"); 
  			printf("\tconst cx,lt_true%d\n", n);
			printf("\tsless ax,bx\n");
			printf("\tjmpc cx\n");
			printf("\tconst ax,0\n");
			printf("\tpush ax\n");
			printf("\tconst cx,lt_false%d\n", n);
			printf("\tjmp cx\n");
			printf(":lt_true%d\n", n);
			printf("\tconst ax,1\n");
			printf("\tpush ax\n");
			printf(":lt_false%d\n", n);
			$$ = BOOL_T; 
		}
	}
	| EXPR GT EXPR 
	{
		if ($1 != NUM || $3 != NUM) {
			yyerror("ERROR: GT");
		} else { 
			int n = incr_label();
			printf("\tpop bx\n");
			printf("\tpop ax\n"); 
			printf("\tconst cx,gt_true%d\n", n);
			printf("\tsless bx,ax\n");
			printf("\tjmpc cx\n");
			printf("\tconst ax,0\n");
			printf("\tpush ax\n");
			printf("\tconst cx,gt_false%d\n", n);
			printf("\tjmp cx\n");
			printf(":gt_true%d\n", n);
			printf("\tconst ax,1\n");
			printf("\tpush ax\n");
			printf(":gt_false%d\n", n);
			$$ = BOOL_T;
		}
	}
	| EXPR LE EXPR { 
		if ($1 != NUM || $3 != NUM) { 
			yyerror("ERROR: LE");
		} else { 
			int n = incr_label();
			printf("\tpop bx\n");
			printf("\tpop ax\n"); 
			printf("\tconst cx,gt_true%d\n", n);
			printf("\tsless bx,ax\n");
			printf("\tjmpc cx\n");
			printf("\tconst ax,0\n");
			printf("\tpush ax\n");
			printf("\tconst cx,gt_false%d\n", n);
			printf("\tjmp cx\n");
			printf(":gt_true%d\n", n);
			printf("\tconst ax,1\n");
 			printf("\tpush ax\n");
			printf(":gt_false%d\n", n);
			printf("\tpop ax\n");
			printf("\tdiv ax,ax\n");
			printf("\tconst bx,1\n");
			printf("\tsub bx,ax\n");
			printf("\tpush bx\n");
			$$ = BOOL_T;
		} 
	}
	| EXPR GE EXPR 
	{ 
		if ($1 != NUM || $3 != NUM) { 
			yyerror("ERROR: GE");
		} else { 
			int n = incr_label();
			printf("\tpop bx\n");
			printf("\tpop ax\n"); 
			printf("\tconst cx,lt_true%d\n", n);
			printf("\tsless ax,bx\n");
			printf("\tjmpc cx\n");
			printf("\tconst ax,0\n");
			printf("\tpush ax\n");
			printf("\tconst cx,lt_false%d\n", n);
			printf("\tjmp cx\n");
			printf(":lt_true%d\n", n);
			printf("\tconst ax,1\n");
			printf("\tpush ax\n");
			printf(":lt_false%d\n", n);
			printf("\tpop ax\n");
			printf("\tdiv ax,ax\n");
			printf("\tconst bx,1\n");
			printf("\tsub bx,ax\n");
			printf("\tpush bx\n");
			$$ = BOOL_T;
		} 
	}
	| BOOLEAN 
	{ 
		printf("\tconst ax,%d\n", yylval.integer);
		printf("\tpush ax\n"); 
		$$ = BOOL_T; 
	}
	| INT
	{
		printf("\tconst ax,%d\n", $1);
		printf("\tpush ax\n");
		$$ = NUM;
	}
	| ID 
	{
		sym_table *sym = find_sym_by_name(t, $1);
		if (sym->class == LOCAL) {
			printf("\tconst bx,%d\n", (int) (2 + 2 * t -> nb_params_var + 2 * sym->pos));
			printf("\tcp cx,bp\n");
			printf("\tsub cx,bx\n");
			printf("\tloadw ax,cx\n");
			printf("\tpush ax\n");
		} else if (sym->class == PARAM) {
			printf("\tconst bx,%d\n", (int) (4 + 2 * t-> nb_params_var - 2 * sym->pos));
			printf("\tcp cx,bp\n");
			printf("\tsub cx,bx\n");
			printf("\tloadw ax,cx\n");
			printf("\tpush ax\n");
		} 
		$$ = sym->type;
	}


lst_args : 
	lst_args VIRGULE EXPR 
 	{ 
 		$$ = $1 + 1;  
 	}
	| EXPR 
	{ 
		$$ = 1; 
	}
	| 
	{
		$$=0;
	};

INST: 
	SET OPEN_ACCO ID CLOSE_ACCO OPEN_ACCO EXPR CLOSE_ACCO 
	{  	
		sym_table *sym = find_sym_by_name(t,$3);
		if (sym == NULL) {
			add_sym(t, $3, LOCAL, pos_from_class(t, LOCAL), $6);
			sym = find_sym_by_name(t,$3);
			t -> nb_local_var += 1;
			printf("\tpop ax\n");
			printf("\tconst bx,%d\n", (int) (2 + 2 * t -> nb_params_var + 2 * sym->pos));
			printf("\tcp cx,bp\n");
			printf("\tsub cx,bx\n");
			printf("\tstorew ax,cx\n");
		} else {
			if (sym->class == LOCAL) {
				printf("\tpop ax\n");
				printf("\tconst bx,%d\n", (int) (2 + 2 * t -> nb_params_var + 2 * sym->pos));
				printf("\tcp cx,bp\n");
				printf("\tsub cx,bx\n");
				printf("\tstorew ax,cx\n");
			} else {
				printf("\tpop ax\n");
				printf("\tconst bx,%d\n", (int) (4 + 2 * t -> nb_params_var - 2 * sym->pos));
				printf("\tcp cx,bp\n");
				printf("\tsub cx,bx\n");
				printf("\tstorew ax,cx\n");
			}
		}
	}
	| IF OPEN_ACCO EXPR CLOSE_ACCO 
	{ 
		int n = incr_label();  
		printf("\tpop ax\n");  
		printf("\tconst cx,fin_if%d\n", n); 
		stack_push(&p,n);  
		printf("\tconst bx,0\n"); 
		printf("\tcmp ax,bx\n"); 
		printf("\tjmpc cx\n"); 
	} BLOC EL
	| DOWHILE 
	{
		int n = incr_label();  
  		stack_push(&p, n);
 		printf(":loop%d\n", n);
	} 
	OPEN_ACCO EXPR CLOSE_ACCO 
	{ 
		if ($4 != BOOL_T) {
    			yyerror("while: type non booleen");
 		 }
  		int pop = stack_pop(&p);
  		printf("\tconst cx,loop_end%d\n", pop);
		stack_push(&p, pop);
		printf("\tpop ax\n");
		printf("\tconst bx,0\n");
		printf("\tcmp ax,bx\n");
		printf("\tjmpz cx\n");
	} 
	BLOC OD 
	{ 
		int pop = stack_pop(&p);
 		printf("\tconst bx,loop%d\n", pop);
  		printf("\tjmp bx\n");
  		printf(":loop_end%d\n", pop);
	}
	| CALL OPEN_ACCO ID CLOSE_ACCO 
	{ 
		printf("\tconst ax,0\n");
		printf("\tpush ax\n"); 
		for (int k = 0; k < t -> nb_local_var; k++) {
			printf("\tpush ax\n");
	  	}
		
	} 
	  OPEN_ACCO lst_args CLOSE_ACCO 
	{ 
		printf("\tconst dx,%s\n", $3);
		printf("\tcall dx\n"); 
		printf("\tconst bx,fin\n");
		printf("\tjmp bx\n");
	}
	| RETURN OPEN_ACCO EXPR CLOSE_ACCO
	{
		printf("\tpop dx\n");
		printf("\tcp cx,bp\n");
		printf("\tconst bx,%d\n", (int) (4 + 2 * ((t -> nb_params_var)) + 2 * ((t -> nb_local_var))));
		printf("\tsub cx,bx\n");
		printf("\tstorew dx,cx\n");
		printf("\tpop bp\n");
		printf("\tret\n");
	} 

EL : ELSE { 
		int pop = stack_pop(&p); 
		printf("\tconst cx,fin_ifel%d\n",pop);
		printf("\tjmp cx\n");
		printf(":fin_if%d\n",pop); 
		stack_push(&p,pop);
	} 
	BLOC FI
	{
		int pop = stack_pop(&p); 
		printf(":fin_ifel%d\n",pop);
	} 
	| FI { 
		int pop = stack_pop(&p); 
		printf(":fin_if%d\n",pop); 
	}; 
%%

int main(int argc, char **argv) {
	if (argc != 2) {
		fprintf(stderr, "Usage: ./prog fichier.tex\n");
		exit(EXIT_FAILURE);
	}
	int fd = open(argv[1], O_RDONLY, 0660);
	if (fd == -1) {
		perror("open");
		exit(EXIT_FAILURE);
	}
	char *str = strtok(argv[1], ".");
	str = strcat(str, ".asm");
	int fdo = open(str, O_RDWR | O_CREAT | O_TRUNC, 0660);
	if (fdo == -1) {
		perror("open");
		exit(EXIT_FAILURE);
	}
	if (dup2(fdo, STDOUT_FILENO) == -1) {
		perror("dup2");
		exit(EXIT_FAILURE);
	}
	if (dup2(fd, STDIN_FILENO) == -1) {
		perror("dup2");
		exit(EXIT_FAILURE);
	}
	

	debut();
	yyparse();
	fin();
 
	dispose_sym_table(t);
	dispose_stack(&p);

	return EXIT_SUCCESS;
}

void debut() {
  printf("\tconst ax,debut\n");
  printf("\tjmp ax\n");
  printf(":nl\n");
  printf("@string \"\\n\"\n");

}

void fin() {
  printf(":val\n");
  printf("@int 0\n");
  printf(":debut\n");
  printf("\tconst bp,pile\n");
  printf("\tconst sp,pile\n");
  printf("\tconst ax,2\n");
  printf("\tsub sp,ax\n");
  printf("\tconst ax,0\n");
  printf("\tpush ax\n");
  
  for (int k = 0; k < (int) t -> nb_local_var; k++) {
    printf("\tpush ax\n");

  }
  
  for (int k = 0; k < (int) t -> nb_params_var; k++) {
    printf("\tconst ax,val\n");
    printf("\tcallscanfd ax\n");
    printf("\tloadw bx,ax\n");
    printf("\tpush bx\n");
  }
  printf("\tconst ax,%s\n", t -> name);
  printf("\tcall ax\n");
  printf(":fin\n");
  for (int k = 0; k < t -> nb_params_var + t -> nb_local_var; k++) {
    printf("\tpop ax\n");
  }
  
  printf("\tcp cx,sp\n");
  printf("\tcallprintfd cx\n");
  printf("\tconst ax,nl\n");
  printf("\tcallprintfs ax\n");
  printf("\tpop ax\n");
  printf("\tend\n");
  printf(":pile\n");
  printf("@int 0\n");
}

void yyerror(const char *str) {
	dispose_sym_table(t);
	dispose_stack(&p);
	fprintf(stderr, "%s\n", str);
}

int incr_label(){
	return nb_label++;
}