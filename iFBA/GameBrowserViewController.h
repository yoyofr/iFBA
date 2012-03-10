//
//  GameBrowserViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>

@interface GameBrowserViewController : UIViewController {
    IBOutlet UITableView *tabView;    
    NSMutableArray *romlist[28],*romlistLbl[28],*rompath[28],*romlistSystem[28];
    NSMutableArray *indexTitles;
    NSMutableArray *burn_supportedRoms,*burn_supportedRomsNames;
    IBOutlet UIBarButtonItem *btn_backToEmu;
}

@property (nonatomic, retain) IBOutlet UITableView *tabView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *btn_backToEmu;

-(IBAction) backToEmu;


@end
