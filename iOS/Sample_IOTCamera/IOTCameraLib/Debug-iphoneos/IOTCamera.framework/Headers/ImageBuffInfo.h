//
//  ImageBuffInfo.h
//  IOTCamera
//
//  Created by Gavin Chang on 13/5/25.
//
//

#ifndef IOTCamera_ImageBuffInfo_h
#define IOTCamera_ImageBuffInfo_h

typedef struct tagImageBuffInfo {
	int nWidth;
	int nHeight;
	int nBytes_per_Pixel;
	int nBytes_per_Row;
	
	int nData_total_length;
	int nData_filled_length;
	unsigned char* pData_buff;
} SIMAGEBUFFINFO, *LPSIMAGEBUFFINFO;

typedef struct tagFrameDecodeParam {
	BOOL bIsDecode_success;
	int nEnumValue_of_AVPixelFormat;	//The pixel format of each frame. This value can be refered to pixfmt.h in ffmpeg library.
	int nSrcFrame_Width;
	int nSrcFrame_Height;
	SIMAGEBUFFINFO sImageInfo;
} SFRMDECODEPARAM, *LPSFRMDECODEPARAM;

typedef struct tagUpdateToScreenParam {
	Camera* pCamera;
	Monitor* pMonitor;
	LPSFRMDECODEPARAM pFrameDecodeParam;
} SUPDATETOSCNPARAM, *LPSUPDATETOSCNPARAM;


#endif
