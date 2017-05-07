# IrcClientLibrary #

Клиентская библиотека для работы с протоколом IRC. Инкапсулирует в себе низкоуровневую работу с сокетами, приём и отправку сообщений, автоматические ответы на пинг от сервера. Пригодна для создания ботов, клиентских программ и для работы с IRC‐протоколом.

Библиотека использует синхронную событийную модель функций обратного вызова. Каждое пришедшее сообщение от сервера разбирается по шаблонам, вызывая соответствующие обработчики событий.

Функции библиотеки инкапсулированы в класс `IrcClient`.

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
Const Password = ""
' Ник бота
Const Nick = "LeoFitz"
' Юзер‐строка, необходима для идентификации
Const UserString = "LeoFitz"
' Описание бота
Const Description = "IRC bot written in FreeBASIC"
' IP‐адрес и порт, с которых будут идти соединения с сервером
Const LocalAddress = "0.0.0.0"
Const LocalPort = "0"
```

Основной код:

```FreeBASIC
' Создаём объект для работы с IRC
Dim Shared objClient As IrcClient

' Установливаем обработчики событий
With objClient
	.ServerMessageEvent = @ServerMessage
	.PrivateMessageEvent = @IrcPrivateMessage
End With

' Открываем соединение с сервером
' Параметры:
' Сервер, порт, локальный адрес, локальный порт, пароль на сервер, ник, юзер‐строка, описание, режим видимости
If objClient.OpenIrc(Server, Port, LocalAddress, LocalPort, Password, Nick, UserString, Description, False) = ResultType.None Then
	' Всё идёт по плану
	' Входим в бесконечный цикл получения данных от сервера
	Do
	Loop While objClient.GetData() = ResultType.None
	' Закрыть
	objClient.CloseIrc()
End If

' Любое серверное сообщение
Public Function ServerMessage(ByVal AdvData As Any Ptr, ByVal ServerCode As WString Ptr, ByVal MessageText As WString Ptr)As ResultType
	If *ServerCode = RPL_WELCOME Then
		' Сервер приветствует нас
		' Присоединиться к каналу
		objClient.JoinChannel("##freebasic-ru")
		' Отправить сообщение на канал
		objClient.SendIrcMessage("##freebasic-ru", "Всем привет!")
	End If
	Return ResultType.None
End Function
```

## Перечисления ##

### ResultType ###

Большинство функций объекта `Ircclient` возвращают значение `ResultType`.

```FreeBASIC
' Результат выполнения запроса приёма отправки данных
Enum ResultType
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
End Enum
```

### CtcpMessageType ###

Перечисление `CtcpMessageType` необходимо в CTCP‐сообщениях.

```FreeBASIC
' Тип сообщения CTCP
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

## Поля ##

### ExtendedData As Any Ptr ###

Дополнительное поле для хранения указателя на любые данные, указанные пользователем. Этот указатель будет отправляться в каждом событии, генерируемом классом IrcClient.

## Методы ##

