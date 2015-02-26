//
//  CameraShowGLView.m
//  IOTCamViewer
//
//  Created by Gavin Chang on 13/5/22.
//  Copyright (c) 2013年 TUTK. All rights reserved.
//

#import <IOTCamera/Camera2.h>
#import <IOTCamera/Monitor.h>
#import <IOTCamera/AVIOCTRLDEFs.h>
#import "CameraShowGLView.h"
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>


// Uniform index.
enum {
    UNIFORM_VIDEOFRAME,
	UNIFORM_INPUTCOLOR,
	UNIFORM_THRESHOLD,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};



@implementation CameraShowGLView

@synthesize minZoom;
@synthesize maxZoom;
@synthesize gestureStartPoint;
@synthesize minGestureLength;
@synthesize maxVariance;
@synthesize delegate;
@synthesize camera;

@synthesize videoFrameTexture;
@synthesize positionRenderTexture;

#pragma mark -
#pragma mark Initialization and teardown

// Override the class method to return the OpenGL layer, as opposed to the normal CALayer
+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		videoFrameTexture = 0;

 		// Do OpenGL Core Animation layer setup
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		// Set scaling to account for Retina display
		//		if ([self respondsToSelector:@selector(setContentScaleFactor:)])
		//		{
		//			self.contentScaleFactor = [[UIScreen mainScreen] scale];
		//		}

		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		//[eaglLayer setAffineTransform:CGAffineTransformMakeRotation( -90 * M_PI  / 180)];
		
		if (!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffers] || ![self loadVertexShader:@"DirectDisplayShader" fragmentShader:@"DirectDisplayShader" forProgram:&directDisplayProgram])
		{
			[self release];
			return nil;
		}
		
		glGenTextures(1, &videoFrameTexture);
		
		minZoom = frame.size;
		maxZoom = CGSizeMake(frame.size.width*2.0,frame.size.height*2.0);
		fScale = 1.0;
	}
    return self;
}

- (void)dealloc
{
	[self tearDownGL];

    [super dealloc];
}

#pragma mark -
#pragma mark OpenGL drawing
- (void)tearDownGL
{
	if( videoFrameTexture != 0 ) {
		glDeleteTextures(1, &videoFrameTexture);
		videoFrameTexture = 0;
	}
	
	[self destroyFramebuffer];
	
	if ([EAGLContext currentContext] == context) {
		[EAGLContext setCurrentContext:nil];
	}
	context = nil;
}

- (void)renderVideo:(CVImageBufferRef)videoFrame
{
	CVPixelBufferLockBaseAddress(videoFrame, 0);
	int bufferHeight = CVPixelBufferGetHeight(videoFrame);
	int bufferWidth = CVPixelBufferGetWidth(videoFrame);
	//NSLog( @"renderVideo %dx%d", bufferWidth, bufferHeight );
	
	// Create a new texture from the camera frame data, display that using the shaders
	if( videoFrameTexture != 0 ) {
		//glGenTextures(1, &videoFrameTexture);
		glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		// This is necessary for non-power-of-two textures
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(videoFrame));
		
		[self drawFrame];
		//glDeleteTextures(1, &videoFrameTexture);
	}
	CVPixelBufferUnlockBaseAddress(videoFrame, 0);
}

- (void)drawFrame2
{
	if( videoFrameTexture != 0 ) {
		glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
		// Draw
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
					
	}
	
	[self presentFramebuffer];
}

- (void)drawFrame
{
    // Replace the implementation of this method to do your own custom drawing.
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
	
//	static const GLfloat clockwise_90_TextureVertices[] = {
//        1.0f, 1.0f,
//        1.0f, 0.0f,
//        0.0f,  1.0f,
//        0.0f,  0.0f,
//    };
//	
//	static const GLfloat clockwise_180_TextureVertices[] = {
//	 0.0f, 0.0f,
//	 1.0f, 0.0f,
//	 0.0f,  1.0f,
//	 1.0f,  1.0f,
//	 };
//
//	static const GLfloat mirror_TextureVertices[] = {
//		1.0f, 1.0f,
//		0.0f, 1.0f,
//		1.0f,  0.0f,
//		0.0f,  0.0f,
//	};

	static const GLfloat passthrough_TextureVertices[] = {
		0.0f, 1.0f,
		1.0f, 1.0f,
		0.0f,  0.0f,
		1.0f,  0.0f,
	};
	
	//    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
	//    glClear(GL_COLOR_BUFFER_BIT);
    
	// Use shader program.
	[self setDisplayFramebuffer];
	glUseProgram(directDisplayProgram);

	if( videoFrameTexture != 0 ) {
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
		
		// Update uniform values
		glUniform1i(uniforms[UNIFORM_VIDEOFRAME], 0);
		//	glUniform4f(uniforms[UNIFORM_INPUTCOLOR], thresholdColor[0], thresholdColor[1], thresholdColor[2], 1.0f);
		//	glUniform1f(uniforms[UNIFORM_THRESHOLD], thresholdSensitivity);
		
		// Update attribute values.
		glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
		glEnableVertexAttribArray(ATTRIB_VERTEX);
		glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, passthrough_TextureVertices);
		glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		[self presentFramebuffer];
	}
}

