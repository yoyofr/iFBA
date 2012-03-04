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
    NSMutableArray *romlist[28],*romlistLbl[28];
    NSMutableArray *indexTitles;
    NSMutableArray *burn_supportedRoms,*burn_supportedRomsNames;
}

@property (nonatomic, retain) IBOutlet UITableView *tabView;

@end
