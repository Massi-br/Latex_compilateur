#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "struct.h"
/*
	symbol table functions
*/
sym_table *create_sym_tab(const char *name) {
	sym_table *s = malloc(sizeof *s);
	if (s == NULL) {
		return NULL;
	}
	s->name = malloc(strlen(name) * sizeof(char));
	strcpy(s->name, name);
	s->class = FUNC;
	s->type = NONE;
	s->pos = 0;
	s->nb_local_var = 0;
	s->nb_params_var = 0;
	s->next = NULL;
	return s;
}

void dispose_sym_table(sym_table *s) {
	if (s == NULL) {
	return;
	}
	sym_table *p = s;
	while (p != NULL) {
		free(p->name);
		sym_table *q = p;
		p = p->next;
		free(q);
 	}
	s = NULL;
}

sym_table *find_sym_by_name(sym_table *s, const char *name) {
	sym_table *p = s;
 	while (p != NULL && strcmp(p->name, name) !=0) {
	    p = p->next;
	}
	return p;
}

int add_sym(sym_table *s, const char *name, sym_class class, int position, t_synth type) {
	sym_table *q = s;
	while (q->next != NULL && strcmp(q->name, name) != 0) {
		q = q->next;
	}
	if (q->next == NULL && strcmp(q->name, name) != 0) {
		sym_table *p = malloc(sizeof(*p));
		p->name = malloc(strlen(name) * sizeof(char));
		strcpy(p->name, name);
		p->nb_local_var = 0;
		p->class = class;
		p->type = type;
		p->pos = position;
		p->nb_params_var = 0;
		p->next = NULL;
		q->next = p;
		return 0;
	} else {
		return -1;
	}
}

int pos_from_class(sym_table *s, sym_class c ) {
	int rslt = 0;
	sym_table *p = s;
	while(p != NULL) {
		if (p->class == c) {
			rslt = p->pos;
		}
		p = p->next;
	}
	return rslt + 1;
}

/*
	Stack functions
*/

stack *stack_create() {
	stack *s = malloc(sizeof(s));
	if (s == NULL) {
		fprintf(stderr, "Error: unable to create the stack\n");
		exit(EXIT_FAILURE);
	}
	s->data = NULL;
	s->size = 0;
	s->top = -1;
 return s;
}

void stack_push(stack **s, int value) {
	if (*s == NULL) {
		*s = stack_create();
	}
	if ((*s)->top == (*s)->size - 1) {
		(*s)->size += 10;
		(*s)->data = realloc((*s)->data, (*s)->size * sizeof(int));
		if ((*s)->data == NULL) {
			fprintf(stderr, "Error: unable to push %d onto the stack\n", value);
			exit(EXIT_FAILURE);
		}
	}
	(*s)->top += 1;
	(*s)->data[(*s)->top] = value;
}

int stack_pop(stack **s) {
	if (*s == NULL || (*s)->top < 0) {
		fprintf(stderr, "Error: unable to pop from an empty stack\n");
		exit(EXIT_FAILURE);
	}
	int value = (*s)->data[(*s)->top];
	(*s)->top -= 1;
	return value;
}

void dispose_stack(stack **s) {
	if (*s == NULL) {
		return;
	}
	free((*s)->data);
	free(*s);
	*s = NULL;
}

