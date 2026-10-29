#pragma once
#include "ipdf_base.h"

class IPDF_Page;
class IPDF_DIBitmap;
class IPDF_Matrix;
class IPDF_Annot;
class IPDF_PathData;

/**
 * @name Annotation Types.
 */
 /*@{*/

/** Unknow type. */
#define ANNOT_TYPE_UNKNOW				0
/** Sticky note. */
#define ANNOT_TYPE_TEXT					1
/** Link annotation. */
#define ANNOT_TYPE_LINK					2
/** Free text annotation */
#define ANNOT_TYPE_FREETEXT				3

/** Line annotation */
#define ANNOT_TYPE_LINE					4
/** Square annotation */
#define ANNOT_TYPE_SQUARE				5
/** Circle annotation */
#define ANNOT_TYPE_CIRCLE				6
/** Polygon annotation */
#define ANNOT_TYPE_POLYGON				7
/** Polyline annotation */
#define ANNOT_TYPE_POLYLINE				8
/** Ink annotation */
#define ANNOT_TYPE_INK					9


/** Highlight annotation */
#define ANNOT_TYPE_HIGHLIGHT			10
/** Underline annotation */
#define ANNOT_TYPE_UNDERLINE			11
/** Squiggly annotation */
#define ANNOT_TYPE_SQUIGGLY				12
/** Strikeout annotation */
#define ANNOT_TYPE_STRIKEOUT			13
/** Caret annotation */
#define ANNOT_TYPE_CARET				14
/** Stamp annotation */
#define ANNOT_TYPE_STAMP				15
/** Popup annotation */
#define ANNOT_TYPE_POPUP				16
/** File attachment annotation */
#define ANNOT_TYPE_FILLATTACHMENT		17
/** Sound annotation */
#define ANNOT_TYPE_SOUND				18
/** Movie annotation */
#define ANNOT_TYPE_MOVIE				19
/** Widget annotation */
#define ANNOT_TYPE_WIDGET				20
/** Screen annotation */
#define ANNOT_TYPE_SCREEN				21
/** PrintmMark annotation */
#define ANNOT_TYPE_PRINTMARK			22
/** Trapnet annotation */
#define ANNOT_TYPE_TRAPNET				23
/** Watermark annotation */
#define ANNOT_TYPE_WATERMARK			24
/** 3D annotation */
#define ANNOT_TYPE_3D					25
/** Repalce annotation */
#define ANNOT_TYPE_REPLACE				26
/** Hilight Area annotation */
#define ANNOT_TYPE_HILIGHTAREA			27
/** TextBox annotation */
#define ANNOT_TYPE_TEXTBOX				28
/** Apple Pencil Kit annotation */
#define ANNOT_TYPE_APK					29
/** Redaction annotation (密文标记) */
#define ANNOT_TYPE_REDACT				30
/*@}*/


/**
 * @name Annotation Border Styles.
 */
/*@{*/

/** No Border */
#define ANNOT_BORDER_NONE		0
/** (Solid) A solid rectangle surrounding the annotation. */
#define ANNOT_BORDER_SOLID		1
/** (Beveled) A simulated embossed rectangle that appears to be raised above the surface of the page.  */
#define ANNOT_BORDER_BEVELED	2
/** (Inset) A simulated engraved rectangle that appears to be recessed below the surface of the page.  */
#define ANNOT_BORDER_INSET		3
/** (Underline) A single line along the bottom of the annotation rectangle. */
#define ANNOT_BORDER_UNDERLINE	4
/** (Dashed)A dashed rectangle surrounding the annotation. */
#define ANNOT_BORDER_DASH		5
/*@}*/

/**
 * @name Annotation Border Effect.
 */
 /*@{*/
/** No effect. */
#define ANNOT_BORDER_EFFECT_NORMAL	0
/** Cloudy effect. */
#define ANNOT_BORDER_EFFECT_CLOUDY	1
/** Ink effect. */
#define ANNOT_BORDER_EFFECT_INK    2
/*@}*/

/**
 * @name Annotation Line Endding Style
 */
 /*@{*/
