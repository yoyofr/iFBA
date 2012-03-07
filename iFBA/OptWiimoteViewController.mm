//
//  OptWiimoteViewController.m
//  iFBA
//
//  Created by Yohann Magnien on 28/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OptWiimoteViewController.h"
#import "OptWiimoteBtnViewController.h"
#import "BTstack/BTDevice.h"
#import "BTstack/btstack.h"
#import "BTstack/run_loop.h"
#import "BTstack/hci_cmds.h"
#import "BTstack/wiimote.h"

#import "fbaconf.h"

int wiimoteSelected;


@implementation OptWiimoteViewController
@synthesize tabView;
@synthesize showIcons;
@synthesize customActivityText;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title=NSLocalizedString(@"Wiimote",@"");
        
        macAddressFont = [UIFont fontWithName:@"Courier New" size:[UIFont labelFontSize]];
        deviceNameFont = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
        inquiryState = kInquiryInactive;
        connectingIndex = -1;
        
        deviceActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [deviceActivity startAnimating];
        bluetoothActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [bluetoothActivity startAnimating];
        
        bt = [BTstackManager sharedInstance];
        
        if (bt) [bt addListener:self];
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
    
//        [bt addListener:self];     
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    if (bt&&ifba_conf.btstack_on) {
//        [bt setDelegate:self];
//        [bt addListener:self];
//        [bt activate];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
//    if (bt&&ifba_conf.btstack_on) [bt deactivate];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
	return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section==0) return 1;
    if (section==1) return 4;
    if (section==2) return 1 + [bt numberOfDevicesFound];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title=nil;
    switch (section) {
        case 0:title=NSLocalizedString(@"Bluetooth",@"");
            break;
        case 1:title=NSLocalizedString(@"Mapping",@"");
            break;
        case 2:title=NSLocalizedString(@"Devices",@"");
            break;
    }
    return title;
}

