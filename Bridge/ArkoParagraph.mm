//  ArkoParagraph.mm

#import "ArkoParagraph.h"
#include "ipdf_base.h"
#include "ipdf_paragraph.h"

@implementation ArkoParagraph {
    IPDF_Paragraph *_para;
}

- (nullable instancetype)initWithSDKParagraph:(void *)para {
    self = [super init];
    if (!self) {
        return nil;
    }
    _para = (IPDF_Paragraph *)para;
    [self buildCaretsIfNeeded];
    return self;
}

/// SDK 的 caret 列表是懒构建的：必须 GetCaretAt 传入段落内一个点，命中某行后才触发
/// BuildCarets()（CountCarets/GetSelBox 等查询在未构建时返回 0/空）。用 bbox 中心点触发。
- (void)buildCaretsIfNeeded {
    if (!_para) return;
    PDSDK_FloatBox box;
    _para->GetBBox(&box);
    PDSDK_FloatPoint pt;
    pt.x = (box.left_bottom_x + box.right_top_x) * 0.5f;
    pt.y = (box.left_bottom_y + box.right_top_y) * 0.5f;
    _para->GetCaretAt(&pt);
}

#pragma mark - 工具

/// 8 角 PDSDK_FloatBox → 包围盒（用户坐标，y=bottom）。
static CGRect ArkoCGRectFromFloatBox(PDSDK_FloatBox *box) {
    if (!box) {
        return CGRectZero;
    }
    float minX = box->left_bottom_x;
    float maxX = box->left_bottom_x;
    float minY = box->left_bottom_y;
    float maxY = box->left_bottom_y;
    const float xs[4] = {box->right_bottom_x, box->right_top_x, box->left_top_x, box->left_bottom_x};
    const float ys[4] = {box->right_bottom_y, box->right_top_y, box->left_top_y, box->left_bottom_y};
    for (int i = 0; i < 4; i++) {
        if (xs[i] < minX) minX = xs[i];
        if (xs[i] > maxX) maxX = xs[i];
        if (ys[i] < minY) minY = ys[i];
        if (ys[i] > maxY) maxY = ys[i];
    }
    return CGRectMake((CGFloat)minX, (CGFloat)minY,
                      (CGFloat)(maxX - minX), (CGFloat)(maxY - minY));
}

static int ArkoBoldItalic(BOOL bold, BOOL italic) {
    return (bold ? 1 : 0) | (italic ? 2 : 0);
}
static int ArkoUnderlineStrikeout(BOOL underline, BOOL strikeout) {
    return (underline ? 1 : 0) | (strikeout ? 2 : 0);
}

#pragma mark - 属性

- (CGRect)bbox {
    if (!_para) return CGRectZero;
    PDSDK_FloatBox box;
    _para->GetBBox(&box);
    return ArkoCGRectFromFloatBox(&box);
}

- (BOOL)isRotated { return _para && _para->IsRotate(); }
- (BOOL)isVertical { return _para && _para->IsVerticalWrittingMode(); }

- (unsigned long long)paragraphHandle {
    return (unsigned long long)(uintptr_t)_para;
}

#pragma mark - 命中 / 选区

- (NSInteger)caretCount {
    if (!_para) return 0;
    [self buildCaretsIfNeeded];
    return (NSInteger)_para->CountCarets();
}

- (NSInteger)caretAtPointX:(CGFloat)x y:(CGFloat)y {
    if (!_para) return -1;
    PDSDK_FloatPoint p;
    p.x = (float)x;
    p.y = (float)y;
    return (NSInteger)_para->GetCaretAt(&p);
}

- (NSInteger)currentCaret {
    return _para ? (NSInteger)_para->GetCurrentCaret() : -1;
}

- (void)currentCaretRange:(NSInteger *)start end:(NSInteger *)end {
    if (!_para) {
        if (start) *start = -1;
        if (end) *end = -1;
        return;
    }
    int s = -1, e = -1;
    _para->GetCurCaretRange(&s, &e);
    if (start) *start = (NSInteger)s;
    if (end) *end = (NSInteger)e;
}

- (nullable NSString *)textFromCaret:(NSInteger)start toCaret:(NSInteger)end {
    if (!_para) return nil;
    int s = (int)start, e = (int)end;
    if (s > e) { int t = s; s = e; e = t; }
    const char *utf8 = _para->GetText_UTF8(s, e);
    if (!utf8) return nil;
    return [NSString stringWithUTF8String:utf8];
}

