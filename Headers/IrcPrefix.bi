#ifndef BATCHEDFILES_IRCCLIENT_IRCPREFIX_BI
#define BATCHEDFILES_IRCCLIENT_IRCPREFIX_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"

Type _IrcPrefix
	Dim Nick As LPWSTR
	Dim User As LPWSTR
	Dim Host As LPWSTR
End Type

Type IrcPrefix As _IrcPrefix

Type LPIRCPREFIX As _IrcPrefix Ptr

#endif
