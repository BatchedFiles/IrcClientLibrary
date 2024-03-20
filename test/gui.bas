#include once "IrcClient.bi"
#include once "IrcReplies.bi"

Const IDC_SEND = 1001
Const IDC_RECEIVE = 1002
Const IDC_START = 1003

Dim Shared Ev As IrcEvents
Dim Shared hWndSend As HWND
Dim Shared hWndReceive As HWND
Dim Shared hWndStart As HWND
Dim Shared pClient As IrcClient Ptr
Dim Shared Channel As BSTR
Dim Shared Message As BSTR
Dim Shared Server As BSTR
Dim Shared Nick As BSTR

Sub AppendLengthTextW( _
		ByVal hwndControl As HWND, _
		ByVal lpwszText As LPWSTR, _
		ByVal Length As Integer _
	)
	Dim OldTextLength As Long = GetWindowTextLengthW(hwndControl)
	Dim NewTextLength As Long = OldTextLength + Length
	
	Dim lpBuffer As WString Ptr = Allocate((NewTextLength + 1) * SizeOf(WCHAR))
	If lpBuffer <> NULL Then
		GetWindowTextW(hwndControl, lpBuffer, NewTextLength)
		lstrcatW(lpBuffer, lpwszText)
		SetWindowTextW(hwndControl, lpBuffer)
		DeAllocate(lpBuffer)
	End If
End Sub

Sub AppendTextW( _
		ByVal hwndControl As HWND, _
		ByVal lpwszText As LPWSTR _
	)
	AppendLengthTextW(hwndControl, lpwszText, lstrlenW(lpwszText))
End Sub

Sub OnNumericMessage( _
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

Sub OnIrcPrivateMessage( _
		ByVal pClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As IrcPrefix Ptr, _
		ByVal MessageText As BSTR _
	)
	Dim pClient As IrcClient Ptr = pClientData
	IrcClientSendPrivateMessage(pClient, pIrcPrefix->Nick, Message)
End Sub

Sub OnRawMessage( _
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
	
	AppendLengthTextW(hWndReceive, @buf, Length)
	AppendLengthTextW(hWndReceive, @Wstr(NewLine), Len(NewLine))
End Sub

Function MainFormWndProc(ByVal hWin As HWND, ByVal wMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As LRESULT
	
	Select Case wMsg
		
		Case WM_CREATE
			hWndReceive = CreateWindowEx(0, _
				@"EDIT", _
				NULL, _
				WS_CHILD Or WS_VISIBLE Or WS_BORDER Or WS_VSCROLL Or WS_HSCROLL Or ES_AUTOHSCROLL Or ES_AUTOVSCROLL Or ES_MULTILINE, _
				0, 0, 640, 480, _
				hWin, _
				Cast(HMENU, IDC_RECEIVE), _
				GetModuleHandle(0), _
				NULL _
			)
			hWndStart = CreateWindowEx(0, _
				@"BUTTON", _
				"Start", _
				WS_CHILD Or WS_VISIBLE Or BS_PUSHBUTTON Or WS_CLIPSIBLINGS, _
				10, 490, 120, 36, _
				hWin, _
				Cast(HMENU, IDC_START), _
				GetModuleHandle(0), _
				NULL _
			)
			
			Server = SysAllocString("irc.pouque.net")
			Nick = SysAllocString("LeoFitz")
			Channel = SysAllocString("#chlor")
			Message = SysAllocString("Yes, me too")
			
			Ev.lpfnPrivateMessageEvent = @OnIrcPrivateMessage
			Ev.lpfnNumericMessageEvent = @OnNumericMessage
			Ev.lpfnReceivedRawMessageEvent = @OnRawMessage
			Ev.lpfnSendedRawMessageEvent = @OnRawMessage
			
			pClient = CreateIrcClient()
			IrcClientSetCallback(pClient, @Ev, pClient)
			
		Case WM_COMMAND
			
			Select Case HiWord(wParam)
				
				Case 0 ' Меню или кнопка
					
					Select Case LoWord(wParam)
						
						Case IDC_START
							EnableWindow(hWndStart, 0)
							
							IrcClientOpenConnectionSimple1(pClient, Server, Nick)
							
							Do
								Dim hrLoop As HRESULT = IrcClientMsgMainLoop(pClient)
								
								If FAILED(hrLoop) Then
									Print "IrcClientStartReceiveDataLoop", HEX(hrLoop)
									Print "Закрываю соединение"
									IrcClientCloseConnection(pClient)
									Exit Do
								Else
									If hrLoop = S_OK Then
										Dim m As MSG = Any
										Do While PeekMessage(@m, NULL, 0, 0, PM_REMOVE) <> 0
											If m.message = WM_QUIT Then
												IrcClientQuitFromServerSimple(pClient)
											Else
												TranslateMessage(@m)
												DispatchMessage(@m)
											End If
										Loop
									Else
										Exit Do
									End If
								End If
							Loop
							
							IrcClientQuitFromServerSimple(pClient)
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