- (NSArray<NSValue *> *)selBoxesFromCaret:(NSInteger)start toCaret:(NSInteger)end {
    if (!_para) return @[];
    int s = (int)start, e = (int)end;
    if (s > e) { int t = s; s = e; e = t; }
    int n = _para->CountSelBox(s, e);
    NSMutableArray<NSValue *> *boxes = [NSMutableArray arrayWithCapacity:(NSUInteger)n];
    for (int i = 0; i < n; i++) {
        PDSDK_FloatBox box;
        if (_para->GetSelBox(i, &box)) {
            [boxes addObject:[NSValue valueWithRect:ArkoCGRectFromFloatBox(&box)]];
        }
    }
    return boxes;
}

#pragma mark - 文本编辑

- (unsigned long long)insertText:(NSString *)utf8
                        atCaret:(NSInteger)caret
                     fontHandle:(unsigned long long)fontHandle
                       fontSize:(float)fontSize
                          color:(unsigned int)argb
                           bold:(BOOL)bold
                         italic:(BOOL)italic
                      underline:(BOOL)underline
                      strikeout:(BOOL)strikeout {
    if (!_para || !utf8) return 0;
    IPDF_Font *font = (IPDF_Font *)(uintptr_t)fontHandle;
    if (!font) {
        // 未显式给字体时复用 caret 处现有字体。
        font = _para->GetFont((int)caret);
    }
    if (!font) return 0;

    IPDF_ParaUndoItem *item = PDSDK_CreateParaUndoItem(PDSDK_PARA_UNDOTYPE_INSERTTEXT);
    if (!item) return 0;

    int ret = _para->InsertText((int)caret, font, fontSize, argb, [utf8 UTF8String],
                                ArkoBoldItalic(bold, italic),
                                ArkoUnderlineStrikeout(underline, strikeout),
                                SCRIPT_NORMAL, item);
    if (!ret) {
        item->Release();
        return 0;
    }
    return (unsigned long long)(uintptr_t)item;
}

- (unsigned long long)deleteTextFromCaret:(NSInteger)start toCaret:(NSInteger)end {
    if (!_para) return 0;
    int s = (int)start, e = (int)end;
    if (s > e) { int t = s; s = e; e = t; }
    if (s == e) return 0;
    IPDF_ParaUndoItem *item = PDSDK_CreateParaUndoItem(PDSDK_PARA_UNDOTYPE_DELETETEXT);
    if (!item) return 0;
    int ret = _para->DeleteText(s, e, item);
    if (!ret) { item->Release(); return 0; }
    return (unsigned long long)(uintptr_t)item;
}

- (unsigned long long)backspaceAtCaret:(NSInteger)caret {
    if (!_para) return 0;
    IPDF_ParaUndoItem *item = PDSDK_CreateParaUndoItem(PDSDK_PARA_UNDOTYPE_DELETETEXT);
    if (!item) return 0;
    int ret = _para->BackSpaceAt((int)caret, item);
    if (!ret) { item->Release(); return 0; }
    return (unsigned long long)(uintptr_t)item;
}

- (unsigned long long)insertReturnAtCaret:(NSInteger)caret {
    if (!_para) return 0;
    IPDF_ParaUndoItem *item = PDSDK_CreateParaUndoItem(PDSDK_PARA_UNDOTYPE_INSERTRETURN);
    if (!item) return 0;
    int ret = _para->InsertReturn((int)caret, item);
    if (!ret) { item->Release(); return 0; }
    return (unsigned long long)(uintptr_t)item;
}

#pragma mark - 排版格式

- (unsigned long long)setTextColor:(unsigned int)argb fromCaret:(NSInteger)start toCaret:(NSInteger)end {
    if (!_para) return 0;
    IPDF_ParaUndoItem *item = PDSDK_CreateParaUndoItem(PDSDK_PARA_UNDOTYPE_COLOR);
    if (!item) return 0;
    int ret = _para->SetTextColor((int)start, (int)end, argb, item);
    if (!ret) { item->Release(); return 0; }
    return (unsigned long long)(uintptr_t)item;
}

