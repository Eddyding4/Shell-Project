#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>

#include "simpleCommand.hh"

SimpleCommand::SimpleCommand() {

  _arguments = std::vector<std::string *>();
}

std::string * SimpleCommand::expansion(std::string * arg) {
  char * ptr = strdup(arg->c_str());
  char * dollar = strchr(ptr, '$');
  char * bracket = strchr(ptr, '{');
  char * replace = (char *) malloc (sizeof(arg) + 100);
  char * temp = replace;

  if(dollar && bracket){
    while(*ptr != '$'){
      *temp = *ptr;
      ptr++;
      temp++;
    }
    *temp = '\0';
    while(dollar){
      if(dollar[1] == '{' && dollar[2] == '}'){
        char * temp2 = dollar + 2;
        char * env = (char * ) malloc (1024);
        char * tempenv = env;
        while(*temp2 != '}'){
          *tempenv = *temp2;
          tempenv++;
          temp2++;
        }
        *tempenv = '\0';
        char * get = getenv(env);
        strcat(replace, get);

        while(*(ptr - 1) != '}'){
          ptr++;
        }
        char * buf = (char *) malloc (1024);
        char * tempbuf = buf;

        while(*ptr != '$' && *ptr){
          *tempbuf = *ptr;
          tempbuf++;
          ptr++;
        }
        *tempbuf = '\0';
        strcat(replace, buf);
      }
      dollar++;
      dollar = strchr(dollar, '$');
    }
    char * str = strdup(replace);
    arg = std::string*(str);
    
    return arg;
  }
  return NULL;
}

SimpleCommand::~SimpleCommand() {
  // iterate over all the arguments and delete them
  for (auto & arg : _arguments) {
    delete arg;
  }
}

void SimpleCommand::insertArgument( std::string * argument ) {
  // simply add the argument to the vector
  _arguments.push_back(argument);
  std::string * temp = expansion(argument)
}

// Print out the simple command
void SimpleCommand::print() {
  for (auto & arg : _arguments) {
    std::cout << "\"" << *arg << "\" \t";
  }
  // effectively the same as printf("\n\n");
  std::cout << std::endl;
}
