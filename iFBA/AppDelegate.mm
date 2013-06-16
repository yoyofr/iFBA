//
//  AppDelegate.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

char debug_root_path[512];
char debug_bundle_path[512];
int lowmem_device;

static float sys_brightness;


#define VERSION_SETTINGS 2

#import <mach/mach.h>
#import <mach/mach_host.h>
#include <sys/types.h>
#include <sys/sysctl.h>

#include "TestFlight.h"

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#import "MenuViewController.h"
#import "fbaconf.h"
#import "burner.h"

extern int nShouldExit;
extern char szAppRomPaths[DIRS_MAX][MAX_PATH];
extern char gameName[64];
extern t_button_map joymap_wiimote[MAX_JOYSTICKS][VSTICK_NB_BUTTON];

extern int device_isIpad;
extern int device_retina;

UIScreen *cur_screen;

@implementation AppDelegate

@synthesize window = _window;
@synthesize navController = _navController;

- (int)loadSettings {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSNumber *valNb;
    NSString *valStr,*keyStr;
    int reset_settings=0;
    
    memset(&ifba_conf,0,sizeof(ifba_conf_t));
    
    //TEMP HACK
    for (int i=0;i<MAX_JOYSTICKS;i++) {
        ifba_conf.vpad_analog_speed[i][0]=1;
        ifba_conf.vpad_analog_speed[i][1]=1;
        ifba_conf.vpad_analog_speed[i][2]=4;
        ifba_conf.vpad_analog_speed[i][3]=4;
    }
    
    valNb=[prefs objectForKey:@"VERSION_SETTINGS"];
	if (valNb == nil) reset_settings=1;
    else if ([valNb intValue]!=VERSION_SETTINGS) reset_settings=1;
#define GET_VALNB(a) \
valNb=[prefs objectForKey:a];
	
    
    //Last game
    gameName[0]=0;    
    
    valStr=[prefs objectForKey:@"lastgame"];
    if (valStr != nil) strcpy(gameName,[valStr UTF8String]);
    else gameName[0]=0;
    
    //Gamebrowser settings
    valNb=[prefs objectForKey:@"filter_type"];
    if ((valNb == nil)||reset_settings) ifba_conf.filter_type=0; //Default is list by name
    else ifba_conf.filter_type = [valNb intValue];
    valNb=[prefs objectForKey:@"filter_missing"];
    if ((valNb == nil)||reset_settings) ifba_conf.filter_missing=0;
    else ifba_conf.filter_missing = [valNb intValue];
    valNb=[prefs objectForKey:@"filter_genre"];
    if ((valNb == nil)||reset_settings) ifba_conf.filter_genre=0xFFFFFFFF^GBF_BIOS; //Default is everything but the BIOS
    else ifba_conf.filter_genre = [valNb intValue];  
    
    //Roms paths
    for (int i=0;i<DIRS_MAX;i++) {        
        valStr=[prefs objectForKey:[NSString stringWithFormat:@"romspath%02X",i]];
        if (valStr != nil) strcpy(szAppRomPaths[i],[valStr UTF8String]);
        else szAppRomPaths[i][0]=0;
        //Recreate dir if not existing
        if (szAppRomPaths[i][0]) {
            //NSLog(@"%s",szAppRomPaths[i]);
            [[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%s",szAppRomPaths[i]] withIntermediateDirectories:TRUE attributes:nil error:nil];
            
        }
    }
    
    
    GET_VALNB(@"btstack_on")
	if ((valNb == nil)||reset_settings) ifba_conf.btstack_on=0;
	else ifba_conf.btstack_on = [valNb intValue];
    GET_VALNB(@"icade_lang")
	if ((valNb == nil)||reset_settings) ifba_conf.icade_lang=0;
	else ifba_conf.icade_lang = [valNb intValue];
    
    
    //Video settings
    GET_VALNB(@"video_fskip")
	if ((valNb == nil)||reset_settings) ifba_conf.video_fskip=10; //AUTO
	else ifba_conf.video_fskip = [valNb intValue];
    GET_VALNB(@"video_60hz")
	if ((valNb == nil)||reset_settings) ifba_conf.video_60hz=0;
	else ifba_conf.video_60hz = [valNb intValue];    
    GET_VALNB(@"aspect_ratio")
	if ((valNb == nil)||reset_settings) ifba_conf.aspect_ratio=1;
	else ifba_conf.aspect_ratio = [valNb intValue];
    GET_VALNB(@"screen_mode")
	if ((valNb == nil)||reset_settings) ifba_conf.screen_mode=1;
	else ifba_conf.screen_mode = [valNb intValue];
    GET_VALNB(@"filtering")
	if ((valNb == nil)||reset_settings) ifba_conf.filtering=1;
	else ifba_conf.filtering = [valNb intValue];
    GET_VALNB(@"brightness")
	if ((valNb == nil)||reset_settings) {
        if ([cur_screen respondsToSelector:@selector(setBrightness:)]) ifba_conf.brightness=cur_screen.brightness;
        else ifba_conf.brightness=0.5f;
    }
	else ifba_conf.brightness = [valNb floatValue];        
    GET_VALNB(@"show_fps")
	if ((valNb == nil)||reset_settings) ifba_conf.show_fps=0;
	else ifba_conf.show_fps = [valNb intValue];
    GET_VALNB(@"video_filter")
	if ((valNb == nil)||reset_settings) ifba_conf.video_filter=0;
	else ifba_conf.video_filter = [valNb intValue];
    GET_VALNB(@"video_filter_strength")
	if ((valNb == nil)||reset_settings) ifba_conf.video_filter_strength=32;
	else ifba_conf.video_filter_strength = [valNb intValue];
    
    
    //Sound settings
    GET_VALNB(@"sound_on")
	if ((valNb == nil)||reset_settings) ifba_conf.sound_on=1;
	else ifba_conf.sound_on = [valNb intValue];
    GET_VALNB(@"sound_freq")
	if ((valNb == nil)||reset_settings) ifba_conf.sound_freq=0;
	else ifba_conf.sound_freq = [valNb intValue];
    GET_VALNB(@"sound_latency")
	if ((valNb == nil)||reset_settings) ifba_conf.sound_latency=1;
	else ifba_conf.sound_latency = [valNb intValue];
    
    //Controls settings
    GET_VALNB(@"vpad_alpha")
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_alpha=2;
	else ifba_conf.vpad_alpha = [valNb intValue];
    GET_VALNB(@"vpad_showSpecial")
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_showSpecial=1;
	else ifba_conf.vpad_showSpecial = [valNb intValue];
    GET_VALNB(@"vpad_btnsize")
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_btnsize=1;
	else ifba_conf.vpad_btnsize = [valNb intValue];
    GET_VALNB(@"vpad_padsize")
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_padsize=1;
	else ifba_conf.vpad_padsize = [valNb intValue];
    GET_VALNB(@"vpad_style")
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_style=0;
	else ifba_conf.vpad_style = [valNb intValue];
    GET_VALNB(@"vpad_followfinger")
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_followfinger=0;
	else ifba_conf.vpad_followfinger = [valNb intValue];
    
    
    //Emulation settings
    GET_VALNB(@"asm_68k")
	if ((valNb == nil)||reset_settings) ifba_conf.asm_68k=1;
	else ifba_conf.asm_68k = [valNb intValue];
    GET_VALNB(@"asm_z80")
	if ((valNb == nil)||reset_settings) ifba_conf.asm_z80=0;
	else ifba_conf.asm_z80 = [valNb intValue];
    GET_VALNB(@"asm_nec")
	if ((valNb == nil)||reset_settings) ifba_conf.asm_nec=0;
	else ifba_conf.asm_nec = [valNb intValue];
    GET_VALNB(@"asm_sh2")
	if ((valNb == nil)||reset_settings) ifba_conf.asm_sh2=0;
	else ifba_conf.asm_sh2 = [valNb intValue];
    
    //Controls mapping
    for (int i=0;i<MAX_JOYSTICKS;i++) 
        for (int j=0;j<VSTICK_NB_BUTTON;j++) {
            keyStr=[NSString stringWithFormat:@"wiimap%02X%02X",i,j];
            valNb=[prefs objectForKey:keyStr];
            if (valNb != nil) ifba_conf.joymap_wiimote[i][j].dev_btn=[valNb intValue];
            else ifba_conf.joymap_wiimote[i][j].dev_btn=default_joymap_wiimote[i][j].dev_btn;
            
            keyStr=[NSString stringWithFormat:@"wiimap_str%02X%02X",i,j];
            valStr=[prefs objectForKey:keyStr];            
            if (valStr != nil) strncpy(ifba_conf.joymap_wiimote[i][j].btn_name,[valStr UTF8String],sizeof(ifba_conf.joymap_wiimote[i][j].btn_name)-1);
            else strcpy(ifba_conf.joymap_wiimote[i][j].btn_name,default_joymap_wiimote[i][j].btn_name);
        }
    for (int j=0;j<VSTICK_NB_BUTTON;j++) {
        keyStr=[NSString stringWithFormat:@"icademap%02X",j];
        valNb=[prefs objectForKey:keyStr];
        if (valNb != nil) ifba_conf.joymap_iCade[j].dev_btn=[valNb intValue];
        else ifba_conf.joymap_iCade[j].dev_btn=default_joymap_iCade[j].dev_btn;
        
        keyStr=[NSString stringWithFormat:@"icademap_str%02X",j];
        valStr=[prefs objectForKey:keyStr];        
        if (valStr != nil) strncpy(ifba_conf.joymap_iCade[j].btn_name,[valStr UTF8String],sizeof(ifba_conf.joymap_iCade[j].btn_name)-1);
        else strcpy(ifba_conf.joymap_iCade[j].btn_name,default_joymap_iCade[j].btn_name);
    }
    
    //TOUCHPAD
    for (int j=0;j<VSTICK_NB_BUTTON;j++) {
        keyStr=[NSString stringWithFormat:@"vpad_button_manual_layout%02X_0",j];
        valNb=[prefs objectForKey:keyStr];        
        if (valNb != nil) ifba_conf.vpad_button_manual_layout[j][0]=[valNb intValue];
        else ifba_conf.vpad_button_manual_layout[j][0]=0;        
        keyStr=[NSString stringWithFormat:@"vpad_button_manual_layout%02X_1",j];
        valNb=[prefs objectForKey:keyStr];        
        if (valNb != nil) ifba_conf.vpad_button_manual_layout[j][1]=[valNb intValue];
        else ifba_conf.vpad_button_manual_layout[j][1]=0;
        
        keyStr=[NSString stringWithFormat:@"vpad_button_x%02X_0",j];
        valNb=[prefs objectForKey:keyStr];        
        if (valNb != nil) ifba_conf.vpad_button_x[j][0]=[valNb floatValue];
        else ifba_conf.vpad_button_manual_layout[j][0]=0;
        keyStr=[NSString stringWithFormat:@"vpad_button_x%02X_1",j];
        valNb=[prefs objectForKey:keyStr];        
        if (valNb != nil) ifba_conf.vpad_button_x[j][1]=[valNb floatValue];
        else ifba_conf.vpad_button_manual_layout[j][1]=0;
        
        keyStr=[NSString stringWithFormat:@"vpad_button_y%02X_0",j];
        valNb=[prefs objectForKey:keyStr];        
        if (valNb != nil) ifba_conf.vpad_button_y[j][0]=[valNb floatValue];
        else ifba_conf.vpad_button_manual_layout[j][0]=0;
        keyStr=[NSString stringWithFormat:@"vpad_button_y%02X_1",j];
        valNb=[prefs objectForKey:keyStr];        
        if (valNb != nil) ifba_conf.vpad_button_y[j][1]=[valNb floatValue];
        else ifba_conf.vpad_button_manual_layout[j][1]=0;
        
    }
    keyStr=[NSString stringWithFormat:@"vpad_pad_manual_layout_0"];
    valNb=[prefs objectForKey:keyStr];        
    if (valNb != nil) ifba_conf.vpad_pad_manual_layout[0]=[valNb intValue];
    else ifba_conf.vpad_pad_manual_layout[0]=0;
    keyStr=[NSString stringWithFormat:@"vpad_pad_manual_layout_1"];
    valNb=[prefs objectForKey:keyStr];        
    if (valNb != nil) ifba_conf.vpad_pad_manual_layout[1]=[valNb intValue];
    else ifba_conf.vpad_pad_manual_layout[1]=0;
    
    keyStr=[NSString stringWithFormat:@"vpad_pad_x_0"];
    valNb=[prefs objectForKey:keyStr];        
    if (valNb != nil) ifba_conf.vpad_pad_x[0]=[valNb floatValue];
    else ifba_conf.vpad_pad_manual_layout[0]=0;
    keyStr=[NSString stringWithFormat:@"vpad_pad_x_1"];
    valNb=[prefs objectForKey:keyStr];        
    if (valNb != nil) ifba_conf.vpad_pad_x[1]=[valNb floatValue];
    else ifba_conf.vpad_pad_manual_layout[1]=0;
    
    keyStr=[NSString stringWithFormat:@"vpad_pad_y_0"];
    valNb=[prefs objectForKey:keyStr];        
    if (valNb != nil) ifba_conf.vpad_pad_y[0]=[valNb floatValue];
    else ifba_conf.vpad_pad_manual_layout[0]=0;
    keyStr=[NSString stringWithFormat:@"vpad_pad_y_1"];
    valNb=[prefs objectForKey:keyStr];        
    if (valNb != nil) ifba_conf.vpad_pad_y[1]=[valNb floatValue];
    else ifba_conf.vpad_pad_manual_layout[1]=0;
    
    
#undef GET_VALNB    
    return reset_settings;
}

- (int)loadSettings:(NSString*)gameStr {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSNumber *valNb;
    NSString *valStr,*keyStr;
    
    if (gameStr==nil) return 1;
    
    memset(&ifba_game_conf,0,sizeof(ifba_game_conf_t));
    
    
    //TEMP HACK
    for (int i=0;i<MAX_JOYSTICKS;i++) {
        ifba_game_conf.vpad_analog_speed[i][0]=1;
        ifba_game_conf.vpad_analog_speed[i][1]=1;
        ifba_game_conf.vpad_analog_speed[i][2]=4;
        ifba_game_conf.vpad_analog_speed[i][3]=4;
    }
    
    keyStr=[NSString stringWithFormat:@"%@_VERSION_SETTINGS",gameStr];
    valNb=[prefs objectForKey:keyStr];
	if (valNb == nil) return 2;
    else if ([valNb intValue]!=VERSION_SETTINGS) return 3;
#define GET_VALNB(a) \
keyStr=[NSString stringWithFormat:@"%@_%@",gameStr,a];\
valNb=[prefs objectForKey:keyStr];
	
    
    //gameStr not null, check if settings exist for game
    GET_VALNB(@"video_fskip")
    if (valNb == nil) return 4; //no setting        
    
    //Video settings
    GET_VALNB(@"video_fskip")
	if ((valNb == nil)) ifba_game_conf.video_fskip=10; //AUTO
	else ifba_game_conf.video_fskip = [valNb intValue];
    GET_VALNB(@"video_60hz")
	if ((valNb == nil)) ifba_game_conf.video_60hz=0;
	else ifba_game_conf.video_60hz = [valNb intValue];    
    GET_VALNB(@"aspect_ratio")
	if ((valNb == nil)) ifba_game_conf.aspect_ratio=1;
	else ifba_game_conf.aspect_ratio = [valNb intValue];
    GET_VALNB(@"screen_mode")
	if ((valNb == nil)) ifba_game_conf.screen_mode=2;
	else ifba_game_conf.screen_mode = [valNb intValue];
    GET_VALNB(@"filtering")
	if ((valNb == nil)) ifba_game_conf.filtering=1;
	else ifba_game_conf.filtering = [valNb intValue];
    GET_VALNB(@"brightness")
	if ((valNb == nil)) {
        if ([cur_screen respondsToSelector:@selector(setBrightness:)]) ifba_game_conf.brightness=cur_screen.brightness;
        else ifba_game_conf.brightness=0.5f;
    }
	else ifba_game_conf.brightness = [valNb floatValue];        
    GET_VALNB(@"show_fps")
	if ((valNb == nil)) ifba_game_conf.show_fps=0;
	else ifba_game_conf.show_fps = [valNb intValue];
    GET_VALNB(@"video_filter")
	if ((valNb == nil)) ifba_game_conf.video_filter=0;
	else ifba_game_conf.video_filter = [valNb intValue];
    GET_VALNB(@"video_filter_strength")
	if ((valNb == nil)) ifba_game_conf.video_filter_strength=32;
	else ifba_game_conf.video_filter_strength = [valNb intValue];
    
    
    //Sound settings
    GET_VALNB(@"sound_on")
	if ((valNb == nil)) ifba_game_conf.sound_on=1;
	else ifba_game_conf.sound_on = [valNb intValue];
    GET_VALNB(@"sound_freq")
	if ((valNb == nil)) ifba_game_conf.sound_freq=0;
	else ifba_game_conf.sound_freq = [valNb intValue];
    GET_VALNB(@"sound_latency")
	if ((valNb == nil)) ifba_game_conf.sound_latency=1;
	else ifba_game_conf.sound_latency = [valNb intValue];
    
    //Controls settings
    GET_VALNB(@"vpad_alpha")
	if ((valNb == nil)) ifba_game_conf.vpad_alpha=2;
	else ifba_game_conf.vpad_alpha = [valNb intValue];
    GET_VALNB(@"vpad_showSpecial")
	if ((valNb == nil)) ifba_game_conf.vpad_showSpecial=1;
	else ifba_game_conf.vpad_showSpecial = [valNb intValue];
    GET_VALNB(@"vpad_btnsize")
	if ((valNb == nil)) ifba_game_conf.vpad_btnsize=1;
	else ifba_game_conf.vpad_btnsize = [valNb intValue];
    GET_VALNB(@"vpad_padsize")
	if ((valNb == nil)) ifba_game_conf.vpad_padsize=1;
	else ifba_game_conf.vpad_padsize = [valNb intValue];
    GET_VALNB(@"vpad_style")
	if ((valNb == nil)) ifba_game_conf.vpad_style=0;
	else ifba_game_conf.vpad_style = [valNb intValue];
    GET_VALNB(@"vpad_followfinger")
	if ((valNb == nil)) ifba_game_conf.vpad_followfinger=0;
	else ifba_game_conf.vpad_followfinger = [valNb intValue];
    
    //Emulation settings
    GET_VALNB(@"asm_68k")
	if ((valNb == nil)) ifba_game_conf.asm_68k=1;
	else ifba_game_conf.asm_68k = [valNb intValue];
    GET_VALNB(@"asm_z80")
	if ((valNb == nil)) ifba_game_conf.asm_z80=0;
	else ifba_game_conf.asm_z80 = [valNb intValue];
    GET_VALNB(@"asm_nec")
	if ((valNb == nil)) ifba_game_conf.asm_nec=0;
	else ifba_game_conf.asm_nec = [valNb intValue];
    GET_VALNB(@"asm_sh2")
	if ((valNb == nil)) ifba_game_conf.asm_sh2=0;
	else ifba_game_conf.asm_sh2 = [valNb intValue];
    
    //Controls mapping
    for (int i=0;i<MAX_JOYSTICKS;i++) 
        for (int j=0;j<VSTICK_NB_BUTTON;j++) {
            keyStr=[NSString stringWithFormat:@"%@_wiimap%02X%02X",gameStr,i,j];
            valNb=[prefs objectForKey:keyStr];            
            if (valNb != nil) ifba_game_conf.joymap_wiimote[i][j].dev_btn=[valNb intValue];
            else ifba_game_conf.joymap_wiimote[i][j].dev_btn=default_joymap_wiimote[i][j].dev_btn;
            
            keyStr=[NSString stringWithFormat:@"%@_wiimap_str%02X%02X",gameStr,i,j];
            valStr=[prefs objectForKey:keyStr];            
            if (valStr != nil) strncpy(ifba_game_conf.joymap_wiimote[i][j].btn_name,[valStr UTF8String],sizeof(ifba_game_conf.joymap_wiimote[i][j].btn_name)-1);
            else strcpy(ifba_game_conf.joymap_wiimote[i][j].btn_name,default_joymap_wiimote[i][j].btn_name);
        }
    for (int j=0;j<VSTICK_NB_BUTTON;j++) {
        keyStr=[NSString stringWithFormat:@"%@_icademap%02X",gameStr,j];
        valNb=[prefs objectForKey:keyStr];        
        if (valNb != nil) ifba_game_conf.joymap_iCade[j].dev_btn=[valNb intValue];
        else ifba_game_conf.joymap_iCade[j].dev_btn=default_joymap_iCade[j].dev_btn;
        
        keyStr=[NSString stringWithFormat:@"%@_icademap_str%02X",gameStr,j];
        valStr=[prefs objectForKey:keyStr];        
        if (valStr != nil) strncpy(ifba_game_conf.joymap_iCade[j].btn_name,[valStr UTF8String],sizeof(ifba_game_conf.joymap_iCade[j].btn_name)-1);
        else strcpy(ifba_game_conf.joymap_iCade[j].btn_name,default_joymap_iCade[j].btn_name);
    }
    
    
    //TOUCHPAD
    for (int j=0;j<VSTICK_NB_BUTTON;j++) {
        keyStr=[NSString stringWithFormat:@"%@_vpad_button_manual_layout%02X_0",gameStr,j];
        valNb=[prefs objectForKey:keyStr];        
        if (valNb != nil) ifba_conf.vpad_button_manual_layout[j][0]=[valNb intValue];
        else ifba_conf.vpad_button_manual_layout[j][0]=0;        
        keyStr=[NSString stringWithFormat:@"%@_vpad_button_manual_layout%02X_1",gameStr,j];
        valNb=[prefs objectForKey:keyStr];        
        if (valNb != nil) ifba_conf.vpad_button_manual_layout[j][1]=[valNb intValue];
        else ifba_conf.vpad_button_manual_layout[j][1]=0;
        
        keyStr=[NSString stringWithFormat:@"%@_vpad_button_x%02X_0",gameStr,j];
        valNb=[prefs objectForKey:keyStr];        
        if (valNb != nil) ifba_conf.vpad_button_x[j][0]=[valNb floatValue];
        else ifba_conf.vpad_button_manual_layout[j][0]=0;
        keyStr=[NSString stringWithFormat:@"%@_vpad_button_x%02X_1",gameStr,j];
        valNb=[prefs objectForKey:keyStr];        
        if (valNb != nil) ifba_conf.vpad_button_x[j][1]=[valNb floatValue];
        else ifba_conf.vpad_button_manual_layout[j][1]=0;
        
        keyStr=[NSString stringWithFormat:@"%@_vpad_button_y%02X_0",gameStr,j];
        valNb=[prefs objectForKey:keyStr];        
        if (valNb != nil) ifba_conf.vpad_button_y[j][0]=[valNb floatValue];
        else ifba_conf.vpad_button_manual_layout[j][0]=0;
        keyStr=[NSString stringWithFormat:@"%@_vpad_button_y%02X_1",gameStr,j];
        valNb=[prefs objectForKey:keyStr];        
        if (valNb != nil) ifba_conf.vpad_button_y[j][1]=[valNb floatValue];
        else ifba_conf.vpad_button_manual_layout[j][1]=0;
        
    }
    keyStr=[NSString stringWithFormat:@"%@_vpad_pad_manual_layout_0",gameStr];
    valNb=[prefs objectForKey:keyStr];        
    if (valNb != nil) ifba_conf.vpad_pad_manual_layout[0]=[valNb intValue];
    else ifba_conf.vpad_pad_manual_layout[0]=0;
    keyStr=[NSString stringWithFormat:@"%@_vpad_pad_manual_layout_1",gameStr];
    valNb=[prefs objectForKey:keyStr];        
    if (valNb != nil) ifba_conf.vpad_pad_manual_layout[1]=[valNb intValue];
    else ifba_conf.vpad_pad_manual_layout[1]=0;
    
    keyStr=[NSString stringWithFormat:@"%@_vpad_pad_x_0",gameStr];
    valNb=[prefs objectForKey:keyStr];        
    if (valNb != nil) ifba_conf.vpad_pad_x[0]=[valNb floatValue];
    else ifba_conf.vpad_pad_manual_layout[0]=0;
    keyStr=[NSString stringWithFormat:@"%@_vpad_pad_x_1",gameStr];
    valNb=[prefs objectForKey:keyStr];        
    if (valNb != nil) ifba_conf.vpad_pad_x[1]=[valNb floatValue];
    else ifba_conf.vpad_pad_manual_layout[1]=0;
    
    keyStr=[NSString stringWithFormat:@"%@_vpad_pad_y_0",gameStr];
    valNb=[prefs objectForKey:keyStr];        
    if (valNb != nil) ifba_conf.vpad_pad_y[0]=[valNb floatValue];
    else ifba_conf.vpad_pad_manual_layout[0]=0;
    keyStr=[NSString stringWithFormat:@"%@_vpad_pad_y_1",gameStr];
    valNb=[prefs objectForKey:keyStr];        
    if (valNb != nil) ifba_conf.vpad_pad_y[1]=[valNb floatValue];
    else ifba_conf.vpad_pad_manual_layout[1]=0;
    
#undef GET_VALNB
    return 0;
}


- (void)saveSettings {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSNumber *valNb;
    NSString *valStr,*keyStr;
    
    valNb=[[NSNumber alloc] initWithInt:VERSION_SETTINGS ];    
    [prefs setObject:valNb forKey:@"VERSION_SETTINGS"];[valNb autorelease];
    
    //last game
    valStr=[NSString stringWithFormat:@"%s",gameName];
    [prefs setObject:valStr forKey:@"lastgame"];
    //Gamebrowser settings
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.filter_type ];
    [prefs setObject:valNb forKey:@"filter_type"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.filter_missing ];
    [prefs setObject:valNb forKey:@"filter_missing"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.filter_genre ];
    [prefs setObject:valNb forKey:@"filter_genre"];[valNb autorelease];
    
    //Roms paths
    for (int i=0;i<DIRS_MAX;i++) {        
        valStr=[NSString stringWithFormat:@"%s",szAppRomPaths[i]];
        keyStr=[NSString stringWithFormat:@"romspath%02X",i];
        [prefs setObject:valStr forKey:keyStr];
    }	    
    
#define SET_VALNB(a) \
[prefs setObject:valNb forKey:a];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.btstack_on ];
    SET_VALNB(@"btstack_on")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.icade_lang ];
	SET_VALNB(@"icade_lang")
    
    //video settings
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.video_fskip ];
    SET_VALNB(@"video_fskip")    
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.video_60hz ];
	SET_VALNB(@"video_60hz")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.aspect_ratio ];
	SET_VALNB(@"aspect_ratio")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.screen_mode ];
	SET_VALNB(@"screen_mode")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.filtering ];
	SET_VALNB(@"filtering")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.show_fps ];
	SET_VALNB(@"show_fps")
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.brightness ];
	SET_VALNB(@"brightness")
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.video_filter ];
	SET_VALNB(@"video_filter")
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.video_filter_strength ];
	SET_VALNB(@"video_filter_strength")
    
    //audio settings
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.sound_on ];
	SET_VALNB(@"sound_on")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.sound_freq ];
	SET_VALNB(@"sound_freq")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.sound_latency ];
	SET_VALNB(@"sound_latency")
    
    //controls settings
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_alpha ];
	SET_VALNB(@"vpad_alpha")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_showSpecial ];
	SET_VALNB(@"vpad_showSpecial")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_btnsize ];
    SET_VALNB(@"vpad_btnsize")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_padsize ];
    SET_VALNB(@"vpad_padsize")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_style ];
    SET_VALNB(@"vpad_style")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_followfinger ];
    SET_VALNB(@"vpad_followfinger")
    
    
    //emulation settings
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.asm_68k];
    SET_VALNB(@"asm_68k")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.asm_z80];
    SET_VALNB(@"asm_z80")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.asm_nec];
    SET_VALNB(@"asm_nec")
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.asm_sh2];
    SET_VALNB(@"asm_sh2")
    
    //controls mapping
    for (int i=0;i<MAX_JOYSTICKS;i++) 
        for (int j=0;j<VSTICK_NB_BUTTON;j++) {
            valNb=[[NSNumber alloc] initWithInt:ifba_conf.joymap_wiimote[i][j].dev_btn];
            [prefs setObject:valNb forKey:[NSString stringWithFormat:@"wiimap%02X%02X",i,j]];
            [valNb release];
        }
    for (int j=0;j<VSTICK_NB_BUTTON;j++) {
        valNb=[[NSNumber alloc] initWithInt:ifba_conf.joymap_iCade[j].dev_btn];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"icademap%02X",j]];
        [valNb release];        
    }
    
    //TOUCHPAD
    for (int j=0;j<VSTICK_NB_BUTTON;j++) {
        valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_button_manual_layout[j][0]];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"vpad_button_manual_layout%02X_0",j]];
        [valNb release];
        valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_button_manual_layout[j][1]];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"vpad_button_manual_layout%02X_1",j]];
        [valNb release];
        valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_button_x[j][0]];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"vpad_button_x%02X_0",j]];
        [valNb release];
        valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_button_x[j][1]];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"vpad_button_x%02X_1",j]];
        [valNb release];
        valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_button_y[j][0]];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"vpad_button_y%02X_0",j]];
        [valNb release];
        valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_button_y[j][1]];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"vpad_button_y%02X_1",j]];
        [valNb release];
    }
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_pad_manual_layout[0]];
    [prefs setObject:valNb forKey:[NSString stringWithFormat:@"vpad_pad_manual_layout_0"]];
    [valNb release];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_pad_manual_layout[1]];
    [prefs setObject:valNb forKey:[NSString stringWithFormat:@"vpad_pad_manual_layout_1"]];
    [valNb release];
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_pad_x[0]];
    [prefs setObject:valNb forKey:[NSString stringWithFormat:@"vpad_pad_x_0"]];
    [valNb release];
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_pad_x[1]];
    [prefs setObject:valNb forKey:[NSString stringWithFormat:@"vpad_pad_x_1"]];
    [valNb release];
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_pad_y[0]];
    [prefs setObject:valNb forKey:[NSString stringWithFormat:@"vpad_pad_y_0"]];
    [valNb release];
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_pad_y[1]];
    [prefs setObject:valNb forKey:[NSString stringWithFormat:@"vpad_pad_y_1"]];
    [valNb release];
    
    
