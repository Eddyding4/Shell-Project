#include <cstdio>
#include <signal.h>
#include "shell.hh"
#include <string.h>
#include <stdlib.h>

int yyparse(void);

extern "C" void disp(int sig){
  printf("myshell>");
}

void Shell::prompt() {
  printf("myshell>");
  char s[20];
    fgets( s, 20, stdin);
    if(!strcmp(s, "exit\n")){
      printf("Bye!\n");
      exit(1);
    }
  fflush(stdout);
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
  yyparse();
 
}

Command Shell::_currentCommand;
