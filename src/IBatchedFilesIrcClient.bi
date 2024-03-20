#ifndef BATCHEDFILES_IRCCLIENT_IBATCHEDFILESIRCCLIENT_BI
#define BATCHEDFILES_IRCCLIENT_IBATCHEDFILESIRCCLIENT_BI

#include once "windows.bi"
#include once "win\ole2.bi"

Extern IID_IBatchedFilesIrcClient Alias "IID_IBatchedFilesIrcClient" As Const IID

Type IBatchedFilesIrcClient As IBatchedFilesIrcClient_

Type IBatchedFilesIrcClientVtbl
	
	QueryInterface As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal riid As const IID const Ptr, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	AddRef As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr _
	)As ULONG
	
	Release As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr _
	)As ULONG
	
	GetTypeInfoCount As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal pctinfo As UINT Ptr _
	)As HRESULT
	
	GetTypeInfo As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal iTInfo As UINT, _
		ByVal lcid As LCID, _
		ByVal ppTInfo As ITypeInfo Ptr Ptr _
	)As HRESULT
	
	GetIDsOfNames As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal riid As Const IID Const Ptr, _
		ByVal rgszNames As LPOLESTR Ptr, _
		ByVal cNames As UINT, _
		ByVal lcid As LCID, _
		ByVal rgDispId As DISPID Ptr _
	)As HRESULT
	
	Invoke As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal dispIdMember As DISPID, _
		ByVal riid As Const IID Const Ptr, _
		ByVal lcid As LCID, _
		ByVal wFlags As WORD, _
		ByVal pDispParams As DISPPARAMS Ptr, _
		ByVal pVarResult As VARIANT Ptr, _
		ByVal pExcepInfo As EXCEPINFO Ptr, _
		ByVal puArgErr As UINT Ptr _
	)As HRESULT
	
	GetClientVersion As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal pClientVersion As BSTR Ptr _
	)As HRESULT
	
	SetClientVersion As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal ClientVersion As BSTR _
	)As HRESULT
	
	GetClientUserInfo As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal pClientUserInfo As BSTR Ptr _
	)As HRESULT
	
	SetClientUserInfo As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal ClientUserInfo As BSTR _
	)As HRESULT
	
	GetCodePage As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal pCodePage As Long Ptr _
	)As HRESULT
	
	SetCodePage As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal CodePage As Long _
	)As HRESULT
	
	OpenConnection As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Server As BSTR, _
		ByVal Port As Integer, _
		ByVal LocalAddress As BSTR, _
		ByVal LocalPort As Integer, _
		ByVal Password As BSTR, _
		ByVal Nick As BSTR, _
		ByVal User As BSTR, _
		ByVal ModeFlags As Long, _
		ByVal RealName As BSTR _
	)As HRESULT
	
	CloseConnection As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr _
	)
	
	MsgStartReceiveDataLoop As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr _
	)As HRESULT
	
	ChangeNick As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	QuitFromServer As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal QuitText As BSTR _
	)As HRESULT
	
	JoinChannel As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	PartChannel As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	RetrieveTopic As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	SetTopic As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal TopicText As BSTR _
	)As HRESULT
	
	SendKick As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal UserName As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	SendInvite As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	SendPrivateMessage As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal MessageTarget As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	SendNotice As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal NoticeTarget As BSTR, _
		ByVal NoticeText As BSTR _
	)As HRESULT
	
	SendWho As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR _
	)As HRESULT
	
	SendWhoIs As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR _
	)As HRESULT
	
	SendAdmin As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	SendInfo As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	SendAway As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	SendIsON As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal NickList As BSTR _
	)As HRESULT
	
	SendPing As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	SendPong As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	SendCtcpPingRequest As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal TimeStamp As BSTR _
	)As HRESULT
	
	SendCtcpTimeRequest As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR _
	)As HRESULT
	
	SendCtcpUserInfoRequest As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR _
	)As HRESULT
	
	SendCtcpVersionRequest As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR _
	)As HRESULT
	
	SendCtcpAction As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	SendCtcpPingResponse As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal TimeStamp As BSTR _
	)As HRESULT
	
	SendCtcpTimeResponse As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal TimeValue As BSTR _
	)As HRESULT
	
	SendCtcpUserInfoResponse As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal UserInfo As BSTR _
	)As HRESULT
	
	SendCtcpVersionResponse As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal Version As BSTR _
	)As HRESULT
	
	SendDccSend As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal FileName As BSTR, _
		ByVal IPAddress As BSTR, _
		ByVal Port As Integer, _
		ByVal FileLength As ULongInt _
	)As HRESULT
	
	SendRawMessage As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal RawText As BSTR _
	)As HRESULT
	
End Type

Type IBatchedFilesIrcClient_
	lpVtbl As IBatchedFilesIrcClientVtbl Ptr
End Type

#define IBatchedFilesIrcClient_QueryInterface(this, riid, ppvObject) (this)->lpVtbl->QueryInterface(this, riid, ppvObject)
#define IBatchedFilesIrcClient_AddRef(this) (this)->lpVtbl->AddRef(this)
#define IBatchedFilesIrcClient_Release(this) (this)->lpVtbl->Release(this)
#define IBatchedFilesIrcClient_GetTypeInfoCount(this, pctinfo) (this)->lpVtbl->GetTypeInfoCount(this, pctinfo)
#define IBatchedFilesIrcClient_GetTypeInfo(this, iTInfo, lcid, ppTInfo) (this)->lpVtbl->GetTypeInfo(this, iTInfo, lcid, ppTInfo)
#define IBatchedFilesIrcClient_GetIDsOfNames(this, riid, rgszNames, cNames, lcid, rgDispId) (this)->lpVtbl->GetIDsOfNames(this, riid, rgszNames, cNames, lcid, rgDispId)
#define IBatchedFilesIrcClient_Invoke(this, dispIdMember, riid, lcid, wFlags, pDispParams, pVarResult, pExcepInfo, puArgErr) (this)->lpVtbl->Invoke(this, dispIdMember, riid, lcid, wFlags, pDispParams, pVarResult, pExcepInfo, puArgErr)

#endif
