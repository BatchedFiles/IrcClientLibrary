#include once "Irc.bi"
#include once "GetIrcData.bi"

Sub IrcClient.ProcessMessage(ByVal Receiver As WString Ptr, ByVal UserName As WString Ptr, ByVal MessageText As WString Ptr)
	If lstrcmp(Receiver, @ClientNick) = 0 Then
		' Сообщение от пользователя
		If CInt(PrivateMessageEvent) Then
			PrivateMessageEvent(AdvancedClientData, UserName, MessageText)
		End If
	Else
		' Сообщение с канала
		If CInt(ChannelMessageEvent) Then
			ChannelMessageEvent(AdvancedClientData, Receiver, UserName, MessageText)
		End If
	End If
End Sub

Sub IrcClient.ProcessNotice(ByVal Receiver As WString Ptr, ByVal UserName As WString Ptr, ByVal MessageText As WString Ptr)
	If lstrcmp(Receiver, @ClientNick) = 0 Then
		' Уведомление от пользователя
		If CInt(NoticeEvent) Then
			NoticeEvent(AdvancedClientData, UserName, MessageText)
		End If
	Else
		' Уведомление с канала
		If CInt(ServerMessageEvent) Then
			ServerMessageEvent(AdvancedClientData, Receiver, MessageText)
		End If
	End If
End Sub

Function IsCtcpMessage(ByVal strMessageText As WString Ptr, ByVal MessageTextLength As Integer)As Boolean
	If MessageTextLength > 2 Then
		If strMessageText[0] = 1 Then
			If strMessageText[MessageTextLength - 1] = 1 Then
				Return True
			End If
		End If
	End If
	Return False
End Function

