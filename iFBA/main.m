//
//  main.m
//  iFBA
//
//  Created by Yohann Magnien on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

int main(int argc, char *argv[])
{
/*    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }*/
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
    /* Give over control to run loop, SDLUIKitDelegate will handle most things from here */
    int exit_status=UIApplicationMain(argc, argv, NULL, NSStringFromClass([AppDelegate class]));
    
    
    [pool release];
    return exit_status;
}

#if TARGET_IPHONE_SIMULATOR

#include "btstack.h"
#include "wiimote.h"

int bt_send_cmd(const hci_cmd_t *cmd, ...) {
    va_list pvar;
	va_start(pvar, cmd);
    
    return 0;
}
void bt_send_l2cap(uint16_t local_cid, uint8_t *data, uint16_t len) {
    
}

// init BTstack library
int bt_open(void){
    return 0;
}
// stop using BTstack library
int bt_close(void) {
    return 0;
}

void run_loop_init(RUN_LOOP_TYPE type) {
    
}
void bt_flip_addr(bd_addr_t dest, bd_addr_t src) {
    
}

btstack_packet_handler_t bt_register_packet_handler(btstack_packet_handler_t handler) {
    return handler;
}

const hci_cmd_t hci_link_key_request_negative_reply;
const hci_cmd_t hci_link_key_request_reply;


const hci_cmd_t btstack_set_power_mode;
const hci_cmd_t btstack_set_system_bluetooth_enabled;
const hci_cmd_t btstack_get_system_bluetooth_enabled;
const hci_cmd_t hci_inquiry;
const hci_cmd_t hci_remote_name_request;
const hci_cmd_t hci_remote_name_request_cancel;
const hci_cmd_t hci_inquiry_cancel;
const hci_cmd_t hci_delete_stored_link_key;
const hci_cmd_t hci_write_inquiry_mode;
const hci_cmd_t l2cap_create_channel;

#endif