- (BOOL)loadVertexShader:(NSString *)vertexShaderName fragmentShader:(NSString *)fragmentShaderName forProgram:(GLuint *)programPointer;
{
    GLuint vertexShader, fragShader;
	
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    *programPointer = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:vertexShaderName ofType:@"vsh"];
    if (![self compileShader:&vertexShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:fragmentShaderName ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(*programPointer, vertexShader);
    
    // Attach fragment shader to program.
    glAttachShader(*programPointer, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(*programPointer, ATTRIB_VERTEX, "position");
    glBindAttribLocation(*programPointer, ATTRIB_TEXTUREPOSITON, "inputTextureCoordinate");
    
    // Link program.
    if (![self linkProgram:*programPointer])
    {
        NSLog(@"Failed to link program: %d", *programPointer);
        
        if (vertexShader)
        {
            glDeleteShader(vertexShader);
            vertexShader = 0;
        }
        if (fragShader)
        {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (*programPointer)
        {
            glDeleteProgram(*programPointer);
            *programPointer = 0;
        }
        
        return FALSE;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_VIDEOFRAME] = glGetUniformLocation(*programPointer, "videoFrame");
    //uniforms[UNIFORM_INPUTCOLOR] = glGetUniformLocation(*programPointer, "inputColor");
    //uniforms[UNIFORM_THRESHOLD] = glGetUniformLocation(*programPointer, "threshold");
    
    // Release vertex and fragment shaders.
    if (vertexShader)
	{
        glDeleteShader(vertexShader);
	}
    if (fragShader)
	{
        glDeleteShader(fragShader);
	}
    
    return TRUE;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)createFramebuffers
{
	glEnable(GL_TEXTURE_2D);
	glDisable(GL_DEPTH_TEST);
	
	// Onscreen framebuffer object
	glGenFramebuffers(1, &viewFramebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
	
	glGenRenderbuffers(1, &viewRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
	
	[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
	
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
	NSLog(@"CameraShowGLView createFramebuffers -- Backing width: %d, height: %d", backingWidth, backingHeight);
	
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderbuffer);
	
	if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
		NSLog(@"Failure with framebuffer generation");
		return NO;
	}
	
	// Offscreen position framebuffer object
	glGenFramebuffers(1, &positionFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, positionFramebuffer);
	
	glGenRenderbuffers(1, &positionRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, positionRenderbuffer);
	
	int positionRenderbuffer_width = self.frame.size.width;
	int positionRenderbuffer_height = self.frame.size.height;
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, positionRenderbuffer_width, positionRenderbuffer_height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, positionRenderbuffer);
    
	// Offscreen position framebuffer texture target
	glGenTextures(1, &positionRenderTexture);
    glBindTexture(GL_TEXTURE_2D, positionRenderTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glHint(GL_GENERATE_MIPMAP_HINT, GL_NICEST);
	//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	//GL_NEAREST_MIPMAP_NEAREST
	
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.frame.size.width, self.frame.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
	//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, FBO_WIDTH, FBO_HEIGHT, 0, GL_RGBA, GL_FLOAT, 0);
	
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, positionRenderTexture, 0);
	//	NSLog(@"GL error15: %d", glGetError());
	
	
	
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE)
	{
		NSLog(@"Incomplete FBO: %d", status);
        exit(1);
    }
	return YES;
}

- (void)destroyFramebuffer;
{
	if (viewFramebuffer)
	{
		glDeleteFramebuffers(1, &viewFramebuffer);
		viewFramebuffer = 0;
	}
	
	if (viewRenderbuffer)
	{
		glDeleteRenderbuffers(1, &viewRenderbuffer);
		viewRenderbuffer = 0;
	}

	if (positionFramebuffer)
	{
		glDeleteFramebuffers(1, &positionFramebuffer);
		positionFramebuffer = 0;
	}
	
	if (positionRenderbuffer)
	{
		glDeleteRenderbuffers(1, &positionRenderbuffer);
		positionRenderbuffer = 0;
	}
	
	fScale = 1;
}

- (void)setDisplayFramebuffer;
{
    if (context)
    {
		//        [EAGLContext setCurrentContext:context];
        
        if (!viewFramebuffer)
		{
            [self createFramebuffers];
		}
        
        glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
        
		//NSLog( @"setDisplayFramebuffer %dx%d", backingWidth, backingHeight );
        glViewport(0, 0, backingWidth, backingHeight);
    }
}

- (void)setPositionThresholdFramebuffer;
{
    if (context)
    {
		//        [EAGLContext setCurrentContext:context];
        
        if (!positionFramebuffer)
		{
            [self createFramebuffers];
		}
        
        glBindFramebuffer(GL_FRAMEBUFFER, positionFramebuffer);
        
        glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    }
}

- (BOOL)presentFramebuffer;
{
    BOOL success = FALSE;
    
    if (context)
    {
		//      [EAGLContext setCurrentContext:context];
        
        glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
        
        success = [context presentRenderbuffer:GL_RENDERBUFFER];
    }
    
    return success;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)attachCamera:(Camera *)cam
{
    camera = cam;
}

- (void)deattachCamera
{
    camera = nil;
}

- (void)setMinimumGestureLength:(NSInteger)length MaximumVariance:(NSInteger)variance
{
    minGestureLength = length;
    maxVariance = variance;
    
    UIPinchGestureRecognizer *pinch = [[[UIPinchGestureRecognizer alloc]
                                        initWithTarget:self
                                        action:@selector(doPinch:)] autorelease];
    [self addGestureRecognizer:pinch];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    gestureStartPoint = [touch locationInView:self];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint currentPosition = [touch locationInView:self];
    
    CGFloat deltaX = currentPosition.x - gestureStartPoint.x;
    CGFloat deltaY = currentPosition.y - gestureStartPoint.y;
    Direction direction = DirectionNone;
    
    // pan
    if (fabsf(deltaX) >= minGestureLength && fabsf(deltaY) <= maxVariance) {
        
        if (deltaX > 0) direction = DirectionPanLeft;
        else direction = DirectionPanRight;
    }
    // tilt
    else if (fabsf(deltaY) >= minGestureLength && fabsf(deltaX) <= maxVariance) {
        
        if (deltaY > 0) direction = DirectionTiltUp;
        else direction = DirectionTiltDown;
    }
    
    if (direction != DirectionNone) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(monitor:gestureSwiped:)]) {
            [self.delegate monitor:self gestureSwiped:direction];
        }
        else {
            
            unsigned char ctrl = -1;
            if (direction == DirectionTiltUp) {
				ctrl = AVIOCTRL_PTZ_UP;
				NSLog( @"glView AVIOCTRL_PTZ_UP" );
			}
            else if (direction == DirectionTiltDown) {
				ctrl = AVIOCTRL_PTZ_DOWN;
				NSLog( @"glView AVIOCTRL_PTZ_DOWN" );
			}
            else if (direction == DirectionPanLeft) {
				ctrl = AVIOCTRL_PTZ_LEFT;
				NSLog( @"glView AVIOCTRL_PTZ_LEFT" );
			}
            else if (direction == DirectionPanRight) {
				ctrl = AVIOCTRL_PTZ_RIGHT;
				NSLog( @"glView AVIOCTRL_PTZ_RIGHT" );
			}
            
            if (camera != nil) {
				SMsgAVIoctrlPtzCmd *request = (SMsgAVIoctrlPtzCmd *)malloc(sizeof(SMsgAVIoctrlPtzCmd));
				request->control = ctrl;
				request->channel = 0;
				request->speed = PT_SPEED;
				request->point = 0;
				request->limit = 0;
				request->aux = 0;
				
					[camera sendIOCtrlToChannel:0 Type:IOTYPE_USER_IPCAM_PTZ_COMMAND Data:(char *)request DataSize:sizeof(SMsgAVIoctrlPtzCmd)];
				
				free(request);
            }
            [self performSelector:@selector(stopPT) withObject:nil afterDelay:PT_DELAY];
        }
    }
}

