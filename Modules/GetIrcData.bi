#ifndef BATCHEDFILES_IRCCLIENT_GETIRCDATA_BI
#define BATCHEDFILES_IRCCLIENT_GETIRCDATA_BI

Enum IrcCommand
	Ping
	PrivateMessage
	Join
	Quit
	Part
	Notice
	Nick
	Error
	Kick
	Mode
	Topic
	Invite
	Pong
	SQuit
End Enum

Enum CtcpMessageKind
	Ping
	Action
	Time
	UserInfo
	Version
	ClientInfo
	Echo
	Finger
	Utc
	None
End Enum

Declare Function IsNumericIrcCommand( _
	ByVal w As WString Ptr, _
	ByVal Length As Integer _
)As Boolean

Declare Function GetIrcCommand( _
	ByVal w As WString Ptr, _
	ByVal pIrcCommand As IrcCommand Ptr _
)As Boolean

Declare Function GetIrcServerName( _
	ByVal strData As WString Ptr _
)As WString Ptr

Declare Function GetIrcMessageText( _
	ByVal strData As WString Ptr _
)As WString Ptr

Declare Function GetCtcpCommand( _
	ByVal w As WString Ptr _
)As CtcpMessageKind

Declare Function SeparateWordBySpace( _
	ByVal wStart As WString Ptr _
)As WString Ptr

#endif
