
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

`[^\n`]*` {
  char * command = strdup(yytext + 1);
  if(command[yyleng -2 ] == '`'){
    command[yyleng - 2] = '\0';
  }

  int tmpin = dup(0);
  int tmpout = dup(1);

  int fdin[2];
  int fdout[2];
  pipe(fdin);
  pipe(fdout);

  write(fdin[1], command, strlen(command));
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
    _exit(1);
  } else if (ret < 0) {
    perror("fork");
    exit(1);
  }

  dup2(tmpin, 0);
  dup2(tmpout, 1);
  close(tmpin);
  close(tmpout);

  char c;
  char * buf = (char *) malloc (1024);
  int i = 0;

  while(read(fdout[0], &c, 1)){
    if(c == '\n'){
      i++;
      buf[i] = ' ';
    } else {
      i++;
      buf[i] = c;
    }
  }
  buf[i] = '\0';
  
  for(i = strlen(buf); i >=0; i--){
    unput(buf[1]);
  }
}

[^ \t\n|><&]*\\[^ \t\n]* {
  int i = 0;
  char * escape = (char *) malloc (1024);
  char * temp = yytext;
}

[^ \t\n][^ \t\n]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}



%%
