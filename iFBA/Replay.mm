//
//  Replay.mm
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#include "string.h"
#include "burner.h"
#include "fbaconf.h"

extern char gameName[64];
extern char debug_root_path[512];

int GetReplayInfo(int slot,char *info) {
    FILE *f;
    char szName[256];
#ifdef RELEASE_DEBUG
    sprintf(szName, "%s/%s.%02d.replay", debug_root_path,gameName,slot);
#else
    sprintf(szName, "/var/mobile/Documents/iFBA/%s.%02d.replay", gameName,slot);
#endif
    
    NSError *err;
    NSDictionary *finfo;
    finfo=[[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%s",szName] error:&err];
    if (finfo==nil) return -1;
    NSDate *fdate=finfo.fileModificationDate;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSString *dateStr=[dateFormatter stringFromDate:fdate];
    
    f=fopen(szName,"rb");
    if (!f) {
        //        NSLog(@"cannot read replay");
        return -1;
    } else {
        char szHeader[7];
        signed int tmpFPS;
        int framecpt,index_max;
        fread(szHeader,6,1,f);
        szHeader[6]=0;
        fread((void*)&framecpt,sizeof(framecpt),1,f);
        fread((void*)&index_max,sizeof(index_max),1,f);
        fread((void*)&tmpFPS,sizeof(tmpFPS),1,f);
        if (index_max>MAX_REPLAY_DATA_BYTES) {
            NSLog(@"Replay file corrupted: wrong max value for replay_index_max");
            fclose(f);
            return -2;
        } else {
            sprintf(info,"%s - %d:%02d",[dateStr UTF8String],framecpt*100/tmpFPS/60,(framecpt*100/tmpFPS)%60,(index_max+18)/1024);
        }
        fclose(f);
    }
    return 0;
}

int GetReplayFileData(int slot,char **data,int *data_length,char *replay_date,int *replay_length) {
    FILE *f;
    char szName[256];
#ifdef RELEASE_DEBUG
    sprintf(szName, "%s/%s.%02d.replay", debug_root_path,gameName,slot);
#else
    sprintf(szName, "/var/mobile/Documents/iFBA/%s.%02d.replay", gameName,slot);
#endif
    
    NSError *err;
    NSDictionary *finfo;
    finfo=[[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%s",szName] error:&err];
    if (finfo==nil) return -1;
    NSDate *fdate=finfo.fileModificationDate;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSString *dateStr=[dateFormatter stringFromDate:fdate];
    
    f=fopen(szName,"rb");
    if (!f) {
        //        NSLog(@"cannot read replay");
        return -1;
    } else {
        char szHeader[7];
        signed int tmpFPS;
        int framecpt,index_max,length;
        fread(szHeader,6,1,f);
        szHeader[6]=0;
        fread((void*)&framecpt,sizeof(framecpt),1,f);
        fread((void*)&index_max,sizeof(index_max),1,f);
        fread((void*)&tmpFPS,sizeof(tmpFPS),1,f);
        if (index_max>MAX_REPLAY_DATA_BYTES) {
            NSLog(@"Replay file corrupted: wrong max value for replay_index_max");
            fclose(f);
            return -2;
        } else {
            //sprintf(info,"%s - %d:%02d",[dateStr UTF8String],framecpt*100/tmpFPS/60,(framecpt*100/tmpFPS)%60,(index_max+18)/1024);
            sprintf(replay_date,"%s",[dateStr UTF8String]);
            *replay_length=framecpt*100/tmpFPS;
        }
        fseek(f,0,SEEK_END);
        length=ftell(f);
        fseek(f,0,SEEK_SET);
        *data_length=length;
        *data=(char*)malloc(length);
        if (*data) fread(*data,*data_length,1,f);
        else {
            NSLog(@"GetReplayFileData: Cannot allocate memory");
            fclose(f);
            return -3;
        }
        
        fclose(f);
    }
    return 0;
}
