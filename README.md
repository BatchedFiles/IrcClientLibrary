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
		If objClient.ReceiveData(@strReceiveBuffer) <> ResultType.None Then
			Exit Do
		End If
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

Почти все методы объекта `IrcClient` возвращают значение типа `ResultType`. Если результат не равен `ResultType.None`, то рекомендуется закрыть соединение функцией `CloseIrc`.

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
End Enum
```


## Константы


### MaxBytesCount

Максимальное количество байт, которое можно отправить на сервер в одной строке. 

```FreeBASIC
Const MaxBytesCount As Integer = 512
```

Необходимо помнить, что длина строки измеряется в символах, а размер одного символа не всегда равен одному байту. Для кодировки UTF-8 размер одного символа может быть от одного до шести байт.


## Поля


### ExtendedData

Дополнительное поле для хранения указателя на любые данные. Этот указатель будет отправляться в каждом событии, генерируемом классом `IrcClient`.

```FreeBASIC
Dim ExtendedData As Any Ptr
```

### CodePage

Кодировка данных, используемая для преобразования байт в строку. Например: CP_UTF8, 1251. По умолчанию используется CP_UTF8.

```FreeBASIC
Dim CodePage As Integer
```


## Методы


### OpenIrc

Открывает соединение с сервером.

```FreeBASIC
Declare Function OpenIrc( _
	ByVal Server As WString Ptr, _
	ByVal Port As WString Ptr, _
	ByVal LocalServer As WString Ptr, _
	ByVal LocalPort As WString Ptr, _
	ByVal Password As WString Ptr, _
	ByVal Nick As WString Ptr, _
	ByVal User As WString Ptr, _
	ByVal Description As WString Ptr, _
	ByVal Visible As Boolean) _
As ResultType
```


#### Параметры

<dl>
<dt>Server</dt>
<dd>Имя сервера для соединения: доменное имя или IP‐адрес, например, chat.freenode.net.</dd>

<dt>Port</dt>
<dd>Строка, содержащая номер порта для соединения, например, 6667.</dd>

<dt>LocalServer</dt>
<dd>Локальный IP‐адрес, к которому будет привязан клиент и с которого будет идти соединение. Можно указать конкретный IP‐адрес сетевой карты, чтобы соединение шло через неё, или оставить пустой строкой, в таком случае операционная система сама выберет сетевую карту для подключения.</dd>

<dt>LocalPort</dt>
<dd>Локальный порт, к которому будет привязан клиент и с которго будет идти соединение. Если указан 0, то операционная система сама выберет свободный порт.</dd>

<dt>Password</dt>
<dd>Пароль на IRC‐сервер, если для соединения с сервером нужен пароль, иначе нужно оставить пустой строкой.</dd>

<dt>Nick</dt>
<dd>Ник (имя пользователя), не должен содержать пробелов и спец‐символов.</dd>

<dt>User</dt>
<dd>Строка‐идентификатор пользователя, обычно имя программы‐клиента, которым пользуются, не может содержать пробелов, не меняется в течение всего соединения.</dd>

<dt>Description</dt>
<dd>Строка‐описание пользователя, может содержать пробелы и спецсимволы, не меняется в течение всего соединения.</dd>

<dt>Visible</dt>
<dd>Флаг видимости для других пользователей.</dd>

</dl>


#### Описание

Если указан пароль на сервер, то функция создаёт строку подключения вида:

```
PASS password
NICK Paul
USER paul 8 * :Paul Mutton
```

Иначе строку подключения вида:

```
NICK Paul
USER paul 8 * :Paul Mutton
```

Затем инициализирует библиотеку сокетов, открывает соединение с сервером и отправляет строку подключения на сервер. Также функция устанавливает интервал ожидания чтения данных от сервера в течение десяти минут.


#### Возвращаемое значение

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.

Если функция завершается ошибкой, то закрывать соединение не требуется.


### ReceiveData

Получает данные от сервера.

```FreeBASIC
Declare Function ReceiveData(ByVal strReturnedString As WString Ptr)As ResultType
```


#### Параметры

<dl>
<dt>strReturnedString</dt>
<dd>Указатель на строку, куда будут записаны данные сервера. Размер буфера под строку должен быть не менее `MaxBytesCount` символов + 1 под нулевой, иначе возможно переполнение буфера.</dd>
</dl>


#### Описание

Функция ищет во внутреннем накопительном буфере комбинацию байтов 13 и 10, соответствующую символам перевода строки и возврата каретки. Если такая комбинация найдена, то все байты до неё преобразуются в строку в соответсткии с текущей кодировкой, записываются в `strReturnedString` и удаляются из накопительного буфера.

Если комбинация байтов 13 и 10 не найдена, то функция запрашивает `MaxBytesCount` байт с сервера за вычетом текущей длины накопительного буфера.

Если накопительный буфер заполнен, а комбинация байтов 13 и 10 не найдена, то весь буфер преобразовывается в строку, записывается `strReturnedString` и очищается.

Функция вызывает событие `ReceivedRawMessageEvent`.

Обычно функции `ReceiveData` и `ParseData` используют в цикле обработки сообщений:

```FreeBASIC
Dim strReceiveBuffer As WString * (IrcClient.MaxBytesCount + 1) = Any
Dim intResult As ResultType = Any

