#include once "AsmIrc.bi"

' Получаем имя пользователя
Public Sub IrcClient.GetIrcUserName(ByVal strReturn As WString Ptr, ByRef strData As WString)
	':Qubick!~miranda@192.168.1.1 JOIN ##freebasic
	lstrcpy(strReturn, @strData[1]) ' Скопировать в строку без учёта начального двоеточия
	Dim w As WString Ptr = StrStr(strReturn, "!") ' Найти знак "!"
	If w = 0 Then
		' Если не найдено, то имя пользователя будет пустым
		strReturn[0] = 0
	Else
		(*w)[0] = 0 ' Записать на его место ноль
	End If
End Sub

' Получаем текст сообщения
Public Sub IrcClient.GetIrcMessageText(ByVal strReturn As WString Ptr, ByRef strData As WString)
	' Найти счёту двоеточие в строке, начиная со второго символа
	Dim w As WString Ptr = StrStr(@strData[1], CommaSeparatorString)
	If w = 0 Then
		' Не найдено
		strReturn[0] = 0
	Else
		lstrcpy(strReturn, w[1]) ' Получить строку после двоеточия
	End If
End Sub

' Получаем имя сервера
Public Sub IrcClient.GetIrcServerName(ByVal strReturn As WString Ptr, ByRef strData As WString)
	' Найти счёту двоеточие в строке, начиная со второго символа
	Dim w As WString Ptr = StrStr(@strData[1], CommaSeparatorString)
	If w = 0 Then
		' Не найдено
		strReturn[0] = 0
	Else
		lstrcpy(strReturn, w[1]) ' Получить строку после двоеточия
	End If
End Sub