- (unsigned long long)setFontSize:(float)size fromCaret:(NSInteger)start toCaret:(NSInteger)end {
    if (!_para) return 0;
    IPDF_ParaUndoItem *item = PDSDK_CreateParaUndoItem(PDSDK_PARA_UNDOTYPE_FONTSIZE);
    if (!item) return 0;
    int ret = _para->SetFontSize((int)start, (int)end, size, item);
    if (!ret) { item->Release(); return 0; }
    return (unsigned long long)(uintptr_t)item;
}

- (unsigned long long)setBoldFromCaret:(NSInteger)start toCaret:(NSInteger)end {
    if (!_para) return 0;
    IPDF_ParaUndoItem *item = PDSDK_CreateParaUndoItem(PDSDK_PARA_UNDOTYPE_BOLD);
    if (!item) return 0;
    int ret = _para->SetBold((int)start, (int)end, item);
    if (!ret) { item->Release(); return 0; }
    return (unsigned long long)(uintptr_t)item;
}

- (unsigned long long)setItalicFromCaret:(NSInteger)start toCaret:(NSInteger)end {
    if (!_para) return 0;
    IPDF_ParaUndoItem *item = PDSDK_CreateParaUndoItem(PDSDK_PARA_UNDOTYPE_ITALIC);
    if (!item) return 0;
    int ret = _para->SetItalic((int)start, (int)end, item);
    if (!ret) { item->Release(); return 0; }
    return (unsigned long long)(uintptr_t)item;
}

- (unsigned long long)setUnderlineFromCaret:(NSInteger)start toCaret:(NSInteger)end {
    if (!_para) return 0;
    IPDF_ParaUndoItem *item = PDSDK_CreateParaUndoItem(PDSDK_PARA_UNDOTYPE_UNDERLINE);
    if (!item) return 0;
    int ret = _para->SetUnderline((int)start, (int)end, item);
    if (!ret) { item->Release(); return 0; }
    return (unsigned long long)(uintptr_t)item;
}

- (unsigned long long)setStrikeoutFromCaret:(NSInteger)start toCaret:(NSInteger)end {
    if (!_para) return 0;
    IPDF_ParaUndoItem *item = PDSDK_CreateParaUndoItem(PDSDK_PARA_UNDOTYPE_STRIKEOUT);
    if (!item) return 0;
    int ret = _para->SetStrikeout((int)start, (int)end, item);
    if (!ret) { item->Release(); return 0; }
    return (unsigned long long)(uintptr_t)item;
}

- (unsigned long long)offsetByX:(float)dx y:(float)dy {
    if (!_para) return 0;
    IPDF_ParaUndoItem *item = PDSDK_CreateParaUndoItem(PDSDK_PARA_UNDOTYPE_OFFSETPARA);
    if (!item) return 0;
    _para->Offset(dx, dy, item);
    return (unsigned long long)(uintptr_t)item;
}

#pragma mark - 格式查询

- (float)fontSizeAtCaret:(NSInteger)caret { return _para ? _para->GetFontSize((int)caret) : 0; }
- (unsigned int)textColorAtCaret:(NSInteger)caret { return _para ? _para->GetFontColor((int)caret) : 0; }
- (BOOL)isBoldAtCaret:(NSInteger)caret { return _para && _para->IsBold((int)caret); }
- (BOOL)isItalicAtCaret:(NSInteger)caret { return _para && _para->IsItalic((int)caret); }
- (BOOL)isUnderlineAtCaret:(NSInteger)caret { return _para && _para->IsUnderline((int)caret); }
- (BOOL)isStrikeoutAtCaret:(NSInteger)caret { return _para && _para->IsStrikeout((int)caret); }

- (unsigned long long)fontHandleAtCaret:(NSInteger)caret {
    if (!_para) return 0;
    IPDF_Font *font = _para->GetFont((int)caret);
    return (unsigned long long)(uintptr_t)font;
}

#pragma mark - 撤销项工厂

+ (unsigned long long)createUndoItemOfType:(NSInteger)undoType {
    IPDF_ParaUndoItem *item = PDSDK_CreateParaUndoItem((int)undoType);
    return (unsigned long long)(uintptr_t)item;
}

+ (void)releaseUndoItem:(unsigned long long)handle {
    IPDF_ParaUndoItem *item = (IPDF_ParaUndoItem *)(uintptr_t)handle;
    if (item) {
        item->Release();
    }
}

@end
