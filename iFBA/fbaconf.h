//
//  fbaconf.h
//  iFBA
//
//  Created by Yohann Magnien on 29/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef iFBA_fbaconf_h
#define iFBA_fbaconf_h

typedef struct {
    unsigned char aspect_ratio;
    unsigned char screen_mode;
    unsigned char filtering;
} ifba_conf_t;

extern ifba_conf_t ifba_conf;


#endif
