//  ArkoSDK.mm

#import "ArkoSDK.h"
#include "ipdf_base.h"

@implementation ArkoSDK

static BOOL sLoaded = NO;

+ (BOOL)loadWithLicense:(NSString *)license error:(NSError **)error {
    if (sLoaded) {
        return YES;
    }
    if (license.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"ArkoPDF.SDK"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"license 不能为空"}];
        }
        return NO;
    }
    // Windows 参考实现不检查 PDF_LoadSDK 的返回值；此处保持一致，仅作记录。
    int ret = PDF_LoadSDK([license UTF8String]);
    (void)ret;
    sLoaded = YES;
    return YES;
}

+ (void)unload {
    if (!sLoaded) {
        return;
    }
    PDF_UnLoadSDK();
    sLoaded = NO;
}

@end
