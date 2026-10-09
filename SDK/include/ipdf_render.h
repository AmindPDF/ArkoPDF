#pragma once

#include "ipdf_base.h"

class IPDF_Document;
class IPDF_Page;
class IPDF_Matrix;
class IPDF_DIBitmap;

class IPDF_RenderContext;

//Color mode of render option.
#define PDSDK_RENDER_COLOR_NORMAL			0
#define PDSDK_RENDER_COLOR_GRAY				1
#define PDSDK_RENDER_COLOR_TWOCOLOR			2
#define PDSDK_RENDER_COLOR_ALPHA			3
//Flags of render option.
#define PDSDK_RENDER_CLEARTYPE				0x00000001
#define PDSDK_RENDER_PRINTGRAPHICTEXT		0x00000002
#define PDSDK_RENDER_FORCE_DOWNSAMPLE		0x00000004
#define PDSDK_RENDER_PRINTPREVIEW			0x00000008
#define PDSDK_RENDER_BGR_STRIPE				0x00000010
#define PDSDK_RENDER_NO_NATIVETEXT			0x00000020
#define PDSDK_RENDER_FORCE_HALFTONE			0x00000040
#define PDSDK_RENDER_RECT_AA				0x00000080
#define PDSDK_RENDER_FILL_FULLCOVER			0x00000100
#define PDSDK_RENDER_PRINTIMAGETEXT			0x00000200
#define PDSDK_RENDER_OVERPRINT				0x00000400
#define PDSDK_RENDER_THINLINE				0x00000800
#define PDSDK_RENDER_NOTEXTSMOOTH			0x10000000
#define PDSDK_RENDER_NOPATHSMOOTH			0x20000000
#define PDSDK_RENDER_NOIMAGESMOOTH			0x40000000
#define PDSDK_RENDER_LIMITEDIMAGECACHE		0x80000000

//dash pattern
#define PDSDK_DASHPATTERN_NONE				0	//solid
#define PDSDK_DASHPATTERN_3_0				1	//3 units on, 3 units off, ...
#define PDSDK_DASHPATTERN_2_1				2	//1 on, 2 off, 2 on, 2 off
#define PDSDK_DASHPATTERN_2_1_0				3	//2 on, 1 off, 2 on, 1 off
#define PDSDK_DASHPATTERN_3_5_6				4	//2 off, 3 on, 5 off, 3 on, 5 off
#define PDSDK_DASHPATTERN_2_3_11			5	//1 on, 3 off, 2 on, 3 off, 2 on
#define PDSDK_DASHPATTERN_6			6	

struct RENDER_OPTION {
	int				m_ColorMode;
	unsigned int		m_BackColor;
	unsigned int		m_ForeColor;
	unsigned int		m_Flags;
};

class IPDF_FormObject;
class IPDF_RenderContext
{
public:
	virtual void Release() = 0;
	
	virtual void Create(IPDF_Page* page, IPDF_Matrix* display_matrix) = 0;
	virtual void Create(IPDF_FormObject* page, IPDF_Matrix* display_matrix) = 0;
	virtual void Render(IPDF_DIBitmap* bitmap, IPDF_Matrix* display_matrix, RENDER_OPTION* options) = 0;
};


/**
 * @brief Specifies that the figure is automatically closed after the #PDSDK_PT_LINETO or #PDSDK_PT_BEZIERTO type
 * for this point is done. A line is drawn from this point to the most recent #SDKPT_MOVETO point.
 */
#define PDSDK_PT_CLOSEFIGURE		0x01
 /** @brief Specifies that a line is to be drawn from the current position to this point, which then becomes the new current position. */
#define PDSDK_PT_LINETO			0x02
/** @brief Specifies that this point is a control point or ending point for a Bézier spline. */
#define PDSDK_PT_BEZIERTO			0x04
/** @brief Specifies that this point starts a figure. This point becomes the new current position. */
#define PDSDK_PT_MOVETO			0x06
/** @brief Denotes point type mask. Point types are: #PDSDK_PT_MOVETO/#PDSDK_PT_LINETO/#PDSDK_PT_BEZIERTO. */
#define PDSDK_PT_TYPE				0x06

