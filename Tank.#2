#include <C8051F020.h>
#include "lcd.h"

extern unsigned char xdata screen[1024];
unsigned char xdata wall_screen[1024];

sbit BTN1 = P1^6;
sbit BTN2 = P1^7;


code unsigned int tank[8][9] =
{
    {0x0000,0x00FC,0x00FC,0x0038,0x003F,0x0038,0x00FC,0x00FC,0x0000},
    {0x0001,0x0009,0x0012,0x003C,0x0079,0x00DE,0x008C,0x0018,0x0030},
    {0x0010,0x0010,0x00D6,0x00FE,0x00FE,0x00FE,0x00C6,0x00C6,0x0000},
    {0x0100,0x0090,0x0048,0x003C,0x009E,0x007B,0x0031,0x0018,0x000C},
    {0x0000,0x007E,0x007E,0x0038,0x01F8,0x0038,0x007E,0x007E,0x0000},
    {0x000C,0x0018,0x0031,0x007B,0x009E,0x003C,0x0048,0x0090,0x0100},
    {0x0000,0x00C6,0x00C6,0x00FE,0x00FE,0x00FE,0x00D6,0x0010,0x0010},
    {0x0030,0x0018,0x008C,0x00DE,0x0079,0x003C,0x0012,0x0009,0x0001}
};

/* Direction & speed tables replace all switch statements */
code unsigned char delay_lut[5] = {0, 8, 5, 3, 1};
code signed char   move_dx[8]   = { 0,-1,-1,-1, 0, 1, 1, 1};
code signed char   move_dy[8]   = {-1,-1, 0, 1, 1, 1, 0,-1};
code signed char   proj_dx[8]   = { 0,-2,-2,-2, 0, 2, 2, 2};
code signed char   proj_dy[8]   = {-2,-2, 0, 2, 2, 2, 0,-2};

/* String literals in flash */
code char str_ready[]     = "READY";
code char str_press[]     = "PRESS BUTTON";
code char str_to_start[]  = "TO START";

unsigned xdata pot1_sample, pot2_sample;
long     xdata pot1_hold = 0, pot2_hold = 0;
int      xdata adc_val;
unsigned char  xdata shot_x[2], shot_y[2], shot_dir[2], shot_time[2];
unsigned int   xdata rand_seed = 1234;
volatile unsigned int xdata sound_duration = 0;

unsigned char field_num   = 0;
unsigned char adc_count   = 0;
unsigned char score1      = 0;
unsigned char score2      = 0;
unsigned char move_tick   = 0;
unsigned char expl_x, expl_y, expl_timer;
unsigned char diag1 = 0, diag2 = 0;
unsigned char shot_active[2];

bit done_sampling = 0;
bit btn1_prev     = 1;
bit btn2_prev     = 1;
bit game_over     = 0;
bit expl_active   = 0;
bit sound_on      = 0;
bit sound_state   = 0;

void play_sound(unsigned int d)
{
    sound_duration = d; sound_on = 1; sound_state = 0;
}

void timer3_isr(void) interrupt 14 using 1
{
    TMR3CN &= ~0x80;
    if (!sound_on) { DAC0H = 128; return; }
    DAC0H = sound_state ? 220 : 36;
    sound_state = !sound_state;
    if (sound_duration) sound_duration--;
    else { sound_on = 0; DAC0H = 128; }
}


void adc_isr(void) interrupt 15 using 2
{
    AD0INT = 0;
    adc_val = (ADC0H << 8) | ADC0L;
    if (AMX0SL == 0x00) { pot1_hold += adc_val; AMX0SL = 0x01; }
    else                 { pot2_hold += adc_val; AMX0SL = 0x00; }
    if (++adc_count == 64)
    {
        pot1_sample = pot1_hold / 32;
        pot2_sample = pot2_hold / 32;
        pot1_hold = pot2_hold = 0;
        adc_count = 0;
        done_sampling = 1;
    }
}

