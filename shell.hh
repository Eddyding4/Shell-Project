#ifndef shell_hh
#define shell_hh



struct Shell {

  static void prompt();

  static Command _currentCommand;
  static int _code;
};

#endif