/*@}*/

/**
 * @name Path fill modes.
 */
 /*@{*/

 /** @brief The alternate fill mode. */
#define PDSDK_FILL_ALTERNATE		1
/** @brief The winding fill mode. */
#define PDSDK_FILL_WINDING			2

typedef struct {
	float			m_PointX;
	float			m_PointY;
	int				m_Flag;
} PDSDK_PATHPOINT;


class IPDF_PathData
{
public:
	virtual void Release() = 0;
	virtual int GetPointCount() = 0;
	virtual float GetPointX(int index) = 0;
	virtual float GetPointY(int index) = 0;
	virtual int GetPointFlag(int index) = 0;
};

class IPDF_FxgeDevice
{
public:
	virtual void Release() = 0;
	virtual void Attach(IPDF_DIBitmap* bitmap) = 0;
	virtual int SetPixel(int x, int y, unsigned int color, int alpha_flag = 0) = 0;
	virtual int FillRect(const PDSDK_Rect* rect, unsigned int color, int alpha_flag = 0) = 0;
	virtual int DrawCosmeticLine(float x1, float y1, float x2, float y2, unsigned int color,int fill_mode = 0, int alpha_flag = 0) = 0;
	virtual void SetDIBits(const IPDF_DIBitmap* pBitmap, int left, int top, int blend_type = DIB_BLEND_NORMAL) = 0;

	virtual int StartRendering() = 0;
	virtual void EndRendering() = 0;
	virtual void Begin() = 0;
	virtual void End() = 0;
	virtual int IsPSPrintDriver() = 0;
	virtual void SaveState() = 0;
	virtual void RestoreState(int bKeepSaved = 0) = 0;
	virtual int	SetClip_Rect(const PDSDK_Rect* rect) = 0;
};



#ifdef _WIN32
#ifndef _WINDOWS_
#include <windows.h>
#endif


class IPDF_WindowsDevice
{
public:
	virtual void Release() = 0;
	virtual void Attach(HDC hdc, int bCmykOutput = 0, int bForcePSOutput = 0, int psLevel = 2) = 0;
	virtual int DrawCosmeticLine(float x1, float y1, float x2, float y2, unsigned int color, int fill_mode = 0, int alpha_flag = 0) = 0;
	virtual void SetDIBits(const IPDF_DIBitmap* pBitmap, int left, int top, int blend_type = DIB_BLEND_NORMAL) = 0;
	virtual int StartRendering() = 0;
	virtual void EndRendering() = 0;
	virtual void Begin() = 0;
	virtual void End() = 0;
	virtual int IsPSPrintDriver() = 0;
	virtual void SaveState() = 0;
	virtual void RestoreState(int bKeepSaved = 0) = 0;
	virtual int	SetClip_Rect(const PDSDK_Rect* rect) = 0;
	virtual IPDF_DIBitmap* GetBitmap() = 0;
	//drawing
	virtual void DrawPath(PDSDK_PATHPOINT* path_data, int point_count, 
		int line_width, unsigned int argb_stroke, unsigned int argb_fill, int fill_type) = 0;
	virtual void DrawLine(const PDSDK_FloatPoint& pt1, const PDSDK_FloatPoint& pt2,
		unsigned int argb, int line_width, int line_style, int dash_pattern, 
		int line_start_style, int line_ending_style,
		int fill_mode, float scale = 1.f, IPDF_Matrix* pObj2Device = NULL) = 0;
	virtual void DrawPolyLine(PDSDK_FloatPoint* points[], int points_count,
		unsigned int argb, int line_width, int line_style, int dash_pattern,
		int line_start_style, int line_ending_style,
		int fill_mode, float scale = 1.f, IPDF_Matrix* pObj2Device = NULL) = 0;
	virtual void DrawRect(const PDSDK_FloatRect& rect,
		unsigned int argb, int border_width, int border_style, int dash_pattern,
		int line_start_style, int line_ending_style,
		int fill_mode, float scale = 1.f, IPDF_Matrix* pObj2Device = NULL) = 0;
	virtual void DrawEllipse(const PDSDK_FloatRect rect,
		unsigned int argb, int border_width, int border_style, int dash_pattern,
		int line_start_style, int line_ending_style,
		int fill_mode, float scale = 1.f, IPDF_Matrix* pObj2Device = NULL) = 0;

};
#endif // _WIN32

