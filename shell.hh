#ifndef shell_hh
#define shell_hh

#include "command.hh"

struct Shell {

  static void prompt();

  static Command _currentCommand;
  static std::string code;
  static std::string code2;

  static char* path;
};

#endif
