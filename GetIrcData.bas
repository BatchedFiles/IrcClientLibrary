#include once "Irc.bi"

' Двоеточие
Const ColonChar As Integer = &h003A
' Восклицательный знак
Const ExclamationChar As Integer = &h0021

' Получаем имя пользователя
Sub GetIrcUserName(ByVal strReturn As WString Ptr, ByVal strData As WString Ptr)
	':Qubick!~miranda@192.168.1.1 JOIN ##freebasic
	
	Dim Start As Integer = Any
	If strData[0] = ColonChar Then
		Start = 1
	Else
		Start = 0
	End If
	
	' Скопировать без учёта начального двоеточия
	lstrcpy(strReturn, @strData[Start])
	
	' Найти знак "!" и удалить
	Dim w As WString Ptr = StrChr(strReturn, ExclamationChar)
	If w <> 0 Then
		w[0] = 0
	End If
	
End Sub

' Получаем текст сообщения
Sub GetIrcMessageText(ByVal strReturn As WString Ptr, ByVal strData As WString Ptr)
	':Qubick!~miranda@192.168.1.1 PRIVMSG ##freebasic :Hello World
	
	If strData[0] <> ColonChar Then
		strReturn[0] = 0
	Else
		' Вернуть всё, что после второго двоеточия
		
		Dim w As WString Ptr = StrChr(@strData[1], ColonChar)
		If w = 0 Then
			' Не найдено
			strReturn[0] = 0
		Else
			lstrcpy(strReturn, @w[1])
		End If
	End If
	
End Sub

' Получаем имя сервера
Sub GetIrcServerName(ByVal strReturn As WString Ptr, ByVal strData As WString Ptr)
	' Найти двоеточие в строке
	Dim w As WString Ptr = StrChr(strData, ColonChar)
	If w = 0 Then
		' Не найдено
		strReturn[0] = 0
	Else
		lstrcpy(strReturn, @w[1])
	End If
	
End Sub

' Определяем первое слово сервера
Function GetServerWord(ByVal w As WString Ptr)As ServerWord
	If lstrcmp(w, @IrcClient.PingString) = 0 Then
		Return ServerWord.PingWord
	End If
	If lstrcmp(w, @IrcClient.PongString) = 0 Then
		Return ServerWord.PongWord
	End If
	If lstrcmp(w, @IrcClient.ErrorString) = 0 Then
		Return ServerWord.ErrorWord
	End If
	
	Return ServerWord.ElseWord
End Function

' Определяем команду
Function GetServerCommand(ByVal w As WString Ptr)As ServerCommand
	If lstrcmp(w, @IrcClient.PrivateMessage) = 0 Then
		Return ServerCommand.PrivateMessage
	End If
	If lstrcmp(w, @IrcClient.NoticeString) = 0 Then
		Return ServerCommand.Notice
	End If
	If lstrcmp(w, @IrcClient.JoinString) = 0 Then
		Return ServerCommand.Join
	End If
	If lstrcmp(w, @IrcClient.QuitString) = 0 Then
		Return ServerCommand.Quit
	End If
	If lstrcmp(w, @IrcClient.InviteString) = 0 Then
		Return ServerCommand.Invite
	End If
	If lstrcmp(w, @IrcClient.KickString) = 0 Then
		Return ServerCommand.Kick
	End If
	If lstrcmp(w, @IrcClient.ModeString) = 0 Then
		Return ServerCommand.Mode
	End If
	If lstrcmp(w, @IrcClient.NickString) = 0 Then
		Return ServerCommand.Nick
	End If
	If lstrcmp(w, @IrcClient.PartString) = 0 Then
		Return ServerCommand.Part
	End If
	If lstrcmp(w, @IrcClient.SQuitString) = 0 Then
		Return ServerCommand.SQuit
	End If
	If lstrcmp(w, @IrcClient.TopicString) = 0 Then
		Return ServerCommand.Topic
	End If
	
	Return ServerCommand.Server
End Function
