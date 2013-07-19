//
//  SendReplayController.m
//  iFBA
//
//  Created by Yohann Magnien on 04/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SendReplayController.h"
#import <QuartzCore/QuartzCore.h>
#import "ASIHTTPRequest.h"
#import "fbaconf.h"
#import "Replay.h"

extern char gameName[64];
extern char debug_root_path[512];
extern int device_isIpad;
static int upload_ok;

//iCade & wiimote
#import "iCadeReaderView.h"
#include "wiimote.h"
#import <QuartzCore/CADisplayLink.h>
#import <QuartzCore/QuartzCore.h>
static int ui_current_pos;
static int wiimoteBtnState;
static iCadeReaderView *iCaderv;
static CADisplayLink* m_displayLink;

UIBarButtonItem *dismissKeybBtn;
extern int glob_replay_currentslot;


@implementation SendReplayController
@synthesize cancelBtn,uploadBtn,authorTextField,descrTextView,uploadPrgView;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    
    dismissKeybBtn=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissKbd)];
    
    [[descrTextView layer] setCornerRadius:15.0];
	[[descrTextView layer] setBorderWidth:3.0];
	[[descrTextView layer] setBorderColor:[[UIColor colorWithRed: 0.95f green: 0.95f blue: 0.95f alpha: 1.0f] CGColor]];   //Adding Border color.
    
    //GEt hostname and remove ".local"
    NSArray *nameArray = [[NSHost currentHost] names];
    NSString *tmpStr=[nameArray objectAtIndex:0];
    NSRange r=[tmpStr rangeOfString:@".local"];
    if (r.location!=NSNotFound) {
        tmpStr=[tmpStr substringToIndex:r.location];
    }
    authorTextField.text=tmpStr;
    
    
    [cancelBtn setType:BButtonTypeDanger];
    [uploadBtn setType:BButtonTypePrimary];
    
    //ICADE & Wiimote
    ui_current_pos=0;
    iCaderv = [[iCadeReaderView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:iCaderv];
    [iCaderv changeLang:ifba_conf.icade_lang];
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv release];
    wiimoteBtnState=0;
}

