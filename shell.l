
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

\"[^\n\"]*\" {
  std::string str = std::string(yytext);
  str = str.substr(1,str.size()-2);
  yylval.cpp_string = new std::string(str);
  return WORD;
}

[^ \\\t\n]*(\\[^nt])((\\[^nt])|[^ \\\t\n])* {
  std::string str = std::string(yytext);
  std::size_t found = str.find('\\');
  while(found!=-1) {
    str = str.substr(0,found) + str.substr(found+1,std::string::npos);
    found = str.find('\\', found+1);
  }
  yylval.cpp_string = new std::string(str);
  return WORD;
}

$\{[^ \}\n]*\}([^ \n]*|$\{[^ \}\n]*\})* {
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
