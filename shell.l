
/*
 *
 * CS-252 
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{

#include <cstring>
#include "y.tab.hh"
#include <sys/wait.h>
#include <sys/types.h>

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

. {
  return NOTOKEN;
}

~[^ \n\t]* {
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

`[^\n`]*` {
	char * command = strdup(yytext+1);

	if(command[yyleng-2] == '`')
		command[yyleng-2] = '\0';
	
	int tmpin = dup(0);
	int tmpout = dup(1);

	int fdpipein[2];
	int fdpipeout[2];

	pipe(fdpipein);
	pipe(fdpipeout);

	write(fdpipein[1], command, strlen(command));
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

	dup2(tmpin, 0);
	dup2(tmpout, 1);
	close(tmpin);
	close(tmpout);

	char ch;
	char * buffer = (char *) malloc (4096);
	int i = 0;
	
	// Read from the pipe the output of the subshell
	while (read(fdpipeout[0], &ch, 1)) {
		if (ch == '\n') buffer[i++] = ' ';
		else buffer[i++] = ch;
	}
	buffer[i] = '\0';

	for (i = strlen(buffer); i >= 0; i--) {
		unput(buffer[i]);
	}
}

["][^\n\"]*["] {
	//quotes
	yylval.cpp_string = new std::string(yytext);
	*yylval.cpp_string = yylval.cpp_string->substr(1, yylval.cpp_string->length()-2);

	/*printf("after dequote, string = %s\n",yylval.cpp_string);*/
	return WORD;
}



[^ \t\n|><&]*\\[^ \t\n]* {
  //escape
	char * str = strdup(yytext);
	char * newstr = (char*) malloc (100);
	//printf("before deescaping, string = %s\n", str);

	int i = 0;
	while (*str){
		if (*str == '\\'){
			if (*(str+1) == '\\'){
				str = str +2;
				newstr[i++] = '\\';
			}else{
				newstr[i++] = *(++str);
			}
		}else{
			newstr[i++] = *str;
		}
		str++;
	}
	newstr[i] = '\0';
	yylval.cpp_string = new std::string(newstr);
	return WORD;
}

$\{[^ \}\n]*\}([^ \n]*|$\{[^ \}\n]*\})* {
  //dollar sign
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
  yylval.cpp_string = new std::string(result);
  return WORD;
}

[^ \t\n][^ \t\n]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}



%%
