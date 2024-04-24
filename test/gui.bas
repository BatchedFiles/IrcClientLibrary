#include once "IrcClient.bi"
#include once "IrcReplies.bi"
#include once "win\commctrl.bi"
#include once "win\shlwapi.bi"
#include once "win\windowsx.bi"

Const IDC_RECEIVE = 1002
Const IDC_START = 1003
Const IDC_STOP = 1004

Type WindowContext
	pClient As IrcClient Ptr
	Server As BSTR
	Port As BSTR
	Nick As BSTR
	Channel As BSTR
	hWndReceive As HWND
	hWndStart As HWND
	hWndStop As HWND
	Ev As IrcEvents
End Type

Private Sub AppendLengthTextW( _
		ByVal hwndControl As HWND, _
		ByVal lpwszText As LPWSTR, _
		ByVal Length As Integer _
	)

	Dim OldTextLength As Long = GetWindowTextLengthW(hwndControl)

	SendMessageW(hwndControl, EM_SETSEL, OldTextLength, OldTextLength)
	SendMessageW(hwndControl, EM_REPLACESEL, FALSE, lpwszText)
	Edit_ScrollCaret(hwndControl)

End Sub

Private Sub OnNumericMessage( _
		ByVal pClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As IrcPrefix Ptr, _
		ByVal IrcNumericCommand As Integer, _
		ByVal MessageText As BSTR _
	)

	Dim pContext As WindowContext Ptr = pClientData

	If IrcNumericCommand = IRCPROTOCOL_RPL_WELCOME Then
		IrcClientJoinChannel(pContext->pClient, pContext->Channel)
	End If

End Sub

Private Sub OnIrcPrivateMessage( _
		ByVal pClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As IrcPrefix Ptr, _
		ByVal MessageText As BSTR _
	)

	Dim pContext As WindowContext Ptr = pClientData

	Dim Message As BSTR = SysAllocString(WStr("Yes, me too"))
	IrcClientSendPrivateMessage(pContext->pClient, pIrcPrefix->Nick, Message)
	SysFreeString(Message)

End Sub

Private Sub OnRawMessage( _
		ByVal pClientData As LPCLIENTDATA, _
		ByVal pBytes As Const UByte Ptr, _
		ByVal Count As Integer _
	)

	Const NewLine = !"\r\n"

	Dim pContext As WindowContext Ptr = pClientData

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

	AppendLengthTextW(pContext->hWndReceive, @buf, Length + Len(NewLine))

End Sub

Private Function MessageLoop( _
		ByVal hWin As HWND, _
		ByVal pContext As WindowContext Ptr _
	)As Integer

	Do
		Dim hrLoop As HRESULT = IrcClientMsgMainLoop(pContext->pClient)

		If FAILED(hrLoop) Then
			IrcClientCloseConnection(pContext->pClient)
			Return 1
		End If

		Select Case hrLoop
			Case S_OK
				Do
					Dim wMsg As MSG = Any
					Dim resGetMessage As BOOL = PeekMessage( _
						@wMsg, _
						NULL, _
						0, _
						0, _
						PM_REMOVE _
					)
					If resGetMessage = 0 Then
						Exit Do
					End If

					If wMsg.message = WM_QUIT Then
						PostQuitMessage(wMsg.wParam)
						Return 0
					End If

					Dim resDialogMessage As BOOL = IsDialogMessage( _
						hWin, _
						@wMsg _
					)

					If resDialogMessage = 0 Then
						TranslateMessage(@wMsg)
						DispatchMessage(@wMsg)
					End If
				Loop

			Case Else ' S_FALSE
				IrcClientCloseConnection(pContext->pClient)
				Return 0
		End Select
	Loop

End Function

Private Sub DisableWindow( _
		ByVal hWin As HWND, _
		ByVal hwndControl As HWND _
	)

	' Disabling a window correctly
	Dim hwndFocus As HWND = GetFocus()

	If hwndFocus = hwndControl Then
		' giving focus to another window
		SendMessage(hWin, WM_NEXTDLGCTL, 0, 0)
	End If

	EnableWindow(hwndControl, 0)

