/*
 * Snes9x - Portable Super Nintendo Entertainment System (TM) emulator.
 *
 * (c) Copyright 1996 - 2001 Gary Henderson (gary.henderson@ntlworld.com) and
 *                           Jerremy Koot (jkoot@snes9x.com)
 *
 * Super FX C emulator code 
 * (c) Copyright 1997 - 1999 Ivar (ivar@snes9x.com) and
 *                           Gary Henderson.
 * Super FX assembler emulator code (c) Copyright 1998 zsKnight and _Demo_.
 *
 * DSP1 emulator code (c) Copyright 1998 Ivar, _Demo_ and Gary Henderson.
 * C4 asm and some C emulation code (c) Copyright 2000 zsKnight and _Demo_.
 * C4 C code (c) Copyright 2001 Gary Henderson (gary.henderson@ntlworld.com).
 *
 * DOS port code contains the works of other authors. See headers in
 * individual files.
 *
 * Snes9x homepage: http://www.snes9x.com
 *
 * Permission to use, copy, modify and distribute Snes9x in both binary and
 * source form, for non-commercial purposes, is hereby granted without fee,
 * providing that this license information and copyright notice appear with
 * all copies and any derived work.
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event shall the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Snes9x is freeware for PERSONAL USE only. Commercial users should
 * seek permission of the copyright holders first. Commercial use includes
 * charging money for Snes9x or software derived from Snes9x.
 *
 * The copyright holders request that bug fixes and improvements to the code
 * should be forwarded to them so everyone can benefit from the modifications
 * in future versions.
 *
 * Super NES and Super Nintendo Entertainment System are trademarks of
 * Nintendo Co., Limited and its subsidiary companies.
 */

#include <string.h>
#include "sdl_font.h"