- (void)switchWiimoteMode:(id)sender {
    ifba_conf.btstack_on =((UISwitch*)sender).on;
    if (bt) {
        if (ifba_conf.btstack_on) [bt activate];
        else {
            [bt stopDiscovery];
            [bt deactivate];
        }
        [tabView reloadData];
    } else ifba_conf.btstack_on =((UISwitch*)sender).on=0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *footer=nil;
    switch (section) {
        case 0://Wiimode mode
            if (ifba_conf.btstack_on) {
                footer=NSLocalizedString(@"BTStack on",@"");
            } else {
                footer=NSLocalizedString(@"BTStack off",@"");
            }
            break;
    }
    return footer;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UISwitch *switchview;
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];                
    }
    cell.accessoryType=UITableViewCellAccessoryNone;
    switch (indexPath.section) {
        case 0://Wiimote mode
            cell.textLabel.text=NSLocalizedString(@"BTStack",@"");
            switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
            [switchview addTarget:self action:@selector(switchWiimoteMode:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchview;
            [switchview release];
            switchview.on=ifba_conf.btstack_on;
            break;
        case 1://Mapping
            cell.textLabel.text=[NSString stringWithFormat:@"Wiimote %d",indexPath.row];
            cell.accessoryView = nil;
            cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
            break;
        case 2://Bluetooth devices
            // Set up the cell...
            NSString *theLabel = nil;
            UIImage *theImage = nil;
            UIFont *theFont = nil;
            
            int idx = [indexPath indexAtPosition:1];
            if (idx >= [bt numberOfDevicesFound]) {
                if (customActivityText) {
                    theLabel = customActivityText;
                    cell.accessoryView = bluetoothActivity;
                } else if ([bt isActivating]){
                    theLabel = @"Activating BTstack...";
                    cell.accessoryView = bluetoothActivity;
                } else if (![bt isActive]){
                    theLabel = @"Bluetooth not accessible!";
                    cell.accessoryView = nil;
                } else {
                    
#if 0
                    if (connectedDevice) {
                        theLabel = @"Disconnect";
                        cell.accessoryView = nil;
                    }
#endif
                    
                    if (connectingIndex >= 0) {
                        theLabel = @"Connecting...";
                        cell.accessoryView = bluetoothActivity;
                    } else {
                        switch (inquiryState){
                            case kInquiryInactive:
                                if ([bt numberOfDevicesFound] > 0){
                                    theLabel = @"Find more devices...";
                                } else {
                                    theLabel = @"Find devices...";
                                }
                                cell.accessoryView = nil;
                                break;
                            case kInquiryActive:
                                theLabel = @"Searching...";
                                cell.accessoryView = bluetoothActivity;
                                break;
                            case kInquiryRemoteName:
                                theLabel = @"Query device names...";
                                cell.accessoryView = bluetoothActivity;
                                break;
                        }
                    }
                }
            } else {
                
                BTDevice *dev = [bt deviceAtIndex:idx];
                
                // pick font
                theLabel = [dev nameOrAddress];
                if ([dev name]){
                    theFont = deviceNameFont;
                } else {
                    theFont = macAddressFont;
                }
                
                // pick an icon for the devices
                if (showIcons) {
                    NSString *imageName = @"bluetooth.png";
                    // check major device class
                    switch (([dev classOfDevice] & 0x1f00) >> 8) {
                        case 0x01:
                            imageName = @"computer.png";
                            break;
                        case 0x02:
                            imageName = @"smartphone.png";
                            break;
                        case 0x05:
                            switch ([dev classOfDevice] & 0xff){
                                case 0x40:
                                    imageName = @"keyboard.png";
                                    break;
                                case 0x80:
                                    imageName = @"mouse.png";
                                    break;
                                case 0xc0:
                                    imageName = @"keyboard.png";
                                    break;
                                default:
                                    imageName = @"HID.png";
                                    break;
                            }
                    }
                    
#ifdef LASER_KB
                    if ([dev name] && [[dev name] isEqualToString:@"CL800BT"]){
                        imageName = @"keyboard.png";
                    }
                    
                    if ([dev name] && [[dev name] isEqualToString:@"CL850"]){
                        imageName = @"keyboard.png";
                    }
                    
                    // Celluon CL800BT, CL850 have 00-0b-24-aa-bb-cc, COD 0x400210
                    uint8_t *addr = (uint8_t *) [dev address];
                    if (addr[0] == 0x00 && addr[1] == 0x0b && addr[2] == 0x24){
                        imageName = @"keyboard.png";
                    }
#endif
                    theImage = [UIImage imageNamed:imageName];
                }
                
                // set accessory view
                if (idx == connectingIndex){
                    cell.accessoryView = deviceActivity;
                } else {
                    cell.accessoryView = nil;
                }
            }
            if (theLabel) cell.textLabel.text =  theLabel;
            if (theFont)  cell.textLabel.font =  theFont;
            if (theImage) cell.imageView.image = theImage; 
    }
    
	
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section==1) {
        wiimoteSelected=indexPath.row;
        OptWiimoteBtnViewController *vc=[[OptWiimoteBtnViewController alloc] initWithNibName:@"OptWiimoteBtnViewController" bundle:nil];
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
        [tabView reloadData];
    }
}

-(void) reload{
	[self.tabView reloadData];
}


// BTstackManagerListenerDelegate
-(void) activatedBTstackManager:(BTstackManager*) manager{
	[self reload];
}
-(void) btstackManager:(BTstackManager*)manager activationFailed:(BTstackError)error {
	[self reload];
}
-(void) discoveryInquiryBTstackManager:(BTstackManager*) manager {
	inquiryState = kInquiryActive;
	[self reload];
}
-(void) btstackManager:(BTstackManager*)manager discoveryQueryRemoteName:(int)deviceIndex {
	inquiryState = kInquiryRemoteName;
	remoteNameIndex = deviceIndex;
	[self reload];
}
-(void) discoveryStoppedBTstackManager:(BTstackManager*) manager {
	inquiryState = kInquiryInactive;
	[self reload];
}
-(void) btstackManager:(BTstackManager*)manager deviceInfo:(BTDevice*)device {
	[self reload];
}

-(void) markConnecting:(int)index; {
	connectingIndex = index;
	[self reload];
}

-(void) setCustomActivityText:(NSString*) text{
	[text retain];
	[customActivityText release];
	customActivityText = text;
	[self reload];
}

// MARK: Table view methods
/*- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!_delegate) return nil;
	int index = [indexPath indexAtPosition:1];
	if (index >= [bt numberOfDevicesFound]){
		if ([_delegate respondsToSelector:@selector(statusCellSelectedDiscoveryView:)]){
			[_delegate statusCellSelectedDiscoveryView:self];
			return nil;
		}
	}
	if ([_delegate respondsToSelector:@selector(discoveryView:willSelectDeviceAtIndex:)] && [_delegate discoveryView:self willSelectDeviceAtIndex:index]){
		return indexPath;
	}
	return nil;
}
*/
@end
