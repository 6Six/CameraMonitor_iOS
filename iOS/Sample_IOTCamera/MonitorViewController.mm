//
//  AppMonitorViewController.m
//  IOTCamSample
//
//  Created by Cloud Hsiao on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MonitorViewController.h"
#import <IOTCamera/AVFRAMEINFO.h>
#import <IOTCamera/ImageBuffInfo.h>
#import <sys/time.h>

unsigned int _getTickCount() {
    
	struct timeval tv;
    
	if (gettimeofday(&tv, NULL) != 0)
        return 0;
    
	return (tv.tv_sec * 1000 + tv.tv_usec / 1000);
}

@interface MonitorViewController ()

@end

@implementation MonitorViewController

@synthesize bStopShowCompletedLock;
@synthesize mCodecId;
@synthesize glView;
@synthesize mPixelBufferPool;
@synthesize mPixelBuffer;
@synthesize mSizePixelBuffer;
@synthesize camera;
@synthesize monitor;

#define DEF_WAIT4STOPSHOW_TIME	250

static NSString *kYourCameraAddress = @"YOURCAMERAADDRESS";
static NSString *kYourAccount = @"ACCOUNT";
static NSString *kYourPassword = @"PASSWORD";

- (IBAction)back:(id)sender
{
    [monitor deattachCamera];
    
    [camera stopSoundToPhone:0];
    [camera stopShow:0];
	[self waitStopShowCompleted:DEF_WAIT4STOPSHOW_TIME];
    [camera stop:0];
    [camera disconnect];
    [camera setDelegate:nil];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationItem.title = @"Monitor";
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(back:)];
    self.navigationItem.leftBarButtonItem = backButton;
    [backButton release];
    
    [camera setDelegate:self];
    [camera connect:kYourCameraAddress];
    [camera start:0 viewAccount:kYourAccount viewPassword:kYourPassword is_playback:FALSE];
    
	[camera startShow:0 ScreenObject:self];
    
	//[camera startSoundToPhone:0];
    
    [monitor attachCamera:camera];


	[self removeGLView:TRUE];
	NSLog( @"video frame {%d,%d}%dx%d", (int)self.monitor.frame.origin.x, (int)self.monitor.frame.origin.y, (int)self.monitor.frame.size.width, (int)self.monitor.frame.size.height);
	if( glView == nil ) {
		glView = [[CameraShowGLView alloc] initWithFrame:self.monitor.frame];
		[glView setMinimumGestureLength:100 MaximumVariance:50];
		glView.delegate = self;
		[glView attachCamera:camera];
	}
	else {
		[self.glView destroyFramebuffer];
		self.glView.frame = self.monitor.frame;
	}
	[self.view addSubview:glView];
	
	if( mCodecId == MEDIA_CODEC_VIDEO_MJPEG ) {
		[self.view bringSubviewToFront:monitor/*self.glView*/];
	}
	else {
		[self.view bringSubviewToFront:/*monitor*/self.glView];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cameraStopShowCompleted:) name: @"CameraStopShowCompleted" object: nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
	if(glView) {
    	[self.glView tearDownGL];
		[self.glView release];
	}
	CVPixelBufferRelease(mPixelBuffer);
	CVPixelBufferPoolRelease(mPixelBufferPool);
    
    [camera release];
    [monitor release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Camera Delegate
- (void)camera:(Camera *)camera didChangeChannelStatus:(NSInteger)channel ChannelStatus:(NSInteger)status
{
    switch (status) {
        case CONNECTION_STATE_CONNECTED:
            break;
            
        case CONNECTION_STATE_CONNECTING:
            break;
            
        case CONNECTION_STATE_DISCONNECTED:
            break;
            
        case CONNECTION_STATE_CONNECT_FAILED:
            break;
            
        case CONNECTION_STATE_TIMEOUT:
            break;
            
        case CONNECTION_STATE_UNKNOWN_DEVICE:
            break;
            
        case CONNECTION_STATE_UNSUPPORTED:
            break;
        
        case CONNECTION_STATE_WRONG_PASSWORD:
            break;
            
        default:
            break;
    }
}

- (void)camera:(Camera *)camera didChangeSessionStatus:(NSInteger)status
{
    switch (status) {
        case CONNECTION_STATE_CONNECTED:
            break;
            
        case CONNECTION_STATE_CONNECTING:
            break;
            
        case CONNECTION_STATE_DISCONNECTED:
            break;
            
        case CONNECTION_STATE_CONNECT_FAILED:
            break;
            
        case CONNECTION_STATE_TIMEOUT:
            break;
            
        case CONNECTION_STATE_UNKNOWN_DEVICE:
            break;
            
        case CONNECTION_STATE_UNSUPPORTED:
            break;
            
        case CONNECTION_STATE_WRONG_PASSWORD:
            break;
            
        default:
            break;
    }
}

- (void)camera:(Camera *)camera didReceiveFrameInfoWithVideoWidth:(NSInteger)videoWidth VideoHeight:(NSInteger)videoHeight VideoFPS:(NSInteger)fps VideoBPS:(NSInteger)videoBps AudioBPS:(NSInteger)audioBps OnlineNm:(NSInteger)onlineNm FrameCount:(unsigned long)frameCount IncompleteFrameCount:(unsigned long)incompleteFrameCount
{
    
}

- (void)camera:(Camera *)camera didReceiveIOCtrlWithType:(NSInteger)type Data:(const char *)data DataSize:(NSInteger)size
{    
    if (type == IOTYPE_USER_IPCAM_GETSTREAMCTRL_RESP) {
        /* do something you want */
    }
    
    /* ... */
}

- (void)camera:(Camera *)camera didReceiveJPEGDataFrame:(const char *)imgData DataSize:(NSInteger)size
{
    /* 
     * You may use the code snippet as below to get an image. 
     
     NSData *data = [NSData dataWithBytes:imgData length:size];
     self.image = [UIImage imageWithData:data]; 
    
     */
}

- (void)camera:(Camera *)camera didReceiveRawDataFrame:(const char *)imgData VideoWidth:(NSInteger)width VideoHeight:(NSInteger)height
{    
    /* You may use the code snippet as below to get an image. */
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, imgData, width * height * 3, NULL);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef imgRef = CGImageCreate(width, height, 8, 24, width * 3, colorSpace, kCGBitmapByteOrderDefault, provider, NULL, true,  kCGRenderingIntentDefault);
    
    UIImage *img = [[UIImage alloc] initWithCGImage:imgRef];
    
    /* Set "img" to your own image object. */
    // self.image = img;
    
    [img release];   
        
    if (imgRef != nil) {
        CGImageRelease(imgRef);
        imgRef = nil;
    }   
    
    if (colorSpace != nil) {
        CGColorSpaceRelease(colorSpace);
        colorSpace = nil;
    }
    
    if (provider != nil) {
        CGDataProviderRelease(provider);
        provider = nil;
    } 
}

