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

#ifdef RELEASE_DEBUG
    NSString *pathToDB=[NSString stringWithFormat:@"%@/iFBA.db",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"]];
#else
    NSString *pathToDB=[NSString stringWithFormat:@"/var/mobile/Documents/iFBA/iFBA.db"];
#endif
    NSFileManager *fileManager=[[NSFileManager alloc] init];
    [fileManager copyItemAtPath:pathToDBTemplate toPath:pathToDB error:&error];
    [fileManager release];
}

void DBHelper::setGameStats(const char *gameName,int playCount,int fav,char *lastPlayed,int playTime) {
#ifdef RELEASE_DEBUG
    NSString *pathToDB=[NSString stringWithFormat:@"%@/iFBA.db",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"]];
#else
    NSString *pathToDB=[NSString stringWithFormat:@"/var/mobile/Documents/iFBA/iFBA.db"];
#endif
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
#ifdef RELEASE_DEBUG
    NSString *pathToDB=[NSString stringWithFormat:@"%@/iFBA.db",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"]];
#else
    NSString *pathToDB=[NSString stringWithFormat:@"/var/mobile/Documents/iFBA/iFBA.db"];
#endif
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
#ifdef RELEASE_DEBUG
    NSString *pathToDB=[NSString stringWithFormat:@"%@/iFBA.db",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"]];
#else
    NSString *pathToDB=[NSString stringWithFormat:@"/var/mobile/Documents/iFBA/iFBA.db"];
#endif
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

int DBHelper::getFavGames(char ***gameNameA) {
    int nbEntries=0;
    return nbEntries;
}

void DBHelper::freeFavGames(int nbEntries,char ***gameNameA) {
    if (nbEntries>0) {
        for (int i=0;i<nbEntries;i++) {
            if ((*gameNameA)[i]) free((*gameNameA)[i]);
        }
        free(*gameNameA);
    }
}


void DBHelper::freeMostPlayedGames(int nbEntries,char ***gameNameA,int **playCountA) {
    if (nbEntries>0) {
        for (int i=0;i<nbEntries;i++) {
            if ((*gameNameA)[i]) free((*gameNameA)[i]);
        }
        free(*playCountA);
        free(*gameNameA);
    }
}

int DBHelper::getMostPlayedGames(char ***gameNameA,int **playCountA) {
#ifdef RELEASE_DEBUG
    NSString *pathToDB=[NSString stringWithFormat:@"%@/iFBA.db",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"]];
#else
    NSString *pathToDB=[NSString stringWithFormat:@"/var/mobile/Documents/iFBA/iFBA.db"];
#endif
	sqlite3 *db;
	int err;
    BOOL success;
    int nbEntries;
    
    nbEntries=0;
    if (!gameNameA) return 0;
    if (!playCountA) return 0;
    
    NSFileManager *fileManager=[[NSFileManager alloc] init];
    success = [fileManager fileExistsAtPath:pathToDB];
    [fileManager release];
    if (!success) createDB();
	
	pthread_mutex_lock(&db_mutex);
    
    if (sqlite3_open([pathToDB UTF8String], &db) == SQLITE_OK){
		char sqlStatement[1024];
		sqlite3_stmt *stmt;
		
		sprintf(sqlStatement,"SELECT COUNT(1) FROM play_stats WHERE play_count>0");
		
		err=sqlite3_prepare_v2(db, sqlStatement, -1, &stmt, NULL);
		if (err==SQLITE_OK){
			while (sqlite3_step(stmt) == SQLITE_ROW) {
                nbEntries=sqlite3_column_int(stmt, 0);
			}
			sqlite3_finalize(stmt);
		} else NSLog(@"ErrSQL : %d",err);
	}
    
    if (nbEntries>0) {
		char sqlStatement[1024];
		sqlite3_stmt *stmt;
        int idx=0;
        
        *gameNameA=(char**)malloc(nbEntries*sizeof(char*));
        *playCountA=(int*)malloc(nbEntries*sizeof(int));
		
		sprintf(sqlStatement,"SELECT game_name,play_count FROM play_stats WHERE play_count>0 ORDER BY play_count DESC");
		
		err=sqlite3_prepare_v2(db, sqlStatement, -1, &stmt, NULL);
		if (err==SQLITE_OK){
			while (sqlite3_step(stmt) == SQLITE_ROW) {
                char *strGame=(char*)sqlite3_column_text(stmt, 0);
                
                (*gameNameA)[idx]=(char*)malloc(strlen(strGame)+1);
                strcpy((*gameNameA)[idx],strGame);
                (*playCountA)[idx]=sqlite3_column_int(stmt,1);
                idx++;
			}
			sqlite3_finalize(stmt);
		} else NSLog(@"ErrSQL : %d",err);
    }
    
	sqlite3_close(db);
	
	pthread_mutex_unlock(&db_mutex);
    
    return nbEntries;
}