#undef SET_VALNB	
    [prefs synchronize];
}

- (void)saveSettings:(NSString *)gameStr {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSNumber *valNb;
    NSString *valStr,*keyStr;
    
    if (gameStr==nil) return;
    
    valNb=[[NSNumber alloc] initWithInt:VERSION_SETTINGS ];    
    keyStr=[NSString stringWithFormat:@"%@_VERSION_SETTINGS",gameStr];
    [prefs setObject:valNb forKey:keyStr];[valNb autorelease];
    
#define SET_VALNB(a) \
keyStr=[NSString stringWithFormat:@"%@_%@",gameStr,a];\
[prefs setObject:valNb forKey:keyStr];[valNb autorelease];
    
    //video settings
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.video_fskip ];
    SET_VALNB(@"video_fskip")    
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.video_60hz ];
	SET_VALNB(@"video_60hz")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.aspect_ratio ];
	SET_VALNB(@"aspect_ratio")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.screen_mode ];
	SET_VALNB(@"screen_mode")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.filtering ];
	SET_VALNB(@"filtering")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.show_fps ];
	SET_VALNB(@"show_fps")
    valNb=[[NSNumber alloc] initWithFloat:ifba_game_conf.brightness ];
	SET_VALNB(@"brightness")
    valNb=[[NSNumber alloc] initWithFloat:ifba_game_conf.video_filter ];
	SET_VALNB(@"video_filter")
    valNb=[[NSNumber alloc] initWithFloat:ifba_game_conf.video_filter_strength ];
	SET_VALNB(@"video_filter_strength")
    
    //audio settings
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.sound_on ];
	SET_VALNB(@"sound_on")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.sound_freq ];
	SET_VALNB(@"sound_freq")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.sound_latency ];
	SET_VALNB(@"sound_latency")
    
    //controls settings
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.vpad_alpha ];
	SET_VALNB(@"vpad_alpha")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.vpad_showSpecial ];
	SET_VALNB(@"vpad_showSpecial")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.vpad_btnsize ];
    SET_VALNB(@"vpad_btnsize")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.vpad_padsize ];
    SET_VALNB(@"vpad_padsize")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.vpad_style ];
    SET_VALNB(@"vpad_style")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.vpad_followfinger ];
    SET_VALNB(@"vpad_followfinger")
    
    
    //emulation settings
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.asm_68k];
    SET_VALNB(@"asm_68k")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.asm_z80];
    SET_VALNB(@"asm_z80")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.asm_nec];
    SET_VALNB(@"asm_nec")
    valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.asm_sh2];
    SET_VALNB(@"asm_sh2")
    
    //controls mapping
    for (int i=0;i<MAX_JOYSTICKS;i++) 
        for (int j=0;j<VSTICK_NB_BUTTON;j++) {
            valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.joymap_wiimote[i][j].dev_btn];
            keyStr=[NSString stringWithFormat:@"%@_wiimap%02X%02X",gameStr,i,j];
            [prefs setObject:valNb forKey:keyStr];
            [valNb release];
        }
    for (int j=0;j<VSTICK_NB_BUTTON;j++) {
        valNb=[[NSNumber alloc] initWithInt:ifba_game_conf.joymap_iCade[j].dev_btn];
        keyStr=[NSString stringWithFormat:@"%@_icademap%02X",gameStr,j];
        
        [prefs setObject:valNb forKey:keyStr];
        [valNb release];
    }
    
    //TOUCHPAD
    for (int j=0;j<VSTICK_NB_BUTTON;j++) {
        valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_button_manual_layout[j][0]];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"%@_vpad_button_manual_layout%02X_0",gameStr,j]];
        [valNb release];
        valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_button_manual_layout[j][1]];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"%@_vpad_button_manual_layout%02X_1",gameStr,j]];
        [valNb release];
        valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_button_x[j][0]];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"%@_vpad_button_x%02X_0",gameStr,j]];
        [valNb release];
        valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_button_x[j][1]];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"%@_vpad_button_x%02X_1",gameStr,j]];
        [valNb release];
        valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_button_y[j][0]];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"%@_vpad_button_y%02X_0",gameStr,j]];
        [valNb release];
        valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_button_y[j][1]];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"%@_vpad_button_y%02X_1",gameStr,j]];
        [valNb release];
    }
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_pad_manual_layout[0]];
    [prefs setObject:valNb forKey:[NSString stringWithFormat:@"%@_vpad_pad_manual_layout_0",gameStr]];
    [valNb release];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_pad_manual_layout[1]];
    [prefs setObject:valNb forKey:[NSString stringWithFormat:@"%@_vpad_pad_manual_layout_1",gameStr]];
    [valNb release];
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_pad_x[0]];
    [prefs setObject:valNb forKey:[NSString stringWithFormat:@"%@_vpad_pad_x_0",gameStr]];
    [valNb release];
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_pad_x[1]];
    [prefs setObject:valNb forKey:[NSString stringWithFormat:@"%@_vpad_pad_x_1",gameStr]];
    [valNb release];
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_pad_y[0]];
    [prefs setObject:valNb forKey:[NSString stringWithFormat:@"%@_vpad_pad_y_0",gameStr]];
    [valNb release];
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.vpad_pad_y[1]];
    [prefs setObject:valNb forKey:[NSString stringWithFormat:@"%@_vpad_pad_y_1",gameStr]];
    [valNb release];
    
