#ifndef BATCHEDFILES_NETWORKCLIENT_BI
#define BATCHEDFILES_NETWORKCLIENT_BI

#include "Network.bi"

Declare Function ConnectToServerA Alias "ConnectToServerA"( _
	ByVal LocalAddress As PCSTR, _
	ByVal LocalPort As PCSTR, _
	ByVal RemoteAddress As PCSTR, _
	ByVal RemotePort As PCSTR, _
	ByVal pSocket As SOCKET Ptr _
)As HRESULT

Declare Function ConnectToServerW Alias "ConnectToServerW"( _
	ByVal LocalAddress As PCWSTR, _
	ByVal LocalPort As PCWSTR, _
	ByVal RemoteAddress As PCWSTR, _
	ByVal RemotePort As PCWSTR, _
	ByVal pSocket As SOCKET Ptr _
)As HRESULT

#ifdef UNICODE
	Declare Function ConnectToServer Alias "ConnectToServerW"( _
		ByVal LocalAddress As PCWSTR, _
		ByVal LocalPort As PCWSTR, _
		ByVal RemoteAddress As PCWSTR, _
		ByVal RemotePort As PCWSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
#else
	Declare Function ConnectToServer Alias "ConnectToServerA"( _
		ByVal LocalAddress As PCSTR, _
		ByVal LocalPort As PCSTR, _
		ByVal RemoteAddress As PCSTR, _
		ByVal RemotePort As PCSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
#endif

#endif
