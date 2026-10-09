//  ArkoParagraph.h
//  段落编辑适配器：封装 IPDF_Paragraph（由 IPDF_LogicalStructAnalyser 拥有，勿 Release）。
//  每个编辑方法内部创建 SDK 原生撤销项（IPDF_ParaUndoItem），返回其句柄供上层撤销/重做，
//  句柄用完后由上层调 +releaseUndoItem: 释放。对应 Windows 版的 CAmdEdt_EditParaTool 段落部分。

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/// 段落撤销类型（数值与 ipdf_paragraph.h 的 PDSDK_PARA_UNDOTYPE_* 一致）。
typedef NS_ENUM(NSInteger, ArkoParaUndoType) {
    ArkoParaUndoDeleteParagraph = 0,
    ArkoParaUndoInsertText      = 1,
    ArkoParaUndoDeleteText      = 2,
    ArkoParaUndoFont            = 3,
    ArkoParaUndoFontSize        = 4,
    ArkoParaUndoColor           = 5,
    ArkoParaUndoBold            = 6,
    ArkoParaUndoItalic          = 7,
    ArkoParaUndoUnderline       = 8,
    ArkoParaUndoStrikeout       = 9,
    ArkoParaUndoInsertReturn    = 17,
    ArkoParaUndoOffsetPara      = 18,
};

/// 段落：命中测试 / 文本选区 / 文本编辑 / 排版格式。
@interface ArkoParagraph : NSObject

@property (nonatomic, readonly) CGRect bbox;          // 用户坐标（x=left, y=bottom）
@property (nonatomic, readonly) BOOL isRotated;
@property (nonatomic, readonly) BOOL isVertical;
/// 底层 IPDF_Paragraph* 句柄（身份比较/按句柄删除用）。
@property (nonatomic, readonly) unsigned long long paragraphHandle;

// ---- 命中 / 选区 ----
- (NSInteger)caretCount;
- (NSInteger)caretAtPointX:(CGFloat)x y:(CGFloat)y;                    // <0 表示未命中
- (NSInteger)currentCaret;
- (void)currentCaretRange:(NSInteger *)start end:(NSInteger *)end;
- (nullable NSString *)textFromCaret:(NSInteger)start toCaret:(NSInteger)end; // UTF-8
- (NSArray<NSValue *> *)selBoxesFromCaret:(NSInteger)start toCaret:(NSInteger)end; // NSValue(CGRect)

// ---- 文本编辑（返回撤销项句柄，0 表示失败；句柄交 +releaseUndoItem: 释放）----
- (unsigned long long)insertText:(NSString *)utf8
                        atCaret:(NSInteger)caret
                     fontHandle:(unsigned long long)fontHandle
                       fontSize:(float)fontSize
                          color:(unsigned int)argb
                           bold:(BOOL)bold
                         italic:(BOOL)italic
                      underline:(BOOL)underline
                      strikeout:(BOOL)strikeout;
- (unsigned long long)deleteTextFromCaret:(NSInteger)start toCaret:(NSInteger)end;
- (unsigned long long)backspaceAtCaret:(NSInteger)caret;
- (unsigned long long)insertReturnAtCaret:(NSInteger)caret;

// ---- 排版格式（返回撤销项句柄）----
- (unsigned long long)setTextColor:(unsigned int)argb fromCaret:(NSInteger)start toCaret:(NSInteger)end;
- (unsigned long long)setFontSize:(float)size fromCaret:(NSInteger)start toCaret:(NSInteger)end;
- (unsigned long long)setBoldFromCaret:(NSInteger)start toCaret:(NSInteger)end;
- (unsigned long long)setItalicFromCaret:(NSInteger)start toCaret:(NSInteger)end;
- (unsigned long long)setUnderlineFromCaret:(NSInteger)start toCaret:(NSInteger)end;
- (unsigned long long)setStrikeoutFromCaret:(NSInteger)start toCaret:(NSInteger)end;
- (unsigned long long)offsetByX:(float)dx y:(float)dy;

// ---- 格式查询（供格式栏反映当前状态）----
- (float)fontSizeAtCaret:(NSInteger)caret;
- (unsigned int)textColorAtCaret:(NSInteger)caret;   // ARGB（0xAARRGGBB）
- (BOOL)isBoldAtCaret:(NSInteger)caret;
- (BOOL)isItalicAtCaret:(NSInteger)caret;
- (BOOL)isUnderlineAtCaret:(NSInteger)caret;
- (BOOL)isStrikeoutAtCaret:(NSInteger)caret;
/// 当前 caret 处的字体句柄（编辑已有段落时复用该字体，保证字形/编码一致）。
- (unsigned long long)fontHandleAtCaret:(NSInteger)caret;

// ---- 撤销项工厂（全局；Undo/Redo 由 ArkoPage 携带 analyser 调用）----
+ (unsigned long long)createUndoItemOfType:(NSInteger)undoType;
+ (void)releaseUndoItem:(unsigned long long)handle;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithSDKParagraph:(void *)para;

@end

NS_ASSUME_NONNULL_END
