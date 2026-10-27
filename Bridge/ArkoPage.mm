//  ArkoPage.mm

#import "ArkoPage.h"
#import "ArkoParagraph.h"
#include "ArkoBitmap.h"
#include "ipdf_base.h"
#include "ipdf_page.h"
#include "ipdf_render.h"
#include "ipdf_annots.h"
#include "ipdf_pagetext.h"
#include "ipdf_paragraph.h"
#include "ipdf_pageobject.h"
#include "ipdf_sign.h"
#include <string>

@implementation ArkoPage {
    IPDF_Page *_page;
    IPDF_PageText *_pageText;
    IPDF_AnnotList *_annotList;
    IPDF_LogicalStructAnalyser *_analyser;
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
    _analyser = NULL;
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

- (void)addShapeAnnotOfType:(NSInteger)annotType
                     points:(NSArray<NSValue *> *)points
                      color:(unsigned int)color
                    opacity:(float)opacity
                borderWidth:(int)borderWidth {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots) {
        return;
    }
    NSUInteger n = points.count;
    if (n < 2) {
        return;
    }
    PDSDK_FloatPoint **pts = (PDSDK_FloatPoint **)malloc(sizeof(PDSDK_FloatPoint *) * n);
    if (!pts) {
        return;
    }
    for (NSUInteger i = 0; i < n; i++) {
        CGPoint p = [points[i] pointValue];
        pts[i] = new PDSDK_FloatPoint();
        pts[i]->x = (float)p.x;
        pts[i]->y = (float)p.y;
    }
    IPDF_Annot *annot = annots->AddAnnot((int)annotType);
    if (annot) {
        annot->SetFlags(ANNOT_FLAG_PRINT);
        annot->SetColor(color);
        annot->SetOpacity(opacity);
        annot->SetBorderWidth(borderWidth);
        annot->SetPoints(pts, (int)n, 0);
    }
    for (NSUInteger i = 0; i < n; i++) {
        delete pts[i];
    }
    free(pts);
}

- (void)addNoteAnnotAtRect:(CGRect)rect
                  contents:(NSString *)contents
                     color:(unsigned int)color
                   opacity:(float)opacity {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots) {
        return;
    }
    IPDF_Annot *annot = annots->AddAnnot(ANNOT_TYPE_TEXT);
    if (annot) {
        annot->SetFlags(ANNOT_FLAG_PRINT);
        annot->SetColor(color);
        annot->SetOpacity(opacity);
        PDSDK_FloatRect r;
        r.left = (float)CGRectGetMinX(rect);
        r.bottom = (float)CGRectGetMinY(rect);
        r.right = (float)CGRectGetMaxX(rect);
        r.top = (float)CGRectGetMaxY(rect);
        annot->SetRect(&r);
        if (contents.length > 0) {
            annot->SetContents([contents UTF8String], 0);
        }
    }
}

- (unsigned long long)addRedactionMarkAtRect:(CGRect)rect
                                   fillColor:(unsigned int)fillColor
                                    contents:(nullable NSString *)contents {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots) return 0;
    IPDF_Annot *annot = annots->AddAnnot(ANNOT_TYPE_REDACT);
    if (!annot) return 0;
    annot->SetFlags(ANNOT_FLAG_PRINT);
    // 4 个角点（左下→右下→右上→左上）
    PDSDK_FloatPoint *pts[4];
    for (int i = 0; i < 4; i++) pts[i] = new PDSDK_FloatPoint();
    pts[0]->x = (float)CGRectGetMinX(rect); pts[0]->y = (float)CGRectGetMinY(rect);
    pts[1]->x = (float)CGRectGetMaxX(rect); pts[1]->y = (float)CGRectGetMinY(rect);
    pts[2]->x = (float)CGRectGetMaxX(rect); pts[2]->y = (float)CGRectGetMaxY(rect);
    pts[3]->x = (float)CGRectGetMinX(rect); pts[3]->y = (float)CGRectGetMaxY(rect);
    annot->SetPoints(pts, 4, 0);
    for (int i = 0; i < 4; i++) delete pts[i];
    annot->SetColor(fillColor);
    annot->SetFillColor(fillColor);
    annot->SetOpacity(1.0f);
    annot->SetBorderWidth(0);
    if (contents.length > 0) {
        annot->SetContents([contents UTF8String], 0);
    }
    annot->GenerateAppearance();
    return (unsigned long long)(uintptr_t)annot->GetAnnotHandler();
}