/** No line ending */
#define ANNOT_LINE_ENDINGSTYLE_NONE 		0
/** A square filled with the annotation’s interior color, if any.  */
#define ANNOT_LINE_ENDINGSTYLE_SQUARE 		1
/** A circle filled with the annotation’s interior color, if any.  */
#define ANNOT_LINE_ENDINGSTYLE_CIRCLE 		2
/** A diamond shape filled with the annotation’s interior color, if any. */
#define ANNOT_LINE_ENDINGSTYLE_DIAMOND 		3
/** Two short lines meeting in an acute angle to form an open arrowhead. */
#define ANNOT_LINE_ENDINGSTYLE_OPENARROW 	4
/** Two short lines meeting in an acute angle as in the OpenArrow style and connected by a third line to form a triangular closed arrowhead filled with the annotation’s interior color, if any. */
#define ANNOT_LINE_ENDINGSTYLE_CLOSEDARROW 	5
/**  A short line at the endpoint perpendicular to the line itself. */
#define ANNOT_LINE_ENDINGSTYLE_BUTT 		6
/** Two short lines in the reverse direction from OpenArrow. */
#define ANNOT_LINE_ENDINGSTYLE_ROPENARROPW 	7
/** A triangular closed arrowhead in the reverse direction from ClosedArrow. */
#define ANNOT_LINE_ENDINGSTYLE_RCLOSEDARROW 8
/** A short line at the endpoint approximately 30 degrees clockwise from perpendicular to the line itself. */
#define ANNOT_LINE_ENDINGSTYLE_SLASH 		9
/*@}*/	

/**
 * @name Subtype of link annotation
 */
 /*@{*/
/** Unknow type. */
#define LINK_UNKNOW		-1
/** Goto a destination. */
#define LINK_DEST		0
/** Open a web url. */
#define LINK_URI		1
/** Open a fileattachment. */
#define LINKE_FILEPATH	2
/*@}*/

/**
 * @name Annotation Appearance Mode
 */
 /*@{*/
/** Normal appearance. */
#define ANNOT_APPEARANCE_NORMAL		0
/** Rollvoer appearance. */
#define ANNOT_APPEARANCE_ROLLOVER	1
/** Down appearance. */
#define ANNOT_APPEARANCE_DOWN		2
/*@}*/

/**
 * @name Annotation Flags
 */
 /*@{*/

/**
 * @brief Do not display the annotation if it does not belong to one of the standard
 * annotation types and no annotation handler is available. 
 */
#define ANNOT_FLAG_INVISIBLE		1
/**
* @brief Do not display or print the annotation or allow it to interact with the user.
*/
#define ANNOT_FLAG_HIDDEN			2
/**
 * @brief Do not print the annotation when the page is printed but displaying on the screen.
 */
#define ANNOT_FLAG_PRINT			4
 /**
  * @brief Do not scale the annotation to match the magnification of the PDF page.
  */
#define ANNOT_FLAG_NOZOOM			8
/**
* @brief Do not rotate the annotation to match the rotation of the page.
*/
#define ANNOT_FLAG_NOROTATE			0x10
/**
 * @brief Do not display the annotation on the screen or allow it to interact with the user.
 */
#define ANNOT_FLAG_NOVIEW			0x20
 /**
  * @brief Do not allow the annotation to interact with the user.
  */
#define ANNOT_FLAG_READONLY			0x40
/**
* @brief Do not allow the annotation to be delete or be modified by the user.
*/
#define ANNOT_FLAG_LOCKED			0x80
/**
 * @brief Invert the interpretation of the ANNOT_FLAG_NOVIEW flag for events.
 */
#define ANNOT_FLAG_TOGGLENOVIEW		0x100
/*@}*/

/**
 * @name Annotation Highlighting mode.
 */
/*@{*/
/** No highlighting. */
#define ANNOT_HIGHLIHT_NONE			0
/** Invert the contents of the annotation. */
#define ANNOT_HIGHLIHT_INVERT		1
/** Hilight the annotation’s border. */
#define ANNOT_HIGHLIHT_OUTLINE		2
/** Display the annotation's down appearance, or offset the contents of the annotation rectangle if no down appearance is defined. */
#define ANNOT_HIGHLIHT_PUSH			3
/*@}*/

class IPDF_WindowsDevice;
struct RENDER_OPTION;

/** @brief The PDF annotiaon hanlder. Indicates the dictionary of annotion. */
typedef void* ANNNOT_HANDLER;

/**
 * @brief Annotation interface.
 *
 */
class IPDF_AnnotList
{
public:
	/** Release annotation list */
	virtual void Release() = 0;

	/**
	 * Display all annotations.
	 *
	 * @param[in] page			The page it belongs to.
	 * @param[in] bitmap		The bitmap to draw on.
	 * @param[in] matrix		The transformation matrix from user space to device space.
	 * @param[in] showwidget	Whether to show widget or not.
	 * 
	 */
	virtual void DisplayAnnots(IPDF_Page* page, IPDF_DIBitmap* bitmap, IPDF_Matrix* matrix, int showwidget) = 0;

