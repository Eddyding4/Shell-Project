
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


[^ \t\n][^ \t\n]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}



%%