End Sub

Private Function MainFormWndProc(ByVal hWin As HWND, ByVal wMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As LRESULT

	Dim pContext As WindowContext Ptr = Any

	If wMsg = WM_CREATE Then
		Dim pStruct As CREATESTRUCT Ptr = CPtr(CREATESTRUCT Ptr, lParam)
		pContext = pStruct->lpCreateParams
		SetWindowLongPtr(hWin, GWLP_USERDATA, Cast(LONG_PTR, pContext))

		pContext->hWndStart = CreateWindowEx(0, _
			WC_BUTTON, _
			"Start", _
			WS_CHILD Or WS_VISIBLE Or BS_PUSHBUTTON Or WS_CLIPSIBLINGS, _
			10, 10, 120, 36, _
			hWin, _
			Cast(HMENU, IDC_START), _
			GetModuleHandle(0), _
			NULL _
		)
		pContext->hWndStop = CreateWindowEx(0, _
			WC_BUTTON, _
			"Stop", _
			WS_CHILD Or WS_VISIBLE Or WS_DISABLED Or BS_PUSHBUTTON Or WS_CLIPSIBLINGS, _
			10 + 120 + 10, 10, 120, 36, _
			hWin, _
			Cast(HMENU, IDC_STOP), _
			GetModuleHandle(0), _
			NULL _
		)
		pContext->hWndReceive = CreateWindowEx(0, _
			WC_EDIT, _
			NULL, _
			WS_CHILD Or WS_VISIBLE Or WS_BORDER Or WS_VSCROLL Or WS_HSCROLL Or ES_AUTOHSCROLL Or ES_AUTOVSCROLL Or ES_MULTILINE, _
			10, 56, (640 * 3) \ 2, (480 * 3) \ 2, _
			hWin, _
			Cast(HMENU, IDC_RECEIVE), _
			GetModuleHandle(0), _
			NULL _
		)

		ZeroMemory(@pContext->Ev, SizeOf(IrcEvents))
		pContext->Ev.lpfnPrivateMessageEvent = @OnIrcPrivateMessage
		pContext->Ev.lpfnNumericMessageEvent = @OnNumericMessage
		pContext->Ev.lpfnReceivedRawMessageEvent = @OnRawMessage
		pContext->Ev.lpfnSendedRawMessageEvent = @OnRawMessage

		pContext->pClient = CreateIrcClient()
		IrcClientSetCallback(pContext->pClient, @pContext->Ev, pContext)

		Dim ClientVersion As BSTR = SysAllocString("IrcBot 1.0; FreeBASIC 1.10.1")
		IrcClientSetClientVersion(pContext->pClient, ClientVersion)
		SysFreeString(ClientVersion)

		Dim UserInfo As BSTR = SysAllocString(WStr("zamabuvaraeu"))
		IrcClientSetUserInfo(pContext->pClient, UserInfo)
		SysFreeString(UserInfo)

		Return 0
	End If

	pContext = Cast(Any Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))

	Select Case wMsg

		Case WM_COMMAND

			Select Case HiWord(wParam)

				Case 0 ' Меню или кнопка

					Select Case LoWord(wParam)

						Case IDC_START
							Dim hrOpen As HRESULT = IrcClientOpenConnectionSimple2( _
								pContext->pClient, _
								pContext->Server, _
								pContext->Port, _
								pContext->Nick _
							)

							If SUCCEEDED(hrOpen) Then
								DisableWindow(hWin, pContext->hWndStart)
								EnableWindow(pContext->hwndStop, 1)

								MessageLoop(hWin, pContext)

								EnableWindow(pContext->hWndStart, 1)
								DisableWindow(hWin, pContext->hwndStop)
							End If

						Case IDC_STOP
							IrcClientQuitFromServerSimple(pContext->pClient)
							EnableWindow(pContext->hWndStart, 1)
							DisableWindow(hWin, pContext->hwndStop)

					End Select

			End Select

		Case WM_DESTROY
			DestroyIrcClient(pContext->pClient)
			PostQuitMessage(0)

		Case Else
			Return DefWindowProc(hWin, wMsg, wParam, lParam)

	End Select

	Return 0