- (void)removeGLView :(BOOL)toPortrait
{
	if( glView ) {
		BOOL bRemoved = FALSE;
		
		for (UIView *subView in self.view.subviews) {
			
			if ([subView isKindOfClass:[CameraShowGLView class]]) {
				
				[subView removeFromSuperview];
				NSLog( @"glView has been removed from view <OK>" );
				bRemoved = TRUE;
				break;
			}
		}
		if( !bRemoved ) {
			for (UIView *subView in self.view.subviews) {
				
				if ([subView isKindOfClass:[CameraShowGLView class]]) {
					
					[subView removeFromSuperview];
					NSLog( @"glView has been removed from view <OK>" );
					bRemoved = TRUE;
					break;
				}
			}
		}
	}
}

- (void)glFrameSize:(NSArray*)param
{
	CGSize* pglFrameSize_Original = (CGSize*)[(NSValue*)[param objectAtIndex:0] pointerValue];
	CGSize* pglFrameSize_Scaling = (CGSize*)[(NSValue*)[param objectAtIndex:1] pointerValue];
	
	
	*pglFrameSize_Scaling = *pglFrameSize_Original;
}

- (void)reportCodecId:(NSValue*)pointer
{
	unsigned short *pnCodecId = (unsigned short *)[pointer pointerValue];

	mCodecId = *pnCodecId;
	
	if( mCodecId == MEDIA_CODEC_VIDEO_MJPEG ) {
		[self.view bringSubviewToFront:monitor/*self.glView*/];
	}
	else {
		[self.view bringSubviewToFront:/*monitor*/self.glView];
	}
}