static char *font[] = {
    "           .      . .                    .                ..       .      .                                                     ",
    "          .#.    .#.#.    . .     ...   .#. .     .      .##.     .#.    .#.     . .       .                                .   ",
    "          .#.    .#.#.   .#.#.   .###.  .#..#.   .#.     .#.     .#.      .#.   .#.#.     .#.                              .#.  ",
    "          .#.    .#.#.  .#####. .#.#.    ..#.   .#.#.   .#.      .#.      .#.    .#.     ..#..           ....             .#.   ",
    "          .#.     . .    .#.#.   .###.   .#..    .#.     .       .#.      .#.   .###.   .#####.   ..    .####.    ..     .#.    ",
    "           .            .#####.   .#.#. .#..#.  .#.#.            .#.      .#.    .#.     ..#..   .##.    ....    .##.   .#.     ",
    "          .#.            .#.#.   .###.   . .#.   .#.#.            .#.    .#.    .#.#.     .#.    .#.             .##.    .      ",
    "           .              . .     ...       .     . .              .      .      . .       .    .#.               ..            ",
    "                                                                                                 .                              ",
    "  .       .       ..     ....      .     ....     ..     ....     ..      ..                                              .     ",
    " .#.     .#.     .##.   .####.    .#.   .####.   .##.   .####.   .##.    .##.     ..      ..       .             .       .#.    ",
    ".#.#.   .##.    .#..#.   ...#.   .##.   .#...   .#..     ...#.  .#..#.  .#..#.   .##.    .##.     .#.    ....   .#.     .#.#.   ",
    ".#.#.    .#.     . .#.   .##.   .#.#.   .###.   .###.     .#.    .##.   .#..#.   .##.    .##.    .#.    .####.   .#.     ..#.   ",
    ".#.#.    .#.      .#.    ...#.  .####.   ...#.  .#..#.    .#.   .#..#.   .###.    ..      ..    .#.      ....     .#.    .#.    ",
    ".#.#.    .#.     .#..   .#..#.   ..#.   .#..#.  .#..#.   .#.    .#..#.    ..#.   .##.    .##.    .#.    .####.   .#.      .     ",
    " .#.    .###.   .####.   .##.     .#.    .##.    .##.    .#.     .##.    .##.    .##.    .#.      .#.    ....   .#.      .#.    ",
    "  .      ...     ....     ..       .      ..      ..      .       ..      ..      ..    .#.        .             .        .     ",
    "                                                                                         .                                      ",
    "  ..      ..     ...      ..     ...     ....    ....     ..     .  .    ...        .    .  .    .       .   .   .   .    ..    ",
    " .##.    .##.   .###.    .##.   .###.   .####.  .####.   .##.   .#..#.  .###.      .#.  .#..#.  .#.     .#. .#. .#. .#.  .##.   ",
    ".#..#.  .#..#.  .#..#.  .#..#.  .#..#.  .#...   .#...   .#..#.  .#..#.   .#.       .#.  .#.#.   .#.     .##.##. .##..#. .#..#.  ",
    ".#.##.  .#..#.  .###.   .#. .   .#..#.  .###.   .###.   .#...   .####.   .#.       .#.  .##.    .#.     .#.#.#. .#.#.#. .#..#.  ",
    ".#.##.  .####.  .#..#.  .#. .   .#..#.  .#..    .#..    .#.##.  .#..#.   .#.     . .#.  .##.    .#.     .#...#. .#.#.#. .#..#.  ",
    ".#...   .#..#.  .#..#.  .#..#.  .#..#.  .#...   .#.     .#..#.  .#..#.   .#.    .#..#.  .#.#.   .#...   .#. .#. .#..##. .#..#.  ",
    " .##.   .#..#.  .###.    .##.   .###.   .####.  .#.      .###.  .#..#.  .###.    .##.   .#..#.  .####.  .#. .#. .#. .#.  .##.   ",
    "  ..     .  .    ...      ..     ...     ....    .        ...    .  .    ...      ..     .  .    ....    .   .   .   .    ..    ",
    "                                                                                                                                ",
    " ...      ..     ...      ..     ...     .   .   .   .   .   .   .  .    . .     ....    ...             ...      .             ",
    ".###.    .##.   .###.    .##.   .###.   .#. .#. .#. .#. .#. .#. .#..#.  .#.#.   .####.  .###.    .      .###.    .#.            ",
    ".#..#.  .#..#.  .#..#.  .#..#.   .#.    .#. .#. .#. .#. .#...#. .#..#.  .#.#.    ...#.  .#..    .#.      ..#.   .#.#.           ",
    ".#..#.  .#..#.  .#..#.   .#..    .#.    .#. .#. .#. .#. .#.#.#.  .##.   .#.#.     .#.   .#.      .#.      .#.    . .            ",
    ".###.   .#..#.  .###.    ..#.    .#.    .#. .#. .#. .#. .#.#.#. .#..#.   .#.     .#.    .#.       .#.     .#.                   ",
    ".#..    .##.#.  .#.#.   .#..#.   .#.    .#...#.  .#.#.  .##.##. .#..#.   .#.    .#...   .#..       .#.   ..#.            ....   ",
    ".#.      .##.   .#..#.   .##.    .#.     .###.    .#.   .#. .#. .#..#.   .#.    .####.  .###.       .   .###.           .####.  ",
    " .        ..#.   .  .     ..      .       ...      .     .   .   .  .     .      ....    ...             ...             ....   ",
    "            .                                                                                                                   ",
    " ..              .                  .              .             .        .        .     .       ..                             ",
    ".##.            .#.                .#.            .#.           .#.      .#.      .#.   .#.     .##.                            ",
    " .#.      ...   .#..      ..      ..#.    ..     .#.#.    ...   .#..     ..        .    .#..     .#.     .. ..   ...      ..    ",
    "  .#.    .###.  .###.    .##.    .###.   .##.    .#..    .###.  .###.   .##.      .#.   .#.#.    .#.    .##.##. .###.    .##.   ",
    "   .    .#..#.  .#..#.  .#..    .#..#.  .#.##.  .###.   .#..#.  .#..#.   .#.      .#.   .##.     .#.    .#.#.#. .#..#.  .#..#.  ",
    "        .#.##.  .#..#.  .#..    .#..#.  .##..    .#.     .##.   .#..#.   .#.     ..#.   .#.#.    .#.    .#...#. .#..#.  .#..#.  ",
    "         .#.#.  .###.    .##.    .###.   .##.    .#.    .#...   .#..#.  .###.   .#.#.   .#..#.  .###.   .#. .#. .#..#.   .##.   ",
    "          . .    ...      ..      ...     ..      .      .###.   .  .    ...     .#.     .  .    ...     .   .   .  .     ..    ",
    "                                                          ...                     .                                             ",
    "                                  .                                                        .      .      .        . .           ",
    "                                 .#.                                                      .#.    .#.    .#.      .#.#.          ",
    " ...      ...    ...      ...    .#.     .  .    . .     .   .   .  .    .  .    ....    .#.     .#.     .#.    .#.#.           ",
    ".###.    .###.  .###.    .###.  .###.   .#..#.  .#.#.   .#...#. .#..#.  .#..#.  .####.  .##.     .#.     .##.    . .            ",
    ".#..#.  .#..#.  .#..#.  .##..    .#.    .#..#.  .#.#.   .#.#.#.  .##.   .#..#.   ..#.    .#.     .#.     .#.                    ",
    ".#..#.  .#..#.  .#. .    ..##.   .#..   .#..#.  .#.#.   .#.#.#.  .##.    .#.#.   .#..    .#.     .#.     .#.                    ",
    ".###.    .###.  .#.     .###.     .##.   .###.   .#.     .#.#.  .#..#.    .#.   .####.    .#.    .#.    .#.                     ",
    ".#..      ..#.   .       ...       ..     ...     .       . .    .  .    .#.     ....      .      .      .                      ",
    " .          .                                                             .                                                     ",
};