unsigned char pot_to_dir(unsigned pot)
{
    unsigned char s;
    if (pot < 200)  pot = 200;
    if (pot > 3800) pot = 3800;
    s = (unsigned char)(((unsigned long)(pot - 200) * 8) / 3601);
    return (s > 7) ? 7 : s;
}


void set_pixel(unsigned char x, unsigned char y)
{
    if (x > 127 || y > 63) return;
    screen[(unsigned int)(y >> 3) * 128 + x] |= (1 << (y & 7));
}

bit get_pixel(unsigned char x, unsigned char y)
{
    if (x > 127 || y > 63) return 0;
    return (screen[(unsigned int)(y >> 3) * 128 + x] & (1 << (y & 7))) ? 1 : 0;
}

void draw_hline(unsigned char x1, unsigned char x2, unsigned char y)
{
    unsigned char x, t;
    if (x1 > x2) { t = x1; x1 = x2; x2 = t; }
    for (x = x1; x <= x2; x++) set_pixel(x, y);
}

void draw_vline(unsigned char x, unsigned char y1, unsigned char y2)
{
    unsigned char y, t;
    if (y1 > y2) { t = y1; y1 = y2; y2 = t; }
    for (y = y1; y <= y2; y++) set_pixel(x, y);
}

void draw_layout(void)
{
    draw_hline(0,127,0);  draw_hline(0,127,63);
    draw_vline(0,0,63);   draw_vline(127,0,63);
    draw_hline(1,126,8);  draw_vline(63,1,8);
    draw_vline(16,9,22);  draw_vline(74,9,22);
    draw_vline(45,30,52); draw_vline(92,30,52);
}

void draw_layout_2(void)
{
    draw_hline(0,127,0);  draw_hline(0,127,63);
    draw_vline(0,0,63);   draw_vline(127,0,63);
    draw_hline(1,126,8);  draw_vline(63,1,8);
    draw_hline(18,54,20); draw_hline(76,116,44);
    draw_vline(30,34,56); draw_vline(98,12,34);
    draw_hline(48,82,31);
}

void draw_current_layout(void)
{
    if (field_num == 0) draw_layout(); else draw_layout_2();
}

void draw_char_5x8(unsigned char x, unsigned char y, char c)
{
    unsigned char col, row, line;
    if (c < 32 || c > 'Z') c = ' ';
    for (col = 0; col < 5; col++)
    {
        line = font5x8[(c - 32) * 5 + col];
        for (row = 0; row < 8; row++)
            if (line & (1 << row)) set_pixel(x + col, y + row);
    }
}

void draw_code_str(unsigned char x, unsigned char y, code char *s)
{
    while (*s) { draw_char_5x8(x, y, *s++); x += 6; }
}

void draw_scores(void)
{
    unsigned char i, sc;
    for (i = 0; i < 2; i++)
    {
        sc = i ? score2 : score1;
        draw_char_5x8(i ? 84 : 24, 1, (sc / 10) + '0');
        draw_char_5x8(i ? 90 : 30, 1, (sc % 10) + '0');
    }
}

/* =============================================================
   WALL BUFFER
   ============================================================= */
void clear_wall_pixel(unsigned char x, unsigned char y)
{
    if (x == 0 || x == 127 || y < 9 || y == 63) return;
    wall_screen[(unsigned int)(y >> 3) * 128 + x] &= ~(1 << (y & 7));
}

void destroy_wall(unsigned char x, unsigned char y)
{
    signed char dx, dy;
    for (dy = -2; dy <= 4; dy++)
        for (dx = -2; dx <= 4; dx++)
            clear_wall_pixel((unsigned char)(x+dx), (unsigned char)(y+dy));
}

void init_wall_screen(void)
{
    unsigned int i;
    blank_screen();
    draw_current_layout();
    for (i = 0; i < 1024; i++) wall_screen[i] = screen[i];
}

