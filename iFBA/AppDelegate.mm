//
//  AppDelegate.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define VERSION_SETTINGS 1

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#import "MenuViewController.h"
#import "fbaconf.h"
#import "burner.h"


#ifdef TESTFLIGHT
#import "TestFlight.h"
#endif

extern char szAppRomPaths[DIRS_MAX][MAX_PATH];
extern char gameName[64];
extern t_button_map joymap_wiimote[MAX_JOYSTICKS][VSTICK_NB_BUTTON];

extern int device_isIpad;

@implementation AppDelegate

@synthesize window = _window;
@synthesize navController = _navController;

void tstfl_log(char *str) {
#ifdef TESTFLIGHT    
    TFLog(@"%s",str);
#endif    
}

void tstfl_validateloadgame(char *name) {
#ifdef TESTFLIGHT    
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"STARTEDGAME-%s",name]];
#endif    
}


- (int)loadSettings {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSNumber *valNb;
    NSString *valStr;
    int reset_settings=0;
    
    
    gameName[0]=0;
    
    memset(&ifba_conf,0,sizeof(ifba_conf_t));
    
    valNb=[prefs objectForKey:@"VERSION_SETTINGS"];
	if (valNb == nil) reset_settings=1;
    else if ([valNb intValue]!=VERSION_SETTINGS) reset_settings=1;
	
	
    //    valNb=[prefs objectForKey:@"VERSION_MAJOR"];
    //    valNb=[prefs objectForKey:@"VERSION_MINOR"];
    
    valNb=[prefs objectForKey:@"aspect_ratio"];
	if ((valNb == nil)||reset_settings) ifba_conf.aspect_ratio=1;
	else ifba_conf.aspect_ratio = [valNb intValue];
    valNb=[prefs objectForKey:@"screen_mode"];
	if ((valNb == nil)||reset_settings) ifba_conf.screen_mode=2;
	else ifba_conf.screen_mode = [valNb intValue];
    valNb=[prefs objectForKey:@"filtering"];
	if ((valNb == nil)||reset_settings) ifba_conf.filtering=1;
	else ifba_conf.filtering = [valNb intValue];
    valNb=[prefs objectForKey:@"brightness"];
	if ((valNb == nil)||reset_settings) {
        if ([[UIScreen mainScreen] respondsToSelector:@selector(setBrightness)]) ifba_conf.brightness=[[UIScreen mainScreen] brightness];
        else ifba_conf.brightness=0.5f;
    }
	else ifba_conf.brightness = [valNb floatValue];        
    valNb=[prefs objectForKey:@"show_fps"];
	if ((valNb == nil)||reset_settings) ifba_conf.show_fps=0;
	else ifba_conf.show_fps = [valNb intValue];
    valNb=[prefs objectForKey:@"video_filter"];
	if ((valNb == nil)||reset_settings) ifba_conf.video_filter=0;
	else ifba_conf.video_filter = [valNb intValue];
    valNb=[prefs objectForKey:@"video_filter_strength"];
	if ((valNb == nil)||reset_settings) ifba_conf.video_filter_strength=32;
	else ifba_conf.video_filter_strength = [valNb intValue];
    
    valNb=[prefs objectForKey:@"sound_on"];
	if ((valNb == nil)||reset_settings) ifba_conf.sound_on=1;
	else ifba_conf.sound_on = [valNb intValue];
    valNb=[prefs objectForKey:@"sound_freq"];
	if ((valNb == nil)||reset_settings) ifba_conf.sound_freq=0;
	else ifba_conf.sound_freq = [valNb intValue];
    valNb=[prefs objectForKey:@"sound_latency"];
	if ((valNb == nil)||reset_settings) ifba_conf.sound_latency=1;
	else ifba_conf.sound_latency = [valNb intValue];
    
    valNb=[prefs objectForKey:@"btstack_on"];
	if ((valNb == nil)||reset_settings) ifba_conf.btstack_on=0;
	else ifba_conf.btstack_on = [valNb intValue];
    valNb=[prefs objectForKey:@"vpad_alpha"];
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_alpha=2;
	else ifba_conf.vpad_alpha = [valNb intValue];
    valNb=[prefs objectForKey:@"vpad_showSpecial"];
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_showSpecial=1;
	else ifba_conf.vpad_showSpecial = [valNb intValue];
    valNb=[prefs objectForKey:@"vpad_btnsize"];
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_btnsize=1;
	else ifba_conf.vpad_btnsize = [valNb intValue];
    valNb=[prefs objectForKey:@"vpad_padsize"];
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_padsize=1;
	else ifba_conf.vpad_padsize = [valNb intValue];
    
    valNb=[prefs objectForKey:@"asm_68k"];
	if ((valNb == nil)||reset_settings) ifba_conf.asm_68k=1;
	else ifba_conf.asm_68k = [valNb intValue];
    valNb=[prefs objectForKey:@"asm_z80"];
	if ((valNb == nil)||reset_settings) ifba_conf.asm_z80=0;
	else ifba_conf.asm_z80 = [valNb intValue];
    valNb=[prefs objectForKey:@"asm_nec"];
	if ((valNb == nil)||reset_settings) ifba_conf.asm_nec=0;
	else ifba_conf.asm_nec = [valNb intValue];
    valNb=[prefs objectForKey:@"asm_sh2"];
	if ((valNb == nil)||reset_settings) ifba_conf.asm_sh2=0;
	else ifba_conf.asm_sh2 = [valNb intValue];
    
    for (int i=0;i<MAX_JOYSTICKS;i++) 
        for (int j=0;j<VSTICK_NB_BUTTON;j++) {
            valNb=[prefs objectForKey:[NSString stringWithFormat:@"wiimap%02X%02X",i,j]];
            if (valNb != nil) joymap_wiimote[i][j].dev_btn=[valNb intValue];
        }
    for (int j=0;j<VSTICK_NB_BUTTON;j++) {
        valNb=[prefs objectForKey:[NSString stringWithFormat:@"icademap%02X",j]];
        if (valNb != nil) joymap_iCade[j].dev_btn=[valNb intValue];
    }
    
    for (int i=0;i<DIRS_MAX;i++) {        
        valStr=[prefs objectForKey:[NSString stringWithFormat:@"romspath%02X",i]];
        if (valStr != nil) strcpy(szAppRomPaths[i],[valStr UTF8String]);
    //Recreate dir if not existing
        if (szAppRomPaths[i][0]) {
            //NSLog(@"%s",szAppRomPaths[i]);
            [[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%s",szAppRomPaths[i]] withIntermediateDirectories:TRUE attributes:nil error:nil];

        }
    }
    return reset_settings;
}

- (void)saveSettings {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSNumber *valNb;
    NSString *valStr;
    
    valNb=[[NSNumber alloc] initWithInt:VERSION_SETTINGS ];    
    [prefs setObject:valNb forKey:@"VERSION_SETTINGS"];[valNb autorelease];
    
    
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.aspect_ratio ];
	[prefs setObject:valNb forKey:@"aspect_ratio"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.screen_mode ];
	[prefs setObject:valNb forKey:@"screen_mode"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.filtering ];
	[prefs setObject:valNb forKey:@"filtering"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.show_fps ];
	[prefs setObject:valNb forKey:@"show_fps"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.brightness ];
	[prefs setObject:valNb forKey:@"brightness"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.video_filter ];
	[prefs setObject:valNb forKey:@"video_filter"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithFloat:ifba_conf.video_filter_strength ];
	[prefs setObject:valNb forKey:@"video_filter_strength"];[valNb autorelease];
    
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.sound_on ];
	[prefs setObject:valNb forKey:@"sound_on"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.sound_freq ];
	[prefs setObject:valNb forKey:@"sound_freq"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.sound_latency ];
	[prefs setObject:valNb forKey:@"sound_latency"];[valNb autorelease];
    
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_alpha ];
	[prefs setObject:valNb forKey:@"vpad_alpha"];[valNb autorelease];    
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_showSpecial ];
	[prefs setObject:valNb forKey:@"vpad_showSpecial"];[valNb autorelease];    
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_btnsize ];
	[prefs setObject:valNb forKey:@"vpad_btnsize"];[valNb autorelease];    
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_padsize ];
	[prefs setObject:valNb forKey:@"vpad_padsize"];[valNb autorelease];    
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.btstack_on ];
	[prefs setObject:valNb forKey:@"btstack_on"];[valNb autorelease];
    
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.asm_68k];
	[prefs setObject:valNb forKey:@"asm_68k"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.asm_z80];
	[prefs setObject:valNb forKey:@"asm_z80"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.asm_nec];
	[prefs setObject:valNb forKey:@"asm_nec"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.asm_sh2];
	[prefs setObject:valNb forKey:@"asm_sh2"];[valNb autorelease];
    
    //joymaps
    for (int i=0;i<MAX_JOYSTICKS;i++) 
        for (int j=0;j<VSTICK_NB_BUTTON;j++) {
            valNb=[[NSNumber alloc] initWithInt:joymap_wiimote[i][j].dev_btn];
            [prefs setObject:valNb forKey:[NSString stringWithFormat:@"wiimap%02X%02X",i,j]];[valNb autorelease];
        }
    for (int j=0;j<VSTICK_NB_BUTTON;j++) {
        valNb=[[NSNumber alloc] initWithInt:joymap_iCade[j].dev_btn];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"icademap%02X",j]];[valNb autorelease];
    }
    
    for (int i=0;i<DIRS_MAX;i++) {        
        valStr=[NSString stringWithFormat:@"%s",szAppRomPaths[i]];
        [prefs setObject:valStr forKey:[NSString stringWithFormat:@"romspath%02X",i]];
        [valStr autorelease];
    }	
	
    [prefs synchronize];
}

