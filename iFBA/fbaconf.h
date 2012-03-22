//
//  fbaconf.h
//  iFBA
//
//  Created by Yohann Magnien on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef iFBA_fbaconf_h
#define iFBA_fbaconf_h

#define MAX_JOYSTICKS 4
#define VPAD_SPECIALS_BUTTON_NB 5
#define VSTICK_NB_BUTTON 11

#define MAX_LANG 2
extern char iCade_langStr[MAX_LANG][32];


typedef struct {
    //rom browser
    unsigned int filter_genre;
    unsigned char filter_type;
    unsigned char filter_missing;
    //Video
    unsigned char aspect_ratio;
    unsigned char screen_mode;
    unsigned char filtering;
    unsigned char show_fps;
    unsigned char video_filter;
    unsigned char video_filter_strength;
    unsigned char video_60hz;
    float brightness;
    unsigned char video_fskip;
    
    //Audio
    unsigned char sound_on;
    unsigned int sound_freq;
    unsigned char sound_latency;
    
    //Controls
    unsigned char vpad_alpha;
    unsigned char vpad_showSpecial;
    unsigned char vpad_btnsize;
    unsigned char vpad_padsize;
    unsigned char btstack_on;
    unsigned char vpad_style;
    int vpad_pad_x,vpad_pad_y;
    int vpad_button_x,vpad_button_y;
    unsigned char icade_lang;
    
    //Emulation
    unsigned char asm_68k;
    unsigned char asm_z80;
    unsigned char asm_nec;
    unsigned char asm_sh2;    
    
    //Extension
    unsigned char extension[64];
} ifba_conf_t;

extern ifba_conf_t ifba_conf;

typedef struct {
    char btn_name[16];
    unsigned char dev_btn;
} t_button_map;

extern t_button_map joymap_iCade[VSTICK_NB_BUTTON];

extern t_button_map joymap_wiimote[MAX_JOYSTICKS][VSTICK_NB_BUTTON];

#endif
