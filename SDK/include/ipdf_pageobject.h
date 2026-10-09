#pragma once
#include "ipdf_base.h"

class IPDF_Font;
class IPDF_Matrix;
class IPDF_PageObject;
class IPDF_TextObject;
class IPDF_ImageObject;
class IPDF_PathObject;
class IPDF_InlineImages;
class IPDF_FormObject;
class IPDF_ShadingObject;

class IPDF_DIBitmap;
/**
 * @name Page objects
 */
 /*@{*/

/** @brief text object. */
#define PDF_PAGEOBJ_TEXT		1
/** @brief path object. */
#define PDF_PAGEOBJ_PATH		2
/** @brief image object. */
#define PDF_PAGEOBJ_IMAGE		3
/** @brief shading object. */
#define PDF_PAGEOBJ_SHADING		4
/** @brief form object. */
#define PDF_PAGEOBJ_FORM		5
/** @brief inline image object. */
#define PDF_PAGEOBJ_INLINES		6

/*@}*/


/**
 * @name Point flags.
 */
 /*@{*/

 /**
  * @brief Specifies that the figure is automatically closed after the #PDF_PATHFLAG_LINETO or #PDF_PATHFLAG_BEZIERTO type
  * for this point is done. A line is drawn from this point to the most recent #PDF_PATHFLAG_MOVETO point.
  */
#define PDF_PATHFLAG_CLOSE		0x01
  /** @brief Specifies that a line is to be drawn from the current position to this point, and then becomes the new current position. */
#define PDF_PATHFLAG_LINETO		0x02
/** @brief Specifies that this point is a control point or ending point for a Bézier line. */
#define PDF_PATHFLAG_BEZIERTO	0x04
/** @brief Specifies that this point starts a figure. This point becomes the new current position. */
#define PDF_PATHFLAG_MOVETO		0x06
/** @brief Denotes point type mask. Point types are: #PDF_PATHFLAG_MOVETO/#PDF_PATHFLAG_LINETO/#PDF_PATHFLAG_BEZIERTO. */
#define PDF_PATHFLAG_TYPE		0x06

/*@}*/






/** @brief PDF page object interface. */
class IPDF_PageObject
{
public:
	/** Get page object type.@see Page objects */
	virtual int GetType() = 0;
	/** Get page object unique ID.*/
	virtual int GetObjID() = 0;
	/** Set page object unique ID. */
	virtual void SetObjID(int nID) = 0;
	/** Get page object bounding box in user space. */
	virtual void GetBBox(PDSDK_FloatRect* box) = 0;
	/** Get text object interface. */
	virtual IPDF_TextObject* GetTextObject() = 0;

	/** Get image object interface. */
	virtual IPDF_ImageObject* GetImageObject() = 0;

	/** Get path object interface. */
	virtual IPDF_PathObject* GetPathObject() = 0;

	/** Get form object interface. */
	virtual IPDF_FormObject* GetFormObject() = 0;

	/** Get shading object interface. */
	virtual IPDF_ShadingObject* GetShadingObject() = 0;
	
	/**
	 * @brief Get the stroke color used in page object.
	 *
	 * return A RGB color, if equal ((DWORD)-1), means no stroke color be used.
	 *
	 */
	virtual unsigned int GetStrokeColor() = 0;

	/**
	 * @brief Set stroke color to page object.
	 *
	 * @param[in] stroke_rgb	The RGB stroke color, use the macro COLOR_MAKERGB to make a RGB format color.
	 *
	 * return A new image object.
	 */
	virtual void SetStrokeColor(unsigned int stroke_rgb) = 0;

	/**
	 * @brief Get the fill color used in page object.
	 *
	 * return A RGB color, if equal ((DWORD)-1), means no fill color be used.
	 *
	 */
	virtual unsigned int GetFillColor() = 0;

	/**
	 * @brief Set fill color to page object.
	 *
	 * @param[in] fill_rgb	The RGB fill color, use the macro COLOR_MAKERGB to make a RGB format color.
	 *
	 */
	virtual void SetFillColor(unsigned int fill_rgb) = 0;
	
	/**
	 * @brief Transform the page object. such as Rotating, shearring, or moveing object.
	 *
	 * @param[in] matrix	The transform matrix used to transform.
	 */
	virtual void Transform(IPDF_Matrix* matrix) = 0;

	/**
	 * @brief Move the page object.
	 *
	 * @param[in] dx	x-direction detal.
	 * @param[in] dy	y-direction detal.
	 */
	virtual void Offset(float dx, float dy) = 0;

	/**
	 * @brief Rotate the page object at the center of bounding box.
	 *
	 * @param[in] angle	The radian.
	 * 
	 */
	virtual void Rotate(float angle) = 0;
	
	//Clone a page object, if not call IPDF_Page::AddPageObject() to add page, we should call Release() to free it.

	/**
	 * @brief Clone an page object.
	 *
	 * return The cloned page object.
	 *
	 * NOTE:if not call IPDF_Page::AddPageObject() to add page, we should call Release() to free it.
	 */
	virtual IPDF_PageObject* Clone() = 0;

	/**
	 * @brief Copy the page object.
	 *
	 * @return 1 for success, 0 for failure.
	 *
	 */
	virtual int Copy(IPDF_PageObject* pSrcObj) = 0;

