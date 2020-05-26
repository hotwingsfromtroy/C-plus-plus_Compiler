%{
    #include<stdio.h>
    #include<stdlib.h>
    #include<string.h>
    #include<stdarg.h>
    #include "extra.h"

    extern int line_no;
    char datatype[30];

    int new_scope=0, current_scope= 0;
    int scope_code_size = 100, scope_size=200;

    int scope_code_array[100], scope_code_n=0;
    
    int temp_mem_location = 0;

    int label_num = 0;

    int end_compilation = 0;


    void push_scope(int scope_code)
    {
        if(scope_code_n<(scope_code_size-1))
        {
            scope_code_n++;
            scope_code_array[scope_code_n] = scope_code;
        }
    }

    int pop_scope()
    {
        if(scope_code_n>=0)
            scope_code_n--;
        return scope_code_array[scope_code_n+1];
    }

    typedef struct sym_node
    {
        int scope;
        char datatype[30];
        char *value;

        char name[100];
       
    }sym_node;


    typedef struct symbol_table
    {
        sym_node *table[1000];
        int table_size;
        
    }symbol_table;

    symbol_table S;

    void Initialize_Symbol_Table()
    {
        S.table_size = 0; 
    }

    void insert_sym_node(sym_node *N)
    {
        if(S.table_size <= 998)
        {
            ++S.table_size;
            S.table[S.table_size-1] = N;
        }
    }

    char* convert_char_to_ascii(char* character)
    {
        int *number;
        char temp;
        if(character[0] == '\\')
        {
            if(character[1] == 'n')
                temp = '\n';
            else if(character[1] == 't')
                temp = '\t';
            else if(character[1] == 'a')
                temp = '\a';
            else if(character[1] == 'b')
                temp = '\b';
            else if(character[1] == 'r')
                temp = '\r';
        }
        else
            temp = character[0];
        *number = temp;
        char *ascii_val = (char*)malloc(5*sizeof(char));
        itoa(*number, ascii_val, 10);
        return ascii_val;
    }

    int check_for_id(char *name, int scope)
    {
        for(int i = 0; i<S.table_size; i++)
        {
            if(S.table[i]->scope == scope && (strcmp(S.table[i]->name, name)==0))
                return 1;
        }   
        return 0;
    }

    int check_validity(char *name)
    {
        for(int j = 0; j<S.table_size; j++)
        {
            if(S.table[j]->scope == current_scope && (strcmp(S.table[j]->name, name)==0))
            {
                return current_scope;
            }
            for(int i = scope_code_n; i >= 0; i--)
            {
                if(S.table[j]->scope == scope_code_array[i] && (strcmp(S.table[j]->name, name)==0))
                {
                    return scope_code_array[i];
                }

            }  
        }

        return -1;
    }


    typedef struct err_node
    {
        int line_no;
        char error_code[100];
        char error_desc[1000];
    }err_node;

    typedef struct error_table
    {
        err_node *table[1000];
        int table_size;
    }error_table;

    error_table E;
    
    void Initialize_Error_Table()
    {
        E.table_size = 0;
    }

    void insert_err_node(err_node *N)
    {
        if(E.table_size <= 998)
        {
            ++E.table_size;
            E.table[E.table_size-1] = N;
            
        }
        
    }


    void yyerror (char const *s) 
    {
        fprintf (stderr, "%s\n", s);
        err_node *err_temp = (err_node*)malloc(sizeof(err_node));
        err_temp->line_no = line_no;
        strcpy(err_temp->error_code, "");
        strcpy(err_temp->error_desc, "THIS LINE IS FAULTY");
        insert_err_node(err_temp);

        end_compilation = 1;

    }


    typedef struct TreeNode
    {
        char *node_type;
        int no_of_links;
        int scope;
        struct TreeNode *children[100];
        char *node_value;
        int line_no;

    }TreeNode;


    typedef struct ParseTree
    {
        TreeNode *root;
    }ParseTree;

    ParseTree *tree;

    ParseTree* create_tree(TreeNode *root)
    {
        ParseTree *temp = (ParseTree*)malloc(sizeof(ParseTree));
        temp->root = root;
        return temp;
    }

    TreeNode* create_node(char *node_type, char *node_value, int scope, int line_no, int no_of_links, ...)
    {
        TreeNode *temp = (TreeNode*)malloc(sizeof(TreeNode));
        temp->node_type = node_type;
        temp->node_value = node_value;
        temp->no_of_links = no_of_links;
        temp->scope = scope;
        temp->line_no = line_no;
        va_list list;

        va_start(list, no_of_links);
        for(int i = 0;i<no_of_links; i++)
        {
            temp->children[i] = va_arg(list, TreeNode*);
        }

        va_end(list);

        return temp;

    }


    int check_datatype(char* datatype)
    {
        if(!strcmp(datatype, "bool") || !strcmp(datatype, "BOOL"))
            return 1;

        if(!strcmp(datatype, "unsigned char") || !strcmp(datatype, "signed char") || \
        !strcmp(datatype, "char") || !strcmp(datatype, "wchar_t") || !strcmp(datatype, "CHAR")) 
            return 2;

        if(!strcmp(datatype, "short int") || !strcmp(datatype, "unsigned short int") || \
        !strcmp(datatype, "unsigned int") || !strcmp(datatype, "int") || !strcmp(datatype, "long int") || \
        !strcmp(datatype, "unsigned long int") || !strcmp(datatype, "long long int") || \
        !strcmp(datatype, "unsigned long long int") || !strcmp(datatype, "INTEGER"))
            return 3;

        
        if(!strcmp(datatype, "float") || !strcmp(datatype, "double") || \
        !strcmp(datatype, "long double") || !strcmp(datatype, "FLOAT"))
            return 4;
        
    }



    TreeNode* check_id_group(TreeNode *node, char *datatype)
    {
        TreeNode *temp_group = node;
        TreeNode *temp_root = (TreeNode*)malloc(sizeof(TreeNode));
        temp_root->children[0] = temp_root->children[1] = NULL;
        temp_root->children[2] = temp_group;
        TreeNode *prev = temp_root;

        int i = 0;
        while(temp_group->no_of_links == 3 || temp_group->no_of_links == 2)
        {
            TreeNode *temp_id_init = temp_group->children[0];

            TreeNode *temp_identifier = temp_id_init->children[0];

            if(check_for_id(temp_identifier->node_value, temp_identifier->scope))
            {
                err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                err_temp->line_no = temp_identifier->line_no;
                strcpy(err_temp->error_code, "");
                strcpy(err_temp->error_desc, strcat(temp_identifier->node_value, " - variable of same name and scope already defined"));
                insert_err_node(err_temp);

                end_compilation = 1;

                if(temp_group->no_of_links==2)
                {
                    if(prev->children[0]==NULL)
                        prev->children[2] = NULL;
                    else
                    {
                        prev->children[1] = temp_group->children[1];
                        prev->no_of_links=2;
                    }
                    break;
                }
                else
                {
                    prev->children[2] = temp_group->children[2];
                    temp_group = prev->children[2];
                    continue;
                }
                
            }

            sym_node *sym_temp = (sym_node*)malloc(sizeof(sym_node));
            strcpy(sym_temp->datatype, datatype);
            strcpy(sym_temp->name, temp_identifier->node_value); 
            sym_temp->scope = temp_identifier->scope;
            // printf("%s\n", temp_id_init->node_value);
            if(!strcmp(temp_id_init->node_value, "ID_TRES"))
            {
                int check_err = 0;
                int check_val = 0;
                TreeNode *temp_data = temp_id_init->children[2];

                if(!strcmp(temp_data->node_type, "STRING"))
                {
                    check_err = 1;
                }

                if(check_err)
                {
                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                    err_temp->line_no = temp_id_init->line_no;
                    strcpy(err_temp->error_code, "");
                    strcpy(err_temp->error_desc, "datatype mismatch");
                    insert_err_node(err_temp);

                    end_compilation = 1;

                    if(temp_group->no_of_links==2)
                    {
                        if(prev->children[0]==NULL)
                            prev->children[2] = NULL;
                        else
                        {
                            prev->children[1] = temp_group->children[1];
                            prev->no_of_links=2;
                        }
                        free(sym_temp);
                        break;
                    }
                    else
                    {
                        prev->children[2] = temp_group->children[2];
                        temp_group = prev->children[2];
                        free(sym_temp);
                        continue;
                    }

                }
               

                if(!check_err)
                {
                    sym_temp->value = (char*)malloc(strlen(temp_data->node_value)*sizeof(char));
                    strcpy(sym_temp->value, temp_data->node_value);
                    // printf("%s\n", sym_temp->value);
                }
            }

            insert_sym_node(sym_temp);
            
            prev = temp_group;
            if(prev->no_of_links == 2)
                break;
            temp_group = temp_group->children[2];
            i++;
        }

        return temp_root->children[2];
        
    }





    typedef struct TAC_subnode
    {
        char *node_type;
        char *node_value;
        char *datatype;
    }TAC_subnode;

    
    
    TAC_subnode* init_TAC_subnode(char *node_type, int arg_num, ...)
    {

        TAC_subnode *temp = (TAC_subnode*)malloc(sizeof(TAC_subnode));

        temp->node_type = strdup(node_type);

        va_list list;

        va_start(list, arg_num);

        if(arg_num > 0)
        {
            temp->node_value = strdup(va_arg(list, char*));
        }
        if(arg_num > 1)
        {
            temp->datatype = strdup(va_arg(list, char*));
        }

        va_end(list);
        return temp;
    }


    typedef struct TAC
    {
        TAC_subnode *op, *arg1, *arg2, *result;
        int line_no;
        struct TAC *next;

    }TAC;

    TAC* init_TAC(TAC_subnode *op, TAC_subnode *arg1, TAC_subnode *arg2, TAC_subnode *result, int line_no)
    {
        TAC *temp = (TAC*)malloc(sizeof(TAC));
        temp->op = op;
        temp->arg1 = arg1;
        temp->arg2 = arg2;
        temp->result = result;
        temp->line_no = line_no;
        temp->next = NULL;
        return temp;
    }

    typedef struct TAC_Table
    {
        TAC *head;
        TAC *tail;
        int size;
    }TAC_Table;
    TAC_Table *tactable;

    TAC_Table* init_TAC_Table()
    {
        TAC_Table *temp = (TAC_Table*)malloc(sizeof(TAC_Table));
        temp->head = temp->tail = NULL;
        temp->size =0;
        return temp;
    }

    void add_to_TAC_Table(TAC_subnode *op, TAC_subnode *arg1, TAC_subnode *arg2, TAC_subnode *result, int line_no)
    {
        TAC *new_row = init_TAC(op, arg1, arg2, result, line_no);
        if(!tactable->size)
        {
            tactable->head = tactable->tail = new_row;
        }
        else
        {
            tactable->tail->next = new_row;
            tactable->tail = tactable->tail->next;
        }
        tactable->size++;
    }   



    void print_quad_row(char *op, char *arg1, char *arg2, char *result)
    {

        printf("%s\t\t%s\t\t%s\t\t%s\n",op, arg1, arg2, result);
    }


    void print_TAC_Table(TAC_Table *tactable)
    {
        if(tactable->size)
        {
            TAC *temp = tactable->head;
            do
            {
                print_quad_row(temp->op->node_value, temp->arg1->node_value, temp->arg2->node_value, temp->result->node_value);
                temp = temp->next;
            }
            while(temp!= NULL);
        }
    }



    char* type_decoder(int i)
    {
        if(i == 1)
            return("BOOL");

        if(i == 2)
            return("CHAR");
        
        if(i == 3)
            return("INTEGER");
        
        if(i == 4)
            return("FLOAT");
        
        
    }


    char* type_conversion_bin(TAC_subnode *arg1, TAC_subnode *arg2)
    {
        int a1 = check_datatype(arg1->datatype);
        int a2 = check_datatype(arg2->datatype);

        if((a1 <= 2 && a2 <= 2))
            return type_decoder(3);

        a1 = a1>a2? a1: a2;
        return type_decoder(a1);
    }


    char* type_conversion_un(TAC_subnode *arg)
    {
        int a = check_datatype(arg->datatype);
        if(a <= 2)
            return type_decoder(3);

        return type_decoder(a);
    }


    


    char* generate_numbered_label(char *text, int *number)
    {
        char *num = (char*)malloc(5*sizeof(char));
        itoa(*number, num, 10);
        (*number)++;
        char *temp = strdup(text);
        return strcat(temp, num);
    }


    int check_bin_op_permissibility(TAC_subnode *op, TAC_subnode *arg1, TAC_subnode *arg2)
    {
        if(!strcmp(op->node_value, "|") || !strcmp(op->node_value, "^") || !strcmp(op->node_value, "&") || !strcmp(op->node_value, "%") ||\
           op->node_value[0] == '|' || op->node_value[0] == '^' || op->node_value[0] == '&' || op->node_value[0] == '%')
            if( check_datatype(arg1->datatype) > 3 || check_datatype(arg2->datatype) > 3)
                return 0;
        return 1;
    }


    int check_un_op_permissibility(TAC_subnode *op, TAC_subnode *arg)
    {
        if(!strcmp(op->node_value, "~"))
            if( check_datatype(arg->datatype) > 3 )
                return 0;
        return 1;
    }


    TAC_subnode* icg(TreeNode *root)
    {
        if(end_compilation)
            return NULL;
        int chk_icg = 0;

        if(!strcmp(root->node_type, "IDENTIFIER"))
        {
            chk_icg =1;
            char *id;
            char *temp = (char*)malloc(20*sizeof(char));
            strcpy(temp, root->node_value);

            char *scope = (char*)malloc(4*sizeof(char));

            itoa(root->scope, scope, 10);

            id = strcat(temp, ":");
            id = strcat(id, scope);

            TAC_subnode *temp_tsnode = NULL;

            for(int i = 0 ; i<S.table_size; i++)
            {
                if(!strcmp(S.table[i]->name, root->node_value) && S.table[i]->scope==root->scope)
                {
                    temp_tsnode = init_TAC_subnode("VARIABLE", 2, id,  type_decoder(check_datatype(S.table[i]->datatype)));
                    break;
                }
            }

            return temp_tsnode;
        }


        else if(!strcmp(root->node_type, "BOOL"))
        {
            chk_icg =1;
            TAC_subnode *temp_tsnode = init_TAC_subnode("LITERAL", 2, root->node_value, "BOOL");
            
            return temp_tsnode;
        }
        else if(!strcmp(root->node_type, "CHAR"))
        {
            chk_icg =1;
            TAC_subnode *temp_tsnode = init_TAC_subnode("LITERAL", 2, root->node_value, "CHAR"); 
            return temp_tsnode;
        }
        else if(!strcmp(root->node_type, "INTEGER"))
        {
            chk_icg =1;
            TAC_subnode *temp_tsnode = init_TAC_subnode("LITERAL", 2, root->node_value, "INTEGER");
            return temp_tsnode;
        }
        else if(!strcmp(root->node_type, "FLOAT"))
        {
            chk_icg =1;
            TAC_subnode *temp_tsnode = init_TAC_subnode("LITERAL", 2, root->node_value, "FLOAT");
            return temp_tsnode;
        }
        else if(!strcmp(root->node_type, "STRING") || !strcmp(root->node_type, "ENDL"))
        {
            chk_icg =1;
            TAC_subnode *temp_string = init_TAC_subnode("LITERAL", 2, root->node_value, "STRING");

            TAC_subnode *temp_null = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_op = init_TAC_subnode("OPERATOR", 1, "=");
            TAC_subnode *temp_result = init_TAC_subnode("VARIABLE", 2, generate_numbered_label("t", &temp_mem_location), "STRING");

            add_to_TAC_Table(temp_op, temp_string, temp_null, temp_result, root->line_no);

            return temp_result;
        }
        else if(!strcmp(root->node_type, "ASGN_OP") || !strcmp(root->node_type, "LOG_OR_OP") || !strcmp(root->node_type, "LOG_AND_OP") || \
                !strcmp(root->node_type, "BIT_OR_OP") || !strcmp(root->node_type, "BIT_XOR_OP") || !strcmp(root->node_type, "BIT_AND_OP") || \
                !strcmp(root->node_type, "EQ_OP") || !strcmp(root->node_type, "REL_OP") || !strcmp(root->node_type, "PLUS_MINUS_OP") || \
                !strcmp(root->node_type, "MUL_DIV_MOD_OP") || !strcmp(root->node_type, "NOT_OP") || !strcmp(root->node_type, "BIT_NOT_OP") || \
                !strcmp(root->node_type, "INC_DEC_OP"))
        {
            chk_icg =1;
            TAC_subnode *temp_tsnode = init_TAC_subnode("OPERATOR", 1, root->node_value);
            return temp_tsnode;
        }
    
        else if(!strcmp(root->node_type, "ID_INIT"))
        {
            chk_icg =1;

            if(!strcmp(root->node_value, "ID_TRES"))
            {
                TAC_subnode *result = icg(root->children[0]);
                TAC_subnode *op = icg(root->children[1]);
                TAC_subnode *arg1 = icg(root->children[2]);
                TAC_subnode *temp_null = init_TAC_subnode("NULL", 1, " ");

                add_to_TAC_Table(op, arg1, temp_null, result, root->line_no);
                return result;
            }
        }



        else if(!strcmp(root->node_type, "EXPRESSION"))
        {
            chk_icg =1;

            if(root->no_of_links ==3)
            {
                if(!strcmp(root->children[0]->node_type, "PARAN"))
                {   
                        return icg(root->children[1]);
                }
                
                TAC_subnode *arg1 = icg(root->children[0]);
                TAC_subnode *op = icg(root->children[1]); 
                TAC_subnode *arg2 = icg(root->children[2]);

                if(!check_bin_op_permissibility(op, arg1, arg2))
                {
                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                    err_temp->line_no = root->line_no;
                    strcpy(err_temp->error_code, "");
                    char *err_desc = strdup("invalid operands of types '");
                    err_desc = strcat(err_desc, arg1->datatype);
                    err_desc = strcat(err_desc, "' and '");
                    err_desc = strcat(err_desc, arg2->datatype);
                    err_desc = strcat(err_desc, "' to binary operator '");
                    err_desc = strcat(err_desc, op->node_value);
                    err_desc = strcat(err_desc, "'");
                    strcpy(err_temp->error_desc, err_desc);
                    insert_err_node(err_temp);
                    end_compilation = 1;
                }


                TAC_subnode *result = init_TAC_subnode("VARIABLE", 2, generate_numbered_label("t", &temp_mem_location), type_conversion_bin(arg1, arg2));

                if(!strcmp(op->node_value,"=") || !strcmp(op->node_value,"+=") || !strcmp(op->node_value,"-=") || \
                !strcmp(op->node_value,"*=") ||  !strcmp(op->node_value,"/=") || !strcmp(op->node_value,"%=") || \
                !strcmp(op->node_value,"&=") || !strcmp(op->node_value,"^=") || !strcmp(op->node_value,"|="))
                {
                    if(strcmp(op->node_value,"="))
                    {
                        if(op->node_value[0]=='+')
                            op->node_value = strdup("+");
                        else if(op->node_value[0]=='-')
                            op->node_value = strdup("-");
                        else if(op->node_value[0]=='*')
                            op->node_value = strdup("*");
                        else if(op->node_value[0]=='/')
                            op->node_value = strdup("/");
                        else if(op->node_value[0]=='%')
                            op->node_value = strdup("%");
                        else if(op->node_value[0]=='&')
                            op->node_value = strdup("&");
                        else if(op->node_value[0]=='^')
                            op->node_value = strdup("^");
                        else if(op->node_value[0]=='|')
                            op->node_value = strdup("|");
  
                        add_to_TAC_Table(op, arg1, arg2, result, root->line_no);

                        TAC_subnode *temp_eq = init_TAC_subnode("OPERATOR", 1, "=");
                        TAC_subnode *temp_null = init_TAC_subnode("NULL", 1, " ");

                        add_to_TAC_Table(temp_eq, result, temp_null, arg1, root->line_no);
                        return arg1;

                    }
                    TAC_subnode *temp_null = init_TAC_subnode("NULL", 1, " ");
                    if(strcmp(arg1->node_type, "LITERAL") )
                    {
                        add_to_TAC_Table(op, arg2, temp_null, arg1, root->line_no);
                        return arg1;
                    }
                    else
                    {
                        err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                        err_temp->line_no = root->line_no;
                        strcpy(err_temp->error_code, "");
                        char *err_desc = strdup("lvalue required");
                        strcpy(err_temp->error_desc, err_desc);
                        insert_err_node(err_temp);
                        end_compilation = 1;
                        return NULL;
                    }
                    
                }
               
                add_to_TAC_Table(op, arg1, arg2, result, root->line_no);               
                return result;
            }
            else if(root->no_of_links==2)
            {
                if(!strcmp(root->node_value, "expr10"))
                {
                    TAC_subnode* op = icg(root->children[0]);
                    TAC_subnode* arg1 = icg(root->children[1]);
                    
                    if(!check_un_op_permissibility(op, arg1))
                    {
                        err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                        err_temp->line_no = root->line_no;
                        strcpy(err_temp->error_code, "");
                        char *err_desc = strdup(" wrong type argument to bit-complement");
                        
                        strcpy(err_temp->error_desc, err_desc);
                        insert_err_node(err_temp);
                        end_compilation = 1;
                    }

                    if(!strcmp(op->node_value, "--") || !strcmp(op->node_value, "++"))
                    {
                        TAC_subnode *arg2 = init_TAC_subnode("LITERAL", 1, "1", "INTEGER");
                        if(!strcmp(op->node_value, "--"))
                            op->node_value = strdup("-");
                        else
                            op->node_value = strdup("+");
                        TAC_subnode *result = init_TAC_subnode("VARIABLE", 2, arg1->node_value, arg1->datatype);
                        add_to_TAC_Table(op, arg1, arg2, result, root->line_no);
                        return result;
                    }

                    TAC_subnode *result = init_TAC_subnode("VARIABLE", 2, generate_numbered_label("t", &temp_mem_location), type_conversion_un(arg1));
                    TAC_subnode *temp_null = init_TAC_subnode("NULL", 1, " ");
                    add_to_TAC_Table(op, arg1, temp_null, result, root->line_no);
                    return result;
                }
                else if(!strcmp(root->node_value, "expr11"))
                {
                    TAC_subnode* op = icg(root->children[1]);
                    TAC_subnode* arg1 = icg(root->children[0]);
                    TAC_subnode *arg2 = init_TAC_subnode("LITERAL", 2, "1", "INTEGER");
                    TAC_subnode *result= init_TAC_subnode("VARIABLE", 2, generate_numbered_label("t", &temp_mem_location), type_conversion_bin(arg1, arg2));

                    if(!strcmp(op->node_value, "--"))
                        op->node_value = strdup("-");
                    else
                        op->node_value = strdup("+");

                    TAC_subnode *temp_eq = init_TAC_subnode("OPERATOR", 1, "=");
                    TAC_subnode *temp_null = init_TAC_subnode("NULL", 1, " ");

                    add_to_TAC_Table(temp_eq, arg1, temp_null, result, root->line_no);
                    add_to_TAC_Table(op, arg1, arg2, arg1, root->line_no);
                    return result;                                       
                }
            }
            
            return NULL;
        }


        else if(!strcmp(root->node_type, "RETURN_CONSTRUCT"))
        {
            chk_icg =1;

            TAC_subnode *arg1 = icg(root->children[1]);
            TAC_subnode *temp_null_1 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_null_2 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_return = init_TAC_subnode("OPERATOR", 1, "return");
            add_to_TAC_Table(temp_return, arg1, temp_null_1, temp_null_2, root->line_no);
        }
        
        else if(!strcmp(root->node_type, "CONDITION"))
        {
            chk_icg =1;
            TAC_subnode *result = icg(root->children[1]);
            return result;
        }

        else if(!strcmp(root->node_type, "IF_CONSTRUCT"))
        {
            chk_icg =1;

            char *if_label_1, *if_label_2;
            if_label_1 = generate_numbered_label("L", &label_num);
            if_label_2 = generate_numbered_label("L", &label_num);

            /////////////////////////////////////////////////////////////////////////////
            TAC_subnode *arg1 = icg(root->children[1]);
            TAC_subnode *temp_if = init_TAC_subnode("OPERATOR", 1, "ifFalse");
            TAC_subnode *temp_label_1 = init_TAC_subnode("OPERATOR", 1, if_label_1);
            TAC_subnode *temp_null_1 = init_TAC_subnode("NULL", 1, " ");

            add_to_TAC_Table(temp_if, arg1, temp_null_1, temp_label_1, root->line_no);
            /////////////////////////////////////////////////////////////////////////////
           
            icg(root->children[2]);
            
            /////////////////////////////////////////////////////////////////////////////
            TAC_subnode *temp_goto = init_TAC_subnode("OPERATOR", 1, "goto");
            TAC_subnode *temp_null_2 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_null_3 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_label_2 = init_TAC_subnode("OPERATOR", 1, if_label_2);

            add_to_TAC_Table(temp_goto, temp_null_2, temp_null_3, temp_label_2, root->line_no);
            /////////////////////////////////////////////////////////////////////////////

            /////////////////////////////////////////////////////////////////////////////            
            TAC_subnode *temp_null_4 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_null_5 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_label_op_1 = init_TAC_subnode("OPERATOR", 1, "Label");
            TAC_subnode *temp_label_3 = init_TAC_subnode("OPERATOR", 1, if_label_1);

            add_to_TAC_Table(temp_label_op_1, temp_null_4, temp_null_5, temp_label_3, root->line_no);
            /////////////////////////////////////////////////////////////////////////////

            icg(root->children[3]);

            /////////////////////////////////////////////////////////////////////////////
            TAC_subnode *temp_null_6 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_null_7 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_label_op_2 = init_TAC_subnode("OPERATOR", 1, "Label");
            TAC_subnode *temp_label_4 = init_TAC_subnode("OPERATOR", 1, if_label_2);

            add_to_TAC_Table(temp_label_op_2, temp_null_6, temp_null_7, temp_label_4, root->line_no); 
            /////////////////////////////////////////////////////////////////////////////

        }


        else if(!strcmp(root->node_type, "FOR_CONSTRUCT"))
        {
            chk_icg =1;

            char *for_label_1, *for_label_2;
            for_label_1 = generate_numbered_label("L", &label_num);
            for_label_2 = generate_numbered_label("L", &label_num);


            icg(root->children[2]);

            /////////////////////////////////////////////////////////////////////////////
            TAC_subnode *temp_label_op_1 = init_TAC_subnode("OPERATOR", 1, "Label");
            TAC_subnode *temp_null_1 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_null_2 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_label_1 = init_TAC_subnode("OPERATOR", 1, for_label_1);

            add_to_TAC_Table(temp_label_op_1, temp_null_1, temp_null_2, temp_label_1, root->line_no);
            /////////////////////////////////////////////////////////////////////////////

            TAC_subnode *arg1 = icg(root->children[3]->children[0]);

            /////////////////////////////////////////////////////////////////////////////
            TAC_subnode *temp_if = init_TAC_subnode("OPERATOR", 1, "ifFalse");
            TAC_subnode *temp_null_3 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_label_2 = init_TAC_subnode("OPERATOR", 1, for_label_2);
            
            add_to_TAC_Table(temp_if, arg1, temp_null_3, temp_label_2, root->line_no);
            /////////////////////////////////////////////////////////////////////////////

            icg(root->children[6]);

            icg(root->children[4]);

            /////////////////////////////////////////////////////////////////////////////
            TAC_subnode *temp_goto = init_TAC_subnode("OPERATOR", 1, "goto");
            TAC_subnode *temp_null_4 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_null_5 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_label_3 = init_TAC_subnode("OPERATOR", 1, for_label_1);

            add_to_TAC_Table(temp_goto, temp_null_4, temp_null_5, temp_label_3, root->line_no);
            /////////////////////////////////////////////////////////////////////////////


            /////////////////////////////////////////////////////////////////////////////
            TAC_subnode *temp_label_op_2 = init_TAC_subnode("OPERATOR", 1, "Label");
            TAC_subnode *temp_null_6 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_null_7 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_label_4 = init_TAC_subnode("OPERATOR", 1, for_label_2);

            add_to_TAC_Table(temp_label_op_2, temp_null_6, temp_null_7, temp_label_4, root->line_no);
            /////////////////////////////////////////////////////////////////////////////


        }

        else if(!strcmp(root->node_type, "WHILE_CONSTRUCT"))
        {
            chk_icg = 1;
            char *while_label_1, *while_label_2;
            while_label_1 = generate_numbered_label("L", &label_num);
            while_label_2 = generate_numbered_label("L", &label_num);

            /////////////////////////////////////////////////////////////////////////////
            TAC_subnode *temp_label_op_1 = init_TAC_subnode("OPERATOR", 1, "Label");
            TAC_subnode *temp_null_1 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_null_2 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_label_1 = init_TAC_subnode("OPERATOR", 1, while_label_1);

            add_to_TAC_Table(temp_label_op_1, temp_null_1, temp_null_2, temp_label_1, root->line_no);
            /////////////////////////////////////////////////////////////////////////////

            TAC_subnode *arg1 = icg(root->children[1]);

            /////////////////////////////////////////////////////////////////////////////
            TAC_subnode *temp_if = init_TAC_subnode("OPERATOR", 1, "ifFalse");
            TAC_subnode *temp_null_3 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_label_2 = init_TAC_subnode("OPERATOR", 1, while_label_2);

            add_to_TAC_Table(temp_if, arg1, temp_null_3, temp_label_2, root->line_no);
            /////////////////////////////////////////////////////////////////////////////

            icg(root->children[2]);

            /////////////////////////////////////////////////////////////////////////////
            TAC_subnode *temp_goto = init_TAC_subnode("OPERATOR", 1, "goto");
            TAC_subnode *temp_null_4 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_null_5 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_label_3 = init_TAC_subnode("OPERATOR", 1, while_label_1);

            add_to_TAC_Table(temp_goto, temp_null_4, temp_null_5, temp_label_3, root->line_no);
            /////////////////////////////////////////////////////////////////////////////

            /////////////////////////////////////////////////////////////////////////////
            TAC_subnode *temp_label_op_2 = init_TAC_subnode("OPERATOR", 1, "Label");
            TAC_subnode *temp_null_6 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_null_7 = init_TAC_subnode("NULL", 1, " ");
            TAC_subnode *temp_label_4 = init_TAC_subnode("OPERATOR", 1, while_label_2);

            add_to_TAC_Table(temp_label_op_2, temp_null_6, temp_null_7, temp_label_4, root->line_no);
            /////////////////////////////////////////////////////////////////////////////

        }

        else if(!strcmp(root->node_type, "OUTPUT"))
        {
            chk_icg = 1;

            TreeNode *op_vals = root->children[1];
            while(!strcmp(op_vals->node_type, "OP_VALS"))
            {
                TAC_subnode *op = init_TAC_subnode("FUNCTION", 1, "cout");
                TAC_subnode *arg1 = icg(op_vals->children[1]);
                TAC_subnode *temp_null_1 = init_TAC_subnode("NULL", 1, " ");
                TAC_subnode *temp_null_2 = init_TAC_subnode("NULL", 1, " ");
                add_to_TAC_Table(op, arg1, temp_null_1, temp_null_2, root->line_no);
                op_vals = op_vals->children[2];
            }            
        }

        if(!chk_icg)
        {
            for(int i = 0; i<root->no_of_links; i++)
            {
                icg(root->children[i]);
            }
        }


        return NULL;
    }




    void print_tab(int n)
    {   
        for(int i =0;i<n; i++)
            printf("\t");
    }

    void print_parse_tree(TreeNode *root, int sub)
    {
        print_tab(sub);
        printf("NODE: %s (%s)\n", root->node_type, root->node_value);
        for(int i = 0; i<root->no_of_links; i++)
        {   

            print_parse_tree(root->children[i], sub+1);
        }

    }


    void* convert_val(TAC_subnode *arg, char *datatype)
    {
        void *final = NULL;
        if(!strcmp(datatype, "INTEGER"))
        {
            int *temp_final = (int*)malloc(sizeof(int));
            *temp_final = atoi(arg->node_value);
        
            final = temp_final;
        }
        else if(!strcmp(datatype, "FLOAT"))
        {
            float *temp_final = (float*)malloc(sizeof(float));
            *temp_final = atof(arg->node_value);
        
            final = temp_final;
        }

        return final;
    }


    int *binary_op_int(int *arg1, int *arg2, char *op)
    {
        int *final = (int*)malloc(sizeof(int));
        if(!strcmp(op, "+"))            *final = *arg1 + *arg2;
        else if(!strcmp(op, "-"))       *final = *arg1 - *arg2;
        else if(!strcmp(op, "*"))       *final = *arg1 * *arg2;
        else if(!strcmp(op, "/"))       *final = *arg1 / *arg2;
        else if(!strcmp(op, "%"))       *final = *arg1 % *arg2;
        else if(!strcmp(op, "&"))       *final = *arg1 & *arg2;
        else if(!strcmp(op, "^"))       *final = *arg1 ^ *arg2;
        else if(!strcmp(op, "|"))       *final = *arg1 | *arg2;
        else if(!strcmp(op, "||"))      *final = *arg1 || *arg2;
        else if(!strcmp(op, "&&"))      *final = *arg1 && *arg2;
        else if(!strcmp(op, "=="))      *final = *arg1 == *arg2;
        else if(!strcmp(op, "!="))      *final = *arg1 != *arg2;
        else if(!strcmp(op, "<"))       *final = *arg1 < *arg2;
        else if(!strcmp(op, "<="))      *final = *arg1 <= *arg2;
        else if(!strcmp(op, ">"))       *final = *arg1 > *arg2;
        else if(!strcmp(op, ">="))      *final = *arg1 >= *arg2;
        return final;
    }

    float *binary_op_float(float *arg1, float *arg2, char *op)
    {
        float *final = (float*)malloc(sizeof(float));
        if(!strcmp(op, "+"))            *final = *arg1 + *arg2;
        else if(!strcmp(op, "-"))       *final = *arg1 - *arg2;
        else if(!strcmp(op, "*"))       *final = *arg1 * *arg2;
        else if(!strcmp(op, "/"))       *final = *arg1 / *arg2;
        else if(!strcmp(op, "||"))      *final = *arg1 || *arg2;
        else if(!strcmp(op, "&&"))      *final = *arg1 && *arg2;
        else if(!strcmp(op, "=="))      *final = *arg1 == *arg2;
        else if(!strcmp(op, "!="))      *final = *arg1 != *arg2;
        else if(!strcmp(op, "<"))       *final = *arg1 < *arg2;
        else if(!strcmp(op, "<="))      *final = *arg1 <= *arg2;
        else if(!strcmp(op, ">"))       *final = *arg1 > *arg2;
        else if(!strcmp(op, ">="))      *final = *arg1 >= *arg2;
        return final;
    }

    int *unary_op_int(int *arg, char *op)
    {
        int *final = (int*)malloc(sizeof(int));
        if(!strcmp(op, "+"))            *final =  + *arg;
        else if(!strcmp(op, "-"))       *final = - *arg;
        else if(!strcmp(op, "!"))       *final = ! *arg;
        else if(!strcmp(op, "~"))       *final = ~ *arg;
        return final;
    }

    float *unary_op_float(float *arg, char *op)
    {
        float *final = (float*)malloc(sizeof(float));
        if(!strcmp(op, "+"))            *final =  + *arg;
        else if(!strcmp(op, "-"))       *final = - *arg;
        else if(!strcmp(op, "!"))       *final = ! *arg;
        return final;
    }


    void binary_operation(TAC **row)
    {      
        if(!strcmp((*row)->result->datatype, "INTEGER"))
        {
            int *arg1 = (int*)convert_val((*row)->arg1, "INTEGER");
            int *arg2 = (int*)convert_val((*row)->arg2, "INTEGER");
            int *new_arg = binary_op_int(arg1, arg2, (*row)->op->node_value);
            (*row)->op = init_TAC_subnode("OPERATOR", 1, "=");
            (*row)->arg2 = init_TAC_subnode("NULL", 1, " ");
            (*row)->arg1 =  init_TAC_subnode("LITERAL", 2, " ", "INTEGER");
            itoa(*new_arg, (*row)->arg1->node_value, 10);          
        }
        else if(!strcmp((*row)->result->datatype, "FLOAT"))
        {
            float *arg1 = (float*)convert_val((*row)->arg1, "FLOAT");
            float *arg2 = (float*)convert_val((*row)->arg2, "FLOAT");
            float *new_arg = binary_op_float(arg1, arg2, (*row)->op->node_value);
            (*row)->op = init_TAC_subnode("OPERATOR", 1, "=");
            (*row)->arg2 = init_TAC_subnode("NULL", 1, " ");
            (*row)->arg1 =  init_TAC_subnode("LITERAL", 2, " ", "FLOAT");
            ftoa(*new_arg, (*row)->arg1->node_value, 5);
        }
    }
    
    void unary_operation(TAC **row)
    {
        if(!strcmp((*row)->result->datatype, "INTEGER"))
        {
            int *arg = (int*)convert_val((*row)->arg1, "INTEGER");
            int *new_arg = unary_op_int(arg, (*row)->op->node_value);
            (*row)->op = init_TAC_subnode("OPERATOR", 1, "=");
            (*row)->arg1 =  init_TAC_subnode("LITERAL", 2, " ", "INTEGER");
            itoa(*new_arg, (*row)->arg1->node_value, 10);
        }
        else if(!strcmp((*row)->result->datatype, "FLOAT"))
        {
            float *arg = (float*)convert_val((*row)->arg1, "FLOAT");
            float *new_arg = unary_op_float(arg, (*row)->op->node_value);
            (*row)->op = init_TAC_subnode("OPERATOR", 1, "=");
            (*row)->arg1 =  init_TAC_subnode("LITERAL", 2, " ", "FLOAT");
            ftoa(*new_arg, (*row)->arg1->node_value, 5);
        }
    }



    void constant_folding(TAC_Table *tactable)
    {

        if(tactable->size)
        {
            TAC *temp = tactable->head;
            do
            {
                if( !strcmp(temp->arg1->node_type, "LITERAL") && !strcmp(temp->arg2->node_type, "LITERAL") )
                {
                    binary_operation(&temp);
                }
                else if(!strcmp(temp->arg1->node_type, "LITERAL") && !strcmp(temp->arg2->node_type, "NULL") &&\
                        strcmp(temp->op->node_value, "ifFalse") && strcmp(temp->op->node_value, "cout") && strcmp(temp->op->node_value, "="))
                {
                    unary_operation(&temp);
                }

                temp = temp->next;
            }
            while(temp!= NULL);
        }

    }



    int check_for_val(TAC *row, int tactable_size, char *var )
    {
        TAC *temp = row;
        if(tactable_size)
        {
            while(temp!=NULL)
            {
                if( (!strcmp(temp->arg1->node_type, "VARIABLE") && !strcmp(temp->arg1->node_value, var)) || \
                    (!strcmp(temp->arg2->node_type, "VARIABLE") && !strcmp(temp->arg2->node_value, var))    )              
                        return 1;
                if( (!strcmp(temp->result->node_type, "VARIABLE") && !strcmp(temp->result->node_value, var)) )
                    return 0;
                temp = temp->next;
            }   
        }
        return 0;
    }


    void unused_var_elimination(TAC_Table *tactable)
    {
        if(tactable->size)
        {
            TAC *temp = tactable->head;
            

            temp = tactable->head;
            int chk = 0, flip = 1;
            TAC *prev_temp = NULL;
            do
            {
                if(!strcmp(temp->result->node_type, "VARIABLE"))
                {

                    if(!check_for_val(temp->next, tactable->size, temp->result->node_value))
                    {
                        if(!chk)
                        {
                            tactable->head = temp->next;
                            free(temp);
                            temp = tactable->head;
                            tactable->size--;
                            chk--;
                        }
                        else
                        {
                            prev_temp->next = temp->next;
                            free(temp);
                            temp = prev_temp->next;
                            tactable->size--;
                            flip = 0;
                        }
                    }
                }
                chk++;
                
                if(chk && flip)
                {
                    prev_temp = temp;
                    temp = temp->next;
                }

                flip = 1;
            }
            while(temp!= NULL);
        }
    }

    void dead_code_elimination(TAC_Table *tactable)
    {
        int size_before, size_after;
        do
        {
            size_before = tactable->size;
            unused_var_elimination(tactable);
            size_after = tactable->size;
        }
        while(size_before-size_after);
    }




    void print_AC(int tab, char *code)
    {
        print_tab(tab);
        printf("%s\n", code);
    }


    char registers[12][5] = {"R0", "R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9", "R10", "R11"};

    char **reg_table;
    
    char** build_reg_table()
    {
        char **temp = (char**)malloc(12 * sizeof(char*));
        for(int i = 0; i <12; i++)
            temp[i] = strdup("");
        return temp;
    }


    int purge_var(TAC *row, char *variable)
    {
        TAC *temp = row;
        while(temp != NULL)
        {
            if(!strcmp(temp->arg1->node_value, variable) || !strcmp(temp->arg2->node_value, variable) || !strcmp(temp->result->node_value, variable))
            {
                return 0;
            }
            temp = temp->next;
        }        
        return 1;
    }

    int purge_add_reg(TAC *row,char *variable)
    {
        TAC *temp = row;
        while(temp != NULL)
        {
            if( !strcmp(temp->result->node_value, variable) )
                return 1;
            if(!strcmp(temp->arg1->node_value, variable) || !strcmp(temp->arg2->node_value, variable) )
                return 0;

            temp =temp->next;
        }
        return 1;
    }

    int is_variable(char *variable)
    {
        for(int i = 0; i < strlen(variable); i++)
            if(variable[i] == ':')
                return 1;
        return 0;
    }



    int assign_reg(char *variable)
    {
        for(int i = 0; i <12; i++ )
        {
            if(strlen(reg_table[i]) == 0)
            {
                reg_table[i] =  strdup(variable);
                return i;
            }
        }
        return -1;
    }


    int is_reg_assigned(char* variable)
    {
        for(int i = 0; i < 12; i++)
        {
            if(!strcmp(reg_table[i], variable))
                return i;
        }
        return -1;
    }


    void assembly_code(TAC_Table *tactable)
    {
        printf("\n\n\n");
        printf("TARGET CODE\n");
        printf("____________________________________________________________________\n");


        reg_table = build_reg_table();
        if(tactable->size)
        {
            print_AC(0, "start:");
            TAC *temp = tactable->head;

            do
            {
                if(!strcmp(temp->op->node_value, "Label") )
                {
                    char *code = strdup(temp->result->node_value);
                    code = strcat(code, ":");
                    print_AC(0, code);
                }
                else if(!strcmp(temp->op->node_value, "goto") )
                {
                    char *code = strdup("B ");
                    code = strcat(code, temp->result->node_value);
                    
                    print_AC(1, code);
                }
                else if(!strcmp(temp->op->node_value, "ifFalse") )
                {
                    char *code;
                    if( !strcmp(temp->arg1->node_type, "VARIABLE") )
                    {
                        char *variable = strdup(temp->arg1->node_value);
                        if(is_variable(variable))
                        {
                            int var_addr_reg = is_reg_assigned(variable);
                            if(var_addr_reg == -1)
                            {
                                var_addr_reg = assign_reg(variable);
                                if(var_addr_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[var_addr_reg]);
                                code = strcat(code, ", =");
                                code = strcat(code, variable);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }
                            char *addr_code = strdup("[");
                            addr_code = strcat(addr_code, registers[var_addr_reg]);
                            addr_code = strcat(addr_code, "]");
                            
                            int var_val_reg = is_reg_assigned(addr_code);
                            if(var_val_reg == -1)
                            {
                                var_val_reg = assign_reg(addr_code);
                                if(var_val_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[var_val_reg]);
                                code = strcat(code, ", ");
                                code = strcat(code, addr_code);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }

                            if(purge_var(temp->next, variable))
                                reg_table[var_addr_reg]= strdup("");

                            if(purge_add_reg(temp->next, variable))
                                reg_table[var_val_reg] = strdup("");

                            code = strdup("CMP ");
                            code = strcat(code, registers[var_val_reg]);

                        }
                        else
                        {
                            int var_val_reg = is_reg_assigned(variable);
                            if( var_val_reg == -1 )
                                var_val_reg = assign_reg(variable);
                            if(var_val_reg == -1)
                            {
                                err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                err_temp->line_no = temp->line_no;
                                strcpy(err_temp->error_code, "");
                                
                                strcpy(err_temp->error_desc, "out of memory!");
                                insert_err_node(err_temp);
                                end_compilation = 1;
                                return;
                            }
                            if(purge_var(temp->next, variable))
                                reg_table[var_val_reg]= strdup("");


                            code = strdup("CMP ");
                            code = strcat(code, registers[var_val_reg]);
                        }
                    }




                    else if( !strcmp(temp->arg1->node_type, "LITERAL") )
                    {
                        code = strdup("CMP ");
                        code = strcat(code, "#");
                        code = strcat(code, temp->arg1->node_value);
                    }


                    code = strcat(code, ", #0");
                    print_AC(1, code);
                    
                    code = strdup("BEQ ");
                    code = strcat(code, temp->result->node_value);
                    

                    print_AC(1, code);
                }




                else if( (!strcmp(temp->op->node_value, "=") && strcmp(temp->arg1->node_type, "STRING") ) || \
                        !strcmp(temp->op->node_value, "~") || \
                       (!strcmp(temp->op->node_value, "+") && !strcmp(temp->arg2->node_value, "NULL")) || \
                        !strcmp(temp->op->node_value, "!"))
                {
                    char *code;
                    char *lhs, *rhs, *r_variable, *l_variable, *r_addr_code;
                    int lhs_var_addr_reg = -1, lhs_var_val_reg  =-1, rhs_var_addr_reg =-1, rhs_var_val_reg= -1; 

                    r_variable = strdup(temp->arg1->node_value);

                    if( !strcmp(temp->arg1->node_type, "VARIABLE") )
                    {
                        if(is_variable(r_variable))
                        {
                            rhs_var_addr_reg = is_reg_assigned(r_variable);
                            if(rhs_var_addr_reg == -1)
                            {
                                rhs_var_addr_reg = assign_reg(r_variable);
                                if(rhs_var_addr_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[rhs_var_addr_reg]);
                                code = strcat(code, ", =");
                                code = strcat(code, r_variable);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }
                            r_addr_code = strdup("[");
                            r_addr_code = strcat(r_addr_code, registers[rhs_var_addr_reg]);
                            r_addr_code = strcat(r_addr_code, "]");
                            
                            rhs_var_val_reg = is_reg_assigned(r_addr_code);
                            if(rhs_var_val_reg == -1)
                            {
                                rhs_var_val_reg = assign_reg(r_addr_code);
                                if(rhs_var_val_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[rhs_var_val_reg]);
                                code = strcat(code, ", ");
                                code = strcat(code, r_addr_code);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }

                            rhs = strdup(registers[rhs_var_val_reg]);
                        }
                        else
                        {
                            rhs_var_val_reg = is_reg_assigned(r_variable);
                            if( rhs_var_val_reg == -1 )
                                rhs_var_val_reg = assign_reg(r_variable);
                            if(rhs_var_val_reg == -1)
                            {
                                err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                err_temp->line_no = temp->line_no;
                                strcpy(err_temp->error_code, "");
                                
                                strcpy(err_temp->error_desc, "out of memory!");
                                insert_err_node(err_temp);
                                end_compilation = 1;
                                return;
                            }
                            rhs = strdup(registers[rhs_var_val_reg]);
                          
                        }
                    }
                    else if( !strcmp(temp->arg1->node_type, "LITERAL") )
                    {
                        rhs = strdup("#");
                        rhs = strcat(rhs, temp->arg1->node_value);
                    }


                    l_variable = strdup(temp->result->node_value);

                    if( !strcmp(temp->result->node_type, "VARIABLE") )
                    {
                        if(is_variable(l_variable))
                        {
                            lhs_var_addr_reg = is_reg_assigned(l_variable);
                            if(lhs_var_addr_reg == -1)
                            {
                                lhs_var_addr_reg = assign_reg(l_variable);
                                if(lhs_var_addr_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[lhs_var_addr_reg]);
                                code = strcat(code, ", =");
                                code = strcat(code, l_variable);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }
                            lhs = strdup("[");
                            lhs = strcat(lhs, registers[lhs_var_addr_reg]);
                            lhs = strcat(lhs, "]");
                            
                      
                        }
                        else
                        {
                            lhs_var_val_reg = is_reg_assigned(l_variable);
                            if( lhs_var_val_reg == -1 )
                                lhs_var_val_reg = assign_reg(l_variable);
                            if(lhs_var_val_reg == -1)
                            {
                                err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                err_temp->line_no = temp->line_no;
                                strcpy(err_temp->error_code, "");
                                
                                strcpy(err_temp->error_desc, "out of memory!");
                                insert_err_node(err_temp);
                                end_compilation = 1;
                                return;
                            }
                            lhs = strdup(registers[lhs_var_val_reg]);

                        }
                    }
                    

                    if(!strcmp(temp->op->node_value, "=") || !strcmp(temp->op->node_value, "+"))
                    {
                        if(lhs[0] == '[')
                        {
                            code = strdup("STR ");
                            code=  strcat(code, rhs);
                            code = strcat(code, ", ");
                            code = strcat(code, lhs);
                        }
                        else
                        {
                            code = strdup("MOV ");
                            code=  strcat(code, lhs);
                            code = strcat(code, ", ");
                            code = strcat(code, rhs);
                        }
                        print_AC(1, code);
                    }
                    else if(!strcmp(temp->op->node_value, "~"))
                    {
                        if(lhs[0] == '[')
                        {
                            int temp_reg = assign_reg("@@@");
                            code = strdup("MVN ");
                            code = strcat(code, registers[temp_reg]);
                            code=  strcat(code, ", ");
                            code = strcat(code, rhs);
                            print_AC(1, code);

                            code = strdup("STR ");
                            code=  strcat(code, registers[temp_reg]);
                            code = strcat(code, ", ");
                            code = strcat(code, lhs);
                            print_AC(1, code);
                            reg_table[temp_reg] = strdup("");
                        }
                        else
                        {
                            code = strdup("MVN ");
                            code=  strcat(code, lhs);
                            code = strcat(code, ", ");
                            code = strcat(code, rhs);
                        }
                        print_AC(1, code);
                    }
                    else if(!strcmp(temp->op->node_value, "!"))
                    {
                        int temp_reg = assign_reg("@@@");
                        code = strdup("MOV ");
                        code = strcat(code, registers[temp_reg]);
                        code = strcat(code, ", #0");
                        print_AC(1, code);

                        code = strdup("CMP ");
                        code=  strcat(code, rhs);
                        code = strcat(code, ", #0");
                        print_AC(1, code);

                        code = strdup("MOVEQ ");
                        code = strcat(code, registers[temp_reg]);
                        code = strcat(code, ", #1");
                        print_AC(1, code);

                        if(lhs[0] == '[')
                        {
                            code = strdup("STR ");
                            code=  strcat(code, registers[temp_reg]);
                            code = strcat(code, ", ");
                            code = strcat(code, lhs);
                            print_AC(1, code);
                        }
                        else
                        {
                            code = strdup("MOV ");
                            code=  strcat(code, lhs);
                            code = strcat(code, ", ");
                            code = strcat(code, registers[temp_reg]);
                        }

                        reg_table[temp_reg] = strdup("");
                        print_AC(1, code);
                    }


                    if(rhs_var_addr_reg != -1)
                    {
                        if(purge_var(temp->next, r_variable))
                            reg_table[rhs_var_addr_reg]= strdup("");
                        
                        if(purge_add_reg(temp->next, r_variable))
                            reg_table[rhs_var_val_reg] = strdup("");      
                    }
                    else
                        if(purge_var(temp->next, r_variable))
                            reg_table[rhs_var_val_reg]= strdup("");

                    if(lhs_var_addr_reg != -1)
                        if(purge_var(temp->next, l_variable))
                            reg_table[lhs_var_addr_reg]= strdup("");
                    else
                        if(purge_var(temp->next, l_variable))
                            reg_table[lhs_var_val_reg]= strdup("");
    
                }



                if( (!strcmp(temp->op->node_value, "+") && strcmp(temp->arg2->node_value, "NULL")) || \
                    (!strcmp(temp->op->node_value, "-") && strcmp(temp->arg2->node_value, "NULL")) || \
                   !strcmp(temp->op->node_value, "*") || !strcmp(temp->op->node_value, "/") || \
                   !strcmp(temp->op->node_value, "&") || !strcmp(temp->op->node_value, "|") || \
                   !strcmp(temp->op->node_value, "^") \
                   || !strcmp(temp->op->node_value, "||") || !strcmp(temp->op->node_value, "&&"))
                {

                    char *code;
                    char *lhs, *rhs, *eq, *r_variable, *l_variable, *e_variable, *r_addr_code, *l_addr_code, *e_addr_code;
                    int lhs_var_addr_reg = -1, lhs_var_val_reg  =-1, rhs_var_addr_reg =-1, rhs_var_val_reg= -1, eq_var_addr_reg = -1, eq_var_val_reg = -1; 
                    
                    r_variable = strdup(temp->arg2->node_value);
                    if( !strcmp(temp->arg2->node_type, "VARIABLE") )
                    {
                        
                        if(is_variable(r_variable))
                        {

                            rhs_var_addr_reg = is_reg_assigned(r_variable);
                            if(rhs_var_addr_reg == -1)
                            {
                                rhs_var_addr_reg = assign_reg(r_variable);
                                if(rhs_var_addr_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[rhs_var_addr_reg]);
                                code = strcat(code, ", =");
                                code = strcat(code, r_variable);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }
                            r_addr_code = strdup("[");
                            r_addr_code = strcat(r_addr_code, registers[rhs_var_addr_reg]);
                            r_addr_code = strcat(r_addr_code, "]");
                            
                            rhs_var_val_reg = is_reg_assigned(r_addr_code);
                            if(rhs_var_val_reg == -1)
                            {
                                rhs_var_val_reg = assign_reg(r_addr_code);
                                if(rhs_var_val_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[rhs_var_val_reg]);
                                code = strcat(code, ", ");
                                code = strcat(code, r_addr_code);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }

                            rhs = strdup(registers[rhs_var_val_reg]);
                        }
                        else
                        {
                            rhs_var_val_reg = is_reg_assigned(r_variable);
                            if( rhs_var_val_reg == -1 )
                                rhs_var_val_reg = assign_reg(r_variable);
                            if(rhs_var_val_reg == -1)
                            {
                                err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                err_temp->line_no = temp->line_no;
                                strcpy(err_temp->error_code, "");
                                
                                strcpy(err_temp->error_desc, "out of memory!");
                                insert_err_node(err_temp);
                                end_compilation = 1;
                                return;
                            }
                            rhs = strdup(registers[rhs_var_val_reg]);
                          
                        }
                    }
                    else if( !strcmp(temp->arg2->node_type, "LITERAL") )
                    {
                        rhs = strdup("#");
                        rhs = strcat(rhs, temp->arg2->node_value);
                    }


                    l_variable = strdup(temp->arg1->node_value);

                    if( !strcmp(temp->arg1->node_type, "VARIABLE") )
                    {
                        if(is_variable(l_variable))
                        {
                            lhs_var_addr_reg = is_reg_assigned(l_variable);
                            if(lhs_var_addr_reg == -1)
                            {
                                lhs_var_addr_reg = assign_reg(l_variable);
                                if(lhs_var_addr_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[lhs_var_addr_reg]);
                                code = strcat(code, ", =");
                                code = strcat(code, l_variable);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }
                            l_addr_code = strdup("[");
                            l_addr_code = strcat(l_addr_code, registers[lhs_var_addr_reg]);
                            l_addr_code = strcat(l_addr_code, "]");
                            
                            lhs_var_val_reg = is_reg_assigned(l_addr_code);
                            if(lhs_var_val_reg == -1)
                            {
                                lhs_var_val_reg = assign_reg(l_addr_code);
                                if(lhs_var_val_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[lhs_var_val_reg]);
                                code = strcat(code, ", ");
                                code = strcat(code, l_addr_code);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }

                            lhs = strdup(registers[lhs_var_val_reg]);
                        }
                        else
                        {
                            lhs_var_val_reg = is_reg_assigned(l_variable);
                            if( lhs_var_val_reg == -1 )
                                lhs_var_val_reg = assign_reg(l_variable);
                            if(rhs_var_val_reg == -1)
                            {
                                err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                err_temp->line_no = temp->line_no;
                                strcpy(err_temp->error_code, "");
                                
                                strcpy(err_temp->error_desc, "out of memory!");
                                insert_err_node(err_temp);
                                end_compilation = 1;
                                return;
                            }
                            lhs = strdup(registers[lhs_var_val_reg]);
                          
                        }
                    }
                    else if( !strcmp(temp->arg1->node_type, "LITERAL") )
                    {
                        lhs = strdup("#");
                        // code = strcat(code, "#");
                        lhs = strcat(lhs, temp->arg1->node_value);
                    }


                    e_variable = strdup(temp->result->node_value);
                    
                    if( !strcmp(temp->result->node_type, "VARIABLE") )
                    {
                        if(is_variable(e_variable))
                        {
                            eq_var_addr_reg = is_reg_assigned(e_variable);
                            if(eq_var_addr_reg == -1)
                            {
                                eq_var_addr_reg = assign_reg(e_variable);
                                if(eq_var_addr_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[eq_var_addr_reg]);
                                code = strcat(code, ", =");
                                code = strcat(code, e_variable);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }
                            eq = strdup("[");
                            eq = strcat(eq, registers[eq_var_addr_reg]);
                            eq = strcat(eq, "]");
                            
                      
                        }
                        else
                        {
                            eq_var_val_reg = is_reg_assigned(e_variable);
                            if( eq_var_val_reg == -1 )
                                eq_var_val_reg = assign_reg(e_variable);
                            if(lhs_var_val_reg == -1)
                            {
                                err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                err_temp->line_no = temp->line_no;
                                strcpy(err_temp->error_code, "");
                                
                                strcpy(err_temp->error_desc, "out of memory!");
                                insert_err_node(err_temp);
                                end_compilation = 1;
                                return;
                            }
                            eq = strdup(registers[eq_var_val_reg]);

                        }
                    }
                    



                    if(!strcmp(temp->op->node_value, "||") || !strcmp(temp->op->node_value, "&&"))
                    {
                        // int temp_reg;
                        if(eq[0] == '[')
                        {
                            int temp_reg = assign_reg("@@@");
                            code = strdup("MOV ");
                            code = strcat(code, registers[temp_reg]);
                            code = strcat(code, ", #0");
                            print_AC(1, code);

                            if(!strcmp(temp->op->node_value, "||"))
                            {
                                code = strdup("CMP ");
                                code = strcat(code, lhs);
                                code = strcat(code, ", #0");
                                print_AC(1, code);

                                code = strdup("MOVNE ");
                                code = strcat(code, registers[temp_reg]);
                                code = strcat(code, ", #1");
                                print_AC(1, code);

                                code = strdup("CMP ");
                                code = strcat(code, rhs);
                                code = strcat(code, ", #0");
                                print_AC(1, code);

                                code = strdup("MOVNE ");
                                code = strcat(code, registers[temp_reg]);
                                code = strcat(code, ", #1");
                                print_AC(1, code);
                            }
                            else
                            {
                                code = strdup("CMP ");
                                code = strcat(code, lhs);
                                code = strcat(code, ", #0");
                                print_AC(1, code);

                                code = strdup("CMPNE ");
                                code = strcat(code, rhs);
                                code = strcat(code, ", #0");
                                print_AC(1, code);

                                code = strdup("MOVNE ");
                                code = strcat(code, registers[temp_reg]);
                                code = strcat(code, ", #1");
                                print_AC(1, code);
                            }

                            code = strdup("STR ");
                            code = strcat(code, registers[temp_reg]);
                            code = strcat(code, ", ");
                            code = strcat(code, eq);
                            print_AC(1, code);
                            reg_table[temp_reg] = strdup("");
                        }
                        else
                        {
                            code = strdup("MOV ");
                            code = strcat(code, eq);
                            code = strcat(code, ", #0");
                            print_AC(1, code);

                            if(!strcmp(temp->op->node_value, "||"))
                            {
                                code = strdup("CMP ");
                                code = strcat(code, lhs);
                                code = strcat(code, ", #0");
                                print_AC(1, code);

                                code = strdup("MOVNE ");
                                code = strcat(code, eq);
                                code = strcat(code, ", #1");
                                print_AC(1, code);

                                code = strdup("CMP ");
                                code = strcat(code, rhs);
                                code = strcat(code, ", #0");
                                print_AC(1, code);

                                code = strdup("MOVNE ");
                                code = strcat(code, eq);
                                code = strcat(code, ", #1");
                                print_AC(1, code);
                            }
                            else
                            {
                                code = strdup("CMP ");
                                code = strcat(code, lhs);
                                code = strcat(code, ", #0");
                                print_AC(1, code);

                                code = strdup("CMPNE ");
                                code = strcat(code, rhs);
                                code = strcat(code, ", #0");
                                print_AC(1, code);

                                code = strdup("MOVNE ");
                                code = strcat(code, eq);
                                code = strcat(code, ", #1");
                                print_AC(1, code);
                            }



                        }
                    }

                    else
                    {
                        if(!strcmp(temp->op->node_value, "+"))
                            code = strdup("ADD ");
                        else if(!strcmp(temp->op->node_value, "-"))
                            code = strdup("SUB ");
                        else if(!strcmp(temp->op->node_value, "*"))
                            code = strdup("MUL ");
                        else if(!strcmp(temp->op->node_value, "/"))
                            code = strdup("UDIV ");///////////////////////////////////////////////////////////////////////
                        else if(!strcmp(temp->op->node_value, "&"))
                            code = strdup("AND ");
                        else if(!strcmp(temp->op->node_value, "|"))
                            code = strdup("ORR ");
                        else if(!strcmp(temp->op->node_value, "^"))
                            code = strdup("EOR ");

                        if(eq[0] == '[')
                        {
                            int temp_reg = assign_reg("@@@");
                            code = strcat(code, registers[temp_reg]);
                            code = strcat(code, ", ");
                            code = strcat(code, lhs);
                            code = strcat(code, ", ");
                            code = strcat(code, rhs);
                            print_AC(1, code);

                            code = strdup("STR ");
                            code = strcat(code, registers[temp_reg]);
                            code = strcat(code, ", ");
                            code = strcat(code, eq);
                            print_AC(1, code);
                            reg_table[temp_reg] = strdup("");
                        }
                        else
                        {
                            code = strcat(code, eq);
                            code = strcat(code, ", ");
                            code = strcat(code, lhs);
                            code = strcat(code, ", ");
                            code = strcat(code, rhs);
                            print_AC(1, code);
                        }
                    }

                    if(rhs_var_addr_reg != -1)
                    {
                        if(purge_var(temp->next, r_variable))
                            reg_table[rhs_var_addr_reg]= strdup("");
                        
                        if(purge_add_reg(temp->next, r_variable))
                            reg_table[rhs_var_val_reg] = strdup("");      
                    }
                    else
                        if(purge_var(temp->next, r_variable))
                            reg_table[rhs_var_val_reg]= strdup("");

                    if(lhs_var_addr_reg != -1)
                    {
                        if(purge_var(temp->next, l_variable))
                            reg_table[lhs_var_addr_reg]= strdup("");
                        
                        if(purge_add_reg(temp->next, l_variable))
                            reg_table[lhs_var_val_reg] = strdup("");      
                    }
                    else
                        if(purge_var(temp->next, l_variable))
                            reg_table[lhs_var_val_reg]= strdup("");
                                                            
                    if(eq_var_addr_reg != -1)
                        if(purge_var(temp->next, e_variable))
                            reg_table[eq_var_addr_reg]= strdup("");
                    else
                        if(purge_var(temp->next, e_variable))
                            reg_table[eq_var_val_reg]= strdup("");

                }






                if(!strcmp(temp->op->node_value, ">") || !strcmp(temp->op->node_value, ">=") || \
                   !strcmp(temp->op->node_value, ">=") || !strcmp(temp->op->node_value, ">=") || \
                   !strcmp(temp->op->node_value, "==") || !strcmp(temp->op->node_value, "!="))
                {

                    char *code;
                    char *lhs, *rhs, *eq, *r_variable, *l_variable, *e_variable, *r_addr_code, *l_addr_code, *e_addr_code;
                    int lhs_var_addr_reg = -1, lhs_var_val_reg  =-1, rhs_var_addr_reg =-1, rhs_var_val_reg= -1, eq_var_addr_reg = -1, eq_var_val_reg = -1; 
                    
                    r_variable = strdup(temp->arg2->node_value);
                    if( !strcmp(temp->arg2->node_type, "VARIABLE") )
                    {
                        
                        if(is_variable(r_variable))
                        {

                            rhs_var_addr_reg = is_reg_assigned(r_variable);
                            if(rhs_var_addr_reg == -1)
                            {
                                rhs_var_addr_reg = assign_reg(r_variable);
                                if(rhs_var_addr_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[rhs_var_addr_reg]);
                                code = strcat(code, ", =");
                                code = strcat(code, r_variable);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }
                            r_addr_code = strdup("[");
                            r_addr_code = strcat(r_addr_code, registers[rhs_var_addr_reg]);
                            r_addr_code = strcat(r_addr_code, "]");
                            
                            rhs_var_val_reg = is_reg_assigned(r_addr_code);
                            if(rhs_var_val_reg == -1)
                            {
                                rhs_var_val_reg = assign_reg(r_addr_code);
                                if(rhs_var_val_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[rhs_var_val_reg]);
                                code = strcat(code, ", ");
                                code = strcat(code, r_addr_code);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }

                            rhs = strdup(registers[rhs_var_val_reg]);
                        }
                        else
                        {
                            rhs_var_val_reg = is_reg_assigned(r_variable);
                            if( rhs_var_val_reg == -1 )
                                rhs_var_val_reg = assign_reg(r_variable);
                            if(rhs_var_val_reg == -1)
                            {
                                err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                err_temp->line_no = temp->line_no;
                                strcpy(err_temp->error_code, "");
                                
                                strcpy(err_temp->error_desc, "out of memory!");
                                insert_err_node(err_temp);
                                end_compilation = 1;
                                return;
                            }
                            rhs = strdup(registers[rhs_var_val_reg]);
                        }
                    }
                    else if( !strcmp(temp->arg2->node_type, "LITERAL") )
                    {
                        rhs = strdup("#");
                        // code = strcat(code, "#");
                        rhs = strcat(rhs, temp->arg2->node_value);
                    }


                    l_variable = strdup(temp->arg1->node_value);

                    if( !strcmp(temp->arg1->node_type, "VARIABLE") )
                    {
                        if(is_variable(l_variable))
                        {
                            lhs_var_addr_reg = is_reg_assigned(l_variable);
                            if(lhs_var_addr_reg == -1)
                            {
                                lhs_var_addr_reg = assign_reg(l_variable);
                                if(lhs_var_addr_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[lhs_var_addr_reg]);
                                code = strcat(code, ", =");
                                code = strcat(code, l_variable);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }
                            l_addr_code = strdup("[");
                            l_addr_code = strcat(l_addr_code, registers[lhs_var_addr_reg]);
                            l_addr_code = strcat(l_addr_code, "]");
                            
                            lhs_var_val_reg = is_reg_assigned(l_addr_code);
                            if(lhs_var_val_reg == -1)
                            {
                                lhs_var_val_reg = assign_reg(l_addr_code);
                                if(lhs_var_val_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[lhs_var_val_reg]);
                                code = strcat(code, ", ");
                                code = strcat(code, l_addr_code);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }

                            lhs = strdup(registers[lhs_var_val_reg]);
                        }
                        else
                        {
                            lhs_var_val_reg = is_reg_assigned(l_variable);
                            if( lhs_var_val_reg == -1 )
                                lhs_var_val_reg = assign_reg(l_variable);
                            if(rhs_var_val_reg == -1)
                            {
                                err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                err_temp->line_no = temp->line_no;
                                strcpy(err_temp->error_code, "");
                                
                                strcpy(err_temp->error_desc, "out of memory!");
                                insert_err_node(err_temp);
                                end_compilation = 1;
                                return;
                            }
                            lhs = strdup(registers[lhs_var_val_reg]);
                          
                        }
                    }
                    else if( !strcmp(temp->arg1->node_type, "LITERAL") )
                    {
                        lhs = strdup("#");
                        // code = strcat(code, "#");
                        lhs = strcat(lhs, temp->arg1->node_value);
                    }


                    e_variable = strdup(temp->result->node_value);
                    
                    if( !strcmp(temp->result->node_type, "VARIABLE") )
                    {
                        if(is_variable(e_variable))
                        {
                            eq_var_addr_reg = is_reg_assigned(e_variable);
                            if(eq_var_addr_reg == -1)
                            {
                                eq_var_addr_reg = assign_reg(e_variable);
                                if(eq_var_addr_reg == -1)
                                {
                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                    err_temp->line_no = temp->line_no;
                                    strcpy(err_temp->error_code, "");
                                    
                                    strcpy(err_temp->error_desc, "out of memory!");
                                    insert_err_node(err_temp);
                                    end_compilation = 1;
                                    return;
                                }
                                code = strdup("LDR ");
                                code = strcat(code, registers[eq_var_addr_reg]);
                                code = strcat(code, ", =");
                                code = strcat(code, e_variable);
                                print_AC(1, code);
                                
                                //////////////////////////////////////////////////////////////
                            }
                            eq = strdup("[");
                            eq = strcat(eq, registers[eq_var_addr_reg]);
                            eq = strcat(eq, "]");
                            
                      
                        }
                        else
                        {
                            eq_var_val_reg = is_reg_assigned(e_variable);
                            if( eq_var_val_reg == -1 )
                                eq_var_val_reg = assign_reg(e_variable);
                            if(lhs_var_val_reg == -1)
                            {
                                err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                err_temp->line_no = temp->line_no;
                                strcpy(err_temp->error_code, "");
                                
                                strcpy(err_temp->error_desc, "out of memory!");
                                insert_err_node(err_temp);
                                end_compilation = 1;
                                return;
                            }
                            // printf("CHECKPOINT1\n");
                            eq = strdup(registers[eq_var_val_reg]);
                            // printf("CHECKPOINT2\n");

                        }
                    }
                    else if( !strcmp(temp->result->node_type, "LITERAL") )
                    {
                        ///WHAT THE ACTUAL SHIT WHY IS THIS CONDITION THERE
                        err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                        err_temp->line_no = temp->line_no;
                        strcpy(err_temp->error_code, "");
                        strcpy(err_temp->error_desc, "lvalue required as left operand of assignment");
                        insert_err_node(err_temp);
                        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        end_compilation = 1;
                    }   


                    if(eq[0] == '[')
                    {
                        code = strdup("STR #0, ");
                        code = strcat(code, eq);
                    }
                    
                    else
                    {
                        code = strdup("MOV ");
                        code = strcat(code, eq);
                        code = strcat(code, ", #0");
                    }
                    print_AC(1, code);

                    code= strdup("CMP ");
                    code = strcat(code, lhs);
                    code = strcat(code, ", ");
                    code = strcat(code, rhs);
                    print_AC(1, code);

                    if(eq[0] == '[')
                        code = strdup("STR");
                    else
                        code = strdup("MOV");


                    if( !strcmp(temp->op->node_value, ">") )
                        code = strcat(code, "GT ");
                    else if( !strcmp(temp->op->node_value, ">=") )
                        code = strcat(code, "GE ");
                    else if( !strcmp(temp->op->node_value, "<") )
                        code = strcat(code, "LT ");
                    else if( !strcmp(temp->op->node_value, "<=") )
                        code = strcat(code, "LE ");
                    else if( !strcmp(temp->op->node_value, "==") )
                        code = strcat(code, "EQ ");
                    else if( !strcmp(temp->op->node_value, "!=") )
                        code = strcat(code, "NE ");

                    if(eq[0] == '[')
                    {
                        code = strcat(code, "#1, ");
                        code = strcat(code, eq);
                    }
                    
                    else
                    {
                        code = strcat(code, eq);
                        code = strcat(code, ", #1");
                    }
                    print_AC(1, code);




                    if(rhs_var_addr_reg != -1)
                    {
                        if(purge_var(temp->next, r_variable))
                            reg_table[rhs_var_addr_reg]= strdup("");
                        
                        if(purge_add_reg(temp->next, r_variable))
                            reg_table[rhs_var_val_reg] = strdup("");      
                    }
                    else
                        if(purge_var(temp->next, r_variable))
                            reg_table[rhs_var_val_reg]= strdup("");

                    if(lhs_var_addr_reg != -1)
                    {
                        if(purge_var(temp->next, l_variable))
                            reg_table[lhs_var_addr_reg]= strdup("");
                        
                        if(purge_add_reg(temp->next, l_variable))
                            reg_table[lhs_var_val_reg] = strdup("");      
                    }
                    else
                        if(purge_var(temp->next, l_variable))
                            reg_table[lhs_var_val_reg]= strdup("");
                                                            
                    if(eq_var_addr_reg != -1)
                        if(purge_var(temp->next, e_variable))
                            reg_table[eq_var_addr_reg]= strdup("");
                    else
                        if(purge_var(temp->next, e_variable))
                            reg_table[eq_var_val_reg]= strdup("");
                
                
                }

                temp = temp->next;

            }
            while(temp!=NULL);
        }
    }


    






%}

