Dim Shared lpfnConnectEx As LPFN_CONNECTEX

#ifndef DEFINE_GUID
#define DEFINE_GUID(n, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8) Extern n Alias #n As GUID : _
	Dim n As GUID = Type(l, w1, w2, {b1, b2, b3, b4, b5, b6, b7, b8})
#endif

DEFINE_GUID(GUID_WSAID_CONNECTEX, _
	&h25a207b9, &hddf3, &h4660, &h8e, &he9, &h76, &he5, &h8c, &h74, &h06, &h3e _
)

Type SocketNode
	ClientSocket As SOCKET
	Padding1 As Integer
	AddressFamily As Long
	SocketType As Long
	Protocol As Long
	Padding2 As Long
End Type

Type ClientRecvCallback
	RecvCallback As OnReceiveData
	lpParameter As Any Ptr
	ClientBuffer As UByte Ptr
	BufferLength As DWORD
	dwError As DWORD
End Type

Type ClientConnectCallback
	ConnectCallback As OnConnect
	lpParameter As Any Ptr
End Type

Type _Win95AsyncResult
	Overlap As WSAOVERLAPPED
	lpContext As Any Ptr
	pCB As OnWriteData
End Type

Type _Win95Socket
	ClientSocket As SOCKET
	hWin As HWND
	ClientRecvContext As ClientRecvCallback
	ClientConnectContext As ClientConnectCallback
End Type

Type TextBuffer
	Chars(0 To (MAX_PATH - 1) + 1) As TCHAR
End Type

Type TextBufferA
	Chars(0 To (MAX_PATH - 1) + 1) As CHAR
End Type

Type TextBufferW
	Chars(0 To (MAX_PATH - 1) + 1) As WCHAR
End Type

Private Function OverlappedSocketStartup( _
	)As HRESULT

	Scope
		Dim wsa As WSAData = Any
		Dim dwError As Long = WSAStartup(MAKEWORD(2, 2), @wsa)
		If dwError <> NO_ERROR Then
			Return HRESULT_FROM_WIN32(dwError)
		End If
	End Scope

	Scope
		Dim ListenSocket As SOCKET = WSASocketW( _
			AF_INET, _
			SOCK_STREAM, _
			IPPROTO_TCP, _
			NULL, _
			0, _
			WSA_FLAG_OVERLAPPED _
		)
		If ListenSocket = INVALID_SOCKET Then
			Dim dwError As Long = WSAGetLastError()
			Return HRESULT_FROM_WIN32(dwError)
		End If

		Dim dwBytes As DWORD = Any
		Dim resLoadConnectEx As Long = WSAIoctl( _
			ListenSocket, _
			SIO_GET_EXTENSION_FUNCTION_POINTER, _
			@GUID_WSAID_CONNECTEX, _
			SizeOf(GUID), _
			@lpfnConnectEx, _
			SizeOf(lpfnConnectEx), _
			@dwBytes, _
			NULL, _
			NULL _
		)
		If resLoadConnectEx = SOCKET_ERROR Then
			Dim dwError As Long = WSAGetLastError()
			closesocket(ListenSocket)
			Return HRESULT_FROM_WIN32(dwError)
		End If

		closesocket(ListenSocket)

	End Scope

	Return S_OK

End Function

Private Sub SendCompletionRoutine( _
		ByVal dwError As DWORD, _
		ByVal cbTransferred As DWORD, _
		ByVal lpOverlapped As LPWSAOVERLAPPED, _
		ByVal dwFlags As DWORD _
	)

	Dim pState As Win95AsyncResult Ptr = CPtr(Win95AsyncResult Ptr, lpOverlapped)

	pState->pCB( _
		pState->lpContext, _
		cbTransferred, _
		dwError _
	)

	Deallocate(pState)

End Sub

