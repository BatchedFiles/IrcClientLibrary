#include once "Win95Socket.bi"
#include once "win\mswsock.bi"
#include once "win\winsock2.bi"
#include once "win\ws2tcpip.bi"

#include once "Win95Hack.bi"

#define WM_SOCKET WM_USER + 1
#define WM_SENDCALLBACK WM_USER + 2
#define WM_READCALLBACK WM_USER + 3

Const SocketListCapacity As Integer = 16

Const Win95WSAVersion = MAKEWORD(1, 1)

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

Private Function StringToInteger( _
		ByVal pBuffer As LPCTSTR _
	)As Integer

	Dim Number As Integer = 0
	Dim i As Integer = Any
	Dim nuSign As UInteger = Any

	If pBuffer[0] = Asc("-") Then
		nuSign = -1
		i = 1
	Else
		nuSign = 0
		i = 0
	End If

	Do While pBuffer[i] >= &h30 AndAlso pBuffer[i] <= &h39
		Dim n As Integer = pBuffer[i]
		Dim Digit As Integer = n And &h0F
		Number = Number + Digit
		Number = Number * 10
		i += 1
	Loop

	Number = Number \ 10

	If nuSign Then
		Return -1 * Number
	End If

	Return Number

End Function

Private Function StringToIntegerW( _
		ByVal pBuffer As LPCWSTR _
	)As Integer

	Dim Number As Integer = 0
	Dim i As Integer = Any
	Dim nuSign As UInteger = Any

	If pBuffer[0] = Asc("-") Then
		nuSign = -1
		i = 1
	Else
		nuSign = 0
		i = 0
	End If

	Do While pBuffer[i] >= &h30 AndAlso pBuffer[i] <= &h39
		Dim n As Integer = pBuffer[i]
		Dim Digit As Integer = n And &h0F
		Number = Number + Digit
		Number = Number * 10
		i += 1
	Loop

	Number = Number \ 10

	If nuSign Then
		Return -1 * Number
	End If

	Return Number

End Function

Private Function Win95SocketStartup( _
	)As HRESULT

	Dim wsa As WSAData = Any
	Dim dwError As Long = WSAStartup(Win95WSAVersion, @wsa)
	If dwError <> NO_ERROR Then
		Return HRESULT_FROM_WIN32(dwError)
	End If

	Return S_OK

End Function

Private Function Win95SocketCleanup( _
	)As HRESULT

	Dim dwError As Long = WSACleanup()
	If dwError <> NO_ERROR Then
		Return HRESULT_FROM_WIN32(dwError)
	End If

	Return S_OK

End Function

Private Sub Win95SocketOnConnect( _
		ByVal pSock As Win95Socket Ptr, _
		ByVal dwError As DWORD _
	)

	pSock->ClientConnectContext.ConnectCallback( _
		pSock->ClientConnectContext.lpParameter, _
		dwError _
	)

End Sub

Private Sub Win95SocketOnSend( _
		ByVal pSock As Win95Socket Ptr, _
		ByVal pState As Win95AsyncResult Ptr, _
		ByVal cbTransferred As DWORD _
	)

	pState->pCB( _
		pState->lpContext, _
		cbTransferred, _
		0 _
	)
	Deallocate(pState)

End Sub

Private Sub Win95SocketOnRecv( _
		ByVal pSock As Win95Socket Ptr, _
		ByVal dwError As DWORD _
	)

	If pSock->ClientRecvContext.ClientBuffer Then
		Dim resRead As Long = recv( _
			pSock->ClientSocket, _
			pSock->ClientRecvContext.ClientBuffer, _
			pSock->ClientRecvContext.BufferLength, _
			0 _
		)

		Dim context As ClientRecvCallback = Any
		CopyMemory( _
			@context, _
			@pSock->ClientRecvContext, _
			SizeOf(ClientRecvCallback) _
		)
		ZeroMemory(@pSock->ClientRecvContext, SizeOf(ClientRecvCallback))

		context.RecvCallback( _
			context.lpParameter, _
			resRead, _
			dwError _
		)
	End If

End Sub

Private Sub Win95SocketOnRead( _
		ByVal pSock As Win95Socket Ptr, _
		ByVal pState As ClientRecvCallback Ptr, _
		ByVal cbTransferred As DWORD _
	)

	pState->RecvCallback( _
		pState->lpParameter, _
		cbTransferred, _
		pState->dwError _
	)
	Deallocate(pState)