%union
{
    char *str_val;
    struct TreeNode *node;
}

%token T_STRING
%token T_CHAR
%token<str_val> T_DATATYPE

%token T_BOOL

%token T_IF
%token T_ELSE
%token T_FOR
%token T_WHILE
%token T_RETURN
%token T_STD_COUT
%token T_STD_ENDL
%token T_MAIN
%token<str_val> T_ID
%token T_OPEN_SCOPE
%token T_CLOSE_SCOPE
%token T_OPEN_PARAN
%token T_CLOSE_PARAN
%token T_SEMICOLON
%token T_COMMA

%token T_INS_OP

%token T_ASGN_EQ_OP
%token T_ASGN_NEQ_OP


%token T_OR_OP
%token T_AND_OP
%token T_BITWISE_OR_OP      
%token T_BITWISE_XOR_OP
%token T_BITWISE_AND_OP
%token T_EQ_OP
%token T_REL_OP

%token T_PLUS_MINUS_OP
%token T_MUL_DIV_MOD_OP
%token T_NOT_OP
%token T_BITWISE_NOT_OP
%token T_INC_DEC_OP

%token T_FLOAT
%token T_INTEGER

%token T_ERR_ID




%%

start:                                          prog                            {
                                                                                    // printf("TREE HAS BEEN MADE!\n");
                                                                                    tree = create_tree($<node>1);
                                                                                }

