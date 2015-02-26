//
//  Camera.h
//  IOTCamViewer
//
//  Created by Cloud Hsiao on 12/5/11.
//  Copyright (c) 2011 TUTK. All rights reserved.
//

#define CHANNEL_VIDEO_FPS 110
#define CHANNEL_VIDEO_BPS 111
#define CHANNEL_VIDEO_FRAMECOUNT 112
#define CHANNEL_VIDEO_INCOMPLETE_FRAMECOUNT 113
#define CHANNEL_VIDEO_ONLINENM 114

#define CONNECTION_MODE_NONE -1
#define CONNECTION_MODE_P2P 0
#define CONNECTION_MODE_RELAY 1
#define CONNECTION_MODE_LAN 2

/* used for display status */
#define CONNECTION_STATE_NONE 0
#define CONNECTION_STATE_CONNECTING 1
#define CONNECTION_STATE_CONNECTED 2
#define CONNECTION_STATE_DISCONNECTED 3
#define CONNECTION_STATE_UNKNOWN_DEVICE 4
#define CONNECTION_STATE_WRONG_PASSWORD 5
#define CONNECTION_STATE_TIMEOUT 6
#define CONNECTION_STATE_UNSUPPORTED 7
#define CONNECTION_STATE_CONNECT_FAILED 8

typedef struct st_LanSearchInfo LanSearch_t;

struct SUB_STREAM
{
    int index;
    int channel;
};
typedef struct SUB_STREAM SubStream_t;

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol CameraDelegate;

@interface Camera : NSObject { }

@property (copy) NSString *name;
@property (copy, readonly) NSString *uid;
@property (readonly) NSInteger sessionID;
@property (readonly) NSInteger sessionMode;
@property (readonly) NSInteger sessionState;
@property (readonly) NSInteger natD;
@property (readonly) NSInteger natC;
@property (readonly) NSInteger connTimes;
@property (readonly) NSInteger connFailErrCode;
@property (readonly) int nAvResend;
@property (readwrite) unsigned int nRecvFrmPreSec;
@property (readwrite) unsigned int nDispFrmPreSec;

@property (nonatomic, assign) NSMutableDictionary* mobScreenDict;
@property (nonatomic, assign) id<CameraDelegate> delegate;

+ (void)initIOTC;
+ (void)uninitIOTC;
+ (NSString *)getIOTCAPIsVerion;
+ (NSString *)getAVAPIsVersion;
+ (LanSearch_t *)LanSearch:(int *)num timeout:(int)timeoutVal;

- (id)initWithName:(NSString *)name;
- (void)connect:(NSString *)uid;
- (void)connect:(NSString *)uid AesKey:(NSString *)aesKey;
- (void)disconnect;
- (void)start:(NSInteger)channel viewAccount:(NSString *)viewAccount viewPassword:(NSString *)viewPassword is_playback:(BOOL)bPlaybackMode;
- (void)stop:(NSInteger)channel;
- (Boolean)isStarting:(NSInteger)channel;
- (void)startShow:(NSInteger)channel ScreenObject:(NSObject*)obScreen;
- (void)stopShow:(NSInteger)channel;
- (void)startSoundToPhone:(NSInteger)channel;
- (void)stopSoundToPhone:(NSInteger)channel;
- (void)startSoundToDevice:(NSInteger)channel;
- (void)stopSoundToDevice:(NSInteger)channel;
- (void)sendIOCtrlToChannel:(NSInteger)channel Type:(NSInteger)type Data:(char *)buff DataSize:(NSInteger)size;
- (unsigned int)getChannel:(NSInteger)channel Snapshot:(char *)imgData dataSize:(unsigned long)size WithImageWidth:(unsigned int *)width ImageHeight:(unsigned int *)height;
- (unsigned int)getChannel:(NSInteger)channel Snapshot:(char *)imgData DataSize:(unsigned long)size ImageType:(unsigned int*)codec_id WithImageWidth:(unsigned int *)width ImageHeight:(unsigned int *)height;
- (NSString *)getViewAccountOfChannel:(NSInteger)channel;
- (NSString *)getViewPasswordOfChannel:(NSInteger)channel;
- (unsigned long)getServiceTypeOfChannel:(NSInteger)channel;
- (int)getConnectionStateOfChannel:(NSInteger)channel;
@end

@protocol CameraDelegate <NSObject>
@optional
- (void)camera:(Camera *)camera didReceiveRawDataFrame:(const char *)imgData VideoWidth:(NSInteger)width VideoHeight:(NSInteger)height;
- (void)camera:(Camera *)camera didReceiveJPEGDataFrame:(const char *)imgData DataSize:(NSInteger)size;
- (void)camera:(Camera *)camera didReceiveJPEGDataFrame2:(NSData *)imgData;
- (void)camera:(Camera *)camera didReceiveFrameInfoWithVideoWidth:(NSInteger)videoWidth VideoHeight:(NSInteger)videoHeight VideoFPS:(NSInteger)fps VideoBPS:(NSInteger)videoBps AudioBPS:(NSInteger)audioBps OnlineNm:(NSInteger)onlineNm FrameCount:(unsigned long)frameCount IncompleteFrameCount:(unsigned long)incompleteFrameCount;
- (void)camera:(Camera *)camera didChangeSessionStatus:(NSInteger)status;   
- (void)camera:(Camera *)camera didChangeChannelStatus:(NSInteger)channel ChannelStatus:(NSInteger)status;
- (void)camera:(Camera *)camera didReceiveIOCtrlWithType:(NSInteger)type Data:(const char*)data DataSize:(NSInteger)size;

@end


