#include "IrcClient.bi"
#include "IrcReplies.bi"

Dim Shared Channel As BSTR
Dim Shared Message As BSTR
Dim Shared Server As BSTR
Dim Shared Nick As BSTR

Sub OnNumericMessageEvent( _
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
	Print *Cast(WString Ptr, IrcMessage)
End Sub

Channel = SysAllocString("#freebasic-ru")
Message = SysAllocString("Да, я тоже.")
Server = SysAllocString("chat.freenode.net")
Nick = SysAllocString("LeoFitz")

Dim Client As IrcClient
Client.lpParameter = @Client
Client.Events.lpfnPrivateMessageEvent = @OnIrcPrivateMessage
Client.Events.lpfnNumericMessageEvent = @OnNumericMessageEvent
Client.Events.lpfnReceivedRawMessageEvent = @OnRawMessage
Client.Events.lpfnSendedRawMessageEvent = @OnRawMessage

Dim hr As HRESULT = IrcClientStartup(@Client)
If FAILED(hr) Then
	Print "IrcClientStartup FAILED", HEX(hr)
	End(1)
End If

hr = IrcClientOpenConnectionSimple1(@Client, Server, Nick)
If FAILED(hr) Then
	Print "IrcClientOpenConnectionSimple1 FAILED", HEX(hr)
	End(1)
End If

hr = IrcClientStartReceiveDataLoop(@Client)
Print "IrcClientStartReceiveDataLoop", HEX(hr)

Print "Закрываю соединение"

IrcClientCloseConnection(@Client)
IrcClientCleanup(@Client)
