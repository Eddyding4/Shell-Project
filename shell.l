
/*
 *
 * CS-252 
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */
%s SOURCE_SC
%{

#include <cstring>
#include "y.tab.hh"
#include <sys/wait.h>
#include <sys/types.h>
#include "shell.hh"

static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
  unput(c);
}

%}

%option noyywrap

%%

\n {
  return NEWLINE;
}

[ \t] {
  /* Discard spaces and tabs */
}

">" {
  return GREAT;
}

">>" {
  return GREATGREAT;
}

"|" {
  return PIPE;
}

"&" {
  return AMPERSAND;
}

">>&" {
  return GREATGREATAMPERSAND;
}

">&" {
  return GREATAMPERSAND;
}

"<" {
  return LESS;
}

"2>" {
  return STANDARDERR;
}

"source" {
  BEGIN(SOURCE_SC);
}

<SOURCE_SC>[^ ><|&\t\n][^ ><|&\t\n]* {
  FILE * in = fopen(yytext, "r+");
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
}

[^ \t\n|><&]*\\[^ \t\n]* {
  //escape
	int i=0;
	char * escChar;
	escChar = new char[strlen(yytext)*2];
	char * args = yytext;
	while ( *args ) {
		if ( *args == '\\' ) {	
			escChar[i] = *(++args);
			i++;	
		} else {
			escChar[i] = *args;
			i++;
		}
		args++;
	}
	escChar[i] = '\0';
	yylval.cpp_string = new std::string(escChar);
	return WORD;
	
}

["][^\n\"]*["] {
	//quotes
	int i = 0;
	char * quoteChar = new char[strlen(yytext)];
	char * args = yytext;
	
	while ( *args ) {
		if ( *args == '\"' ) {
			quoteChar[i] = *(++args);
			i++;
		} else {
			quoteChar[i] = *args;
			i++;
		}
		args++;
	}
	quoteChar[i] = '\0';
	yylval.cpp_string = new std::string(quoteChar);
	return WORD;
}

\$\([^\n\$]*\)|`[^\n`]*` {
	//subshell
  	std::string * cmd = new std::string(yytext);
	cmd->pop_back();

	// string check
	if (strchr(cmd->c_str(), '`') != NULL) { 
		cmd = new std::string(yytext+1);
		cmd->pop_back();
	}
	else {
		cmd = new std::string(yytext+2);  
		cmd->pop_back();
	}

	int tmpin = dup(0);
	int tmpout = dup(1);

	int fdpipein[2];
	int fdpipeout[2];

	pipe(fdpipein);
	pipe(fdpipeout);

	write(fdpipein[1], cmd->c_str(), cmd->size());
	write(fdpipein[1], "\n", 1);
	write(fdpipein[1], "exit", 4);
	write(fdpipein[1], "\n", 1);

	close(fdpipein[1]);

	dup2(fdpipein[0], 0);
	close(fdpipein[0]);
	dup2(fdpipeout[1], 1);
	close(fdpipeout[1]);

	int ret = fork();
	if (ret == 0) {
		execvp("/proc/self/exe", NULL);
		_exit(1);
	} else if (ret < 0) {
		perror("fork");
		exit(1);
	}
  waitpid(ret, 0, 0);
	dup2(tmpin, 0);
	dup2(tmpout, 1);
	close(tmpin);
	close(tmpout);

	char ch;
	std::string buffer;
	int i = 0;
	
	// Read from the pipe the output of the subshell
	while (read(fdpipeout[0], &ch, 1)) {
		if (ch == '\n') 
    ch = ' ';
    buffer.push_back(ch);
	}
  //fprintf(stderr, "%s", buffer.c_str());
	for (i = buffer.length() - 1; i >= 0; i--) {
		unput(buffer[i]);
	}
}

~[^ \n\t]* {
	//tilde stuff
  std::string str = std::string(yytext);
  std::string home = getenv("HOME");
  if (str.size() == 1) {
    yylval.cpp_string = new std::string(home);
  } 
  else {
    if (str[1] == '/') {
      str = home + str.substr(1, -1);
    } 
    else {
      str = std::string("/homes/") + str.substr(1,-1);
    }
    yylval.cpp_string = new std::string(str);
  }
  return WORD;
}

$\{[^ \}\n]*\}([^ \n]*|$\{[^ \}\n]*\})* {
  //environment expansion
  std::string str = std::string(yytext);
  std::string result = "";
  std::size_t found = str.find('$');
  while(found!=-1) {
    std::string component;
    result += str.substr(0, found);
    if (str[found+1] == '{') {
      std::size_t end = str.find('}');
      if (end != -1) {
        component = str.substr(found+2, end-found-2);
        if (getenv(component.c_str())) result += getenv(component.c_str());
        else result += component;      
        str = str.substr(end+1,-1);
      }
    }
    found = str.find('$');
  }
  result += str;
  if(strcmp(result.c_str(), "$") == 0){
	int pid = getpid();
	std::string temp = std::to_string(pid);
	yylval.cpp_string = new std::string(temp);
  } else if(strcmp(result.c_str(), "?") == 0){
	//printf("%s", WEXITSTATUS(status))
  } else {
    yylval.cpp_string = new std::string(result);
  }

  return WORD;
}


[^ ><|&\t\n][^ ><|&\t\n]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}



%%
