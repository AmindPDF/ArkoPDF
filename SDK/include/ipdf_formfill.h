#pragma once
#include "ipdf_base.h"

#ifndef PDSDKEXPORT
#define PDSDKEXPORT
#endif

class IPDF_Document;
class IPDF_Page;
class IPDF_DIBitmap;

/** 表单字段类型（与 PDFium fpdfformfill.h 保持一致）。 */
#define PDSDK_FORMFIELD_UNKNOWN		0
#define PDSDK_FORMFIELD_PUSHBUTTON	1
#define PDSDK_FORMFIELD_CHECKBOX	2
#define PDSDK_FORMFIELD_RADIOBUTTON	3
#define PDSDK_FORMFIELD_COMBOBOX	4
#define PDSDK_FORMFIELD_LISTBOX		5
#define PDSDK_FORMFIELD_TEXTFIELD	6

/** 系统时间（FFI_GetLocalTime 回调用）。 */
typedef struct _PDSDK_SystemTime {
	unsigned short	year;			/* 实际年份，如 2026 */
	unsigned short	month;			/* 1-12 */
	unsigned short	day;			/* 1-31 */
	unsigned short	hour;			/* 0-23 */
	unsigned short	minute;			/* 0-59 */
	unsigned short	second;			/* 0-59 */
	unsigned short	millisecond;	/* 0-999 */
} PDSDK_SystemTime;

/**
 * 表单填充回调（由上层 ObjC/Swift 桥接实现，MVP 精简版）。
 * 全部回调可空；为空则跳过。
 */
typedef struct _PDSDK_FORMFILLINFO {
	int		version;		/* 必须为 1 */
	void*	pUserData;		/* 用户数据，回调时原样传回 */
	/** 表单变化后请求重绘（page 为底层页对象，left/top/right/bottom 为 PDF 用户坐标）。 */
	void	(*Invalidate)(void* pUserData, void* page, double left, double top, double right, double bottom);
	/** 任一表单字段值改变时通知。 */
	void	(*OnChange)(void* pUserData);
	/** 请求设置光标（FXCT_ARROW/HAND/VBEAM/HBEAM...）。 */
	void	(*SetCursor)(void* pUserData, int cursorType);
	/** 取系统当前时间。 */
	void	(*GetLocalTime)(void* pUserData, PDSDK_SystemTime* time);
} PDSDK_FORMFILLINFO;

/**
 * 表单填充环境（AcroForm 交互：文本框/复选框/单选/下拉/列表/按钮）。
 * 用法：文档打开后 PDSDK_NewFormFillEnvironment 创建；每页加载后调 OnAfterLoadPage，
 * 关闭前调 OnBeforeClosePage；渲染页面内容后再调 DrawFields 叠加表单字段；
 * 鼠标/键盘事件路由到 OnMouseMove/OnLButtonDown/OnKeyDown/OnChar 等。
 */
class IPDF_FormFill {
public:
	virtual void Release() = 0;

	/** 页面加载/关闭钩子（每页必须成对调用）。 */
	virtual void OnAfterLoadPage(IPDF_Page* page) = 0;
	virtual void OnBeforeClosePage(IPDF_Page* page) = 0;

	/** 命中测试：返回字段类型（PDSDK_FORMFIELD_*），无字段返回 -1。 */
	virtual int HasFormFieldAtPoint(IPDF_Page* page, float x, float y) = 0;

	/** 交互事件（返回 1 表示表单引擎已处理，调用方应停止继续分发）。 */
	virtual int OnMouseMove(IPDF_Page* page, int modifier, float x, float y) = 0;
	virtual int OnLButtonDown(IPDF_Page* page, int modifier, float x, float y) = 0;
	virtual int OnLButtonUp(IPDF_Page* page, int modifier, float x, float y) = 0;
	virtual int OnKeyDown(IPDF_Page* page, int keyCode, int modifier) = 0;
	virtual int OnKeyUp(IPDF_Page* page, int keyCode, int modifier) = 0;
	virtual int OnChar(IPDF_Page* page, int nChar, int modifier) = 0;
	virtual int ForceToKillFocus() = 0;

	/** 渲染表单字段到位图（页面内容渲染完成后调用）。 */
	virtual void DrawFields(IPDF_Page* page, IPDF_DIBitmap* bitmap,
							int start_x, int start_y, int size_x, int size_y,
							int rotate, int flags) = 0;

	/** 高亮。fieldType=0 表示所有字段。 */
	virtual void SetHighlightColor(int fieldType, unsigned long color) = 0;
	virtual void SetHighlightAlpha(unsigned char alpha) = 0;
	virtual void RemoveHighlight() = 0;
};

/** 创建表单填充环境（document 打开后可调；失败返回 NULL）。 */
extern "C" PDSDKEXPORT IPDF_FormFill* PDSDK_NewFormFillEnvironment(IPDF_Document* document, const PDSDK_FORMFILLINFO* info);