Declare Function OpenIrc(ByVal Server As WString Ptr, _
ByVal Port As WString Ptr, _
ByVal LocalServer As WString Ptr, _
ByVal LocalPort As WString Ptr, _
ByVal Password As WString Ptr, _
ByVal Nick As WString Ptr, _
ByVal User As WString Ptr, _
ByVal Description As WString Ptr, _
ByVal Visible As Boolean)As ResultType


	<table>

	<tr>
	<td>OpenIrc(ByRef Server As WString, ByRef Port As WString, ByRef Password As WString, ByRef Nick As WString, ByRef User As WString, ByRef Description As WString, ByVal Visible As Boolean)As ResultType</td>
	<td><p>Открывает соединение с IRC‐сервером. Параметры:</p>
	<ul>
	<li>Server — имя сервера (доменное имя, например, chat.freenode.net) для соединения;</li>
	<li>Port — строка, содержащая номер порта для соединения, например, 6667;</li>
	<li>Password — пароль, если для соединения с сервером нужен пароль, иначе можно оставить пустой строкой;</li>
	<li>Nick — ник (имя пользователя), не должен содержать пробелов и спец‐символов;</li>
	<li>User — юзер‐строка, некий идентификатор пользователя (обычно имя программы‐клиента, которым пользуется пользователь), не должен содержать пробелов, не может быть изменена в течение всего соединения;</li>
	<li>Description — описание пользователя, может содержать пробелы и спецсимволы, не может быть изменено в течение всего соединения;</li>
	<li>Visible — флаг видимости для других пользователей.</li>
	</ul>
	<p>Возвращает значение типа ResultType, по которому можно определить код ошибки.</p></td>
	</tr>

	<tr>
	<td>GetData()As ResultType</td>
	<td>Ожидание получения данных от сервера и запуск обработки. Возвращает значение типа ResultType, по которому можно определить код ошибки.</td>
	</tr>


	<tr>
	<td>CloseIrc()</td>
	<td>Убивает соединение с сервером. Приём данных с сервера прекращается.</td>
	</tr>

	<tr>
	<td>SendIrcMessage(ByRef strChannel As WString, ByRef strMessageText As WString)As ResultType</td>
	<td>Отправляет сообщение пользователю. strChannel может быть именем пользователя или канала. Если strChannel — это имя пользователя, то отправляется сообщение, которое доступно только этому пользователю, если strChannel — это имя канала, то сообщение отправится в канал и будет доступно всем, сидящим на канале. strMessageText — текст сообщения. Возвращает значение типа ResultType, по которому можно определить код ошибки.</td>
	</tr>

	<tr>
	<td>SendNotice(ByRef strChannel As WString, ByRef strNoticeText As  WString)As ResultType</td>
	<td>Отправляет уведомление пользователю или на канал. Уведомление аналогично личному сообщению с той разницей, что на него не требуется отвечать. Возвращает значение типа ResultType, по которому можно определить код ошибки.</td>
	</tr>

	<tr>
	<td>ChangeTopic(ByRef strChannel As WString, ByRef strTopic As WString)As ResultType</td>
	<td>Устанавливает тему канала. Возвращает значение типа ResultType, по которому можно определить код ошибки.</td>
	</tr>

	<tr>
	<td>QuitFromServer(ByRef strMessageText As WString)As ResultType</td>
	<td>Выходит из IRC‐сети. В качестве прощального сообщения можно установить strMessageText. Возвращает значение типа ResultType, по которому можно определить код ошибки.</td>
	</tr>

	<tr>
	<td>ChangeNick(ByRef Nick As WString)As ResultType</td>
	<td>Меняет ник текущего пользователя. Возвращает значение типа ResultType, по которому можно определить код ошибки.</td>
	</tr>

	<tr>
	<td>JoinChannel(ByRef strChannel As WString)As ResultType</td>
	<td>Присоединяет к каналу. Имя канала должно начинаться с символов «&amp;», «#», «+» или «!», но обычно это «#», длина строки с именем не должна превышать 50 символов. Если канал до этого не существовал, он будет создан. Возвращает значение типа ResultType, по которому можно определить код ошибки.</td>
	</tr>

	<tr>
	<td>PartChannel(ByRef strChannel As  WString, ByRef strMessageText As WString)As ResultType</td>
	<td>Покидает канал. В качестве прощального сообщения можно установить strMessageText. Возвращает значение типа ResultType, по которому можно определить код ошибки.</td>
	</tr>

	<tr>
	<td>SendCtcpMessage(ByRef strChannel As  WString, ByVal iType As CtcpMessageType, ByRef Param As WString)As ResultType</td>
	<td>Отправка CTCP‐запроса. Возвращает значение типа ResultType, по которому можно определить код ошибки.</td>
	</tr>

	<tr>
	<td>SendCtcpNotice(ByRef strChannel As  WString, ByVal iType As CtcpMessageType, ByRef NoticeText As WString)As ResultType</td>
	<td>Отправка CTCP‐ответа. Возвращает значение типа ResultType, по которому можно определить код ошибки.</td>
	</tr>

	<tr>
	<td>SendRawMessage(ByRef strRawText As WString)As ResultType</td>
	<td>Отправляет сырую IRC‐команду. Возвращает значение типа ResultType, по которому можно определить код ошибки.</td>
	</tr>

	</table>

<h3>События IrcClient</h3>

-->