//Render status
#define PDSDK_RENDERSTATUS_READY		0
#define PDSDK_RENDERSTATUS_CONTINUE		1
#define PDSDK_RENDERSTATUS_DONE			2
#define PDSDK_RENDERSTATUS_FAILED		3

class IPDF_ProgressiveRenderer
{
public:
	virtual void Release() = 0;
	virtual int GetStatus() = 0;
	virtual void Start(IPDF_RenderContext* render_context, IPDF_FxgeDevice* device,
		const RENDER_OPTION* options, class IPDF_Pause* pause, int bDropObjects = 0) = 0;
	
#ifdef _WIN32
	virtual void Start(IPDF_RenderContext* render_context, IPDF_WindowsDevice* device,
		const RENDER_OPTION* options, class IPDF_Pause* pause, int bDropObjects = 0) = 0;
#endif 
	virtual void Continue(class IPDF_Pause* pause) = 0;
	virtual void Clear() = 0;
};




//show mode
#define PDF_SHOWMODE_SINGLE            0  
#define PDF_SHOWMODE_CONTINUOUS        1
#define PDF_SHOWMODE_SINGLE_FACING     2
#define PDF_SHOWMODE_CONTINUOUS_FACING 3

//zoom mode
#define  PDF_ZOOMEMODE_NONE            0
#define  PDF_ZOOMEMODE_CUSTOM          1
#define  PDF_ZOOMEMODE_ACTUAL_SIZE     2
#define  PDF_ZOOMEMODE_FIT_PAGE        3
#define  PDF_ZOOMEMODE_FIT_WIDTH       4
#define  PDF_ZOOMEMODE_FIT_HEIGHT      5
#define  PDF_ZOOMEMODE_FIT_RECTANGLE   6
#define  PDF_ZOOMEMODE_FIT_VISIBLE	  7

#define LAYOUT_VIEWER_VIEWMODE			0  
#define LAYOUT_VIEWER_THUMBMODE			1
struct Viewer_LayoutInfo{
	int show_mode;//PDF_SHOWMODE_XXXX
	int facing_count;
	int zoom_mode;//PDF_ZOOMEMODE_XXXX
	float zoom_factor;
	int is_coverpage;//0:normal, 1:cover page.
	int show_annot;//0:do not show annoations, 1:show
	int reverse_pages; //0:normal, 1:reverse
	int rotate; //0: no rotate, 1:rotate-clockwise 90 degree, 2:180, 3:270

	int         margin_h;      //[horizontal margin]
//	int			margin_v;      //[vertical margin]
	int			margin_top;      //[top margin]
	int			margin_bottom;      //[bottom margin]
	int			border_h;	   //
	int         border_v;	   //
	int         page_space;    //space between pages
};

class IViewer_RenderCallbacks
{
public:
	virtual IPDF_Document* GetDocument() = 0;
	virtual IPDF_Page* GetPage(int page_index) = 0;
	virtual int ParsePage(int page_index) = 0;
	virtual int IsPageLocked() = 0;
	
	//platform handler
	virtual unsigned int GetTickCount() = 0;
	
