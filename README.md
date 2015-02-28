# HDCameraMonitor
Purpose
---
    This is used for connecting to Camera, and show screen in real time.


Usage
---
    [Camera initIOTC];
    Camera *camera = [[Camera alloc] initWithName:@"Camera"];
    [camera setDelegate:self];
    [camera connect:kYourCameraAddress];
    [camera start:0 viewAccount:kYourAccount viewPassword:kYourPassword is_playback:FALSE];
    
	  [camera startShow:0 ScreenObject:self];
	  
	  Monitor *monitor = [[Monitor alloc] init];
	  [monitor attachCamera:camera];
	  
	  // to do something..
