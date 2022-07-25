
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
void expandWildcard(char * prefix, char * suffix);
bool cmpfunction (char * i, char * j);
static bool wildCard;

%}

%%

goal: command_list;

arg_list:
  arg_list WORD {
      //printf(" Yacc: insert argument \"%s\"\n", $2->c_str());
      wildCard = false;
      char *p = (char *)"";
      expandWildcard(p, (char*)$2->c_str());
      std::sort(_sortArgument.begin(), sortArgument.end(), cmpfunction);
      for(auto a:_sortArgument){
        std::string * argToInsert = new std::string(a);
        Command::_currentSimpleCommand->insertArgument(argToInsert);
      }
      _sortArgument.clear();
      //Command::_currentSimpleCommand->insertArgument( $2 );
      
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

bool cmpfunction (char * i, char * j) { return strcmp(i,j)<0; }

void
yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}

void expandWildcardsIfNecessary(std::string * arg){
  char * args = (char *)arg->c_str();
  char * a;
  std::string path;

  if(strchr(args, '?') == NULL & strchr(args, '*') == NULL){
    Command::_currentSimpleCommand->insertArgument(arg);
    return;
  }
  DIR * dir;

}
#if 0
main()
{
  yyparse();
}
#endif
