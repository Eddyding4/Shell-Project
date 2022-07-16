
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

%}

%%

goal: command_list;

arg_list:
  arg_list WORD {
    printf(" Yacc: insert argument \"%s\"\n", $2->c_str());
    Command::_currentSimpleCommand->insertArgument( $2 );
  } 
  | /*empty*/
  ;

cmd_and_args:
  WORD {
    printf(" Yacc: insert command \"%s\"\n", $1->c_str());
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
    printf(" Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
  }
  | GREAT WORD {
    printf(" Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
  }
  | GREATGREATAMPERSAND WORD {
    printf(" Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
  }
  | GREATAMPERSAND WORD {
    printf(" Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
  }
  | LESS WORD {
    printf(" Yacc: insert input \"%s\"\n", $2->c_str());
    Shell::_currentCommand._inFile = $2;
  }
  | STANDARDERR WORD {
    printf(" Yacc: insert error \"%s\"\n", $2->c_str());
    Shell::_currentCommand._errFile = $2;
  }
  ;

io_modifier_list:
  io_modifier_list io_modifier
  | /*empty*/
  ;

background_opt:
  AMPERSAND
  | /*empty*/
  ;

command_line:
  pipe_list io_modifier_list background_opt NEWLINE {
    printf(" Yacc: Execute command\n");
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
