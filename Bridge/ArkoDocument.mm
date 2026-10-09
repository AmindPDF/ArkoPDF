//  ArkoDocument.mm

#import "ArkoDocument.h"
#import "ArkoPage.h"
#include "ipdf_base.h"
#include "ipdf_document.h"
#include "ipdf_page.h"
#include "ipdf_pageprocess.h"

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

#pragma mark - 页面组织（PPO）

- (void)reloadPages {
    if (!_doc) {
        _pages = nil;
        return;
    }
    int n = _doc->GetPageCount();
    _pages = [NSMutableArray arrayWithCapacity:(NSUInteger)n];
    for (int i = 0; i < n; i++) {
        IPDF_Page *page = _doc->GetPage(i);
        ArkoPage *wrapper = [[ArkoPage alloc] initWithSDKPage:page index:i];
        [_pages addObject:wrapper];
    }
}

- (void)notifyPPOWillChange:(ArkoPPOOperation)op pages:(NSArray<NSNumber *> *)pages {
    if ([self.ppoDelegate respondsToSelector:@selector(document:willChangePages:pages:)]) {
        [self.ppoDelegate document:self willChangePages:op pages:pages];
    }
}

- (void)notifyPPODidChange:(ArkoPPOOperation)op {
    if ([self.ppoDelegate respondsToSelector:@selector(document:didChangePages:)]) {
        [self.ppoDelegate document:self didChangePages:op];
    }
}

- (void)insertBlankPageAt:(NSInteger)index width:(CGFloat)width height:(CGFloat)height {
    if (!_doc) return;
    [self notifyPPOWillChange:ArkoPPOOperationInsertBlank pages:@[@(index)]];
    _pages = nil;  // 变更前先释放旧页引用，避免悬空
    IPDF_PageOrganizer *ppo = _doc->GetPageOrganizer();
    if (ppo) {
        ppo->InsertBlankAt((int)index, (float)width, (float)height);
        ppo->Release();
    }
    [self reloadPages];
    [self notifyPPODidChange:ArkoPPOOperationInsertBlank];
}

- (void)deletePagesFrom:(NSInteger)start count:(NSInteger)count {
    if (!_doc || count <= 0) return;
    NSMutableArray<NSNumber *> *pages = [NSMutableArray arrayWithCapacity:(NSUInteger)count];
    for (NSInteger i = 0; i < count; i++) {
        [pages addObject:@(start + i)];
    }
    [self notifyPPOWillChange:ArkoPPOOperationDeletePages pages:pages];
    _pages = nil;
    IPDF_PageOrganizer *ppo = _doc->GetPageOrganizer();
    if (ppo) {
        ppo->DeletePages((int)start, (int)count);
        ppo->Release();
    }
    [self reloadPages];
    [self notifyPPODidChange:ArkoPPOOperationDeletePages];
}

- (void)swapPage:(NSInteger)page1 with:(NSInteger)page2 {
    if (!_doc || page1 == page2) return;
    [self notifyPPOWillChange:ArkoPPOOperationSwapPages pages:@[@(page1), @(page2)]];
    _pages = nil;
    IPDF_PageOrganizer *ppo = _doc->GetPageOrganizer();
    if (ppo) {
        ppo->SwapPages((int)page1, (int)page2);
        ppo->Release();
    }
    [self reloadPages];
    [self notifyPPODidChange:ArkoPPOOperationSwapPages];
}

- (NSInteger)pageRotationAtIndex:(NSInteger)index {
    if (!_doc) return 0;
    IPDF_Page *p = _doc->GetPage((int)index);
    int r = p ? p->GetRotate() : 0;
    if (p) p->Release();
    return (NSInteger)r;
}

- (void)setPageRotation:(NSInteger)rotateFlag atIndex:(NSInteger)index {
    if (!_doc) return;
    [self notifyPPOWillChange:ArkoPPOOperationRotatePage pages:@[@(index)]];
    _pages = nil;
    IPDF_PageOrganizer *ppo = _doc->GetPageOrganizer();
    if (ppo) {
        ppo->RotatePage((int)index, (int)rotateFlag);
        ppo->Release();
    }
    [self reloadPages];
    [self notifyPPODidChange:ArkoPPOOperationRotatePage];
}

- (nullable NSArray<NSNumber *> *)clonePageHandlersFrom:(NSInteger)start count:(NSInteger)count {
    if (!_doc || count <= 0) return nil;
    NSMutableArray<NSNumber *> *clones = [NSMutableArray arrayWithCapacity:(NSUInteger)count];
    for (NSInteger i = 0; i < count; i++) {
        IPDF_Page *p = _doc->GetPage((int)(start + i));
        PDF_PageHandler clone = NULL;
        if (p) {
            PDF_PageHandler h = p->GetHandler();
            clone = h ? PDSDK_ClonePageHandler(h) : NULL;
        }
        [clones addObject:@((unsigned long long)(uintptr_t)clone)];
    }
    return clones;
}

- (void)restorePagesWithClones:(NSArray<NSNumber *> *)clones atIndex:(NSInteger)start {
    if (!_doc || clones.count == 0) return;
    int count = (int)clones.count;
    [self notifyPPOWillChange:ArkoPPOOperationInsertBlank pages:@[@(start)]];
    _pages = nil;

    // 1. 建空白临时文档并插入占位页（删除页只是断开引用，页面数据仍在 PDF 里）
    IPDF_Document *blank = PDSDK_NewDocument();
    if (blank) {
        if (blank->NewBlankDoc(1, 1, count) == 0) {
            int *srcPages = (int *)malloc(sizeof(int) * (size_t)count);
            for (int i = 0; i < count; i++) srcPages[i] = i;
            IPDF_PageOrganizer *ppo = _doc->GetPageOrganizer();
            if (ppo) {
                ppo->InsertPagesFrom((int)start, blank, srcPages, count);
                ppo->Release();
            }
            free(srcPages);
        }
        PDSDK_ReleaseDocument(blank);
    }

    // 2. 把克隆的页面句柄拷回占位页，重新连接引用
    for (int i = 0; i < count; i++) {
        IPDF_Page *p = _doc->GetPage((int)(start + i));
        if (!p) continue;
        PDF_PageHandler clone = (PDF_PageHandler)(uintptr_t)clones[(NSUInteger)i].unsignedLongLongValue;
        if (clone) {
            // Copy 不消耗 clone，保留供后续多次撤销复用；clone 生命周期由上层撤销项管理
            PDSDK_CopyPageHandler(p->GetHandler(), clone);
        }
    }

    [self reloadPages];
    [self notifyPPODidChange:ArkoPPOOperationInsertBlank];
}

+ (void)destroyPageHandlerClones:(NSArray<NSNumber *> *)clones {
    for (NSNumber *n in clones) {
        PDF_PageHandler clone = (PDF_PageHandler)(uintptr_t)n.unsignedLongLongValue;
        if (clone) {
            PDSDK_DestroyPageHandlerClone(clone);
        }
    }
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