Do
	If objClient.ReceiveData(@strReceiveBuffer) <> ResultType.None Then
		Exit Do
	End If
	intResult = objClient.ParseData(@strReceiveBuffer)
Loop While intResult = ResultType.None

Client.CloseIrc()
```


#### Возвращаемое значение

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.

Если в течение десяти минут данные с сервера не будут получены, то функция завершается ошибкой. Это помогает завершать зависшие соединения.


### ParseData

Разбирает пришедшие с сервера данные и вызывает обработчики событий.

```FreeBASIC
Declare Function ParseData(ByVal strData As WString Ptr)As ResultType
```


#### Параметры

<dl>
<dt>strReceiveBuffer</dt>
<dd>Указатель на строку данных, полученную от сервера.</dd>
</dl>


#### Описание

Функция разбирает строку по шаблону и вызывает следующие события:

* ServerErrorEvent
* ServerMessageEvent
* NoticeEvent
* ChannelMessageEvent
* PrivateMessageEvent
* UserJoinedEvent
* UserLeavedEvent
* NickChangedEvent
* TopicEvent
* QuitEvent
* KickEvent
* InviteEvent
* PingEvent
* PongEvent
* ModeEvent
* CtcpMessageEvent
* CtcpNoticeEvent

Функция самостоятельно обрабатывает сообщения `PING` и отправляет на него сообщения `PONG`. Событие `PingEvent` вызывается только тогда, когда установлен обработчик события. В таком случае обработкой сообщений `PING` должен заниматься клиент самостоятельно, вызывая функцию `SendPong`.


#### Возвращаемое значение

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### CloseIrc

Закрывает соединение с сервером.

```FreeBASIC
Declare Sub CloseIrc()
```


#### Параметры

Функция не имеет параметров.


#### Описание

Функция немедленно закрывает соединение с сервером, без отправки сообщения `QUIT` о выходе из сети и освобождает ресурсы библиотеки сокетов. Функцию `CloseIrc` рекомендуется вызывать при любых ошибках сети и для освобождения ресурсов библиотеки сокетов.


#### Возвращаемое значение

Функция не возвращает значений.


### SendIrcMessage

Отправляет сообщение на канал или пользователю.

```FreeBASIC
Declare Function SendIrcMessage(ByVal strChannel As WString Ptr, ByVal strMessageText As WString Ptr)As ResultType
```


#### Параметры

<dl>
<dt>strChannel</dt>
<dd>Имя пользователя или канал. Если указан канал, то сообщение получат все пользователи, сидящие на канале. Если указано имя пользователя, то сообщение получит только этот пользователь.</dd>

<dt>strMessageText</dt>
<dd>Текст сообщения</dd>
</dl>


#### Описание

Функция в создаёт строку вида:

```
PRIVMSG target :Message Text
```

Где `target` — это канал или имя пользователя. Эта строка преобразуется в массив байт в соответствии с текущей кодировкой и отправляется на сервер.


#### Возвращаемое значение

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### SendNotice

Отправляет уведомление пользователю.

```FreeBASIC
Declare Function SendNotice(ByVal strChannel As WString Ptr, ByVal strNoticeText As WString Ptr)As ResultType
```

#### Параметры

<dl>
<dt>strChannel</dt>
<dd>Имя пользователя, получателя уведомления.</dd>

<dt>strNoticeText</dt>
<dd>Текст уведомления.</dd>
</dl>


#### Описание

Функция создаёт строку вида:

```
NOTICE target :Notice Text
```

Где `target` — это имя пользователя. Эта строка преобразуется в массив байт в соответствии с текущей кодировкой и отправляется на сервер.

Уведомление аналогично сообщению с тем отличием, что на него не следует отвечать автоматически.


#### Возвращаемое значение

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### ChangeTopic

Устанавливает, удаляет или получает тему канала.

```FreeBASIC
Declare Function ChangeTopic(ByVal strChannel As WString Ptr, ByVal strTopic As WString Ptr)As ResultType
```


#### Параметры

<dl>
<dt>strChannel</dt>
<dd>Канал для установки или запроса темы.</dd>

<dt>strNoticeText</dt>
<dd>Текст темы.</dd>
</dl>


#### Описание

Если `strTopic` — нулевой указатель `NULL`, то на сервер отправляется строка:

```
Topic
```

В ответ сервер отправит тему канала. Сервер ответит кодами `RPL_TOPIC`, если тема существует, или `RPL_NOTOPIC`, если тема не установлена.

Если `strTopic` — указатель на пустую строку, на сервер отправляется строка:

```
Topic :
```

В этом случае сервер удалит тему канала.

Иначе на сервер отправляется строка:

```
Topic :strTopic
```

В этом случае сервер установит тему канала, указанную в `strTopic`.


#### Возвращаемое значение

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.

















### QuitFromServer

Отправляет на сервер сообщение о выходе с сервера, что вынуждает сервер закрыть соединение.

Параметры:

`strMessageText` — текст прощального сообщения. Необязателен.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### ChangeNick

Меняет ник пользователя.

Параметры:

`Nick` — новый ник.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


















### JoinChannel

Присоединяет пользователя к каналу или каналам.

Параметры:

`strChannel` — список каналов, разделённый запятыми без пробелов. Если на канале установлен пароль, то через пробел указываются пароли для входа, разделённые запятыми без пробелов.

Пример:

```FreeBASIC
' Присоединение к каналам
Client.JoinChannel("#freebasic,#freebasic-ru")

