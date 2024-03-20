#include once "IrcClient.bi"
#include once "IrcReplies.bi"
#include once "win\commctrl.bi"
#include once "win\windowsx.bi"

Const IDC_SEND = 1001
Const IDC_RECEIVE = 1002
Const IDC_START = 1003

Dim Shared hWndSend As HWND
Dim Shared hWndReceive As HWND
Dim Shared hWndStart As HWND

Dim Shared Ev As IrcEvents
Dim Shared pClient As IrcClient Ptr

Dim Shared Server As BSTR
Dim Shared Nick As BSTR
Dim Shared Channel As BSTR

Private Sub AppendLengthTextW( _
		ByVal hwndControl As HWND, _
		ByVal lpwszText As LPWSTR, _
		ByVal Length As Integer _
	)
	
	Dim OldTextLength As Long = GetWindowTextLengthW(hwndControl)
	Dim NewTextLength As Long = OldTextLength + Length
	
	Dim lpBuffer As WCHAR Ptr = Allocate((NewTextLength + 1) * SizeOf(WCHAR))
	
	If lpBuffer Then
		GetWindowTextW(hwndControl, lpBuffer, NewTextLength)
		lstrcatW(lpBuffer, lpwszText)
		SetWindowTextW(hwndControl, lpBuffer)
		
		Dim NewTextLength2 As Long = GetWindowTextLengthW(hwndControl)
		Edit_SetSel(hwndControl, NewTextLength2, NewTextLength2)
		
		Edit_ScrollCaret(hwndControl)
		
		DeAllocate(lpBuffer)
	End If
	
End Sub

Private Sub OnNumericMessage( _
		ByVal pClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As IrcPrefix Ptr, _
		ByVal IrcNumericCommand As Integer, _
		ByVal MessageText As BSTR _
	)
	
	Dim pClient As IrcClient Ptr = pClientData
	
	If IrcNumericCommand = IRCPROTOCOL_RPL_WELCOME Then
		IrcClientJoinChannel(pClient, Channel)
	End If
	
End Sub

Private Sub OnIrcPrivateMessage( _
		ByVal pClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As IrcPrefix Ptr, _
		ByVal MessageText As BSTR _
	)
	
	Dim pClient As IrcClient Ptr = pClientData
	
	Dim Message As BSTR = SysAllocString(WStr("Yes, me too"))
	IrcClientSendPrivateMessage(pClient, pIrcPrefix->Nick, Message)
	SysFreeString(Message)
	
End Sub

Private Sub OnRawMessage( _
		ByVal lpParameter As LPCLIENTDATA, _
		ByVal pBytes As Const UByte Ptr, _
		ByVal Count As Integer _
	)
	
	Const NewLine = !"\r\n"
	
	Dim buf As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	Dim Length As Long = MultiByteToWideChar( _
		CP_UTF8, _
		0, _
		pBytes, _
		Count, _
		@buf, _
		IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM _
	)
	buf[Length] = 0
	
	lstrcatW(@buf, @WStr(NewLine))	
	
	AppendLengthTextW(hWndReceive, @buf, Length + Len(NewLine))
	
End Sub

Private Sub ClientLoop()
	Do
		Dim hrLoop As HRESULT = IrcClientMsgMainLoop(pClient)
		
		If FAILED(hrLoop) Then
			IrcClientCloseConnection(pClient)
			Return
		Else
			If hrLoop = S_OK Then
				Dim m As MSG = Any
				Do While PeekMessage(@m, NULL, 0, 0, PM_REMOVE) <> 0
					If m.message = WM_QUIT Then
						IrcClientQuitFromServerSimple(pClient)
						Return
					Else
						TranslateMessage(@m)
						DispatchMessage(@m)
					End If
				Loop
			Else
				Return
			End If
		End If
	Loop
End Sub

