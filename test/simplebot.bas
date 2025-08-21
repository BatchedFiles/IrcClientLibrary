#include once "IrcClient.bi"

Dim Shared pClient As IrcClient Ptr

Sub OnIrcPrivateMessage( _
		ByVal pClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As IrcPrefix Ptr, _
		ByVal MessageText As BSTR _
	)
	IrcClientSendPrivateMessage( _
		pClient, _
		pIrcPrefix->Nick, _
		SysAllocString("Yes, me too") _
	)
End Sub

Dim Ev As IrcEvents
Ev.lpfnPrivateMessageEvent = @OnIrcPrivateMessage

pClient = CreateIrcClient(@Ev, 0)

IrcClientOpenConnectionSimple1( _
	pClient, _
	SysAllocString("irc.pouque.net"), _
	SysAllocString("LeoFitz") _
)
IrcClientJoinChannel(pClient, SysAllocString("#chlor"))

IrcClientMainLoop(pClient)

IrcClientCloseConnection(pClient)
DestroyIrcClient(pClient)