void restore_wall_screen(void)
{
    unsigned int i;
    for (i = 0; i < 1024; i++) screen[i] = wall_screen[i];
}


unsigned char draw_tank_player(unsigned char x, unsigned char y,
                                unsigned char orientation, unsigned char player)
{
    unsigned int  mask;
    unsigned char shift = y & 7;
    unsigned int  base  = (unsigned int)(y >> 3) * 128 + x;
    unsigned char hit   = 0;
    unsigned char k;

    orientation &= 0x07;
    for (k = 0; k < 9; k++)
    {
        mask = tank[orientation][k];
        if (player && k == 4) mask &= 0x00E7;
        mask <<= shift;

        hit |= screen[base + k] & (mask & 0xFF);
        screen[base + k] |= (mask & 0xFF);

        if (y <= 55)
        {
            hit |= screen[base + k + 128] & ((mask >> 8) & 0xFF);
            screen[base + k + 128] |= ((mask >> 8) & 0xFF);
        }
    }
    return hit;
}

void move_tank(unsigned char *x, unsigned char *y,
               unsigned char dir, unsigned char *diag)
{
    if (dir & 1)
    {
        if (*diag) *x = (unsigned char)(*x + move_dx[dir]);
        else       *y = (unsigned char)(*y + move_dy[dir]);
    }
    else
    {
        *x = (unsigned char)(*x + move_dx[dir]);
        *y = (unsigned char)(*y + move_dy[dir]);
    }
    *diag ^= 1;
}

void keep_in_bounds(unsigned char *x, unsigned char *y)
{
    if (*x < 1)   *x = 1;
    if (*x > 118) *x = 118;
    if (*y < 10)  *y = 10;
    if (*y > 54)  *y = 54;
}

bit tanks_overlap(unsigned char x1, unsigned char y1,
                  unsigned char x2, unsigned char y2)
{
    if (x1+8 < x2 || x2+8 < x1) return 0;
    if (y1+8 < y2 || y2+8 < y1) return 0;
    return 1;
}

/* =============================================================
   PROJECTILE
   ============================================================= */
void draw_projectile(unsigned char x, unsigned char y)
{
    unsigned char dx, dy;
    for (dy = 0; dy < 3; dy++)
        for (dx = 0; dx < 3; dx++)
            set_pixel(x+dx, y+dy);
}

void move_projectile(unsigned char *x, unsigned char *y, unsigned char dir)
{
    *x = (unsigned char)(*x + proj_dx[dir & 7]);
    *y = (unsigned char)(*y + proj_dy[dir & 7]);
}

bit proj_oob(unsigned char x, unsigned char y)
{
    return (x < 1 || x > 124 || y < 10 || y > 61) ? 1 : 0;
}

bit proj_hits_wall(unsigned char x, unsigned char y)
{
    return (get_pixel(x,y) || get_pixel(x+1,y) ||
            get_pixel(x,y+1) || get_pixel(x+1,y+1)) ? 1 : 0;
}

void draw_explosion(unsigned char x, unsigned char y, unsigned char frame)
{
    unsigned char r, max = frame + 3;
    for (r = 0; r <= max; r++)
    {
        set_pixel(x+r,y); set_pixel(x-r,y);
        set_pixel(x,y+r); set_pixel(x,y-r);
        if (r < max)
        {
            set_pixel(x+r,y+r); set_pixel(x-r,y-r);
            set_pixel(x+r,y-r); set_pixel(x-r,y+r);
        }
    }
}

unsigned char get_speed(void)
{
    unsigned char v = (unsigned char)(~P3) & 0x07;
    return (v > 4) ? 4 : v;
}


unsigned char simple_rand(void)
{
    rand_seed = rand_seed * 1103 + 12345;
    return (unsigned char)(rand_seed >> 8);
}