	/**
	 * @brief Enable to show icon annotations as fixed size.
	 *
	 * @param[in] nFixedIconType	Indicates how to display fixed annotations.
	 *								0 is to show as normal annotations,
	 *								and 1 is to show as fixed scaling size,
	 *								and 2 is to show as fixed device size.
	 * @param[in] sx				Fixed size according to the value of <i>nFixedIconType</i> in x axis.
	 * @param[in] sy				Fixed size according to the value of <i>nFixedIconType</i> in y axis.
	 * @param[in] nRotate			Page rotation, valid values are 0, 1, 2, 3.
	 */
	virtual void SetFixedIconParams(int nFixedIconType, float sx, float sy, int nRotate) = 0;

	/**
	 * @brief	Get annotation	matrix from page space to device space.
	 *
	 * @param[in] annot						The annotation.
	 * @param[in] user2device_matrix		Current displaying transformation matrix.
	 * @param[out] out_matrix				Annotation matrix to display.
	 */
	virtual void GetAnnotMatrix(const IPDF_Annot* annot, const IPDF_Matrix* user2device_matrix, IPDF_Matrix* out_matrix) const = 0;
	/** Count annotations in the annotation list. */
	virtual int Count() = 0;

	/**
	 * Get an annotation at specified index.
	 *
	 * @param[in] index				The zero-based index in the annotation list.
	 * @return An annotation.
	 */
	virtual IPDF_Annot* GetAnnot(int index) = 0;
	/**
	 * Get annotation's index.
	 *
	 * @param[in] pAnnot			The input annotation.
	 * @return The zero-based index in the annotation list, -1 for not exist.
	 */
	virtual int GetIndex(IPDF_Annot* pAnnot) = 0;
	/** Remove all the annotations. */
	virtual void RemoveAll() = 0;
	/**
	 * Remove the specificed annotation.
	 *
	 * @param[in] pAnnot			The annotation to be removed.
	 */
	virtual void RemoveAnnot(IPDF_Annot* pAnnot) = 0;

	/**
	 * Remove annotation by the specificed annotation handler.
	 *
	 * @param[in] hander			The annotation handler.
	 * @note This method is used to implement Redo/Undo operater of annotation.
	 */
	virtual void RemoveAnnotByAnnotHandler(ANNNOT_HANDLER hander) = 0;

	/**
	 * Get an annotation by specified position.
	 *
	 * @param[in] point				The input position in PDF coordinate.
	 * @return An annotation.
	 */
	virtual IPDF_Annot* GetAnnotAt(const PDSDK_FloatPoint& point) = 0;
	/**
	 * Get an annotation by specified handler.
	 *
	 * @param[in] hander			The annotation handler.
	 * @return An annotation.
	 */
	virtual IPDF_Annot* GetAnnotByAnnotHandler(ANNNOT_HANDLER hander) = 0;
	/**
	 * Set the device DPI.
	 *
	 * @param[in] x			The x-direction DPI.
	 * @param[in] y			The y-direction DPI.
	 * 
	 */
	virtual void SetDrawingDPI(int x, int y) = 0;

	/** Create an annotation by sepcificed type and append to annotation list.
	 *
	 * @param[in] annot_type			The input annotation type.
	 * @return An annotation.
	*/
	virtual IPDF_Annot* AddAnnot(int annot_type) = 0;

	/** Create an annotation by sepcificed hander and insert to annotation list.
	 *
	 * @param[in] insert_at				The zero-based index to insert at.
	 * @param[in] annot_handler			The input annotation handler.
	 * @return An annotation.
	 */
	virtual IPDF_Annot* AddAnnotByHandler(int insert_at, ANNNOT_HANDLER annot_handler) = 0;

	/** Add an annotation to annotation list.
	 *
	 * @param[in] pAnnot				The input annotation.
	 * 
	 */
	virtual void AddAnnot(IPDF_Annot* pAnnot) = 0;
	/** Check whether to show icon annotations as fixed size. */
	virtual int IsFixedIcon() = 0;
};


/**
 * @name Annotation Subtypes
 */
 /*@{*/
