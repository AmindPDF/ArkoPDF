//  ArkoPage.mm

#import "ArkoPage.h"
#include "ArkoBitmap.h"
#include "ipdf_base.h"
#include "ipdf_page.h"
#include "ipdf_render.h"
#include "ipdf_annots.h"
#include "ipdf_pagetext.h"

@implementation ArkoPage {
    IPDF_Page *_page;
    IPDF_PageText *_pageText;
    IPDF_AnnotList *_annotList;
    NSInteger _index;
}

- (nullable instancetype)initWithSDKPage:(void *)page index:(NSInteger)index {
    self = [super init];
    if (!self) {
        return nil;
    }
    _page = (IPDF_Page *)page;
    _pageText = NULL;
    _annotList = NULL;
    _index = index;
    return self;
}

- (NSInteger)pageIndex {
    return _index;
}

- (CGFloat)widthInPoints {
    return _page ? (CGFloat)_page->GetWidth() : 0;
}

- (CGFloat)heightInPoints {
    return _page ? (CGFloat)_page->GetHeight() : 0;
}

#pragma mark - 懒加载 SDK 子对象

- (IPDF_PageText *)sdkPageText {
    if (!_pageText && _page) {
        _pageText = _page->GetPageText();
        if (_pageText) {
            _pageText->ParseText();
        }
    }
    return _pageText;
}

- (IPDF_AnnotList *)sdkAnnotList {
    if (!_annotList && _page) {
        _annotList = _page->LoadAnnotList();
    }
    return _annotList;
}

#pragma mark - 渲染

- (nullable CGImageRef)renderImageAtScale:(CGFloat)scale CF_RETURNS_RETAINED {
    if (!_page) {
        return NULL;
    }
    if (scale <= 0) {
        scale = 1.0;
    }

    CGFloat ptW = (CGFloat)_page->GetWidth();
    CGFloat ptH = (CGFloat)_page->GetHeight();
    int pxW = (int)ceil(ptW * scale);
    int pxH = (int)ceil(ptH * scale);
    if (pxW < 1) { pxW = 1; }
    if (pxH < 1) { pxH = 1; }

    // 渲染前必须先解析页面内容，否则渲染出来是空白（对照 Windows 参考实现）
    _page->ParseContent();

    IPDF_Matrix *ctm = PDSDK_NewMatrix();
    _page->GetDisplayMatrix(ctm, 0, 0, pxW, pxH, 0);

    IPDF_DIBitmap *bmp = PDSDK_NewDIBitmap(DIB_ARGB, pxW, pxH);
    if (!bmp) {
        ctm->Release();
        return NULL;
    }
    bmp->Clear(COLOR_ARGB_MAKE(255, 255, 255, 255)); // 不透明白底

    IPDF_RenderContext *rc = PDSDK_NewRenderContext();
    if (rc) {
        rc->Create(_page, ctm);
        RENDER_OPTION opt = {};
        opt.m_ColorMode = PDSDK_RENDER_COLOR_NORMAL;
        opt.m_BackColor = COLOR_MAKERGB(255, 255, 255);
        opt.m_ForeColor = COLOR_MAKERGB(0, 0, 0);
        opt.m_Flags = PDSDK_RENDER_CLEARTYPE;
        rc->Render(bmp, ctm, &opt);
        rc->Release();
    }

    // 把标注叠加到已渲染的位图上（跨平台 DrawAnnot/DisplayAnnots 路径）。
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (annots) {
        annots->DisplayAnnots(_page, bmp, ctm, 0);
    }

    CGImageRef img = ArkoCGImageCreateFromDIBitmap(bmp);
    bmp->Release();
    ctm->Release();
    return img;
}

#pragma mark - 文本选择

- (NSInteger)caretAtUserPointX:(CGFloat)ux y:(CGFloat)uy tolerance:(CGFloat)tol {
    IPDF_PageText *pt = [self sdkPageText];
    if (!pt) {
        return -1;
    }
    PDSDK_FloatPoint p;
    p.x = (float)ux;
    p.y = (float)uy;
    int caret = pt->GetCaret(&p, (float)tol, (float)tol);
    return (NSInteger)caret;
}

- (NSArray<NSValue *> *)charBoxesFromCaret:(NSInteger)start toCaret:(NSInteger)end {
    IPDF_PageText *pt = [self sdkPageText];
    if (!pt) {
        return @[];
    }
    int s = (int)start, e = (int)end;
    if (s > e) { int t = s; s = e; e = t; }

    int n = pt->CountSelectedCharBox(s, e);
    NSMutableArray<NSValue *> *boxes = [NSMutableArray arrayWithCapacity:(NSUInteger)n];
    for (int i = 0; i < n; i++) {
        PDSDK_FloatRect r;
        if (pt->GetSelectedCharBox(i, &r)) {
            // PDF 用户坐标 left/bottom/right/top → CGRect(x=left, y=bottom, w=right-left, h=top-bottom)
            CGRect c = CGRectMake((CGFloat)r.left,
                                  (CGFloat)r.bottom,
                                  (CGFloat)(r.right - r.left),
                                  (CGFloat)(r.top - r.bottom));
            [boxes addObject:[NSValue valueWithRect:c]];
        }
    }
    return boxes;
}