- (void)updateToScreen:(NSValue*)pointer
{
	LPSIMAGEBUFFINFO pScreenBmpStore = (LPSIMAGEBUFFINFO)[pointer pointerValue];
	if( mPixelBuffer == nil ||
	   mSizePixelBuffer.width != pScreenBmpStore->nWidth ||
	   mSizePixelBuffer.height != pScreenBmpStore->nHeight ) {
		
		if(mPixelBuffer) {
			CVPixelBufferRelease(mPixelBuffer);
			CVPixelBufferPoolRelease(mPixelBufferPool);
		}
		
		NSMutableDictionary* attributes;
		attributes = [NSMutableDictionary dictionary];
		[attributes setObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
		[attributes setObject:[NSNumber numberWithInt:pScreenBmpStore->nWidth] forKey: (NSString*)kCVPixelBufferWidthKey];
		[attributes setObject:[NSNumber numberWithInt:pScreenBmpStore->nHeight] forKey: (NSString*)kCVPixelBufferHeightKey];
		
		CVReturn err = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (CFDictionaryRef) attributes, &mPixelBufferPool);
		if( err != kCVReturnSuccess ) {
			NSLog( @"mPixelBufferPool create failed!" );
		}
		err = CVPixelBufferPoolCreatePixelBuffer (NULL, mPixelBufferPool, &mPixelBuffer);
		if( err != kCVReturnSuccess ) {
			NSLog( @"mPixelBuffer create failed!" );
		}
		mSizePixelBuffer = CGSizeMake(pScreenBmpStore->nWidth, pScreenBmpStore->nHeight);
		NSLog( @"CameraLiveViewController - mPixelBuffer created %dx%d nBytes_per_Row:%d", pScreenBmpStore->nWidth, pScreenBmpStore->nHeight, pScreenBmpStore->nBytes_per_Row );
	}
	CVPixelBufferLockBaseAddress(mPixelBuffer,0);
	
	UInt8* baseAddress = (UInt8*)CVPixelBufferGetBaseAddress(mPixelBuffer);
	
	memcpy(baseAddress, pScreenBmpStore->pData_buff, pScreenBmpStore->nBytes_per_Row * pScreenBmpStore->nHeight );
	
	CVPixelBufferUnlockBaseAddress(mPixelBuffer,0);
	
	[glView renderVideo:mPixelBuffer];
}

- (void)waitStopShowCompleted:(unsigned int)uTimeOutInMs
{
	unsigned int uStart = _getTickCount();
	while( self.bStopShowCompletedLock == FALSE ) {
		usleep(1000);
		unsigned int now = _getTickCount();
		if( now - uStart >= uTimeOutInMs ) {
			NSLog( @"CameraLiveViewController - waitStopShowCompleted !!!TIMEOUT!!!" );
			break;
		}
	}
	
}

- (void)cameraStopShowCompleted:(NSNotification *)notification
{
	bStopShowCompletedLock = TRUE;
}

#pragma mark - MonitorTouchDelegate Methods
/*
 - (void)monitor:(Monitor *)monitor gestureSwiped:(Direction)direction
 {
 }
 */

- (void)monitor:(Monitor *)monitor gesturePinched:(CGFloat)scale
{
	NSLog( @"CameraLiveViewController - Pinched scale:%f", scale );

}

@end
