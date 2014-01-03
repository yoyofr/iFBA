//
//  EmuViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define min(a,b) (a<b?a:b)

#ifdef TESTFLIGHT_BUILD
#include "TestFlight.h"
#endif

#define EMUVIEWCONTROLLER
#import "fbaconf.h"
#include "DBHelper.h"

//hack
extern char debug_root_path[512];

extern signed int nBurnFPS; //100*FPS

volatile float glob_mov_x,glob_mov_y;
volatile float glob_pos_x,glob_pos_y,glob_pos_xi,glob_pos_yi;
volatile int glob_mov_init,glob_touchpad_cnt=0,glob_ffingeron=0;
volatile int glob_touchpad_fingerid=0;
volatile int glob_shootmode=0,glob_shooton=0,glob_autofirecpt;
volatile int glob_touchpad_hack;
volatile int glob_buttons_limit;
volatile float glob_scr_ratioX=1,glob_scr_ratioY=1;
int wait_control;

volatile float mScaleFactor;
volatile int mDeviceType,mDevice_ww,mDevice_hh;



int LoadReplay(int slot);
int SaveReplay(int slot);
volatile unsigned char glob_replay_data_stream[MAX_REPLAY_DATA_BYTES];
volatile unsigned int glob_framecpt,glob_replay_mode,glob_framecpt_max,glob_replay_data_index,glob_replay_data_index_max;
unsigned char glob_replay_flag;
unsigned int glob_replay_last_dx16,glob_replay_last_dy16,glob_delta_dy16;
unsigned char glob_replay_last_fingerOn;
volatile int glob_replay_currentslot;
unsigned int last_DrvInput[10];
//

long long playtime,playtime_lastclock;
int playtime_upd=0;

ifba_conf_t *cur_ifba_conf;
ifba_conf_t ifba_conf;
ifba_conf_t ifba_game_conf;
int optionScope; //0:default, 1:current game
int game_has_options;

extern UIScreen *cur_screen;

volatile int doFrame_inProgress=0;

#include "inp_sdl_keys.h"
unsigned char joy_state[MAX_JOYSTICKS][GN_MAX_KEY];

#import "EmuViewController.h"
#include "string.h"
#include "sdl_font.h"

#import "BTstack/BTDevice.h"
#import "BTstack/btstack.h"
#import "BTstack/run_loop.h"
#import "BTstack/hci_cmds.h"
#import "BTstack/wiimote.h"
static BTDevice *device;
static uint16_t wiiMoteConHandle = 0;
void startWiimoteDetection(void);
void stopWiimoteDetection(void);

int iOS_wiiDeadZoneValue=1;
int iOS_inGame;
int iOS_waysStick=8;
float joy_analog_x[MAX_JOYSTICKS];
float joy_analog_y[MAX_JOYSTICKS];
float joy_analog_z[MAX_JOYSTICKS];
float joy_analog_l[MAX_JOYSTICKS];
float joy_analog_r[MAX_JOYSTICKS];
int wm_joy_pl[MAX_JOYSTICKS];
int wm_prev_joy_pl[MAX_JOYSTICKS];
float patch_analog_x[MAX_JOYSTICKS];
float patch_analog_y[MAX_JOYSTICKS];

t_button_map default_joymap_iCade[MAX_JOYSTICKS][VSTICK_NB_BUTTON]={
    {{"Start",7},
        {"Select/Coin",8},
        {"Menu",0},
        {"Turbo",0},
        {"Service",0},
        {"Fire 1",1},
        {"Fire 2",3},
        {"Fire 3",5},
        {"Fire 4",2},
        {"Fire 5",4},
        {"Fire 6",6}},
    {{"Start",7},
        {"Select/Coin",8},
        {"Menu",0},
        {"Turbo",0},
        {"Service",0},
        {"Fire 1",1},
        {"Fire 2",3},
        {"Fire 3",5},
        {"Fire 4",2},
        {"Fire 5",4},
        {"Fire 6",6}},
    {{"Start",7},
        {"Select/Coin",8},
        {"Menu",0},
        {"Turbo",0},
        {"Service",0},
        {"Fire 1",1},
        {"Fire 2",3},
        {"Fire 3",5},
        {"Fire 4",2},
        {"Fire 5",4},
        {"Fire 6",6}},
    {{"Start",7},
        {"Select/Coin",8},
        {"Menu",0},
        {"Turbo",0},
        {"Service",0},
        {"Fire 1",1},
        {"Fire 2",3},
        {"Fire 3",5},
        {"Fire 4",2},
        {"Fire 5",4},
        {"Fire 6",6}}
};

int joymap_dir_iCade[MAX_JOYSTICKS][8];

// Wiimote: 1,2,+,-,A,B and home => 6+1 buttons
// Wiimote classic: A,B,X,Y,LT,RT,L,R,+,- and home => 8+1 buttons
// Order  Wiimote Classic  Emu
//  1        +      +      Start
//  2        -      -      Select/Coin
//  3      home    home    Menu
//  4        /      L      Turbo
//  5        1      Y      Fire 1
//  6        2      X      Fire 2
//  7        A      B      Fire 3
//  8        B      A      Fire 4
//  9        /      LT     Fire 5
// 10        /      RT     Fire 6

t_button_map default_joymap_wiimote[MAX_JOYSTICKS][VSTICK_NB_BUTTON]={
    {{"Start",WII_BUTTON_START},
        {"Select/Coin",WII_BUTTON_SELECT},
        {"Menu",WII_BUTTON_HOME},
        {"Turbo",WII_BUTTON_G},
        {"Service",WII_BUTTON_H},
        {"Fire 1",WII_BUTTON_A},
        {"Fire 2",WII_BUTTON_B},
        {"Fire 3",WII_BUTTON_C},
        {"Fire 4",WII_BUTTON_D},
        {"Fire 5",WII_BUTTON_E},
        {"Fire 6",WII_BUTTON_F}},
    {{"Start",WII_BUTTON_START},
        {"Select/Coin",WII_BUTTON_SELECT},
        {"Menu",WII_BUTTON_HOME},
        {"Turbo",WII_BUTTON_G},
        {"Service",WII_BUTTON_H},
        {"Fire 1",WII_BUTTON_A},
        {"Fire 2",WII_BUTTON_B},
        {"Fire 3",WII_BUTTON_C},
        {"Fire 4",WII_BUTTON_D},
        {"Fire 5",WII_BUTTON_E},
        {"Fire 6",WII_BUTTON_F}},
    {{"Start",WII_BUTTON_START},
        {"Select/Coin",WII_BUTTON_SELECT},
        {"Menu",WII_BUTTON_HOME},
        {"Turbo",WII_BUTTON_G},
        {"Service",WII_BUTTON_H},
        {"Fire 1",WII_BUTTON_A},
        {"Fire 2",WII_BUTTON_B},
        {"Fire 3",WII_BUTTON_C},
        {"Fire 4",WII_BUTTON_D},
        {"Fire 5",WII_BUTTON_E},
        {"Fire 6",WII_BUTTON_F}},
    {{"Start",WII_BUTTON_START},
        {"Select/Coin",WII_BUTTON_SELECT},
        {"Menu",WII_BUTTON_HOME},
        {"Turbo",WII_BUTTON_G},
        {"Service",WII_BUTTON_H},
        {"Fire 1",WII_BUTTON_A},
        {"Fire 2",WII_BUTTON_B},
        {"Fire 3",WII_BUTTON_C},
        {"Fire 4",WII_BUTTON_D},
        {"Fire 5",WII_BUTTON_E},
        {"Fire 6",WII_BUTTON_F}},
};
int joymap_dir_wiimote[MAX_JOYSTICKS][VSTICK_NB_BUTTON];



extern int fba_main( int argc, char **argv );
extern bool bAppDoFast;

void updateVbuffer(unsigned short *buff,int w,int h,int pitch);

static unsigned short *vbuffer;
int visible_area_w,visible_area_h;
static int vid_rotated,vid_aspectX,vid_aspectY;
int nShouldExit;
static GLuint txt_vbuffer;
static volatile float pb_value;
static volatile int pb_total;
static char pb_msg[256];

volatile int renderVPADonly;


int device_isIpad,device_retina;
unsigned int virtual_stick_buttons_alpha=75;
unsigned int virtual_stick_buttons_alpha2=150;
int virtual_stick_on;
long virtual_stick_padfinger;

int device_orientation;

int virtual_stick_pad;
int virtual_stick_posx_ofs,virtual_stick_posy_ofs;
int virtual_stick_maxdist=90;
int virtual_stick_mindist=16;
int virtual_stick_maxdist2=90*90;
int virtual_stick_mindist2=10*10;
volatile int vpad_button_nb=VPAD_SPECIALS_BUTTON_NB;
int vpad_button_nb_save;
float virtual_stick_angle;
typedef struct {int button_id,w,h,sw,sh;unsigned char r,g,b;long finger_id;} t_touch_area;
t_touch_area virtual_stick[VSTICK_NB_BUTTON];

void resetPadLayouts() {
    UIInterfaceOrientation cur_or=[[UIApplication sharedApplication] statusBarOrientation];
    if ((cur_or==UIInterfaceOrientationLandscapeLeft)||(cur_or==UIInterfaceOrientationLandscapeRight)) device_orientation=1;
    else device_orientation=0;
    
    if (vpad_button_nb) {
        for (int i=VPAD_SPECIALS_BUTTON_NB;i<vpad_button_nb;i++) {
            cur_ifba_conf->vpad_button_manual_layout[i][device_orientation]=0;
            //                cur_ifba_conf->vpad_button_manual_layout[i][1]=0;
        }
    } else {
        for (int i=VPAD_SPECIALS_BUTTON_NB;i<VSTICK_NB_BUTTON;i++) {
            cur_ifba_conf->vpad_button_manual_layout[i][device_orientation]=0;
            //                cur_ifba_conf->vpad_button_manual_layout[i][1]=0;
        }
    }
    
}

void computePadLayouts(int nb_button){
    int w;
    int h;
    int btnsize=(device_isIpad?64:48);
    switch (cur_ifba_conf->vpad_btnsize) {
        case 0:btnsize>>=1;break;
        case 1:break;
        case 2:btnsize<<=1;break;
    }
    
    ///////////////////////////
    //PAD
    ///////////////////////////
    if (cur_ifba_conf->vpad_pad_manual_layout[0]==0){
        if (device_isIpad) {
            cur_ifba_conf->vpad_pad_x[0] = virtual_stick_maxdist;
            cur_ifba_conf->vpad_pad_y[0] = mDevice_hh-virtual_stick_maxdist-80;
        } else {
            cur_ifba_conf->vpad_pad_x[0] = virtual_stick_maxdist;
            cur_ifba_conf->vpad_pad_y[0] = mDevice_hh-virtual_stick_maxdist-0;
        }
    }
    if (cur_ifba_conf->vpad_pad_manual_layout[1]==0){
        if (device_isIpad) {
            cur_ifba_conf->vpad_pad_x[1] = virtual_stick_maxdist+40;
            cur_ifba_conf->vpad_pad_y[1] = mDevice_ww-virtual_stick_maxdist-40;
        } else {
            cur_ifba_conf->vpad_pad_x[1] = virtual_stick_maxdist;
            cur_ifba_conf->vpad_pad_y[1] = mDevice_ww-virtual_stick_maxdist;
            
        }
    }
    
    ///////////////////////////
    //SPECIAL BUTTONS
    ///////////////////////////
    for (int i=0;i<5;i++) {
        virtual_stick[i].r=0xFF;virtual_stick[i].g=0xFF;virtual_stick[i].b=0xFF;
    }
    virtual_stick[0].button_id=GN_START;
    virtual_stick[1].button_id=GN_SELECT_COIN;
    virtual_stick[2].button_id=GN_MENU_KEY;
    virtual_stick[3].button_id=GN_TURBO;
    virtual_stick[4].button_id=GN_SERVICE;
    
    virtual_stick[5].button_id=GN_A;
    virtual_stick[6].button_id=GN_B;
    virtual_stick[7].button_id=GN_C;
    virtual_stick[8].button_id=GN_D;
    virtual_stick[9].button_id=GN_E;
    virtual_stick[10].button_id=GN_F;
    
    
    if (device_isIpad) {
        for (int i=0;i<5;i++) {
            virtual_stick[i].w=64;virtual_stick[i].h=64;
            virtual_stick[i].sw=64;virtual_stick[i].sh=32;
        }
        
        cur_ifba_conf->vpad_button_x[0][0]=mDevice_ww-64;
        cur_ifba_conf->vpad_button_y[0][0]=0;
        cur_ifba_conf->vpad_button_x[1][0]=mDevice_ww-64-96;
        cur_ifba_conf->vpad_button_y[1][0]=0;
        cur_ifba_conf->vpad_button_x[2][0]=0;
        cur_ifba_conf->vpad_button_y[2][0]=0;
        cur_ifba_conf->vpad_button_x[3][0]=96;
        cur_ifba_conf->vpad_button_y[3][0]=0;
        cur_ifba_conf->vpad_button_x[4][0]=mDevice_ww/2-32;
        cur_ifba_conf->vpad_button_y[4][0]=0;
        
        cur_ifba_conf->vpad_button_x[0][1]=mDevice_hh-64;
        cur_ifba_conf->vpad_button_y[0][1]=0;
        cur_ifba_conf->vpad_button_x[1][1]=mDevice_hh-64;
        cur_ifba_conf->vpad_button_y[1][1]=100;
        cur_ifba_conf->vpad_button_x[2][1]=0;
        cur_ifba_conf->vpad_button_y[2][1]=0;
        cur_ifba_conf->vpad_button_x[3][1]=0;
        cur_ifba_conf->vpad_button_y[3][1]=100;
        cur_ifba_conf->vpad_button_x[4][1]=mDevice_hh/2-32;
        cur_ifba_conf->vpad_button_y[4][1]=0;
    } else {
        for (int i=0;i<5;i++) {
            virtual_stick[i].w=48;virtual_stick[i].h=48;
            virtual_stick[i].sw=48;virtual_stick[i].sh=24;
        }
        
        
        cur_ifba_conf->vpad_button_x[0][0]=mDevice_ww-48;
        cur_ifba_conf->vpad_button_y[0][0]=0;
        cur_ifba_conf->vpad_button_x[1][0]=mDevice_ww-48-64;
        cur_ifba_conf->vpad_button_y[1][0]=0;
        cur_ifba_conf->vpad_button_x[2][0]=0;
        cur_ifba_conf->vpad_button_y[2][0]=0;
        cur_ifba_conf->vpad_button_x[3][0]=64;
        cur_ifba_conf->vpad_button_y[3][0]=0;
        cur_ifba_conf->vpad_button_x[4][0]=mDevice_ww/2-24;
        cur_ifba_conf->vpad_button_y[4][0]=0;
        
        cur_ifba_conf->vpad_button_x[0][1]=mDevice_hh-48;
        cur_ifba_conf->vpad_button_y[0][1]=0;
        cur_ifba_conf->vpad_button_x[1][1]=mDevice_hh-48;
        cur_ifba_conf->vpad_button_y[1][1]=48;
        cur_ifba_conf->vpad_button_x[2][1]=0;
        cur_ifba_conf->vpad_button_y[2][1]=0;
        cur_ifba_conf->vpad_button_x[3][1]=0;
        cur_ifba_conf->vpad_button_y[3][1]=48;
        cur_ifba_conf->vpad_button_x[4][1]=mDevice_hh/2-24;
        cur_ifba_conf->vpad_button_y[4][1]=0;
    }
    
    
    ///////////////////////////
    //FIRE BUTTONS
    ///////////////////////////
    
    for (int i=0;i<nb_button;i++) {
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].r=0xDF;
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].g=0xDF;
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].b=0xDF;
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].w=btnsize*1.3f;  //touch area is 30% larger than drawing one
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].sw=btnsize;
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].h=btnsize*1.3f;  //touch area is 30% larger than drawing one
        virtual_stick[VPAD_SPECIALS_BUTTON_NB+i].sh=btnsize;
    }
    
