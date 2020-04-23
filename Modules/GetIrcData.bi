#ifndef BATCHEDFILES_IRCCLIENT_GETIRCDATA_BI
#define BATCHEDFILES_IRCCLIENT_GETIRCDATA_BI

#include "IrcPrefix.bi"

Enum IrcCommand
	PingWord
	PrivateMessage
	Join
	Quit
	Part
	Notice
	Nick
	ErrorWord
	Kick
	Mode
	Topic
	Invite
	PongWord
	SQuit
	Server
End Enum

Enum CtcpMessageKind
	None
	Ping
	Time
	UserInfo
	Version
	Action
	ClientInfo
	Echo
	Finger
	Utc
End Enum

Declare Function GetIrcPrefix( _
	ByVal pIrcPrefix As IrcPrefix Ptr, _
	ByVal IrcData As WString Ptr _
)As WString Ptr

Declare Function GetIrcCommand( _
	ByVal w As WString Ptr _
)As IrcCommand

Declare Function GetIrcServerName( _
	ByVal strData As WString Ptr _
)As WString Ptr

Declare Function GetIrcMessageText( _
	ByVal strData As WString Ptr _
)As WString Ptr

Declare Function GetCtcpCommand( _
	ByVal w As WString Ptr _
)As CtcpMessageKind

Declare Function GetNextWord( _
	ByVal wStart As WString Ptr _
)As WString Ptr

#endif