bit pos_safe(unsigned char x, unsigned char y,
             unsigned char ox, unsigned char oy)
{
    unsigned char k;
    unsigned int  mask;
    unsigned char shift = y & 7;
    unsigned int  base  = (unsigned int)(y >> 3) * 128 + x;

    if (x < 2 || x > 117 || y < 11 || y > 53) return 0;
    if (tanks_overlap(x, y, ox, oy)) return 0;

    for (k = 0; k < 9; k++)
    {
        mask = tank[0][k] << shift;
        if (wall_screen[base + k] & (mask & 0xFF)) return 0;
        if (y <= 55 && (wall_screen[base+k+128] & ((mask >> 8) & 0xFF))) return 0;
    }
    return 1;
}

void randomize_tanks(unsigned char *x1, unsigned char *y1, unsigned char *d1,
                     unsigned char *x2, unsigned char *y2, unsigned char *d2)
{
    unsigned char t, nx, ny;
    for (t = 0; t < 50; t++)
    {
        nx = 2 + (simple_rand() % 116);
        ny = 11 + (simple_rand() % 43);
        if (pos_safe(nx, ny, *x2, *y2)) { *x1=nx; *y1=ny; break; }
    }
    for (t = 0; t < 50; t++)
    {
        nx = 2 + (simple_rand() % 116);
        ny = 11 + (simple_rand() % 43);
        if (pos_safe(nx, ny, *x1, *y1)) { *x2=nx; *y2=ny; break; }
    }
    *d1 = simple_rand() & 7;
    *d2 = simple_rand() & 7;
    diag1 = diag2 = 0;
}


