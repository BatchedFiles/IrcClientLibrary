#include once "IIrcClient.bi"

Type IrcClient
	Dim VirtualTable As IIrcClientVirtualTable Ptr
	
	Dim ReferenceCounter As DWORD
	
End Type

Declare Function ConstructorIrcClient()As IrcClient Ptr

Declare Sub DestructorIrcClient(ByVal pIrcClient As IrcClient Ptr)

Declare Function IrcClientQueryInterface(ByVal This As IrcClient Ptr, ByVal riid As REFIID, ByVal ppv As Any Ptr Ptr)As HRESULT

Declare Function IrcClientAddRef(ByVal This As IrcClient Ptr)As ULONG

Declare Function IrcClientRelease(ByVal This As IrcClient Ptr)As ULONG

Declare Function IrcClientShowMessageBox(ByVal This As IrcClient Ptr, ByVal pResult As Long Ptr)As HRESULT