- (NSInteger)deleteContentInRects:(NSArray<NSValue *> *)rects {
    if (!_page || rects.count == 0) return -1;
    NSUInteger n = rects.count;
    PDSDK_FloatRect *arr = (PDSDK_FloatRect *)malloc(sizeof(PDSDK_FloatRect) * n);
    if (!arr) return -1;
    for (NSUInteger i = 0; i < n; i++) {
        CGRect r = [rects[i] rectValue];
        arr[i].left = (float)CGRectGetMinX(r);
        arr[i].bottom = (float)CGRectGetMinY(r);
        arr[i].right = (float)CGRectGetMaxX(r);
        arr[i].top = (float)CGRectGetMaxY(r);
    }
    int ret = _page->DeleteContentObjects(arr, (int)n);
    free(arr);
    return (NSInteger)ret;
}

- (NSArray<NSDictionary *> *)redactionMarks {
    NSMutableArray<NSDictionary *> *marks = [NSMutableArray array];
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots) return marks;
    int n = annots->Count();
    for (int i = 0; i < n; i++) {
        IPDF_Annot *annot = annots->GetAnnot(i);
        if (!annot) continue;
        if (annot->GetType() != ANNOT_TYPE_REDACT) continue;
        PDSDK_FloatRect r = annot->GetRect();
        CGRect rect = CGRectMake((CGFloat)r.left, (CGFloat)r.bottom,
                                 (CGFloat)(r.right - r.left), (CGFloat)(r.top - r.bottom));
        const char *contents = annot->GetContents_UTF8();
        NSString *contentsStr = contents ? [NSString stringWithUTF8String:contents] : @"";
        [marks addObject:@{
            @"rect": [NSValue valueWithRect:rect],
            @"contents": contentsStr,
        }];
    }
    return marks;
}

- (void)addOverlayText:(NSString *)text
                inRect:(CGRect)rect
            fontHandle:(unsigned long long)fontHandle
              fontSize:(float)fontSize
                 color:(unsigned int)color
                 align:(int)align {
    if (!_page || text.length == 0 || fontHandle == 0) return;
    IPDF_Font *font = (IPDF_Font *)(uintptr_t)fontHandle;
    if (!font) return;

    // 粗略估算文字宽度（半宽近似，用于居中/右对齐）
    float textW = fontSize * 0.55f * (float)text.length;
    float x = 0;
    if (align == 0) {
        x = (float)CGRectGetMinX(rect) + 3;
    } else if (align == 2) {
        x = (float)CGRectGetMaxX(rect) - textW - 3;
    } else {
        x = (float)(CGRectGetMidX(rect) - textW / 2.0f);
    }
    float y = (float)(CGRectGetMidY(rect) - fontSize * 0.35f);

    // NSString → wchar_t（macOS wchar_t 为 32 位，BMP 字符直接取 UTF-16 码元）
    NSUInteger len = text.length;
    wchar_t *wbuf = (wchar_t *)malloc(sizeof(wchar_t) * (len + 1));
    if (!wbuf) return;
    for (NSUInteger i = 0; i < len; i++) {
        wbuf[i] = (wchar_t)[text characterAtIndex:i];
    }
    wbuf[len] = 0;
    _page->AddText(wbuf, x, y, font, fontSize, color);
    free(wbuf);
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

- (unsigned long long)annotHandlerAtIndex:(NSInteger)index {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots || index < 0 || index >= annots->Count()) {
        return 0;
    }
    IPDF_Annot *annot = annots->GetAnnot((int)index);
    if (!annot) {
        return 0;
    }
    return (unsigned long long)(uintptr_t)annot->GetAnnotHandler();
}

- (void)removeAnnotByHandler:(unsigned long long)handler {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots || handler == 0) {
        return;
    }
    annots->RemoveAnnotByAnnotHandler((ANNNOT_HANDLER)(uintptr_t)handler);
}

