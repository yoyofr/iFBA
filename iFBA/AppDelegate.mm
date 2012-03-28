//
//  AppDelegate.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

char debug_root_path[512];
char debug_bundle_path[512];

static float sys_brightness;


#define VERSION_SETTINGS 2

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

@implementation AppDelegate

@synthesize window = _window;
@synthesize navController = _navController;

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
    
    valStr=[prefs objectForKey:@"lastgame"];
    if (valStr != nil) strcpy(gameName,[valStr UTF8String]);
    else gameName[0]=0;
    
    valNb=[prefs objectForKey:@"filter_type"];
	if ((valNb == nil)||reset_settings) ifba_conf.filter_type=0; //Default is list by name
	else ifba_conf.filter_type = [valNb intValue];
    valNb=[prefs objectForKey:@"filter_missing"];
	if ((valNb == nil)||reset_settings) ifba_conf.filter_missing=0;
	else ifba_conf.filter_missing = [valNb intValue];
    valNb=[prefs objectForKey:@"filter_genre"];
	if ((valNb == nil)||reset_settings) ifba_conf.filter_genre=0xFFFFFFFF^GBF_BIOS; //Default is everything but the BIOS
	else ifba_conf.filter_genre = [valNb intValue];    
    
    valNb=[prefs objectForKey:@"video_fskip"];
	if ((valNb == nil)||reset_settings) ifba_conf.video_fskip=10; //AUTO
	else ifba_conf.video_fskip = [valNb intValue];    
    valNb=[prefs objectForKey:@"video_60hz"];
	if ((valNb == nil)||reset_settings) ifba_conf.video_60hz=0;
	else ifba_conf.video_60hz = [valNb intValue];    
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
        if ([[UIScreen mainScreen] respondsToSelector:@selector(setBrightness:)]) ifba_conf.brightness=[UIScreen mainScreen].brightness;
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
    valNb=[prefs objectForKey:@"vpad_style"];
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_style=0;
	else ifba_conf.vpad_style = [valNb intValue];
    valNb=[prefs objectForKey:@"vpad_pad_x"];
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_pad_x=0;
	else ifba_conf.vpad_pad_x = [valNb intValue];
    valNb=[prefs objectForKey:@"vpad_pad_y"];
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_pad_y=0;
	else ifba_conf.vpad_pad_y = [valNb intValue];
    valNb=[prefs objectForKey:@"vpad_button_x"];
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_button_x=0;
	else ifba_conf.vpad_button_x = [valNb intValue];
    valNb=[prefs objectForKey:@"vpad_button_y"];
	if ((valNb == nil)||reset_settings) ifba_conf.vpad_button_y=0;
	else ifba_conf.vpad_button_y = [valNb intValue];
    valNb=[prefs objectForKey:@"icade_lang"];
	if ((valNb == nil)||reset_settings) ifba_conf.icade_lang=0;
	else ifba_conf.icade_lang = [valNb intValue];
    
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
        else szAppRomPaths[i][0]=0;
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
    NSString *valStr,*keyStr;
    
    valNb=[[NSNumber alloc] initWithInt:VERSION_SETTINGS ];    
    [prefs setObject:valNb forKey:@"VERSION_SETTINGS"];[valNb autorelease];
    
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.filter_type ];
	[prefs setObject:valNb forKey:@"filter_type"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.filter_missing ];
	[prefs setObject:valNb forKey:@"filter_missing"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.filter_genre ];
	[prefs setObject:valNb forKey:@"filter_genre"];[valNb autorelease];
    
    valStr=[NSString stringWithFormat:@"%s",gameName];
    [prefs setObject:valStr forKey:@"lastgame"];
    
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.video_fskip ];
	[prefs setObject:valNb forKey:@"video_fskip"];[valNb autorelease];        
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.video_60hz ];
	[prefs setObject:valNb forKey:@"video_60hz"];[valNb autorelease];    
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
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_style ];
	[prefs setObject:valNb forKey:@"vpad_style"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_pad_x ];
	[prefs setObject:valNb forKey:@"vpad_pad_x"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_pad_y ];
	[prefs setObject:valNb forKey:@"vpad_pad_y"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_button_x ];
	[prefs setObject:valNb forKey:@"vpad_button_x"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.vpad_button_y ];
	[prefs setObject:valNb forKey:@"vpad_button_y"];[valNb autorelease];
    valNb=[[NSNumber alloc] initWithInt:ifba_conf.icade_lang ];
	[prefs setObject:valNb forKey:@"icade_lang"];[valNb autorelease];
    
    
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
            [prefs setObject:valNb forKey:[NSString stringWithFormat:@"wiimap%02X%02X",i,j]];
            [valNb release];
        }
    for (int j=0;j<VSTICK_NB_BUTTON;j++) {
        valNb=[[NSNumber alloc] initWithInt:joymap_iCade[j].dev_btn];
        [prefs setObject:valNb forKey:[NSString stringWithFormat:@"icademap%02X",j]];
        [valNb release];
    }
    
    for (int i=0;i<DIRS_MAX;i++) {        
        valStr=[NSString stringWithFormat:@"%s",szAppRomPaths[i]];
        keyStr=[NSString stringWithFormat:@"romspath%02X",i];
        [prefs setObject:valStr forKey:keyStr];
    }	
	
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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    int settings_reseted=[self loadSettings];
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(setBrightness:)]) {
        sys_brightness=[UIScreen mainScreen].brightness;
        [[UIScreen mainScreen]setBrightness:ifba_conf.brightness];
    }
    
    /* Set working directory to resource path */
    //NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *documentsDirectory=@"/var/mobile/Documents/iFBA";
    [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:TRUE attributes:nil error:nil];
    [[NSFileManager defaultManager] changeCurrentDirectoryPath: documentsDirectory];
    