/** Arrow annotatioin. */
#define ANNOT_SUBTYPE_ARROW			1
/** Goto destinatioin of link annotatioin. */
#define ANNOT_SUBTYPE_LINKDEST		2
/** Goto websit of link annotatioin. */
#define ANNOT_SUBTYPE_LINKURI		3
/** Open a file attachment of line annotatioin. */
#define ANNOT_SUBTYPE_LINKFILPATH	4
/** Mark Pen annotatioin, a subtype of Ink annotation. */
#define ANNOT_SUBTYPE_MARKPEN		5
/** Hilight Area annotatioin, a subtype of Hightlight annotatioin. */
#define ANNOT_SUBTYPE_AREAHILIGHT	6
/** TextBox annotatioin, a subtype of FreeText annotation. */
#define ANNOT_SUBTYPE_TEXTBOX		7
/*@}*/

/**
 * @brief Annotation Interface.
 *
 */
class IPDF_Annot
{
public:
	/** Release the annotation. */
	virtual void Release() = 0;
	/** Get annotation type.@see Annotation Types
	 *
	 * @return The annotation type.
	 */
	virtual int GetType() = 0;
	/** Get annotation subtype.@see Annotation Subtypes
	 *
	 * @return The annotation subtype.
	 */
	virtual int GetSubType() = 0;

	/** Set annotation subtype.
	 *
	 * @param[in] sub_type			The annotaion subtypes.@see Annotation Subtypes
	 */
	virtual void SetSubType(int sub_type) = 0;

	/** Get annotation flag. @see Annotation Flags
	 *
	 * @return The annotation flags.
	 */
	virtual int GetFlags() = 0;

	/** Set annotation flags.
	 *
	 * @param[in] flags			The annotaion flags.@see Annotation Flags
	 */
	virtual void SetFlags(int flags) = 0;

	/** Get annotation handler. 
	 *
	 * @return The annotation handler, actually the handler is the dictionary of annotation.
	 */
	virtual ANNNOT_HANDLER GetAnnotHandler() = 0;

	/** Get annotation rectangle.
	 *
	 * @return The annotation rectangle.
	 */
	virtual PDSDK_FloatRect GetRect() = 0;

	/** Set annotation rectangle.
	 *
	 * @param[in] rect			The input rectangle.
	 * @note The method just valiable for pop-up annotation.
	 */
	virtual void SetRect(PDSDK_FloatRect* rect) = 0;

	/** Move the annotatioin.
	 *
	 * @param[in] dx			The x-direction delta value.
	 * @param[in] dy			The y-direction delta value.
	 */
	virtual void Move(float dx, float dy) = 0;

	/** Draw annotation to a bitmap.
	 *
	 * @param[in] page						The page whitch the annotation is belong to.
	 * @param[in] bitmap					The bitmap to display the annotation.
	 * @param[in] matrix					The transform matrix. Normally it is the display matrix for page rendering.
	 * @param[in] nAppearenceMode			The appearance mode.@see Annotation Appearance Mode
	 */
	virtual void DrawAnnot(IPDF_Page* page, IPDF_DIBitmap* bitmap, IPDF_Matrix* matrix, int nAppearenceMode) = 0;
	
	/** Draw annotation in a render-context.
	 *
	 * @param[in] page						The page whitch the annotation is belong to.
	 * @param[in] pContext					The rendering context.
	 * @param[in] pUser2Device				The transform matrix. Normally it is the display matrix for page rendering.
	 * @param[in] mode						The appearance mode.@see Annotation Appearance Mode
	 *
	 * @return Non-zero for success, otherwise failure.
	 */
	virtual int DrawInContext(const IPDF_Page* page, const IPDF_RenderContext* pContext,
		const IPDF_Matrix* pUser2Device, int mode) = 0;
#ifdef _WIN32
	/** Draw annotation in Windows Device Context.
	 *
	 * @param[in] page						The page whitch the annotation is belong to.
	 * @param[in] pDevice					The Windows DC to display the annotation.
	 * @param[in] matrix					The transform matrix. Normally it is the display matrix for page rendering.
	 * @param[in] nAppearenceMode			The appearance mode.@see Annotation Appearance Mode
	 * @param[in] opts						The rendering options.Can not be NULL.
	 *
	 * @return Non-zero for success, otherwise failure.
	 */
	virtual int DrawAnnot(const IPDF_Page* page, const IPDF_WindowsDevice* pDevice, const IPDF_Matrix* matrix, int nAppearenceMode, const RENDER_OPTION* opts) = 0;
#endif
	/** Get the line-starting style.
	 *
	 * @return The line-starting style.@see Annotation Line Endding Style
	 */
	virtual int GetLineStartingStyle() = 0;

	/** Set the line-starting style.
	 *
	 * @param[in]  style		The line-starting style.@see Annotation Line Endding Style
	 */
	virtual void SetLineStartingStyle(int style) = 0;