#undef SET_VALNB    
	
    [prefs synchronize];
}

- (void)removeSettings:(NSString *)gameStr {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *keyStr;
    
    if (gameStr==nil) return;
    
    
    keyStr=[NSString stringWithFormat:@"%@_VERSION_SETTINGS",gameStr];
    [prefs removeObjectForKey:keyStr];
    
    
#define REMOVE_KEY(a) \
keyStr=[NSString stringWithFormat:@"%@_%@",gameStr,a];\
[prefs removeObjectForKey:keyStr];
    
    //video settings
    REMOVE_KEY(@"video_fskip")    
	REMOVE_KEY(@"video_60hz")
	REMOVE_KEY(@"aspect_ratio")
	REMOVE_KEY(@"screen_mode")
	REMOVE_KEY(@"filtering")
	REMOVE_KEY(@"show_fps")
	REMOVE_KEY(@"brightness")
	REMOVE_KEY(@"video_filter")
	REMOVE_KEY(@"video_filter_strength")
    
    //audio settings
	REMOVE_KEY(@"sound_on")
	REMOVE_KEY(@"sound_freq")
	REMOVE_KEY(@"sound_latency")
    
    //controls settings
	REMOVE_KEY(@"vpad_alpha")
	REMOVE_KEY(@"vpad_showSpecial")
    REMOVE_KEY(@"vpad_btnsize")
    REMOVE_KEY(@"vpad_padsize")
    REMOVE_KEY(@"btstack_on")
    REMOVE_KEY(@"vpad_style")
    REMOVE_KEY(@"vpad_followfinger")
	REMOVE_KEY(@"icade_lang")
    
    //emulation settings
    REMOVE_KEY(@"asm_68k")
    REMOVE_KEY(@"asm_z80")
    REMOVE_KEY(@"asm_nec")
    REMOVE_KEY(@"asm_sh2")
    
    //controls mapping
    for (int i=0;i<MAX_JOYSTICKS;i++) 
        for (int j=0;j<VSTICK_NB_BUTTON;j++) {
            keyStr=[NSString stringWithFormat:@"%@_wiimap%02X%02X",gameStr,i,j];
            [prefs removeObjectForKey:keyStr];
        }
    for (int j=0;j<VSTICK_NB_BUTTON;j++) {
        keyStr=[NSString stringWithFormat:@"%@_icademap%02X",gameStr,j];
        [prefs removeObjectForKey:keyStr];
    }
#undef REMOVE_KEY	
    [prefs synchronize];
}