- (void)addAnnotByHandler:(unsigned long long)handler atIndex:(NSInteger)index {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots || handler == 0) {
        return;
    }
    annots->AddAnnotByHandler((int)index, (ANNNOT_HANDLER)(uintptr_t)handler);
}

#pragma mark - 段落编辑

/// UTF-16(NSString) → wchar_t（macOS 上 wchar_t 为 32 位 UTF-32）。
static std::wstring ArkoWStringFromNSString(NSString *s) {
    std::wstring result;
    NSUInteger len = s.length;
    result.reserve(len);
    for (NSUInteger i = 0; i < len; i++) {
        unichar c = [s characterAtIndex:i];
        if (CFStringIsSurrogateHighCharacter(c) && i + 1 < len) {
            unichar lo = [s characterAtIndex:i + 1];
            if (CFStringIsSurrogateLowCharacter(lo)) {
                UTF32Char cp = CFStringGetLongCharacterForSurrogatePair(c, lo);
                result.push_back((wchar_t)cp);
                i++;
                continue;
            }
        }
        result.push_back((wchar_t)c);
    }
    return result;
}

- (IPDF_LogicalStructAnalyser *)sdkAnalyser {
    if (!_analyser && _page) {
        _page->ParseContent();
        _analyser = PDSDK_CreateLogicalStructAnalyser();
        if (_analyser) {
            _analyser->DoAnalyse(_page);
        }
    }
    return _analyser;
}

- (NSInteger)paragraphCount {
    IPDF_LogicalStructAnalyser *a = [self sdkAnalyser];
    return a ? (NSInteger)a->GetParagraphCount() : 0;
}

- (nullable ArkoParagraph *)paragraphAtIndex:(NSInteger)index {
    IPDF_LogicalStructAnalyser *a = [self sdkAnalyser];
    if (!a || index < 0 || index >= a->GetParagraphCount()) {
        return nil;
    }
    IPDF_Paragraph *para = a->GetParagraph((int)index);
    if (!para) return nil;
    return [[ArkoParagraph alloc] initWithSDKParagraph:para];
}

- (nullable ArkoParagraph *)paragraphAtPointX:(CGFloat)x y:(CGFloat)y {
    IPDF_LogicalStructAnalyser *a = [self sdkAnalyser];
    if (!a) return nil;
    PDSDK_FloatPoint p;
    p.x = (float)x;
    p.y = (float)y;
    IPDF_Paragraph *para = a->GetParagraph(&p);
    if (!para) return nil;
    return [[ArkoParagraph alloc] initWithSDKParagraph:para];
}

- (nullable ArkoParagraph *)newParagraphAtX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height {
    IPDF_LogicalStructAnalyser *a = [self sdkAnalyser];
    if (!a) return nil;
    PDSDK_FloatPoint p;
    p.x = (float)x;
    p.y = (float)y;
    IPDF_Paragraph *para = a->NewParagraphAt(&p, (float)width, (float)height);
    if (!para) return nil;
    return [[ArkoParagraph alloc] initWithSDKParagraph:para];
}

- (void)deleteParagraphAtIndex:(NSInteger)index {
    IPDF_LogicalStructAnalyser *a = [self sdkAnalyser];
    if (!a || index < 0 || index >= a->GetParagraphCount()) return;
    IPDF_Paragraph *para = a->GetParagraph((int)index);
    if (para) {
        a->DeleteParagraph(para, NULL);
    }
}

- (void)deleteParagraphAtIndex:(NSInteger)index undoItem:(unsigned long long)undoItem {
    IPDF_LogicalStructAnalyser *a = [self sdkAnalyser];
    if (!a || index < 0 || index >= a->GetParagraphCount()) return;
    IPDF_Paragraph *para = a->GetParagraph((int)index);
    if (para) {
        a->DeleteParagraph(para, (IPDF_ParaUndoItem *)(uintptr_t)undoItem);
    }
}