#define SET_BUTTON_LAYOUT(a,o,px,py) \
if (cur_ifba_conf->vpad_button_manual_layout[a][o]==0) { \
cur_ifba_conf->vpad_button_x[a][o]=px; cur_ifba_conf->vpad_button_y[a][o]=py; \
}
    
    
    if (device_isIpad) {
        w=mDevice_ww;
        h=mDevice_hh-40;
    } else {
        w=mDevice_ww;
        h=mDevice_hh;
    }
    w-=10;
    h-=10; //dirty hack to compensate the +30% touch area size
    
    if (cur_ifba_conf->vpad_followfinger && glob_ffingeron) { //follow finger mode
        switch (nb_button) { //verti
            case 0:
                break;
            case 1:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,0, w-btnsize, h-btnsize)
                break;
            case 2:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,0, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,0, w-btnsize, h-btnsize)
                break;
            case 3:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,0, w-btnsize, h-btnsize*3.15f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,0, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,0, w-btnsize, h-btnsize)
                break;
            case 4:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,0, w-btnsize, h-btnsize*3.15f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,0, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,0, w-btnsize, h-btnsize)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+3,0, w-btnsize*2.1f, h-btnsize)
                break;
            case 5:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,0, w-btnsize, h-btnsize*3.15f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,0, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,0, w-btnsize, h-btnsize)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+3,0, w-btnsize*2.1f, h-btnsize)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+4,0, w-btnsize*2.1f, h-btnsize*2.1f)
                break;
            case 6:
            default:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,0, w-btnsize, h-btnsize*3.15f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,0, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,0, w-btnsize, h-btnsize)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+3,0, w-btnsize*2.1f, h-btnsize*3.15f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+4,0, w-btnsize*2.1f, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+5,0, w-btnsize*2.1f, h-btnsize)
                break;
        }
    } else {
        switch (nb_button) { //verti
            case 0:
                break;
            case 1:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,0, w-btnsize, h-btnsize*2.6f)
                break;
            case 2:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,0, w-btnsize, h-btnsize*2.6f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,0, w-btnsize, h-btnsize*1.5f)
                break;
            case 3:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,0, w-btnsize, h-btnsize*2.6f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,0, w-btnsize, h-btnsize*1.5f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,0, w-btnsize*2.1f, h-btnsize*2.6f)
                break;
            case 4:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,0, w-btnsize, h-btnsize*2.6f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,0, w-btnsize, h-btnsize*1.5f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,0, w-btnsize*2.1f, h-btnsize*2.6f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+3,0, w-btnsize*2.1f, h-btnsize*1.5f)
                break;
            case 5:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,0, w-btnsize, h-btnsize*3.15f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,0, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,0, w-btnsize, h-btnsize)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+3,0, w-btnsize*2.1f, h-btnsize*3.15f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+4,0, w-btnsize*2.1f, h-btnsize*2.1f)
                break;
            case 6:
            default:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,0, w-btnsize, h-btnsize*3.15f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,0, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,0, w-btnsize, h-btnsize)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+3,0, w-btnsize*2.1f, h-btnsize*3.15f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+4,0, w-btnsize*2.1f, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+5,0, w-btnsize*2.1f, h-btnsize)
                break;
        }
    }
    
    if (device_isIpad) {
        w=mDevice_hh;
        h=mDevice_ww-40;
    } else {
        w=mDevice_hh;
        h=mDevice_ww;
    }
    w-=10;
    h-=10; //dirty hack to compensate the +30% touch area size
    
    if (cur_ifba_conf->vpad_followfinger && glob_ffingeron) { //follow finger mode
        switch (nb_button) {//horiz
            case 0:
                break;
            case 1:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,1, w-btnsize, h-btnsize*2.1f)
                break;
            case 2:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,1, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,1, w-btnsize, h-btnsize)
                break;
            case 3:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,1, w-btnsize, h-btnsize*3.15f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,1, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,1, w-btnsize, h-btnsize)
                break;
            case 4:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,1, w-btnsize, h-btnsize*4.2f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,1, w-btnsize, h-btnsize*3.15f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,1, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+3,1, w-btnsize, h-btnsize)
                break;
            case 5:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,1, w-btnsize*3.15f, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,1, w-btnsize*2.1f, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,1, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+3,1, w-btnsize*2.1f, h-btnsize)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+4,1, w-btnsize, h-btnsize)
                break;
            case 6:
            default:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,1, w-btnsize*3.15f, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,1, w-btnsize*2.1f, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,1, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+3,1, w-btnsize*3.15f, h-btnsize)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+4,1, w-btnsize*2.1f, h-btnsize)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+5,1, w-btnsize, h-btnsize)
                break;
        }
        
    } else {
        
        switch (nb_button) {//horiz
            case 0:
                break;
            case 1:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,1, w-btnsize, h-btnsize*2.1f)
                break;
            case 2:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,1, w-btnsize*2.1f, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,1, w-btnsize, h-btnsize*2.1f)
                break;
            case 3:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,1, w-btnsize*2.1f, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,1, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,1, w-btnsize, h-btnsize)
                break;
            case 4:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,1, w-btnsize*2.1f, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,1, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,1, w-btnsize*2.1f, h-btnsize)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+3,1, w-btnsize, h-btnsize)
                break;
            case 5:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,1, w-btnsize*3.15f, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,1, w-btnsize*2.1f, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,1, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+3,1, w-btnsize*2.1f, h-btnsize)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+4,1, w-btnsize, h-btnsize)
                break;
            case 6:
            default:
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB,1, w-btnsize*3.15f, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+1,1, w-btnsize*2.1f, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+2,1, w-btnsize, h-btnsize*2.1f)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+3,1, w-btnsize*3.15f, h-btnsize)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+4,1, w-btnsize*2.1f, h-btnsize)
                SET_BUTTON_LAYOUT(VPAD_SPECIALS_BUTTON_NB+5,1, w-btnsize, h-btnsize)
                break;
        }
    }
}

int gTurboMode;

static uint vpad_button_texture[6],vpad_dpad_texture;
static uint vpad_button_spe_texture[5];
static uint filter_crt_texture,filter_scanline_texture;
static uint vpad_animated_dpad[9]; //8directions + still
static uint vpad_animated_stick[2]; //8directions + still


char gameName[64];
int launchGame;

volatile int emuThread_running;

static GLfloat vertices[5][2];  /* Holds Float Info For 4 Sets Of Vertices */
static GLfloat texcoords[5][2]; /* Holds Float Info For 4 Sets Of Texture coordinates. */

static void *context; //hack to call objective C func from C

static UIProgressView *prgview=nil;
static UIView *statusview=nil;
static UIView *statusDownview=nil;
static UILabel *statusMsgview=nil;
static UILabel *statusLoadMsgview=nil;
static char statusMsg[512];
static char statusLoadMsg[512];

static int statusMsgUpdated=0;
static int statusLoadMsgUpdated=0;

@implementation EmuViewController

@synthesize control;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Emu", @"Emu");
        //self.tabBarItem.image = [UIImage imageNamed:@"Emu"];
        launchGame=0;
        device_orientation=0; //portrait
        
        //DEBUG
        //launchGame=1;
        //sprintf(gameName,"dogyuun");
        //
        
        
        //WIIMOTE
        // create discovery controller
        //discoveryView = [[BTDiscoveryViewController alloc] init];
        //[discoveryView setDelegate:self];
        //[self.view addSubview:discoveryView.view];
        //    discoveryView.view.hidden=TRUE;
        // BTstack
        bt = [BTstackManager sharedInstance];
        if (bt) {
            [bt setDelegate:self];
            [bt addListener:self];
            //[bt addListener:discoveryView];
            if (ifba_conf.btstack_on) [bt activate];
        }
        renderVPADonly=0;
        
        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (uint) loadTexture:(UIImage*)uiimage {
	CGImage* image = uiimage.CGImage;
	assert(image != NULL);
	const int width = CGImageGetWidth(image);
	const int height = CGImageGetHeight(image);
	const int dataSize = width * height * 4;
	uint handle;
	
	uint8_t* textureData = (uint8_t*)malloc(dataSize);
    if (!textureData) {
        NSLog(@"Error: cannot allocate texture");
    }
    memset(textureData,0,dataSize);
	CGContext* textureContext = CGBitmapContextCreate(textureData, width, height, 8, width * 4, CGImageGetColorSpace(image), kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(textureContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), image);
	CGContextRelease(textureContext);
	
    
	glGenTextures(1, &handle);
	glBindTexture(GL_TEXTURE_2D, handle);
	
	glTexParameterf(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);//TRUE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
	
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (cur_ifba_conf->filtering?GL_LINEAR:GL_NEAREST) );
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (cur_ifba_conf->filtering?GL_LINEAR:GL_NEAREST));
	
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	
	glBindTexture(GL_TEXTURE_2D, 0);
	
	free(textureData);
	return handle;
}



