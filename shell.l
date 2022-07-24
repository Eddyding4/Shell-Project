
/*
 *
 * CS-252 
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{

#include <cstring>
#include "y.tab.hh"
#include <sys/wait.h>
#include <sys/types.h>

static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
  unput(c);
}

%}

%option noyywrap

%%

\n {
  return NEWLINE;
}

[ \t] {
  /* Discard spaces and tabs */
}

">" {
  return GREAT;
}

">>" {
  return GREATGREAT;
}

"|" {
  return PIPE;
}

"&" {
  return AMPERSAND;
}

">>&" {
  return GREATGREATAMPERSAND;
}

">&" {
  return GREATAMPERSAND;
}

"<" {
  return LESS;
}

"2>" {
  return STANDARDERR;
}

. {
  return NOTOKEN;
}

[^ \t\n|><&]*\\[^ \t\n]* {
  //escape
	int i=0;
	char * escChar;
	escChar = new char[strlen(yytext)*2];
	char * args = yytext;
	while ( *args ) {
		if ( *args == '\\' ) {	
			escChar[i] = *(++args);
			i++;	
		} else {
			escChar[i] = *args;
			i++;
		}
		args++;
	}
	escChar[i] = '\0';
	yylval.cpp_string = new std::string(escChar);
	return WORD;
	
}

["][^\n\"]*["] {
	//quotes
	int i = 0;
	char * quoteChar = new char[strlen(yytext)];
	char * args = yytext;
	
	while ( *args ) {
		if ( *args == '\"' ) {
			quoteChar[i] = *(++args);
			i++;
		} else {
			quoteChar[i] = *args;
			i++;
		}
		args++;
	}
	quoteChar[i] = '\0';
	yylval.cpp_string = new std::string(quoteChar);
	return WORD;
}

\$\([^\n\$]*\)|`[^\n`]*` {
	//subshell
	int i=0;
	std::string * command = new std::string(yytext);
	command->pop_back();

  if(strchr(command->c_str(), '`') != NULL){
    command = new std::string(yytext + 1);
    command->pop_back();
  } else {
    command = new std::string(yytext + 2);
    command->pop_back();
  }

  int tmpin = dup(0);
  int tmpout = dup(1);

  int fdin[2];
  int fdout[2];

  pipe(fdin);
  pipe(fdout);

  write(fdin[1], command->c_str(), command->size());
  write(fdin[1], "\n", 1);
  write(fdin[1], "exit", 4);
  write(fdin[1], "\n", 1);
  close(fdin[1]);

  dup2(fdin[0], 0);
  close(fdin[0]);
  dup2(fdout[1], 1);
  close(fdout[1]);

  int ret = fork();
  if(ret == 0){
    execvp("/proc/self/exe", NULL);
    exit(1);
  } else if (ret < 0){
    perror("fork");
    exit(1);
  }

  //restore defaults
  dup2(tmpin, 0);
  dup2(tmpout, 1);
  close(tmpin);
  close(tmpout);

  char c;
  size_t size = 0;
  i = 0;

  char * buf = new char[1024];
  while(read(fdout[0], &c, 1)){
    if(c == '\n' ){
      buf[i++] = ' ';
    } else {
      buf[i++] = c;
    }
  }
  buf[i] = '\0';
  i = strlen(buf) - 1
  for (i ; i >= 0; i--) {
		unput(buffer[i]);
	}
}


[^ \t\n][^ \t\n]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}



%%
