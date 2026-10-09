#pragma once
#include "ipdf_base.h"
class IPDF_Font;
class IPDF_Page;
class IPDF_Font;
class IPDF_Matrix;
class iAmd_XmlElement;

/**
 * @name Alignment of paragraph.
 */
 /*@{*/

/** Align None */
#define PARA_ALIGN_NONE			-1
/** Align left */
#define PARA_ALIGN_LEFT			0
/** Align center */
#define PARA_ALIGN_CENTER		1
/** Align right */
#define PARA_ALIGN_RIGHT		2
/** Align adjust */
#define PARA_ALIGN_ADJUST		3

/*@}*/

/**
 * @name Text script flags.
 */
 /*@{*/

/** Normal text */
#define SCRIPT_NORMAL	0
/** Supper script */
#define SCRIPT_SUPPER	1
/** Sub script */
#define SCRIPT_SUB		2

/*@}*/



class IPDF_Paragraph
{
public:
	/**
	 * @brief Get the bounding box of paragraph.
	 *
	 * @param[out] box		Receiv the bounding box in user space.
	 * 
	 */
	virtual void GetBBox(PDSDK_FloatBox* box) = 0;

	/**
	 * @brief Test whether the paragraph is rotated.
	 *
	 * @return 1 for rotated, 0 for normal.
	 *
	 */
	virtual int IsRotate() = 0;

	/**
	 * @brief Test whether the paragraph is vertical writting mode.
	 *
	 * @return 1 for vertical writting, 0 for normal.
	 *
	 */
	virtual int IsVerticalWrittingMode() = 0;

	/**
	 * @brief Get the text of specified range in paragraph.
	 *
	 * @param[in] start_caret		The start caret.
	 * @param[in] end_caret			The end caret.
	 * 
	 * @return The unicodes in sepcified range.
	 */
	virtual const wchar_t* GetText(int start_caret, int end_caret) = 0;

	/**
	 * @brief Get the text of specified range in paragraph.
	 *
	 * @param[in] start_caret		The start caret.
	 * @param[in] end_caret			The end caret.
	 *
	 * @return The utf8 in sepcified range.
	 */
	virtual const char* GetText_UTF8(int start_caret, int end_caret) = 0;

	/**
	 * @brief Get currernt caret after paragraph modify.
	 * When some text changed, such as rest text color,reset font, insert or delete text,
	 * the current caret should be changed, so must re-load it.
	 *
	 * @return The currrent caret.
	 */
	virtual int GetCurrentCaret() = 0;

	/**
	 * @brief Get currernt selection range after paragraph modify.
	 * When some text changed, such as rest text color,reset font, insert or delete text,
	 * the current caret should be changed, so must re-load it.
	 *
	 * @param[out] start_caret		Receiv the start caret of range.
	 * @param[out] end_caret		Receiv the end caret of range.
	 *
	 *
	 */
	virtual void GetCurCaretRange(int* start_caret, int* end_caret) = 0;

	/**
	 * @brief Get caret by point.
	 *
	 * @param[in] point		The point in user space.
	 *
	 * @return The caret amon the point, less then 0 means no caret catched.
	 */
	virtual int GetCaretAt(const PDSDK_FloatPoint* point) = 0;

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
	 * @brief Count total number of carets in paragraph.
	 *
	 * @return The total number of carets.
	 */
	virtual int CountCarets() = 0;

	/**
	 * @brief Test whether is the first caret of the paragraph.
	 *
	 * @return 1 for first caret, 0 for not.
	 */
	virtual int IsHeaderCaret(int caret) = 0;

	/**
	 * @brief Test whether is the tail caret of the paragraph.
	 *
	 * @return 1 for tail caret, 0 for not.
	 */
	virtual int IsTailCaret(int caret) = 0;

	/**
	 * @brief Test whether is the first caret of a text line.
	 *
	 * @return 1 for first caret of line, 0 for not.
	 */
	virtual int GetLineHeaderCaret(int caret) = 0;

	/**
	 * @brief Test whether is the tail caret of a text line.
	 *
	 * @return 1 for tail caret of line, 0 for not.
	 */
	virtual int GetLineTailCaret(int caret) = 0;

