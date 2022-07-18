#include <cstdio>
#include <signal.h>
#include "shell.hh"

int yyparse(void);

void Shell::prompt() {
  printf("myshell>");
  fflush(stdout);
}


int main() {
  Shell::prompt();
  struct sigaction signalAction;
  //signalAction.sa_handler = sigIntHandler;
  sigemptyset(&signalAction.sa_mask);
  signalAction.sa_flags = SA_RESTART;

  if(sigaction(SIGINT, &signalAction, NULL)){
    perror("sigaction");
    exit(2);
  }
  yyparse();
}

Command Shell::_currentCommand;
