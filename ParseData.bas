#include once "AsmIrc.bi"
#include once "windows.bi"
#include once "win\shlwapi.bi"

' Разбираем сообщение и вызываем соответствующие события
Function IrcClient.ParseData(ByVal ircData As WString Ptr Ptr, ByVal ircDataCount As Integer, ByVal strData As WString Ptr)As ResultType
	If lstrcmp(ircData[0], @PingString) = 0 Then
		If CInt(PingEvent) Then
			' Понг не отправлять, это сделает сам клиент
			Dim strServer As WString * (MaxBytesCount + 1) = Any
			GetIrcServerName(@strServer, strData)
			Return PingEvent(ExtendedData, @strServer)
		Else
			' Отправляем понг самостоятельно
			Dim strPong As WString * (MaxBytesCount + 1) = Any
			lstrcpy(@strPong, @PongStringWithSpace)
			lstrcat(@strPong, @strData[6])
			Return SendData(@strPong)
		End If
	End If
	
	If lstrcmp(ircData[0], @PongString) = 0 Then
		' Сообщаем клиенту о пришедшем понге
		If CInt(PongEvent) Then
			Dim strServer As WString * (MaxBytesCount + 1) = Any
			GetIrcServerName(@strServer, strData)
			Return PongEvent(ExtendedData, @strServer)
		Else
			Return ResultType.None
		End If
	End If
	
	If lstrcmp(ircData[0], @ErrorString) = 0 Then
		' Сервер отправил ошибку
		'ERROR :Closing Link: 89.22.170.64 (Client Quit)
		If CInt(ServerErrorEvent) Then
			Dim strMessageText As WString * (MaxBytesCount + 1) = Any
			GetIrcMessageText(@strMessageText, strData)
			ServerErrorEvent(ExtendedData, @strMessageText)
		End If
		Return ResultType.ServerError
	Else
		' Имя пользователя, необходимо почти во всех событиях
		Dim strUserName As WString * (MaxBytesCount + 1) = Any
		GetIrcUserName(@strUserName, ircData[0])
		' Определяем команду
		
		If lstrcmp(ircData[1], @InviteString) = 0 Then
			' приглашение пользователя на канал
			' от кого INVITE кому канал
			':Angel!wings@irc.org INVITE Wiz #Dust
			If CInt(InviteEvent) Then
				'В ircData[3] содержится имя канала
				Return InviteEvent(ExtendedData, @strUserName, ircData[3])
			Else
				Return ResultType.None
			End If
		End If
		
		If lstrcmp(ircData[1], @JoinString) = 0 Then
			' Кто-то присоединился к каналу
			':Qubick!~Qubick@irc.org JOIN ##freebasic
			If CInt(UserJoinedEvent) Then
				Return UserJoinedEvent(ExtendedData, ircData[2], @strUserName)
			Else
				Return ResultType.None
			End If
		End If
		
		If lstrcmp(ircData[1], @KickString) = 0 Then
			' Удар по пользователю
			':WiZ!jto@tolsun.oulu.fi KICK #Finnish John
			'KICK message on channel #Finnish
			'from WiZ to remove John from channel
			If CInt(KickEvent) Then
				'В ircData[2] содержится имя канала, с которого ударили
				'В ircData[3] содержится имя пользователя которого ударили
				Return KickEvent(ExtendedData, @strUserName, ircData[2], ircData[3])
			Else
				Return ResultType.None
			End If
		End If
		
		If lstrcmp(ircData[1], @ModeString) = 0 Then
			' Установка режима
			':ChanServ!ChanServ@services. MODE ##freebasic +v ssteiner
			' нужны данные: кто включил статус
			' кому включили статус
			' на каком канале включили статус
			' и текст строки
			If CInt(ModeEvent) Then
				' Кто изменил режим
				'ircData[2] - канал
				'ircData[3] - режим
				'ircData[4] - кому установили режим
				Return ModeEvent(ExtendedData, @strUserName, ircData[2], ircData[4], ircData[3])
			Else
				Return ResultType.None
			End If
		End If
		
		If lstrcmp(ircData[1], @NickString) = 0 Then
			' Кто-то сменил ник
			' В ircData[2] содержится новый ник
			If CInt(NickChangedEvent) Then
				Return NickChangedEvent(ExtendedData, @strUserName, ircData[2])
			Else
				Return ResultType.None
			End If
		End If
		
		If lstrcmp(ircData[1], @NoticeString) = 0 Then
			' Уведомление
			Dim strMessageText As WString * (MaxBytesCount + 1) = Any
			GetIrcMessageText(@strMessageText, strData)
			
			' Второй SOH символ в строке
			Dim strSoh As WString Ptr = StrStr(@strMessageText[1], @SohString)
			If strMessageText[0] = 1 AndAlso strSoh <> 0 Then
				' CTCP-ответ от клиента
				If CInt(CtcpNoticeEvent) Then
					' Надо вырезать первый и последний символ 
					strSoh[0] = 0
					
					' Ответы CTCP
					':Angel!wings@irc.org NOTICE Qubick :PING 1402355972
					' strUserName *ircData[2]
					
					' Найти пробел и поставить на его место NullChar
					Dim wSpase As WString Ptr = StrStr(@strMessageText[1], @WhiteSpaceString)
					If wSpase <> 0 Then
						wSpase[0] = 0
						If lstrcmp(@strMessageText[1], @PingString) = 0 Then
							Return CtcpNoticeEvent(ExtendedData, @strUserName, ircData[2], CtcpMessageType.Ping, @wSpase[1])
						End If
						If lstrcmp(@strMessageText[1], @UserInfoString) = 0 Then
							Return CtcpNoticeEvent(ExtendedData, @strUserName, ircData[2], CtcpMessageType.UserInfo, @wSpase[1])
						End If
						If lstrcmp(@strMessageText[1], @TimeString) = 0 Then
							Return CtcpNoticeEvent(ExtendedData, @strUserName, ircData[2], CtcpMessageType.Time, @wSpase[1])
						End If
						If lstrcmp(@strMessageText[1], @VersionString) = 0 Then
							Return CtcpNoticeEvent(ExtendedData, @strUserName, ircData[2], CtcpMessageType.Version, @wSpase[1])
						End If
					End If
					Return ResultType.None
				Else
					Return ResultType.None
				End If
			Else
				If lstrcmp(ircData[2], @m_Nick) = 0 Then
					If CInt(NoticeEvent) Then
						Return NoticeEvent(ExtendedData, @strUserName, strMessageText)
					Else
						Return ResultType.None
					End If
				Else
					' ircData[2] - канал
					If CInt(ServerMessageEvent) Then
						Return ServerMessageEvent(ExtendedData, ircData[2], strMessageText)
					Else
						Return ResultType.None
					End If
				End If
			End If
		End If
		
		If lstrcmp(ircData[1], @PrivateMessage) = 0 Then
			' Сообщение от канала или пользователя
			' В ircData(2) содержится имя получателя
			':Angel!wings@irc.org PRIVMSG Wiz :Are you receiving this message ?
			Dim strMessageText As WString * (MaxBytesCount + 1) = Any
			GetIrcMessageText(@strMessageText, strData)
			' Последний SOH символ в строке
			Dim strSoh As WString Ptr = StrStr(@strMessageText[1], @SohString)
			
			' первый и последний символы сообщения имеют ASCII-значение 0x01
			If strMessageText[0] = 1 AndAlso strSoh <> 0 Then
				REM ' Запросы CTCP
				If CInt(CtcpMessageEvent) Then
					' Надо вырезать первый и последний символ 
					strSoh[0] = 0
					' @strMessageText[1]
					' Исходим из предположения, что ник «кому» совпадает с нашим
					
					REM ':Angel!wings@irc.org PRIVMSG Qubick :PING 1402355972
					REM ' strUserName *ircData[2]
					REM ' PRIVMSG Qubick :VERSION
					REM ' PRIVMSG Qubick :TIME
					REM ' PRIVMSG Qubick :USERINFO
					
					' Найти пробел и поставить на его место NullChar
					Dim wSpace As WString Ptr = StrStr(@strMessageText[1], @WhiteSpaceString)
					If wSpace <> 0 Then
						wSpace[0] = 0
						If lstrcmp(@strMessageText[1], @PingString) = 0 Then
							Return CtcpMessageEvent(ExtendedData, @strUserName, ircData[2], CtcpMessageType.Ping, @wSpace[1])
						End If
					End If
					If lstrcmp(@strMessageText[1], @UserInfoString) = 0 Then
						Return CtcpMessageEvent(ExtendedData, @strUserName, ircData[2], CtcpMessageType.UserInfo, @WhiteSpaceString)
					End If
					If lstrcmp(@strMessageText[1], @TimeString) = 0 Then
						Return CtcpMessageEvent(ExtendedData, @strUserName, ircData[2], CtcpMessageType.Time, @WhiteSpaceString)
					End If
					If lstrcmp(@strMessageText[1], @VersionString) = 0 Then
						Return CtcpMessageEvent(ExtendedData, @strUserName, ircData[2], CtcpMessageType.Version, @WhiteSpaceString)
					End If
					Return ResultType.None
				Else
					Return ResultType.None
				End If
			Else
				If lstrcmp(ircData[2], @m_Nick) = 0 Then
					' Сообщение от пользователя
					If CInt(PrivateMessageEvent) Then
						Return PrivateMessageEvent(ExtendedData, @strUserName, @strMessageText)
					Else
						Return ResultType.None
					End If
				Else
					' ircData[2] - канал
					If CInt(ChannelMessageEvent) Then
						Return ChannelMessageEvent(ExtendedData, ircData[2], @strUserName, @strMessageText)
					Else
						Return ResultType.None
					End If
				End If
			End If
		End If
		
		If lstrcmp(ircData[1], @PartString) = 0 Then
			' Пользователь покинул канал
			If CInt(UserLeavedEvent) Then
				Dim strMessageText As WString * (MaxBytesCount + 1) = Any
				GetIrcMessageText(@strMessageText, strData)
				Return  UserLeavedEvent(ExtendedData, ircData[2], @strUserName, @strMessageText)
			Else
				Return ResultType.None
			End If
		End If
		
		If lstrcmp(ircData[1], @QuitString) = 0 Then
			' Кто-то вышел
			If CInt(UserQuitEvent) Then
				Dim strMessageText As WString * (MaxBytesCount + 1) = Any
				GetIrcMessageText(@strMessageText, strData)
				Return UserQuitEvent(ExtendedData, @strUserName, @strMessageText)
			Else
				Return ResultType.None
			End If
		End If
		
		If lstrcmp(ircData[1], @SQuitString) = 0 Then
			REM ' Выход оператора
		End If
		
		If lstrcmp(ircData[1], @TopicString) = 0 Then
			' Смена темы
			If CInt(TopicEvent) Then
				Dim strMessageText As WString * (MaxBytesCount + 1) = Any
				GetIrcMessageText(@strMessageText, strData)
				Return TopicEvent(ExtendedData, ircData[2], @strUserName, @strMessageText)
			Else
				Return ResultType.None
			End If
		Else
			' Серверное сообщение
			If CInt(ServerMessageEvent) Then
				' ircData[1] — код сообщения
				' ircData[2] — ник получателя
				' а дальше идут данные
				Dim strMessage As WString * (MaxBytesCount + 1) = Any
				Return ServerMessageEvent(ExtendedData, ircData[1], @strMessage)
			Else
				Return ResultType.None
			End If
		End If
	End If
End Function
