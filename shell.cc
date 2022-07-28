#include <cstdio>
#include <signal.h>
#include "shell.hh"
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include "y.tab.hh"
int yyparse(void);

extern "C" void disp(int sig){
  printf("\n");
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


int main(int argc, char ** argv) {
  FILE * in = fopen(".shellrc", "r+");
  if (!in) {
    perror("fopen");
    BEGIN(INITIAL);
  } else {
    fputc('\n', in);
    yypush_buffer_state(yy_create_buffer(in, YY_BUF_SIZE));
    BEGIN(INITIAL);
    yyparse();
    yypop_buffer_state();
    fclose(in);
  }

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
