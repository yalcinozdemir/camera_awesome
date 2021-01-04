//
//  ImageStreamController.m
//  camerawesome
//
//  Created by Dimitri Dessus on 17/12/2020.
//

#import "ImageStreamController.h"
#import <sys/utsname.h>

@implementation ImageStreamController

- (instancetype)initWithEventSink:(FlutterEventSink)imageStreamEventSink {
    self = [super init];
    _imageStreamEventSink = imageStreamEventSink;
    _streamImages = imageStreamEventSink != nil;
    _fpsLimit = 0;
    _oldDate = [NSDate date];
    frameCountLimit = [self calculateFrameCountLimitForDevice];
    frameCount = 0;
    return self;
}

# pragma mark - Camera Delegates
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSDate *now = [NSDate date];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *componentsForFirstDate = [calendar components:NSCalendarUnitSecond fromDate:now];
    NSDateComponents *componentsForSecondDate = [calendar components:NSCalendarUnitSecond fromDate:_oldDate];
    
    if ([componentsForFirstDate second] == [componentsForSecondDate second]) {
        frameCount++;
        
        if (frameCount >= frameCountLimit) {
            return;
        }
    } else {
        frameCount = 0;
        _oldDate = [NSDate date];
    }
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    const Boolean isPlanar = CVPixelBufferIsPlanar(pixelBuffer);
    size_t planeCount;
    if (isPlanar) {
        planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
    } else {
        planeCount = 1;
    }
    
    FlutterStandardTypedData *data;
    for (int i = 0; i < planeCount; i++) {
        void *planeAddress;
        size_t bytesPerRow;
        size_t height;
        size_t width;

        if (isPlanar) {
            planeAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, i);
            bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, i);
            height = CVPixelBufferGetHeightOfPlane(pixelBuffer, i);
            width = CVPixelBufferGetWidthOfPlane(pixelBuffer, i);
        } else {
            planeAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
            bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
            height = CVPixelBufferGetHeight(pixelBuffer);
            width = CVPixelBufferGetWidth(pixelBuffer);
        }

        NSNumber *length = @(bytesPerRow * height);
        NSData *bytes = [NSData dataWithBytes:planeAddress length:length.unsignedIntegerValue];
        data = [FlutterStandardTypedData typedDataWithBytes:bytes];
    }

    // Only send bytes for now
    _imageStreamEventSink(data);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
}

/// calculate fps limit, useful for low CPU devices
- (int)calculateFrameCountLimitForDevice {
    int frameCountLimit = 30;
    
    // TODO: Improve this list with a lot of real tests
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine
                                               encoding:NSUTF8StringEncoding];
    if ([deviceModel isEqualToString:@"iPhone7,1"] || [deviceModel isEqualToString:@"iPhone7,2"]) {
        // iPhone 6 & iPhone 6 Plus
        frameCountLimit = 1;
    } else if ([deviceModel isEqualToString:@"iPhone8,1"] || [deviceModel isEqualToString:@"iPhone8,2"] || [deviceModel isEqualToString:@"iPhone8,4"]) {
        // iPhone 6S & iPhone 6S Plus & iPhone SE
        frameCountLimit = 2;
    } else if ([deviceModel isEqualToString:@"iPhone9,1"] || [deviceModel isEqualToString:@"iPhone9,2"] || [deviceModel isEqualToString:@"iPhone9,3"] || [deviceModel isEqualToString:@"iPhone9,4"]) {
        // iPhone 7 & iPhone 7 Plus
        frameCountLimit = 2;
    } else if ([deviceModel isEqualToString:@"iPhone10,1"] || [deviceModel isEqualToString:@"iPhone10,2"] || [deviceModel isEqualToString:@"iPhone10,4"] || [deviceModel isEqualToString:@"iPhone10,5"]) {
        // iPhone 8 & iPhone 8 Plus
        frameCountLimit = 15;
    } else if ([deviceModel isEqualToString:@"iPhone10,3"] || [deviceModel isEqualToString:@"iPhone10,6"]) {
        // iPhone X
        frameCountLimit = 15;
    }
    
    // TODO: Add iPad
    
    return frameCountLimit;
}

@end
