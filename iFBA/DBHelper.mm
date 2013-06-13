/*
 *  DBHelper.cpp
 *  iFBA
 *
 *  Created by Yohann Magnien on 24/03/12.
 *  Copyright 2012 __YoyoFR / Yohann Magnien__. All rights reserved.
 *
 */
#include "DBHelper.h"

#include "sqlite3.h"
#include <pthread.h>
pthread_mutex_t db_mutex;

void DBHelper::createDB() {
    NSError *error;
    NSString *pathToDBTemplate=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"iFBA.db"];
    
    NSString *pathToDB=[NSString stringWithFormat:@"%@/iFBA.db",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"]];
    
    NSFileManager *fileManager=[[NSFileManager alloc] init];
    [fileManager copyItemAtPath:pathToDBTemplate toPath:pathToDB error:&error];
    [fileManager release];
}

void DBHelper::setGameStats(const char *gameName,int playCount,int fav,char *lastPlayed,int playTime) {
    NSString *pathToDB=[NSString stringWithFormat:@"%@/iFBA.db",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"]];
	sqlite3 *db;
	int err;
    BOOL success;
    
    NSFileManager *fileManager=[[NSFileManager alloc] init];
    success = [fileManager fileExistsAtPath:pathToDB];
    [fileManager release];
    if (!success) createDB();
    
	pthread_mutex_lock(&db_mutex);
	
	if (sqlite3_open([pathToDB UTF8String], &db) == SQLITE_OK){
		char sqlStatement[1024];
        
        sprintf(sqlStatement,"DELETE FROM play_stats WHERE game_name=\"%s\"",gameName);
        err=sqlite3_exec(db, sqlStatement, NULL, NULL, NULL);
        if (err==SQLITE_OK){
        } else NSLog(@"ErrSQL : %d",err);
		
        sprintf(sqlStatement,"INSERT INTO play_stats (game_name,play_count,fav,last_play,play_time) SELECT \"%s\",%d,%d,\"%s\",%d",gameName,playCount,fav,lastPlayed,playTime);
        err=sqlite3_exec(db, sqlStatement, NULL, NULL, NULL);
        if (err==SQLITE_OK){
        } else NSLog(@"ErrSQL : %d",err);
	};
	sqlite3_close(db);
	
	pthread_mutex_unlock(&db_mutex);
}
void DBHelper::getGameStats(const char *gameName,int *playCount,int *fav,char *lastPlayed,int *playTime) {
    NSString *pathToDB=[NSString stringWithFormat:@"%@/iFBA.db",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"]];
	sqlite3 *db;
	int err;
    BOOL success;
    
    NSFileManager *fileManager=[[NSFileManager alloc] init];
    success = [fileManager fileExistsAtPath:pathToDB];
    [fileManager release];
    if (!success) createDB();
    
    
    if (playCount) *playCount=0;
    if (fav) *fav=0;
    if (lastPlayed) lastPlayed[0]=0;
    if (playTime) *playTime=0;
    
	pthread_mutex_lock(&db_mutex);
	
	if (sqlite3_open([pathToDB UTF8String], &db) == SQLITE_OK){
		char sqlStatement[1024];
		sqlite3_stmt *stmt;
		
		sprintf(sqlStatement,"SELECT play_count,fav,last_play,play_time FROM play_stats WHERE game_name=\"%s\"",gameName);
		
		err=sqlite3_prepare_v2(db, sqlStatement, -1, &stmt, NULL);
		if (err==SQLITE_OK){
			while (sqlite3_step(stmt) == SQLITE_ROW) {
                if (playCount) *playCount=sqlite3_column_int(stmt,0);
                if (fav) *fav=sqlite3_column_int(stmt,1);
                if (lastPlayed) strcpy(lastPlayed,(const char*)sqlite3_column_text(stmt,2));
                if (playTime) *playTime=sqlite3_column_int(stmt,3);
			}
			sqlite3_finalize(stmt);
		} else NSLog(@"ErrSQL : %d",err);
	};
	sqlite3_close(db);
	
	pthread_mutex_unlock(&db_mutex);
}

void DBHelper::getGameInfo(const char *gameName,char *gameInfo) {
	NSString *pathToDB=[NSString stringWithFormat:@"%@/iFBA.db",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"]];
	sqlite3 *db;
	int err;
    BOOL success;
    
    if (!gameInfo) return;
    gameInfo[0]=0;
    
    
    NSFileManager *fileManager=[[NSFileManager alloc] init];
    success = [fileManager fileExistsAtPath:pathToDB];
    [fileManager release];
    if (!success) createDB();
	
	pthread_mutex_lock(&db_mutex);
	
	if (sqlite3_open([pathToDB UTF8String], &db) == SQLITE_OK){
		char sqlStatement[1024];
		sqlite3_stmt *stmt;
		
		sprintf(sqlStatement,"SELECT i.info FROM history_game g,history_info i WHERE i.game_id=g.game_id and g.game_name=\"%s\"",gameName);
		
		err=sqlite3_prepare_v2(db, sqlStatement, -1, &stmt, NULL);
		if (err==SQLITE_OK){
			while (sqlite3_step(stmt) == SQLITE_ROW) {
                int i=0,j=0;
                char c;
                char *result_str=(char*)sqlite3_column_text(stmt, 0);
                while (c=result_str[i++]) {
                    if (c!='\\') gameInfo[j++]=c;
                    else {
                        if (result_str[i]=='n') {
                            i++;
                            gameInfo[j++]='\n';
                        } else gameInfo[j++]=c;
                    }
                }
                gameInfo[j]=0;
			}
			sqlite3_finalize(stmt);
		} else NSLog(@"ErrSQL : %d",err);
	};
	sqlite3_close(db);
	
	pthread_mutex_unlock(&db_mutex);
}