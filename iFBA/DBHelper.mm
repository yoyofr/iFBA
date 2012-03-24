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


void DBHelper::getGameInfo(const char *gameName,char *gameInfo) {
	NSString *pathToDB=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"iFBA.db"];
	sqlite3 *db;
	int err;	
	NSString *result=nil;
    
    if (!gameInfo) return;
    gameInfo[0]=0;
	
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