prog:                                           T_DATATYPE main                 {
                                                                                    if(strcmp($<str_val>1, "int") && strcmp($<str_val>1, "void"))
                                                                                    {
                                                                                        err_node *temp = (err_node*)malloc(sizeof(err_node));
                                                                                        temp->line_no = line_no;
                                                                                        strcpy(temp->error_code, "");
                                                                                        strcpy(temp->error_desc, "main should be 'int' or 'void'");
                                                                                        insert_err_node(temp);

                                                                                        TreeNode *temp_datatype = create_node("DATATYPE", "int", current_scope, line_no, 0);
                                                                                        $<node>$ = create_node("PROGRAM", "NULL", current_scope, line_no, 2, temp_datatype, $<node>2);
                                                                                    }
                                                                                    else
                                                                                    {
                                                                                        TreeNode *temp_datatype = create_node("DATATYPE", $<str_val>1, current_scope, line_no, 0);
                                                                                        $<node>$ = create_node("PROGRAM", "NULL", current_scope, line_no, 2, temp_datatype, $<node>2);
                                                                                    }

                                                                                }

main:                                           T_MAIN main_args compound_statement     {
                                                                                            $<node>$ = create_node("MAIN", "NULL", current_scope, line_no, 2, $<node>2, $<node>3);    
                                                                                        }
                                            