	/**
	 * @brief Count the box number of selected text in paragraph.
	 *
	 * @param[in] caret_start	The start caret of selected text.
	 * @param[in] caret_end		The end caret of selected text.
	 *
	 * @return The number of box for selected text.
	 */
	virtual int CountSelBox(int start_caret, int end_caret) = 0;

	/**
	 * @brief Get the boxies of selected text in paragraph.
	 *
	 * @param[in] index		The zero-based box index, range is 0 to CountSelBox()-1.
	 * @param[in] box		Receive the box data.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int GetSelBox(int index, PDSDK_FloatBox* box) = 0;
	
	
	/**
	 * @brief Insert text at the position specified by caret.
	 *
	 * @param[in] caret						The text caret to insert text.
	 * @param[in] font						Font for text.
	 * @param[in] font_size				Font size.
	 * @param[in] color					Text color.Use COLOR_ARGB_MAKE() to mark ARGB color.
	 * @param[in] text						The text.
	 * @param[in] nBoldItalic				A flag indicate the bold/italic.0 for normal, 1 for bold only, 2 for italic only, 3 for BoldItalic.
	 * @param[in] nUnderlineStrikeout		A flag indicate the underline/strikout, 0 for normal, 1 for underline, 2 for strikeout, 3 for both underline and italic.
	 * @param[in] nScript					Script type.@see Text script flags
	 * @param[in] pUndoItem				The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int InsertText(int caret, IPDF_Font* font, float font_size, unsigned int color, const wchar_t* text,
							int nBoldItalic, int nUnderlineStrikeout, int nScript, IPDF_ParaUndoItem* pUndoItem) = 0;
	
	/**
	 * @brief UTF8 version for InsertText.
	 *
	 * @param[in] caret						The text caret to insert text.
	 * @param[in] font						Font for text.
	 * @param[in] font_size				Font size.
	 * @param[in] color					Text color.Use COLOR_ARGB_MAKE() to mark ARGB color.
	 * @param[in] text						The text.
	 * @param[in] nBoldItalic				A flag indicate the bold/italic.0 for normal, 1 for bold only, 2 for italic only, 3 for BoldItalic.
	 * @param[in] nUnderlineStrikeout		A flag indicate the underline/strikout, 0 for normal, 1 for underline, 2 for strikeout, 3 for both underline and italic.
	 * @param[in] nScript					Script type.@see Text script flags
	 * @param[in] pUndoItem				The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int InsertText(int caret, IPDF_Font* font, float font_size, unsigned int color, const char* text_utf8, 
							int nBoldItalic, int nUnderlineStrikeout, int nScript, IPDF_ParaUndoItem* pUndoItem) = 0;
	
	/**
	 * @brief Delete text in paragraph.
	 *
	 * @param[in] start_caret						The start caret of selected text.
	 * @param[in] end_caret						The end caret of selected text.
	 * @param[in] pUndoItem						The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int DeleteText(int start_caret, int end_caret, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Do backspace event.
	 *
	 * @param[in] caret				The caret.
	 * @param[in] pUndoItem		The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int BackSpaceAt(int caret, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Insert return flag to start a new line.
	 *
	 * @param[in] caret				The caret indicate where the return flag will be inserted.
	 * @param[in] pUndoItem		The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int InsertReturn(int caret, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Set stroke color to selected texts.
	 *
	 * @param[in] start_caret			The start caret of selected text.
	 * @param[in] end_caret				The end caret of selected text.
	 * @param[in] isStroke				A flag to decided whether the selected text to be stroke. 0 for not stroke, 1 for stroke.
	 * @param[in] stroke_color			Stroke color. Use COLOR_ARGB_MAKE() to mark ARGB color.
	 * @param[in] pUndoItem				The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int SetStroke(int start_caret, int end_caret, int isStroke, unsigned int stroke_color, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Set text color (fill color) to selected texts.
	 *
	 * @param[in] start_caret			The start caret of selected text.
	 * @param[in] end_caret				The end caret of selected text.
	 * @param[in] color					Text color.Use COLOR_ARGB_MAKE() to mark ARGB color.
	 * @param[in] pUndoItem				The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int SetTextColor(int start_caret, int end_caret, unsigned int color, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Set font to selected texts.
	 *
	 * @param[in] start_caret			The start caret of selected text.
	 * @param[in] end_caret				The end caret of selected text.
	 * @param[in] font					The pdf font.
	 * @param[in] pUndoItem				The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int SetFont(int start_caret, int end_caret, IPDF_Font* font, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Set font size to selected texts.
	 *
	 * @param[in] start_caret			The start caret of selected text.
	 * @param[in] end_caret				The end caret of selected text.
	 * @param[in] font_size				The font size.
	 * @param[in] pUndoItem				The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int SetFontSize(int start_caret, int end_caret, float font_size, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Set italic style to selected texts.
	 *
	 * @param[in] start_caret			The start caret of selected text.
	 * @param[in] end_caret				The end caret of selected text.
	 * @param[in] pUndoItem				The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int SetItalic(int start_caret, int end_caret, IPDF_ParaUndoItem* pUndoItem) = 0;
	
	/**
	 * @brief Set bold style to selected texts.
	 *
	 * @param[in] start_caret			The start caret of selected text.
	 * @param[in] end_caret				The end caret of selected text.
	 * @param[in] pUndoItem				The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int SetBold(int start_caret, int end_caret, IPDF_ParaUndoItem* pUndoItem) = 0;
	
	/**
	 * @brief Set underline to selected texts.
	 *
	 * @param[in] start_caret			The start caret of selected text.
	 * @param[in] end_caret				The end caret of selected text.
	 * @param[in] pUndoItem				The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int SetUnderline(int start_caret, int end_caret, IPDF_ParaUndoItem* pUndoItem) = 0;
	
	/**
	 * @brief Set strikout line to selected texts.
	 *
	 * @param[in] start_caret			The start caret of selected text.
	 * @param[in] end_caret				The end caret of selected text.
	 * @param[in] pUndoItem				The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int SetStrikeout(int start_caret, int end_caret, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Set script style to selected texts.
	 *
	 * @param[in] start_caret			The start caret of selected text.
	 * @param[in] end_caret				The end caret of selected text.
	 * @param[in] nScript				The script type. @see Text script flags.
	 * @param[in] pUndoItem				The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for sucess, 0 for failure.
	 */
	virtual int SetScript(int start_caret, int end_caret, int nScript, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Test whether the text is bold.
	 *
	 * @param[in] caret			The caret to test.
	 *
	 * @return 1 for bold, 0 for normal.
	 */
	virtual int IsBold(int caret) = 0;

	/**
	 * @brief Test whether the text is italic.
	 *
	 * @param[in] caret			The caret to test.
	 *
	 * @return 1 for italic, 0 for normal.
	 */
	virtual int IsItalic(int caret) = 0;

	/**
	 * @brief Test whether the text is underline style.
	 *
	 * @param[in] caret			The caret to test.
	 *
	 * @return 1 for underline style, 0 for normal.
	 */
	virtual int IsUnderline(int caret) = 0;

	/**
	 * @brief Test whether the text is strikout style.
	 *
	 * @param[in] caret			The caret to test.
	 *
	 * @return 1 for strikout style, 0 for normal.
	 */
	virtual int IsStrikeout(int caret) = 0;

	/**
	 * @brief Test whether the text is supper script style.
	 *
	 * @param[in] caret			The caret to test.
	 *
	 * @return 1 for supper script style, 0 for normal.
	 */
	virtual int IsSupperScript(int caret) = 0;

	/**
	 * @brief Test whether the text is subscript style.
	 *
	 * @param[in] caret			The caret to test.
	 *
	 * @return 1 for subscript style, 0 for normal.
	 */
	virtual int IsSubScript(int caret) = 0;
	
	/**
	 * @brief Get text font at caret.
	 *
	 * @param[in] caret			The caret.
	 *
	 * @return The pdf font.
	 */
	virtual IPDF_Font* GetFont(int caret) = 0;

	/**
	 * @brief Get font size at caret.
	 *
	 * @param[in] caret			The caret.
	 *
	 * @return The font size.
	 */
	virtual float GetFontSize(int caret) = 0;

	/**
	 * @brief Get text color at caret.
	 *
	 * @param[in] caret			The caret.
	 *
	 * @return The text color, ARGB format.
	 */
	virtual unsigned int GetFontColor(int caret) = 0;

	/**
	 * @brief Get char space at caret.
	 *
	 * @param[in] caret			The caret.
	 *
	 * @return The character space.
	 */
	virtual float GetCharSpace(int caret) = 0;

	/**
	 * @brief Get word space at caret.
	 *
	 * @param[in] caret			The caret.
	 *
	 * @return The word space.
	 */
	virtual float GetWordSpace(int caret) = 0;

	/**
	 * @brief Get line space at caret.
	 *
	 * @param[in] caret			The caret.
	 *
	 * @return The line space.
	 */
	virtual float GetLineSpace() = 0;

	/**
	 * @brief Get horizontal scale at caret.
	 *
	 * @param[in] caret			The caret.
	 *
	 * @return The horizontal scale.
	 */
	virtual float GetHorzScale() = 0;

	/**
	 * @brief Set character space to selected texts.
	 *
	 * @param[in] start_caret		The start caret of selected text.
	 * @param[in] end_caret			The end caret of selected text.
	 * @param[in] space				The new character space.
	 * @param[in] pUndoItem			The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 */
	virtual void SetCharSpace(int start_caret, int end_caret, float space, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Set word space to selected texts.
	 *
	 * @param[in] start_caret		The start caret of selected text.
	 * @param[in] end_caret			The end caret of selected text.
	 * @param[in] space				The new word space.
	 * @param[in] pUndoItem			The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 */
	virtual void SetWordSpace(int start_caret, int end_caret, float space, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Set line space to selected texts.
	 *
	 * @param[in] start_caret		The start caret of selected text.
	 * @param[in] end_caret			The end caret of selected text.
	 * @param[in] space				The new line space.
	 * @param[in] pUndoItem			The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 */
	virtual void SetLineSpace(int start_caret, int end_caret, float space, IPDF_ParaUndoItem* pUndoItem) = 0;
	/* Not support now. */
	virtual void SetCharHorzScale(int start_caret, int end_caret, float scale, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Get line alignment at caret.
	 *
	 * @param[in] caret			The caret.
	 *
	 * @return The line alignment. @see Alignment of paragraph.
	 */
	virtual int GetAlign(int caret) = 0;

	/**
	 * @brief Set alignment to selected texts.
	 *
	 * @param[in] start_caret		The start caret of selected text.
	 * @param[in] end_caret			The end caret of selected text.
	 * @param[in] align				The new align. @see Alignment of paragraph.
	 * @param[in] pUndoItem			The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 */
	virtual void SetAlign(int start_caret, int end_caret, int align, IPDF_ParaUndoItem* pUndoItem) = 0;
	
	/**
	 * @brief Move the paragrah.
	 *
	 * @param[in] dx			The x-direction delta.
	 * @param[in] dy			The y-derection delta.
	 * @param[in] pUndoItem		The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 */
	virtual void Offset(float dx, float dy, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Transform the paragrah.
	 *
	 * @param[in] matrix		The transfrom matrix.
	 * @param[in] pUndoItem		The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 */
	virtual void Transform(IPDF_Matrix* matrix, IPDF_ParaUndoItem* pUndoItem) = 0;

	/**
	 * @brief Resize the width of the paragrah.
	 *
	 * @param[in] leftside_or_rightsize			0 for leftside moved, 1 for rightsize moved.
	 * @param[in] dx							The x-derection delta(oldside_x - newsize_x).
	 * @param[in] pUndoItem						The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 */
	virtual void ResizeWidth(int leftside_or_rightsize, float dx, IPDF_ParaUndoItem* pUndoItem) = 0;
	

	/**
	 * @brief Get unicode at caret.
	 *
	 * @return Unicode of char.
	 *
	 */
	virtual unsigned short GetCharUnicode(int caret) = 0;

	/**
	 * @brief Get char set at caret.
	 *
	 * @return Charset of char.@see Font charsets, same as defined in Win32 font charsets
	 *
	 */
	virtual int GetCharsetAt(int caret) = 0;

	/**
	 * @brief Move lines.
	 *
	 * @param[in] start_caret		The start caret of selected text.
	 * @param[in] end_caret			The end caret of selected text.
	 * @param[in] xOffset			The x-direction offset.
	 * @param[in] yOffset			The y-direction offset.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int MoveLines(int start_caret, int end_caret, float xOffset, float yOffset) = 0;

	/** Not support now. */
	virtual iAmd_XmlElement* ToXML(const wchar_t* temp_font_file) = 0;

	/** Generate form. */
	virtual void GenerateForm() = 0;


	/**
	 * @brief Get sentence range.
	 *
	 * @param[in] caret				The caret in a textline.
	 * @param[out] start_caret		Receiv start caret of sentence.
	 * @param[out] end_caret		Receiv end caret of sentence.
	 *
	 */
	virtual void GetSentenceRange(int caret, int& start_caret, int& end_caret) = 0;

	/**
	 * @brief Get inner paragraph range.
	 *
	 * @param[in] caret				The caret in a textline.
	 * @param[out] start_caret		Receiv start caret of inner paragraph.
	 * @param[out] end_caret		Receiv end caret of inner paragraph.
	 *
	 */
	virtual void GetInnerParaRange(int caret, int& start_caret, int& end_caret) = 0;

	/**
	 * @brief Replace text in paragraph.
	 *
	 * @param[in] start_caret		The start caret of inner paragraph.
	 * @param[in] end_caret			The end caret of inner paragraph.
	 * @param[in] new_text			The new text use to replace.
	 * @param[in] pSubstFont		The font used to instea the old font when old font is embbedded.
	 * @param[in] font_size			The font size.-1 for invalide.
	 * @param[in] font_color		The font color.-1 for invalide.
	 * @param[in] font_bold			Bold style.-1 for invalide.1 for bold, 0 for normal.
	 * @param[in] font_italic		Italic style.-1 for invalide. 1 for italic, 0 for normal.
	 * @param[in/out] new_text		A caret anchor, it will be chage after replaced.
	 * @param[in] pUndoItem			The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 */
	virtual int ReplaceTexts(int start_caret, int end_caret,
		const wchar_t* new_text, IPDF_Font* pSubstFont, int& caret_anchor, 
		float font_size, unsigned int font_color, int font_bold, int font_italic, 
		IPDF_ParaUndoItem* pUndoItem) = 0;
	/** Not support now. */
	virtual unsigned long GetZOrder() = 0;

	virtual void SetFiexdWidth(float fixed_width) = 0;

	virtual int CountLines() = 0;
	virtual int CountSubParagraphs() = 0;
	virtual void GetSubPragraphPos(int iSub, PDSDK_FloatBox* box_para, int& start_caret, int& end_caret) = 0;
};

/** Not support now. */
class IPDF_Table
{
public:

	virtual void GetBBox(PDSDK_FloatRect* pBBox) = 0;
	virtual int GetRowCount() = 0;
	virtual int GetRowBBox(int iRow, PDSDK_FloatRect* pBBox) = 0;
	virtual int GetCellCount(int iRow) = 0;
	virtual int GetCellBBox(int iRow, int iCell, PDSDK_FloatRect* pBBox) = 0;
	virtual const wchar_t* GetCellText(int iRow, int iCell) = 0;
	virtual IPDF_Table* GetCellTable(int iRow, int iCell) = 0;
};

/** The text paragraph recognizer interface. */
class IPDF_LogicalStructAnalyser
{
public:
	/** Release the Analyser. */
	virtual void Release() = 0;

	/**
	 * @brief Start to recognize the paragraph for a page.
	 *
	 * @param[in] page		The PDF page to analys.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int DoAnalyse(IPDF_Page* page) = 0;

	/**
	 * @brief Get paragraph count.
	 *
	 * @return The count of paragraphs.
	 */
	virtual int GetParagraphCount() = 0;

	/**
	 * @brief Get paragraph by index.
	 *
	 * @param[in] index		The zero-based paragraph index, range is 0 to GetParagraphCount()-1.
	 *
	 * @return The pdf paragrah at index.
	 */
	virtual IPDF_Paragraph* GetParagraph(int index) = 0;

	/**
	 * @brief Get paragraph at point.
	 *
	 * @param[in] point		 The point in user space.
	 *
	 * @return The pdf paragrah at point.
	 */
	virtual IPDF_Paragraph* GetParagraph(const PDSDK_FloatPoint* point) = 0;

	/**
	 * @brief New paragraph at point.
	 *
	 * @param[in] point		The point in user space.
	 * @param[in] width		The width of new paragraph.
	 * @param[in] height	The height of new paragraph.
	 *
	 * @return The newly paragrah.
	 */
	virtual IPDF_Paragraph* NewParagraphAt(const PDSDK_FloatPoint* point, float width, float height) = 0;

	/**
	 * @brief Delete paragraph from the analyser.
	 *
	 * @param[in] para				The paragraph to be deleted.
	 * @param[in] pUndoItem			The undo item.Call PDSDK_CreateParaUndoItem() to creat the undo item.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int DeleteParagraph(IPDF_Paragraph* para, IPDF_ParaUndoItem* pUndoItem) = 0;
	
	/** Not support now. */
	virtual int GetTableCount() = 0;
	/** Not support now. */
	virtual IPDF_Table* GetTable(int index) = 0;
};

int PDF_CharsetFromUnicode(unsigned short);

/**
 * @name Paragraph undo types.
 */
 /*@{*/
/** Delete paragraph. For IPDF_Paragraph::DeleteParagraph(). */
#define PDSDK_PARA_UNDOTYPE_DELETEPARA			0 
/** Insert text. For IPDF_Paragraph::InsertText(). */
#define PDSDK_PARA_UNDOTYPE_INSERTTEXT			1 
/** Delete text. For IPDF_Paragraph::DeleteText(). */
#define PDSDK_PARA_UNDOTYPE_DELETETEXT			2 
/** Set font. For IPDF_Paragraph::SetFont(). */
#define PDSDK_PARA_UNDOTYPE_FONT				3 
/** Set font size. For IPDF_Paragraph::SetFontSize().*/
#define PDSDK_PARA_UNDOTYPE_FONTSIZE			4 
/** Set text color. For IPDF_Paragraph::SetTextColor(). */
#define PDSDK_PARA_UNDOTYPE_COLOR				5 
/** Set bold. For IPDF_Paragraph::SetBold(). */
#define PDSDK_PARA_UNDOTYPE_BOLD				6 
/** Set italic. For IPDF_Paragraph::SetItalic(). */
#define PDSDK_PARA_UNDOTYPE_ITALIC				7 
/** Set under line. For IPDF_Paragraph::SetUnderline(). */
#define PDSDK_PARA_UNDOTYPE_UNDERLINE			8 
/** Set strikout. For IPDF_Paragraph::SetStrikeout(). */
#define PDSDK_PARA_UNDOTYPE_STRIKEOUT			9 
/** Set supper script. For IPDF_Paragraph::SetScript(). */
#define PDSDK_PARA_UNDOTYPE_SUPPERSCRIPT		10 
/** Set subscript. For IPDF_Paragraph::SetScript(). */
#define PDSDK_PARA_UNDOTYPE_SUBSCRIPT			11 
/** Set no scriopt. For IPDF_Paragraph::SetScript(). */
#define PDSDK_PARA_UNDOTYPE_NOSCRIPT			12 
/** Set char space. For IPDF_Paragraph::SetCharSpace(). */
#define PDSDK_PARA_UNDOTYPE_CHARSPACE			13 
/** Set word space. For IPDF_Paragraph::SetWordSpace(). */
#define PDSDK_PARA_UNDOTYPE_WORDSPACE			14 
/** Set line space. For IPDF_Paragraph::SetLineSpace(). */
#define PDSDK_PARA_UNDOTYPE_LINESPACE			15 
/** Set align. For IPDF_Paragraph::SetAlign(). */
#define PDSDK_PARA_UNDOTYPE_ALIGN				16 
/** Insert return. For IPDF_Paragraph::DeleteText(). */
#define PDSDK_PARA_UNDOTYPE_INSERTRETURN		17 
/** Offset paragraph. For IPDF_Paragraph::OffsetParagraph(). */
#define PDSDK_PARA_UNDOTYPE_OFFSETPARA			18 
/** Repalce text. For IPDF_Paragraph::ReplaceTexts(). */
#define PDSDK_PARA_UNDOTYPE_REPLACETEXT			19

//aLee FixedBug 202509
/** Resize paragraph width. For IPDF_Paragraph::ResizeWidth(). */
#define PDSDK_PARA_UNDOTYPE_RESIZEWIDTH			20 
//end

/*@}*/

/** @brief PDF paragraph undo item interface. */
class IPDF_ParaUndoItem
{
public:
	/** Release undo item. */
	virtual void					Release() = 0;
	/** Undo. */
	virtual void					Undo(IPDF_LogicalStructAnalyser* analyser) = 0;
	/** Redo. */
	virtual void					Redo(IPDF_LogicalStructAnalyser* analyser) = 0;
};