End Sub

Private Function Win95SocketHiddenWindowWndProc( _
		ByVal hWin As HWND, _
		ByVal wMsg As UINT, _
		ByVal wParam As WPARAM, _
		ByVal lParam As LPARAM _
	) As LRESULT

	Dim pSock As Win95Socket Ptr = Any

	If wMsg = WM_CREATE Then
		Dim pStruct As CREATESTRUCT Ptr = CPtr(CREATESTRUCT Ptr, lParam)
		pSock = pStruct->lpCreateParams
		SetWindowLongPtr(hWin, GWLP_USERDATA, Cast(LONG_PTR, pSock))
		Return 0
	End If

	pSock = Cast(Any Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))

	Select Case wMsg

		Case WM_SOCKET
			' SOCKET s = (SOCKET)wParam;
			Dim lEvent As Integer = WSAGETSELECTEVENT(lParam)
			Dim dwError As Integer = WSAGETSELECTERROR(lParam)

			If lEvent And FD_READ Then
				Win95SocketOnRecv(pSock, dwError)
			End If

			If lEvent And FD_WRITE Then
				' send data
			End If

			If lEvent And FD_CONNECT Then
				' connect success
				Win95SocketOnConnect(pSock, dwError)
			End If

			If lEvent And FD_CLOSE Then
				' closesocket
			End If

		Case WM_SENDCALLBACK
			Dim pState As Win95AsyncResult Ptr = CPtr(Win95AsyncResult Ptr, lParam)
			Dim cbTransferred As DWORD = wParam
			Win95SocketOnSend(pSock, pState, cbTransferred)

		Case WM_READCALLBACK
			Dim pState As ClientRecvCallback Ptr = CPtr(ClientRecvCallback Ptr, lParam)
			Dim cbTransferred As DWORD = wParam
			Win95SocketOnRead(pSock, pState, cbTransferred)

		Case Else
			Return DefWindowProc(hWin, wMsg, wParam, lParam)

	End Select

	Return 0

End Function

Private Function Win95SocketCreateHiddenWindow( _
		ByVal pSock As Win95Socket Ptr _
	)As HWND

	Const HiddenWindowClassName = __TEXT("HiddenWindow")
	Dim hInst As HINSTANCE = NULL

	Dim wcls As WNDCLASSEX = Any
	With wcls
		.cbSize        = SizeOf(WNDCLASSEX)
		.style         = 0
		.lpfnWndProc   = @Win95SocketHiddenWindowWndProc
		.cbClsExtra    = 0
		.cbWndExtra    = 0
		.hInstance     = hInst
		.hIcon         = NULL
		.hCursor       = NULL
		.hbrBackground = NULL
		.lpszMenuName  = Cast(TCHAR Ptr, NULL)
		.lpszClassName = @HiddenWindowClassName
		.hIconSm       = NULL
	End With

	Dim resRegister As ATOM = RegisterClassEx(@wcls)
	If resRegister = 0 Then
		Return NULL
	End If

	Dim hWin As HWND = CreateWindowEx( _
		0, _
		@HiddenWindowClassName, _
		NULL, _
		0, _
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, _
		HWND_MESSAGE, _
		NULL, _
		hInst, _
		pSock _
	)

	Return hWin

End Function

Public Function CreateWin95Socket( _
	) As Win95Socket Ptr

	Dim hrStartup As HRESULT = Win95SocketStartup()
	If FAILED(hrStartup) Then
		Return NULL
	End If

	Dim pSock As Win95Socket Ptr = Allocate(SizeOf(Win95Socket))

	If pSock Then
		Dim hWin As HWND = Win95SocketCreateHiddenWindow(pSock)

		If hWin Then
			pSock->hWin = hWin
			pSock->ClientSocket = INVALID_SOCKET

			Return pSock
		End If

		Deallocate(pSock)
	End If

	Return NULL

End Function

Public Sub DestroyWin95Socket( _
		ByVal pSock As Win95Socket Ptr _
	)

	Win95SocketCloseConnection(pSock)
	DestroyWindow(pSock->hWin)
	Deallocate(pSock)
	Win95SocketCleanup()

End Sub