main_args:                                      T_OPEN_PARAN T_CLOSE_PARAN              {
                                                                                            $<node>$ = create_node("PARANS", "NULL", current_scope, line_no, 0);
                                                                                        }


compound_statement:                             scope_open statement_list scope_close   {
                                                                                            $<node>$ = create_node("COMPOUND STATEMENT", "NULL", current_scope, line_no, 3, $<node>1, $<node>2, $<node>3);    

                                                                                        }

scope_open:                                     T_OPEN_SCOPE                    {
                                                                                    push_scope(current_scope);
                                                                                    current_scope = ++new_scope;
                                                                                    $<node>$ = create_node("OPEN SCOPE", "{", current_scope, line_no, 0);
                                                                                }  

scope_close:                                    T_CLOSE_SCOPE                   {
                                                                                    current_scope = pop_scope();
                                                                                    $<node>$ = create_node("CLOSE SCOPE", "}", current_scope, line_no, 0);

                                                                                }

statement_list:                                 statement statement_list        {
                                                                                    $<node>$ = create_node("STATEMENT LIST", "NULL", current_scope, line_no, 2, $<node>1, $<node>2);
                                                                                    
                                                                                }
                                            |                                   {
                                                                                    $<node>$ = create_node("NULL", "NULL", current_scope, line_no, 0);
                                                                                }
                                            ;