	/** Get the line-endding style.
	 *
	 * @return The line-endding style.@see Annotation Line Endding Style
	 */
	virtual int GetLineEndingStyle() = 0;

	/** Set the line-endding style.
	 *
	 * @param[in]  style		The line-starting style.@see Annotation Line Endding Style
	 */
	virtual void SetLineEndingStyle(int style) = 0;

	/**
	 * @brief Set the points to annotation.
	 *
	 * @param[in] points_array		The input points.
	 * Line annotation: points_array has only two points, specificate the moveto point and lineto piont, if arrow annot, subType is 1.\n
	 * Square annotation: points_array has only two points specificate (left, bottom) and (right, top).\n
	 * Circle annotation: points_array has only two points specificate (left, bottom) and (right, top), means specificate the BBox of Cricle.\n
	 * Polygon annotation: points_array and point_count spcificate the points use to make a polygon.\n
	 * Polyline annotation: points_array and point_count spcificate the points use to make a polyline.\n
	 * Ink annotation:(x1, y1, x2, y2, ..., xn, yn), point_count = n / 2;\n
	 * Markup annotation(Highlight, Underline, Strikeout, Squiggly): points_array has n * 4 points specificate the boxies, the points order of a box is (left, top)(right, top)(left,bottom)(right bottom).\n
	 * Caret annotation: points_array has only two points specificate (left, bottom) and (right, top).\n
	 * StickNote annotation: points_array has two points as the bounding-box:(left, bottom, right, top).\n
	 *
	 * @param[in] point_count	The point count of points_array.
	 * @param[in] subType		The subtype of annotation.Just used for Arrow annotation.
	 *
	 * @return Zero for failure, Non-zero for success.
	 */
	virtual int SetPoints(PDSDK_FloatPoint* points_array[], int point_count, int subType = 0) = 0;

	
	/** Get the points count.
	 *
	 * @return The number of points.
	 * @note for StickNote, return two:(left, bottom), (right, top).
	 */
	virtual int GetPointsCount() = 0;
	
	/**
	 * @brief Get the points of annotation.
 	 *
 	 * @param[in/out] points_array		The points array. It should be filled by PDSDK_FloatPoint object.
 	 * @param[in] array_length			The length of points_array.
 	 * 
 	 * @return The actual readed number of points..
	 */
	virtual int GetPoints(PDSDK_FloatPoint* points_array[], int array_length) = 0;

	/**
	 * @brief Generate the appearance stream of annotation.
	 *
	 * @note When use @see SetPoints() to change the annotation appearance, we need generate the appearance stream before PDF documet saving.
	 */
	virtual void GenerateAppearance() = 0;

	/**
	 * @brief Get the anntation name.
	 *
	 *
	 * @return The annotation name, a text string uniquely identifying it among all the annotations on its page. 
	 */
	virtual const char* GetAnnotName() = 0;

	/**
	 * @brief Set the anntation name.
	 *
	 * @param[in] name			The input name.
	 */
	virtual void SetAnnotName(const char* name) = 0;

	/**
	 * @brief Get the creation date or modified date of annotation.
	 *
	 * @param[in] creat_or_modify			Zero for creation date, 1 for modified date.
	 * @return The date string. The format of date string is (D:YYYYMMDDHHmmSSOHH'mm').
	 */
	virtual const char* GetDate(int creat_or_modify) = 0;

	/**
	 * @brief Set the creation date or modified date of annotation.
	 *
	 * @param[in] date						The date string(YYYYMMDDHHmmSSOHH'mm').
	 * @param[in] creat_or_modify			Zero for creation date, 1 for modified date.
	 * 
	 */
	virtual void SetDate(const char* date, int creat_or_modify) = 0;

	/**
	 * @brief Get the author of annotation.
	 *
	 * @return The author(unicode).
	 */
	virtual const wchar_t* GetAuthor() = 0;

	/**
	 * @brief Set the author of annotation.
	 *
	 * @param[in] author					The input author(unicode).
	 *
	 */
	virtual void SetAuthor(const wchar_t* author) = 0;
	/**
	 * @brief Set the author of annotation, utf8 version.
	 *
	 * @param[in] author					The input author(utf8).
	 *
	 */
	virtual void SetAuthor(const char* author_utf8) = 0;

	/**
	 * @brief Get the subject of annotation.
	 *
	 * @return The subject(unicode).
	 */
	virtual const wchar_t* GetSubject() = 0;

	/**
	 * @brief Set the subject of annotation.
	 *
	 * @param[in] subject					The input subject(unicode).
	 *
	 */
	virtual void SetSubject(const wchar_t* subject) = 0;
	/**
	 * @brief Set the subject of annotation, utf8 version.
	 *
	 * @param[in] subject					The input subject(utf8).
	 *
	 */
	virtual void SetSubject(const char* subject_utf8) = 0;

