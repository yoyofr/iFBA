//
//  GameBrowserViewController.h
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>
#import "OptSelGenresViewController.h"

@interface GameBrowserViewController : UIViewController {
    IBOutlet UITableView *tabView;    
    NSMutableArray *romlist,*romlistLbl,*rompath,*romlistSystem,*romlistGenre,*romavail,*sectionLbl,*sectionLblMin;
    NSMutableArray *indexTitles;
    NSMutableArray *burn_supportedRoms,*burn_supportedRomsNames;
    IBOutlet UIBarButtonItem *btn_backToEmu,*btn_missing;
    OptSelGenresViewController *selgenrevc;

}

@property (nonatomic, retain) IBOutlet UITableView *tabView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *btn_backToEmu,*btn_missing;
@property (nonatomic, retain) OptSelGenresViewController *selgenrevc;

-(IBAction) backToEmu;
-(IBAction) showFavorites;
-(IBAction) showMostplayed;
-(IBAction) showGenres;
-(IBAction) showMissing:(id)sender;
-(IBAction) changeFilter:(id)sender;

@end