Private Function OverlappedSocketBeginWrite( _
		ByVal pSock As Win95Socket Ptr, _
		ByVal lpContext As Any Ptr, _
		ByVal Buffer As Any Ptr, _
		ByVal Count As DWORD, _
		ByVal pCB As OnWriteData, _
		ByVal ppState As Win95AsyncResult Ptr Ptr _
	)As HRESULT

	Dim OverlappedCallback As LPWSAOVERLAPPED_COMPLETION_ROUTINE = Any
	Dim pState As Win95AsyncResult Ptr = Any
	If CInt(pCB) Then
		OverlappedCallback = @SendCompletionRoutine
		pState = NULL
	Else
		OverlappedCallback = NULL
		pState = Allocate(SizeOf(Win95AsyncResult))
		If pState = NULL Then
			*ppState = NULL
			Return E_OUTOFMEMORY
		End If
	End If

	ZeroMemory(@pState->Overlap, SizeOf(WSAOVERLAPPED))
	pState->lpContext = lpContext
	pState->pCB = pCB

	Dim SendBuf As WSABUF = Any
	SendBuf.len = Count
	SendBuf.buf = Buffer

	Const dwSendFlags = 0
	Dim res As Long = WSASend( _
		pSock->ClientSocket, _
		@SendBuf, _
		1, _
		NULL, _
		dwSendFlags, _
		@pState->Overlap, _
		OverlappedCallback _
	)

	If res Then
		Dim dwError As Long = WSAGetLastError()

		If dwError = WSA_IO_PENDING Then
			*ppState = pState
			Return S_OK
		End If

		Deallocate(pState)
		*ppState = NULL

		Return HRESULT_FROM_WIN32(dwError)
	End If

	*ppState = pState

	Return S_OK

End Function

Private Function OverlappedSocketResolveHost( _
		ByVal Host As PCTSTR, _
		ByVal Port As PCTSTR, _
		ByVal ppAddressList As ADDRINFOT Ptr Ptr _
	)As HRESULT

	*ppAddressList = NULL

	Dim resAddrInfo As INT_ = GetAddrInfo( _
		Host, _
		Port, _
		NULL, _
		ppAddressList _
	)
	If resAddrInfo Then
		Return HRESULT_FROM_WIN32(resAddrInfo)
	End If

	Return S_OK

End Function

Private Function OverlappedSocketCreateSocketsAndBind( _
		ByVal LocalAddress As PCTSTR, _
		ByVal LocalPort As PCTSTR, _
		ByVal pSocketList As SocketNode Ptr, _
		ByVal Count As Integer, _
		ByVal pSockets As Integer Ptr _
	)As HRESULT

	Dim pAddressList As ADDRINFOT Ptr = NULL
	Dim hr As HRESULT = OverlappedSocketResolveHost( _
		LocalAddress, _
		LocalPort, _
		@pAddressList _
	)
	If FAILED(hr) Then
		*pSockets = 0
		Return hr
	End If

	Dim pAddressNode As ADDRINFOT Ptr = pAddressList
	Dim BindResult As Long = 0
	Dim SocketCount As Integer = 0

	Dim dwError As Long = 0
	Do
		If SocketCount > Count Then
			dwError = ERROR_INSUFFICIENT_BUFFER
			Exit Do
		End If

		Dim ClientSocket As SOCKET = socket_( _
			pAddressNode->ai_family, _
			pAddressNode->ai_socktype, _
			pAddressNode->ai_protocol _
		)
		If ClientSocket = INVALID_SOCKET Then
			dwError = WSAGetLastError()
			pAddressNode = pAddressNode->ai_next
			Continue Do
		End If

		BindResult = bind( _
			ClientSocket, _
			Cast(LPSOCKADDR, pAddressNode->ai_addr), _
			pAddressNode->ai_addrlen _
		)
		If BindResult Then
			dwError = WSAGetLastError()
			closesocket(ClientSocket)
			pAddressNode = pAddressNode->ai_next
			Continue Do
		End If

		pSocketList[SocketCount].ClientSocket = ClientSocket
		pSocketList[SocketCount].AddressFamily = pAddressNode->ai_family
		pSocketList[SocketCount].SocketType = pAddressNode->ai_socktype
		pSocketList[SocketCount].Protocol = pAddressNode->ai_protocol

		SocketCount += 1
		pAddressNode = pAddressNode->ai_next

	Loop While pAddressNode

	FreeAddrInfo(pAddressList)

	If BindResult Then
		For i As Integer = 0 To SocketCount - 1
			closesocket(pSocketList[i].ClientSocket)
		Next
		*pSockets = 0
		Return HRESULT_FROM_WIN32(dwError)
	End If

	*pSockets = SocketCount

	Return S_OK