	/**
	 * @brief Eraser the ink annotation.
	 *
	 * @param[in] rect					Spcificate the rectangle area to be eraser.
	 *
	 */
	virtual int DoEraser(const PDSDK_FloatRect& rect) = 0;

	/**
	 * @brief Test whether the ink annotation is in a rectangle.
	 *
	 * @param[in] rect					The input rectangle.
	 *
	 */
	virtual int IsInkPointsInRect(const PDSDK_FloatRect& rect) = 0;

	/**
	 * @brief Scale annotation to fit a rectangle.
	 *
	 * @param[in] dest_rect				The input destination rectangle.
	 *
	 */
	virtual void ScaleToRect(const PDSDK_FloatRect& dest_rect) = 0;

	/**
	 * @brief Append points to ink annotation.
	 *
	 * @param[in] points_array				The points array. It should be filled by PDSDK_FloatPoint object.
	 * @param[in] point_count				The length of points_array.
	 *
	 */
	virtual void AppendInkPoints(PDSDK_FloatPoint* points_array[], int point_count) = 0;

	/**
	 * @brief Count the number of segments of ink annotation.
	 *
	 * @return The number of segments.
	 *
	 */
	virtual int CountInkPointsSegment() = 0;

	/**
	 * @brief Count the number of points for sepcificate segment.
	 *
	 * @param[in] iSeg			The segment index.
	 * @return The number of the segment specificated by iSeg.
	 *
	 */
	virtual int CountInkSegPoints(int iSeg) = 0;

	/**
	 * @brief Get the points of sepcificated segment.
	 *
	 * @param[in] iSeg			The segment index.
	 * @param[in/out] points_array			The array to receiv the points.
	 * @param[in] array_length			The length of array points_array.
	 * @return The number of the segment specificated by iSeg.
	 *
	 */
	virtual int GetInkPointsSegmnet(int iSeg, PDSDK_FloatPoint* points_array[], int array_length) = 0;

	/**
	 * @brief Get the path data sepcificated segment.
	 *
	 * @param[in] iSeg			The segment index.
	 * @param[in] path_data		The path data with iSeg.
	 * @return The number of the segment specificated by iSeg.
	 *
	 */
	virtual int GetInkSegPathData(int iSeg, IPDF_PathData* path_data) = 0;
	//Common Properties
	/**
	 * @brief Get the border color.
	 *
	 * @param[in/out] rgb		The border color.
	 * @return 0 means no color.
	 *
	 */
	virtual int GetColor(unsigned int& rgb) = 0;

	/**
	 * @brief Set the border color.
	 *
	 * @param[in] rgb		The border color.
	 * 
	 */
	virtual void SetColor(unsigned int rgb) = 0;

	/**
	 * @brief Get the fill color.
	 *
	 * @param[in/out] rgb		The fill color.
	 * @return 0 means no color.
	 *
	 */
	virtual int GetFillColor(unsigned int& rgb) = 0;

	/**
	 * @brief Set the fill color.
	 *
	 * @param[in] rgb		The fill color.
	 *
	 */
	virtual void SetFillColor(unsigned int rgb) = 0;

	/**
	 * @brief Get the opacity.
	 *
	 * @return The opacity from 0.0  to 1.0.
	 *
	 */
	virtual float GetOpacity() = 0;

	/**
	 * @brief Set the opacity.
	 *
	 * @param[in] op		The opacity(0.0-1.0).
	 *
	 */
	virtual void SetOpacity(float op) = 0;

	/**
	* @brief Get border width.
	*
	* @return The border width.
	*
	*/
	virtual int GetBorderWidth() = 0;

	/**
	 * @brief Set border width.
	 *
	 * @param[in] width		The border width.
	 *
	 */
	virtual void SetBorderWidth(int width) = 0;

	/**
	 * @brief Get border style.
	 *
	 * @return The border style.@see Annotation Border Styles
	 *
	 */
	virtual int GetBorderStyle() = 0;

	/**
	 * @brief Set border style.
	 *
	 * @param[in] width		The border style.@see Annotation Border Styles
	 *
	 */
	virtual void SetBorderStyle(int style) = 0;

	/**
	 * @brief 测量标注类型：0=非测量 1=距离(RulerDimension) 2=周长(PerimeterDimension) 3=面积(AreaDimension)。
	 */
	virtual void SetMeasureType(int type) = 0;
	virtual int GetMeasureType() = 0;