	/**
	 * @brief Release the page object.
	 *
	 * NOTE: Just the page object which call Clone() to cloned and have not been added to page can be release.
	 *
	 */
	virtual void Release() = 0;

#ifdef _WIN32
	/** Serial image object to XML */
	virtual iAmd_XmlElement* ToXML(const wchar_t* temp_img_file) = 0;
#endif // _WIN32

	
};
/** @brief PDF text object interface. */
class IPDF_TextObject
{
public:
	/**
	 * @brief Get the text of text object.
	 *
	 * @param[in] unicode_buf	A buffer used to receive the unicode text.
	 * @param[in] buf_len		The buffer lenght.
	 * @return The length of received text.
	 */
	virtual int GetText(unsigned short* unicode_buf, int buf_len) = 0;

	/**
	 * @brief Get origin position of text object.
	 *
	 * @param[out] x	The x-coordinate in user space.
	 * @param[out] y	The y-coordinate in user space.
	 * 
	 */
	virtual void GetBaseLine(float* x, float* y) = 0;

	/**
	 * @brief Set font to text object.
	 *
	 * @param[in] font	The new font to be setted.
	 *
	 */
	virtual void SetFont(IPDF_Font* font) = 0;
	/**
	 * @brief Set font size to text object.
	 *
	 * @param[in] font_size	The new font size .
	 *
	 */

	virtual void SetFontSize(float font_size) = 0;
};

/** @brief PDF image object interface. */
class IPDF_ImageObject
{
public:
	/**
	 * @brief Get image source type.
	 *
	 * @return The image source type, 0 for bitmap, 1 for JPG.
	 */
	virtual int GetImgType() = 0; 

	/**
	 * @brief Get image source data.
	 *
	 * @param[out] buf		A buffer to receiv the image sourse data bytes.
	 * @param[in] buf_len	The buffer length in bytes..
	 *
	 * @return The received data length.
	 */
	virtual int GetImgData(unsigned char* buf, int buf_len) = 0;

	/**
	 * @brief Save image to disk.
	 *
	 * @param[in] path	The destinate jpg file path(unicode).
	 *
	 * @return Less zero for failure, 1 for success.
	 */
	virtual int SaveImgAsJpeg(const wchar_t* path) = 0;

	/**
	 * @brief Save image to disk.
	 *
	 * @param[in] path	The destinate jpg file path(utf8).
	 *
	 * @return Less zero for failure, 1 for success.
	 */
	virtual int SaveImgAsJpegUTF8(const char* path_utf8) = 0;

	/** Flip image object on horizontal. */
	virtual void FlipImg_H() = 0;

	/** Flip image object on vertical. */
	virtual void FlipImg_V() = 0;

	/**
	 * @brief Fit image to a rectangle.
	 *
	 * @param[in] left			The x-coordinate of the left-bottom corner.
	 * @param[in] left			The y-coordinate of the left-bottom corner.
	 * @param[in] right			The x-coordinate of the right-top corner.
	 * @param[in] top			The y-coordinate of the right-top corner.
	 *
	 */
	virtual void FitRect(float left, float bottom, float right, float top) = 0;
	
	/**
	 * @brief Set the clip box to iamge object.
	 *
	 * @param[in] left			The x-coordinate of the left-bottom corner.
	 * @param[in] left			The y-coordinate of the left-bottom corner.
	 * @param[in] right			The x-coordinate of the right-top corner.
	 * @param[in] top			The y-coordinate of the right-top corner.
	 *
	 */
	virtual void SetClip(float left, float bottom, float right, float top) = 0;

	/** Get the pixel width. */
	virtual int GetPixelWidth() = 0;
	/** Get the pixel height. */
	virtual int GetPixelHeight() = 0;

	/**
	 * @brief Render image object into memory bitmap.
	 *
	 * @param[in] dest_width	The pixel width.
	 * @param[in] dest_height	The pixel height.
	 * 
	 * @return	An bitmap which render the image into.
	 *
	 */
	virtual IPDF_DIBitmap* GetBitmap(int dest_width, int dest_height) = 0;
};




/** @brief PDF path object interface. */
class IPDF_PathObject
{
public:
	/** Get path point count. */
	virtual int GetPathPointCount() = 0;

	/**
	 * @brief Get path points.
	 *
	 * @param[in] index		The zero-based index, range is zero to GetPathPointCount().
	 * @param[out] flag		The point flag. @see Point flags
	 * @param[out] point	To receiv the point data.
	 *
	 */
	virtual void GetPathPoint(int index, int* flag, PDSDK_FloatPoint* point) = 0;


	/**
	 * @brief Test whether the path is a rectangle.
	 *
	 * @return 1 for rectangle, 0 for not.
	 *
	 */
	virtual int PathIsRect() = 0;
};

/** @brief PDF form object interface. */
class IPDF_FormObject
{
public:
	virtual int GetPageObjCount() = 0;
	virtual IPDF_PageObject* GetPageObj(int index) = 0;
	virtual void DeletePageObj(IPDF_PageObject* obj) = 0;
	virtual IPDF_PageObject* GetPageObjAtPoint(PDSDK_FloatPoint point) = 0;
};