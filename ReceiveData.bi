#ifndef BATCHEDFILES_IRCCLIENT_RECEIVEDATA_BI
#define BATCHEDFILES_IRCCLIENT_RECEIVEDATA_BI

#include "IrcClient.bi"

Declare Function StartRecvOverlapped( _
	ByVal pIrcClient As IrcClient Ptr _
)As Boolean

Declare Sub ReceiveCompletionROUTINE( _
	ByVal dwError As DWORD, _
	ByVal cbTransferred As DWORD, _
	ByVal lpOverlapped As LPWSAOVERLAPPED, _
	ByVal dwFlags As DWORD _
)

#endif