void main(void)
{
    unsigned char x1, y1, d1, x2, y2, d2;
    unsigned char ox1, oy1, ox2, oy2;
    unsigned char spd, dly, p;
    unsigned char tx, ty, *sc;
    bit do_move;

    WDTCN = 0xDE; WDTCN = 0xAD;
    XBR2 = 0x40;  XBR0 = 0x04;
    OSCXCN = 0x67;
    TMOD = 0x20; TH1 = -167; TR1 = 1;
    while (TF1 == 0) {} TF1 = 0; TR1 = 0;
    while (!(OSCXCN & 0x80)) {}
    OSCICN = 0x08;
    RCAP2H = (-1659) >> 8; RCAP2L = (-1659) & 0xFF; TR2 = 1;
    REF0CN = 0x03; AMX0CF = 0xC0; AMX0SL = 0x00;
    ADC0CF = 0x40; ADC0CN = 0x8C;
    DAC0CN = 0x80; DAC0H = 128;
    TMR3CN = 0x00;
    TMR3RLH = 0xF7; TMR3RLL = 0xCE;
    TMR3H   = 0xF7; TMR3L   = 0xCE;
    TMR3CN |= 0x04;
    IE = 0x80; EIE2 = 0x03;
    init_lcd();

reset_game:
    score1 = score2 = 0;
    shot_active[0] = shot_active[1] = 0;
    shot_time[0]   = shot_time[1]   = 0;
    expl_active = 0; expl_timer = 0;
    sound_on = 0; sound_duration = 0; DAC0H = 128;
    game_over = 0;
    x1=5; y1=40; d1=0;
    x2=110; y2=30; d2=2;
    diag1 = diag2 = move_tick = 0;
    btn1_prev = btn2_prev = 1;

    init_wall_screen();
    draw_scores();
    draw_tank_player(x1,y1,d1,0);
    draw_tank_player(x2,y2,d2,1);
    draw_code_str(48,22,str_ready);
    draw_code_str(16,34,str_press);
    draw_code_str(34,44,str_to_start);
    refresh_screen();

    while (BTN1 && BTN2)  {}
    while (!BTN1 || !BTN2) {}

    while (1)
    {
        if (game_over)
        {
            restore_wall_screen();
            draw_scores();
            draw_tank_player(x1,y1,d1,0);
            draw_tank_player(x2,y2,d2,1);
            draw_code_str(31,22,str_game_over);
            draw_code_str(16,34,str_press);
            draw_code_str(34,44,str_to_start);
            refresh_screen();
            while (BTN1 && BTN2)  {}
            while (!BTN1 || !BTN2) {}
            field_num ^= 1;
            goto reset_game;
        }

        if (!done_sampling) continue;
        done_sampling = 0;

        d1 = pot_to_dir(pot2_sample);
        d2 = pot_to_dir(pot1_sample);

        spd = get_speed();
        dly = delay_lut[(spd > 4) ? 3 : spd];
        do_move = 0;
        if (!spd) move_tick = 0;
        else if (++move_tick >= dly) { move_tick = 0; do_move = 1; }

        ox1=x1; oy1=y1; ox2=x2; oy2=y2;

        if (do_move && !expl_active)
        {
            move_tank(&x1,&y1,d1,&diag1);
            keep_in_bounds(&x1,&y1);
            restore_wall_screen();
            if (draw_tank_player(x1,y1,d1,0)) { x1=ox1; y1=oy1; }

            move_tank(&x2,&y2,d2,&diag2);
            keep_in_bounds(&x2,&y2);
            restore_wall_screen();
            if (draw_tank_player(x2,y2,d2,1)) { x2=ox2; y2=oy2; }

            if (tanks_overlap(x1,y1,x2,y2)) { x1=ox1;y1=oy1;x2=ox2;y2=oy2; }
        }

        if (!expl_active)
        {
            if (!BTN1 && btn1_prev && !shot_active[0])
            {
                shot_active[0]=1; shot_dir[0]=d1;
                shot_x[0]=x1+4;  shot_y[0]=y1+4; shot_time[0]=0;
                play_sound(80);
            }
            if (!BTN2 && btn2_prev && !shot_active[1])
            {
                shot_active[1]=1; shot_dir[1]=d2;
                shot_x[1]=x2+4;  shot_y[1]=y2+4; shot_time[1]=0;
                play_sound(80);
            }
        }
        btn1_prev = BTN1;
        btn2_prev = BTN2;

        restore_wall_screen();

        for (p = 0; p < 2; p++)
        {
            if (!shot_active[p] || expl_active) continue;
            tx = p ? x1 : x2;
            ty = p ? y1 : y2;
            sc = p ? &score2 : &score1;

            move_projectile(&shot_x[p],&shot_y[p],shot_dir[p]);
            shot_time[p]++;

            if (proj_oob(shot_x[p],shot_y[p]))
            {
                shot_active[p]=0; play_sound(25);
            }
            else if (shot_x[p]>=tx && shot_x[p]<=tx+8 &&
                     shot_y[p]>=ty && shot_y[p]<=ty+8)
            {
                shot_active[p]=0;
                expl_active=1; expl_x=tx+4; expl_y=ty+4; expl_timer=0;
                play_sound(220);
                if (*sc < 3) (*sc)++;
                if (*sc >= 3) game_over = 1;
                if (!game_over) randomize_tanks(&x1,&y1,&d1,&x2,&y2,&d2);
            }
            else if (proj_hits_wall(shot_x[p],shot_y[p]))
            {
                destroy_wall(shot_x[p],shot_y[p]);
                shot_active[p]=0; play_sound(25);
            }
            else if (shot_time[p] >= 30)
                shot_active[p]=0;
        }

        restore_wall_screen();
        draw_scores();
        draw_tank_player(x1,y1,d1,0);
        draw_tank_player(x2,y2,d2,1);
        for (p = 0; p < 2; p++)
            if (shot_active[p]) draw_projectile(shot_x[p],shot_y[p]);
        if (expl_active)
        {
            draw_explosion(expl_x,expl_y,expl_timer);
            if (++expl_timer > 12) expl_active = 0;
        }
        refresh_screen();
    }
}

