#pragma once
#include "ipdf_base.h"
class IPDF_Page;

/**
 * @name Find flags.
 */
 /*@{*/

/** @brief Whether to match the character case(upper or lower). */
#define PDFFIND_MATCHCASE      0x00000001
/** @brief Whether to match the whole word. */
#define PDFFIND_MATCHWHOLEWORD 0x00000002
/** @brief Whether to do consecutive searching. */
#define PDFFIND_CONSECUTIVE	0x00000004

/*@}*/

/** @brief PDF Text Page Interface. */
class IPDF_PageText
{
public:
	/** Release the PDF texgt page. */
	virtual void Release() = 0;

	/**
	 * @brief Get all text in a page.
	 *
	 * @param[in/out] in_out_buf		A buffer to receiv the text.
	 * @param[in/out] in_out_buflen		Length of in_out_buf buffer.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int GetAllText(char* in_out_buf, int* in_out_buflen) = 0;

	/**
	 * @brief Unicode version for getting all text in a page.
	 *
	 * @param[in/out] in_out_buf		A buffer to receiv the text.
	 * @param[in/out] in_out_buflen		Length of in_out_buf buffer.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int GetAllText_Unicode(wchar_t* in_out_buf, int* in_out_buflen) = 0;
	
	/**
	 * @brief Parse page text.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int ParseText() = 0;

	/**
	 * @brief Test whether the page text is parsed.
	 *
	 * @return 1 for parsed, 0 for not parsed.
	 */
	virtual int IsParsed() = 0;
	
	/**
	 * @name Text selection methods.
	 */
	/*@{*/

	/**
	 * @brief Count characters in a page.
	 *
	 * @return The total number of characters in a page.
	 */
	virtual int CountChars() = 0;

	/**
	 * @brief Get text caret index at specificed point.
	 *
	 * @param[in] point				The point in user space.
	 * @param[in] xTorelance		X-direction torelance.
	 * @param[in] yTorelance		Y-direction torelance.
	 *
	 * @return The zero-based caret index. Less than zero means no character at specificed point.
	 */
	virtual int GetCaret(const PDSDK_FloatPoint* point, float xTorelance, float yTorelance) = 0;

	/**
	 * @brief Get text caret position.
	 *
	 * @param[in] caret			The caret index.
	 * @param[out] top			Top point in user space.
	 * @param[out] bottom		Bottom point in user space.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int GetCaretPos(int caret, PDSDK_FloatPoint* top, PDSDK_FloatPoint* bottom) = 0;

	/**
	 * @brief Get next text caret.
	 *
	 * @param[in] caret			The caret index.
	 * @param[in] direct		The direction for next caret. @see Caret direction flags
	 *
	 * @return The next caret index, less 0 means no caret.
	 */
	virtual int GetNextCaret(int caret, int direct) = 0;

	/**
	 * @brief Get selected text.
	 *
	 * @param[in] caret_start		The start caret of selected chars.
	 * @param[out] caret_end		The end caret of selected chars.
	 *
	 * @return The selected char's unicodes.
	 */
	virtual const wchar_t* GetSelectedChars(int caret_start, int caret_end) = 0;

	/**
	 * @brief UTF8 version for getting selected text.
	 *
	 * @param[in] caret_start		The start caret of selected chars.
	 * @param[in] caret_end		The end caret of selected chars.
	 *
	 * @return The selected char's utf8.
	 */
	virtual const char* GetSelCharUTF8(int caret_start, int caret_end) = 0;

	/**
	 * @brief Count the selected text's rectangle.
	 *
	 * @param[in] caret_start		The start caret of selected chars.
	 * @param[in] caret_end		The end caret of selected chars.
	 *
	 * @return The number of rectangles whitch used to hilight.
	 */
	virtual int CountSelectedCharBox(int caret_start, int caret_end) = 0;

	/**
	 * @brief Get selected text's rectangle.
	 *
	 * @param[in] index		The zero-based rectangle index, range is 0 to CountSelectedCharBox()-1.
	 * @param[in] rect		The rectangle of specificed caret.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int GetSelectedCharBox(int index, PDSDK_FloatRect* rect) = 0;

	/**
	 * @brief Get text in specificed rectangle.
	 *
	 * @param[in] rect		The rectangle.
	 *
	 * @return The selected unicodes.
	 */
	virtual const wchar_t* GetTextByRect(const PDSDK_FloatRect* rect) = 0;

	/**
	 * @brief Get text in specificed rectangle.
	 *
	 * @param[in] rect		The rectangle.
	 *
	 * @return The selected utf8s.
	 */
	virtual const char* GetTextByRectUTF8(const PDSDK_FloatRect* rect) = 0;

	/** Not support now. */
	virtual int GetWordBreak(int caret, int direction) const = 0;

	/*@}*/

	/**
	 * @name Find text methods.
	 */
	/*@{*/

	/**
	 * @brief Find the first match with specified find flags, optionally with a start position..
	 *
	 * @param[in] find_what		The word to be matched.
	 * @param[in] find_flag		The find flags. @see Find flags.
	 * @param[in] start_pos		The find start position, an zero-based position.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int FindFirst(const wchar_t* find_what, int find_flag, int start_pos = 0) = 0;

	/**
	 * @brief Find the next match. 
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int FindNext() = 0;

	/**
	 * @brief Find the previous match.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int FindPrev() = 0;

	/** Get the current order. */
	virtual int GetCurFindOrder() = 0;

	/** Get the count of current matches. */
	virtual int GetMatchedCount() = 0;

	/** Get the count of rectangle of current matches. */
	virtual int GetMatchedTextRectCount() = 0;

	/**
	 * @brief Get matched text's rectangle by specified index.
	 *
	 * @param[in] index		The zero-based rectangle index. Range is from 0 to GetMatchedTextRectCount().
	 * @param[out] rect		Receiv the rectangle.
	 *
	 */
	virtual void GetMatchedTextRect(int index, PDSDK_FloatRect* rect) = 0;

	/**
	 * @brief Get text line which contain the match.
	 *
	 * @param[in] start		The first char order of match.
	 * @param[in] count		The count of match.
	 * @return The text line of specified match.
	 */
	virtual const char* GetTextAbstract(int start, int count) = 0;

	/**
	 * @brief Get text line which contain the match(Unicode version).
	 *
	 * @param[in] start		The first char order of match.
	 * @param[in] count		The count of match.
	 * @return The text line of specified match.
	 */
	virtual const wchar_t* GetTextAbstract_Unicode(int start, int count) = 0;

	/*@}*/

	/**
	 * @brief Get the word which contain the specified text caret.
	 *
	 * @param[in] caret		The text caret index.
	 * @param[out] iStart	The start caret of word.
	 * @param[out] iEnd		The end caret of word.
	 * @return The word's unicodes.
	 */
	virtual const wchar_t* GetWordAt(int caret, int& iStart, int& iEnd) = 0;
;
};