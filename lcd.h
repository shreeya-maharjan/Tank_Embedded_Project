/*#ifndef LCD_H
#define LCD_H

#include <stdint.h>

/* Shadow screen buffer (128x64 / 8 = 1024 bytes) 
extern unsigned char xdata screen[1024];

/* Core functions 
void init_lcd(void);
void refresh_screen(void);
void clear_screen(void);

/* Low-level (optional but useful) 
void lcd_cmd(unsigned char cmd);
void lcd_data(unsigned char dat);

#endif*/


#ifndef LCD_H
#define LCD_H

extern char xdata screen[];
extern char code font5x8[];

void init_lcd(void);
void refresh_screen(void);
void blank_screen(void);

#endif