- (void)dealloc
{
    [_window release];
    [_navController release];
    [super dealloc];
}

- (UIImage *)imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

- (NSString *)machine
{
	size_t size;
	
	// Set 'oldp' parameter to NULL to get the size of the data
	// returned so we can allocate appropriate amount of space
	sysctlbyname("hw.machine", NULL, &size, NULL, 0); 
	
	// Allocate the space to store name
	char *name = (char*)malloc(size);
	
	// Get the platform name
	sysctlbyname("hw.machine", name, &size, NULL, 0);
	
	// Place name into a string
	NSString *machine = [[[NSString alloc] initWithCString:name] autorelease];
	
	// Done with this
	free(name);
	
	return machine;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
    [TestFlight takeOff:@"56f0ec34-3ad4-4db7-9a15-0edbd4f1f3ff"];
    
    
    //TODO: to review
    if([[UIScreen screens]count]*0 > 1) { //if there are more than 1 screens connected to the device    
        CGSize max;
        UIScreenMode *maxScreenMode;
        max.width=0;
        for(int i = 0; i < [[[[UIScreen screens] objectAtIndex:1] availableModes]count]; i++) {
            UIScreenMode *current = [[[[UIScreen screens]objectAtIndex:1]availableModes]objectAtIndex:i];
            if(current.size.width > max.width) {
                max = current.size;
                maxScreenMode = current;
            }
        }
        //Now we have the highest mode. Turn the external display to use that mode.
        cur_screen = [[UIScreen screens] objectAtIndex:1];
        cur_screen.currentMode = maxScreenMode;
        //Boom! Now the external display is set to the proper mode. We need to now
        //set the screen of a new UIWindow to the external screen        
    } else {    
        cur_screen=[UIScreen mainScreen];        
    }
    self.window = [[[UIWindow alloc] initWithFrame:[cur_screen bounds]] autorelease];
    self.window.screen = cur_screen;
    
    
    int settings_reseted=[self loadSettings];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    if ([cur_screen respondsToSelector:@selector(setBrightness:)]) {
        sys_brightness=cur_screen.brightness;
        [cur_screen setBrightness:ifba_conf.brightness];
    }
    
    /* iPhone Simulator == i386
	 iPhone == iPhone1,1             //Slow
	 3G iPhone == iPhone1,2          //Slow
	 3GS iPhone == iPhone2,1
	 4 iPhone == iPhone3,1
	 1st Gen iPod == iPod1,1         //Slow
	 2nd Gen iPod == iPod2,1
	 3rd Gen iPod == iPod3,1
	 */	
    lowmem_device=0;
	NSString *strMachine=[self machine];
	NSRange r = [strMachine rangeOfString:@"iPhone2," options:NSCaseInsensitiveSearch];
	if (r.location != NSNotFound) {
		lowmem_device=1;
	}
	r.location=NSNotFound;
	r = [strMachine rangeOfString:@"iPod3" options:NSCaseInsensitiveSearch];
	if (r.location != NSNotFound) {
		lowmem_device=1;
	}
    r.location=NSNotFound;
	r = [strMachine rangeOfString:@"iPod4" options:NSCaseInsensitiveSearch];
	if (r.location != NSNotFound) {
		lowmem_device=1;
	}
    r.location=NSNotFound;
	r = [strMachine rangeOfString:@"iPad1" options:NSCaseInsensitiveSearch];
	if (r.location != NSNotFound) {
		lowmem_device=1;
	}
    
    //    NSLog(@"lowmem_device: %d",lowmem_device);
    
    /* Set working directory to resource path */
//    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *documentsDirectory=@"/var/mobile/Documents/iFBA";
    [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:TRUE attributes:nil error:nil];
    [[NSFileManager defaultManager] changeCurrentDirectoryPath: documentsDirectory];
    
#if RELEASE_DEBUG
    strcpy(debug_root_path,[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] UTF8String]);
    strcpy(debug_bundle_path,[[[NSBundle mainBundle] resourcePath] UTF8String]);