End Function

Private Function EnableVisualStyles()As HRESULT

	' Only for Win95
	InitCommonControls()

	' Dim icc As INITCOMMONCONTROLSEX = Any
	' icc.dwSize = SizeOf(INITCOMMONCONTROLSEX)
	' icc.dwICC = ICC_ANIMATE_CLASS Or _
	' 	ICC_BAR_CLASSES Or _
	' 	ICC_COOL_CLASSES Or _
	' 	ICC_DATE_CLASSES Or _
	' 	ICC_HOTKEY_CLASS Or _
	' 	ICC_INTERNET_CLASSES Or _
	' 	ICC_LINK_CLASS Or _
	' 	ICC_LISTVIEW_CLASSES Or _
	' 	ICC_NATIVEFNTCTL_CLASS Or _
	' 	ICC_PAGESCROLLER_CLASS Or _
	' 	ICC_PROGRESS_CLASS Or _
	' 	ICC_STANDARD_CLASSES Or _
	' 	ICC_TAB_CLASSES Or _
	' 	ICC_TREEVIEW_CLASSES Or _
	' 	ICC_UPDOWN_CLASS Or _
	' 	ICC_USEREX_CLASSES Or _
	' ICC_WIN95_CLASSES

	' Dim res As BOOL = InitCommonControlsEx(@icc)
	' If res = 0 Then
	' 	Dim dwError As DWORD = GetLastError()
	' 	Return HRESULT_FROM_WIN32(dwError)
	' End If

	Return S_OK

End Function

Private Function wWinMain( _
		Byval hInst As HINSTANCE, _
		ByVal hPrevInstance As HINSTANCE, _
		ByVal lpCmdLine As LPCWSTR, _
		ByVal iCmdShow As Long _
	)As Integer

	Const NineWindowTitle = "IrcClient"
	Const MainWindowClassName = "IrcClient"

	EnableVisualStyles()

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

	Dim Argc As Long = Any
	Dim Args As LPWSTR Ptr = CommandLineToArgvW( _
		lpCmdLine, _
		@Argc _
	)

	If Argc <> 5 Then
		Return 1
	End If

	Dim Context As WindowContext = Any
	Context.Server = SysAllocString(Args[1])
	Context.Port = SysAllocString(Args[2])
	Context.Nick = SysAllocString(Args[3])
	Context.Channel = SysAllocString(Args[4])

	Dim hWin As HWND = CreateWindowEx(WS_EX_OVERLAPPEDWINDOW, _
		@MainWindowClassName, _
		@NineWindowTitle, _
		WS_OVERLAPPEDWINDOW Or WS_CLIPCHILDREN, _
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, _
		NULL, _
		NULL, _
		hInst, _
		@Context _
	)
	If hWin = NULL Then
		Return 1
	End If

	ShowWindow(hWin, iCmdShow)
	UpdateWindow(hWin)

	Dim m As MSG = Any
	Dim GetMessageResult As Integer = GetMessage(@m, NULL, 0, 0)

	Do While GetMessageResult <> 0

		If GetMessageResult = -1 Then
			Return 1
		End If

		Dim resDialogMessage As BOOL = IsDialogMessage( _
			hWin, _
			@m _
		)

		If resDialogMessage = 0 Then
			TranslateMessage(@m)
			DispatchMessage(@m)
		End If

		GetMessageResult = GetMessage(@m, NULL, 0, 0)

	Loop

	Return m.WPARAM

End Function

#ifndef WITHOUT_RUNTIME
Private Function EntryPoint()As Integer
#else
Public Function EntryPoint Alias "EntryPoint"()As Integer
#endif

	Dim lpCmdLine As WCHAR Ptr = GetCommandLineW()
	Dim WinMainResult As Integer = wWinMain(GetModuleHandle(0), NULL, lpCmdLine, SW_SHOW)

	Return WinMainResult

End Function

#ifndef WITHOUT_RUNTIME
Dim RetCode As Long = CLng(EntryPoint())
End(RetCode)
#endif