- (void)deleteParagraphByHandle:(unsigned long long)handle undoItem:(unsigned long long)undoItem {
    IPDF_LogicalStructAnalyser *a = [self sdkAnalyser];
    IPDF_Paragraph *para = (IPDF_Paragraph *)(uintptr_t)handle;
    if (a && para) {
        a->DeleteParagraph(para, (IPDF_ParaUndoItem *)(uintptr_t)undoItem);
    }
}

- (void)paraUndoItem:(unsigned long long)handle {
    IPDF_LogicalStructAnalyser *a = [self sdkAnalyser];
    IPDF_ParaUndoItem *item = (IPDF_ParaUndoItem *)(uintptr_t)handle;
    if (a && item) {
        item->Undo(a);
    }
}

- (void)paraRedoItem:(unsigned long long)handle {
    IPDF_LogicalStructAnalyser *a = [self sdkAnalyser];
    IPDF_ParaUndoItem *item = (IPDF_ParaUndoItem *)(uintptr_t)handle;
    if (a && item) {
        item->Redo(a);
    }
}

#pragma mark - 页面对象

- (IPDF_PageObject *)sdkPageObjectAtIndex:(NSInteger)index {
    if (!_page) return NULL;
    _page->ParseContent();
    if (index < 0 || index >= _page->CountPageObjects()) return NULL;
    return _page->GetPageObject((int)index);
}

- (NSInteger)pageObjectCount {
    if (!_page) return 0;
    _page->ParseContent();
    return (NSInteger)_page->CountPageObjects();
}

- (nullable NSDictionary *)pageObjectInfoAtIndex:(NSInteger)index {
    IPDF_PageObject *obj = [self sdkPageObjectAtIndex:index];
    if (!obj) return nil;
    PDSDK_FloatRect fr;
    obj->GetBBox(&fr);
    CGRect rect = CGRectMake((CGFloat)fr.left, (CGFloat)fr.bottom,
                             (CGFloat)(fr.right - fr.left), (CGFloat)(fr.top - fr.bottom));
    BOOL isImage = obj->GetImageObject() != NULL;
    return @{
        @"type": @(obj->GetType()),
        @"bbox": [NSValue valueWithRect:rect],
        @"image": @(isImage),
    };
}

- (NSInteger)pageObjectIndexAtPointX:(CGFloat)x y:(CGFloat)y {
    if (!_page) return -1;
    _page->ParseContent();
    PDSDK_FloatPoint p;
    p.x = (float)x;
    p.y = (float)y;
    IPDF_PageObject *obj = _page->GetPageObject(&p);
    if (!obj) return -1;
    return (NSInteger)_page->GetZOrder(obj);
}

- (unsigned long long)clonePageObjectAtIndex:(NSInteger)index {
    IPDF_PageObject *obj = [self sdkPageObjectAtIndex:index];
    if (!obj) return 0;
    IPDF_PageObject *clone = obj->Clone();
    return (unsigned long long)(uintptr_t)clone;
}

- (unsigned long long)pageObjectHandlerAtIndex:(NSInteger)index {
    IPDF_PageObject *obj = [self sdkPageObjectAtIndex:index];
    return (unsigned long long)(uintptr_t)obj;
}

+ (void)releasePageObjectClone:(unsigned long long)clone {
    IPDF_PageObject *obj = (IPDF_PageObject *)(uintptr_t)clone;
    if (obj) obj->Release();
}

- (void)addPageObjectClone:(unsigned long long)clone atZOrder:(NSInteger)zOrder {
    if (!_page || !clone) return;
    IPDF_PageObject *src = (IPDF_PageObject *)(uintptr_t)clone;
    IPDF_PageObject *newObj = src->Clone();
    if (newObj) {
        _page->AddPageObject((int)zOrder, newObj);
    }
}

- (void)copyPageObjectAtIndex:(NSInteger)index fromClone:(unsigned long long)clone {
    IPDF_PageObject *obj = [self sdkPageObjectAtIndex:index];
    IPDF_PageObject *src = (IPDF_PageObject *)(uintptr_t)clone;
    if (obj && src) {
        obj->Copy(src);
    }
}

- (void)deletePageObjectAtIndex:(NSInteger)index {
    IPDF_PageObject *obj = [self sdkPageObjectAtIndex:index];
    if (obj) {
        _page->DeletePageObject(obj);
    }
}

