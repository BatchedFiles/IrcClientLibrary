''
'' Библиотека для работы с IRC
''
#ifndef unicode
	#define unicode
#endif
#include once "windows.bi"
#include once "win\shellapi.bi"
#include once "win\shlwapi.bi"

#include once "Network.bi"

' Тип сообщения CTCP
Enum CtcpMessageType
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

' Результат выполнения запроса приёма отправки данных
Enum ResultType
	' Ошибки нет
	None
	' Ошибка инициализации
	WSAError
	' Ошибка сети
	SocketError
	' Пользователь отменил данные
	UserCancel
	' Ошибка сервера
	ServerError
End Enum

' Клиент
Type IrcClient
	
	' Константы
	
	' IRC‐команды
	Const SQuitString = "SQUIT"
	Const QuitString = "QUIT"
	Const QuitStringWithSpace = "QUIT :"
	Const PassStringWithSpace = "PASS "
	Const NickString = "NICK"
	Const NickStringWithSpace = "NICK "
	Const UserStringWithSpace = "USER "
	Const DefaultBotNameSepVisible = " 0 * :"
	Const DefaultBotNameSepInvisible = " 8 * :"
	Const PingString = "PING"
	Const PingStringWithSpace = "PING "
	Const PongString = "PONG"
	Const PongStringWithSpace = "PONG "
	Const ErrorString = "ERROR"
	Const PartString = "PART"
	Const PartStringWithSpace = "PART "
	Const PrivateMessage = "PRIVMSG"
	Const PrivateMessageWithSpace = "PRIVMSG "
	Const SpaceWithCommaString = " :"
	Const InviteString = "INVITE"
	Const JoinString = "JOIN"
	Const JoinStringWithSpace = "JOIN "
	Const KickString = "KICK"
	Const ModeString = "MODE"
	Const NoticeString = "NOTICE"
	Const NoticeStringWithSpace = "NOTICE "
	Const TopicString = "TOPIC"
	Const TopicStringWithSpace = "TOPIC "
	Const UserInfoString = "USERINFO"
	Const UserInfoStringWithSpace = "USERINFO "
	Const TimeString = "TIME"
	Const TimeStringWithSpace = "TIME "
	Const VersionString = "VERSION"
	Const VersionStringWithSpace = "VERSION "
	
	Const NewLineString = !"\r\n"
	
	Const JoinStringWithSpaceLength As Integer = 5
	Const PartStringWithSpaceLength As Integer = 5
	Const QuitStringWithSpaceLength As Integer = 6
	Const PrivateMessageWithSpaceLength As Integer = 8
	Const TopicStringWithSpaceLength As Integer = 6
	Const NoticeStringWithSpaceLength As Integer = 7
	
	' Максимальная длина принимаемых данных в IRC
	Const MaxBytesCount As Integer = 512
	' Максимальная длина ника в чате
	Const MaxNickLength As Integer = 50
	' Максимальная длина канала в чате
	Const MaxChannelNameLength As Integer = 50
	' Максимальная длина параметра в CTCP запросах
	Const MaxCtcpMessageParamLength As Integer = 50
	
	
	' Методы
	
	' Запуск соединения с сервером
	Declare Function OpenIrc(ByVal Server As WString Ptr, _
		ByVal Port As WString Ptr, _
		ByVal LocalServer As WString Ptr, _
		ByVal LocalPort As WString Ptr, _
		ByVal Password As WString Ptr, _
		ByVal Nick As WString Ptr, _
		ByVal User As WString Ptr, _
		ByVal Description As WString Ptr, _
		ByVal Visible As Boolean)As ResultType
	
	' Получение сообщения от сервера
	Declare Function ReceiveData(ByVal strReturnedString As WString Ptr)As ResultType
	' Разбираем полученные данные
	Declare Function ParseData(ByVal strData As WString Ptr)As ResultType
	
	' Закрытие соединения
	Declare Sub CloseIrc()
	
	' Отправка сообщения
	Declare Function SendIrcMessage(ByVal strChannel As WString Ptr, ByVal strMessageText As WString Ptr)As ResultType
	' Отправка уведомления
	Declare Function SendNotice(ByVal strChannel As WString Ptr, ByVal strNoticeText As WString Ptr)As ResultType
	' Смена темы
	Declare Function ChangeTopic(ByVal strChannel As WString Ptr, ByVal strTopic As WString Ptr)As ResultType
	' Выход из сети
	Declare Function QuitFromServer(ByVal strMessageText As WString Ptr)As ResultType
	' Смена ника
	Declare Function ChangeNick(ByVal Nick As WString Ptr)As ResultType
	' Присоединение к каналу
	Declare Function JoinChannel(ByVal strChannel As WString Ptr)As ResultType
	' Отсоединение от канала
	Declare Function PartChannel(ByVal strChannel As WString Ptr, ByVal strMessageText As WString Ptr)As ResultType
	' Отправка CTCP-запроса
	Declare Function SendCtcpMessage(ByVal strChannel As WString Ptr, ByVal iType As CtcpMessageType, ByVal Param As WString Ptr)As ResultType
	' Отправка CTCP-ответа
	Declare Function SendCtcpNotice(ByVal strChannel As WString Ptr, ByVal iType As CtcpMessageType, ByVal NoticeText As WString Ptr)As ResultType
	' Отправка сырого сообщения
	Declare Function SendRawMessage(ByVal strRawText As WString Ptr)As ResultType

	' Поля
	
	' Дополнительное поле для хранения разной информации
	' Оно будет отправляться в псевдособытия
	Dim ExtendedData As Any Ptr
	
	' Кодировка
	Dim CodePage As Integer
	
	' Псевдособытия
	Dim SendedRawMessageEvent As Sub(ByVal AdvData As Any Ptr, ByVal MessageText As WString Ptr)
	Dim ReceivedRawMessageEvent As Sub(ByVal AdvData As Any Ptr, ByVal MessageText As WString Ptr)
	Dim ServerErrorEvent As Sub(ByVal AdvData As Any Ptr, ByVal Message As WString Ptr)
	Dim DisconnectEvent As Sub(ByVal AdvData As Any Ptr)
	Dim ServerMessageEvent As Function(ByVal AdvData As Any Ptr, ByVal ServerCode As WString Ptr, ByVal MessageText As WString Ptr)As ResultType
	Dim NoticeEvent As Function(ByVal AdvData As Any Ptr, ByVal Channel As WString Ptr, ByVal NoticeText As WString Ptr)As ResultType
	Dim ChannelMessageEvent As Function(ByVal AdvData As Any Ptr, ByVal Channel As WString Ptr, ByVal User As WString Ptr, ByVal MessageText As WString Ptr)As ResultType
	Dim PrivateMessageEvent As Function(ByVal AdvData As Any Ptr, ByVal User As WString Ptr, ByVal MessageText As WString Ptr)As ResultType
	Dim UserJoinedEvent As Function(ByVal AdvData As Any Ptr, ByVal Channel As WString Ptr, ByVal UserName As WString Ptr)As ResultType
	Dim UserLeavedEvent As Function(ByVal AdvData As Any Ptr, ByVal Channel As WString Ptr, ByVal UserName As WString Ptr, ByVal MessageText As WString Ptr)As ResultType
	Dim NickChangedEvent As Function(ByVal AdvData As Any Ptr, ByVal OldNick As WString Ptr, ByVal NewNick As WString Ptr)As ResultType
	Dim TopicEvent As Function(ByVal AdvData As Any Ptr, ByVal Channel As WString Ptr, ByVal UserName As WString Ptr, ByVal Text As WString Ptr) As ResultType
	Dim QuitEvent As Function(ByVal AdvData As Any Ptr, ByVal UserName As WString Ptr, ByVal MessageText As WString Ptr)As ResultType
	Dim KickEvent As Function(ByVal AdvData As Any Ptr, ByVal AdminName As WString Ptr, ByVal Channel As WString Ptr, ByVal KickedUser As WString Ptr)As ResultType
	Dim InviteEvent As Function(ByVal AdvData As Any Ptr, ByVal FromuserName As WString Ptr, ByVal Channel As WString Ptr)As ResultType
	Dim PingEvent As Function(ByVal AdvData As Any Ptr, ByVal Server As WString Ptr)As ResultType
	Dim PongEvent As Function(ByVal AdvData As Any Ptr, ByVal Server As WString Ptr)As ResultType
	Dim ModeEvent As Function(ByVal AdvData As Any Ptr, ByVal AdminName As WString Ptr, ByVal Channel As WString Ptr, ByVal UserName As WString Ptr, ByVal Mode As WString Ptr)As ResultType
	Dim CtcpMessageEvent As Function(ByVal AdvData As Any Ptr, ByVal FromUser As WString Ptr, ByVal UserName As WString Ptr, ByVal MessageType As CtcpMessageType, ByVal Param As WString Ptr)As ResultType
	Dim CtcpNoticeEvent As Function(ByVal AdvData As Any Ptr, ByVal FromUser As WString Ptr, ByVal UserName As WString Ptr, ByVal MessageType As CtcpMessageType, ByVal MessageText As WString Ptr)As ResultType
	
	' Отпавка строки на сервер
	Declare Function SendData(ByVal strData As WString Ptr)As ResultType
	' Поиск CrLf в накопительном буфере
	Declare Function FindCrLfA()As Integer
	
	' Инкапсуляция свойств
	
	' Ник пользователя
	Dim m_Nick As WString * (MaxNickLength + 1)
	
	' Накопительный буфер приёма данных
	Dim m_Buffer As ZString * (MaxBytesCount + 1)
	Dim m_BufferLength As Integer
	Dim m_Socket As SOCKET
	
End Type

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

' Получаем имя пользователя
Declare Sub GetIrcUserName(ByVal strReturn As WString Ptr, ByVal strData As WString Ptr)
' Получаем текст сообщения
Declare Function GetIrcMessageText(ByVal strData As WString Ptr)As WString Ptr
' Получаем имя сервера
Declare Sub GetIrcServerName(ByVal strReturn As WString Ptr, ByVal strData As WString Ptr)

' Определяем первое слово сервера
Declare Function GetServerWord(ByVal w As WString Ptr)As ServerWord

' Определяем команду
Declare Function GetServerCommand(ByVal w As WString Ptr)As ServerCommand

' Определяем команду CTCP сообщения
Declare Function GetCtcpCommand(ByVal w As WString Ptr)As CtcpMessageType

' Отделение слова нулевым символом и возвращение указателя на следующее слово
Declare Function GetNextWord(ByVal wStart As WString Ptr)As WString Ptr
