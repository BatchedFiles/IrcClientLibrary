# IrcClientLibrary

Клиентская библиотека для работы с протоколом IRC. Инкапсулирует в себе низкоуровневую работу с сокетами, приём и отправку сообщений, автоматические ответы на пинг от сервера. Пригодна для создания ботов, клиентских программ и для работы с IRC‐протоколом.

Библиотека использует синхронную событийную модель функций обратного вызова. Каждое пришедшее сообщение от сервера разбирается по шаблонам, вызывая соответствующие обработчики событий.

Функции библиотеки инкапсулированы в класс `IrcClient`.


## Компиляция

```Batch
fbc -lib Irc.bas SendData.bas ReceiveData.bas ParseData.bas GetIrcData.bas SendMessages.bas Network.bas
```


## Быстрый старт

Этот пример показывает как легко создать соединение с сервером IRC, зайти на канал и отправить сообщение.

Подключаем заголовочные файлы:

```FreeBASIC
#include once "Irc.bi"
#include once "IrcEvents.bi"
#include once "IrcReplies.bi"
```

Определяем параметры подключения к серверу:

```FreeBASIC
' Имя сервера
Const Server = "chat.freenode.net"
' Порт
Const Port = "6667"
' Пароль на соединение с сервером, в данном случае пуст
Const ServerPassword = ""
' Ник бота
Const Nick = "LeoFitz"
' Юзер‐строка, необходима для идентификации
Const UserString = "LeoFitz"
' Описание бота
Const Description = "IRC bot written in FreeBASIC"
' IP‐адрес и порт, с которых будут идти соединения с сервером
Const LocalAddress = "0.0.0.0"
Const LocalPort = "0"
Const Channel = "##freebasic-ru"
```

Основной код:

```FreeBASIC
' Создаём объект для работы с IRC
Dim Shared Client As IrcClient

' Кодировка
Client.CodePage = CP_UTF8

' Установливаем обработчики событий
Client.ServerMessageEvent = @ServerMessage
Client.PrivateMessageEvent = @IrcPrivateMessage

' Открываем соединение с сервером
' Параметры:
' Сервер, порт, локальный адрес, локальный порт, пароль на сервер, ник, юзер‐строка, описание, режим видимости
If Client.OpenIrc(Server, Port, LocalAddress, LocalPort, ServerPassword, Nick, UserString, Description, False) = ResultType.None Then
	' Всё идёт по плану
	
	Dim strReceiveBuffer As WString * (IrcClient.MaxBytesCount + 1) = Any
	Dim intResult As ResultType = Any
	
	' Бесконечный цикл получения данных от сервера до тех пор, пока не будет ошибок
	Do
		intResult = objClient.ReceiveData(@strReceiveBuffer)
		intResult = objClient.ParseData(@strReceiveBuffer)
	Loop While intResult = ResultType.None
	
	' Закрыть
	Client.CloseIrc()
End If

' Любое серверное сообщение
Function ServerMessage(ByVal AdvData As Any Ptr, ByVal ServerCode As WString Ptr, ByVal MessageText As WString Ptr)As ResultType
	If *ServerCode = RPL_WELCOME Then
		' Сервер приветствует нас
		' Присоединиться к каналу
		Client.JoinChannel(Channel)
		' Отправить сообщение на канал
		Client.SendIrcMessage(Channel, "Всем привет!")
	End If
	Return ResultType.None
End Function

' Личное сообщение
Function IrcPrivateMessage(ByVal AdvData As Any Ptr, ByVal User As WString Ptr, ByVal MessageText As WString Ptr)As ResultType
	' Команда от админа
	If *User = AdminNick Then
		Dim intMemory As UInteger = Fre()
		objClient.SendIrcMessage(AdminNick, "Количество свободной памяти в байтах = " & WStr(intMemory))
	End If
	Return ResultType.None
End Function
```


## Перечисления


### ResultType

Большинство функций объекта `Ircclient` возвращают значение `ResultType`.

```FreeBASIC
Enum ResultType
	' Ошибки нет
	None
	' Ошибка инициализации библиотеки сокетов
	WSAError
	' Ошибка сети
	SocketError
	' Ошибка IRC‐сервера
	ServerError
	' Пользователь отменил обработку данных
	UserCancel
End Enum
```