Public Function Win95SocketBeginWrite( _
		ByVal pSock As Win95Socket Ptr, _
		ByVal lpContext As Any Ptr, _
		ByVal Buffer As Any Ptr, _
		ByVal Count As DWORD, _
		ByVal pCB As OnWriteData, _
		ByVal ppState As Win95AsyncResult Ptr Ptr _
	)As HRESULT

	Dim cbTransferred As Long = send( _
		pSock->ClientSocket, _
		Buffer, _
		Count, _
		0 _
	)

	If cbTransferred = SOCKET_ERROR Then
		Dim dwError As Long = WSAGetLastError()
		*ppState = NULL
		Return HRESULT_FROM_WIN32(dwError)
	End If

	Scope
		Dim pState As Win95AsyncResult Ptr = Allocate(SizeOf(Win95AsyncResult))
		If pState = NULL Then
			*ppState = NULL
			Return E_OUTOFMEMORY
		End If

		pState->lpContext = lpContext
		pState->pCB = pCB

		*ppState = pState

		PostMessage( _
			pSock->hWin, _
			WM_SENDCALLBACK, _
			cbTransferred, _
			Cast(LPARAM, pState) _
		)
	End Scope

	Return S_OK

End Function

Public Function Win95SocketBeginRead( _
		ByVal pSock As Win95Socket Ptr, _
		ByVal lpContext As Any Ptr, _
		ByVal Buffer As Any Ptr, _
		ByVal Count As DWORD, _
		ByVal pCB As OnReceiveData, _
		ByVal ppState As Win95AsyncResult Ptr Ptr _
	)As HRESULT

	*ppState = NULL

	Dim resRead As Long = recv( _
		pSock->ClientSocket, _
		Buffer, _
		Count, _
		0 _
	)

	If resRead = SOCKET_ERROR Then
		Dim dwError As Long = WSAGetLastError()
		If dwError = WSAEWOULDBLOCK Then
			pSock->ClientRecvContext.RecvCallback = pCB
			pSock->ClientRecvContext.lpParameter = lpContext
			pSock->ClientRecvContext.ClientBuffer = Buffer
			pSock->ClientRecvContext.BufferLength = Count
			pSock->ClientRecvContext.dwError = 0

			Return S_OK
		End If

		ZeroMemory(@pSock->ClientRecvContext, SizeOf(ClientRecvCallback))

		Return HRESULT_FROM_WIN32(dwError)
	End If

	Scope
		Dim pState As ClientRecvCallback Ptr = Allocate(SizeOf(ClientRecvCallback))
		If pState = NULL Then
			Return E_OUTOFMEMORY
		End If

		pState->RecvCallback = pCB
		pState->lpParameter = lpContext
		pState->ClientBuffer = Buffer
		pState->BufferLength = Count
		pState->dwError = 0

		PostMessage( _
			pSock->hWin, _
			WM_READCALLBACK, _
			resRead, _
			Cast(LPARAM, pState) _
		)
	End Scope

	Return S_OK

End Function

