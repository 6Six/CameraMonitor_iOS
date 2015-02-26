//
//  CameraShowGLView.h
//  IOTCamViewer
//
//  Created by Gavin Chang on 13/5/22.
//  Copyright (c) 2013年 TUTK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface CameraShowGLView : UIView
{
	GLuint directDisplayProgram;	/* The pixel dimensions of the backbuffer */
	GLuint videoFrameTexture;
	
	GLint backingWidth, backingHeight;
	
	EAGLContext *context;
	
	/* OpenGL names for the renderbuffer and framebuffers used to render to this view */
	GLuint viewRenderbuffer, viewFramebuffer;
	
	GLuint positionRenderTexture;
	GLuint positionRenderbuffer, positionFramebuffer;
	
	id<MonitorTouchDelegate>delegate;
    Camera *camera;
	CGPoint gestureStartPoint;
	NSInteger minGestureLength;
	NSInteger maxVariance;
	
	CGSize minZoom;
	CGSize maxZoom;
	CGFloat fScale;
}

@property (nonatomic, assign) CGSize minZoom;
@property (nonatomic, assign) CGSize maxZoom;

@property (nonatomic, assign) CGPoint gestureStartPoint;
@property (nonatomic, assign) NSInteger minGestureLength;
@property (nonatomic, assign) NSInteger maxVariance;
@property (nonatomic, assign) IBOutlet id<MonitorTouchDelegate> delegate;
@property (nonatomic, assign) Camera* camera;

@property (readonly) GLuint positionRenderTexture;
@property (readonly) GLuint videoFrameTexture;


- (void)tearDownGL;
- (void)renderVideo:(CVImageBufferRef)videoFrame;
- (void)drawFrame;

- (BOOL)loadVertexShader:(NSString *)vertexShaderName fragmentShader:(NSString *)fragmentShaderName forProgram:(GLuint *)programPointer;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

// OpenGL drawing
- (BOOL)createFramebuffers;
- (void)destroyFramebuffer;
- (void)setDisplayFramebuffer;
- (void)setPositionThresholdFramebuffer;
- (BOOL)presentFramebuffer;


- (void)attachCamera:(Camera *)camera;
- (void)deattachCamera;
- (void)setMinimumGestureLength:(NSInteger)length MaximumVariance:(NSInteger)variance;

@end