### CtcpMessageType

Перечисление `CtcpMessageType` необходимо в CTCP‐сообщениях.

```FreeBASIC
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
```


## Поля


### ExtendedData As Any Ptr

Дополнительное поле для хранения указателя на любые данные. Этот указатель будет отправляться в каждом событии, генерируемом классом `IrcClient`.


### CodePage

Кодировка данных, используемая для преобразования байт в строку. Например: CP_UTF8, 1251.


## Методы

Почти все методы возвращают значение типа `ResultType`. Если результат не равен `ResultType.None`, то рекомендуется закрыть соединение функцией `CloseIrc`.


### OpenIrc

```FreeBASIC
Declare Function OpenIrc(ByVal Server As WString Ptr, _
ByVal Port As WString Ptr, _
ByVal LocalServer As WString Ptr, _
ByVal LocalPort As WString Ptr, _
ByVal Password As WString Ptr, _
ByVal Nick As WString Ptr, _
ByVal User As WString Ptr, _
ByVal Description As WString Ptr, _
ByVal Visible As Boolean)As ResultType
```

Функция создаёт строку подключения, инициализирует библиотеку сокетов, открывает соединение с сервером и отправляет строку подключения на сервер. Также функция устанавливает интервал ожидания на чтение данных от сервера в течение минут.

Параметры:

`Server` — имя сервера для соединения (доменное имя или IP‐адрес, например, chat.freenode.net).

`Port` — строка, содержащая номер порта для соединения, например, 6667.

`LocalServer` — локальный IP‐адрес, к которому будет привязан клиент и с которого будет идти соединение, например, 0.0.0.0.

`LocalPort` — локальный порт, к которому будет привязан клиент и с которго будет идти соединение, например, 0.

`Password` — пароль на IRC‐сервер, если для соединения с сервером нужен пароль, иначе можно оставить пустой строкой.

`Nick` — ник (имя пользователя), не должен содержать пробелов и спец‐символов.

`User` — строка‐идентификатор пользователя, обычно имя программы‐клиента, которым пользуются, не может содержать пробелов, не меняется в течение всего соединения.

`Description` — строка‐описание пользователя, может содержать пробелы и спецсимволы, не меняется в течение всего соединения.

`Visible` — флаг видимости для других пользователей.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### ReceiveData

Получает данные от сервера. Если в течение десяти минут данные не будут получены, то функция завершается ошибкой.

Параметры:

`strReturnedString` — указатель на строку, куда будут записаны данные сервера. Размер буфера под строку должен быть не менее IrcClient.MaxBytesCount символов + 1 под нулевой.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### ParseData

Разбирает пришедшие с сервера данные и вызывает обработчики событий.

Параметры:

`strReceiveBuffer` — указатель на строку данных сервера. Размер строки должен быть не менее IrcClient.MaxBytesCount символов + 1 под нулевой

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### CloseIrc

Закрывает соединение с сервером. Приём данных с сервера прекращается. Сообщение о выходе не отправляется.

Функция не возвращает значений.


### SendIrcMessage

Отправляет сообщение на канал или личное сообщение пользователю.

Параметры:

`strChannel` — пользователь или канал.

`strMessageText` — текст сообщения.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### SendNotice

Отправляет уведомление пользователю.

Параметры:

`strChannel` — имя пользователя.

`strNoticeText` — текст уведомления.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### ChangeTopic

Устанавливает тему канала.

Параметры:

`strChannel` — канал.

`strTopic` — новая тема.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### QuitFromServer

Отправляет на сервер сообщение о выходе с сервера, что вынуждает сервер закрыть соединение.

Параметры:

`strMessageText` — текст прощального сообщения. Необязателен.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.

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
	' Отправка сообщения PONG
	Declare Function SendPong(ByVal strServer As WString Ptr)As ResultType
	' Отправка сообщения PING
	Declare Function SendPing(ByVal strServer As WString Ptr)As ResultType
	' Отправка сырого сообщения
	Declare Function SendRawMessage(ByVal strRawText As WString Ptr)As ResultType
	
	

