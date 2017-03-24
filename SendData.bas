#include once "AsmIrc.bi"

' Отправка строки на сервер
Function IrcClient.SendData(ByVal strData As WString Ptr)As ResultType
	' Добавляем перевод строки для данных
	Dim strDataWithNewLine As WString * (MaxBytesCount + 1) = Any
	lstrcat(lstrcpyn(@strDataWithNewLine, strData, MaxBytesCount - 2), @NewLineString)
	
	' Перекодируем в байты utf8
	' Отправляем intBytesCount - 1, чтобы не отправлять нулевой символ в конце
	Dim SendBuffer As ZString * (MaxBytesCount + 1) = Any
	If send(m_Socket, @SendBuffer, WideCharToMultiByte(CP_UTF8, 0, @strDataWithNewLine, -1, @SendBuffer, (MaxBytesCount + 1), 0, 0) - 1, 0) = SOCKET_ERROR Then
		' Ошибка
		Return ResultType.SocketError
	Else
		' Лог сообщений
		If CInt(SendedRawMessageEvent) Then
			SendedRawMessageEvent(ExtendedData, strData)
		End If
		Return ResultType.None
	End If
End Function