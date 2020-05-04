#include "IrcClient.bi"
#include "IrcReplies.bi"

Sub OnNumericMessageEvent( _
		ByVal ClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal IrcNumericCommand As Integer, _
		ByVal MessageText As BSTR _
	)
	If IrcNumericCommand = IRCPROTOCOL_RPL_WELCOME Then
		IrcClientJoinChannel(CPtr(IrcClient Ptr, ClientData), SysAllocString("#freebasic-ru"))
	End If
End Sub

Sub OnIrcPrivateMessage( _
		ByVal ClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal MessageText As BSTR _
	)
	IrcClientSendPrivateMessage(CPtr(IrcClient Ptr, ClientData), pIrcPrefix->Nick, SysAllocString("Да, я тоже."))
End Sub

Sub OnRawMessage( _
		ByVal ClientData As LPCLIENTDATA, _
		ByVal IrcMessage As BSTR _
	)
	Print *Cast(WString Ptr, IrcMessage)
End Sub

Dim Client As IrcClient
Client.AdvancedClientData = @Client
Client.lpfnPrivateMessageEvent = @OnIrcPrivateMessage
Client.lpfnNumericMessageEvent = @OnNumericMessageEvent
Client.lpfnReceivedRawMessageEvent = @OnRawMessage
Client.lpfnSendedRawMessageEvent = @OnRawMessage

Dim hr As HRESULT = IrcClientStartup(@Client)
If FAILED(hr) Then
	Print "IrcClientStartup FAILED", HEX(hr)
	End(1)
End If

hr = IrcClientOpenConnectionSimple1(@Client, SysAllocString("chat.freenode.net"), SysAllocString("LeoFitz"))
If FAILED(hr) Then
	Print "IrcClientOpenConnectionSimple1 FAILED", HEX(hr)
	End(1)
End If

hr = IrcClientStartReceiveDataLoop(@Client)
Print "IrcClientStartReceiveDataLoop", HEX(hr)

Print "Закрываю соединение"

IrcClientCloseConnection(@Client)
IrcClientCleanup(@Client)
