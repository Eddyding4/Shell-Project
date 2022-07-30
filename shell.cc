#include <cstdio>
#include <signal.h>
#include "shell.hh"
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
int yyparse(void);

extern "C" void disp(int sig){
  printf("\n");
  Shell::prompt();
}
extern "C" void dis(int sig){
  while(waitpid(-1, 0, WNOHANG) > 0 ){
  }
}
void Shell::prompt() {
  if ( isatty(0) ) {
    if(!strcmp(getenv("PROMPT"), "")){
      printf("myshell>");
    } else {
      printf(getenv("PROMPT"));
      printf(">")
    }
  }
  fflush(stdout);
}


int main(int argc, char ** argv) {
  setenv("PROMPT", "", 1);
  Shell::prompt();
  struct sigaction signalAction;
  signalAction.sa_handler = disp;
  sigemptyset(&signalAction.sa_mask);
  signalAction.sa_flags = SA_RESTART;
  
  Shell::path = realpath(argv[0], NULL);
  
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
char * Shell::path;
