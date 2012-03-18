//
//  OptVideoViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptVideoViewController.h"
#import "MNEValueTrackingSlider.h"

#import "fbaconf.h"

extern volatile int emuThread_running;
extern int launchGame;
extern char gameName[64];

@implementation OptVideoViewController
@synthesize tabView,btn_backToEmu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"Video",@"");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //
    // Change the properties of the imageView and tableView (these could be set
    // in interface builder instead).
    //
    //self.tabView.style=UITableViewStyleGrouped;
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (emuThread_running) {
        btn_backToEmu.title=[NSString stringWithFormat:@"%s",gameName];
        self.navigationItem.rightBarButtonItem = btn_backToEmu;
    }    
    [tabView reloadData];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 8;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section==2) return 2;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    return title;
}




- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    switch (section) {
        case 0://Aspect Ratio
            if (ifba_conf.aspect_ratio) {
                footer=NSLocalizedString(@"Respect original game's aspect ratio",@"");
            } else {
                footer=NSLocalizedString(@"Don't respect original game's aspect ratio",@"");
            }
            break;
        case 1://Screen mode
            switch (ifba_conf.screen_mode) {
                case 0:
                    footer=NSLocalizedString(@"Original resolution",@"");
                    break;
                case 1:
                    footer=NSLocalizedString(@"Scaled resolution with vpad",@"");
                    break;
                case 2:
                    footer=NSLocalizedString(@"Fullscreen",@"");
                    break;
            }
            break;
        case 2://Video Filter
            switch (ifba_conf.video_filter) {
                case 0:
                    footer=NSLocalizedString(@"No filter",@"");
                    break;
                case 1:
                    footer=NSLocalizedString(@"Scanline",@"");
                    break;
                case 2:
                    footer=NSLocalizedString(@"CRT",@"");
                    break;
            }
            break;
        case 3://Filtering
            switch (ifba_conf.filtering) {
                case 0:
                    footer=NSLocalizedString(@"No filtering",@"");
                    break;
                case 1:
                    footer=NSLocalizedString(@"Linear filtering",@"");
                    break;
            }
            break;
        case 4://show fps
            switch (ifba_conf.show_fps) {
                case 0:
                    footer=NSLocalizedString(@"Do not display fps",@"");
                    break;
                case 1:
                    footer=NSLocalizedString(@"Display fps",@"");
                    break;
            }
            break;
        case 5://60Hz
            switch (ifba_conf.video_60hz) {
                case 0:
                    footer=NSLocalizedString(@"Correct timing",@"");
                    break;
                case 1:
                    footer=NSLocalizedString(@"Force 60Hz for smoother video",@"");
                    break;
            }
            break;
        case 6://brightness
            footer=nil;
            break;
        case 7://frameskip
            footer=nil;
            break;
    }
    return footer;
}

- (void)segActionVideoMode:(id)sender {
    int refresh=0;
    if (ifba_conf.screen_mode!=[sender selectedSegmentIndex]) refresh=1;
    ifba_conf.screen_mode=[sender selectedSegmentIndex];
    if (refresh) [tabView reloadData];
}
- (void)segActionVideoFilter:(id)sender {
    int refresh=0;
    if (ifba_conf.video_filter!=[sender selectedSegmentIndex]) refresh=1;
    ifba_conf.video_filter=[sender selectedSegmentIndex];
    if (refresh) [tabView reloadData];
}

- (void)switch60Hz:(id)sender {
    ifba_conf.video_60hz =((UISwitch*)sender).on;
    [tabView reloadData];
}

- (void)switchAspectRatio:(id)sender {
    ifba_conf.aspect_ratio =((UISwitch*)sender).on;
    [tabView reloadData];
}
- (void)switchFiltering:(id)sender {
    ifba_conf.filtering =((UISwitch*)sender).on;
    [tabView reloadData];
}
- (void)switchShowFPS:(id)sender {
    ifba_conf.show_fps =((UISwitch*)sender).on;
    [tabView reloadData];
}
-(void)sliderBrightness:(id)sender {
    ifba_conf.brightness=((UISlider*)sender).value;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(setBrightness)]) [[UIScreen mainScreen] setBrightness:ifba_conf.brightness];
    //    [tabView reloadData];
}
-(void)sliderFilterStrength:(id)sender {
    ifba_conf.video_filter_strength=((UISlider*)sender).value;
    //    [tabView reloadData];
}