#endif
    

    
    // Override point for customization after application launch.
    UIViewController *menuvc;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        menuvc = [[[MenuViewController alloc] initWithNibName:@"MenuViewController_iPhone" bundle:nil] autorelease];
        device_isIpad=0;
    } else {
        //menuvc = [[[MenuViewController alloc] initWithNibName:@"MenuViewController_iPad" bundle:nil] autorelease];
        menuvc = [[[MenuViewController alloc] initWithNibName:@"MenuViewController_iPhone" bundle:nil] autorelease];        
        device_isIpad=1;
    }
    
    //check if retina
    device_retina=0;
    if ([cur_screen respondsToSelector:@selector(scale)]) {
        if ([cur_screen scale]==2) device_retina=1;
    }
    
    lowmem_device=0;
    
    self.navController = [[[UINavigationController alloc] init] autorelease];
    [[self.navController navigationBar] setBarStyle:UIBarStyleBlack]; // UIBarStyleDefault];
    //    [[self.navController navigationBar] setTranslucent:YES];
    //****************************************************
    //Init background image with a mosaic of random titles
    //****************************************************    
    int bg_width=cur_screen.applicationFrame.size.width;
    int bg_height=cur_screen.applicationFrame.size.height;
    int bg_max=MAX(bg_width,bg_height);
    int bg_min=MIN(bg_width,bg_height);
    