#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    context=self;
    
	// Do any additional setup after loading the view, typically from a nib.
    m_oglView=(OGLView*)(self.view);
    
    mScaleFactor=1.0f;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		mDeviceType=1; //ipad
		mDevice_hh=1024;
		mDevice_ww=768;
	}
	else {
		
		mDeviceType=0; //iphone   (iphone 4 res currently not handled)
		mDevice_hh=480;
		mDevice_ww=320;
        
        UIScreen* mainscr = [UIScreen mainScreen];
		if ([mainscr respondsToSelector:@selector(currentMode)]) {
			if (mainscr.currentMode.size.width>480) {  //iphone 4
				mDeviceType=0;
				mScaleFactor=1;
			}
            if(mainscr.bounds.size.height>=568) {
                mDevice_hh=568; //iPhone 5
            }
		}
	}
    
    m_oglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	[EAGLContext setCurrentContext:m_oglContext];
	[m_oglView initialize:m_oglContext scaleFactor:mScaleFactor];
    
    //create texture
    glGenTextures(1, &txt_vbuffer);               /* Create 1 Texture */
    glBindTexture(GL_TEXTURE_2D, txt_vbuffer);    /* Bind The Texture */
	
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (cur_ifba_conf->filtering?GL_LINEAR:GL_NEAREST) );
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (cur_ifba_conf->filtering?GL_LINEAR:GL_NEAREST));
    
	glBindTexture(GL_TEXTURE_2D, 0);
    
    /************************************/
    /* init texture for vpad */
    
    // a,b,c,d buttons
    vpad_dpad_texture=[self loadTexture:[UIImage imageNamed:@"dpad.png"]];
    vpad_button_texture[0]=[self loadTexture:[UIImage imageNamed:@"button_1.png"]];
    vpad_button_texture[1]=[self loadTexture:[UIImage imageNamed:@"button_2.png"]];
    vpad_button_texture[2]=[self loadTexture:[UIImage imageNamed:@"button_3.png"]];
    vpad_button_texture[3]=[self loadTexture:[UIImage imageNamed:@"button_4.png"]];
    vpad_button_texture[4]=[self loadTexture:[UIImage imageNamed:@"button_5.png"]];
    vpad_button_texture[5]=[self loadTexture:[UIImage imageNamed:@"button_6.png"]];
    vpad_button_spe_texture[0]=[self loadTexture:[UIImage imageNamed:@"button-start.png"]];
    vpad_button_spe_texture[1]=[self loadTexture:[UIImage imageNamed:@"button-coin.png"]];
    vpad_button_spe_texture[2]=[self loadTexture:[UIImage imageNamed:@"button-menu.png"]];
    vpad_button_spe_texture[3]=[self loadTexture:[UIImage imageNamed:@"button-turbo.png"]];
    vpad_button_spe_texture[4]=[self loadTexture:[UIImage imageNamed:@"button-service.png"]];
    
    vpad_button_nb=VPAD_SPECIALS_BUTTON_NB; //0button by default. Activated when scanned by emu
    vpad_button_nb_save=vpad_button_nb;
    
    vpad_animated_dpad[0]=[self loadTexture:[UIImage imageNamed:@"DPad_NotPressed.png"]];
    vpad_animated_dpad[1]=[self loadTexture:[UIImage imageNamed:@"DPad_R.png"]];
    vpad_animated_dpad[2]=[self loadTexture:[UIImage imageNamed:@"DPad_DR.png"]];
    vpad_animated_dpad[3]=[self loadTexture:[UIImage imageNamed:@"DPad_D.png"]];
    vpad_animated_dpad[4]=[self loadTexture:[UIImage imageNamed:@"DPad_DL.png"]];
    vpad_animated_dpad[5]=[self loadTexture:[UIImage imageNamed:@"DPad_L.png"]];
    vpad_animated_dpad[6]=[self loadTexture:[UIImage imageNamed:@"DPad_UL.png"]];
    vpad_animated_dpad[7]=[self loadTexture:[UIImage imageNamed:@"DPad_U.png"]];
    vpad_animated_dpad[8]=[self loadTexture:[UIImage imageNamed:@"DPad_UR.png"]];
    
    vpad_animated_stick[0]=[self loadTexture:[UIImage imageNamed:@"stick-inner.png"]];
    vpad_animated_stick[1]=[self loadTexture:[UIImage imageNamed:@"stick-outer.png"]];
    
    
    filter_crt_texture=[self loadTexture:[UIImage imageNamed:@"crt-1.png"]];
    filter_scanline_texture=[self loadTexture:[UIImage imageNamed:@"scanline-1.png"]];
    /**************************************/
    
    vbuffer=(unsigned short*)malloc(TEXTURE_W*TEXTURE_H*2);
    if (!vbuffer ) {
        NSLog(@"Critical issue: vbuffer cannot be allocated");
    }
    memset(vbuffer,0,TEXTURE_W*TEXTURE_H*2);
    vid_rotated=0;
    vid_aspectX=4;
    vid_aspectY=3;
    virtual_stick_on=1;
    visible_area_w=480;
    visible_area_h=320;
    
    for (int i=0;i<MAX_JOYSTICKS;i++) {
        joy_analog_x[i]=0;
        joy_analog_y[i]=0;
        joy_analog_l[i]=0;
        joy_analog_r[i]=0;
        patch_analog_x[i]=0;
        patch_analog_y[i]=0;
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden=YES;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    
    //assign good conf
    if (game_has_options) cur_ifba_conf=(ifba_conf_t*)&ifba_game_conf;
    else cur_ifba_conf=(ifba_conf_t*)&ifba_conf;
    
    
    UIInterfaceOrientation cur_or=[[UIApplication sharedApplication] statusBarOrientation];
    if ((cur_or==UIInterfaceOrientationLandscapeLeft)||(cur_or==UIInterfaceOrientationLandscapeRight)) device_orientation=1;
    else device_orientation=0;
    
    if (renderVPADonly&&(vpad_button_nb==VPAD_SPECIALS_BUTTON_NB)) vpad_button_nb=VSTICK_NB_BUTTON;
    
    
    if (bt&&ifba_conf.btstack_on) {
        stopWiimoteDetection();
    }
    
    //
    for (int i=0;i<num_of_joys;i++) {
        wm_joy_pl[i]=wm_prev_joy_pl[i]=0;
    }
    joy_state[0][GN_MENU_KEY]=0;
    
    //icade map
    memset(joymap_dir_iCade,0,sizeof(joymap_dir_iCade));
    for (int joy=0;joy<MAX_JOYSTICKS;joy++)
        for (int i=0;i<VSTICK_NB_BUTTON;i++) {
            int j=cur_ifba_conf->joymap_iCade[joy][i].dev_btn;
            if (j) {
                switch (i) {
                    case 0:joymap_dir_iCade[joy][j-1]=GN_START;break;
                    case 1:joymap_dir_iCade[joy][j-1]=GN_SELECT_COIN;break;
                    case 2:joymap_dir_iCade[joy][j-1]=GN_MENU_KEY;break;
                    case 3:joymap_dir_iCade[joy][j-1]=GN_TURBO;break;
                    case 4:joymap_dir_iCade[joy][j-1]=GN_SERVICE;break;
                    case 5:joymap_dir_iCade[joy][j-1]=GN_A;break;
                    case 6:joymap_dir_iCade[joy][j-1]=GN_B;break;
                    case 7:joymap_dir_iCade[joy][j-1]=GN_C;break;
                    case 8:joymap_dir_iCade[joy][j-1]=GN_D;break;
                    case 9:joymap_dir_iCade[joy][j-1]=GN_E;break;
                    case 10:joymap_dir_iCade[joy][j-1]=GN_F;break;
                }
            }
        }
    //wiimotes map
    memset(joymap_dir_wiimote,0,sizeof(joymap_dir_wiimote));
    for (int joy=0;joy<MAX_JOYSTICKS;joy++)
        for (int i=0;i<VSTICK_NB_BUTTON;i++) {
            int j=cur_ifba_conf->joymap_wiimote[joy][i].dev_btn;
            if (j) {
                switch (i) {
                    case 0:joymap_dir_wiimote[joy][j-1]=GN_START;break;
                    case 1:joymap_dir_wiimote[joy][j-1]=GN_SELECT_COIN;break;
                    case 2:joymap_dir_wiimote[joy][j-1]=GN_MENU_KEY;break;
                    case 3:joymap_dir_wiimote[joy][j-1]=GN_TURBO;break;
                    case 4:joymap_dir_wiimote[joy][j-1]=GN_SERVICE;break;
                    case 5:joymap_dir_wiimote[joy][j-1]=GN_A;break;
                    case 6:joymap_dir_wiimote[joy][j-1]=GN_B;break;
                    case 7:joymap_dir_wiimote[joy][j-1]=GN_C;break;
                    case 8:joymap_dir_wiimote[joy][j-1]=GN_D;break;
                    case 9:joymap_dir_wiimote[joy][j-1]=GN_E;break;
                    case 10:joymap_dir_wiimote[joy][j-1]=GN_F;break;
                }
            }
        }
    
    //ICADE
    control = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:control];
    control.active = YES;
    control.delegate = self;
    [control changeLang:ifba_conf.icade_lang];
    [control changeControllerType:cur_ifba_conf->joy_iCadeIMpulse];
    [control release];
    
    
    
    int cur_width=m_oglView.frame.size.width;
    int cur_height=m_oglView.frame.size.height;
    
    //TOUCHPAD Setup
    computePadLayouts(vpad_button_nb-VPAD_SPECIALS_BUTTON_NB);
    vpad_button_nb_save=vpad_button_nb;
    virtual_stick_pad=0;
    //
    for (int j=0;j<MAX_JOYSTICKS;j++) {
        joy_analog_x[j]=0;joy_analog_y[j]=0;
        patch_analog_x[j]=0;patch_analog_y[j]=0;
        joy_state[j][GN_UP]=0;
        joy_state[j][GN_DOWN]=0;
        joy_state[j][GN_LEFT]=0;
        joy_state[j][GN_RIGHT]=0;
        joy_state[j][GN_UPRIGHT]=0;
        joy_state[j][GN_DOWNRIGHT]=0;
        joy_state[j][GN_UPLEFT]=0;
        joy_state[j][GN_DOWNLEFT]=0;
        for (int i=0;i<VSTICK_NB_BUTTON;i++)  {
            virtual_stick[i].finger_id=0;
            joy_state[j][virtual_stick[i].button_id]=0;
        }
    }
    
    glob_touchpad_cnt=0;
    
    m_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(loopCheck)];
    m_displayLink.frameInterval = 2; //30fps
	[m_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    if (renderVPADonly) {
        nShouldExit=3;
    } else {
        playtime=0;
        playtime_lastclock=clock();
        
        
        //If resuming
        if (nShouldExit==2) {
            //launch new game ?
            if (launchGame==1) {//yes, exit current one
                nShouldExit=1;
                while (emuThread_running) {
                    [NSThread sleepForTimeInterval:0.01]; //10ms
                }
                [NSThread sleepForTimeInterval:0.1]; //100ms
            } else {//no, only resume
                nShouldExit=0;
            }
        }
        //If required launch game / emuthread
        if (launchGame==1) {
            nShouldExit=0;
            pb_value=0;
            pb_total=0;
            pb_msg[0]=0;
            
            ////////////////
            glob_framecpt_max=0;
            glob_replay_data_index=0;
            glob_framecpt=0;
            glob_replay_data_index_max=MAX_REPLAY_DATA_BYTES;
            
            if (glob_replay_mode==REPLAY_PLAYBACK_MODE) { //REPLAY
                if (LoadReplay(glob_replay_currentslot)!=0) glob_replay_mode=0;
                
            }
            
            //////////////
            glob_shooton=0;
            glob_shootmode=0;
            glob_buttons_limit=6;
            cur_ifba_conf->vpad_followfinger=0;
            if ((strcmp(gameName,"donpachi")==0)||(strcmp(gameName,"donpachij")==0)) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=1;
            }
            if ((strcmp(gameName,"ddonpach")==0)||(strcmp(gameName,"ddonpachj")==0)) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=2;
            }
            if ((strcmp(gameName,"feversos")==0)||(strcmp(gameName,"dfeveron")==0)) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=3;
            }
            if ((strcmp(gameName,"bgaregga")==0)||(strcmp(gameName,"bgareggabl")==0)||(strcmp(gameName,"bgareggacn")==0)||(strcmp(gameName,"bgareggahk")==0)||(strcmp(gameName,"bgaregganv")==0)||(strcmp(gameName,"bgareggat2")==0)||(strcmp(gameName,"bgareggatw")==0)) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=4;
            }
            if ((strcmp(gameName,"dogyuun")==0)||(strcmp(gameName,"dogyuuna")==0)||(strcmp(gameName,"dogyuunt")==0)){
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=5;
            }
            if (strcmp(gameName,"truxton2")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=6;
            }
            if (strcmp(gameName,"ket")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=7;
            }
            if (strcmp(gameName,"progear")==0) {
                cur_ifba_conf->vpad_followfinger=1; glob_buttons_limit=2;glob_touchpad_hack=8;
            }
            if (strcmp(gameName,"s1945")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=9;
            }
            if (strcmp(gameName,"gunbird")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=10;
            }
            if (strcmp(gameName,"gunbird2")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=11;
            }
            if (strcmp(gameName,"dragnblz")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=12;
            }
            if ((strcmp(gameName,"batrider")==0)||(strcmp(gameName,"batrideru")==0)||(strcmp(gameName,"batriderc")==0)||(strcmp(gameName,"batriderj")==0)||(strcmp(gameName,"batriderk")==0)||(strcmp(gameName,"batriderja")==0)||
                (strcmp(gameName,"batridert")==0)){
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=13;
            }
            if ((strcmp(gameName,"bbakraid")==0)||(strcmp(gameName,"bbakraidj")==0)||(strcmp(gameName,"bbakraidja")==0)) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=14;
            }
            if (strcmp(gameName,"dimahoo")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=15;glob_buttons_limit=2;
            }
            if ((strcmp(gameName,"grindstm")==0)||(strcmp(gameName,"grindstma")==0)||(strcmp(gameName,"vfive")==0)) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=16;
            }
            if ((strcmp(gameName,"batsugun")==0)||(strcmp(gameName,"batsugunsp")==0)) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=17;
            }
            if (strcmp(gameName,"esprade")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=18;
            }
            if (strcmp(gameName,"espgal")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=19;
            }
            if ((strcmp(gameName,"samuraia")==0)||(strcmp(gameName,"sngkace")==0)) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=20;
            }
            if ((strcmp(gameName,"tengai")==0)||(strcmp(gameName,"tengaij")==0)) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=21;
            }
            if (strcmp(gameName,"gigawing")==0) {
                cur_ifba_conf->vpad_followfinger=1; glob_buttons_limit=2;glob_touchpad_hack=22;
            }
            if (strcmp(gameName,"mmatrix")==0) {
                cur_ifba_conf->vpad_followfinger=1; glob_buttons_limit=1;glob_touchpad_hack=23;
            }
            if (strcmp(gameName,"ddpdoj")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=24;
            }
            if (strcmp(gameName,"ddpdojblk")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=25;
            }
            if ((strcmp(gameName,"varth")==0)||(strcmp(gameName,"varthr1")==0)||(strcmp(gameName,"varthu")==0)||(strcmp(gameName,"varthj")==0)) {
                //not working well
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=26;
            }
            if ((strcmp(gameName,"mahoudai")==0)||(strcmp(gameName,"sstriker")==0)||(strcmp(gameName,"sstrikera")==0)) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=27;
            }
            if ((strcmp(gameName,"shippumd")==0)||(strcmp(gameName,"kingdmgp")==0)) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=28;
            }
            if ((strcmp(gameName,"daioh")==0)||(strcmp(gameName,"daioha")==0)) {
                cur_ifba_conf->vpad_followfinger=2;glob_touchpad_hack=29;
            }
            if (strcmp(gameName,"s1945ii")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=30;
            }
            if (strcmp(gameName,"s1945iii")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=31;
            }
            if ((strcmp(gameName,"ddpdoja")==0)||(strcmp(gameName,"ddpdojb")==0)) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=32;
            }
            if (strcmp(gameName,"ddp2")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=33;
            }
            if ((strcmp(gameName,"ddp2100")==0)||(strcmp(gameName,"ddp2101")==0)) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=34;
            }
            if (strcmp(gameName,"blazstar")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=35;
            }
            if (strcmp(gameName,"ironclad")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=36;
            }
            if (strcmp(gameName,"pulstar")==0) {
                cur_ifba_conf->vpad_followfinger=1;glob_touchpad_hack=37;
            }
            
            
            if (cur_ifba_conf->vpad_followfinger) {
#ifdef TESTFLIGHT_BUILD
                [TestFlight passCheckpoint:@"FINGER_MODE"];
#endif
                //printf("Using follow-finger touchscreen mode\n");
                
                UIAlertView* alert =
                [[UIAlertView alloc] initWithTitle:@"Follow finger mode"
                                           message:[NSString stringWithFormat:@"Follow finger mode activated.\nTap on 'service' button to switch between controls mode.\n\nFor classic 'service' button (if supported by game), hold one finger somewhere on the screen and press 'service' with a second finger.",gameName]
                                          delegate:nil cancelButtonTitle:@"Close or wait" otherButtonTitles: nil];
                
                [NSTimer scheduledTimerWithTimeInterval:3
                                                 target:alert
                                               selector:@selector(dismissWithClickedButtonIndex:animated:)
                                               userInfo:nil
                                                repeats:NO];
                
                [alert show];
                [alert release];
            }
            glob_ffingeron=cur_ifba_conf->vpad_followfinger;
            
            //////////////////
            vpad_button_nb=VPAD_SPECIALS_BUTTON_NB; //0button by default. Activated when scanned by emu
            vpad_button_nb_save=vpad_button_nb;
            
            computePadLayouts(vpad_button_nb-VPAD_SPECIALS_BUTTON_NB);
            
            
            
            [NSThread detachNewThreadSelector:@selector(emuThread) toTarget:self withObject:NULL];
            launchGame=0;
            prgview=[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
            prgview.frame=CGRectMake(10,m_oglView.frame.size.height/2,m_oglView.frame.size.width-20,30);
            prgview.progress=0;
            [self.view addSubview:prgview];
            [prgview release];
            
            statusview=[[UIView alloc] init];
            statusview.frame=CGRectMake(10,m_oglView.frame.size.height/2-110,m_oglView.frame.size.width-20,80);
            [[statusview layer] setCornerRadius:15.0];
            [[statusview layer] setBorderWidth:3.0];
            [[statusview layer] setBorderColor:[[UIColor colorWithRed: 0.95f green: 0.95f blue: 0.95f alpha: 1.0f] CGColor]];   //Adding Border color.
            statusview.backgroundColor=[UIColor colorWithRed:0.1f green:0.0f blue:0.25f alpha:1.0f];
            
            statusDownview=[[UIView alloc] init];
            statusDownview.frame=CGRectMake(10,m_oglView.frame.size.height/2+40,m_oglView.frame.size.width-20,80);
            [[statusDownview layer] setCornerRadius:15.0];
            [[statusDownview layer] setBorderWidth:3.0];
            [[statusDownview layer] setBorderColor:[[UIColor colorWithRed: 0.95f green: 0.95f blue: 0.95f alpha: 1.0f] CGColor]];   //Adding Border color.
            statusDownview.backgroundColor=[UIColor colorWithRed:0.1f green:0.0f blue:0.25f alpha:1.0f];
            
            statusMsgview=[[UILabel alloc] init];
            statusMsgview.frame=CGRectMake(10,5,statusview.frame.size.width-20,statusview.frame.size.height-10);
            statusMsgview.autoresizingMask=UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            statusMsgview.text=@"";
            statusMsgview.textColor=[UIColor whiteColor];
            statusMsgview.backgroundColor=[UIColor clearColor];
            statusMsgview.lineBreakMode=UILineBreakModeWordWrap;
            statusMsgview.numberOfLines=3;
            statusMsgview.font=[UIFont boldSystemFontOfSize:16];
            statusMsgview.textAlignment=UITextAlignmentCenter;
            [statusview addSubview:statusMsgview];
            [self.view addSubview:statusview];
            [statusMsgview release];
            [statusview release];
            
            statusLoadMsgview=[[UILabel alloc] init];
            statusLoadMsgview.frame=CGRectMake(10,5,statusview.frame.size.width-20,statusview.frame.size.height-10);
            statusLoadMsgview.autoresizingMask=UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            statusLoadMsgview.text=@"";
            statusLoadMsgview.textColor=[UIColor whiteColor];
            statusLoadMsgview.backgroundColor=[UIColor clearColor];
            statusLoadMsgview.lineBreakMode=UILineBreakModeWordWrap;
            statusLoadMsgview.numberOfLines=10;
            statusLoadMsgview.font=[UIFont boldSystemFontOfSize:10];
            statusLoadMsgview.textAlignment=UITextAlignmentCenter;
            [statusDownview addSubview:statusLoadMsgview];
            [self.view addSubview:statusDownview];
            [statusLoadMsgview release];
            [statusDownview release];
            
            
        }
        launchGame=0;
    }
    //update ogl framebuffer
    [m_oglView didRotateFromInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    if (m_displayLink) [m_displayLink invalidate];
    
    if (renderVPADonly==0) {//was emulating a game
        int playTime_incr=playtime/CLOCKS_PER_SEC;
        
        //update game stats
        int playCount,fav,playTime;
        char lastPlayed[11];
        DBHelper::getGameStats(gameName, &playCount, &fav, lastPlayed,&playTime);
        playTime+=playTime_incr;
        DBHelper::setGameStats(gameName, playCount, fav, lastPlayed,playTime);
        //NSLog(@"exit emuview, set Stats: pc:%d, fav:%d, lp:%s, pt:%d",playCount,fav,lastPlayed,playTime);
    }
    
    //reset rendering mode
    renderVPADonly=0;
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    if (glob_replay_mode==REPLAY_RECORD_MODE) { //SAVE
        SaveReplay(glob_replay_currentslot);
#ifdef TESTFLIGHT_BUILD
        [TestFlight passCheckpoint:@"Save replay"];
#endif
    }
    
    if (nShouldExit==1) {
        while (emuThread_running) {
            [NSThread sleepForTimeInterval:0.01]; //10ms
        }
        
        
    }
    if (bt&&ifba_conf.btstack_on) {
        startWiimoteDetection();
    }
    
    if (prgview) {
        [prgview removeFromSuperview];
        prgview=nil;
    }
    if (statusMsgview) {
        [statusMsgview removeFromSuperview];
        statusMsgview=nil;
    }
    if (statusview) {
        [statusview removeFromSuperview];
        statusview=nil;
    }
    if (statusLoadMsgview) {
        [statusLoadMsgview removeFromSuperview];
        statusLoadMsgview=nil;
    }
    if (statusDownview) {
        [statusDownview removeFromSuperview];
        statusDownview=nil;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    /*    if ((interfaceOrientation==UIInterfaceOrientationPortrait)||(interfaceOrientation==UIInterfaceOrientationPortraitUpsideDown)) {
     m_oglView.frame=CGRectMake(0,0,mDevice_ww,mDevice_hh);
     device_orientation=0;
     
     } else {
     m_oglView.frame=CGRectMake(0,0,mDevice_hh,mDevice_ww);
     device_orientation=1;
     }
     if (prgview) prgview.frame=CGRectMake(10,m_oglView.frame.size.height/2,m_oglView.frame.size.width-20,30);
     if (statusview) statusview.frame=CGRectMake(10,m_oglView.frame.size.height/2-30,m_oglView.frame.size.width-20,30);*/
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    //[self shouldAutorotateToInterfaceOrientation:fromInterfaceOrientation];
    //hack ios 6?
    if ((fromInterfaceOrientation==UIInterfaceOrientationPortrait)||(fromInterfaceOrientation==UIInterfaceOrientationPortraitUpsideDown)) {
        m_oglView.frame=CGRectMake(0,0,mDevice_hh,mDevice_ww);
        device_orientation=1;
    } else {
        m_oglView.frame=CGRectMake(0,0,mDevice_ww,mDevice_hh);
        device_orientation=0;
    }
    [m_oglView didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    if (prgview) prgview.frame=CGRectMake(10,m_oglView.frame.size.height/2,m_oglView.frame.size.width-20,30);
    if (statusview) statusview.frame=CGRectMake(10,m_oglView.frame.size.height/2-30,m_oglView.frame.size.width-20,30);
}

/****************************************************/
/****************************************************/
/*        ICADE                                     */
/****************************************************/
/****************************************************/

- (void)setICadeState:(BOOL)state forButton:(iCadeState)button {
    virtual_stick_on=0;
    switch (button) {
        case iCadeButtonA:
            joy_state[0][joymap_dir_iCade[0][0]]=state;
            break;
        case iCadeButtonB:
            joy_state[0][joymap_dir_iCade[0][1]]=state;
            break;
        case iCadeButtonC:
            joy_state[0][joymap_dir_iCade[0][2]]=state;
            break;
        case iCadeButtonD:
            joy_state[0][joymap_dir_iCade[0][3]]=state;
            break;
        case iCadeButtonE:
            joy_state[0][joymap_dir_iCade[0][4]]=state;
            break;
        case iCadeButtonF:
            joy_state[0][joymap_dir_iCade[0][5]]=state;
            break;
        case iCadeButtonG:
            joy_state[0][joymap_dir_iCade[0][6]]=state;
            break;
        case iCadeButtonH:
            joy_state[0][joymap_dir_iCade[0][7]]=state;
            break;
        case iCadeJoystickUp:
            joy_state[0][GN_UP]=state;
            break;
        case iCadeJoystickRight:
            joy_state[0][GN_RIGHT]=state;
            break;
        case iCadeJoystickDown:
            joy_state[0][GN_DOWN]=state;
            break;
        case iCadeJoystickLeft:
            joy_state[0][GN_LEFT]=state;
            break;
        case iCadeButtonA2:
            joy_state[1][joymap_dir_iCade[1][0]]=state;
            break;
        case iCadeButtonB2:
            joy_state[1][joymap_dir_iCade[1][1]]=state;
            break;
        case iCadeButtonC2:
            joy_state[1][joymap_dir_iCade[1][2]]=state;
            break;
        case iCadeButtonD2:
            joy_state[1][joymap_dir_iCade[1][3]]=state;
            break;
        case iCadeButtonE2:
            joy_state[1][joymap_dir_iCade[1][4]]=state;
            break;
        case iCadeButtonF2:
            joy_state[1][joymap_dir_iCade[1][5]]=state;
            break;
        case iCadeJoystick2Up:
            joy_state[1][GN_UP]=state;
            break;
        case iCadeJoystick2Right:
            joy_state[1][GN_RIGHT]=state;
            break;
        case iCadeJoystick2Down:
            joy_state[1][GN_DOWN]=state;
            break;
        case iCadeJoystick2Left:
            joy_state[1][GN_LEFT]=state;
            break;
        default:
            break;
    }
    
    
    if (joy_state[0][GN_MENU_KEY]) nShouldExit=2;
    bAppDoFast=joy_state[0][GN_TURBO];
}

- (void)buttonDown:(iCadeState)button {
    [self setICadeState:YES forButton:button];
}

- (void)buttonUp:(iCadeState)button {
    [self setICadeState:NO forButton:button];
}

/****************************************************/
/****************************************************/
/*        BTSTACK / WIIMOTE                         */
/****************************************************/
/****************************************************/

void updateWiimotes(void) {
    //Wiimotes update
    int wii_but;
    for (int i=0;i<num_of_joys;i++) {
        if (wm_joy_pl[i]=iOS_wiimote_check(&(joys[i]))) virtual_stick_on=0;
        if (wm_joy_pl[i]!=wm_prev_joy_pl[i]) {
            wm_prev_joy_pl[i]=wm_joy_pl[i];
            
            joy_state[i][GN_UP]=(wm_joy_pl[i]&WII_JOY_UP?1:0);
            joy_state[i][GN_DOWN]=(wm_joy_pl[i]&WII_JOY_DOWN?1:0);
            joy_state[i][GN_LEFT]=(wm_joy_pl[i]&WII_JOY_LEFT?1:0);
            joy_state[i][GN_RIGHT]=(wm_joy_pl[i]&WII_JOY_RIGHT?1:0);
            
            
            if ((wii_but=joymap_dir_wiimote[i][WII_BUTTON_A-1])) joy_state[i][wii_but]=(wm_joy_pl[i]&WII_JOY_A?1:0);
            if ((wii_but=joymap_dir_wiimote[i][WII_BUTTON_B-1])) joy_state[i][wii_but]=(wm_joy_pl[i]&WII_JOY_B?1:0);
            if ((wii_but=joymap_dir_wiimote[i][WII_BUTTON_C-1])) joy_state[i][wii_but]=(wm_joy_pl[i]&WII_JOY_C?1:0);
            if ((wii_but=joymap_dir_wiimote[i][WII_BUTTON_D-1])) joy_state[i][wii_but]=(wm_joy_pl[i]&WII_JOY_D?1:0);
            if ((wii_but=joymap_dir_wiimote[i][WII_BUTTON_E-1])) joy_state[i][wii_but]=(wm_joy_pl[i]&WII_JOY_E?1:0);
            if ((wii_but=joymap_dir_wiimote[i][WII_BUTTON_F-1])) joy_state[i][wii_but]=(wm_joy_pl[i]&WII_JOY_F?1:0);
            if ((wii_but=joymap_dir_wiimote[i][WII_BUTTON_G-1])) joy_state[i][wii_but]=(wm_joy_pl[i]&WII_JOY_G?1:0);
            if ((wii_but=joymap_dir_wiimote[i][WII_BUTTON_H-1])) joy_state[i][wii_but]=(wm_joy_pl[i]&WII_JOY_H?1:0);
            if ((wii_but=joymap_dir_wiimote[i][WII_BUTTON_HOME-1])) joy_state[i][wii_but]=(wm_joy_pl[i]&WII_JOY_HOME?1:0);
            if ((wii_but=joymap_dir_wiimote[i][WII_BUTTON_START-1])) joy_state[i][wii_but]=(wm_joy_pl[i]&WII_JOY_START?1:0);
            if ((wii_but=joymap_dir_wiimote[i][WII_BUTTON_SELECT-1])) joy_state[i][wii_but]=(wm_joy_pl[i]&WII_JOY_SELECT?1:0);
            
        }
        
        if (joy_state[i][GN_MENU_KEY]) nShouldExit=2;
        bAppDoFast=joy_state[i][GN_TURBO];
    }
    
    
}

void startWiimoteDetection(void) {
    //    NSLog(@"Looking for wiimote");
    
    BTstackManager * bt = [BTstackManager sharedInstance];
    if (bt) {BTstackError err = [bt activate];
        if (err) NSLog(@"activate err 0x%02x!", err);
    }
}

void stopWiimoteDetection(void) {
    // NSLog(@"Stop looking for wiimote");
    BTstackManager * bt = [BTstackManager sharedInstance];
	if (bt) [bt stopDiscovery];
}


-(void) activatedBTstackManager:(BTstackManager*) manager {
    //	NSLog(@"activated!");
	[[BTstackManager sharedInstance] startDiscovery];
}

-(void) btstackManager:(BTstackManager*)manager deviceInfo:(BTDevice*)newDevice {
    //	NSLog(@"Device Info: addr %@ name %@ COD 0x%06x", [newDevice addressString], [newDevice name], [newDevice classOfDevice] );
	if ([newDevice name]){
        NSRange r=[[newDevice name] rangeOfString:@"Nintendo RVL-CNT" options:NSCaseInsensitiveSearch];
        if (r.location!=NSNotFound) {
            //NSLog(@"WiiMote found with address %@", [newDevice addressString]);
            device = newDevice;
            [[BTstackManager sharedInstance] stopDiscovery];
        }
	}
}

-(void) discoveryStoppedBTstackManager:(BTstackManager*) manager {
    //	NSLog(@"discoveryStopped!");
	// connect to device
	if (device) bt_send_cmd(&l2cap_create_channel, [device address], 0x13);
}


// direct access
-(void) btstackManager:(BTstackManager*) manager
  handlePacketWithType:(uint8_t) packet_type
			forChannel:(uint16_t) channel
			   andData:(uint8_t *)packet
			   withLen:(uint16_t) size
{
	bd_addr_t event_addr;
	
    switch (packet_type) {
            
        case L2CAP_DATA_PACKET://0x06
        {
            struct wiimote_t *wm = NULL;
            
            wm = wiimote_get_by_source_cid(channel);
            
            if(wm!=NULL)
            {
                
                byte* msg = packet + 2;
                byte event = packet[1];
                
                switch (event) {
                    case WM_RPT_BTN:
                    {
                        /* button */
                        wiimote_pressed_buttons(wm, msg);
                        break;
                    }
                    case WM_RPT_READ:
                    {
                        /* data read */
                        
                        if(WIIMOTE_DBG)printf("WM_RPT_READ data arrive!\n");
                        
                        wiimote_pressed_buttons(wm, msg);
                        
                        byte err = msg[2] & 0x0F;
                        
                        if (err == 0x08)
                            printf("Unable to read data - address does not exist.\n");
                        else if (err == 0x07)
                            printf("Unable to read data - address is for write-only registers.\n");
                        else if (err)
                            printf("Unable to read data - unknown error code %x.\n", err);
                        
                        unsigned short offset = BIG_ENDIAN_SHORT(*(unsigned short*)(msg + 3));
                        
                        byte len = ((msg[2] & 0xF0) >> 4) + 1;
                        
                        byte *data = (msg + 5);
                        
                        if(WIIMOTE_DBG)
                        {
                            int i = 0;
                            printf("Read: 0x%04x ; ",offset);
                            for (; i < len; ++i)
                                printf("%x ", data[i]);
                            printf("\n");
                        }
                        
                        if(wiimote_handshake(wm,WM_RPT_READ,data,len))
                        {
                            //btUsed = 1;
                            //                            [inqViewControl showConnected:nil];
                            //                            [inqViewControl showConnecting:nil];
                            //Create UIAlertView alert
                            //                            [inqViewControl showConnecting:nil];
                            
                            /*                            UIAlertView* alert =
                             [[UIAlertView alloc] initWithTitle:@"Connection detected!"
                             message: [NSString stringWithFormat:@"%@ '%@' connection sucessfully completed!",
                             (wm->exp.type != EXP_NONE ? @"Classic Controller" : @"WiiMote"),
                             [NSNumber numberWithInt:(wm->unid)+1]]
                             delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
                             [alert show];
                             //[alert dismissWithClickedButtonIndex:0 animated:TRUE];
                             [alert release];
                             */
                            if(device!=nil)
                            {
                                [device setConnectionState:kBluetoothConnectionConnected];
                                device = nil;
                            }
                            [[BTstackManager sharedInstance] startDiscovery];
                        }
                        
                        return;
                    }
                    case WM_RPT_CTRL_STATUS:
                    {
                        wiimote_pressed_buttons(wm, msg);
                        
                        /* find the battery level and normalize between 0 and 1 */
                        if(WIIMOTE_DBG)
                        {
                            wm->battery_level = (msg[5] / (float)WM_MAX_BATTERY_CODE);
                            
                            printf("BATTERY LEVEL %d\n", wm->battery_level);
                        }
                        
                        //handshake stuff!
                        if(wiimote_handshake(wm,WM_RPT_CTRL_STATUS,msg,-1))
                        {
                            //btUsed = 1;
                            //                            [inqViewControl showConnected:nil];
                            //                            [inqViewControl showConnecting:nil];
                            /*                            UIAlertView* alert =
                             [[UIAlertView alloc] initWithTitle:@"Connection detected!"
                             message: [NSString stringWithFormat:@"WiiMote '%@' connection sucessfully completed!",[NSNumber numberWithInt:(wm->unid)+1]]
                             delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
                             [alert show];
                             //[alert dismissWithClickedButtonIndex:0 animated:TRUE];
                             [alert release];*/
                            [device setConnectionState:kBluetoothConnectionConnected];
                            
                            if(device!=nil)
                            {
                                [device setConnectionState:kBluetoothConnectionConnected];
                                device = nil;
                            }
                            [[BTstackManager sharedInstance] startDiscovery];
                        }
                        
                        return;
                    }
                    case WM_RPT_BTN_EXP:
                    {
                        /* button - expansion */
                        wiimote_pressed_buttons(wm, msg);
                        wiimote_handle_expansion(wm, msg+2);
                        
                        break;
                    }
                    case WM_RPT_WRITE:
                    {
                        /* write feedback - safe to skip */
                        break;
                    }
                    default:
                    {
                        printf("Unknown event, can not handle it [Code 0x%x].", event);
                        return;
                    }
                }
            }
            break;
        }
        case HCI_EVENT_PACKET://0x04
        {
            switch (packet[0]){
                    
                case L2CAP_EVENT_CHANNEL_OPENED:
                    
                    // data: event (8), len(8), status (8), address(48), handle (16), psm (16), local_cid(16), remote_cid (16)
                    if (packet[2] == 0) {
                        
                        // inform about new l2cap connection
                        bt_flip_addr(event_addr, &packet[3]);
                        uint16_t psm = READ_BT_16(packet, 11);
                        uint16_t source_cid = READ_BT_16(packet, 13);
                        wiiMoteConHandle = READ_BT_16(packet, 9);
                        //                        NSLog(@"Channel successfully opened: handle 0x%02x, psm 0x%02x, source cid 0x%02x, dest cid 0x%02x", wiiMoteConHandle, psm, source_cid,  READ_BT_16(packet, 15));
                        
                        if (psm == 0x13) {
                            
                            // interupt channel openedn succesfully, now open control channel, too.
                            if(WIIMOTE_DBG)printf("open control channel\n");
                            bt_send_cmd(&l2cap_create_channel, event_addr, 0x11);
                            struct wiimote_t *wm = NULL;
                            wm = &joys[num_of_joys];
                            memset(wm, 0, sizeof(struct wiimote_t));
                            wm->unid = num_of_joys;
                            wm->i_source_cid = source_cid;
                            memcpy(&wm->addr,&event_addr,BD_ADDR_LEN);
                            if(WIIMOTE_DBG)printf("addr %02x:%02x:%02x:%02x:%02x:%02x\n", wm->addr[0], wm->addr[1], wm->addr[2],wm->addr[3], wm->addr[4], wm->addr[5]);
                            if(WIIMOTE_DBG)printf("saved 0x%02x  0x%02x\n",source_cid,wm->i_source_cid);
                            wm->exp.type = EXP_NONE;
                            
                        } else {
                            
                            //inicializamos el wiimote!
                            struct wiimote_t *wm = NULL;
                            wm = &joys[num_of_joys];
                            wm->wiiMoteConHandle = wiiMoteConHandle;
                            wm->c_source_cid = source_cid;
                            wm->state = WIIMOTE_STATE_CONNECTED;
                            num_of_joys++;
                            if(WIIMOTE_DBG)printf("Devices Number: %d\n",num_of_joys);
                            wiimote_handshake(wm,-1,NULL,-1);
                        }
                    }
                    break;
                case L2CAP_EVENT_CHANNEL_CLOSED:
                {
                    // data: event (8), len(8), channel (16)
                    uint16_t  source_cid = READ_BT_16(packet, 2);
                    //NSLog(@"Channel successfully closed: cid 0x%02x",source_cid);
                    
                    bd_addr_t addr;
                    int unid = wiimote_remove(source_cid,&addr);
                    if(unid!=-1)
                    {
                        //                        [inqViewControl removeDeviceForAddress:&addr];
                        UIAlertView* alert =
                        [[UIAlertView alloc] initWithTitle:@"Disconnection!"
                                                   message:[NSString stringWithFormat:@"WiiMote '%@' disconnection detected.\nIs battery drainned?",[NSNumber numberWithInt:(unid+1)]]
                                                  delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
                        [alert show];
                        
                        [alert release];
                    }
                    
                }
                    break;
                    
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
	
}

//******************************************

-(void) emuThread {
    emuThread_running=1;
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    int argc=2;
    char *argv[2];
    argv[0]=(char*)malloc(5);
    if (!argv[0]) {
        NSLog(@"Error: cannot allocate argv[0]");
    }
    sprintf(argv[0],"%s","iFBA");
    argv[1]=(char*)malloc(strlen(gameName)+1);
    if (!argv[1]) {
        NSLog(@"Error: cannot allocate argv[1]");
    }
    sprintf(argv[1],"%s",gameName);
    
#ifdef TESTFLIGHT_BUILD
    //TFLog(@"Start game: %s",gameName);
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"Start game: %s",gameName]];
#endif
    
    fba_main(argc,(char**)argv);
    free (argv[0]);
    free (argv[1]);
    
    if ((launchGame==0)&&(glob_replay_mode==REPLAY_PLAYBACK_MODE)&&(glob_replay_data_index>=glob_replay_data_index_max)) {
        UIAlertView* alert =
        [[UIAlertView alloc] initWithTitle:@"Information"
                                   message:@"End of replay. Tap on 'MENU' button."
                                  delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
    
    [pool release];
    emuThread_running=0;
}

int vstick_update_status(int rx,int ry) {
    float angle;
    //compute distance
    float dist=(rx-cur_ifba_conf->vpad_pad_x[device_orientation])*(rx-cur_ifba_conf->vpad_pad_x[device_orientation])+(ry-cur_ifba_conf->vpad_pad_y[device_orientation])*(ry-cur_ifba_conf->vpad_pad_y[device_orientation]);
    
    
    //virtual_stick_pad=0; //Reset pad state
    joy_analog_x[0]=0;joy_analog_y[0]=0;
    if ((dist>virtual_stick_mindist2)&&(dist<virtual_stick_maxdist2)) {
        virtual_stick_pad=0; //Reset pad state
        //compute angle
        //        float rdist=sqrtf(dist);
        float dx=rx-cur_ifba_conf->vpad_pad_x[device_orientation];
        float dy=-ry+cur_ifba_conf->vpad_pad_y[device_orientation];
        if (dx!=0) {
            
            angle=atanf(dy/dx);
            if ((dx>=0)&&(dy>=0)) { //TOP RIGHT
                
            } else if ((dx<=0)&&(dy>=0)) { //TOP LEFT
                angle=M_PI+angle;
            } else if ((dx<=0)&&(dy<=0)) { //BOTTOM LEFT
                angle=M_PI+angle;
            } else if ((dx>=0)&&(dy<=0)) { //BOTTOM RIGHT
                angle=M_PI*2+angle;
            }
        } else {
            if (dy>0) angle=M_PI/2;
            else angle=M_PI*3/2;
        }
        virtual_stick_angle=angle;
        
        joy_analog_x[0]=dx*2/virtual_stick_maxdist;
        joy_analog_y[0]=dy*2/virtual_stick_maxdist;
        
        if ( ((virtual_stick_angle<M_PI*2)&&(virtual_stick_angle>=M_PI*2-M_PI/8))||((virtual_stick_angle<M_PI/8)&&(virtual_stick_angle>=0))) { //Right
            virtual_stick_pad=GN_RIGHT;
        } else if ((virtual_stick_angle>=-M_PI/8+M_PI/4)&&(virtual_stick_angle<M_PI/8+M_PI/4)) { //Up&Right
            virtual_stick_pad=GN_UPRIGHT;
        } else if ((virtual_stick_angle>=-M_PI/8+2*M_PI/4)&&(virtual_stick_angle<M_PI/8+2*M_PI/4)) { //Up
            virtual_stick_pad=GN_UP;
        } else if ((virtual_stick_angle>=-M_PI/8+3*M_PI/4)&&(virtual_stick_angle<M_PI/8+3*M_PI/4)) { //Up&Left
            virtual_stick_pad=GN_UPLEFT;
        } else if ((virtual_stick_angle>=-M_PI/8+4*M_PI/4)&&(virtual_stick_angle<M_PI/8+4*M_PI/4)) { //Left
            virtual_stick_pad=GN_LEFT;
        } else if ((virtual_stick_angle>=-M_PI/8+5*M_PI/4)&&(virtual_stick_angle<M_PI/8+5*M_PI/4)) { //Left&Down
            virtual_stick_pad=GN_DOWNLEFT;
        } else if ((virtual_stick_angle>=-M_PI/8+6*M_PI/4)&&(virtual_stick_angle<M_PI/8+6*M_PI/4)) { //Down
            virtual_stick_pad=GN_DOWN;
        } else if ((virtual_stick_angle>=-M_PI/8+7*M_PI/4)&&(virtual_stick_angle<M_PI/8+7*M_PI/4)) { //Down&Right
            virtual_stick_pad=GN_DOWNRIGHT;
        }
        //    printf("angle: %f pad:%02X\n",angle*180/M_PI,virtual_stick_pad);
    } else if (dist<virtual_stick_mindist2) {//deadzone
        virtual_stick_pad=0; //Reset pad state
        if (renderVPADonly) return 1;
        else return -1;
    } else if (dist>virtual_stick_maxdist2) return 0;
    
    if (renderVPADonly) {
        virtual_stick_pad=0;
        return 1;
    }
    return virtual_stick_pad;
}


void ios_fingerEvent(long touch_id, int evt_type, float x, float y,float lx,float ly) {
    //printf("%d/touch %08X, type %d, %f x %f\n",glob_touchpad_cnt,touch_id,evt_type,x,y);
    int ret;
    int new_vpad_button_nb=0;
    
    switch (evt_type) {
        case 1: //Pressed
            virtual_stick_on=1;
            glob_touchpad_cnt++;
            if (cur_ifba_conf->vpad_followfinger && glob_ffingeron) { //follow finger mode
                //check if finger is on a button
                int button_pressed=0;
                for (int i=0;i<vpad_button_nb;i++) {
                    if ((x>cur_ifba_conf->vpad_button_x[i][device_orientation])&&(x<cur_ifba_conf->vpad_button_x[i][device_orientation]+virtual_stick[i].w)&&
                        (y>cur_ifba_conf->vpad_button_y[i][device_orientation])&&(y<cur_ifba_conf->vpad_button_y[i][device_orientation]+virtual_stick[i].h)){
                        joy_state[0][virtual_stick[i].button_id]=1;
                        virtual_stick[i].finger_id=touch_id;
                        button_pressed=1;
                        
                        if (cur_ifba_conf->vpad_followfinger_firemode==0) {                        //check if last button pressed to change fire 1 mode (repetitive or full pressed)
                            if ((virtual_stick[i].button_id-GN_A)==(vpad_button_nb-VPAD_SPECIALS_BUTTON_NB-1)) glob_shootmode^=1;
                            else {
                                if (glob_ffingeron==1) {
                                    //cave 2 buttons style (shoot/laser | bomb
                                    switch (virtual_stick[i].button_id) {
                                        case GN_A: //shoot on/off
                                            glob_shooton^=1;
                                            break;
                                        case GN_SERVICE: //switch finger/normal touch control if at least 2 fingers press screen
                                            if (glob_touchpad_cnt==1) {
                                                joy_state[0][GN_SERVICE]=0;
                                                glob_ffingeron=0;
                                                new_vpad_button_nb=VPAD_SPECIALS_BUTTON_NB;//force recompute
                                            }
                                            break;
                                    }
                                } else if (glob_ffingeron==2) {
                                    //daioh style
                                    switch (virtual_stick[i].button_id) {
                                        case GN_A: //shoot on/off
                                            if (glob_shootmode==0) glob_shooton^=1;
                                            else {
                                                glob_shootmode=0;
                                                glob_shooton=1;
                                            }
                                            break;
                                        case GN_B:
                                            if (glob_shootmode==1) glob_shooton^=1;
                                            else {
                                                glob_shootmode=1;
                                                glob_shooton=1;
                                            }
                                            break;
                                        case GN_C:
                                            if (glob_shootmode==2) glob_shooton^=1;
                                            else {
                                                glob_shootmode=2;
                                                glob_shooton=1;
                                            }
                                            break;
                                        case GN_SERVICE: //switch finger/normal touch control if at least 2 fingers press screen
                                            if (glob_touchpad_cnt==1) {
                                                joy_state[0][GN_SERVICE]=0;
                                                glob_ffingeron=0;
                                                new_vpad_button_nb=VPAD_SPECIALS_BUTTON_NB;//force recompute
                                            }
                                            break;
                                    }
                                }
                            }
                        } else { //normal shoot mode, check if service is pressed
                            if (virtual_stick[i].button_id==GN_SERVICE) {
                                if (glob_touchpad_cnt==1) {
                                    joy_state[0][GN_SERVICE]=0;
                                    glob_ffingeron=0;
                                    new_vpad_button_nb=VPAD_SPECIALS_BUTTON_NB;//force recompute
                                }
                            }
                        }
                        //break;  //no break, allow 2 or more buttons with 1 finger
                    }
                }
                if ((!button_pressed)&&(glob_touchpad_fingerid==0)) {
                    glob_touchpad_fingerid=touch_id;
                    glob_pos_x=x;
                    glob_pos_y=y;
                    glob_mov_x=glob_mov_y=0;
                    glob_mov_init=1;
                    glob_pos_xi=x;
                    glob_pos_yi=y;
                }
            } else {
                if (vstick_update_status(x,y)>0) { //finger is on pad
                    //printf("padtouch %08X, type %d, %f x %f\n",touch_id,evt_type,x,y);
                    
                    joy_state[0][GN_UP]=(virtual_stick_pad==GN_UP?1:0);
                    joy_state[0][GN_DOWN]=(virtual_stick_pad==GN_DOWN?1:0);
                    joy_state[0][GN_LEFT]=(virtual_stick_pad==GN_LEFT?1:0);
                    joy_state[0][GN_RIGHT]=(virtual_stick_pad==GN_RIGHT?1:0);
                    joy_state[0][GN_UPRIGHT]=(virtual_stick_pad==GN_UPRIGHT?1:0);
                    joy_state[0][GN_DOWNRIGHT]=(virtual_stick_pad==GN_DOWNRIGHT?1:0);
                    joy_state[0][GN_UPLEFT]=(virtual_stick_pad==GN_UPLEFT?1:0);
                    joy_state[0][GN_DOWNLEFT]=(virtual_stick_pad==GN_DOWNLEFT?1:0);
                    virtual_stick_padfinger=touch_id;
                } else { //check if finger is on a button
                    for (int i=0;i<vpad_button_nb;i++) {
                        if ((x>cur_ifba_conf->vpad_button_x[i][device_orientation])&&(x<cur_ifba_conf->vpad_button_x[i][device_orientation]+virtual_stick[i].w)&&
                            (y>cur_ifba_conf->vpad_button_y[i][device_orientation])&&(y<cur_ifba_conf->vpad_button_y[i][device_orientation]+virtual_stick[i].h)){
                            joy_state[0][virtual_stick[i].button_id]=1;
                            virtual_stick[i].finger_id=touch_id;
                            //break;  //no break, allow 2 or more buttons with 1 finger
                            
                            if ((virtual_stick[i].button_id==GN_SERVICE)&&cur_ifba_conf->vpad_followfinger) {//switch finger/normal touch control
                                if (glob_touchpad_cnt==1) {
                                    joy_state[0][GN_SERVICE]=0;
                                    glob_ffingeron=cur_ifba_conf->vpad_followfinger;
                                    new_vpad_button_nb=VPAD_SPECIALS_BUTTON_NB;//force recompute
                                }
                            }
                        }
                    }
                }
            }
            break;
        case 2: //Moved
            virtual_stick_on=1;
            if (renderVPADonly) {
                if (touch_id==virtual_stick_padfinger) { //is it the finger on pad
                    cur_ifba_conf->vpad_pad_x[device_orientation]+=x-lx;
                    cur_ifba_conf->vpad_pad_y[device_orientation]+=y-ly;
                    cur_ifba_conf->vpad_pad_manual_layout[device_orientation]=1;
                } else {
                    for (int i=VPAD_SPECIALS_BUTTON_NB;i<vpad_button_nb;i++) {
                        if (virtual_stick[i].finger_id==touch_id) {
                            //move button
                            cur_ifba_conf->vpad_button_manual_layout[i][device_orientation]=1;
                            cur_ifba_conf->vpad_button_x[i][device_orientation]+=x-lx;
                            cur_ifba_conf->vpad_button_y[i][device_orientation]+=y-ly;
                            break;
                        }
                    }
                }
            } else {
                
                if (cur_ifba_conf->vpad_followfinger && glob_ffingeron) {
                    if (touch_id==glob_touchpad_fingerid) {
                        glob_pos_x=x;
                        glob_pos_y=y;
                        if (lx) {
                            glob_mov_x=x-lx;
                        }
                        if (ly) {
                            glob_mov_y=-(y-ly);
                        }
                    }
                } else {
                    if (touch_id==virtual_stick_padfinger) { //is it the finger on pad
                        if ((ret=vstick_update_status(x,y))<=0) {
                            if (ret<0) {
                                virtual_stick_padfinger=0;
                                joy_analog_x[0]=0;joy_analog_y[0]=0;
                                joy_state[0][GN_UP]=0;
                                joy_state[0][GN_DOWN]=0;
                                joy_state[0][GN_LEFT]=0;
                                joy_state[0][GN_RIGHT]=0;
                                joy_state[0][GN_UPRIGHT]=0;
                                joy_state[0][GN_DOWNRIGHT]=0;
                                joy_state[0][GN_UPLEFT]=0;
                                joy_state[0][GN_DOWNLEFT]=0;
                            }
                        } else {
                            joy_state[0][GN_UP]=(virtual_stick_pad==GN_UP?1:0);
                            joy_state[0][GN_DOWN]=(virtual_stick_pad==GN_DOWN?1:0);
                            joy_state[0][GN_LEFT]=(virtual_stick_pad==GN_LEFT?1:0);
                            joy_state[0][GN_RIGHT]=(virtual_stick_pad==GN_RIGHT?1:0);
                            joy_state[0][GN_UPRIGHT]=(virtual_stick_pad==GN_UPRIGHT?1:0);
                            joy_state[0][GN_DOWNRIGHT]=(virtual_stick_pad==GN_DOWNRIGHT?1:0);
                            joy_state[0][GN_UPLEFT]=(virtual_stick_pad==GN_UPLEFT?1:0);
                            joy_state[0][GN_DOWNLEFT]=(virtual_stick_pad==GN_DOWNLEFT?1:0);
                        }
                    } else if (virtual_stick_padfinger==0) {
                        if (vstick_update_status(x,y)) virtual_stick_padfinger=touch_id;
                        joy_state[0][GN_UP]=(virtual_stick_pad==GN_UP?1:0);
                        joy_state[0][GN_DOWN]=(virtual_stick_pad==GN_DOWN?1:0);
                        joy_state[0][GN_LEFT]=(virtual_stick_pad==GN_LEFT?1:0);
                        joy_state[0][GN_RIGHT]=(virtual_stick_pad==GN_RIGHT?1:0);
                        joy_state[0][GN_UPRIGHT]=(virtual_stick_pad==GN_UPRIGHT?1:0);
                        joy_state[0][GN_DOWNRIGHT]=(virtual_stick_pad==GN_DOWNRIGHT?1:0);
                        joy_state[0][GN_UPLEFT]=(virtual_stick_pad==GN_UPLEFT?1:0);
                        joy_state[0][GN_DOWNLEFT]=(virtual_stick_pad==GN_DOWNLEFT?1:0);
                    }
                    
                    for (int i=0;i<vpad_button_nb;i++) {
                        //is there a button already pressed with this finger ?
                        if (virtual_stick[i].finger_id==touch_id) {
                            //a button was pressed and finger moved
                            //check if finger is still in button area
                            
                            if ((x>cur_ifba_conf->vpad_button_x[i][device_orientation])&&(x<cur_ifba_conf->vpad_button_x[i][device_orientation]+virtual_stick[i].w)&&
                                (y>cur_ifba_conf->vpad_button_y[i][device_orientation])&&(y<cur_ifba_conf->vpad_button_y[i][device_orientation]+virtual_stick[i].h)) {
                                //break;  //no break, allow 2 or more buttons with 1 finger
                            } else {
                                //button not pressed anymore
                                //do not break to check if finger moved to a new button
                                virtual_stick[i].finger_id=0;
                                joy_state[0][virtual_stick[i].button_id]=0;
                            }
                        } else {
                            //did the finger move to a new button area ?
                            if ((x>cur_ifba_conf->vpad_button_x[i][device_orientation])&&(x<cur_ifba_conf->vpad_button_x[i][device_orientation]+virtual_stick[i].w)&&
                                (y>cur_ifba_conf->vpad_button_y[i][device_orientation])&&(y<cur_ifba_conf->vpad_button_y[i][device_orientation]+virtual_stick[i].h)){
                                joy_state[0][virtual_stick[i].button_id]=1;
                                virtual_stick[i].finger_id=touch_id;
                            }
                        }
                    }
                }
            }
            break;
        case 0: //Release
            virtual_stick_on=1;
            glob_touchpad_cnt--;
            if (glob_touchpad_cnt<0) glob_touchpad_cnt=0;
            if ((touch_id==glob_touchpad_fingerid)||(glob_touchpad_cnt==0)) {
                glob_touchpad_fingerid=0;
                glob_mov_x=glob_mov_y=0;
            }
            
            if (virtual_stick_padfinger==touch_id) {
                virtual_stick_padfinger=0;
                virtual_stick_pad=0;
                joy_analog_x[0]=0;joy_analog_y[0]=0;
                joy_state[0][GN_UP]=0;
                joy_state[0][GN_DOWN]=0;
                joy_state[0][GN_LEFT]=0;
                joy_state[0][GN_RIGHT]=0;
                joy_state[0][GN_UPRIGHT]=0;
                joy_state[0][GN_DOWNRIGHT]=0;
                joy_state[0][GN_UPLEFT]=0;
                joy_state[0][GN_DOWNLEFT]=0;
            }
            
            
            for (int i=0;i<VSTICK_NB_BUTTON;i++)
                if (virtual_stick[i].finger_id==touch_id) {
                    virtual_stick[i].finger_id=0;
                    joy_state[0][virtual_stick[i].button_id]=0;
                    //break;  //no break, allow 2 or more buttons with 1 finger
                }
            break;
    }
    
    if (new_vpad_button_nb) vpad_button_nb=new_vpad_button_nb;
    
    if (joy_state[0][GN_MENU_KEY]) nShouldExit=2;
    bAppDoFast=joy_state[0][GN_TURBO];
}


int StatedLoad(int slot);

void updateVbuffer(unsigned short *buff,int w,int h,int pitch,int rotated,int nXAspect,int nYAspect) {
    //DEBUG
    /*    static int lstate=1;
     if (lstate) {
     lstate=0;
     StatedLoad(0);
     }*/
    //DEBUG
    vid_rotated=rotated;
    visible_area_w=w;
    if (visible_area_w>TEXTURE_W) {
        NSLog(@"ERROR: width is too large (%d/%d)",visible_area_w,TEXTURE_W);
    }
    if (visible_area_h>TEXTURE_H) {
        NSLog(@"ERROR: width is too large (%d/%d)",visible_area_h,TEXTURE_H);
    }
    visible_area_h=h;
    vid_aspectX=nXAspect;
    vid_aspectY=nYAspect;
    pitch>>=1;
    unsigned short *src,*dst;
    src=buff;
    dst=vbuffer;
    for (int y=0;y<h;y++) {
        memcpy(dst,src,w<<1);
        dst+=TEXTURE_W;
        src+=pitch;
    }
    [(id) context doFrame];
}


- (void)drawVPad {
    int cur_width=m_oglView.frame.size.width;
    int cur_height=m_oglView.frame.size.height;
    
    virtual_stick_buttons_alpha=64*cur_ifba_conf->vpad_alpha;
    virtual_stick_buttons_alpha2=96*cur_ifba_conf->vpad_alpha;
    if (virtual_stick_buttons_alpha>255) virtual_stick_buttons_alpha=255;
    if (virtual_stick_buttons_alpha2>255) virtual_stick_buttons_alpha2=255;
    
    if (cur_ifba_conf->vpad_padsize==0) virtual_stick_maxdist=64;
    else if (cur_ifba_conf->vpad_padsize==1) virtual_stick_maxdist=80;
    else if (cur_ifba_conf->vpad_padsize==2) virtual_stick_maxdist=96;
    
    
    virtual_stick_maxdist2=virtual_stick_maxdist*virtual_stick_maxdist;
    virtual_stick_mindist2=virtual_stick_mindist*virtual_stick_mindist;
    
    if (vpad_button_nb_save!=vpad_button_nb) {
        computePadLayouts(vpad_button_nb-VPAD_SPECIALS_BUTTON_NB);
        vpad_button_nb_save=vpad_button_nb;
    }
    
    //update viewport to match real device screen
    
    glViewport(0, 0, cur_width, cur_height);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    /* Enable Vertex Pointer */
    texcoords[0][0]=0; texcoords[0][1]=0;
    texcoords[1][0]=1; texcoords[1][1]=0;
    texcoords[2][0]=0; texcoords[2][1]=1;
    texcoords[3][0]=1; texcoords[3][1]=1;
    
    for (int i=(cur_ifba_conf->vpad_showSpecial?0:VPAD_SPECIALS_BUTTON_NB);i<vpad_button_nb;i++) {
        if (renderVPADonly&&(i!=2)&&(i<VPAD_SPECIALS_BUTTON_NB)) continue;
        if ((i>=VPAD_SPECIALS_BUTTON_NB)&&(glob_replay_mode==REPLAY_PLAYBACK_MODE)) break;

        if (i>=VPAD_SPECIALS_BUTTON_NB) {
            glBindTexture(GL_TEXTURE_2D, vpad_button_texture[i-VPAD_SPECIALS_BUTTON_NB]);
        }
        else glBindTexture(GL_TEXTURE_2D, vpad_button_spe_texture[i]);
        //        }
        
        vertices[0][0]=(float)(cur_ifba_conf->vpad_button_x[i][device_orientation]+((virtual_stick[i].w-virtual_stick[i].sw)>>1))/cur_width;
        vertices[0][1]=(float)(cur_ifba_conf->vpad_button_y[i][device_orientation]+((virtual_stick[i].h-virtual_stick[i].sh)>>1))/cur_height;
        
        vertices[1][0]=vertices[0][0]+(float)(virtual_stick[i].sw)/cur_width;
        vertices[1][1]=(float)(cur_ifba_conf->vpad_button_y[i][device_orientation]+((virtual_stick[i].h-virtual_stick[i].sh)>>1))/cur_height;
        
        vertices[2][0]=(float)(cur_ifba_conf->vpad_button_x[i][device_orientation]+((virtual_stick[i].w-virtual_stick[i].sw)>>1))/cur_width;
        vertices[2][1]=vertices[0][1]+(float)(virtual_stick[i].sh)/cur_height;
        
        vertices[3][0]=vertices[0][0]+(float)(virtual_stick[i].sw)/cur_width;
        vertices[3][1]=vertices[0][1]+(float)(virtual_stick[i].sh)/cur_height;
        
        vertices[0][0]=vertices[0][0]*2-1;
        vertices[1][0]=vertices[1][0]*2-1;
        vertices[2][0]=vertices[2][0]*2-1;
        vertices[3][0]=vertices[3][0]*2-1;
        vertices[0][1]=-vertices[0][1]*2+1;
        vertices[1][1]=-vertices[1][1]*2+1;
        vertices[2][1]=-vertices[2][1]*2+1;
        vertices[3][1]=-vertices[3][1]*2+1;
        
        if (virtual_stick[i].finger_id) glColor4ub(virtual_stick[i].r,virtual_stick[i].g,virtual_stick[i].b,virtual_stick_buttons_alpha2);
        else glColor4ub(virtual_stick[i].r,virtual_stick[i].g,virtual_stick[i].b,virtual_stick_buttons_alpha);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    //now the stick
    
    if ((glob_ffingeron==0)&&(glob_replay_mode!=REPLAY_PLAYBACK_MODE)) {
        switch (cur_ifba_conf->vpad_style) {
            case 0: //animated pad
                glBindTexture(GL_TEXTURE_2D, vpad_animated_dpad[virtual_stick_pad]);    /* Bind The Texture */
                vertices[0][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]-virtual_stick_maxdist*0.9f)/cur_width;
                vertices[0][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]+virtual_stick_maxdist*0.9f)/cur_height;
                vertices[1][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]+virtual_stick_maxdist*0.9f)/cur_width;;
                vertices[1][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]+virtual_stick_maxdist*0.9f)/cur_height;
                vertices[2][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]-virtual_stick_maxdist*0.9f)/cur_width;
                vertices[2][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]-virtual_stick_maxdist*0.9f)/cur_height;
                vertices[3][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]+virtual_stick_maxdist*0.9f)/cur_width;
                vertices[3][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]-virtual_stick_maxdist*0.9f)/cur_height;
                
                vertices[0][0]=vertices[0][0]*2-1;
                vertices[1][0]=vertices[1][0]*2-1;
                vertices[2][0]=vertices[2][0]*2-1;
                vertices[3][0]=vertices[3][0]*2-1;
                vertices[0][1]=-vertices[0][1]*2+1;
                vertices[1][1]=-vertices[1][1]*2+1;
                vertices[2][1]=-vertices[2][1]*2+1;
                vertices[3][1]=-vertices[3][1]*2+1;
                glColor4ub(250,245,255,virtual_stick_buttons_alpha);
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
                break;
            case 1: //animated stick
                glBindTexture(GL_TEXTURE_2D, vpad_animated_stick[1]);    /* Bind The Texture */
                vertices[0][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]-virtual_stick_maxdist*0.9f)/cur_width;
                vertices[0][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]+virtual_stick_maxdist*0.9f)/cur_height;
                vertices[1][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]+virtual_stick_maxdist*0.9f)/cur_width;;
                vertices[1][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]+virtual_stick_maxdist*0.9f)/cur_height;
                vertices[2][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]-virtual_stick_maxdist*0.9f)/cur_width;
                vertices[2][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]-virtual_stick_maxdist*0.9f)/cur_height;
                vertices[3][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]+virtual_stick_maxdist*0.9f)/cur_width;
                vertices[3][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]-virtual_stick_maxdist*0.9f)/cur_height;
                
                vertices[0][0]=vertices[0][0]*2-1;
                vertices[1][0]=vertices[1][0]*2-1;
                vertices[2][0]=vertices[2][0]*2-1;
                vertices[3][0]=vertices[3][0]*2-1;
                vertices[0][1]=-vertices[0][1]*2+1;
                vertices[1][1]=-vertices[1][1]*2+1;
                vertices[2][1]=-vertices[2][1]*2+1;
                vertices[3][1]=-vertices[3][1]*2+1;
                glColor4ub(250,245,255,virtual_stick_buttons_alpha);
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
                
                switch (virtual_stick_pad) {
                    case 0:
                        virtual_stick_posx_ofs=0;virtual_stick_posy_ofs=0;
                        break;
                    case 1:
                        virtual_stick_posx_ofs=virtual_stick_maxdist*0.3f;virtual_stick_posy_ofs=0;
                        break;
                    case 2:
                        virtual_stick_posx_ofs=virtual_stick_maxdist*0.3f;virtual_stick_posy_ofs=-virtual_stick_maxdist*0.3f;
                        break;
                    case 3:
                        virtual_stick_posx_ofs=0;virtual_stick_posy_ofs=-virtual_stick_maxdist*0.3f;
                        break;
                    case 4:
                        virtual_stick_posx_ofs=-virtual_stick_maxdist*0.3f;virtual_stick_posy_ofs=-virtual_stick_maxdist*0.3f;
                        break;
                    case 5:
                        virtual_stick_posx_ofs=-virtual_stick_maxdist*0.3f;virtual_stick_posy_ofs=0;
                        break;
                    case 6:
                        virtual_stick_posx_ofs=-virtual_stick_maxdist*0.3f;virtual_stick_posy_ofs=virtual_stick_maxdist*0.3f;
                        break;
                    case 7:
                        virtual_stick_posx_ofs=0;virtual_stick_posy_ofs=virtual_stick_maxdist*0.3f;
                        break;
                    case 8:
                        virtual_stick_posx_ofs=virtual_stick_maxdist*0.3f;virtual_stick_posy_ofs=virtual_stick_maxdist*0.3f;
                        break;
                }
                
                
                glBindTexture(GL_TEXTURE_2D, vpad_animated_stick[0]);    /* Bind The Texture */
                vertices[0][0]=(float)(virtual_stick_posx_ofs+cur_ifba_conf->vpad_pad_x[device_orientation]-virtual_stick_maxdist*0.9f)/cur_width;
                vertices[0][1]=(float)(virtual_stick_posy_ofs+cur_ifba_conf->vpad_pad_y[device_orientation]+virtual_stick_maxdist*0.9f)/cur_height;
                vertices[1][0]=(float)(virtual_stick_posx_ofs+cur_ifba_conf->vpad_pad_x[device_orientation]+virtual_stick_maxdist*0.9f)/cur_width;;
                vertices[1][1]=(float)(virtual_stick_posy_ofs+cur_ifba_conf->vpad_pad_y[device_orientation]+virtual_stick_maxdist*0.9f)/cur_height;
                vertices[2][0]=(float)(virtual_stick_posx_ofs+cur_ifba_conf->vpad_pad_x[device_orientation]-virtual_stick_maxdist*0.9f)/cur_width;
                vertices[2][1]=(float)(virtual_stick_posy_ofs+cur_ifba_conf->vpad_pad_y[device_orientation]-virtual_stick_maxdist*0.9f)/cur_height;
                vertices[3][0]=(float)(virtual_stick_posx_ofs+cur_ifba_conf->vpad_pad_x[device_orientation]+virtual_stick_maxdist*0.9f)/cur_width;
                vertices[3][1]=(float)(virtual_stick_posy_ofs+cur_ifba_conf->vpad_pad_y[device_orientation]-virtual_stick_maxdist*0.9f)/cur_height;
                
                vertices[0][0]=vertices[0][0]*2-1;
                vertices[1][0]=vertices[1][0]*2-1;
                vertices[2][0]=vertices[2][0]*2-1;
                vertices[3][0]=vertices[3][0]*2-1;
                vertices[0][1]=-vertices[0][1]*2+1;
                vertices[1][1]=-vertices[1][1]*2+1;
                vertices[2][1]=-vertices[2][1]*2+1;
                vertices[3][1]=-vertices[3][1]*2+1;
                glColor4ub(250,245,255,virtual_stick_buttons_alpha);
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
                
                break;
            case 2: //not animated
                glBindTexture(GL_TEXTURE_2D, vpad_dpad_texture);    /* Bind The Texture */
                vertices[0][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]-virtual_stick_maxdist*0.9f)/cur_width;
                vertices[0][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]+virtual_stick_maxdist*0.9f)/cur_height;
                vertices[1][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]+virtual_stick_maxdist*0.9f)/cur_width;;
                vertices[1][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]+virtual_stick_maxdist*0.9f)/cur_height;
                vertices[2][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]-virtual_stick_maxdist*0.9f)/cur_width;
                vertices[2][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]-virtual_stick_maxdist*0.9f)/cur_height;
                vertices[3][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]+virtual_stick_maxdist*0.9f)/cur_width;
                vertices[3][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]-virtual_stick_maxdist*0.9f)/cur_height;
                
                vertices[0][0]=vertices[0][0]*2-1;
                vertices[1][0]=vertices[1][0]*2-1;
                vertices[2][0]=vertices[2][0]*2-1;
                vertices[3][0]=vertices[3][0]*2-1;
                vertices[0][1]=-vertices[0][1]*2+1;
                vertices[1][1]=-vertices[1][1]*2+1;
                vertices[2][1]=-vertices[2][1]*2+1;
                vertices[3][1]=-vertices[3][1]*2+1;
                glColor4ub(250,245,255,virtual_stick_buttons_alpha);
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
                break;
        }
    }
    
    
    
    glDisable(GL_TEXTURE_2D);
    
    if ((glob_ffingeron==0)&&(glob_replay_mode!=REPLAY_PLAYBACK_MODE)&&(cur_ifba_conf->vpad_style==2)) { //highlight direction
        for (int i=0;i<4;i++) {
            vertices[0][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]+0.9f*0.9f*virtual_stick_maxdist*cosf(i*M_PI/2))/cur_width;
            vertices[0][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]-0.9f*0.9f*virtual_stick_maxdist*sinf(i*M_PI/2))/cur_height;
            
            vertices[1][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]+0.6f*0.9f*virtual_stick_maxdist*cosf(i*M_PI/2+M_PI/8))/cur_width;
            vertices[1][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]-0.6f*0.9f*virtual_stick_maxdist*sinf(i*M_PI/2+M_PI/8))/cur_height;
            
            vertices[2][0]=(float)(cur_ifba_conf->vpad_pad_x[device_orientation]+0.6f*0.9f*virtual_stick_maxdist*cosf(i*M_PI/2-M_PI/8))/cur_width;
            vertices[2][1]=(float)(cur_ifba_conf->vpad_pad_y[device_orientation]-0.6f*0.9f*virtual_stick_maxdist*sinf(i*M_PI/2-M_PI/8))/cur_height;
            
            vertices[0][0]=vertices[0][0]*2-1;
            vertices[1][0]=vertices[1][0]*2-1;
            vertices[2][0]=vertices[2][0]*2-1;
            vertices[0][1]=-vertices[0][1]*2+1;
            vertices[1][1]=-vertices[1][1]*2+1;
            vertices[2][1]=-vertices[2][1]*2+1;
            
            
            if (virtual_stick_pad) {
                if (((virtual_stick_pad-1)>>1==i)||((((virtual_stick_pad)>>1)&3)==i)) glColor4ub(250,245,255,virtual_stick_buttons_alpha2);
                else glColor4ub(250,245,255,virtual_stick_buttons_alpha);
            } else glColor4ub(250,245,255,virtual_stick_buttons_alpha);
            
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 3);
        }
    }
    glDisable(GL_BLEND);
}