- (nullable NSString *)selectedTextFromCaret:(NSInteger)start toCaret:(NSInteger)end {
    IPDF_PageText *pt = [self sdkPageText];
    if (!pt) {
        return nil;
    }
    int s = (int)start, e = (int)end;
    if (s > e) { int t = s; s = e; e = t; }
    const char *utf8 = pt->GetSelCharUTF8(s, e);
    if (!utf8) {
        return nil;
    }
    return [NSString stringWithUTF8String:utf8];
}

#pragma mark - 标注

- (void)addTextMarkupOfType:(NSInteger)annotType
                  lineBoxes:(NSArray<NSValue *> *)lineBoxes
                      color:(unsigned int)color
                    opacity:(float)opacity {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots) {
        return;
    }
    NSUInteger nLines = lineBoxes.count;
    if (nLines == 0) {
        return;
    }

    int pointCount = (int)(nLines * 4);
    PDSDK_FloatPoint **points = (PDSDK_FloatPoint **)malloc(sizeof(PDSDK_FloatPoint *) * (size_t)pointCount);
    if (!points) {
        return;
    }

    for (NSUInteger i = 0; i < nLines; i++) {
        CGRect r = [lineBoxes[i] rectValue];
        float left = (float)CGRectGetMinX(r);
        float right = (float)CGRectGetMaxX(r);
        float bottom = (float)CGRectGetMinY(r);
        float top = (float)CGRectGetMaxY(r);

        // SDK 约定顺序：每行 (left,top)(right,top)(left,bottom)(right,bottom)
        points[i * 4 + 0] = new PDSDK_FloatPoint(); points[i * 4 + 0]->x = left;  points[i * 4 + 0]->y = top;
        points[i * 4 + 1] = new PDSDK_FloatPoint(); points[i * 4 + 1]->x = right; points[i * 4 + 1]->y = top;
        points[i * 4 + 2] = new PDSDK_FloatPoint(); points[i * 4 + 2]->x = left;  points[i * 4 + 2]->y = bottom;
        points[i * 4 + 3] = new PDSDK_FloatPoint(); points[i * 4 + 3]->x = right; points[i * 4 + 3]->y = bottom;
    }

    IPDF_Annot *annot = annots->AddAnnot((int)annotType);
    if (annot) {
        annot->SetFlags(ANNOT_FLAG_PRINT);
        annot->SetColor(color);
        annot->SetOpacity(opacity);
        annot->SetPoints(points, pointCount, 0);
    }

    for (int i = 0; i < pointCount; i++) {
        delete points[i];
    }
    free(points);
}

#pragma mark - 标注管理

- (NSInteger)annotCount {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    return annots ? annots->Count() : 0;
}

- (nullable NSDictionary *)annotInfoAtIndex:(NSInteger)index {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots || index < 0 || index >= annots->Count()) {
        return nil;
    }
    IPDF_Annot *annot = annots->GetAnnot((int)index);
    if (!annot) {
        return nil;
    }
    unsigned int color = 0;
    annot->GetColor(color);
    PDSDK_FloatRect fr = annot->GetRect();
    CGRect rect = CGRectMake((CGFloat)fr.left, (CGFloat)fr.bottom,
                             (CGFloat)(fr.right - fr.left), (CGFloat)(fr.top - fr.bottom));
    return @{
        @"type": @(annot->GetType()),
        @"color": @(color),
        @"opacity": @(annot->GetOpacity()),
        @"rect": [NSValue valueWithRect:rect],
    };
}

- (void)removeAnnotAtIndex:(NSInteger)index {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots || index < 0 || index >= annots->Count()) {
        return;
    }
    IPDF_Annot *annot = annots->GetAnnot((int)index);
    if (annot) {
        annots->RemoveAnnot(annot);
    }
}

- (void)setAnnotColor:(unsigned int)color atIndex:(NSInteger)index {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots || index < 0 || index >= annots->Count()) {
        return;
    }
    IPDF_Annot *annot = annots->GetAnnot((int)index);
    if (annot) {
        annot->SetColor(color);
    }
}

- (void)setAnnotOpacity:(float)opacity atIndex:(NSInteger)index {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots || index < 0 || index >= annots->Count()) {
        return;
    }
    IPDF_Annot *annot = annots->GetAnnot((int)index);
    if (annot) {
        annot->SetOpacity(opacity);
    }
}

#pragma mark - 保存

- (void)generateContent {
    if (_page) {
        _page->GenerateContent();
    }
}

+ (unsigned int)makeRGBColorWithRed:(uint8_t)r green:(uint8_t)g blue:(uint8_t)b {
    return COLOR_MAKERGB(r, g, b);
}

- (void)dealloc {
    if (_pageText) { _pageText->Release(); _pageText = NULL; }
    if (_annotList) { _annotList->Release(); _annotList = NULL; }
    if (_page) { _page->Release(); _page = NULL; }
}

@end
