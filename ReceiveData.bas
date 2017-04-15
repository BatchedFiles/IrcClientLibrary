#include once "Irc.bi"
#include once "windows.bi"
#include once "win\shlwapi.bi"

' Получение строки от сервера
Function IrcClient.ReceiveData(ByVal strReceiveData As WString Ptr)As ResultType
	' Ищем в буфере символы \r\n
	' Если они есть, то возвращаем строку до \r\n
	' иначе получаем данные, добавляя их в буфер, до тех пор, пока не появятся \r\n
	Dim wNewLine As WString Ptr = StrStr(@m_Buffer, @NewLineString)
	Do While wNewLine = 0
		' Проверить размер текущего накопительного буфера
		' Если он заполнен, то данные получать нельза
		If lstrlen(@m_Buffer) >= StaticBufferSize Then
			Return ResultType.BufferOverflow
		Else
			' Получаем данные
			Dim ReceiveBuffer As ZString * (MaxBytesCount + 1) = Any
			Dim intReceivedBytesCount As Integer = recv(m_Socket, @ReceiveBuffer, MaxBytesCount, 0)
			If intReceivedBytesCount > 0 Then
				Dim TempCodeReceiveBuffer As WString * (MaxBytesCount + 1) = Any
				ReceiveBuffer[intReceivedBytesCount] = 0 ' Теперь валидная строка для винапи
				' Преобразуем utf8 в WString
				' -1 — значит, длина строки будет проверяться самой функцией по завершающему нулю
				MultiByteToWideChar(CP_UTF8, 0, @ReceiveBuffer, -1, TempCodeReceiveBuffer, MaxBytesCount + 1)
				
				' Добавляем их в буфер и ищем \r\n
				wNewLine = StrStr(lstrcat(@m_Buffer, TempCodeReceiveBuffer), @NewLineString)
			Else
				' Ошибка, так как должно быть как минимум 1 байт на блокирующем сокете
				Return ResultType.SocketError
			End If
		End If
	Loop
	' Поставить ноль там, где найдены \r\n
	wNewLine[0] = 0
	' Получаем строку
	lstrcpyn(strReceiveData, @m_Buffer, MaxBytesCount)
	
	' Удаляем из буфера полученную строку вместе с символами переноса строки
	memmove(@m_Buffer, @wNewLine[2], StaticBufferSize + 1 - CInt(@m_Buffer - @wNewLine[2]))
	
	' Лог сообщений
	If CInt(ReceivedRawMessageEvent) Then
		ReceivedRawMessageEvent(ExtendedData, strReceiveData)
	End If
	Return ResultType.None
End Function