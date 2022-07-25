
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

void expandWildCardsIfNecessary(char * arg);
void expandWildCards(char * prefix, char * arg);
int cmpfunc(const void * file1, const void * file2);
bool is_dir(const char * path);

%}

%%

goal: command_list;

arg_list:
  arg_list WORD {
      //printf(" Yacc: insert argument \"%s\"\n", $2->c_str());
      if(strcmp(Command::_currentSimpleCommand->_arguments[0], "echo") == 0 && strchr($2, '?'))
      Command::_currentSimpleCommand->insertArgument( $2 );
      else
      expandWildcardsIfNecessary
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

int maxEntries = 20;
int nEntries = 0;
char ** entries;

void expandWildCardsIfNecessary(char * arg){
  maxEntries = 20;
  nEntries = 0;
  entries = (char **) malloc (maxEntries * sizeof(char*));

  if(strchr(arg, '*') || strchr(arg, '?')) {
    expandWildCard(NULL, arg);
    qsort(entries, nEntries, sizeof(char *), cmpfunc);
    for(int i = 0; i < nEntries; i++){
      Command::_currentSimpleCommand->insertArgument(entries[i]);
    } 
  } else {
    Command::_currentSimpleCommand->insertArgument(arg);
  }
  return;
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