- (void)deletePageObjectByHandler:(unsigned long long)handler {
    IPDF_PageObject *obj = (IPDF_PageObject *)(uintptr_t)handler;
    if (obj) {
        _page->DeletePageObject(obj);
    }
}

- (void)movePageObjectAtIndex:(NSInteger)index byX:(float)dx y:(float)dy {
    IPDF_PageObject *obj = [self sdkPageObjectAtIndex:index];
    if (obj) obj->Offset(dx, dy);
}

- (void)resizePageObjectAtIndex:(NSInteger)index toWidth:(float)width height:(float)height {
    IPDF_PageObject *obj = [self sdkPageObjectAtIndex:index];
    if (!obj) return;
    PDSDK_FloatRect fr;
    obj->GetBBox(&fr);
    float oldW = fr.right - fr.left;
    float oldH = fr.top - fr.bottom;
    if (oldW <= 0 || oldH <= 0 || width <= 0 || height <= 0) return;

    float sx = width / oldW;
    float sy = height / oldH;
    // 以左下角为锚点缩放：T(ax,ay) · S(sx,sy) · T(-ax,-ay)
    float ax = fr.left, ay = fr.bottom;
    IPDF_Matrix *m = PDSDK_NewMatrix();
    m->Set(sx, 0, 0, sy, ax * (1 - sx), ay * (1 - sy));
    obj->Transform(m);
    m->Release();
}

- (void)rotatePageObjectAtIndex:(NSInteger)index byAngle:(float)radian {
    IPDF_PageObject *obj = [self sdkPageObjectAtIndex:index];
    if (obj) obj->Rotate(radian);
}

- (void)flipPageObjectAtIndex:(NSInteger)index horizontal:(BOOL)horizontal {
    IPDF_PageObject *obj = [self sdkPageObjectAtIndex:index];
    if (!obj) return;
    IPDF_ImageObject *img = obj->GetImageObject();
    if (!img) return;
    if (horizontal) img->FlipImg_H();
    else img->FlipImg_V();
}

- (void)replaceImageAtIndex:(NSInteger)index withJpegPath:(NSString *)path {
    IPDF_PageObject *obj = [self sdkPageObjectAtIndex:index];
    if (!obj || !path) return;
    std::wstring w = ArkoWStringFromNSString(path);
    _page->ReplaceImage(obj, w.c_str());
}

- (BOOL)exportImageAtIndex:(NSInteger)index toJpegPath:(NSString *)path {
    IPDF_PageObject *obj = [self sdkPageObjectAtIndex:index];
    if (!obj || !path) return NO;
    IPDF_ImageObject *img = obj->GetImageObject();
    if (!img) return NO;
    return img->SaveImgAsJpegUTF8([path UTF8String]) > 0;
}

- (void)sendPageObjectToBackAtIndex:(NSInteger)index {
    IPDF_PageObject *obj = [self sdkPageObjectAtIndex:index];
    if (obj) _page->SendObjToBack(obj);
}

- (void)bringPageObjectToFrontAtIndex:(NSInteger)index {
    IPDF_PageObject *obj = [self sdkPageObjectAtIndex:index];
    if (obj) _page->BringObjToFront(obj);
}

- (NSInteger)addImageWithJpegPath:(NSString *)path
                              atX:(float)x y:(float)y
                            width:(float)width height:(float)height
                            alpha:(float)alpha {
    if (!_page || !path) return -1;
    _page->ParseContent();
    IPDF_PageObject *obj = _page->AddImage([path UTF8String], x, y, width, height, alpha, NULL);
    if (!obj) return -1;
    return (NSInteger)_page->GetZOrder(obj);
}

- (NSInteger)placeSignatureWithJpegPath:(NSString *)path
                                    atX:(float)x y:(float)y
                                  width:(float)width height:(float)height {
    if (!_page || !path) return -1;
    IPDF_Signer *signer = PDSDK_CreateSigner();
    if (!signer) return -1;
    IPDF_Document *sigDoc = PDSDK_NewDocument();
    if (!sigDoc) {
        signer->Release();
        return -1;
    }
    int ok = signer->CreateSignature_UTF8([path UTF8String], sigDoc);
    if (!ok) {
        PDSDK_ReleaseDocument(sigDoc);
        signer->Release();
        return -1;
    }
    IPDF_PageObject *obj = signer->PlaceSignature(_page, x, y, (int)width, (int)height, sigDoc);
    PDSDK_ReleaseDocument(sigDoc);
    signer->Release();
    if (!obj) return -1;
    _page->ParseContent();
    return (NSInteger)_page->GetZOrder(obj);
}