	//Render event
	virtual	void OnBeforeDraw(IPDF_DIBitmap* bmp) = 0;
	virtual	void OnAfterDraw(IPDF_DIBitmap* bmp) = 0;
	virtual	void OnDrawBackground(IPDF_DIBitmap* bmp) = 0;
	virtual	void OnDrawPShawdow(IPDF_DIBitmap* bmp, int page_index) = 0;
	virtual	void OnPageVisible(int page_index, int visible) = 0;
	virtual	void OnPageIndexChange(int page_index) = 0;
	virtual	void OnStartRendering() = 0;
	virtual	void OnFinishRendering() = 0;
	virtual	void OnRenderDataChange() = 0;
	virtual void OnScalePage(int page_index) = 0;
	virtual void OnGotoPage(int page_index) = 0;
};


class IPDF_Viewer
{
public:
	virtual void Release() = 0;
	
	virtual void Create(IViewer_RenderCallbacks* callbacks, int nLayout) = 0;
	virtual void SetSize(int canvas_width, int canvas_height) = 0;
	virtual void InitLayout(int dpi_x, int dpi_y, Viewer_LayoutInfo* layout_info) = 0;
	
	virtual void SetShowMode(int mode, int facing_count) = 0;
	virtual void GetShowMode(int* mode, int* facing_count) = 0;
	virtual void SetZoomMode(int zoom_mode) = 0;
	virtual int GetZoomMode() = 0;
	virtual void SetRotate(int rotate) = 0;
	virtual int GetRotate() = 0;
	virtual void SetReverse(int reverse) = 0;
	virtual void SetCoverPage(int cover) = 0;
	virtual int IsCoverPage() = 0;
	virtual void SetShowAnnots(int show_annots) = 0;
	virtual IPDF_DIBitmap* GetDisplayBitmap(int bProgressive) = 0;//user cannot release this bitmap;
	virtual void ContinueRendering() = 0;
	
	//page view info
	virtual int GetCurrentPage() = 0;
	virtual PDSDK_Rect GetPageRectInCanvas(int page_index, int bCalc = 0) = 0;
	//page rectangle include margin
	virtual PDSDK_Rect GetPageFullRectInCanvas(int page_index) = 0;
	virtual int	IsVisible(int page_index) = 0;
	
//	virtual int GetRenderStatus() = 0;
	
	//scroll info
	virtual void GetScrollMaxRange(unsigned long* out_MaxWidth, unsigned long* out_MaxHeight) = 0;
	virtual unsigned long GetCurScrollPosX() = 0;
	virtual unsigned long GetCurScrollPosY() = 0;
	virtual void ScrollToPosX(unsigned long pos_x) = 0;
	virtual void ScrollToPosY(unsigned long pos_y) = 0;
	virtual void Scroll(unsigned long offset_x, unsigned long offset_y, int current_row_only = 0) = 0;
	
	//Go to page
	virtual void GotoPage(int page_index, int bFitVisible) = 0;
	virtual void GotoPage(int page_index, float start_left, float start_top) = 0;
	virtual void GotoPage(PDSDK_Dest dest) = 0;
	virtual void ZoomTo(int zoom_mode, float scale = 1.0f, int fit_mode = -1, int fit_h = -1, int bCalcScale = 1) = 0;
	virtual float GetZoomFactor() = 0;
	virtual float GetZoomFactorFromZoomMode(int zoom_mode) = 0;
	virtual void FitVisible(int page_index) = 0;
	virtual int GetPageFromPosY(unsigned long pos_y) = 0;
	
	//Previouse / Next View
	virtual void ClearViewRecords() = 0;
	virtual void AddViewRecords() = 0;
	virtual void PrevView() = 0;
	virtual void NextView() = 0;
	virtual int ExistPrevView() = 0;
	virtual int ExistNextView() = 0;
	
	virtual void SetRedrawFlag() = 0;
	virtual void SetPDFPagesChanged() = 0;
	
	virtual int GetFacingCount() = 0;
	virtual int	GetRowCount() = 0;              
	virtual int	 GetColCount() = 0;                  
};