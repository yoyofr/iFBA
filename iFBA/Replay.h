//
//  Replay.h
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


int GetReplayInfo(int slot,char *info);
int GetReplayFileData(int slot,char **data,int *data_length,char *replay_date,int *replay_length);
