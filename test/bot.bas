#include once "IrcClient.bi"
#include once "IrcReplies.bi"

Dim Shared Channel As BSTR
Dim Shared Message As BSTR
Dim Shared Server As BSTR
Dim Shared Nick As BSTR
Dim Shared pClient As IrcClient Ptr

Sub OnNumericMessage( _
		ByVal pClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As IrcPrefix Ptr, _
		ByVal IrcNumericCommand As Integer, _
		ByVal MessageText As BSTR _
	)
	If IrcNumericCommand = IRCPROTOCOL_RPL_WELCOME Then
		IrcClientJoinChannel(pClient, Channel)
	End If
End Sub

Sub OnIrcPrivateMessage( _
		ByVal pClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As IrcPrefix Ptr, _
		ByVal MessageText As BSTR _
	)
	IrcClientSendPrivateMessage(pClient, pIrcPrefix->Nick, Message)
End Sub

Sub OnRawMessage( _
		ByVal lpParameter As LPCLIENTDATA, _
		ByVal pBytes As Const UByte Ptr, _
		ByVal Count As Integer _
	)
	Print *Cast(ZString Ptr, pBytes)
End Sub

' Server = SysAllocString("chat.freenode.net")
' Nick = SysAllocString("LeoFitz")
' Channel = SysAllocString("#freebasic-ru")
' Message = SysAllocString("Yes, me too")
Server = SysAllocString("irc.pouque.net")
Nick = SysAllocString("LeoFitz")
Channel = SysAllocString("#chlor")
Message = SysAllocString("Yes, me too")

Dim Ev As IrcEvents
Ev.lpfnPrivateMessageEvent = @OnIrcPrivateMessage
Ev.lpfnNumericMessageEvent = @OnNumericMessage
Ev.lpfnReceivedRawMessageEvent = @OnRawMessage
Ev.lpfnSendedRawMessageEvent = @OnRawMessage

pClient = CreateIrcClient(@Ev, pClient)

Dim hrConnection As HRESULT = IrcClientOpenConnectionSimple1(pClient, Server, Nick)
If FAILED(hrConnection) Then
	Print "OpenConnection FAILED", HEX(hrConnection)
	End(1)
End If

IrcClientMainLoop(pClient)

IrcClientCloseConnection(pClient)

DestroyIrcClient(pClient)