//    NSLog(@"dim: %d %d",bg_width,bg_height);
    
    UIView *bg_view=[[UIView alloc] initWithFrame:CGRectMake(0,0,bg_max,bg_max)];
    int x,y,yavg,cnt,cntImg;
    x=y=0;
    bg_view.backgroundColor=[UIColor blackColor];
    bg_view.frame=CGRectMake(0,0,bg_max,bg_max);
    cnt=0;yavg=0;cntImg=0;
    
    /*   
     //USed to generate background from titles png files 
     while (y<bg_max) {
     char *szName;
     NSString *img_name;
     UIImage *img_tmp=nil;
     while (img_tmp==nil) {
     nBurnDrvActive=arc4random()%nBurnDrvCount;
     BurnDrvGetZipName(&szName,0);
     img_name=[NSString stringWithFormat:@"%s.png",szName];
     img_tmp=[UIImage imageNamed:img_name];
     if (img_tmp&&device_retina) img_tmp=[UIImage imageWithCGImage:img_tmp.CGImage scale:2 orientation:img_tmp.imageOrientation];
     }        
     UIImageView *img=[[UIImageView alloc] initWithImage:img_tmp];
     img.frame=CGRectMake(x,y,img_tmp.size.width,img_tmp.size.height);
     x+=img_tmp.size.width;
     yavg+=img_tmp.size.height;
     cnt++;
     if ((x>=bg_max)||((x>bg_min)&&(y>bg_min))) {
     x=0;
     y+=yavg/cnt;
     cnt=0;yavg=0;
     }
     [bg_view addSubview:img];
     [img release];
     cntImg++;
     }*/
    UIImage *imgtmp;
    if (bg_max*(device_retina+1)>1024) imgtmp=[UIImage imageNamed:@"background2048.jpg"];
    else imgtmp=[UIImage imageNamed:@"background1024.jpg"];
    if (device_retina) imgtmp=[UIImage imageWithCGImage:imgtmp.CGImage scale:2 orientation:imgtmp.imageOrientation];    
    UIImageView *img=[[UIImageView alloc] initWithImage:imgtmp];
    [bg_view addSubview:img];
    [img release];
    // NSLog(@"%d images, %d x %d",cntImg,bg_max,bg_max);
    self.navController.view.backgroundColor=[UIColor colorWithPatternImage:[self imageWithView:bg_view]];
    //*****************************************************
    
    [self.navController pushViewController:menuvc animated:YES];    
    //self.navController.navigationBarHidden=TRUE;
    self.window.rootViewController = self.navController;    
    [self.window makeKeyAndVisible];
    
    
    if (settings_reseted) {
        NSString *msgString=[NSString stringWithFormat:NSLocalizedString(@"Warning_Settings_Reset",@""),[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
        UIAlertView *settingsMsg=[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",@"") message:msgString delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
        [settingsMsg show];
    }
    
    [TestFlight passCheckpoint:@"LAUNCH_OK"];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */    
    nShouldExit=2;
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [self saveSettings];
    if ([cur_screen respondsToSelector:@selector(setBrightness:)]) {
        [cur_screen setBrightness:sys_brightness];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    if ([cur_screen respondsToSelector:@selector(setBrightness:)]) {
        sys_brightness=cur_screen.brightness;
        [cur_screen setBrightness:ifba_conf.brightness];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [self saveSettings];
    if ([cur_screen respondsToSelector:@selector(setBrightness:)]) {
        [cur_screen setBrightness:sys_brightness];
    }
}

/*
 // Optional UITabBarControllerDelegate method.
 - (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
 {
 }
 */

/*
 // Optional UITabBarControllerDelegate method.
 - (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
 {
 }
 */

@end