End Function

Private Function OverlappedSocketBeginConnect( _
		ByVal pSock As Win95Socket Ptr, _
		ByVal lpContext As Any Ptr, _
		ByVal LocalAddress As LPCTSTR, _
		ByVal LocalPort As LPCTSTR, _
		ByVal RemoteAddress As LPCTSTR, _
		ByVal RemotePort As LPCTSTR, _
		ByVal pCB As OnConnect, _
		ByVal ppState As Win95AsyncResult Ptr Ptr _
	)As HRESULT

	' Dim tLocalServer As WString Ptr = Any
	' If LocalServer = NULL Then
	' 	tLocalServer = @WStr("")
	' Else
	' 	tLocalServer = LocalServer
	' End If

	' Dim tLocalPort As WString Ptr = Any
	' If LocalPort = NULL Then
	' 	tLocalPort = @WStr("")
	' Else
	' 	tLocalPort = LocalPort
	' End If

	Dim Count As Integer = SocketListCapacity

	Dim pSocketList As SocketNode Ptr = Allocate(Count * SizeOf(SocketNode))
	If pSocketList = 0 Then
		pSock->ClientSocket = INVALID_SOCKET
		Return E_OUTOFMEMORY
	End If

	Dim SocketLength As Integer = Any
	Dim hrBind As HRESULT = OverlappedSocketCreateSocketsAndBind( _
		LocalAddress, _
		LocalPort, _
		pSocketList, _
		Count, _
		@SocketLength _
	)
	If FAILED(hrBind) Then
		Deallocate(pSocketList)
		pSock->ClientSocket = INVALID_SOCKET
		Return hrBind
	End If

	Dim pAddressList As ADDRINFOT Ptr = NULL
	Dim hrResolve As HRESULT = OverlappedSocketResolveHost( _
		RemoteAddress, _
		RemotePort, _
		@pAddressList _
	)
	If FAILED(hrResolve) Then
		For i As Integer = 0 To SocketLength - 1
			closesocket(pSocketList[i].ClientSocket)
		Next
		Deallocate(pSocketList)
		pSock->ClientSocket = INVALID_SOCKET
		Return hrResolve
	End If

	Dim ConnectResult As Long = SOCKET_ERROR
	Dim dwError As Long = 0

	For i As Integer = 0 To SocketLength - 1
		Dim pAddress As ADDRINFOT Ptr = pAddressList

		Do
			ConnectResult = connect( _
				pSocketList[i].ClientSocket, _
				Cast(LPSOCKADDR, pAddress->ai_addr), _
				pAddress->ai_addrlen _
			)
			dwError = WSAGetLastError()

			If ConnectResult = 0 Then
				pSock->ClientSocket = pSocketList[i].ClientSocket
				Exit For
			End If

			pAddress = pAddress->ai_next

		Loop Until pAddress = 0
	Next

	FreeAddrInfo(pAddressList)

	If ConnectResult <> 0 Then
		For i As Integer = 0 To SocketLength - 1
			closesocket(pSocketList[i].ClientSocket)
		Next
		Deallocate(pSocketList)
		pSock->ClientSocket = INVALID_SOCKET
		Return HRESULT_FROM_WIN32(dwError)
	End If

	For i As Integer = 0 To SocketLength - 1
		If pSocketList[i].ClientSocket <> pSock->ClientSocket Then
			closesocket(pSocketList[i].ClientSocket)
		End If
	Next

	Deallocate(pSocketList)

	Return S_OK

End Function
