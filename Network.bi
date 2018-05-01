#ifndef BATCHEDFILES_IRCCLIENT_NETWORK_BI
#define BATCHEDFILES_IRCCLIENT_NETWORK_BI

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "win\winsock2.bi"
#include once "win\ws2tcpip.bi"

Declare Function ConnectToServer( _
	ByVal sServer As WString Ptr, _
	ByVal ServiceName As WString Ptr, _
	ByVal localServer As WString Ptr, _
	ByVal LocalServiceName As WString Ptr _
)As SOCKET

Declare Function CreateSocketAndBind( _
	ByVal sServer As WString Ptr, _
	ByVal ServiceName As WString Ptr _
)As SOCKET

Declare Function CreateSocketAndListen( _
	ByVal localServer As WString Ptr, _
	ByVal ServiceName As WString Ptr _
)As SOCKET

Declare Sub CloseSocketConnection( _
	ByVal mSock As SOCKET _
)

Declare Function ResolveHost( _
	ByVal sServer As WString Ptr, _
	ByVal ServiceName As WString Ptr _
)As addrinfoW Ptr

#endif
