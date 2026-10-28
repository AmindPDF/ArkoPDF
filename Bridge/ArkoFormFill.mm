//  ArkoFormFill.mm
//  表单填充桥接：封装 PDSDK 的 IPDF_FormFill。

#import "ArkoFormFill.h"
#import "ArkoPage.h"
#include "ipdf_formfill.h"
#include "ipdf_document.h"
#include "ipdf_page.h"
#include <string.h>

// ============ PDSDK_FORMFILLINFO 回调 ============

static void _FF_Invalidate(void* pUserData, void* page,
						   double left, double top, double right, double bottom) {
	ArkoFormFill* self = (__bridge ArkoFormFill*)pUserData;
	if (self.onInvalidate) self.onInvalidate();
}

static void _FF_OnChange(void* pUserData) {
	ArkoFormFill* self = (__bridge ArkoFormFill*)pUserData;
	if (self.onChange) self.onChange();
}

static void _FF_SetCursor(void* pUserData, int cursorType) {
	// 光标由 Swift 侧 hover 逻辑控制，这里暂不处理。
}

static void _FF_GetLocalTime(void* pUserData, PDSDK_SystemTime* time) {
	if (!time) return;
	NSDate* now = [NSDate date];
	NSCalendar* cal = [NSCalendar currentCalendar];
	NSDateComponents* c = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
										   NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond |
										   NSCalendarUnitNanosecond) fromDate:now];
	time->year = (unsigned short)c.year;
	time->month = (unsigned short)c.month;
	time->day = (unsigned short)c.day;
	time->hour = (unsigned short)c.hour;
	time->minute = (unsigned short)c.minute;
	time->second = (unsigned short)c.second;
	time->millisecond = (unsigned short)(c.nanosecond / 1000000);
}

// ============ 实现 ============

@interface ArkoFormFill () {
	IPDF_FormFill* _ff;
	PDSDK_FORMFILLINFO _info;
}
@end

@implementation ArkoFormFill

static IPDF_FormFill* g_pFormFill = NULL;

void* ArkoGetSDKFormFill(void) { return g_pFormFill; }
void ArkoSetSDKFormFill(void* ff) { g_pFormFill = (IPDF_FormFill*)ff; }

- (instancetype)initWithSDKDocument:(void *)docHandle {
	self = [super init];
	if (self) {
		memset(&_info, 0, sizeof(_info));
		_info.version = 1;
		_info.pUserData = (__bridge void*)self;
		_info.Invalidate = _FF_Invalidate;
		_info.OnChange = _FF_OnChange;
		_info.SetCursor = _FF_SetCursor;
		_info.GetLocalTime = _FF_GetLocalTime;
		_ff = PDSDK_NewFormFillEnvironment((IPDF_Document*)docHandle, &_info);
		if (!_ff) {
			return nil;
		}
		ArkoSetSDKFormFill(_ff);
	}
	return self;
}

- (void)close {
	if (_ff) {
		ArkoSetSDKFormFill(NULL);
		_ff->Release();
		_ff = NULL;
	}
}

- (void)dealloc {
	[self close];
}

- (void)onAfterLoadPage:(ArkoPage *)page {
	if (_ff) _ff->OnAfterLoadPage((IPDF_Page*)[page sdkPage]);
}

- (void)onBeforeClosePage:(ArkoPage *)page {
	if (_ff) _ff->OnBeforeClosePage((IPDF_Page*)[page sdkPage]);
}

- (NSInteger)formFieldTypeAtPage:(ArkoPage *)page x:(CGFloat)x y:(CGFloat)y {
	if (!_ff) return -1;
	return _ff->HasFormFieldAtPoint((IPDF_Page*)[page sdkPage], (float)x, (float)y);
}

- (BOOL)onMouseMoveAtPage:(ArkoPage *)page x:(CGFloat)x y:(CGFloat)y modifier:(int)modifier {
	if (!_ff) return NO;
	return _ff->OnMouseMove((IPDF_Page*)[page sdkPage], modifier, (float)x, (float)y) != 0;
}

- (BOOL)onLButtonDownAtPage:(ArkoPage *)page x:(CGFloat)x y:(CGFloat)y modifier:(int)modifier {
	if (!_ff) return NO;
	return _ff->OnLButtonDown((IPDF_Page*)[page sdkPage], modifier, (float)x, (float)y) != 0;
}

- (BOOL)onLButtonUpAtPage:(ArkoPage *)page x:(CGFloat)x y:(CGFloat)y modifier:(int)modifier {
	if (!_ff) return NO;
	return _ff->OnLButtonUp((IPDF_Page*)[page sdkPage], modifier, (float)x, (float)y) != 0;
}

- (BOOL)onKeyDownAtPage:(ArkoPage *)page keyCode:(int)keyCode modifier:(int)modifier {
	if (!_ff) return NO;
	return _ff->OnKeyDown((IPDF_Page*)[page sdkPage], keyCode, modifier) != 0;
}

- (BOOL)onKeyUpAtPage:(ArkoPage *)page keyCode:(int)keyCode modifier:(int)modifier {
	if (!_ff) return NO;
	return _ff->OnKeyUp((IPDF_Page*)[page sdkPage], keyCode, modifier) != 0;
}

- (BOOL)onCharAtPage:(ArkoPage *)page nChar:(int)nChar modifier:(int)modifier {
	if (!_ff) return NO;
	return _ff->OnChar((IPDF_Page*)[page sdkPage], nChar, modifier) != 0;
}

- (BOOL)forceKillFocus {
	if (!_ff) return NO;
	return _ff->ForceToKillFocus() != 0;
}

- (void)drawFieldsForPage:(ArkoPage *)page
				   bitmap:(void *)bitmap
				  startX:(int)startX startY:(int)startY
				   sizeX:(int)sizeX sizeY:(int)sizeY
				  rotate:(int)rotate flags:(int)flags {
	if (!_ff) return;
	_ff->DrawFields((IPDF_Page*)[page sdkPage], (IPDF_DIBitmap*)bitmap,
					startX, startY, sizeX, sizeY, rotate, flags);
}

- (void)setHighlightColor:(int)fieldType color:(unsigned long)color {
	if (_ff) _ff->SetHighlightColor(fieldType, color);
}

- (void)setHighlightAlpha:(unsigned char)alpha {
	if (_ff) _ff->SetHighlightAlpha(alpha);
}

- (void)removeHighlight {
	if (_ff) _ff->RemoveHighlight();
}

@end
