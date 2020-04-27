#include "IrcClient.bi"

Sub OnIrcPrivateMessage( _
		ByVal ClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal MessageText As LPWSTR _
	)
	IrcClientSendPrivateMessage(CPtr(IrcClient Ptr, ClientData), pIrcPrefix->Nick, "Да, я тоже.")
End Sub

Sub OnRawMessage( _
		ByVal ClientData As LPCLIENTDATA, _
		ByVal MessageText As LPWSTR _
	)
	Print *MessageText
End Sub

Dim Client As IrcClient
Client.AdvancedClientData = @Client
Client.lpfnPrivateMessageEvent = @OnIrcPrivateMessage
Client.lpfnReceivedRawMessageEvent = @OnRawMessage
Client.lpfnSendedRawMessageEvent = @OnRawMessage

Dim hr As HRESULT = IrcClientStartup(@Client)
If FAILED(hr) Then
	Print HEX(hr)
	End(1)
End If

hr = IrcClientOpenConnectionSimple1(@Client, "chat.freenode.net", "LeoFitz")
If FAILED(hr) Then
	Print HEX(hr)
	End(1)
End If

IrcClientJoinChannel(@Client, "#freebasic-ru")
IrcClientStartReceiveDataLoop(@Client)

Print "Закрываю соединение"

IrcClientCloseConnection(@Client)
IrcClientCleanup(@Client)