statement:                                      compound_statement              {
                                                                                    $<node>$ = create_node("STATEMENT", "NULL", current_scope, line_no, 1, $<node>1);    
                                                                                }

                                            |   init                            {
                                                                                    $<node>$ = create_node("STATEMENT", "NULL", current_scope, line_no, 1, $<node>1);    
                                                                                }
                                            |   expr T_SEMICOLON                {   
                                                                                    TreeNode *temp_semicolon = create_node("SEMICOLON", ";", current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("STATEMENT", "NULL", current_scope, line_no, 2, $<node>1, temp_semicolon);
                                                                                }

                                           
                                            |   if_construct                    {
                                                                                    $<node>$ = create_node("STATEMENT", "NULL", current_scope, line_no, 1, $<node>1);

                                                                                }
                                            
                                            |   while_construct                 {
                                                                                    $<node>$ = create_node("STATEMENT", "NULL", current_scope, line_no, 1, $<node>1);

                                                                                }
                                            
                                            |   for_construct                   {
                                                                                    $<node>$ = create_node("STATEMENT", "NULL", current_scope, line_no, 1, $<node>1);

                                                                                }
                                            
                                            |   output                          {
                                                                                    $<node>$ = create_node("STATEMENT", "NULL", current_scope, line_no, 1, $<node>1);

                                                                                }
                                            
                                            |   return_construct                {
                                                                                    $<node>$ = create_node("STATEMENT", "NULL", current_scope, line_no, 1, $<node>1);

                                                                                }
                                            

                                          

                                            |   T_SEMICOLON                     {
                                                                                    TreeNode *temp_sc = create_node("SEMICOLON", ";", current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("STATEMENT", "NULL", current_scope, line_no, 1, temp_sc);

                                                                                }
                                          


init:                                           T_DATATYPE id_group             {
                                                                                    TreeNode *temp_id_group = check_id_group($<node>2, $<str_val>1);
                                                                                    TreeNode *temp_datatype = create_node("DATATYPE", $<str_val>1, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("INIT", "NULL", current_scope, line_no, 2, temp_datatype, temp_id_group);

                                                                                }


id_group:                                       id_init T_SEMICOLON             {
                                                                                    TreeNode *temp = create_node("SEMICOLON", ";", current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("ID_GROUP", "NULL", current_scope, line_no, 2, $<node>1, temp);

                                                                                }
                                            

                                            |   id_init T_COMMA id_group        {
                                                                                    TreeNode *temp = create_node("COMMA", ",", current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("ID_GROUP", "NULL", current_scope, line_no, 3, $<node>1, temp, $<node>3);
                                                                                }
                                            |   id_init id_group                {
                                                                                    err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                                                                    err_temp->line_no = line_no;
                                                                                    strcpy(err_temp->error_code, "");
                                                                                    strcpy(err_temp->error_desc, "Syntax Error - ',' missing");
                                                                                    insert_err_node(err_temp);

                                                                                    TreeNode *temp = create_node("COMMA", ",", current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("ID_GROUP", "NULL", current_scope, line_no, 3, $<node>1, temp, $<node>2);
                                                                                }


id_init:                                        T_ID                            {
                                                                                    TreeNode *temp = create_node("IDENTIFIER", $<str_val>1, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("ID_INIT", "ID_UNO", current_scope, line_no, 1, temp);                                                                                    
                                                                                }
                                            |   T_ID T_ASGN_EQ_OP expr          {
                                                                                    TreeNode *temp_id = create_node("IDENTIFIER", $<str_val>1, current_scope, line_no, 0);
                                                                                    TreeNode *temp_asgn = create_node("ASGN_OP", $<str_val>2, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("ID_INIT", "ID_TRES", current_scope, line_no, 3, temp_id, temp_asgn, $<node>3); 
                                                                                }



expr:                                           expr T_ASGN_EQ_OP expr1         {
                                                                                    TreeNode *temp_asgn = create_node("ASGN_OP", $<str_val>2, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr", current_scope, line_no, 3, $<node>1, temp_asgn, $<node>3);
                                                                                }
                                            |   expr T_ASGN_NEQ_OP expr1        {
                                                                                    TreeNode *temp_asgn = create_node("ASGN_OP", $<str_val>2, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr", current_scope, line_no, 3, $<node>1, temp_asgn, $<node>3);
                                                                                }
                                            |   expr1                           { $<node>$ = $<node>1; }

expr1:                                          expr1 T_OR_OP expr2             {
                                                                                    TreeNode *temp_log_or = create_node("LOG_OR_OP", $<str_val>2, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr1", current_scope, line_no, 3, $<node>1, temp_log_or, $<node>3);
                                                                                }
                                            |   expr2                           { $<node>$ = $<node>1; }

expr2:                                          expr2 T_AND_OP expr3             {
                                                                                    TreeNode *temp_log_and = create_node("LOG_AND_OP", $<str_val>2, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr2", current_scope, line_no, 3, $<node>1, temp_log_and, $<node>3);
                                                                                }
                                            |   expr3                           { $<node>$ = $<node>1; }


expr3:                                          expr3 T_BITWISE_OR_OP expr4     {
                                                                                    TreeNode *temp_bit_or = create_node("BIT_OR_OP", $<str_val>2, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr3", current_scope, line_no, 3, $<node>1, temp_bit_or, $<node>3);
                                                                                }
                                            |   expr4                           { $<node>$ = $<node>1; }

expr4:                                          expr4 T_BITWISE_XOR_OP expr5    {
                                                                                    TreeNode *temp_bit_xor = create_node("BIT_XOR_OP", $<str_val>2, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr4", current_scope, line_no, 3, $<node>1, temp_bit_xor, $<node>3);
                                                                                }
                                            |   expr5                           { $<node>$ = $<node>1; }

expr5:                                          expr5 T_BITWISE_AND_OP expr6    {
                                                                                    TreeNode *temp_bit_and = create_node("BIT_AND_OP", $<str_val>2, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr5", current_scope, line_no, 3, $<node>1, temp_bit_and, $<node>3);
                                                                                }
                                            |   expr6                           { $<node>$ = $<node>1; }

expr6:                                          expr6 T_EQ_OP expr7             {
                                                                                    TreeNode *temp_eq = create_node("EQ_OP", $<str_val>2, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr6", current_scope, line_no, 3, $<node>1, temp_eq, $<node>3);
                                                                                }
                                            |   expr7                           { $<node>$ = $<node>1; }

expr7:                                          expr7 T_REL_OP expr8            {
                                                                                    TreeNode *temp_rel = create_node("REL_OP", $<str_val>2, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr7", current_scope, line_no, 3, $<node>1, temp_rel, $<node>3);
                                                                                }
                                            |   expr8                           { $<node>$ = $<node>1; }



expr8:                                          expr8 T_PLUS_MINUS_OP expr9     {
                                                                                    TreeNode *temp_plus_minus = create_node("PLUS_MINUS_OP", $<str_val>2, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr8", current_scope, line_no, 3, $<node>1, temp_plus_minus, $<node>3);
                                                                                }
                                            |   expr9                           { $<node>$ = $<node>1; }

expr9:                                         expr9 T_MUL_DIV_MOD_OP expr10    {
                                                                                    TreeNode *temp_mul_div_mod = create_node("MUL_DIV_MOD_OP", $<str_val>2, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr9", current_scope, line_no, 3, $<node>1, temp_mul_div_mod, $<node>3);
                                                                                }
                                            |   expr10                          { $<node>$ = $<node>1; }


expr10:                                         T_NOT_OP expr10                 {
                                                                                    TreeNode *temp_not = create_node("NOT_OP", $<str_val>1, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr10", current_scope, line_no, 2, temp_not, $<node>2);
                                                                                }
                                            |   T_BITWISE_NOT_OP expr10         {
                                                                                    TreeNode *temp_bit_not = create_node("BIT_NOT_OP", $<str_val>1, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr10", current_scope, line_no, 2, temp_bit_not, $<node>2);
                                                                                }
                                            |   T_INC_DEC_OP expr10             {
                                                                                    TreeNode *temp_inc_dec = create_node("INC_DEC_OP", $<str_val>1, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr10", current_scope, line_no, 2, temp_inc_dec, $<node>2);
                                                                                }

                                            |   T_PLUS_MINUS_OP expr10          {
                                                                                    TreeNode *temp_plus_minus = create_node("PLUS_MINUS_OP", $<str_val>1, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr10", current_scope, line_no, 2, temp_plus_minus, $<node>2);
                                                                                }
                                            |   expr11                          { $<node>$ = $<node>1; }


expr11:                                         expr11 T_INC_DEC_OP             {
                                                                                    TreeNode *temp_inc_dec = create_node("INC_DEC_OP", $<str_val>2, current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr11", current_scope, line_no, 2, $<node>1, temp_inc_dec);
                                                                                }
                                            |   expr12

expr12:                                         T_OPEN_PARAN expr T_CLOSE_PARAN {
                                                                                    TreeNode *temp_open = create_node("PARAN", "(", current_scope, line_no, 0);
                                                                                    TreeNode *temp_close = create_node("PARAN", ")", current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("EXPRESSION", "expr12", current_scope, line_no, 3, temp_open, $<node>2, temp_close);

                                                                                }
                                            |   value                           {  $<node>$ = $<node>1;  }

value:                                          T_ID                            {
                                                                                    int this_scope = check_validity($<str_val>1);
                                                                                    if(this_scope == -1)
                                                                                    {
                                                                                        err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                                                                        err_temp->line_no = line_no;
                                                                                        strcpy(err_temp->error_code, "");
                                                                                        char *temp_str_val = strdup($<str_val>1);
                                                                                        strcpy(err_temp->error_desc, strcat(temp_str_val, " - undeclared variable"));
                                                                                        insert_err_node(err_temp);

                                                                                        end_compilation = 1;
                                                                                    }


                                                                                    $<node>$ = create_node("IDENTIFIER", $<str_val>1, this_scope, line_no, 0);
                                                                                }
                                            |   literal                         {  $<node>$ = $<node>1;  }

literal:                                        T_BOOL                          {
                                                                                    if(!strcmp($<str_val>1, "true"))
                                                                                        $<node>$ = create_node("BOOL", "1", current_scope, line_no, 0);
                                                                                    else
                                                                                        $<node>$ = create_node("BOOL", "0", current_scope, line_no, 0);

                                                                                }
                                            |   T_CHAR                          {
                                                                                    $<node>$ = create_node("CHAR", convert_char_to_ascii($<str_val>1), current_scope, line_no, 0);
                                                                                }

                                            |   T_INTEGER                       {
                                                                                    $<node>$ = create_node("INTEGER", $<str_val>1, current_scope, line_no, 0);

                                                                                }
                                            |   T_FLOAT                         {
                                                                                    $<node>$ = create_node("FLOAT", $<str_val>1, current_scope, line_no, 0);

                                                                                }
                                            |   T_STRING                        {
                                                                                    $<node>$ = create_node("STRING", $<str_val>1, current_scope, line_no, 0);
                                                                                }




return_construct:                               T_RETURN expr T_SEMICOLON       {
                                                                                    TreeNode *temp_return = create_node("RETURN", "NULL", current_scope, line_no, 0);
                                                                                    TreeNode *temp_sc = create_node("SEMICOLON", ";", current_scope, line_no, 0);

                                                                                    $<node>$ = create_node("RETURN_CONSTRUCT", "NULL", current_scope, line_no, 3, temp_return, $<node>2, temp_sc);

                                                                                }




if_construct:                                   T_IF condition statement else_part      {
                                                                                            TreeNode *temp_if = create_node("IF", "NULL", current_scope, line_no, 0);
                                                                                            $<node>$ = create_node("IF_CONSTRUCT", "NULL", current_scope, line_no, 4, temp_if, $<node>2, $<node>3, $<node>4);                          
                                                                                        }

condition:                                      T_OPEN_PARAN expr T_CLOSE_PARAN {
                                                                                    TreeNode *temp_open_paran = create_node("PARAN", "(", current_scope, line_no, 0);
                                                                                    TreeNode *temp_close_paran = create_node("PARAN", ")", current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("CONDITION", "NULL", current_scope, line_no, 3, temp_open_paran, $<node>2, temp_close_paran);
                                                                                }

else_part:                                      T_ELSE statement                {
                                                                                    TreeNode *temp_else = create_node("ELSE", "NULL", current_scope, line_no, 0);
                                                                                    $<node>$ = create_node("ELSE", "NULL", current_scope, line_no, 2, temp_else, $<node>2);                          
                                                                                }



while_construct:                                while_keyword condition statement       {
                                                                                            $<node>$ = create_node("WHILE_CONSTRUCT", "NULL", current_scope, line_no, 3, $<node>1, $<node>2, $<node>3);                          
                                                                                            current_scope = pop_scope();
                                                                                        }

while_keyword:                                  T_WHILE                                 {
                                                                                            push_scope(current_scope);
                                                                                            current_scope = ++new_scope;
                                                                                            $<node>$ = create_node("WHILE", "NULL", current_scope, line_no, 0);
                                                                                        }


for_construct:                                  for_keyword T_OPEN_PARAN for_para_1 for_para_2 for_para_3 T_CLOSE_PARAN statement   {
                                                                                                                                        TreeNode *temp_open_paran = create_node("PARAN", "(", current_scope, line_no, 0);
                                                                                                                                        TreeNode *temp_close_paran = create_node("PARAN", ")", current_scope, line_no, 0);
                                                                                                                                     
                                                                                                                                        $<node>$ = create_node("FOR_CONSTRUCT", "NULL", current_scope, line_no, 7, $<node>1, temp_open_paran, $<node>3, $<node>4, $<node>5, temp_close_paran, $<node>7);
                                                                                                                                        
                                                                                                                                        current_scope = pop_scope();
                                                                                                                                    }

for_keyword:                                    T_FOR                       {
                                                                                push_scope(current_scope);
                                                                                current_scope = ++new_scope;
                                                                                $<node>$ = create_node("FOR", "NULL", current_scope, line_no, 0);
                                                                            }



for_para_1:                                     expr T_SEMICOLON            {     
                                                                                TreeNode *temp_sc = create_node("SEMICOLON", "NULL", current_scope, line_no, 0);
                                                                                $<node>$ = create_node("FOR_PARA", "FOR_PARA_1", current_scope, line_no, 2, $<node>1, temp_sc ); 
                                                                            }
                                            |   init                        {     
                                                                                $<node>$ = create_node("FOR_PARA", "FOR_PARA_1", current_scope, line_no, 1, $<node>1 ); 
                                                                            }
                                            |   T_SEMICOLON                 {     
                                                                                TreeNode *temp_sc = create_node("SEMICOLON", "NULL", current_scope, line_no, 0);
                                                                                $<node>$ = create_node("FOR_PARA", "FOR_PARA_1", current_scope, line_no, 1, temp_sc ); 
                                                                            }
                                            

for_para_2:                                     expr T_SEMICOLON            {     
                                                                                TreeNode *temp_sc = create_node("SEMICOLON", "NULL", current_scope, line_no, 0);
                                                                                $<node>$ = create_node("FOR_PARA", "FOR_PARA_2", current_scope, line_no, 2, $<node>1, temp_sc ); 
                                                                            }
                                            |   T_SEMICOLON                 {     
                                                                                TreeNode *temp_sc = create_node("SEMICOLON", "NULL", current_scope, line_no, 0);
                                                                                $<node>$ = create_node("FOR_PARA", "FOR_PARA_2", current_scope, line_no, 1, temp_sc ); 
                                                                            }
                                            

for_para_3:                                     expr                        {     
                                                                                $<node>$ = create_node("FOR_PARA", "FOR_PARA_3", current_scope, line_no, 1, $<node>1 ); 
                                                                            }
                                            |                               {   
                                                                                TreeNode *temp_null = create_node("NULL", "NULL", current_scope, line_no, 0);   
                                                                                $<node>$ = create_node("FOR_PARA", "FOR_PARA_3", current_scope, line_no, 1, temp_null );
                                                                            }
                                            ;



output:                                         T_STD_COUT  output_vals T_SEMICOLON     {
                                                                                            if(!strcmp($<node>2->node_type, "NULL"))
                                                                                            {
                                                                                                err_node *err_temp = (err_node*)malloc(sizeof(err_node));
                                                                                                err_temp->line_no = line_no;
                                                                                                strcpy(err_temp->error_code, "");
                                                                                                strcpy(err_temp->error_desc, "expression expected before ;");
                                                                                                insert_err_node(err_temp);

                                                                                                $<node>$ = create_node("NULL", "NULL", current_scope, line_no, 0); 



                                                                                            }
                                                                                            TreeNode *temp_cout = create_node("COUT", "NULL", current_scope, line_no, 0);
                                                                                            TreeNode *temp_sc = create_node("SEMICOLON", "NULL", current_scope, line_no, 0);
                                                                                            $<node>$ = create_node("OUTPUT", "NULL", current_scope, line_no, 3, temp_cout, $<node>2, temp_sc);

                                                                                        }

output_vals:                                    T_INS_OP expr output_vals               {
                                                                                            TreeNode *temp_ins_op = create_node("INS_OP", "NULL", current_scope, line_no, 0);
                                                                                            $<node>$ = create_node("OP_VALS", "NULL", current_scope, line_no, 3, temp_ins_op, $<node>2, $<node>3);
                                                                                        }


                                            |   T_INS_OP T_STD_ENDL output_vals         {
                                                                                            TreeNode *temp_ins_op = create_node("INS_OP", "NULL", current_scope, line_no, 0);
                                                                                            TreeNode *temp_endl = create_node("ENDL", "\\n", current_scope, line_no, 0);
                                                                                            $<node>$ = create_node("OP_VALS", "NULL", current_scope, line_no, 3, temp_ins_op, temp_endl, $<node>3);
                                                                                        }
                                            |                                           { 
                                                                                            $<node>$ = create_node("NULL", "NULL", current_scope, line_no, 0); 
                                                                                        }
                                            ;








%%


int main()
{
    Initialize_Symbol_Table();
    Initialize_Error_Table();
    tactable =  init_TAC_Table();
    yyparse();
    
    
    if(!end_compilation)
    {
        printf("\n\n\n");
        printf("ABSRTACT SYNTAX TREE\n");
        printf("____________________________________________________________________\n");
        print_parse_tree(tree->root, 0);
    }

    printf("\n\n\n");
    if(!end_compilation)
        icg(tree->root);

    if(!end_compilation)
    {
        printf("TAC Code\n");
        printf("____________________________________________________________________\n");
        printf("Op\t\tArg1\t\tArg2\t\tResult\n");
        print_TAC_Table(tactable);

        dead_code_elimination(tactable);
        printf("\n\n\n");
        printf("Dead Code Eliminated\n");
        printf("____________________________________________________________________\n");
        printf("Op\t\tArg1\t\tArg2\t\tResult\n");
        print_TAC_Table(tactable);

        constant_folding(tactable);
        printf("\n\n\n");
        printf("Constant Folding Done\n");
        printf("____________________________________________________________________\n");
        printf("Op\t\tArg1\t\tArg2\t\tResult\n");
        print_TAC_Table(tactable);

        printf("\n\n\n");
        assembly_code(tactable);
    }

    printf("\n\n\n");
    printf("____________________________________________________________________\n");
    printf("SYMBOL TABLE\nTABLE size:%d\n", S.table_size);
    printf("ID_Name\t\tID_Datatype\t\tID_Value\t\tID_Scope\n");
    for(int i = 0 ; i<S.table_size; i++)
    {
        printf("%s\t\t%s\t\t\t%s\t\t\t%d\n", S.table[i]->name, S.table[i]->datatype, S.table[i]->value, S.table[i]->scope);
    }

    printf("\n\n\n");
    printf("ERROR TABLE\nTABLE size:%d\n", E.table_size);
    printf("____________________________________________________________________\n");
    printf("ERR_Line\t\tERR_Code\t\tERR_Desc\n");
    for(int i = 0 ; i<E.table_size; i++)
        printf("%d\t\t%s\t\t%s\n", E.table[i]->line_no, E.table[i]->error_code, E.table[i]->error_desc);
    
    printf("\n\n\n");

}