#ifndef BATCHEDFILES_IRCCLIENT_IRCPREFIX_BI
#define BATCHEDFILES_IRCCLIENT_IRCPREFIX_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\ole2.bi"

Type _IrcPrefix
	Dim Nick As LPWSTR
	Dim NickLength As Integer
	Dim User As LPWSTR
	Dim UserLength As Integer
	Dim Host As LPWSTR
	Dim HostLength As Integer
End Type

Type IrcPrefix As _IrcPrefix

Type LPIRCPREFIX As _IrcPrefix Ptr

Declare Function GetIrcPrefix( _
	ByVal pIrcPrefix As IrcPrefix Ptr, _
	ByVal bstrIrcMessage As BSTR _
)As Integer

#endif
