#include once "AsmIrc.bi"

' Получение строки от сервера
Public Function IrcClient.ReceiveData(ByVal strReceiveData As WString Ptr)As ResultType
	' Ищем в буфере символы \r\n
	' Если они есть, то возвращаем строку до \r\n
	' иначе получаем данные и добавляем их в буфер
	Dim w As WString Ptr = StrStr(m_Buffer, NewLineString)
	Do While w = 0
		Dim ReceiveBuffer As ZString * (MaxBytesCount + 1) = Any
		
		' Проверить размер текущего накопительного буфера
		' Если он заполнен, то данные получать нельза
		If lstrlen(m_Buffer) >= StaticBufferSize Then
			Return ResultType.BufferOverflow
		Else
			' Получаем данные
			Dim intReceivedBytesCount As Integer = recv(m_Socket, ReceiveBuffer, MaxBytesCount, 0)
			If intReceivedBytesCount > 0 Then
				Dim TempCodeReceiveBuffer As WString * (MaxBytesCount + 1) = Any
				ReceiveBuffer[intReceivedBytesCount] = 0 ' Теперь валидная строка для винапи
				' Преобразуем utf8 в WString
				' -1 — значит, длина строки будет проверяться самой функцией по завершающему нулю
				MultiByteToWideChar(CP_UTF8, 0, @ReceiveBuffer, -1, TempCodeReceiveBuffer, MaxBytesCount + 1)
				
				lstrcat(m_Buffer, TempCodeReceiveBuffer)
				w = StrStr(m_Buffer, NewLineString)
			Else
				' Ошибка, так как должно быть как минимум 1 байт на блокирующем сокете
				Return ResultType.SocketError
			End If
		End If
	Loop
	' Поставить ноль там, где найдены \r\n
	(*w)[0] = 0
	' Получаем строку
	' Исходя из предположения, что строка до \r\n вмещается в принимающий буфер
	lstrcpy(strReceiveData, m_Buffer)
	
	' Удаляем из буфера полученную строку вместе с символами переноса строки
	
	' Временный буфер
	Dim TempBuffer As WString * (StaticBufferSize + 1) = Any
	' Скопировать туда
	lstrcpy(TempBuffer, w[2])
	' Скопировать обратно
	lstrcpy(m_Buffer, TempBuffer)
	
	' Лог сообщений
	If CInt(ReceivedRawMessageEvent) Then
		ReceivedRawMessageEvent(ExtendedData, *strReceiveData)
	End If
	Return ResultType.None
End Function