int ErrorWhileLoading(const char* pszText) {
    int strHeight=1;
    int i=0;
    while (pszText[i]) {
        if (pszText[i]<32) strHeight++;
        i++;
    }
    strcpy(statusMsg,pszText);
    statusMsgUpdated=1;
    
    usleep(3000000); //3s
    
}

int ProgressUpdateBurner(int nLen,int totalLen, const char* pszText) {
    if (totalLen<0) {
        if (pszText) strcpy(statusLoadMsg,pszText);
        else statusLoadMsg[0]=0;
        statusLoadMsgUpdated=1;
        return 0;
    }
    pb_total+=nLen;
    if (totalLen) {
        if (pb_total>totalLen) pb_total=totalLen;
        pb_value=(float)pb_total/(float)totalLen;
    } else {
        pb_total=0;
        pb_value=1;
    }
    
    if (pszText) strcpy(statusMsg,pszText);
    else statusMsg[0]=0;
    statusMsgUpdated=1;
    
    
    return 0;
}

int StopProgressBar() {
    pb_value=1;
    
    
}

-(void) loopCheck {
    static int msgCounter=0;
    
    if (renderVPADonly) [self doFrameVPAD];
    
    if (nShouldExit==2) {
        self.navigationController.navigationBar.hidden=NO;
        [[self navigationController] popViewControllerAnimated:NO];
    }
    
    if (prgview) {
        if (pb_value<1) {
            msgCounter=60; //2seconds
            prgview.progress=pb_value;
            if (statusMsgUpdated) {
                statusMsgview.text=[NSString stringWithFormat:@"%s",statusMsg];
                statusMsgUpdated=0;
            }
            if (statusLoadMsgUpdated) {
                statusLoadMsgview.text=[NSString stringWithFormat:@"%s",statusLoadMsg];
                statusLoadMsgUpdated=0;
            }
        } else {
            if (msgCounter>0) {
                msgCounter--;
                if (msgCounter<60) {
                    prgview.alpha=msgCounter*1.0f/60.0f;
                    statusDownview.alpha=msgCounter*1.0f/60.0f;
                    statusview.alpha=msgCounter*1.0f/60.0f;
                }
            }
            else {
                [prgview removeFromSuperview];
                prgview=nil;
                [statusMsgview removeFromSuperview];
                statusMsgview=nil;
                [statusview removeFromSuperview];
                statusview=nil;
                [statusLoadMsgview removeFromSuperview];
                statusLoadMsgview=nil;
                [statusDownview removeFromSuperview];
                statusDownview=nil;
            }
        }
    }
    
}