	/**
	 * @brief FreeText 变体：0=Textbox 1=Typewriter 2=Callout。存储到 /IT。
	 */
	virtual void SetFreeTextType(int type) = 0;
	virtual int GetFreeTextType() = 0;

	/**
	 * @brief Callout 引出线目标点（页面坐标）。
	 */
	virtual void SetCalloutPoint(float x, float y) = 0;
	virtual int GetCalloutPoint(float& x, float& y) = 0;

	/**
	 * @brief 设置 FreeText 标注的文字内容（重渲染外观）。
	 * 内部从标注 Rect 推算文字左上角；font 为文档默认字体，font_size 为字号（pt）。
	 */
	virtual void SetFreeTextContent_UTF8(const char* content, IPDF_Font* font, float font_size, unsigned int color) = 0;

	/**
	 * @brief Get parent annotation.
	 *
	 * @return The parent annotation.
	 *
	 */
	virtual IPDF_Annot* GetParent() = 0;

	/**
	 * @brief Set parent annotation.
	 *
	 * @param[in] pParent		The parent annotation.
	 *
	 */
	virtual void SetParent(IPDF_Annot* pParent) = 0;

	/**
	 * @brief Get popup annotation.
	 *
	 * @return The popup annotation.
	 *
	 */
	virtual IPDF_Annot* GetPopup() = 0;

	/**
	 * @brief Set popup annotation.
	 *
	 * @param[in] pPopup		The popup annotation.
	 *
	 */
	virtual void SetPopup(IPDF_Annot* pPopup) = 0;

	/**
	 * @brief Set the positon to show popup annotation.
	 *
	 * @param[in] rect		A rectangle to specified the showing area of popup annotation.
	 *
	 */
	virtual void SetPopupRect(const PDSDK_FloatRect& rect) = 0;

	/**
	 * @brief Get the showing rectangel of popup annotation.
	 *
	 * @param[out] rect		The rectangle of popup annotation.
	 *
	 */
	virtual void GetPopupRect(PDSDK_FloatRect& rect) = 0;

	/**
	* @brief Set the open flag of popup annotation.
	*
	* @param[in] bOpen		The popup open flag. 1 for open when display, 0 for closed.
	*
	*/
	virtual void SetPopupOpen(int bOpen) = 0;

	/**
	 * @brief Test whether the content of  annotation is rich text.
	 *
	 * @return 1 for rich text, otherwise not.
	 *
	 */
	virtual int ContentIsRichText() = 0;

	/**
	 * @brief Get annotation content.
	 *
	 * @return The unicode content.
	 *
	 */
	virtual const wchar_t* GetContents() = 0;

	/**
	 * @brief Get annotation content.
	 *
	 * @return The UTF-8 content.
	 *
	 */
	virtual const char* GetContents_UTF8() = 0;

	/**
	* @brief Set annotaion content.
	*
	* @param[in] contents		The unicode encodding content of annotation.
	* @param[in] bRichText		The rich text flag,1 for rich text, otherwise not. 
	*
	*/
	virtual void SetContents(const wchar_t* contents, int bRichText) = 0;

	/**
	* @brief Set annotaion content.
	*
	* @param[in] contents		The UTF-8 encodding content of annotation.
	* @param[in] bRichText		The rich text flag,1 for rich text, otherwise not.
	*
	*/
	virtual void SetContents(const char* contents_utf8, int bRichText) = 0;

	/**
	 * @brief Get IRT annotation.
	 *
	 * @return The IRT annotation.
	 *
	 */
	virtual ANNNOT_HANDLER GetIRT() = 0;

	/**
	 * @brief Set IRT annotation.
	 *
	 * @param[in] pIRTAnnot		The IRT annotation.
	 *
	 */
	virtual void SetIRT(IPDF_Annot* pIRTAnnot) = 0;

	/**
	 * @brief Set annotation to group with annother.
	 *
	 * @param[in] pAnnot		The annotation to be grouped with.
	 *
	 */
	virtual void GroupWith(IPDF_Annot* pAnnot) = 0;

	//link annot
	/**
	 * @brief Get the destination of link annotion.
	 *
	 * @param[out] dest		The desitination.@see PDF destination structure
	 *
	 */
	virtual int GetDestination(PDSDK_Dest& dest) = 0;

	/**
	 * @brief Set the destination to link annotion.
	 *
	 * @param[in] dest		The desitination.@see PDF destination structure
	 *
	 */
	virtual void SetDestination(const PDSDK_Dest& dest) = 0;