' Присоединение к каналам с указанием для первого канала пароля
Client.JoinChannel("#freebasic,#freebasic-ru password1")
```

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### PartChannel

Отключает пользователя от канала.

Параметры:

`strChannel` — канал для выхода.

`strMessageText` — прощальное сообщение. Необязательно.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### SendRawMessage

Отправляет «сырые» данные, то есть как они есть.

Параметры:

`strRawText` — данные.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### SendPong

Отправляет сообщение PONG.

Параметры:

`strServer` — сервер, к которому подключён клиент.

Сервер отправляет сообщения PING для проверки подключённости пользователя. Если пользователь вовремя не ответит сообщением PONG, то сервер закроет соединение. Обычно отправка PONG вручную не требуется, так как это берёт на себя библиотека.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### SendPing

Отправляет сообщение PING.

Параметры:

`strServer` — сервер, к которому подключён клиент.

На сообщение PING сервер ответит сообщением PONG.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### SendCtcpMessage

Отправляет CTCP‐сообщение.

Параметры:

`strChannel` — получатель сообщения: имя канала канала или пользователя.

`iType` — тип сообщения.

`Param` — параметр, для разных типов сообщения имеет разное значение.

CTCP‐сообщения — это 


#### iType

Харастеризует тип CTCP‐сообщения. В настоящий момент библиотека обрабатывает следующие значения:

`Ping` — проверка активности пользователя. В `Param` необходимо указать какое‐нибудь число, которое получатель отправит обратно отправителю, чтобы по разнице времени отправки и прибытия вычислить задержку сообщений.

`Time` — запрашивается локальное время пользователя. `Param` игнорируется.

`UserInfo` — запрашивается информация о пользователе. `Param` игнорируется.

`Version` — запрашивается версия клиента. `Param` игнорируется.

`Action` — отправляемое сообщение показывается так, будто оно сказано от первого лица. В большинстве клиентов CTCP Action реализуется через команду «/me». В `Param` необходимо указать текст сообщения.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.


### SendCtcpNotice

Отправляет ответ на CTCP запрос. Эту функцию обычно вызывают в событии `f`.

Параметры:

`strChannel` — получатель сообщения: имя канала канала или пользователя.

`iType` — тип сообщения.

`NoticeText` — текст ответа.


#### iType

Может принимать одно из следующих значений:

`Ping` — ответ на PING пользователя. В `NoticeText` необходимо число, которое пришло.

`Time` — запрашивается локальное время пользователя. В `NoticeText` необходимо отправить локальное время пользователя.

`UserInfo` — запрашивается информация о пользователе. В `NoticeText` необходимо указать данные пользователя.

`Version` — запрашивается версия клиента. В `NoticeText` необходимо указать версию программы.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.
	
	
## События
