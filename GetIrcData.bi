#ifndef BATCHEDFILES_IRCCLIENT_GETIRCDATA_BI
#define BATCHEDFILES_IRCCLIENT_GETIRCDATA_BI

#include "IrcClient.bi"

Enum IrcCommand
	PingWord
	PongWord
	ErrorWord
	PrivateMessage
	Notice
	Join
	Quit
	SQuit
	Invite
	Kick
	Mode
	Nick
	Part
	Topic
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

' Получаем текст сообщения
Declare Function GetIrcMessageText( _
	ByVal strData As WString Ptr _
)As WString Ptr

' Определяем команду CTCP сообщения
Declare Function GetCtcpCommand( _
	ByVal w As WString Ptr _
)As CtcpMessageKind

' Отделение слова нулевым символом и возвращение указателя на следующее слово
Declare Function GetNextWord( _
	ByVal wStart As WString Ptr _
)As WString Ptr

#endif
