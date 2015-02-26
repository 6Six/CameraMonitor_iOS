//
//  Camera2.h
//  IOTCamComponent
//
//  Created by Cloud Hsiao on 12/7/3.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#ifndef IOTCamComponent_Camera2_h
#define IOTCamComponent_Camera2_h
#import "Camera.h"

@interface Camera()
{
    id<CameraDelegate> delegateForMonitor;
}

@property (nonatomic, assign) id<CameraDelegate> delegateForMonitor;

@end
#endif