- (void)stopPT
{
	if (camera != nil) {
		SMsgAVIoctrlPtzCmd *request = (SMsgAVIoctrlPtzCmd *)malloc(sizeof(SMsgAVIoctrlPtzCmd));
		request->channel = 0;
		request->control = AVIOCTRL_PTZ_STOP;
		request->speed = PT_SPEED;
		request->point = 0;
		request->limit = 0;
		request->aux = 0;
		
		[camera sendIOCtrlToChannel:0 Type:IOTYPE_USER_IPCAM_PTZ_COMMAND Data:(char *)request DataSize:sizeof(SMsgAVIoctrlPtzCmd)];
		free(request);
    }
}

- (void)doPinch:(UIPinchGestureRecognizer *)pinch
{
    if (pinch.state == UIGestureRecognizerStateEnded) {
		
		CGFloat maxScale = (CGFloat)maxZoom.width / (CGFloat)minZoom.width;
		NSLog( @"CameraShowGLView - doPinch scale:%.1f/%.1f", pinch.scale, maxScale );
		
		if( minZoom.width == 0 )
			return;
		
		CGFloat scale = fScale * pinch.scale;
		if( scale < 1 ) {
			scale = 1;
		}
		else if( maxScale < scale ) {
			scale = maxScale;
		}
		
        if (self.delegate && [self.delegate respondsToSelector:@selector(monitor:gesturePinched:)]) {
            [self.delegate monitor:nil gesturePinched:scale];
        }
		
		//[self setFrame:CGRectMake(0,0, (minZoom.width*scale), (minZoom.height*scale))];
		fScale = scale;
    }
}

@end