-(void)sliderFSkip:(id)sender {
    ifba_conf.video_fskip=((MNEValueTrackingSlider*)sender).value;
    if (ifba_conf.video_fskip==10) [((MNEValueTrackingSlider*)sender) setValue:10 sValue:@"AUTO"];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UISwitch *switchview;
    UISegmentedControl *segconview;
    MNEValueTrackingSlider *sliderview;
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];  
    }
    cell.accessoryType=UITableViewCellAccessoryNone;
    switch (indexPath.section) {
        case 0://Aspect Ratio
            cell.textLabel.text=NSLocalizedString(@"Aspect Ratio",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switchAspectRatio:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=ifba_conf.aspect_ratio;
            break;
        case 1://Screen mode
            cell.textLabel.text=NSLocalizedString(@"Screen mode",@"");
            
            segconview = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@" 1 ", @" 2 ", @" 3 ", nil]];
            segconview.selectedSegmentIndex=ifba_conf.screen_mode;
            
            segconview.segmentedControlStyle = UISegmentedControlStylePlain;
            [segconview addTarget:self action:@selector(segActionVideoMode:) forControlEvents:UIControlEventValueChanged];            
            cell.accessoryView = segconview;
            [segconview release];
            
            break;
        case 2://Video Filters
            if (indexPath.row==0) {
            cell.textLabel.text=NSLocalizedString(@"Video filter",@"");
            segconview = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@" 0 ", @" 1 ", @" 2 ", nil]];
            segconview.segmentedControlStyle = UISegmentedControlStylePlain;
            [segconview addTarget:self action:@selector(segActionVideoFilter:) forControlEvents:UIControlEventValueChanged];            
            cell.accessoryView = segconview;
            [segconview release];
            segconview.selectedSegmentIndex=ifba_conf.video_filter;
            } else { //strength
                cell.textLabel.text=NSLocalizedString(@"Video filter strength",@"");
                sliderview = [[MNEValueTrackingSlider alloc] initWithFrame:CGRectMake(0,0,140,30)];                
                [sliderview setMaximumValue:255.0f];
                [sliderview setMinimumValue:0];
                [sliderview setContinuous:true];
                [sliderview addTarget:self action:@selector(sliderFilterStrength:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = sliderview;
                [sliderview release];
                sliderview.value=ifba_conf.video_filter_strength;
            }
            break;
        case 3://Filtering
            cell.textLabel.text=NSLocalizedString(@"Filtering",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switchFiltering:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=ifba_conf.filtering;
            break;
        case 4://Show FPS
            cell.textLabel.text=NSLocalizedString(@"Show FPS",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switchShowFPS:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=ifba_conf.show_fps;
            break;
        case 5://60Hz
            cell.textLabel.text=NSLocalizedString(@"60Hz",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switch60Hz:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=ifba_conf.video_60hz;
            break;
        case 6://Brightness
            cell.textLabel.text=NSLocalizedString(@"Brightness",@"");
            sliderview = [[MNEValueTrackingSlider alloc] initWithFrame:CGRectMake(0,0,140,30)];
            [sliderview setMaximumValue:1.0f];
            [sliderview setMinimumValue:0];
            [sliderview setContinuous:true];
            sliderview.value=ifba_conf.brightness;            
            
            [sliderview addTarget:self action:@selector(sliderBrightness:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sliderview;
            [sliderview release];
            if ([[UIScreen mainScreen] respondsToSelector:@selector(setBrightness)]==NO) sliderview.enabled=NO; 
            break;
        case 7://Frameskipping
            cell.textLabel.text=NSLocalizedString(@"Frameskip",@"");
            sliderview = [[MNEValueTrackingSlider alloc] initWithFrame:CGRectMake(0,0,140,30)];
            [sliderview setMaximumValue:10.0f];
            [sliderview setMinimumValue:0];
            [sliderview setContinuous:true];
            sliderview.value=ifba_conf.video_fskip;
            if (ifba_conf.video_fskip==10) [sliderview setValue:10 sValue:@"AUTO"];
            [sliderview addTarget:self action:@selector(sliderFSkip:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sliderview;
            [sliderview release];
            break;
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

-(IBAction) backToEmu {
    launchGame=2;
    [self.navigationController popToRootViewControllerAnimated:NO];
}

@end
