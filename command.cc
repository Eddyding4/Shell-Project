/*
 * CS252: Shell project
 *
 * Template file.
 * You will need to add more code here to execute the command table.
 *
 * NOTE: You are responsible for fixing any bugs this code may have!
 *
 * DO NOT PUT THIS PROJECT IN A PUBLIC REPOSITORY LIKE GIT. IF YOU WANT 
 * TO MAKE IT PUBLICALLY AVAILABLE YOU NEED TO REMOVE ANY SKELETON CODE 
 * AND REWRITE YOUR PROJECT SO IT IMPLEMENTS FUNCTIONALITY DIFFERENT THAN
 * WHAT IS SPECIFIED IN THE HANDOUT. WE OFTEN REUSE PART OF THE PROJECTS FROM  
 * SEMESTER TO SEMESTER AND PUTTING YOUR CODE IN A PUBLIC REPOSITORY
 * MAY FACILITATE ACADEMIC DISHONESTY.
 */

#include <cstdio>
#include <cstdlib>

#include <iostream>
#include <fcntl.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>
#include <signal.h>
#include <errno.h>

#include <cstring>
#include "command.hh"
#include "shell.hh"


Command::Command() {
    // Initialize a new vector of Simple Commands
    _simpleCommands = std::vector<SimpleCommand *>();

    _outFile = NULL;
    _inFile = NULL;
    _errFile = NULL;
    _background = false;
}

void Command::insertSimpleCommand( SimpleCommand * simpleCommand ) {
    // add the simple command to the vector
    _simpleCommands.push_back(simpleCommand);
}

void Command::clear() {
    // deallocate all the simple commands in the command vector
    for (auto simpleCommand : _simpleCommands) {
        delete simpleCommand;
    }

    // remove all references to the simple commands we've deallocated
    // (basically just sets the size to 0)
    _simpleCommands.clear();
    bool check = (_outFile == _errFile);

    
    if ( _outFile ) {
        delete _outFile;
    }
    _outFile = NULL;

    if ( _inFile ) {
        delete _inFile;
    }
    _inFile = NULL;

    if ( _errFile && !check) {
        delete _errFile;
    }
    _errFile = NULL;
    _append = false;
    _background = false;
}

void Command::print() {
    /*printf("\n\n");
    printf("              COMMAND TABLE                \n");
    printf("\n");
    printf("  #   Simple Commands\n");
    printf("  --- ----------------------------------------------------------\n");

    int i = 0;
    // iterate over the simple commands and print them nicely
    for ( auto & simpleCommand : _simpleCommands ) {
        printf("  %-3d ", i++ );
        simpleCommand->print();
    }

    printf( "\n\n" );
    printf( "  Output       Input        Error        Background\n" );
    printf( "  ------------ ------------ ------------ ------------\n" );
    printf( "  %-12s %-12s %-12s %-12s\n",
            _outFile?_outFile->c_str():"default",
            _inFile?_inFile->c_str():"default",
            _errFile?_errFile->c_str():"default",
            _background?"YES":"NO");
    printf( "\n\n" );
    */
}