Public Function Win95SocketBeginConnect( _
		ByVal pSock As Win95Socket Ptr, _
		ByVal lpContext As Any Ptr, _
		ByVal LocalAddress As LPCWSTR, _
		ByVal LocalPort As LPCWSTR, _
		ByVal RemoteAddress As LPCWSTR, _
		ByVal RemotePort As LPCWSTR, _
		ByVal pCB As OnConnect, _
		ByVal ppState As Win95AsyncResult Ptr Ptr _
	)As HRESULT

	*ppState = NULL
	ZeroMemory(@pSock->ClientRecvContext, SizeOf(ClientRecvCallback))

	Dim LocalSocket As SOCKET = Any
	Scope
		LocalSocket = socket_( _
			AF_INET, _
			SOCK_STREAM, _
			IPPROTO_TCP _
		)
		If LocalSocket = INVALID_SOCKET Then
			Dim dwError As Long = WSAGetLastError()
			Return HRESULT_FROM_WIN32(dwError)
		End If

		Dim dwSelect As Long = WSAAsyncSelect( _
			LocalSocket, _
			pSock->hWin, _
			WM_SOCKET, _
			FD_READ Or FD_WRITE Or FD_CONNECT Or FD_CLOSE _
		)
		If dwSelect Then
			Dim dwError As Long = WSAGetLastError()
			closesocket(LocalSocket)
			Return HRESULT_FROM_WIN32(dwError)
		End If
	End Scope

	If LocalAddress Then
		Dim PortNumber As Integer = StringToIntegerW(LocalPort)
		Dim HostA As TextBufferA = Any
		Dim resWide As Long = WideCharToMultiByte( _
			CP_ACP, _
			0, _
			LocalAddress, _
			-1, _
			@HostA.Chars(0), _
			MAX_PATH, _
			NULL, _
			NULL _
		)

		' Resolve local address
		Dim LocalEndPoint As SOCKADDR_IN = Any
		ZeroMemory(@LocalEndPoint, SizeOf(SOCKADDR_IN))
		LocalEndPoint.sin_family = AF_INET
		LocalEndPoint.sin_port = htons(PortNumber)

		' LocalEndPoint.sin_addr.s_addr = inet_addr("127.0.0.1")
		Dim LocalHostEnt As HOSTENT Ptr = gethostbyname(@HostA.Chars(0))
		If LocalHostEnt = NULL Then
			Dim dwError As Long = WSAGetLastError()
			closesocket(LocalSocket)
			Return HRESULT_FROM_WIN32(dwError)
		End If

		CopyMemory( _
			@LocalEndPoint.sin_addr, _
			LocalHostEnt->h_addr, _
			SizeOf(SOCKADDR_IN) _
		)

		Dim resBind As Long = bind( _
			LocalSocket, _
			CPtr(SOCKADDR Ptr, @LocalEndPoint), _
			SizeOf(SOCKADDR_IN) _
		)
		If resBind Then
			Dim dwError As Long = WSAGetLastError()
			closesocket(LocalSocket)
			Return HRESULT_FROM_WIN32(dwError)
		End If
	End If

	Scope
		Dim PortNumber As Integer = StringToIntegerW(RemotePort)
		Dim HostA As TextBufferA = Any
		Dim resWide As Long = WideCharToMultiByte( _
			CP_ACP, _
			0, _
			RemoteAddress, _
			-1, _
			@HostA.Chars(0), _
			MAX_PATH, _
			NULL, _
			NULL _
		)

		' Resolve Remote Host
		Dim RemoteEndPoint As SOCKADDR_IN = Any
		ZeroMemory(@RemoteEndPoint, SizeOf(SOCKADDR_IN))
		RemoteEndPoint.sin_family = AF_INET
		RemoteEndPoint.sin_port = htons(PortNumber)

		' RemoteEndPoint.sin_addr.s_addr = inet_addr("127.0.0.1")
		Dim RemoteHostEnt As HOSTENT Ptr = gethostbyname(@HostA.Chars(0))
		If RemoteHostEnt = NULL Then
			Dim dwError As Long = WSAGetLastError()
			closesocket(LocalSocket)
			Return HRESULT_FROM_WIN32(dwError)
		End If

		CopyMemory( _
			@RemoteEndPoint.sin_addr, _
			RemoteHostEnt->h_addr, _
			SizeOf(SOCKADDR_IN) _
		)

		Dim resConnect As Long = connect( _
			LocalSocket, _
			CPtr(SOCKADDR Ptr, @RemoteEndPoint), _
			SizeOf(SOCKADDR_IN) _
		)
		If resConnect Then
			Dim dwError As Long = WSAGetLastError()
			If dwError <> WSAEWOULDBLOCK Then
				closesocket(LocalSocket)
				Return HRESULT_FROM_WIN32(dwError)
			End If
		End If
	End Scope

	pSock->ClientConnectContext.ConnectCallback = pCB
	pSock->ClientConnectContext.lpParameter = lpContext
	pSock->ClientSocket = LocalSocket

	Return S_OK

End Function

Public Sub Win95SocketCloseConnection( _
		ByVal pSock As Win95Socket Ptr _
	)

	If pSock->ClientSocket <> INVALID_SOCKET Then
		shutdown(pSock->ClientSocket, SD_BOTH)
		closesocket(pSock->ClientSocket)
		pSock->ClientSocket = INVALID_SOCKET
	End If

End Sub

Public Function Win95SocketMainLoop( _
		ByVal pSock As Win95Socket Ptr _
	)As HRESULT

	Dim m As MSG = Any
	Dim GetMessageResult As Integer = GetMessage(@m, NULL, 0, 0)

	Do While GetMessageResult <> 0

		If GetMessageResult = -1 Then
			Return E_FAIL
		End If

		TranslateMessage(@m)
		DispatchMessage(@m)

		GetMessageResult = GetMessage(@m, NULL, 0, 0)
	Loop

	Return S_OK

End Function
