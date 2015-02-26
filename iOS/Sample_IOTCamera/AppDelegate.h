//
//  AppDelegate.h
//  IOTCamSample
//
//  Created by Cloud Hsiao on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <IOTCamera/Camera.h>

NSMutableArray *camera_list;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (strong, nonatomic) IBOutlet UITabBarController *rootViewController;

@end
