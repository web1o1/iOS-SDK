//
//  KernelDefinition.h
//
//  Created by linfish on 13/8/26.
//  Copyright (c) 2013 linfish. All rights reserved.
//

// following controls the kernel doing recognition online or offline
// online mode usually have a larger database then offline
// some license may only support one mode, please set correctly
typedef enum {
    km_online = 0,  // enable kernel with online recognition
    km_offline,     // enable kernel with offline recognition, need call loadKernelData before recognize
    km_sequence     // enable kernel with online then offline recognition, need call loadKernelData for offline recognize
} KernelMode;

// following controls the kernel doing recognition in speed or accuracy
// note that online mode's speed may depend on network status
typedef enum {
    kp_speed = 0,   // prefer speed than accuracy
    kp_balance,     // prefer balance between speed and accuracy
    kp_accurate     // prefer accuracy than speed
} KernelPrefer;

// following defines the error may reported by kernel
// some error depends on setting, some error depends on server or service
typedef enum {
    ke_update_failed = -2,      //         [offline] update offline data failed, kernel will load offline data in device instead
    ke_not_ready = -1,          //         [offline] offline data not exist or kerenl still loading offline data, please wait
    ke_no_error = 0,            // [online][offline]
    ke_unknown_error,           // [online][offline] unexpected error occured
    ke_network_error,           // [online][offline] network connection error, can not connect to server
    ke_username_not_set,        // [online][offline] username not set, please set user name as account
    ke_invalid_username,        // [online][offline] invalid username, please check typo or contact us to check license status
    ke_invalid_bundle_id,       // [online][offline] invalid bundle ID, please set the correct bundle ID with account
    ke_server_down,             // [online][offline] server currently unavailable, please contact us to get more informations
    ke_server_in_maintenance,   // [online][offline] server down for maintenance, please contact us or check website
    ke_service_invalid,         // [online][offline] account has no permission to use service, please make sure kernel mode set correctly for license
    ke_service_expired,         // [online][offline] service of this account is expired, please contact us to extend license
    ke_service_paused,          // [online]          service is currently paused, please restart it on the website
    ke_service_busy             // [online]          service is busy now, please reduce request sending frequency
} KernelError;

