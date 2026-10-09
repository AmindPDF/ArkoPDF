//  ArkoDocument.mm

#import "ArkoDocument.h"
#import "ArkoPage.h"
#include "ipdf_base.h"
#include "ipdf_document.h"

@implementation ArkoDocument {
    IPDF_Document *_doc;
    NSMutableArray<ArkoPage *> *_pages;
}

- (nullable instancetype)initWithURL:(NSURL *)url error:(NSError **)error {
    self = [super init];
    if (!self) {
        return nil;
    }

    _doc = PDSDK_NewDocument();
    if (!_doc) {
        if (error) {
            *error = [NSError errorWithDomain:@"ArkoPDF.SDK"
                                         code:-2
                                     userInfo:@{NSLocalizedDescriptionKey: @"PDSDK_NewDocument 返回 NULL（SDK 未加载？）"}];
        }
        return nil;
    }

    int ret = _doc->Open([[url path] UTF8String], 0);
    if (ret != PDF_OPEN_ERROR_SUCCESS) {
        if (error) {
            *error = [ArkoDocument errorForOpenCode:ret];
        }
        PDSDK_ReleaseDocument(_doc);
        _doc = NULL;
        return nil;
    }

    int n = _doc->GetPageCount();
    _pages = [NSMutableArray arrayWithCapacity:(NSUInteger)n];
    for (int i = 0; i < n; i++) {
        IPDF_Page *page = _doc->GetPage(i);
        ArkoPage *wrapper = [[ArkoPage alloc] initWithSDKPage:page index:i];
        [_pages addObject:wrapper];
    }
    return self;
}

- (NSInteger)pageCount {
    return _doc ? _doc->GetPageCount() : 0;
}

- (nullable ArkoPage *)pageAtIndex:(NSInteger)index {
    if (!_pages) {
        return nil;
    }
    if (index < 0 || index >= (NSInteger)_pages.count) {
        return nil;
    }
    return _pages[(NSUInteger)index];
}

- (BOOL)saveToURL:(NSURL *)url error:(NSError **)error {
    if (!_doc) {
        return NO;
    }
    // 保存前把每页内容重新序列化（含新增标注）。
    for (ArkoPage *page in _pages) {
        [page generateContent];
    }

    IPDF_Creator *creator = PDSDK_NewCreator();
    if (!creator) {
        if (error) {
            *error = [NSError errorWithDomain:@"ArkoPDF.SDK"
                                         code:-3
                                     userInfo:@{NSLocalizedDescriptionKey: @"PDSDK_NewCreator 返回 NULL"}];
        }
        return NO;
    }
    creator->Init(_doc, PDF_CREATE_NO_ORIGINAL);
    int ret = creator->Create([[url path] UTF8String], NULL, NULL);
    creator->Release();
    if (!ret) {
        if (error) {
            *error = [NSError errorWithDomain:@"ArkoPDF.SDK"
                                         code:-4
                                     userInfo:@{NSLocalizedDescriptionKey:
                                                    [NSString stringWithFormat:@"保存失败：%@", url.lastPathComponent]}];
        }
        return NO;
    }
    return YES;
}

- (void)close {
    if (_doc) {
        // 先释放各页（各自 Release 其 IPDF_Page / PageText / AnnotList），再关闭文档。
        _pages = nil;
        _doc->Close(0);
        PDSDK_ReleaseDocument(_doc);
        _doc = NULL;
    }
}

- (void)dealloc {
    [self close];
}

+ (NSError *)errorForOpenCode:(int)code {
    NSString *desc;
    switch (code) {
        case PDF_OPEN_ERROR_FILE:     desc = @"文件不存在或无法打开"; break;
        case PDF_OPEN_ERROR_FORMAT:   desc = @"不是有效的 PDF 或文件已损坏"; break;
        case PDF_OPEN_ERROR_PASSWORD: desc = @"需要密码"; break;
        case PDF_OPEN_ERROR_HANDLER:  desc = @"不支持的加密处理器"; break;
        case PDF_OPEN_ERROR_CERT:     desc = @"缺少数字证书"; break;
        default:                      desc = [NSString stringWithFormat:@"打开失败（code=%d）", code]; break;
    }
    return [NSError errorWithDomain:@"ArkoPDF.SDK"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: desc}];
}

@end