#pragma mark - 链接标注

- (unsigned long long)addLinkAnnotInRect:(CGRect)rect {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots) return 0;
    IPDF_Annot *annot = annots->AddAnnot(ANNOT_TYPE_LINK);
    if (!annot) return 0;
    annot->SetFlags(ANNOT_FLAG_PRINT);
    PDSDK_FloatRect fr;
    fr.left = (float)CGRectGetMinX(rect);
    fr.bottom = (float)CGRectGetMinY(rect);
    fr.right = (float)CGRectGetMaxX(rect);
    fr.top = (float)CGRectGetMaxY(rect);
    annot->SetRect(&fr);
    annot->SetColor(COLOR_MAKERGB(0, 122, 255));  // 蓝色边框，便于识别
    annot->SetBorderWidth(1);
    annot->SetOpacity(0.9f);
    annot->GenerateAppearance();
    return (unsigned long long)(uintptr_t)annot->GetAnnotHandler();
}

- (void)setLinkURI:(NSString *)uri forAnnotHandler:(unsigned long long)handler {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots || !handler) return;
    IPDF_Annot *annot = annots->GetAnnotByAnnotHandler((ANNNOT_HANDLER)(uintptr_t)handler);
    if (annot) {
        annot->SetURI([uri UTF8String]);
    }
}

- (void)setLinkDestinationPage:(NSInteger)pageIndex
                      zoomMode:(NSInteger)zoomMode
                forAnnotHandler:(unsigned long long)handler {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots || !handler) return;
    IPDF_Annot *annot = annots->GetAnnotByAnnotHandler((ANNNOT_HANDLER)(uintptr_t)handler);
    if (annot) {
        PDSDK_Dest dest;
        dest.page_index = (int)pageIndex;
        dest.zoom_mode = (int)zoomMode;
        dest.dest[0] = dest.dest[1] = dest.dest[2] = dest.dest[3] = 0;
        annot->SetDestination(dest);
    }
}

- (nullable NSString *)linkURIForAnnotHandler:(unsigned long long)handler {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots || !handler) return nil;
    IPDF_Annot *annot = annots->GetAnnotByAnnotHandler((ANNNOT_HANDLER)(uintptr_t)handler);
    if (!annot) return nil;
    const char *uri = annot->GetURI();
    return uri ? [NSString stringWithUTF8String:uri] : nil;
}

- (nullable NSDictionary *)linkDestinationForAnnotHandler:(unsigned long long)handler {
    IPDF_AnnotList *annots = [self sdkAnnotList];
    if (!annots || !handler) return nil;
    IPDF_Annot *annot = annots->GetAnnotByAnnotHandler((ANNNOT_HANDLER)(uintptr_t)handler);
    if (!annot) return nil;
    PDSDK_Dest dest;
    if (!annot->GetDestination(dest)) return nil;
    return @{@"page": @(dest.page_index), @"zoomMode": @(dest.zoom_mode)};
}

#pragma mark - 保存

- (void)generateContent {
    if (_page) {
        _page->GenerateContent();
    }
}

- (BOOL)hasTrailmark {
    return _page ? (_page->ExistTrailmark() != 0) : NO;
}

+ (unsigned int)makeRGBColorWithRed:(uint8_t)r green:(uint8_t)g blue:(uint8_t)b {
    return COLOR_MAKERGB(r, g, b);
}

- (void)dealloc {
    if (_analyser) { _analyser->Release(); _analyser = NULL; }
    if (_pageText) { _pageText->Release(); _pageText = NULL; }
    if (_annotList) { _annotList->Release(); _annotList = NULL; }
    if (_page) { _page->Release(); _page = NULL; }
}

@end