-(void) viewWillAppear:(BOOL)animated {  //Not called in iOS 4.3 simulator... BUG?
    [super viewWillAppear:animated];    
    
    /* Wiimote check => rely on cadisplaylink*/
    m_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(checkWiimote)];
    m_displayLink.frameInterval = 3; //20fps
	[m_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];    
    
    uploadPrgView.progress=0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    iCaderv.active = YES;
    iCaderv.delegate = self;
    [iCaderv becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (m_displayLink) [m_displayLink invalidate];
    m_displayLink=nil;
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void) dealloc {
    [dismissKeybBtn release];
    [super dealloc];
}

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up {
    NSDictionary* userInfo = [aNotification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect newFrame = self.view.frame;
    
    if (keyboardEndFrame.size.height > keyboardEndFrame.size.width)
    {   //we must be in landscape
        if (keyboardEndFrame.origin.x==0)
        {   //upside down so need to flip origin
            newFrame.origin = CGPointMake(keyboardEndFrame.size.width, 0);
        }
        
        newFrame.size.width -= keyboardEndFrame.size.width * (up?1:-1);
        
    } else
    {   //in portrait
        if (keyboardEndFrame.origin.y==0)
        {
            //upside down so need to flip origin
            newFrame.origin = CGPointMake(0, keyboardEndFrame.size.height);
        }
        newFrame.size.height -= keyboardEndFrame.size.height * (up?1:-1);
        
    }
    self.view.frame = newFrame;
    
    [UIView commitAnimations];
}

- (void)keyboardWillShown:(NSNotification*)aNotification
{
//    buttonDone.enabled = true;
    [self moveTextViewForKeyboard:aNotification up:YES];
}

- (void)keyboardWillHide:(NSNotification*)aNotification
{
//    buttonDone.enabled = false;
    [self moveTextViewForKeyboard:aNotification up:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {    
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//    [self.mnview setNeedsLayout];
}

-(void) dismissKbd {
    [self.descrTextView resignFirstResponder];
    [self.authorTextField resignFirstResponder];
    self.navigationItem.rightBarButtonItem=nil;
}

-(void)textViewDidBeginEditing:(UITextView *)textView {
    self.navigationItem.rightBarButtonItem=dismissKeybBtn;
}

- (void)textViewDidChange:(UITextView *)textView {
    // scroll to current line
//    [textView scrollRangeToVisible:NSMakeRange([textView.text length],0)];
}


-(void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem=dismissKeybBtn;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
//    NSLog(@"New text: %@",textField.text);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


- (void)textViewDidEndEditing:(UITextView *)textView {
//    NSLog(@"New text: %@",textView.text);
}

- (int) SendReplay {
    upload_ok=0;
    NSString *author=authorTextField.text;
    NSString *description=[descrTextView.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];//[descrTextView.text stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
    
    //get upload url
    NSURL *urlGetUploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%sauto",IFBAONLINE]];
    NSString *urlString;
    NSURLRequest *requestUpload = [NSURLRequest requestWithURL:urlGetUploadURL];
    
    NSURLResponse *response;
    NSError *error=nil;
    //send it
    NSData *responseData = [NSURLConnection sendSynchronousRequest:requestUpload returningResponse:&response error:&error];
    //    NSLog(@"data length: %d",[responseData length]);
    urlString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    // check for an error. If there is a network error, you should handle it here.
    if(error) {
        NSLog(@"SendReplay error: %@",[error localizedDescription]);
        return -1;
    }
    
    // add file data
    char *replay_data;
    char replay_date[11];
    int replay_length;
    int replay_data_len,err;
    if (err=GetReplayFileData(glob_replay_currentslot,&replay_data,&replay_data_len,replay_date,&replay_length)) {
        NSLog(@"GetReplayFileData: error %d",err);
        return -2;
    }
    NSData *fileData;
    fileData=[NSData dataWithBytes:replay_data length:replay_data_len];
    free(replay_data);
    
//    NSLog(@"url used: %@",urlString);
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
    request.requestMethod=@"POST";
    
//    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
//    [request setURL:[NSURL URLWithString:urlString]];
//    [request setHTTPMethod:@"POST"];
    
    NSMutableData *body = [NSMutableData data];
    
    
    NSString *boundary = [NSString stringWithString:@"0xKhTmLbOuNdArY---This_Is_ThE_BoUnDaRyy---pqo"];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    //[request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request addRequestHeader:@"Content-Type" value:contentType];
    
    
    // Param1: gamename
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"game\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%s",gameName] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    // Param2: date
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"date\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%s",replay_date] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Param3: length(in seconds)
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"length\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"%d",replay_length] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Param4: author
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"author\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:author] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Param5: description
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"desc\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:description] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //replay data
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%s\"\r\n",gameName] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:fileData]];
    [body appendData:[[NSString stringWithString:@"Content-Transfer-Encoding: binary\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    // close form
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // set request body
    //[request setHTTPBody:body];
    [request appendPostData:body];
    

//    [request setDownloadDestinationPath:[NSString stringWithFormat:@"%s",szName]];
    
    [request setUploadProgressDelegate:uploadPrgView];
	[request setDelegate:self];

    [request startAsynchronous];
/*    error = [request error];
    if (!error) {
        NSLog(@"ok");
    } else NSLog(@"ko: %@",[error localizedDescription]);
    
    
    //return and test
    //NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    //NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    NSString *returnString=[request responseString];
    
    NSLog(@"%@", returnString);*/
    return 0;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (upload_ok) [self.navigationController popViewControllerAnimated:TRUE];
}



- (void)requestFinished:(ASIHTTPRequest *)request {
    NSString *returnString=[request responseString];
//    NSLog(@"%@", returnString);
    
    upload_ok=1;
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Information" message:[NSString stringWithFormat:@"Upload successful.",[[request error] localizedDescription]] delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
    [alert show];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
	UIAlertView *alert;
		alert = [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Upload error:\n%@",[[request error] localizedDescription]] delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
		[alert show];
}


-(IBAction) uploadClicked {
    int err=[self SendReplay];
    if (err) {
        UIAlertView *alert;
		alert = [[[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"SendReplay error(%d)",err] delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
		[alert show];
    }
}

-(IBAction) cancelClicked {
    [self.navigationController popViewControllerAnimated:TRUE];
}


#pragma Icade support
/****************************************************/
/****************************************************/
/*        ICADE                                     */
/****************************************************/
/****************************************************/
- (void)buttonDown:(iCadeState)button {
    
    
}
- (void)buttonUp:(iCadeState)button {
    if (button&iCadeJoystickDown) {
    } else if (button&iCadeJoystickUp) {
    } else if (button&iCadeJoystickLeft) {
    } else if (button&iCadeJoystickRight) {
    }else if (button&iCadeButtonA) { //validate
        [self.navigationController popViewControllerAnimated:YES];
    } else if (button&iCadeButtonB) { //back
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma Wiimote/iCP support
#define WII_BUTTON_UP(A) (wiimoteBtnState&A)&& !(pressedBtn&A)
-(void) checkWiimote {
    if (num_of_joys==0) return;
    int pressedBtn=iOS_wiimote_check(&(joys[0]));
    
    if (WII_BUTTON_UP(WII_JOY_DOWN)) {
        [self buttonUp:iCadeJoystickDown];
    } else if (WII_BUTTON_UP(WII_JOY_UP)) {
        [self buttonUp:iCadeJoystickUp];
    } else if (WII_BUTTON_UP(WII_JOY_LEFT)) {
        [self buttonUp:iCadeJoystickLeft];
    } else if (WII_BUTTON_UP(WII_JOY_RIGHT)) {
        [self buttonUp:iCadeJoystickRight];
    } else if (WII_BUTTON_UP(WII_JOY_A)) {
        [self buttonUp:iCadeButtonA];
    } else if (WII_BUTTON_UP(WII_JOY_B)) {
        [self buttonUp:iCadeButtonB];
    } else if (WII_BUTTON_UP(WII_JOY_C)) {
        [self buttonUp:iCadeButtonC];
    } else if (WII_BUTTON_UP(WII_JOY_D)) {
        [self buttonUp:iCadeButtonD];
    } else if (WII_BUTTON_UP(WII_JOY_E)) {
        [self buttonUp:iCadeButtonE];
    } else if (WII_BUTTON_UP(WII_JOY_F)) {
        [self buttonUp:iCadeButtonF];
    } else if (WII_BUTTON_UP(WII_JOY_G)) {
        [self buttonUp:iCadeButtonG];
    } else if (WII_BUTTON_UP(WII_JOY_H)) {
        [self buttonUp:iCadeButtonH];
    }
    
    
    wiimoteBtnState=pressedBtn;
}




@end
