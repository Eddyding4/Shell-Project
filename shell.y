
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
#include <algorithm>
#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
#define MAXFILENAME 1024
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
static std::vector<char *> _sortArgument = std::vector<char *>();

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
		    expandWildcardsIfNecessary($2);
      
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

void expandWildcardsIfNecessary(std::string * arg) 
{
	char * args = (char *) malloc(arg->length()+1);
	strcpy(args,arg->c_str());
	max = 30;
	num = 0;
	entries = (char **) malloc (max * sizeof(char *));

	if (strchr(args, '*') || strchr(args, '?')) 
	{
		expandWildCards(NULL, args);
		free(args);
		if(num == 0)
		{
			Command::_currentSimpleCommand->insertArgument(arg);
			return;
		}
		qsort(entries, num, sizeof(char *), cmpfunc);
		for (int i = 0; i < num; i++) 
		{
			std::string * str = new std::string(entries[i]);
			Command::_currentSimpleCommand->insertArgument(str);
			free(entries[i]);
		}
	} else {
		free(args);
		Command::_currentSimpleCommand->insertArgument(arg);
	}
	free(entries);
	return;
}

int cmpfunc (const void *file1, const void *file2) 
{
	const char *_file1 = *(const char **)file1;
	const char *_file2 = *(const char **)file2;
	return strcmp(_file1, _file2);
}

void expandWildCards(char * prefix, char * arg)
{
	char * temp = arg;
	char * save = (char *) malloc (strlen(arg));
	char * dir2 = save;

	if(temp[0] == '/')
		*(save++) = *(temp++);

	while (*temp != '/' && *temp) 
		*(save++) = *(temp++);
	
	*save = '\0';
	if (strchr(dir2, '*') || strchr(dir2, '?')) 
	{
		if (!prefix && arg[0] == '/') 
		{
			prefix = strdup("/");
			dir2++;
		}  

		char * reg = (char *) malloc (2*strlen(arg) + 10);
		char * a = dir2;
		char * r = reg;
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
		regcomp(&re, reg, REG_EXTENDED|REG_NOSUB);

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
						if (!strcmp(toOpen, ".")) nPrefix = strdup(ent->d_name);
						else if (!strcmp(toOpen, "/")) sprintf(nPrefix, "%s%s", toOpen, ent->d_name);
						else sprintf(nPrefix, "%s/%s", toOpen, ent->d_name);
						expandWildCards(nPrefix, (*temp == '/')?++temp:temp);
					}
				}
				else 
				{	
					if (num == max) 
					{ 
						max *= 2; 
						entries = (char **) realloc (entries, max * sizeof(char *)); 
					}
					char * argument = (char *) malloc (100);
					argument[0] = '\0';
					if (prefix)
						sprintf(argument, "%s/%s", prefix, ent->d_name);

					if (ent->d_name[0] == '.') 
					{
						if (arg[0] == '.')
							entries[num++] = (argument[0] != '\0')?strdup(argument):strdup(ent->d_name);
					}
					else {
						entries[num++] = (argument[0] != '\0')?strdup(argument):strdup(ent->d_name);
					}
					free(argument);

				}
			}
		}
		closedir(dir);
		regfree(&re);
		free(toOpen);

	} 
	else 
	{
		char * pre = (char *) malloc (100);
		if(prefix) 
			sprintf(pre, "%s/%s", prefix, dir2);
		else
			pre = strdup(dir2);

		if(*temp)
			expandWildCards(pre, ++temp);
	}
	free(dir2);
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
