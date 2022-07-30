/*
 * CS252: Systems Programming
 * Purdue University
 * Example that shows how to read one line with simple editing
 * using raw terminal.
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <termios.h>
#include <assert.h>
#include <string>
#include <vector>

#define MAX_BUFFER_LINE 1024
#define HISTORY_SIZE 32

extern "C" void  tty_raw_mode(void);
extern char* strdup(const char*);

// Buffer where line is stored
int line_length;
char line_buffer[MAX_BUFFER_LINE];
char right_buf[MAX_BUFFER_LINE];
int right_side;
int current;

// Simple history array
// This history does not change. 
// Yours have to be updated.

std::vector<std::string> history;

void read_line_print_usage()
{
  std::string usage = "\n"
    " ctr-a        Move to the beginning of line\n"
    " ctr-e        Move to the end of line\n"
    " ctr-h        Removes the character at the position before the cursor.\n"
    " ctr-h        Removes the character at the cursor\n"
    " ctrl-?       Print usage\n"
    " Backspace    Deletes last character\n"
    " up arrow     See last command in the history\n";

  write(1, usage.c_str(), strlen(usage.c_str()));
}

/* 
 * Input a line with some basic editing.
 */
char * read_line() {
  struct termios original_attribute;
	tcgetattr(0, &original_attribute);
  // Set terminal in raw mode
  tty_raw_mode();

  line_length = 0;
  right_side = 0;
  current = 0;
  // Read one line until enter is typed
  while (1) {

    // Read one character in raw mode.
    char ch;
    read(0, &ch, 1);

    if (ch>=32 && ch != 127) {
      // It is a printable character. 

      // Do echo
      write(1,&ch,1);

      // If max number of character reached return.
      if (line_length==MAX_BUFFER_LINE-2) break; 
    
      // add char to buffer.
      line_buffer[line_length]=ch;
      line_length++;

      // Check right_buf
      if (right_side) {
        for (int i=right_side-1; i>=0; i--) {
          char c = right_buf[i];
          write(1,&c,1);
        }
      }
      for (int i=0; i<right_side; i++) {
        char c = 8;
        write(1,&c,1);
      }
    }
    else if (ch==10) {
      // <Enter> was typed. Return line
      char temp[MAX_BUFFER_LINE];
      for(int i = 0; i < line_length; i++){
        
        char ascii = (char)(line_buffer[i]);
        strcat(temp, &ascii);
      }
      printf("%s\n", temp[0]);
      printf("%s\n", temp);
      // Print newline

      write(1,&ch,1);
      break;
    }
    else if (ch == 1) {
      // ctrl-A was typed. The cursor moves to the beginning of the line
      int tmp = line_length;
      for (int i=0; i<tmp; i++) {
        char c = 8;
        write(1,&c,1);
        right_buf[right_side] = line_buffer[line_length-1];
        right_side++;
        line_length--;
        current++;
      }
    }
    else if (ch == 4) {
      // ctrl-D was typed

      // Go back one character
      if (line_length == 0) continue;

      for(int i=right_side-2; i>=0; i--) {
        char c = right_buf[i];
        write(1,&c,1);
      }
      // Write a space to erase the last character read
      ch = ' ';
      write(1,&ch,1);

      // Go back one character
      for (int i=0; i<right_side; i++) {
        char c = 8;
        write(1,&c,1);
      }

      // Remove one character from buffer
      right_side--;
    }
    else if (ch == 5) {
      // ctrl-E was typed. The cursor moves to the end of the line
      for (int i=right_side-1; i>=0; i--) {
        write(1,"\033[1C",5);
        line_buffer[line_length]=right_buf[right_side-1];
        right_side--;
        line_length++;
        current--;
      }
    }
    
    else if (ch == 8 || ch == 127) {
      // <backspace> was typed. Remove previous character read.

      // Removes the character at the cursor
      if (line_length == 0) continue;

      ch = 8;
      write(1,&ch,1);

      for(int i=right_side-1; i>=0; i--) {
        char c = right_buf[i];
        write(1,&c,1);
      }
      // Write a space to erase the last character read
      ch = ' ';
      write(1,&ch,1);
      
      // Go back one character
      for (int i=0; i<right_side+1; i++) {
        char c = 8;
        write(1,&c,1);
      }

      // Remove one character from buffer
      line_length--;
      current--;
    }
    else if (ch==27) {
      // Escape sequence. Read two chars more
      //
      // HINT: Use the program "keyboard-example" to
      // see the ascii code for the different chars typed.
      //
      char ch1; 
      char ch2;
      read(0, &ch1, 1);
      read(0, &ch2, 1);
      if (ch1==91 && ch2==65 ) {
	      // Up arrow. Print next line in history.
       
	      // Erase old line
	      // Print backspaces
	      int i = 0;
	      for (i =0; i < line_length - current; i++) {
	        ch = 8;
	        write(1,&ch,1);
	      }
       
	      // Print spaces on top
	      for (i =0; i < line_length; i++) {
	        ch = ' ';
	        write(1,&ch,1);
	      }
       
	      // Print backspaces
	      for (i =0; i < line_length; i++) {
	        ch = 8;
	        write(1,&ch,1);
	      }	
        right_side = 0;
	      // Copy line from history
	      
       
	      // echo line
	      write(1, line_buffer, line_length);
        current = line_length;
      } if (ch1 == 91 && ch2 == 66){
        // down arrow
        // Erase old line
        // Print backspaces
        int i = 0;
        for (i =line_length - current; i < line_length; i++) {
          ch = 8;
            write(1,&ch,1);
        }

        // Print spaces on top
        for (i =0; i < line_length; i++) {
          ch = ' ';
          write(1,&ch,1);
        }

        // Print backspaces
        for (i =0; i < line_length; i++) {
            ch = 8;
            write(1,&ch,1);
        }	

        if(1 > 0)
        {
          // Copy line from history
          line_length = strlen(line_buffer);

          // echo line
          write(1, line_buffer, line_length);
          current = line_length;
        }
        else
        {
          strcpy(line_buffer, "");
          line_length = strlen(line_buffer);

          write(1, line_buffer, line_length);
          current = line_length;
        }

      } if (ch1==91 && ch2==68) {
        // left arrow. 

        // Move the cursor to the left
        if (line_length == 0) continue;
        ch = 8;
        write(1,&ch,1);
        // Allow insertion 
        right_buf[right_side] = line_buffer[line_length-1];
        right_side++;
        line_length--;
        current--;
      }
      else if (ch1==91 && ch2==67) {
        // right arrow. 

        // Move the cursor to the arrow
        if (right_side == 0) continue;
        write(1,"\033[1C",5);
        // Allow insertion 
        line_buffer[line_length]=right_buf[right_side-1];
        line_length++;
        right_side--;
        current++;
      }
      
    }

  }

  // Add eol and null char at the end of string
  line_buffer[line_length]=10;
  line_length++;
  line_buffer[line_length]=0;
  tcsetattr(0, TCSANOW, &original_attribute);

  return line_buffer;
}