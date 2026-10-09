#pragma once

#define XML_CHILD_TYPE_INVALID		0
#define XML_CHILD_TYPE_ELEMENT		1
#define XML_CHILD_TYPE_CONTENT		2


/**
 * @brief XML element.
 */
class iAmd_XmlElement
{
public:
	virtual void Release() = 0;
	virtual const char*				GetTagName(int bQualified = 0) =0;
	virtual void					SetTagName(const char* space, const char* tag_name) = 0;
	virtual void					SetTagName(const char* tag_name) = 0;
	virtual int						HasAttr(const char* attr_name) =0;
	virtual const wchar_t*			GetAttrValue(const char* name) =0;
	virtual int						GetAttrInt(const char* name) = 0;
	virtual float					GetAttrFloat(const char* name) = 0;
	virtual int						CountAttrs() = 0;
	virtual const wchar_t*			GetAttrValueByIndex(int index, char out_space[128], char out_name[128]) = 0;
	virtual unsigned int			CountChildren() =0;
	virtual iAmd_XmlElement*		GetElement(unsigned int index) =0;
	virtual void					AddChildElement(iAmd_XmlElement* child_element) = 0;
	virtual void					AddChildContent(const wchar_t* content, int bCData) = 0;
	virtual void					SetAttrValueUnicode(const char* name, const wchar_t* unicode) = 0;
	virtual void					SetAttrValueInt(const char* name, int value) = 0;
	virtual void					SetAttrValueFloat(const char* name, float value) = 0;
	virtual int						OutputStream(unsigned char* pBuf, int nLen) = 0;
	virtual int						GetChildType(int index) = 0;
};