#if RELEASE_DEBUG
    strcpy(debug_root_path,[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] UTF8String]);
    strcpy(debug_bundle_path,[[[NSBundle mainBundle] resourcePath] UTF8String]);
#endif
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
    
    //check if retina
    device_retina=0;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        if ([[UIScreen mainScreen] scale]==2) device_retina=1;
    }
    
    self.navController = [[[UINavigationController alloc] init] autorelease];
    [[self.navController navigationBar] setBarStyle:UIBarStyleBlack]; // UIBarStyleDefault];
    //    [[self.navController navigationBar] setTranslucent:YES];
    
    
    
    
    
    
    //****************************************************
    //Init background image with a mosaic of random titles
    //****************************************************    
    int bg_width=[UIScreen mainScreen].applicationFrame.size.width;
    int bg_height=[UIScreen mainScreen].applicationFrame.size.height;
    int bg_max=MAX(bg_width,bg_height);
    UIView *bg_view=[[UIView alloc] initWithFrame:CGRectMake(0,0,bg_max,bg_max)];
    int x,y;
    x=y=0;
    bg_view.backgroundColor=[UIColor blackColor];
    bg_view.frame=CGRectMake(0,0,bg_max,bg_max);
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
        if (x>=bg_max) {
            x=0;
            y+=32;
        }
        [bg_view addSubview:img];
        [img release];
    }
    self.navController.view.backgroundColor=[UIColor colorWithPatternImage:[self imageWithView:bg_view]];
    //*****************************************************
    
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
    nShouldExit=2;
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [self saveSettings];
    if ([[UIScreen mainScreen] respondsToSelector:@selector(setBrightness:)]) {
        [[UIScreen mainScreen]setBrightness:sys_brightness];
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
    if ([[UIScreen mainScreen] respondsToSelector:@selector(setBrightness:)]) {
        sys_brightness=[UIScreen mainScreen].brightness;
        [[UIScreen mainScreen]setBrightness:ifba_conf.brightness];
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
    if ([[UIScreen mainScreen] respondsToSelector:@selector(setBrightness:)]) {
        [[UIScreen mainScreen] setBrightness:sys_brightness];
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
