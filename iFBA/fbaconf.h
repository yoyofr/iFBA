//
//  fbaconf.h
//  iFBA
//
//  Created by Yohann Magnien on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef iFBA_fbaconf_h
#define iFBA_fbaconf_h

#define iFBA_VERSION_MAJOR 0
#define iFBA_VERSION_MINOR 6

#define REPLAY_FLAG_TOUCHONOFF (1<<0)
#define REPLAY_FLAG_POSX (1<<1)
#define REPLAY_FLAG_POSY (1<<2)
#define REPLAY_FLAG_IN0 (1<<3)
#define REPLAY_FLAG_IN1 (1<<4)
#define REPLAY_FLAG_IN2 (1<<5)
#define REPLAY_FLAG_IN3 (1<<6)
#define REPLAY_RECORD_MODE 1
#define REPLAY_PLAYBACK_MODE 2
#define MAX_REPLAY_DATA_BYTES 1024*1024

#define MAX_JOYSTICKS 4
#define VPAD_SPECIALS_BUTTON_NB 5
#define VSTICK_NB_BUTTON 11

#define MAX_LANG 2
extern char iCade_langStr[MAX_LANG][32];

//replay
typedef struct {
    unsigned int drvinput[2];
    unsigned int patch_memX,patch_memY;
} t_replay_data;


typedef struct {
    char btn_name[16];
    unsigned char dev_btn;
} t_button_map;

typedef struct {
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
    float vpad_analog_speed[MAX_JOYSTICKS][4];  //4 axis
    unsigned char vpad_alpha;
    unsigned char vpad_showSpecial;
    unsigned char vpad_btnsize;
    unsigned char vpad_padsize;
    unsigned char vpad_style;
    unsigned char vpad_followfinger;
    float vpad_pad_x[2],vpad_pad_y[2];
    int vpad_pad_manual_layout[2];
    float vpad_button_x[VSTICK_NB_BUTTON][2],vpad_button_y[VSTICK_NB_BUTTON][2];
    int vpad_button_manual_layout[VSTICK_NB_BUTTON][2];
    t_button_map joymap_iCade[VSTICK_NB_BUTTON];
    t_button_map joymap_wiimote[MAX_JOYSTICKS][VSTICK_NB_BUTTON];
    
    
    //Emulation
    unsigned char asm_68k;
    unsigned char asm_z80;
    unsigned char asm_nec;
    unsigned char asm_sh2;        
    
    //rom browser
    unsigned int filter_genre;
    unsigned char filter_type;
    unsigned char filter_missing;
    //global settings
    unsigned char btstack_on;
    unsigned char icade_lang;
    
} ifba_conf_t;

typedef struct {
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
    float vpad_analog_speed[MAX_JOYSTICKS][4];  //4 axis
    unsigned char vpad_alpha;
    unsigned char vpad_showSpecial;
    unsigned char vpad_btnsize;
    unsigned char vpad_padsize;
    unsigned char vpad_style;
    unsigned char vpad_followfinger;
    float vpad_pad_x[2],vpad_pad_y[2];
    int vpad_pad_manual_layout[2];
    float vpad_button_x[VSTICK_NB_BUTTON][2],vpad_button_y[VSTICK_NB_BUTTON][2];
    int vpad_button_manual_layout[VSTICK_NB_BUTTON][2];
    t_button_map joymap_iCade[VSTICK_NB_BUTTON];
    t_button_map joymap_wiimote[MAX_JOYSTICKS][VSTICK_NB_BUTTON];
    
    //Emulation
    unsigned char asm_68k;
    unsigned char asm_z80;
    unsigned char asm_nec;
    unsigned char asm_sh2;        
} ifba_game_conf_t;

extern ifba_game_conf_t *cur_ifba_conf;
extern ifba_conf_t ifba_conf;
extern ifba_game_conf_t ifba_game_conf;
extern int game_has_options;

extern t_button_map default_joymap_iCade[VSTICK_NB_BUTTON];
extern t_button_map default_joymap_wiimote[MAX_JOYSTICKS][VSTICK_NB_BUTTON];


#ifndef EMUVIEWCONTROLLER

extern int glob_mov_init,glob_touchpad_cnt,glob_ffingeron;
extern float glob_pos_x,glob_pos_y,glob_pos_xi,glob_pos_yi;
extern int glob_touchpad_fingerid;
extern int glob_touchpad_hack;
extern float glob_scr_ratioX,glob_scr_ratioY;


//follow finger
extern void PatchMemory68KFFinger();
extern float glob_mov_x,glob_mov_y;
extern float glob_pos_x,glob_pos_y;
extern int glob_shootmode,glob_shooton,glob_autofirecpt,glob_ffingeron;
extern int wait_control;
//replay
extern unsigned char glob_replay_data_stream[MAX_REPLAY_DATA_BYTES];
extern unsigned int glob_framecpt,glob_replay_mode,glob_framecpt_max,glob_replay_data_index,glob_replay_data_index_max;
extern unsigned char glob_replay_flag;
extern unsigned int glob_replay_last_dx16,glob_replay_last_dy16;
extern unsigned char glob_replay_last_fingerOn;
//
extern unsigned int last_DrvInput[10];
//
extern int nShouldExit;
//
#endif

#endif
