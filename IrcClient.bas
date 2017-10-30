#include once "IrcClient.bi"

Common Shared GlobalObjectsCount As Long

Function ConstructorIrcClient()As IrcClient Ptr
	Dim pIrcClient As IrcClient Ptr = CPtr(IrcClient Ptr, Allocate(SizeOf(IrcClient)))
	If pIrcClient = 0 Then
		Return 0
	End If
	
	pIrcClient->VirtualTable = CPtr(IIrcClientVirtualTable Ptr, Allocate(SizeOf(IIrcClientVirtualTable)))
	If pIrcClient->VirtualTable = 0 Then
		DeAllocate(pIrcClient)
		Return 0
	End If
	
	pIrcClient->ReferenceCounter = 0
	pIrcClient->VirtualTable->VirtualTable.QueryInterface = @IrcClientQueryInterface
	pIrcClient->VirtualTable->VirtualTable.AddRef = @IrcClientAddRef
	pIrcClient->VirtualTable->VirtualTable.Release = @IrcClientRelease
	pIrcClient->VirtualTable->ShowMessageBox = @IrcClientShowMessageBox
	
	Return pIrcClient
End Function

Sub DestructorIrcClient(ByVal pIrcClient As IrcClient Ptr)
	DeAllocate(pIrcClient->VirtualTable)
	DeAllocate(pIrcClient)
End Sub

Function IrcClientQueryInterface(ByVal This As IrcClient Ptr, ByVal riid As REFIID, ByVal ppv As Any Ptr Ptr)As HRESULT
	
	*ppv = 0
	
	If IsEqualIID(@IID_IUnknown, riid) Then
		*ppv = CPtr(IUnknown Ptr, This)
	End If
	
	If IsEqualIID(@IID_IIrcClient, riid) Then
		*ppv = CPtr(IIrcClient Ptr, This)
	End If
	
	If *ppv <> 0 Then
		This->VirtualTable->VirtualTable.AddRef(CPtr(IUnknown Ptr, This))
		Return S_OK
	End If
	
	Return E_NOINTERFACE
	
End Function

Function IrcClientAddRef(ByVal This As IrcClient Ptr)As ULONG
	InterlockedIncrement(@GlobalObjectsCount)
	Return InterlockedIncrement(@This->ReferenceCounter)
End Function

Function IrcClientRelease(ByVal This As IrcClient Ptr)As ULONG
	InterlockedDecrement(@This->ReferenceCounter)
	
	If This->ReferenceCounter = 0 Then
		DestructorIrcClient(This)
		InterlockedDecrement(@GlobalObjectsCount)
		
		Return 0
	End If
	
	Return This->ReferenceCounter
End Function

Function IrcClientShowMessageBox(ByVal This As IrcClient Ptr, ByVal pResult As Long Ptr)As HRESULT
	*pResult = 0
	MessageBox(0, "Это тестовое сообщение", "IRCClient COM Library", MB_OK)
	Return S_OK
End Function
