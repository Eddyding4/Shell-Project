#include <cstdio>
#include <signal.h>
#include "shell.hh"
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

#ifndef YY_BUF_SIZE
#ifdef __ia64__
#define YY_BUF_SIZE 30000
#else
#define YY_BUF_SIZE 16000
#endif

void yyrestart(FILE * input_file );
int yyparse(void);
void yypush_buffer_state(YY_BUFFER_STATE buffer);
void yypop_buffer_state();
YY_BUFFER_STATE yy_create_buffer(FILE * file, int size);

extern "C" void disp(int sig){
  //printf("\n");
  Shell::prompt();
}
extern "C" void dis(int sig){
  while(waitpid(-1, 0, WNOHANG) > 0 ){
 
  //printf("%d exited\n", getpid());
  }
}
void Shell::prompt() {
  if ( isatty(0) ) {
    printf("myshell>");

  }
  fflush(stdout);
}

void source(void) {
  std::string s = ".shellrc";
  FILE * in = fopen(s.c_str(), "r");

  if (!in) {
    return;
  }

  yypush_buffer_state(yy_create_buffer(in, YY_BUF_SIZE));
  Shell::_srcCmd = true;
  yyparse();
  yypop_buffer_state();
  fclose(in);
  Shell::_srcCmd = false;
}


int main() {
  Shell::prompt();	
  struct sigaction signalAction;
  signalAction.sa_handler = disp;
  sigemptyset(&signalAction.sa_mask);
  signalAction.sa_flags = SA_RESTART;

  if(sigaction(SIGINT, &signalAction, NULL)){
    perror("sigaction");
    exit(2);
  }
  struct sigaction sa;
  sa.sa_handler = dis;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_RESTART | SA_NOCLDSTOP;
  if(sigaction(SIGCHLD, &sa, NULL)){
    perror("sigaction");
    exit(2);
  }
  yyparse();
 
}

Command Shell::_currentCommand;
