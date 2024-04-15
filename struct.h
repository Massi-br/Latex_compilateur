#ifndef _STRUCT_H
#define _STRUCT_H


typedef enum type_synth {
	NUM, BOOL_T, ERR_0, ERR_T, NONE
} t_synth;

typedef enum { 
	PARAM, LOCAL, FUNC 
} sym_class;

typedef struct sym_table sym_table;
typedef struct stack stack;

struct sym_table {
  char *name;
  sym_class class;
  t_synth type;
  unsigned int pos;
  size_t nb_params_var;
  size_t nb_local_var;
  sym_table *next;
};

struct stack {
    int size;
    int top;
    int *data;
};

/*
		FONCTIONS TABLE SYMBOLES
*/
sym_table *create_sym_tab(const char *sym_name);
int add_sym(sym_table *s, const char *name, sym_class c, int pos, t_synth tp);
int pos_from_class (sym_table *s, sym_class c );
void dispose_sym_table(sym_table *s);
sym_table *find_sym_by_name (sym_table *t, const char *s);

/*
		FONCTIONS PILE
*/
stack *stack_create();
int stack_pop(stack **s);
void stack_push(stack **s, int value);
void dispose_stack(stack **s);
 
#endif 