- (void)dealloc
{
    [_window release];
    [_navController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef TESTFLIGHT
    [TestFlight takeOff:@"2ffa7d1a4e9cbc814d66901ca319816a_NjYzOTkyMDEyLTAyLTI4IDAxOjM1OjE2LjcyOTEwMA"];
#endif
    
    int settings_reseted=[self loadSettings];
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(setBrightness)])  [[UIScreen mainScreen]setBrightness:ifba_conf.brightness];
    
    /* Set working directory to resource path */
    //NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *documentsDirectory=@"/var/mobile/Documents/iFBA";
    [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:TRUE attributes:nil error:nil];
    [[NSFileManager defaultManager] changeCurrentDirectoryPath: documentsDirectory];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
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
    self.navController = [[[UINavigationController alloc] init] autorelease];
    [[self.navController navigationBar] setBarStyle:UIBarStyleDefault];
    //    [[self.navController navigationBar] setTranslucent:YES];    
    [self.navController pushViewController:menuvc animated:YES];    
    self.window.rootViewController = self.navController;
    
    [self.window makeKeyAndVisible];
    
    
    if (settings_reseted) {
        NSString *msgString=[NSString stringWithFormat:NSLocalizedString(@"Warning_Settings_Reset",@""),[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
        UIAlertView *settingsMsg=[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",@"") message:msgString delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
        [settingsMsg show];
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [self saveSettings];
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