Function IrcClient.ParseData(ByVal strData As WString Ptr)As Boolean
	' Копия данных для сохранения оригинала
	Dim wStart As WString Ptr = strData
	
	' Первое слово
	Dim wServerWord As WString Ptr = wStart
	
	' Отделить первое слово в строке
	wStart = GetNextWord(wStart)
	
	Select Case GetServerWord(wServerWord)
		
		Case ServerWord.PingWord
			'PING :barjavel.freenode.net
			If CInt(PingEvent) Then
				' Понг не отправлять, это сделает сам клиент
				PingEvent(AdvancedClientData, GetIrcServerName(wStart))
			Else
				' Отправляем понг самостоятельно
				Return SendPong(GetIrcServerName(wStart))
			End If
			
		Case ServerWord.PongWord
			'PONG :barjavel.freenode.net
			If CInt(PongEvent) Then
				PongEvent(AdvancedClientData, GetIrcServerName(wStart))
			End If
			
		Case ServerWord.ErrorWord
			'ERROR :Closing Link: 89.22.170.64 (Client Quit)
			If CInt(ServerErrorEvent) Then
				ServerErrorEvent(AdvancedClientData, GetIrcMessageText(wStart))
			End If
			
			Return False
			
		Case Else
			
			' Имя пользователя, необходимо почти во всех событиях
			Dim strUserName As WString * (MaxBytesCount + 1) = Any
			GetIrcUserName(@strUserName, wServerWord)
			
			' Серверная команда (второе слово)
			Dim IrcCommand As WString Ptr = wStart
			wStart = GetNextWord(wStart)
			
			' Определяем команду
			Select Case GetServerCommand(IrcCommand)
				Case ServerCommand.PrivateMessage
					':Angel!wings@irc.org PRIVMSG Wiz :Are you receiving this message ?
					
					' Получатель сообщения
					Dim ircReceiver As WString Ptr = wStart
					wStart = GetNextWord(wStart)
			
					Dim strMessageText As WString Ptr = GetIrcMessageText(wStart)
					
					':Angel!wings@irc.org PRIVMSG Qubick :PING 1402355972
					':Angel!wings@irc.org PRIVMSG Qubick :VERSION
					':Angel!wings@irc.org PRIVMSG Qubick :TIME
					':Angel!wings@irc.org PRIVMSG Qubick :USERINFO
					
					Dim MessageTextLength As Integer = lstrlen(strMessageText)
					
					If IsCtcpMessage(strMessageText, MessageTextLength) Then
						strMessageText[MessageTextLength - 1] = 0
						wStart = GetNextWord(@strMessageText[1])
						
						Select Case GetCtcpCommand(@strMessageText[1])
							
							Case CtcpMessageType.Ping
								
								If CInt(CtcpPingRequestEvent) = 0 Then
									SendCtcpPingResponse(@strUserName, wStart)
								Else
									CtcpPingRequestEvent(AdvancedClientData, @strUserName, ircReceiver, wStart)
								End If
								
							Case CtcpMessageType.UserInfo
								If CInt(CtcpUserInfoRequestEvent) = 0 Then
									If ClientUserInfo <> 0 Then
										SendCtcpUserInfoResponse(@strUserName, ClientUserInfo)
									End If
								Else
									CtcpUserInfoRequestEvent(AdvancedClientData, @strUserName, ircReceiver)
								End If
								
							Case CtcpMessageType.Time
								If CInt(CtcpTimeRequestEvent) = 0 Then
									' Tue, 15 Nov 1994 12:45:26 GMT
									Const DateFormatString = "ddd, dd MMM yyyy "
									Const TimeFormatString = "HH:mm:ss GMT"
									Dim TimeValue As WString * 64 = Any
									Dim dtNow As SYSTEMTIME = Any
									
									GetSystemTime(@dtNow)
									
									Dim dtBufferLength As Integer = GetDateFormat(LOCALE_INVARIANT, 0, @dtNow, @DateFormatString, @TimeValue, 31) - 1
									GetTimeFormat(LOCALE_INVARIANT, 0, @dtNow, @TimeFormatString, @TimeValue[dtBufferLength], 31 - dtBufferLength)
									
									Return SendCtcpTimeResponse(@strUserName, @TimeValue)
								Else
									CtcpTimeRequestEvent(AdvancedClientData, @strUserName, ircReceiver)
								End If
								
							Case CtcpMessageType.Version
								If CInt(CtcpVersionRequestEvent) = 0 Then
									If ClientVersion <> 0 Then
										Return SendCtcpVersionResponse(@strUserName, ClientVersion)
									End If
								Else
									CtcpVersionRequestEvent(AdvancedClientData, @strUserName, ircReceiver)
								End If
								
							Case CtcpMessageType.Action
								If CInt(CtcpActionEvent) Then
									wStart = GetNextWord(@strMessageText[1])
									CtcpActionEvent(AdvancedClientData, @strUserName, ircReceiver, wStart)
								End If
								
							Case Else
								ProcessMessage(ircReceiver, @strUserName, strMessageText)
								
						End Select
					Else
						ProcessMessage(ircReceiver, @strUserName, strMessageText)
					End If
					
				Case ServerCommand.Notice
					':Angel!wings@irc.org NOTICE Wiz :Are you receiving this message ?
					':Angel!wings@irc.org NOTICE Qubick :PING 1402355972
					
					' Получатель сообщения
					Dim ircReceiver As WString Ptr = wStart
					wStart = GetNextWord(wStart)
					
					Dim strNoticeText As WString Ptr = GetIrcMessageText(wStart)
					
					Dim NoticeTextLength As Integer = lstrlen(strNoticeText)
					
					If IsCtcpMessage(strNoticeText, NoticeTextLength) Then
						strNoticeText[NoticeTextLength - 1] = 0
						wStart = GetNextWord(@strNoticeText[1])
						
						Select Case GetCtcpCommand(@strNoticeText[1])
							
							Case CtcpMessageType.Ping
								If CInt(CtcpPingResponseEvent) Then
									CtcpPingResponseEvent(AdvancedClientData, @strUserName, ircReceiver, wStart)
								End If
								
							Case CtcpMessageType.UserInfo
								If CInt(CtcpUserInfoResponseEvent) Then
									CtcpUserInfoResponseEvent(AdvancedClientData, @strUserName, ircReceiver, wStart)
								End If
								
							Case CtcpMessageType.Time
								If CInt(CtcpTimeResponseEvent) Then
									CtcpTimeResponseEvent(AdvancedClientData, @strUserName, ircReceiver, wStart)
								End If
								
							Case CtcpMessageType.Version
								If CInt(CtcpVersionResponseEvent) Then
									CtcpVersionResponseEvent(AdvancedClientData, @strUserName, ircReceiver, wStart)
								End If
								
							Case Else
								ProcessNotice(ircReceiver, @strUserName, strNoticeText)
								
						End Select
						
					Else
						ProcessNotice(ircReceiver, @strUserName, strNoticeText)
					End If
					
				Case ServerCommand.Join
					' Кто-то присоединился к каналу
					':Qubick!~Qubick@irc.org JOIN ##freebasic
					If CInt(UserJoinedEvent) Then
						UserJoinedEvent(AdvancedClientData, wStart, @strUserName)
					End If
					
				Case ServerCommand.Quit
					' Кто-то вышел
					If CInt(QuitEvent) Then
						QuitEvent(AdvancedClientData, @strUserName, GetIrcMessageText(wStart))
					End If
					
				Case ServerCommand.Invite
					' приглашение пользователя на канал
					' от кого INVITE кому канал
					':Angel!wings@irc.org INVITE Wiz #Dust
					If CInt(InviteEvent) Then
						Dim ircReceiver As WString Ptr = wStart
						' Канал на который зовут
						wStart = GetNextWord(wStart)
						InviteEvent(AdvancedClientData, @strUserName, wStart)
					End If
					
				Case ServerCommand.Kick
					' Удар по пользователю
					':WiZ!jto@tolsun.oulu.fi KICK #Finnish John
					'KICK message on channel #Finnish
					'from WiZ to remove John from channel
					If CInt(KickEvent) Then
						' Имя канала, с которого ударили
						Dim Channel As WString Ptr = wStart
						wStart = GetNextWord(wStart)
						' В wStart имя пользователя которого ударили
						KickEvent(AdvancedClientData, @strUserName, Channel, wStart)
					End If
					
				Case ServerCommand.Mode
					' Установка режима
					':ChanServ!ChanServ@services. MODE ##freebasic +v ssteiner
					' нужны данные: кто включил статус
					' кому включили статус
					' на каком канале включили статус
					' и текст строки
					If CInt(ModeEvent) Then
						' Кто изменил режим
						'ircData2 - канал
						Dim Channel As WString Ptr = wStart
						wStart = GetNextWord(wStart)
						
						'ircData3 - режим
						Dim Mode As WString Ptr = wStart
						wStart = GetNextWord(wStart)
						
						'ircData4 - кому установили режим
						
						ModeEvent(AdvancedClientData, @strUserName, Channel, wStart, Mode)
					End If
					
				Case ServerCommand.Nick
					' Кто-то сменил ник
					' В ircData2 содержится новый ник
					If CInt(NickChangedEvent) Then
						NickChangedEvent(AdvancedClientData, @strUserName, wStart)
					End If
					
				Case ServerCommand.Part
					' Пользователь покинул канал
					If CInt(UserLeavedEvent) Then
						UserLeavedEvent(AdvancedClientData, wStart, @strUserName, GetIrcMessageText(wStart))
					End If
					
				Case ServerCommand.Topic
					' Смена темы
					If CInt(TopicEvent) Then
						TopicEvent(AdvancedClientData, wStart, @strUserName, GetIrcMessageText(wStart))
					End If
					
				Case ServerCommand.SQuit
					' Выход оператора
					If CInt(QuitEvent) Then
						QuitEvent(AdvancedClientData, @strUserName, GetIrcMessageText(wStart))
					End If
					
				Case Else
					' Серверное сообщение
					If CInt(ServerMessageEvent) Then
						' IrcCommand — код сообщения
						' ник получателя
						Dim ircReceiver As WString Ptr = wStart
						wStart = GetNextWord(wStart)
						
						ServerMessageEvent(AdvancedClientData, IrcCommand, wStart)
					End If
					
			End Select
			
	End Select
	
	Return True
	
End Function
