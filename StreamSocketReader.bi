#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "win\winsock2.bi"

Type StreamSocketReader
	' Максимальный размер буфера
	Const MaxBufferLength As Integer = 16 * 1024 - 1
	
	' Клиентский сокет
	Dim ClientSocket As SOCKET
	' Буфер данных
	Dim Buffer As ZString * (MaxBufferLength + 1)
	' Количество данных в буфере
	Dim BufferLength As Integer
	' Индекс начала необработанных данные в буфере
	Dim Start As Integer
	
	' Инициализация
	Declare Sub Initialize()
	
	' Чтение данных из сокета и возвращение строки
	' Возвращает длину полученной строки без учёта нулевого символа
	Declare Function ReadLine(ByVal wLine As WString Ptr, ByVal nLineBufferLength As Integer)As Integer
	
	' Удаляет обработанные данные из буфера
	Declare Sub Flush()
	
Private:
	
	' Поиск символов CrLf в буфере
	Declare Function FindCrLfA()As Integer
	
End Type