- (void)doFrame {
    
    int width,height,rw,rh;
    float zf;
    
    
    if (doFrame_inProgress) return;
    doFrame_inProgress=1;
    
    if (virtual_stick_on==0) {
        //analog patch
        float fincr=0.1f;
        for (int i=0;i<MAX_JOYSTICKS;i++) {
            if (joy_state[i][GN_LEFT]) {
                if (patch_analog_x[i]>-1) patch_analog_x[i]-=fincr;
                else patch_analog_x[i]=-1;
            }
            if (joy_state[i][GN_RIGHT]) {
                if (patch_analog_x[i]<1) patch_analog_x[i]+=fincr;
                else patch_analog_x[i]=1;
            }
            if ( !(joy_state[i][GN_LEFT]||joy_state[i][GN_RIGHT]) ) {
                if (patch_analog_x[i]>0) patch_analog_x[i]-=fincr;
                if (patch_analog_x[i]<0) patch_analog_x[i]+=fincr;
            }
            if (joy_state[i][GN_DOWN]) {
                if (patch_analog_y[i]>-1) patch_analog_y[i]-=fincr;
                else patch_analog_y[i]=-1;
            }
            if (joy_state[i][GN_UP]) {
                if (patch_analog_y[i]<1) patch_analog_y[i]+=fincr;
                else patch_analog_y[i]=1;
            }
            if ( !(joy_state[i][GN_UP]||joy_state[i][GN_DOWN]) ) {
                if (patch_analog_y[i]>0) patch_analog_y[i]-=fincr;
                if (patch_analog_y[i]<0) patch_analog_y[i]+=fincr;
            }
            joy_analog_x[i]=patch_analog_x[i];
            joy_analog_y[i]=patch_analog_y[i];
        }
    }
    
    //get ogl context & bind
    
    [EAGLContext setCurrentContext:m_oglContext];
	[m_oglView bind];
    
    
    width=m_oglView.frame.size.width;
    height=m_oglView.frame.size.height;
    
    /**********************************/
    /* Redraw */
    /**********************************/
    
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, txt_vbuffer);    /* Bind The Texture */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (cur_ifba_conf->filtering?GL_LINEAR:GL_NEAREST) );
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (cur_ifba_conf->filtering?GL_LINEAR:GL_NEAREST));
    
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, TEXTURE_W, TEXTURE_H, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, vbuffer);
    
    /* Begin Drawing Quads, setup vertex and texcoord array pointers */
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
    
    /* Enable Vertex Pointer */
    glEnableClientState(GL_VERTEX_ARRAY);
    /* Enable Texture Coordinations Pointer */
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glColor4ub(255,255,255,255);
    
    switch (vid_rotated) {
        case 0:
            texcoords[0][0]=(float)0/TEXTURE_W; texcoords[0][1]=(float)0/TEXTURE_H;
            texcoords[1][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[1][1]=(float)0/TEXTURE_H;
            texcoords[2][0]=(float)0/TEXTURE_W; texcoords[2][1]=(float)(visible_area_h)/TEXTURE_H;
            texcoords[3][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[3][1]=(float)(visible_area_h)/TEXTURE_H;
            break;
        case 2:
            texcoords[0][0]=(float)0/TEXTURE_W; texcoords[0][1]=(float)0/TEXTURE_H;
            texcoords[1][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[1][1]=(float)0/TEXTURE_H;
            texcoords[2][0]=(float)0/TEXTURE_W; texcoords[2][1]=(float)(visible_area_h)/TEXTURE_H;
            texcoords[3][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[3][1]=(float)(visible_area_h)/TEXTURE_H;
            break;
        case 1:
            texcoords[0][0]=(float)0/TEXTURE_W; texcoords[0][1]=(float)(visible_area_h)/TEXTURE_H;
            texcoords[1][0]=(float)0/TEXTURE_W; texcoords[1][1]=(float)0/TEXTURE_H;
            texcoords[2][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[2][1]=(float)(visible_area_h)/TEXTURE_H;
            texcoords[3][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[3][1]=(float)0/TEXTURE_H;
            break;
        case 3:
            texcoords[0][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[0][1]=(float)0/TEXTURE_H;
            texcoords[1][0]=(float)(visible_area_w)/TEXTURE_W; texcoords[1][1]=(float)(visible_area_h)/TEXTURE_H;
            texcoords[2][0]=(float)0/TEXTURE_W; texcoords[2][1]=(float)0/TEXTURE_H;
            texcoords[3][0]=(float)0/TEXTURE_W; texcoords[3][1]=(float)(visible_area_h)/TEXTURE_H;
            break;
    }
    float ios_aspect=(float)width/(float)height;
    float game_aspect=(float)vid_aspectX/(float)vid_aspectY;
    
    switch (cur_ifba_conf->screen_mode) {
        case 0://org
            if (ios_aspect>game_aspect) {
                if (vid_rotated&1) {
                    rh=min(height,visible_area_w);
                    rw=rh*(cur_ifba_conf->aspect_ratio?game_aspect:ios_aspect);
                } else {
                    rh=min(height,visible_area_h);
                    rw=rh*(cur_ifba_conf->aspect_ratio?game_aspect:ios_aspect);
                }
                
            } else {
                if (vid_rotated&1) {
                    rw=min(width,visible_area_h);
                    rh=rw/(cur_ifba_conf->aspect_ratio?game_aspect:ios_aspect);
                } else {
                    rw=min(width,visible_area_w);
                    rh=rw/(cur_ifba_conf->aspect_ratio?game_aspect:ios_aspect);
                }
            }
            break;
        case 1://max with room for vpad
            if (ios_aspect>game_aspect) {
                rh=height-virtual_stick_maxdist*(device_isIpad?2.5f:1.2f);
                rw=rh*(cur_ifba_conf->aspect_ratio?game_aspect:ios_aspect);
            } else {
                rh=height-virtual_stick_maxdist*(device_isIpad?2.5f:1.2f);
                rw=rh*(cur_ifba_conf->aspect_ratio?game_aspect:ios_aspect);
                if (rw>width) {
                    rw=width;
                    rh=rw/(cur_ifba_conf->aspect_ratio?game_aspect:ios_aspect);
                }
            }
            break;
        case 2://max with margin on sides
            if (ios_aspect>game_aspect) {
                rh=height*0.9;
                rw=rh*(cur_ifba_conf->aspect_ratio?game_aspect:ios_aspect);
            } else {
                rh=height*0.9;
                rw=rh*(cur_ifba_conf->aspect_ratio?game_aspect:ios_aspect);
                if (rw>width*0.9) {
                    rw=width*0.9;
                    rh=rw/(cur_ifba_conf->aspect_ratio?game_aspect:ios_aspect);
                }
            }
            break;
        case 3://full
            if (ios_aspect>game_aspect) {
                rh=height;
                rw=rh*(cur_ifba_conf->aspect_ratio?game_aspect:ios_aspect);
                
            } else {
                rw=width;
                rh=rw/(cur_ifba_conf->aspect_ratio?game_aspect:ios_aspect);
            }
            break;
    }
    
    if (vid_rotated&1) {
        glob_scr_ratioX=(float)visible_area_h/rw*cur_ifba_conf->vpad_followfinger_sensibility;
        glob_scr_ratioY=(float)visible_area_w/rh*cur_ifba_conf->vpad_followfinger_sensibility;
    } else {
        glob_scr_ratioX=(float)visible_area_w/rw*cur_ifba_conf->vpad_followfinger_sensibility;
        glob_scr_ratioY=(float)visible_area_h/rh*cur_ifba_conf->vpad_followfinger_sensibility;
    }
    //    static int yoyo=0;
    //    yoyo++;
    //    if ((yoyo%60)==0) NSLog(@"%d x %d / %d x %d / %f %f",rw,rh,visible_area_w,visible_area_h,glob_scr_ratioX,glob_scr_ratioY);
    
    glViewport((width-rw)>>1, height-rh, rw, rh);
    if (vid_rotated&&(pb_value==1)) {
        vertices[0][0]=1; vertices[0][1]=-1;
        vertices[1][0]=-1; vertices[1][1]=-1;
        vertices[2][0]=1; vertices[2][1]=1;
        vertices[3][0]=-1; vertices[3][1]=1;
    } else {
        vertices[0][0]=-1; vertices[0][1]=1;
        vertices[1][0]=1; vertices[1][1]=1;
        vertices[2][0]=-1; vertices[2][1]=-1;
        vertices[3][0]=1; vertices[3][1]=-1;
    }
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    switch (cur_ifba_conf->video_filter) {
        case 0:break;
        case 1:
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            /* Enable Vertex Pointer */
            texcoords[0][0]=0; texcoords[0][1]=0;
            texcoords[1][0]=1.0f*rw/32.0f; texcoords[1][1]=0;
            texcoords[2][0]=0; texcoords[2][1]=1.0f*rh/32.0f;
            texcoords[3][0]=1.0f*rw/32.0f; texcoords[3][1]=1.0f*rh/32.0f;
            glBindTexture(GL_TEXTURE_2D, filter_scanline_texture);    /* Bind The Texture */
            glColor4ub(255,255,255,cur_ifba_conf->video_filter_strength);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            glDisable(GL_BLEND);
            break;
        case 2:
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glColor4ub(255,255,255,cur_ifba_conf->video_filter_strength);
            /* Enable Vertex Pointer */
            zf=1.0f;
            texcoords[0][0]=0; texcoords[0][1]=0;
            texcoords[1][0]=1.0f*rw*zf/8.0f; texcoords[1][1]=0;
            texcoords[2][0]=0; texcoords[2][1]=1.0f*rh*zf/8.0f;
            texcoords[3][0]=1.0f*rw*zf/8.0f; texcoords[3][1]=1.0f*rh*zf/8.0f;
            glBindTexture(GL_TEXTURE_2D, filter_crt_texture);    /* Bind The Texture */
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            glDisable(GL_BLEND);
            break;
    }
    
    if (virtual_stick_on/*&&(glob_replay_mode!=REPLAY_PLAYBACK_MODE)*/) [self drawVPad];
    [m_oglContext presentRenderbuffer:GL_RENDERBUFFER_OES];
    
    //get time
    long long cur_clock=clock();
    long long cur_delta=cur_clock-playtime_lastclock;
    if (cur_delta<0) cur_delta=0;
    playtime+=cur_delta;
    playtime_lastclock=cur_clock;
    //if (!((playtime_upd++)&31)) NSLog(@"%d",playtime/CLOCKS_PER_SEC);
    
    doFrame_inProgress=0;
}

- (void)doFrameVPAD {
    
    int width,height;
    
    if (emuThread_running) {
        [self doFrame];
        return;
    }
    
    
    if (doFrame_inProgress) return;
    doFrame_inProgress=1;
    
    //get ogl context & bind
    
    [EAGLContext setCurrentContext:m_oglContext];
	[m_oglView bind];
    
    
    width=m_oglView.frame.size.width;
    height=m_oglView.frame.size.height;
    
    /**********************************/
    /* Redraw */
    /**********************************/
    
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnable(GL_TEXTURE_2D);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (cur_ifba_conf->filtering?GL_LINEAR:GL_NEAREST) );
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (cur_ifba_conf->filtering?GL_LINEAR:GL_NEAREST));
    
    
    /* Begin Drawing Quads, setup vertex and texcoord array pointers */
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
    
    /* Enable Vertex Pointer */
    glEnableClientState(GL_VERTEX_ARRAY);
    /* Enable Texture Coordinations Pointer */
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glColor4ub(255,255,255,255);
    
    [self drawVPad];
    [m_oglContext presentRenderbuffer:GL_RENDERBUFFER_OES];
    
    doFrame_inProgress=0;
}


///////////////////////////////////////////////////////////////////
int SaveReplay(int slot) {
    FILE *f;
    char szName[256];
#ifdef RELEASE_DEBUG
    sprintf(szName, "%s/%s.%02d.replay", debug_root_path,gameName,slot);
#else
    sprintf(szName, "/var/mobile/Documents/iFBA/%s.%02d.replay", gameName,slot);
#endif
    glob_framecpt_max=glob_framecpt;
    glob_replay_data_index_max=glob_replay_data_index;
    
    f=fopen(szName,"wb");
    if (!f) {
        NSLog(@"cannot save replay");
        return -1;
    } else {
        char szHeader[7]="iFBAXX";
        szHeader[4]=iFBA_VERSION_MAJOR+48;
        szHeader[5]=iFBA_VERSION_MINOR+48;
        fwrite(szHeader,6,1,f);
        glob_framecpt_max=glob_framecpt;
        fwrite((void*)&glob_framecpt_max,sizeof(glob_framecpt_max),1,f);
        //        NSLog(@"Saving: %dKB",glob_replay_data_index_max/1024);
        
        fwrite((void*)&glob_replay_data_index_max,sizeof(glob_replay_data_index_max),1,f);
        fwrite((void*)&nBurnFPS,sizeof(nBurnFPS),1,f);
        fwrite((void*)glob_replay_data_stream,glob_replay_data_index_max,1,f);
        fclose(f);
    }
    return 0;
}
int LoadReplay(int slot) {
    FILE *f;
    char szName[256];
#ifdef RELEASE_DEBUG
    sprintf(szName, "%s/%s.%02d.replay", debug_root_path,gameName,slot);
#else
    sprintf(szName, "/var/mobile/Documents/iFBA/%s.%02d.replay", gameName,slot);
#endif
    
    f=fopen(szName,"rb");
    if (!f) {
        NSLog(@"cannot read replay");
        return -1;
    } else {
        char szHeader[7];
        signed int tmpFPS;
        fread(szHeader,6,1,f);
        szHeader[6]=0;
        //        NSLog(@"File header: %s",szHeader);
        fread((void*)&glob_framecpt_max,sizeof(glob_framecpt_max),1,f);
        fread((void*)&glob_replay_data_index_max,sizeof(glob_replay_data_index_max),1,f);
        fread((void*)&tmpFPS,sizeof(tmpFPS),1,f);
        if (glob_replay_data_index_max>MAX_REPLAY_DATA_BYTES) {
            NSLog(@"Replay file corrupted: wrong max value for replay_index_max");
            fclose(f);
            return -2;
        } else {
            //            NSLog(@"Loading: %dKB / FPS: %d / Estimated running time: %d:%02d",glob_replay_data_index_max/1024,tmpFPS,glob_framecpt_max*100/tmpFPS/60,(glob_framecpt_max*100/tmpFPS)%60);
#ifdef TESTFLIGHT_BUILD
            [TestFlight passCheckpoint:@"Load replay"];
#endif
            fread((void*)glob_replay_data_stream,glob_replay_data_index_max,1,f);
            
        }
        fclose(f);
    }
    return 0;
}

@end
