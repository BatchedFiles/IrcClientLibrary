#ifndef BATCHEDFILES_IRCCLIENT_SENDDATA_BI
#define BATCHEDFILES_IRCCLIENT_SENDDATA_BI

#include "IrcClient.bi"

Declare Function StartSendOverlapped( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByRef strData As ValueBSTR _
)As HRESULT
	
#endif