Private Function MainFormWndProc(ByVal hWin As HWND, ByVal wMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As LRESULT
	
	Select Case wMsg
		
		Case WM_CREATE
			hWndStart = CreateWindowEx(0, _
				@"BUTTON", _
				"Start", _
				WS_CHILD Or WS_VISIBLE Or BS_PUSHBUTTON Or WS_CLIPSIBLINGS, _
				10, 10, 120, 36, _
				hWin, _
				Cast(HMENU, IDC_START), _
				GetModuleHandle(0), _
				NULL _
			)
			hWndReceive = CreateWindowEx(0, _
				@"EDIT", _
				NULL, _
				WS_CHILD Or WS_VISIBLE Or WS_BORDER Or WS_VSCROLL Or WS_HSCROLL Or ES_AUTOHSCROLL Or ES_AUTOVSCROLL Or ES_MULTILINE, _
				10, 56, 640, 480, _
				hWin, _
				Cast(HMENU, IDC_RECEIVE), _
				GetModuleHandle(0), _
				NULL _
			)
			
			' Server = SysAllocString(WStr("irc.pouque.net"))
			Server = SysAllocString(WStr("irc.quakenet.org"))
			Nick = SysAllocString(WStr("LeoFitz"))
			Channel = SysAllocString(WStr("#chlor"))
			
			Ev.lpfnPrivateMessageEvent = @OnIrcPrivateMessage
			Ev.lpfnNumericMessageEvent = @OnNumericMessage
			Ev.lpfnReceivedRawMessageEvent = @OnRawMessage
			Ev.lpfnSendedRawMessageEvent = @OnRawMessage
			
			pClient = CreateIrcClient()
			IrcClientSetCallback(pClient, @Ev, pClient)
			
			Dim ClientVersion As BSTR = SysAllocString("IrcBot 1.0; FreeBASIC 1.10.1")
			IrcClientSetClientVersion(pClient, ClientVersion)
			SysFreeString(ClientVersion)
			
			Dim UserInfo As BSTR = SysAllocString(WStr("Leopold Fitz"))
			IrcClientSetUserInfo(pClient, UserInfo)
			SysFreeString(UserInfo)
			
		Case WM_COMMAND
			
			Select Case HiWord(wParam)
				
				Case 0 ' Меню или кнопка
					
					Select Case LoWord(wParam)
						
						Case IDC_START
							EnableWindow(hWndStart, 0)
							
							IrcClientOpenConnectionSimple1(pClient, Server, Nick)
							
							ClientLoop()
							
							IrcClientCloseConnection(pClient)
							DestroyIrcClient(pClient)
							
							PostQuitMessage(0)
							
					End Select
					
			End Select
			
		Case WM_DESTROY
			PostQuitMessage(0)
			
		Case Else
			Return DefWindowProc(hWin, wMsg, wParam, lParam)
			
	End Select
	
	Return 0
	
End Function

Private Function tWinMain( _
		Byval hInst As HINSTANCE, _
		ByVal hPrevInstance As HINSTANCE, _
		ByVal lpCmdLine As LPTSTR, _
		ByVal iCmdShow As Long _
	)As Integer
	
	Const NineWindowTitle = "IrcClient"
	Const MainWindowClassName = "IrcClient"
	
	Dim wcls As WNDCLASSEX = Any
	With wcls
		.cbSize        = SizeOf(WNDCLASSEX)
		.style         = CS_HREDRAW Or CS_VREDRAW
		.lpfnWndProc   = @MainFormWndProc
		.cbClsExtra    = 0
		.cbWndExtra    = 0
		.hInstance     = hInst
		.hIcon         = NULL
		.hCursor       = LoadCursor(NULL, IDC_ARROW)
		.hbrBackground = Cast(HBRUSH, COLOR_BTNFACE + 1)
		.lpszMenuName  = Cast(TCHAR Ptr, NULL)
		.lpszClassName = @MainWindowClassName
		.hIconSm       = NULL
	End With
	
	If RegisterClassEx(@wcls) = FALSE Then
		Return 1
	End If
	
	Dim hWndMain As HWND = CreateWindowEx(WS_EX_OVERLAPPEDWINDOW, _
		@MainWindowClassName, _
		@NineWindowTitle, _
		WS_OVERLAPPEDWINDOW Or WS_CLIPCHILDREN, _
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, _
		NULL, _
		NULL, _
		hInst, _
		NULL _
	)
	If hWndMain = NULL Then
		Return 1
	End If
	
	ShowWindow(hWndMain, iCmdShow)
	UpdateWindow(hWndMain)
	
	Dim m As MSG = Any
	Dim GetMessageResult As Integer = GetMessage(@m, NULL, 0, 0)
	
	Do While GetMessageResult <> 0
		
		If GetMessageResult = -1 Then
			Return 1
		Else
			TranslateMessage(@m)
			DispatchMessage(@m)
		End If
		
		GetMessageResult = GetMessage(@m, NULL, 0, 0)
		
	Loop
	
	Return m.WPARAM
	
End Function

Dim WinMainResult As Integer = tWinMain(GetModuleHandle(0), NULL, NULL, SW_SHOW)
End(WinMainResult)
