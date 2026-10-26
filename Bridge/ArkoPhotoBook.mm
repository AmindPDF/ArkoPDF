//  ArkoPhotoBook.mm

#import "ArkoPhotoBook.h"
#import <AppKit/AppKit.h>
#include "ipdf_base.h"
#include "ipdf_photobook.h"
#include "ipdf_document.h"
#include "ArkoSaveProgress.h"

@implementation ArkoPhotoBook {
    IPDF_PhotoBookCreator *_creator;
    float _paperW, _paperH;
    int _cols, _rows;
    float _marginH, _marginV;
    float _spaceH, _spaceV;
    float _ratio;
    NSMutableArray<NSString *> *_paths;
    NSMutableArray<NSNumber *> *_pixW;
    NSMutableArray<NSNumber *> *_pixH;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    // creator 失败时置 NULL，buildAndSave 里检查（不在此返回 nil，避免 Swift 侧 optional）
    _creator = PDSDK_CreatePhotoBookCreator();
    _paperW = 612; _paperH = 792;
    _cols = 2; _rows = 2;
    _marginH = 45; _marginV = 45;
    _spaceH = 6; _spaceV = 6;
    _ratio = 5.0f / 7.0f;  // 竖版 5:7
    _paths = [NSMutableArray array];
    _pixW = [NSMutableArray array];
    _pixH = [NSMutableArray array];
    return self;
}

- (void)setPaperWidth:(float)w height:(float)h { _paperW = w; _paperH = h; }
- (void)setLayoutCols:(int)cols rows:(int)rows { _cols = cols; _rows = rows; }
- (void)setMarginsHorizontal:(float)h vertical:(float)v { _marginH = h; _marginV = v; }
- (void)setSpacingHorizontal:(float)h vertical:(float)v { _spaceH = h; _spaceV = v; }
- (void)setPhotoRatio:(float)ratio { _ratio = ratio; }

- (void)addImageAtPath:(NSString *)path pixelWidth:(int)w pixelHeight:(int)h {
    [_paths addObject:path];
    [_pixW addObject:@(w)];
    [_pixH addObject:@(h)];
}

- (BOOL)buildAndSaveToURL:(NSURL *)url progress:(void (^)(float))progress isCancelled:(BOOL (^)(void))isCancelled error:(NSError **)error {
    if (!_creator) {
        if (error) {
            *error = [NSError errorWithDomain:@"ArkoPDF.SDK" code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"PhotoBook 创建器不可用"}];
        }
        return NO;
    }

    _creator->Init(_paperW, _paperH, _cols, _rows, _marginH, _marginV, _spaceH, _spaceV, _ratio);
    for (NSUInteger i = 0; i < _paths.count; i++) {
        _creator->AddImage([_paths[i] UTF8String], _pixW[i].intValue, _pixH[i].intValue);
    }
    _creator->BuildPhotoBook(NULL);

    IPDF_Document *doc = _creator->GetPDDoc(1);  // 1 = take ownership
    if (!doc) {
        _creator->Release();
        _creator = NULL;
        if (error) {
            *error = [NSError errorWithDomain:@"ArkoPDF.SDK" code:-2
                                     userInfo:@{NSLocalizedDescriptionKey: @"生成相册失败（GetPDDoc 返回空）"}];
        }
        return NO;
    }

    BOOL ok = NO;
    IPDF_Creator *c = PDSDK_NewCreator();
    if (c) {
        c->Init(doc, PDF_CREATE_NO_ORIGINAL);

        ArkoProgressSink *sink = nil;
        if (progress || isCancelled) {
            sink = [[ArkoProgressSink alloc] init];
            sink.onProgress = progress;
            sink.onCancel = isCancelled;
        }
        ArkoSavePause pause;
        ArkoSaveProgress prog;
        prog.sink = sink;
        ok = c->Create([[url path] UTF8String], &pause, &prog) != 0;
        c->Release();
    }
    PDSDK_ReleaseDocument(doc);

    _creator->Release();
    _creator = NULL;

    if (!ok && error) {
        *error = [NSError errorWithDomain:@"ArkoPDF.SDK" code:-3
                                 userInfo:@{NSLocalizedDescriptionKey: @"保存相册 PDF 失败"}];
    }
    return ok;
}

- (void)dealloc {
    if (_creator) {
        _creator->Release();
        _creator = NULL;
    }
}

@end
