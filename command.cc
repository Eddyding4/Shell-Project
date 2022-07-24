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
  if(strcmp(_simpleCommands[0]->_arguments[0]->c_str(), "exit") == 0){
    printf("Good Bye!!\n");
    exit(1);
  }
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
  if(!strcmp(_simpleCommands[i]->_arguments[0]->c_str(), "setenv") ){
    int error = setenv(_simpleCommands[i]->_arguments[1]->c_str(), _simpleCommands[i]->_arguments[2]->c_str(), 1);
		if(error) {
			perror("setenv");
		}
    clear();
    Shell::prompt();
    return;
  } else if (!strcmp(_simpleCommands[i]->_arguments[0]->c_str(), "unsetenv")){
    int error = unsetenv(_simpleCommands[i]->_arguments[1]->c_str());
		if(error) {
			perror("unsetenv");
		}
		clear();
		Shell::prompt();
    return;

  } else if (!strcmp(_simpleCommands[i]->_arguments[0]->c_str(), "cd")){
    int error;
		if(_simpleCommands[i]->_arguments.size() == 1){
			error = chdir(getenv("HOME"));
		} else {
			error = chdir(_simpleCommands[i]->_arguments[1]->c_str());
		}

		if(error < 0){
			perror("cd");
		}

		clear();
		Shell::prompt();
    return;
  }
  if(strcmp(_simpleCommands[i]->_arguments[0]->c_str(), "source") == 0){
    std::string cmd;
		std::ifstream fd;

		fd.open(_simpleCommands[i]->_arguments[1]->c_str());

		std::getline(fd, cmd);
		fd.close();

		// save in/out
		int tmpin=dup(0);
		int tmpout=dup(1);

		// input command
		int fdpipein[2];
		pipe(fdpipein);
		write(fdpipein[1], cmd.c_str(), strlen(cmd.c_str()));
		write(fdpipein[1], "\n", 1);

		close(fdpipein[1]);

		int fdpipeout[2];
		pipe(fdpipeout);

		dup2(fdpipein[0], 0);
		close(fdpipein[0]);
		dup2(fdpipeout[1], 1);
		close(fdpipeout[1]);

		int ret_source = fork();
		if (ret_source == 0) {
			execvp("/proc/self/exe", NULL);
			exit(1);
		} else if (ret < 0) {
			perror("fork");
			exit(1);
	 }

		dup2(tmpin, 0);
		dup2(tmpout, 1);
		close(tmpin);
		close(tmpout);	

		char ch;
		char * buffer = new char[i];
	 int r = 0;

				// read output 
		while (read(fdpipeout[0], &ch, 1)) {
			//if (ch == '\n' ? buffer[i++] = '\n' : buffer[i++] = ch) {};
			if (ch != '\n')  buffer[r++] = ch;
		}

		buffer[r] = '\0';
		printf("%s\n",buffer);

		fflush(stdout);
    clear();
		Shell::prompt();
		return;
    }
       
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
      if (!strcmp(_simpleCommands[i]->_arguments[0]->c_str(), "printenv")){
        char ** env = environ;
				while(*env){
					printf("%s\n", *env);
					env++;
				}
      }
        char** myargv = (char **) malloc ((_simpleCommands[i]->_arguments.size() + 1) * sizeof(char*));
	      for ( unsigned int j = 0; j < _simpleCommands[i]->_arguments.size(); j++ ) {

	        myargv[j] = strdup(_simpleCommands[i]->_arguments[j]->c_str());
	      }
	      myargv[_simpleCommands[i]->_arguments.size()] = NULL;
        
	      execvp(myargv[0], myargv);
        	
	      perror("execvp");
	      exit(1);	 
      } else if (ret < 0) {
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
  
 // Clear to prepare for next command
  clear();

  // Print new prompt
  /*if ( isatty(0) ) {
    Shell::prompt();
  }*/
  Shell::prompt();
}
SimpleCommand * Command::_currentSimpleCommand;
