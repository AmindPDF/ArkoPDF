#pragma once

//#ifdef AMD_BUILD_CN
class IPDF_Page;
struct PDSDK_FloatRect;
class IPDF_FapiaoRecgnizer
{
public:
	virtual void Release() = 0;
	virtual void StartPage(IPDF_Page* pPDPage) = 0;
	virtual void EndPage() = 0;
	virtual const wchar_t* GetID() = 0;
	virtual const wchar_t* GetCode() = 0;
	virtual const wchar_t* GetDate() = 0;
	virtual const wchar_t* GetPurchaser() = 0;
	virtual const wchar_t* GetPurchaserID() = 0;
	virtual const wchar_t* GetSeller() = 0;
	virtual const wchar_t* GetSellerID() = 0;
	virtual int CountRecorders() = 0;
	virtual const wchar_t* GetEntryName(int iRecorder) = 0;
	virtual const wchar_t* GetMode(int iRecorder) = 0;
	virtual const wchar_t* GetUnit(int iRecorder) = 0;
	virtual int GetQuantity(int iRecorder) = 0;
	virtual float GetUnitPrice(int iRecorder) = 0;
	virtual float GetAmount(int iRecorder) = 0;
	virtual float GetTaxRate(int iRecorder) = 0;
	virtual float GetTaxAmount(int iRecorder) = 0;
	virtual float GetTotalAmount() = 0;
	virtual float GetTotalTextAmount() = 0;
	virtual const wchar_t* GetTotalString() = 0;
	virtual float GetTotal() = 0;

	virtual int CountTable() = 0;
	virtual void GetTableBox(int iTable, PDSDK_FloatRect* box) = 0;
	virtual int CountRows(int iTable) = 0;
	virtual void GetRowBox(int iTable, int row, PDSDK_FloatRect* box) = 0;
	virtual int GetCellCount(int iTable, int row) = 0;
	virtual void GetCellBox(int iTable, int row, int col, PDSDK_FloatRect* box) = 0;
};


//#endif // AMD_BUILD_CN
