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


typedef struct {
    //Video
    unsigned char aspect_ratio;
    unsigned char screen_mode;
    unsigned char filtering;
    unsigned char show_fps;
    unsigned char video_filter;
    unsigned char video_filter_strength;
    float brightness;
    
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
    int vpad_pad_x,vpad_pad_y;
    int vpad_buttons_x,vpad_buttons_y;
    
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
