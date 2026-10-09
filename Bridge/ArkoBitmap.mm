//  ArkoBitmap.mm

#include "ArkoBitmap.h"

CGImageRef ArkoCGImageCreateFromDIBitmap(IPDF_DIBitmap *bitmap) {
    if (!bitmap) {
        return NULL;
    }
    int w = bitmap->GetWidth();
    int h = bitmap->GetHeight();
    unsigned int pitch = bitmap->GetPitch();
    unsigned char *pixels = bitmap->GetPixels();
    if (w <= 0 || h <= 0 || !pixels) {
        return NULL;
    }

    // DIB_ARGB / DIB_RGBA 为 32bpp，内存字节序 BGRA（低地址 = 蓝）。
    // 对应 CG：kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little。
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(pixels,
                                             w,
                                             h,
                                             8,
                                             pitch,
                                             cs,
                                             kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(cs);
    if (!ctx) {
        return NULL;
    }
    CGImageRef img = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    return img; // +1
}
