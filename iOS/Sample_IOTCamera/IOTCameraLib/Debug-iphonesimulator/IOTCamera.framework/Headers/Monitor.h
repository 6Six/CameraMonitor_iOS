//
//  Monitor.h
//  IOTCamViewer
//
//  Created by Cloud Hsiao on 1/18/12.
//  Copyright (c) 2012 TUTK. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum 
{
    DirectionNone = 0,
    DirectionTiltUp = 1,
    DirectionTiltDown = 2,
    DirectionPanLeft = 3,
    DirectionPanRight = 4,
} Direction;

@protocol MonitorTouchDelegate;

@interface Monitor : UIImageView {
	CGFloat fScale;
}

@property (nonatomic, assign) IBOutlet id<MonitorTouchDelegate> delegate;

- (void)setMinimumGestureLength:(NSInteger)length MaximumVariance:(NSInteger)variance;
- (void)attachCamera:(Camera *)camera;
- (void)deattachCamera;

@end

@protocol MonitorTouchDelegate <NSObject>
@optional
- (void)monitor:(Monitor *)monitor gestureSwiped:(Direction)direction;
- (void)monitor:(Monitor *)monitor gesturePinched:(CGFloat)scale;
@end

#define PT_SPEED 8
#define PT_DELAY 1.5