static int font_width = 8;
static int font_height = 9;

void DisplayChar (uint16 *Screen, uint8 c, uint16 resW,int rotated)
{
	int line = (((c & 0x7f) - 32) >> 4) * font_height;
	int offset = (((c & 0x7f) - 32) & 15) * font_width;
    
	int h, w;
	uint16 *s = (uint16 *) Screen;
    
    if (rotated) {
        s+=font_width-1;
        for (h = 0; h < font_height; h++, line++,
             s += -1-resW*font_width/*resW - font_width*/)
        {
            for (w = 0; w < font_width; w++, s+=resW)
            {
                uint8 p = font [line][offset + w];
                
                if (p == '#')
                    *s = 0xffff;
                else
                    if (p == '.')
                        *s = 0x0000;//BLACK;
            }
        }
    } else {
        for (h = 0; h < font_height; h++, line++,
             s += resW - font_width)
        {
            for (w = 0; w < font_width; w++, s++)
            {
                uint8 p = font [line][offset + w];
                
                if (p == '#')
                    *s = 0xffff;
                else
                    if (p == '.')
                        *s = 0x0000;//BLACK;
            }
        }
    }
}

void DrawString (const char *string, uint16 *screen, uint8 x, uint8 y, uint16 resW,int rotated) {
	uint16 *Screen = screen + 2 + x + y * resW;
	int len = strlen (string);//,50);
	int max_chars = resW / (font_width - 2);
	int char_count = 0;
	int i;	
//	if (len > 47) len = 47;
	
    if (rotated) {
        Screen = screen + (resW-x-font_height) + y * resW;
        for (i = 0; i < len; i++, char_count++)
        {
            if (char_count >= max_chars || string [i] < 32)
            {
                Screen -= (font_width - 1) * max_chars;
                Screen += font_height * resW/*pitch*/;
                if (Screen >= screen + resW/*pitch*/ * 240)
                    break;
                char_count -= max_chars;
            }
            if (string [i] < 32)
                continue;
            DisplayChar (Screen, string [i], resW,1);
            Screen += (font_width - 2)*resW;// * sizeof (uint16); 
        }     
    } else {
        for (i = 0; i < len; i++)
        {
            if (char_count >= max_chars || string [i] < 32)
            {
                Screen -= (font_width - 2) * char_count;
                char_count =0;//-= max_chars;
                Screen += font_height * resW/*pitch*/;
                if (Screen >= screen + resW/*pitch*/ * 240)
                    break;
                
            }
            if (string [i] < 32)
                continue;
            DisplayChar (Screen, string [i], resW,0);
            Screen += (font_width - 2);// * sizeof (uint16); 
            char_count++;
        }
    }
}

void DrawRect ( uint16 *screen, int x, int y, int w, int h, int c , uint16 resW,int rotated) {
	uint16 cc = (c & 0x00F80000) >> 8 | (c & 0x0000F800) >> 5 | (c & 0x000000F8) >> 3;
	uint16 *Screen = screen + x + y * resW;
	uint16 * ss;    
	int ww, hh = h;
    if (rotated) {
        Screen = screen + (resW-x-h) + y * resW;
        while ( --w > 0) {
            hh = h;
            ss = Screen;
            Screen += resW;
            while ( --hh > 0) {
                *ss = cc;
                ss++;
            }
        }
        
    } else {
        while ( --hh > 0) {
            ww = w;
            ss = Screen;
            Screen += resW;
            while ( --ww > 0) {
                *ss = cc;
                ss++;
            }
        }
    }
}