	/**
	 * @brief Set named destination to link annotion.
	 *
	 * @param[in] dest_name		The named desitination.
	 *
	 */
	virtual int SetDestination(const wchar_t* dest_name) = 0;

	/**
	 * @brief Get the URI of link annotion.
	 *
	 * @return		The URI string.
	 *
	 */
	virtual const char* GetURI() = 0;

	/**
	 * @brief Set the URI of link annotion.
	 *
	 * @param[in] uri		The URI string.
	 *
	 */
	virtual void SetURI(const char* uri) = 0;

	/**
	 * @brief Get the file path link annotion.
	 *
	 * @return		The file path encodding by unicode .
	 *
	 */
	virtual const wchar_t* GetFilePath() = 0;

	/**
	 * @brief Set file path of link annotion.
	 *
	 * @param[in] path		The unicode encodding file path.
	 *
	 */
	virtual void SetFilePath(const wchar_t* path) = 0;

	/**
	 * @brief Set file path of link annotion.
	 *
	 * @param[in] path		The utf8 encodding file path.
	 *
	 */
	virtual void SetFilePath(const char* path_utf8) = 0;

	/**
	 * @brief Set annotation highlight style.
	 *
	 * @param[in] nStyle		The highlight style. @see Annotation Highlighting mode
	 *
	 */
	virtual void SetHighlightStyle(int nStyle) = 0;

	/**
	 * @brief Test whether a point is in a annotation rectangle.
	 *
	 * @param[in] x		The x component of point.
	 * @param[in] y		The y component of point.
	 *
	 * @return		1 for in annotation rectangle, 0 for not in .
	 */
	virtual int IsPointInAnnot(float x, float y) = 0;

	/**
	 * @brief Enter the edit mode to start edit the annotation text.
	 *  Used for Type write annotion, Text Box annoation, Call Out annotation
	 *
	 * @param[in] nStyle		The highlight style. @see Annotation Highlighting mode
	 *
	 * @return The editable paragraph interface.
	 */
	virtual IPDF_Paragraph* StartEditText() = 0;
	
	/**
	 * @brief Test whether a point is in the editable area of annotation.
	 *
	 * @param[in] x		The x component of point.
	 * @param[in] y		The y component of point.
	 *
	 * @return		1 for in editable area, 0 for not in .
	 */
	virtual int IsPointInEditArea(float x, float y) = 0;

	/**
	 * @brief Set the key-value formatted private data to annotation.
	 *
	 * @param[in] key		The key of private data.
	 * @param[in] value		The value of private data.
	 *
	 * @return		1 for in editable area, 0 for not in .
	 */
	virtual void SetPrivateData(const char* key, const char* value) = 0;

	/**
	 * @brief Test whether a key is exist in annotaion dictionay or
	 * the private data mapped by a key is exist.
	 *
	 * @param[in] key		The key to test.
	 *
	 * @return		1 for exist, 0 for not exist .
	 */
	virtual int	IsKeyExist(const char* key) = 0;

	/**
	 * @brief Get the key-value formatted private data of annotation.
	 *
	 * @param[in] key		The key of private data.
	 *
	 * @return		The value of private data .
	 */
	virtual const char* GetPrivateData(const char* key) = 0;

	/**
	 * @brief Set the unique ID to annotation.
	 *
	 * @param[in] id		The unique ID.
	 *
	 * @return		The value of private data .
	 */
	virtual void SetAnnotID(const char* id) = 0;

	/**
	 * @brief Get the unique ID of annotation.
	 *
	 *
	 * @return		The unique ID of annotation.
	 */
	virtual const char* GetAnnotID() = 0;
#ifdef _WIN32
	/**
	 * @brief Serial annotaiton to XML.
	 *
	 *
	 * @return		A XML element.
	 */
	virtual iAmd_XmlElement* ToXML() = 0;
#endif

	virtual void UpdateContent(const wchar_t* new_content, IPDF_Font* font,float font_size, unsigned int clr, float left, float top) = 0;
	virtual void UpdateContent_UTF8(const char* new_content, IPDF_Font* font, float font_size, unsigned int clr, float left, float top) = 0;
	virtual void SetAPKData(const IPDF_DIBitmap* bitmap, const unsigned char* apk_data, unsigned long len_data, float left, float bottom, float width, float height) = 0;
	virtual unsigned long GetAPKPointData(const unsigned char* apk_data, unsigned long len_data) = 0;

	virtual void GetBounderyPoints(PDSDK_FloatPoint& pt1, PDSDK_FloatPoint& pt2) = 0;
};