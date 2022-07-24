#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>

#include "simpleCommand.hh"

SimpleCommand::SimpleCommand() {

  _arguments = std::vector<std::string *>();
}

SimpleCommand::~SimpleCommand() {
  // iterate over all the arguments and delete them
  for (auto & arg : _arguments) {
    delete arg;
  }
}
std::string  SimpleCommand::expansion(std::string * argument){
  char * arg = strdup(argument->c_str());
	char * checkDollar = strchr(arg, '$');
	char * checkBraces = strchr(arg, '{');

	char * replace = (char *) malloc (sizeof(argument) + 50);
	char * temp = replace;

	if (checkDollar && checkBraces) {
		while (*arg != '$') {
			*temp = *arg;
			temp++; arg++;
		}
		*temp = '\0';

		while (checkDollar) {
			if (checkDollar[1] == '{' && checkDollar[2] != '}') {
				char * temporary = checkDollar + 2;
				char * env = (char *) malloc (20);
				char * envtemp = env;

				while (*temporary != '}') {
					*envtemp = *temporary;
					envtemp++; temporary++;
				}
				*envtemp = '\0';

				char * get = getenv(env);

				strcat(replace, get);

				while (*(arg-1) != '}') arg++;

				char * buf = (char *) malloc (20);
				char * tbuf = buf;

				while (*arg != '$' && *arg) {
					*tbuf = *arg;
					tbuf++; arg++;
				}
				*tbuf = '\0';
				strcat(replace, buf);
			}
			checkDollar++;
			checkDollar = strchr(checkDollar, '$');
		}
    std::string str = std::string(replace);
		return str;
	}
	return NULL;
}


void SimpleCommand::insertArgument( std::string * argument ) {
  // simply add the argument to the vector
  _arguments.push_back(argument);
  argument = &expansion(argument);

}



// Print out the simple command
void SimpleCommand::print() {
  for (auto & arg : _arguments) {
    std::cout << "\"" << *arg << "\" \t";
  }
  // effectively the same as printf("\n\n");
  std::cout << std::endl;
}
