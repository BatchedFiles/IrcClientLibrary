#ifndef BATCHEDFILES_IRCCLIENT_GETIRCDATA_BI
#define BATCHEDFILES_IRCCLIENT_GETIRCDATA_BI

Enum ServerWord
	PingWord
	PongWord
	ErrorWord
	ElseWord
End Enum

Enum ServerCommand
	PrivateMessage
	Notice
	Join
	Quit
	Invite
	Kick
	Mode
	Nick
	Part
	Topic
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

' Получаем имя пользователя
Declare Sub GetIrcUserName( _
	ByVal strReturn As WString Ptr, _
	ByVal strData As WString Ptr _
)

' Получаем текст сообщения
Declare Function GetIrcMessageText( _
	ByVal strData As WString Ptr _
)As WString Ptr

' Получаем имя сервера
Declare Function GetIrcServerName( _
	ByVal strData As WString Ptr _
)As WString Ptr

' Определяем первое слово сервера
Declare Function GetServerWord( _
	ByVal w As WString Ptr _
)As ServerWord

' Определяем команду
Declare Function GetServerCommand( _
	ByVal w As WString Ptr _
)As ServerCommand

' Определяем команду CTCP сообщения
Declare Function GetCtcpCommand( _
	ByVal w As WString Ptr _
)As CtcpMessageKind

' Отделение слова нулевым символом и возвращение указателя на следующее слово
Declare Function GetNextWord( _
	ByVal wStart As WString Ptr _
)As WString Ptr

#endif
