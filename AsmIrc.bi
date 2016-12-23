''
'' Библиотека для работы с IRC
''
#ifndef unicode
	#define unicode
#endif
#include once "windows.bi"
#include once "win\shlwapi.bi"
#include once "win\shellapi.bi"
#include once "win\winsock2.bi"
#include once "win\ws2tcpip.bi"
#include once "Network.bi"

' Тип сообщения CTCP
Public Enum CtcpMessageType
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
Public Enum ResultType
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
	' Переполнение буфера
	BufferOverflow
End Enum

' Клиент
Type IrcClient
	
	Public:
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
		Const SohString = ""
		
		' Размер буфера с нулевым символом
		Const MaxBytesCount As Integer = 512 * SizeOf(WString)
		' Размер внутреннего накопительного буфера 
		Const StaticBufferSize As Integer = MaxBytesCount * 4
		' Новая строка
		Const NewLineString = !"\r\n"
		' Двоеточие
		Const CommaSeparatorString = ":"
		' Пробел
		Const WhiteSpaceString = " "
		
		
		' Методы
		
		' Запуск соединения с сервером
		Declare Function OpenIrc(ByRef Server As WString, _
									ByRef Port As WString, _
									ByRef LocalServer As WString, _
									ByRef LocalServiceName As WString, _
									ByRef Password As WString, _
									ByRef Nick As WString, _
									ByRef User As WString, _
									ByRef Description As WString, _
									ByVal Visible As Boolean)As ResultType
		' Получение данных от сервера и запуск обработки команд
		Declare Function GetData()As ResultType
		' Закрытие соединения
		Declare Sub CloseIrc()
		
		' Отправка сообщения
		Declare Function SendIrcMessage(ByRef strChannel As WString, ByRef strMessageText As  WString)As ResultType
		' Отправка уведомления
		Declare Function SendNotice(ByRef strChannel As WString, ByRef strNoticeText As  WString)As ResultType
		' Смена темы
		Declare Function ChangeTopic(ByRef strChannel As WString, ByRef strTopic As WString)As ResultType
		' Выход из сети
		Declare Function QuitFromServer(ByRef strMessageText As WString)As ResultType
		' Смена ника
		Declare Function ChangeNick(ByRef Nick As WString)As ResultType
		' Присоединение к каналу
		Declare Function JoinChannel(ByRef strChannel As  WString)As ResultType
		' Отсоединение от канала
		Declare Function PartChannel(ByRef strChannel As  WString, ByRef strMessageText As WString)As ResultType
		' Отправка CTCP-запроса
		Declare Function SendCtcpMessage(ByRef strChannel As  WString, ByVal iType As CtcpMessageType, ByRef Param As WString)As ResultType
		' Отправка CTCP-ответа
		Declare Function SendCtcpNotice(ByRef strChannel As  WString, ByVal iType As CtcpMessageType, ByRef NoticeText As WString)As ResultType
		' Отправка сырого сообщения
		Declare Function SendRawMessage(ByRef strRawText As  WString)As ResultType
		REM ' Отправка пинга и понга
		REM Declare Function SendPing()As ResultType
		REM Declare Function SendPong()As ResultType
	
		' Поля
		
		' Дополнительное поле для хранения разной информации
		' Оно будет отправляться в псевдособытия
		Dim ExtendedData As Any Ptr
		
		' Псевдособытия
		Dim SendedRawMessageEvent As Sub(ByVal AdvData As Any Ptr, ByRef MessageText As WString)
		Dim ReceivedRawMessageEvent As Sub(ByVal AdvData As Any Ptr, ByRef MessageText As WString)
		Dim ServerMessageEvent As Function(ByVal AdvData As Any Ptr, ByRef ServerCode As WString, ByRef MessageText As WString)As ResultType
		Dim NoticeEvent As Function(ByVal AdvData As Any Ptr, ByRef Channel As WString, ByRef NoticeText As WString)As ResultType
		Dim ChannelMessageEvent As Function(ByVal AdvData As Any Ptr, ByRef Channel As WString, ByRef User As WString, ByRef MessageText As WString)As ResultType
		Dim PrivateMessageEvent As Function(ByVal AdvData As Any Ptr, ByRef User As WString, ByRef MessageText As WString)As ResultType
		Dim UserJoinedEvent As Function(ByVal AdvData As Any Ptr, ByRef Channel As WString, ByRef UserName As WString)As ResultType
		Dim UserLeavedEvent As Function(ByVal AdvData As Any Ptr, ByRef Channel As WString, ByRef UserName As WString, ByRef MessageText As WString)As ResultType
		Dim NickChangedEvent As Function(ByVal AdvData As Any Ptr, ByRef OldNick As WString, ByRef NewNick As WString)As ResultType
		Dim TopicEvent As Function(ByVal AdvData As Any Ptr, ByRef Channel As WString, ByRef UserName As WString, ByRef Text As WString) As ResultType
		Dim UserQuitEvent As Function(ByVal AdvData As Any Ptr, ByRef UserName As WString, ByRef MessageText As WString)As ResultType
		Dim KickEvent As Function(ByVal AdvData As Any Ptr, ByRef AdminName As WString, ByRef Channel As WString, ByRef KickedUser As WString)As ResultType
		Dim InviteEvent As Function(ByVal AdvData As Any Ptr, ByRef FromuserName As WString, ByRef Channel As WString)As ResultType
		Dim DisconnectEvent As Sub(ByVal AdvData As Any Ptr)
		Dim PingEvent As Function(ByVal AdvData As Any Ptr, ByRef Server As WString)As ResultType
		Dim PongEvent As Function(ByVal AdvData As Any Ptr, ByRef Server As WString)As ResultType
		Dim ModeEvent As Function(ByVal AdvData As Any Ptr, ByRef AdminName As WString, ByRef Channel As WString, ByRef UserName As WString, ByRef Mode As WString)As ResultType
		Dim CtcpMessageEvent As Function(ByVal AdvData As Any Ptr, ByRef FromUser As WString, ByRef UserName As WString, ByVal MessageType As CtcpMessageType, ByRef Param As WString)As ResultType
		Dim CtcpNoticeEvent As Function(ByVal AdvData As Any Ptr, ByRef FromUser As WString, ByRef UserName As WString, ByVal MessageType As CtcpMessageType, ByRef MessageText As WString)As ResultType
		Dim ServerErrorEvent As Sub(ByVal AdvData As Any Ptr, ByRef Message As WString)
		
	Private:
		
		' Получение сообщения от сервера
		Declare Function ReceiveData(ByVal strReturnedString As WString Ptr)As ResultType
		' Отпавка строки на сервер
		Declare Function SendData(ByRef strData As WString)As ResultType
		
		' Разбираем полученные данные
		Declare Function ParseData(ByVal ircData As WString Ptr Ptr, ByVal ircDataCount As Integer, ByRef strData As WString)As ResultType
		
		' Получаем имя пользователя
		Declare Sub GetIrcUserName(ByVal strReturn As WString Ptr, ByRef strData As WString)
		' Получаем текст сообщения
		Declare Sub GetIrcMessageText(ByVal strReturn As WString Ptr, ByRef strData As WString)
		' Получаем имя сервера
		Declare Sub GetIrcServerName(ByVal strReturn As WString Ptr, ByRef strData As WString)
		
		' Инкапсуляция свойств
		
		' Ник пользователя
		Dim m_Nick As WString * (MaxBytesCount + 1)
		
		' Накопительный буфер приёма данных
		Dim m_Buffer As WString * (StaticBufferSize + 1)
		Dim m_Socket As SOCKET
		
End Type
