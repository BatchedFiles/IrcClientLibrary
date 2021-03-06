#ifndef unicode
#define unicode
#endif

#include "IrcClient.bi"
#include "IrcReplies.bi"

Const IDC_SEND = 1001
Const IDC_RECEIVE = 1002
Const IDC_START = 1003

Dim Shared hWndSend As HWND
Dim Shared hWndReceive As HWND
Dim Shared hWndStart As HWND
Dim Shared Client As IrcClient
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
		SetWindowText(hwndControl, lpBuffer)
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
		ByVal ClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal IrcNumericCommand As Integer, _
		ByVal MessageText As BSTR _
	)
	If IrcNumericCommand = IRCPROTOCOL_RPL_WELCOME Then
		IrcClientJoinChannel(CPtr(IrcClient Ptr, ClientData), Channel)
	End If
End Sub

Sub OnIrcPrivateMessage( _
		ByVal ClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal MessageText As BSTR _
	)
	IrcClientSendPrivateMessage(CPtr(IrcClient Ptr, ClientData), pIrcPrefix->Nick, Message)
End Sub

Sub OnRawMessage( _
		ByVal ClientData As LPCLIENTDATA, _
		ByVal IrcMessage As BSTR _
	)
	AppendLengthTextW(hWndReceive, IrcMessage, SysStringLen(IrcMessage))
	AppendLengthTextW(hWndReceive, !"\r\n", 2)
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
			
			Channel = SysAllocString("#freebasic-ru")
			Message = SysAllocString("Да, я тоже.")
			Server = SysAllocString("chat.freenode.net")
			Nick = SysAllocString("LeoFitz")
			
			Client.lpParameter = @Client
			Client.Events.lpfnPrivateMessageEvent = @OnIrcPrivateMessage
			Client.Events.lpfnNumericMessageEvent = @OnNumericMessage
			Client.Events.lpfnReceivedRawMessageEvent = @OnRawMessage
			Client.Events.lpfnSendedRawMessageEvent = @OnRawMessage
			
		Case WM_COMMAND
			
			Select Case HiWord(wParam)
				
				Case 0 ' Меню или кнопка
					
					Select Case LoWord(wParam)
						
						Case IDC_START
							EnableWindow(hWndStart, 0)
							
							Dim hr As HRESULT = IrcClientStartup(@Client)
							If FAILED(hr) Then
								Print "IrcClientStartup FAILED", HEX(hr)
							End If
							
							hr = IrcClientOpenConnectionSimple1(@Client, Server, Nick)
							If FAILED(hr) Then
								Print "IrcClientOpenConnectionSimple1 FAILED", HEX(hr)
							End If
							
							Do
								hr = IrcClientMsgStartReceiveDataLoop(@Client)
								
								If FAILED(hr) Then
									Print "IrcClientStartReceiveDataLoop", HEX(hr)
									Print "Закрываю соединение"
									IrcClientCloseConnection(@Client)
									IrcClientCleanup(@Client)
									Exit Do
								Else
									If hr = S_OK Then
										Dim m As MSG = Any
										Do While PeekMessage(@m, NULL, 0, 0, PM_REMOVE) <> 0
											If m.message = WM_QUIT Then
												IrcClientQuitFromServerSimple(@Client)
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
							
							IrcClientQuitFromServerSimple(@Client)
							IrcClientCloseConnection(@Client)
							IrcClientCleanup(@Client)
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

Function WinMain( _
		Byval hInst As HINSTANCE, _
		ByVal hPrevInstance As HINSTANCE, _
		ByVal Args As WString Ptr Ptr, _
		ByVal ArgsCount As Integer, _
		ByVal iCmdShow As Integer _
	) As Integer
	
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
		.lpszMenuName  = Cast(WString Ptr, NULL)
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

Dim ArgsCount As DWORD = Any
Dim Args As WString Ptr Ptr = CommandLineToArgvW(GetCommandLine(), @ArgsCount)
Dim WinMainResult As Integer = WinMain(GetModuleHandle(0), NULL, Args, CInt(ArgsCount), SW_SHOW)
LocalFree(Args)
End(WinMainResult)
