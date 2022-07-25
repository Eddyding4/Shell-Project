
/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 */

%code requires 
{
#include <string>
#include <cstring>
#include <regex>
#include <iostream>
#include <dirent.h>
#include <regex.h>
#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
}

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;  
}

%token <cpp_string> WORD
%token NOTOKEN GREAT NEWLINE GREATGREAT PIPE AMPERSAND GREATGREATAMPERSAND GREATAMPERSAND LESS STANDARDERR 

%{
//#define yylex yylex
#include <cstdio>
#include "shell.hh"

void yyerror(const char * s);
int yylex();

void expandWildcardsIfNecessary(std::string * arg);
int cmpfunc (const void *file1, const void *file2);
void expandWildCards(char * prefix, char * arg);

%}

%%

goal: command_list;

arg_list:
  arg_list WORD {
      //printf(" Yacc: insert argument \"%s\"\n", $2->c_str());
      //Command::_currentSimpleCommand->insertArgument( $2 );
    if(strcmp(Shell::_currentSimpleCommand[0]->_arguments[0]->c_str(), "echo") == 0 && strchr($2, '?')) {
      	Command::_currentSimpleCommand->insertArgument( $2 );
	  } else {
		    expandWildcardsIfNecessary($2);
    }
      
  } 
  | /*empty*/
  ;

cmd_and_args:
  WORD {
    //printf(" Yacc: insert command \"%s\"\n", $1->c_str());
    Command::_currentSimpleCommand = new SimpleCommand();
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  arg_list {
    Shell::_currentCommand.
    insertSimpleCommand( Command::_currentSimpleCommand );
  }
  ;

pipe_list:
  cmd_and_args
  |  pipe_list PIPE cmd_and_args 
  ;

io_modifier:
  GREATGREAT WORD {
    Shell::_currentCommand._append = true;
    Shell::_currentCommand._count++;
    Shell::_currentCommand._outFile = $2;
  }
  | GREAT WORD {
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._count++;
  }
  | GREATGREATAMPERSAND WORD {
    Shell::_currentCommand._append = true;
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._errFile = $2;
    Shell::_currentCommand._count++;
  }
  | GREATAMPERSAND WORD {
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._errFile = $2;
    Shell::_currentCommand._count++;
  }
  | LESS WORD {
    Shell::_currentCommand._count++;
    Shell::_currentCommand._inFile = $2;
  }
  | STANDARDERR WORD {
    Shell::_currentCommand._count++;
    Shell::_currentCommand._errFile = $2;
  } 
  ;

io_modifier_list:
  io_modifier_list io_modifier
  | /*empty*/
  ;

background_opt:
  AMPERSAND {
    Shell::_currentCommand._background = true;
  }
  | /*empty*/
  ;

command_line:
  pipe_list io_modifier_list background_opt NEWLINE {
    //printf(" Yacc: Execute command\n");
    Shell::_currentCommand.execute();
  }
  | NEWLINE 
  | error NEWLINE{yyerrok; }
  ;

command_list:
  command_line
  | command_list command_line
  ;
%%

int max = 30;
int num = 0;
char ** entries;

int cmp (const void *file1, const void *file2) 
{
	const char *_file1 = *(const char **)file1;
	const char *_file2 = *(const char **)file2;
	return strcmp(_file1, _file2);
}

void expandWildcardsIfNecessary(std::string * arg){
  char * temp = (char *) malloc(arg->length()+1);
  strcpy(temp, arg->c_str());
  max = 20;
  num = 0;
  entries = (char **) malloc (max * sizeof(char *));

  if(strchr(temp, '*') || strchr(temp, '?')){
    expandWildCards(NULL, temp);
    if(num == 0){
      Command::_currentSimpleCommand->insertArgument(arg);
			return;
    }
    qsort(entries, num, sizeof(char *), cmp);
    for (int i = 0; i < num; i++) {
			std::string * str = new std::string(entries[i]);
			Command::_currentSimpleCommand->insertArgument(str);
		}
	} else {
		Command::_currentSimpleCommand->insertArgument(arg);
  }
	return;
}



void expandWildCards(char * prefix, char * arg){
  char * temp = arg;
  char * save = (char*) malloc (strlen(arg) + 10);
  char * dir = save;

  if(temp[0] = '/'){
    *(save++) = *(temp++);
  }
  while (*temp != '/' && *temp){
    *(save++) = *(temp++);
  }
  *save = '\0';
  if (strchr(dir, '*') || strchr(dir, '?')) 
	{
		if (!prefix && arg[0] == '/') 
		{
			prefix = strdup("/");
			dir++;
		}  

		char * temp2 = (char *) malloc (2*strlen(arg) + 10);
		char * a = dir;
		char * r = temp2;

		*r = '^';
		r++;
		while (*a) 
		{
			if (*a == '*') { *r='.'; r++; *r='*'; r++; }
			else if (*a == '?') { *r='.'; r++; }
			else if (*a == '.') { *r='\\'; r++; *r='.'; r++; }
			else { *r=*a; r++; }
			a++;
		}
		*r = '$';
		r++;
		*r = '\0';

		regex_t re;

		int expbuf = regcomp(&re, temp2, REG_EXTENDED|REG_NOSUB);

		char * toOpen = strdup((prefix)?prefix:".");
		DIR * dir = opendir(toOpen);
		if (dir == NULL) 
		{
			perror("opendir");
			return;
		}

		struct dirent * ent;
		regmatch_t match;
		while ((ent = readdir(dir)) != NULL) 
		{
			if (!regexec(&re, ent->d_name, 1, &match, 0)) 
			{
				if (*temp) 
				{
					if (ent->d_type == DT_DIR) 
					{
						char * nPrefix = (char *) malloc (150);
						if (!strcmp(toOpen, ".")) {
              nPrefix = strdup(ent->d_name);
            }
						else if (!strcmp(toOpen, "/")) {
              sprintf(nPrefix, "%s%s", toOpen, ent->d_name);
            }  else {
              sprintf(nPrefix, "%s/%s", toOpen, ent->d_name);
            }
						expandWildCards(nPrefix, (*temp == '/')?++temp:temp);
					}
				} else {	
					if (num == max) 
					{ 
						max *= 2; 
						entries = (char **) realloc (entries, max * sizeof(char *)); 
					}
					char * argument = (char *) malloc (1024);
					argument[0] = '\0';
					if (prefix)
						sprintf(argument, "%s/%s", prefix, ent->d_name);

					if (ent->d_name[0] == '.') 
					{
						if (arg[0] == '.')
							entries[num++] = (argument[0] != '\0')?strdup(argument):strdup(ent->d_name);
					}
					else
						entries[num++] = (argument[0] != '\0')?strdup(argument):strdup(ent->d_name);
				}
			}
		}
		closedir(dir);
	} else {
		char * preToSend = (char *) malloc (1024);
		if(prefix) 
			sprintf(preToSend, "%s/%s", prefix, dir);
		else
			preToSend = strdup(dir);

		if(*temp)
			expandWildCards(preToSend, ++temp);
	}
}
void
yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}


#if 0
main()
{
  yyparse();
}
#endif
