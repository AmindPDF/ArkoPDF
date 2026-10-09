#pragma once

class IPDF_Document;
struct PDSDK_Dest;

/**
 * @name Bookmark font flags.
 */
 /*@{*/

 /** @brief Italic style of bookmark item. */
#define PDF_BOOKMARK_ITALIC			1
/** @brief Bold style of bookmark item. */
#define PDF_BOOKMARK_BOLD			2

/*@}*/



/**
 * @brief PDF bookmark(outline item) interface.
 */
class IPDF_Bookmark
{
public:
	/** Release a bookmark object. */
	virtual void Release() = 0;

	/** Get the title. A unicode encoded string is returned. */
	virtual const wchar_t* GetTitle() = 0;
	/** Get the title. A utf8 encoded string is returned. */
	virtual const char* GetTitleUTF8() = 0;

	/**
	 * Set the title of a bookmark item.
	 *
	 * @param[in] title		The new title(unicode) of the bookmark item.
	 */
	virtual void SetTitle(const wchar_t* title) = 0;

	/**
	 * Set the title of a bookmark item.
	 *
	 * @param[in] title		The new title (utf8) of the bookmark item.
	 */
	virtual void SetTitle(const char* title_utf8) = 0;
	/** Get the color. In Windows COLORREF format: 0x00ggbbrr. */
	virtual unsigned int GetColor() = 0;

	/**
	 *Set the color of a bookmark item.
	 *
	 * @param[in] color		The new color of the bookmark item.
	 */
	virtual void SetColor(unsigned int color) = 0;

	/** Get the font style. Italic and/or bold. */
	virtual int GetFontStyle() = 0;

	/**
	 *Set the fontstyle of a bookmark item.
	 *
	 * @param[in] color		The new fontstyle of the bookmark item. Italic
	 *						and/or bold. See PDF ref 8.2.2 for the details
	 */
	virtual void SetFontStyle(int style) = 0;
	/**
	 *Get the destination of a bookmark item.
	 *
	 * @param[out] dest		Receiv the destination information.
	 * @param[in] sdk_doc	The PDF document.
	 *
	 */
	virtual void GetDestInfo(PDSDK_Dest* dest, IPDF_Document* sdk_doc) = 0;

	/**
	 *Set the destination of a bookmark item.
	 *
	 * @param[in] dest		The new destination.
	 * @param[in] sdk_doc	The PDF document.
	 *
	 *	NOTE: If the bookmark has action, the action will be removed.
	 */
	virtual void SetDestInfo(const PDSDK_Dest* dest, IPDF_Document* sdk_doc) = 0;
};
/** @brief PDF bookmark(outline) tree interface. */
class IPDF_BookmarkTree
{
public:
	/** Release a bookmark tree object. */
	virtual void Release() = 0;
	
	/**
	 * Get the first child bookmark of specified parent bookmark.
	 * If parent is 0, get top level items.
	 *
	 * @param[in] parent	The input parent bookmark.
	 * @return The first child bookmark.
	 */
	virtual IPDF_Bookmark*		GetFirstChild(const IPDF_Bookmark* parent) = 0;
	/**
	 * Get the next sibling bookmark of specified bookmark in the same level.
	 *
	 * @param[in] bookmark	The input bookmark.
	 * @return The next sibling bookmark.
	 */
	virtual IPDF_Bookmark*		GetNextSibling(const IPDF_Bookmark* bookmark) = 0;

	/**
	 * New a bookmark item and insert into bookmark tree.
	 *
	 * @param[in] title				The unicode title of new bookmark.
	 * @param[in] parent			The parent of new bookmark. Can be 0, if insert_after not NULL or 
	 *								it will be the first item of the tree.
	 * @param[in] insert_after		The item after which the new item is to be inserted.
	 *								If 0, will be inserted to the first child of parent.
	 * @return The new item if successful; otherwise 0.
	*/
	virtual IPDF_Bookmark*		InsertBookmark(const wchar_t* title, IPDF_Bookmark* parent, IPDF_Bookmark* insert_after) = 0;
	/**
	 * New a bookmark item and insert into bookmark tree.
	 *
	 * @param[in] title				The utf8 title of new bookmark.
	 * @param[in] parent			The parent of new bookmark. Can be 0, if insert_after not NULL or
	 *								it will be the first item of the tree.
	 * @param[in] insert_after		The item after which the new item is to be inserted.
	 *								If 0, will be inserted to the first child of parent.
	 * @return The new item if successful; otherwise 0.
	*/
	virtual IPDF_Bookmark*		InsertBookmark(const char* title_utf8, IPDF_Bookmark* parent, IPDF_Bookmark* insert_after) = 0;

	/**
	 * Move a bookmark item to specified level.
	 *
	 * @param[in] bookmark			The bookmark to be moved.
	 * @param[in] parent_moveto		The destinate parent which to be inserting.
	 *								
	 * @param[in] insert_after		The item after which the moving item is to be inserted.
	 *								If 0, will be inserted to the first child of parent.
	 * @return 1 if successful; otherwise 0.
	*/
	virtual int          		MoveBookmark(IPDF_Bookmark* bookmark, IPDF_Bookmark* parent_moveto, IPDF_Bookmark* insert_after) = 0;

	/**
	 * Remove a bookmark item from bookmark tree.
	 * @param[in] bookmark	The bookmark item to be removed.
	 */
	virtual void				RemoveBookmark(IPDF_Bookmark* bookmark) = 0;
};