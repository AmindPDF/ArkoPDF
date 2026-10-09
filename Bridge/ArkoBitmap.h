//  ArkoBitmap.h
//  内部工具（仅 ObjC++ 使用，不暴露给 Swift）：SDK 位图 → CGImage。

#ifndef ArkoBitmap_h
#define ArkoBitmap_h

#include "ipdf_base.h"
#import <CoreGraphics/CoreGraphics.h>

#ifdef __cplusplus
extern "C" {
#endif

/// 把 SDK 的 32bpp BGRA 位图转成 CGImage。返回 +1（调用方负责 CGImageRelease）。
CGImageRef ArkoCGImageCreateFromDIBitmap(IPDF_DIBitmap *bitmap);

#ifdef __cplusplus
}
#endif

#endif