void Command::execute() {
  if(strcmp(_simpleCommands[0]->_arguments[0]->c_str(),"exit") == 0){
		printf("Good bye!!\n");
		exit(1);
	}
  if(!strcmp(_simpleCommands[0]->_arguments[0]->c_str(), "setenv") ){
    for(char **env = environ; *env != 0; env++){
      char * thisEnv = *env;
      if(strstr(thisEnv, _simpleCommands[0]->_arguments[1]->c_str())){
        char * temp = strtok(thisEnv, "=");
        char result [100]; 
        strcpy(result, temp);
        strcat(result, "=");
        strcat(result, _simpleCommands[0]->_arguments[2]->c_str());
        strcpy(*env, result);
      }
    }
  } else if (!strcmp(_simpleCommands[0]->_arguments[0]->c_str(), "unsetenv")){
    for(char **env = environ; *env != 0; env++){
      char * thisEnv = *env;
      if(strstr(thisEnv, _simpleCommands[0]->_arguments[1]->c_str())){
        strcpy(*env, "");
      }
    } 
  } else if (!strcmp(_simpleCommands[0]->_arguments[0]->c_str(), "printenv")){
    for(char **env = environ; *env != 0; env++){
      char * thisEnv = *env;
      printf("%s\n", thisEnv);
    }
  } else if (!strcmp(_simpleCommands[0]->_arguments[0]->c_str(), "cd")){
    if (_simpleCommands[0]->_arguments[1] != NULL){
      chdir(_simpleCommands[0]->_arguments[1]->c_str());
    } else {
      chdir(getenv("HOME"));
    }
  } else {
    // Don't do anything if there are no simple commands
  if ( _simpleCommands.size() == 0 ) {
    if(isatty(0)){ 
	  Shell::prompt();
    return;
    }
  }  

    // Print contents of Command data structure
  print();
    
    // save in and out
  int tmpin = dup(0);
  int tmpout = dup(1);
  int tmperr = dup(2);
    // set initial input
  int fdin;
  if (_inFile) {
    fdin = open(_inFile->c_str(), O_RDONLY);
  } else {
      // use default input
    fdin = dup(tmpin);
  }
  int ret;
  int fdout;
  int fderr;
  if(_errFile){
    fderr = open(_errFile->c_str(), O_WRONLY|O_CREAT|O_TRUNC, 0664);

  } else {
    fderr = dup(tmperr);
  }
  dup2(fderr, 2);
  for ( unsigned int i = 0; i < _simpleCommands.size() ; i++ ) {
   
    // redirect input 
    dup2(fdin, 0);
    close(fdin);
       
    // setup output
    if( i == _simpleCommands.size() - 1 ){
    // last simple command
	    if(_outFile){
	      fdout = open(_outFile->c_str(), O_WRONLY|O_CREAT|O_TRUNC, 0664);
	    } else {
	      fdout = dup(tmpout);
	    }
    } else {
	// not last simple command create pipe
	  int fdpipe[2];
    pipe(fdpipe);
	  fdout = fdpipe[1];
	  fdin = fdpipe[0];
    } 
    dup2(fdout, 1);
    close(fdout);
    //create child process
    ret = fork();
    if (ret == 0) {
      if(strcmp(_simpleCommands[i]->_arguments[0]->c_str(), "source") == 0){
        FILE * fp = fopen(_simpleCommands[i]->_arguments[1]->c_str(), O_RDONLY);
        char line[1024];
        fgets(line, 1023, fp);
        fclose(fp);
        int tmp2in = dup(0);
        int tmp2out = dup(1);
        int fdpipein[2];
        int fdpipeout[2];

        pipe(fdpipein);
        pipe(fdpipeout);

        write(fdpipein[1], line, strlen(line));
        write(fdpipein[1], "\n", 1);

        close(fdpipein[1]);
        dup2(fdpipein[0], 0);
        close(fdpipein[0]);
        dup2(fdpipeout[1], 1);
        close(fdpipeout[1]);
        int pid = fork();
        if(pid == 0){
          execvp("/proc/self/exe", NULL);
          _exit(1);
        } else if (pid < 0) {
          perror("fork");
          exit(2);
        }
        dup2(tmp2in, 0);
        dup2(tmp2out, 1);
        close(tmp2in);
        close(tmp2out);

        char c;
        char * buf = (char *) malloc(200);
        int i = 0;
        while (read(fdpipeout[0], &c, 1)){
          if (c != '\n'){
            i++;
            buf[i] = c;
          }
        }
        buf[i] = '\0';
        printf("%s\n", buf);
      } else {
        char** myargv = (char **) malloc ((_simpleCommands[i]->_arguments.size() + 1) * sizeof(char*));
	      for ( unsigned int j = 0; j < _simpleCommands[i]->_arguments.size(); j++ ) {

	        myargv[j] = strdup(_simpleCommands[i]->_arguments[j]->c_str());
	      }
	      myargv[_simpleCommands[i]->_arguments.size()] = NULL;
        
	      execvp(myargv[0], myargv);
        	
	      perror("execvp");
	      exit(1);	
      }
    }
    else if (ret < 0) {
      perror("fork");
	    exit(2);
    }
  }
   
    // restore in/out defaults
    dup2(tmpin, 0);
    dup2(tmpout, 1);
    dup2(tmperr, 2);

    close(tmpin);
    close(tmpout);
    close(tmperr);
    if (!_background) {
      waitpid(ret, 0, 0);
    }
  }
  
 // Clear to prepare for next command
  clear();

  // Print new prompt
  /*if ( isatty(0) ) {
    Shell::prompt();
  }*/
  Shell::prompt();
}

SimpleCommand * Command::_currentSimpleCommand;
