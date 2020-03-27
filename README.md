# IrcClientLibrary

Клиентская библиотека для работы с протоколом IRC. Инкапсулирует низкоуровневую работу с сокетами, приём и отправку сообщений, автоматические ответы на пинг от сервера. Пригодна для создания ботов, клиентских программ и мессенджеров для работы с IRC‐протоколом.

Библиотека использует синхронную событийную модель функций обратного вызова. Каждое пришедшее сообщение от сервера разбирается по шаблонам, вызывая соответствующие обработчики событий.

Функции библиотеки работают со структурой `IrcClient`.


## Компиляция

```Batch
make.cmd
```


## Быстрый старт

Этот пример консольного приложения показывает как создать соединение с сервером IRC, зайти на канал и отправить сообщение в приват.

```FreeBASIC
#include "IrcClient.bi"

Dim Shared Client As IrcClient

Sub IrcPrivateMessage( _
		ByVal AdvData As Any Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal MessageText As WString Ptr _
	)
	
	SendIrcMessage(@Client, UserName, "Hello chat!")
	
End Sub

Client.lpfnPrivateMessageEvent = @IrcPrivateMessage

If OpenIrc(@Client, "chat.freenode.net", "LeoFitz") Then
	
	JoinChannel(@Client, "#freebasic-ru")
	
	IrcClientStartReceiveDataLoop(@Client)
	
End If

```

Функция `WaitForSingleObjectEx` используется для остановки текущего потока и вызова асинхронных операций чтения‐записи.

В оконных приложениях вместо функции `WaitForSingleObjectEx` необходимо использовать `MsgWaitForMultipleObjectsEx`.


## Константы


### MaxBytesCount

Максимальное количество байт, которое можно отправить на сервер в одной строке.

```FreeBASIC
Const MaxBytesCount As Integer = 512
```

Длина строки измеряется в символах, а размер одного символа не всегда равен одному байту. Для кодировки UTF-8 размер одного символа может быть от одного до шести байт.


### DefaultServerPort

Стандартный порт по умолчанию для соединения с сервером.

```FreeBASIC
Const DefaultServerPort As Integer = 6667
```


## Поля


### AdvancedClientData

Дополнительное поле для хранения указателя на любые данные. Этот указатель будет отправляться в каждом событии, генерируемом классом `IrcClient`.

```FreeBASIC
Dim AdvancedClientData As Any Ptr
```

### CodePage

Номер кодировочной таблицы, используемой для преобразования байт в строку.

```FreeBASIC
Dim CodePage As Integer
```

В стандарте IRC‐протокола не определено, каким образом строки будут преобразовываться в байты, эта задача возлагается на самого клиента. Клиент для преобразования строк использует кодировочную таблицу. Например: 65001 (UTF-8), 1251 (кодировка Windows для кириллицы), 866 (кодировка DOS для кириллицы), 20866 (KOI8-R), 21866 (KOI8-U).

Библиотека использует кодировку UTF-8 по умолчанию (65001).

Нельзя использовать кодировки, в символах которых присутствуют нули. Например: UTF-16 (1200), UTF-16 BE (1201). Нули в данном случае будут интерпретироваться как символ с кодом 0, что в большинстве случаев означает конец последовательности символов. IRC‐протокол накладывает ограничение на использование нулевого символа.


### ClientVersion

Версия используемой программы. Если установлена, то будет отправлена серверу на CTCP‐запрос `VERSION`.

```FreeBASIC
Dim ClientVersion As WString Ptr
```


### ClientUserInfo

Информация о пользователе. Если установлена, то будет отправлена серверу на CTCP‐запрос `USERINFO`.

```FreeBASIC
Dim ClientUserInfo As WString Ptr
```


## Функции


### OpenIrc

Открывает соединение с сервером. Перегружена.

```FreeBASIC
Declare Function OpenIrc( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr, _
	ByVal Nick As WString Ptr _
) As Boolean

Declare Function OpenIrc( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr, _
	ByVal Port As WString Ptr, _
	ByVal Nick As WString Ptr, _
	ByVal User As WString Ptr, _
	ByVal Description As WString Ptr _
) As Boolean

Declare Function OpenIrc( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr, _
	ByVal Port As WString Ptr, _
	ByVal LocalAddress As WString Ptr, _
	ByVal LocalPort As WString Ptr, _
	ByVal Password As WString Ptr, _
	ByVal Nick As WString Ptr, _
	ByVal User As WString Ptr, _
	ByVal Description As WString Ptr, _
	ByVal Visible As Boolean _
) As Boolean
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`. Структура должна быть инициализирована нулями.</dd>

<dt>Server</dt>
<dd>Имя сервера для соединения: доменное имя или IP‐адрес, например, chat.freenode.net.</dd>

<dt>Port</dt>
<dd>Строка, содержащая номер порта для соединения. Стандартный порт для IRC сети — 6667. Однако также доступны некоторые другие порты, на каждом из которых используется определённая кодировка для преобразования байт в строку. Необходимо смотреть в описании сервера на его официальном сайте.</dd>

<dt>LocalAddress</dt>
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
<dd>Описание пользователя, любые дополнительные данные, которые могут быть полезны, например, настоящие имя и фамилия пользователя, может содержать пробелы и спецсимволы, не меняется в течение всего соединения.</dd>

<dt>Visible</dt>
<dd>Флаг видимости для других пользователей. Если установлен в `True`, то пользователя можно будет найти командой `WHO`. Обычно все серверы устанавливают его в `False`.</dd>

</dl>


#### Описание

Если длина пароля на сервер равна нулю, то функция создаёт строку подключения вида:

```
NICK Paul
USER paul 8 * :Paul Mutton
```

Если пароль не пустой, то создаёт строку подключения вида:

```
PASS password
NICK Paul
USER paul 8 * :Paul Mutton
```

Затем инициализирует библиотеку сокетов функцией WSAStartup(), открывает соединение с сервером и отправляет строку подключения на сервер. Также функция устанавливает интервал ожидания чтения данных от сервера в течение десяти минут.


#### Возвращаемое значение

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.

Если функция завершается ошибкой, то закрывать соединение не требуется.


### RunIrcClient

Запускает цикл обработки данных от сервера, разбирает их по шаблону и вызывает события.

```FreeBASIC
Declare Sub RunIrcClient( _
	ByVal pIrcClient As IrcClient Ptr _
)
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>
</dl>

#### Описание

Функция разбирает строку по шаблону и вызывает следующие события:

* SendedRawMessageEvent
* ReceivedRawMessageEvent
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
* CtcpTimeRequestEvent
* CtcpUserInfoRequestEvent
* CtcpVersionRequestEvent
* CtcpActionEvent
* CtcpPingResponseEvent
* CtcpTimeResponseEvent
* CtcpUserInfoResponseEvent
* CtcpVersionResponseEvent

Функция самостоятельно обрабатывает сообщения `PING` и отправляет на него сообщения `PONG`. Если установлен обработчик события `PingEvent`, то обработкой сообщения `PING` клиент должен заниматься самостоятельно, вызывая функцию `SendPong`.

Цикл обработки сообщений прерывается когда получение данных от сервера завершается ошибкой.


#### Возвращаемое значение

Функция не возваращает значений.


### CloseIrcClient

Закрывает соединение с сервером.

```FreeBASIC
Declare Sub CloseIrcClient( _
	ByVal pIrcClient As IrcClient Ptr _
)
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>
</dl>


#### Описание

Функция немедленно закрывает соединение с сервером, без отправки сообщения `QUIT` о выходе из сети и освобождает ресурсы библиотеки сокетов. Функцию `CloseIrc` рекомендуется вызывать при любых ошибках сети и для освобождения ресурсов библиотеки сокетов.


#### Возвращаемое значение

Функция не возвращает значений.


### SendIrcMessage

Отправляет сообщение на канал или пользователю.

```FreeBASIC
Declare Function SendIrcMessage( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>

<dt>Channel</dt>
<dd>Имя пользователя или канал. Если указан канал, то сообщение получат все пользователи, сидящие на канале. Если указано имя пользователя, то сообщение получит только этот пользователь.</dd>

<dt>MessageText</dt>
<dd>Текст сообщения</dd>
</dl>


#### Описание

Функция создаёт строку вида:

```
PRIVMSG target :Message Text
```

Где `target` — это канал или имя пользователя. Эта строка преобразуется в массив байт в соответствии с текущей кодировкой и отправляется на сервер.


#### Возвращаемое значение

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.


### SendNotice

Отправляет уведомление пользователю.

```FreeBASIC
Declare Function SendNotice( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal NoticeText As WString Ptr _
) As Boolean
```

#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>

<dt>Channel</dt>
<dd>Имя пользователя, получателя уведомления.</dd>

<dt>NoticeText</dt>
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

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.


### ChangeTopic

Устанавливает, удаляет или получает тему канала.

```FreeBASIC
Declare Function ChangeTopic( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal TopicText As WString Ptr _
) As Boolean
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>

<dt>Channel</dt>
<dd>Канал для установки или запроса темы.</dd>

<dt>TopicText</dt>
<dd>Текст темы.</dd>
</dl>


#### Описание

Если `TopicText` — нулевой указатель `NULL`, то на сервер отправляется строка:

```
Topic
```

В ответ сервер отправит тему канала. Сервер ответит кодами `RPL_TOPIC`, если тема существует, или `RPL_NOTOPIC`, если тема не установлена.

Если `TopicText` — указатель на пустую строку, на сервер отправляется строка:

```
Topic :
```

В этом случае сервер удалит тему канала.

Иначе на сервер отправляется строка:

```
Topic :TopicText
```

В этом случае сервер установит тему канала, указанную в `TopicText`.


#### Возвращаемое значение

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.


### QuitFromServer

Отправляет на сервер сообщение о выходе, что вынуждает сервер закрыть соединение. Перегружена.

```FreeBASIC
Declare Function QuitFromServer Overload( _
	ByVal pIrcClient As IrcClient Ptr _
) As Boolean

Declare Function QuitFromServer Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>

<dt>MessageText</dt>
<dd>Текст прощального сообщения.</dd>
</dl>


#### Описание

Если длина прощального сообщения равна нулю, то функция отправляет на сервер строку:

```
QUIT
```

Иначе функция отправляет строку

```
QUIT :Прощальное сообщение
```

Это вынуждает сервер закрыть соединение с клиентом.


#### Возвращаемое значение

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.


### ChangeNick

Меняет ник пользователя.

```FreeBASIC
Declare Function ChangeNick( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Nick As WString Ptr _
) As Boolean
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>

<dt>Nick</dt>
<dd>Новый ник.</dd>
</dl>


### Описание

Функция отправляет на сервер строку:

```
NICK новый ник
```


#### Возвращаемое значение

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.


### JoinChannel

Присоединяет к каналу или каналам.

```
Declare Function JoinChannel( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr _
) As Boolean
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>

<dt>Channel</dt>
<dd>Список каналов, разделённый запятыми без пробелов. Если на канале установлен пароль, то через пробел указываются пароли для входа, разделённые запятыми без пробелов.</dd>
</dl>


#### Описание

Функция отправляет на сервер строку:

```
JOIN channel
```

#### Пример

```FreeBASIC
' Присоединение к каналам
Client.JoinChannel("#freebasic,#freebasic-ru")

' Присоединение к каналам с указанием для первого канала пароля
Client.JoinChannel("#freebasic,#freebasic-ru password1")
```


#### Возвращаемое значение

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.


### PartChannel

Отключает от канала. Перегружена.

```
Declare Function PartChannel Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr _
) As Boolean

Declare Function PartChannel Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>

<dt>Channel</dt>
<dd>Канал для выхода.</dd>

<dt>MessageText</dt>
<dd>Текст прощального сообщения.</dd>
</dl>


#### Описание

Функция отправляет на сервер строку:

```
PART channel: прощальное сообщение
```

Это вынуждает сервер отсоединить пользователя от канала.


#### Возвращаемое значение

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.


### SendCtcpAction

Отправляет CTCP‐сообщение ACTION, отображаемое клиентами так, будто пользователь сказал текст от третьего лица.

```
Declare Function SendCtcpAction( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>

<dt>UserName</dt>
<dd>Имя пользователя или канал, кому адресовано сообщение.</dd>

<dt>MessageText</dt>
<dd>Текст сообщения.</dd>
</dl>

#### Описание

Сообщение ACTION позволяет сказать текст от третьего лица. В большинстве клиентов ACTION отправляется через команду /me.

Функция отправляет на сервер строку:

```
PRIVMSG UserName: ACTION MessageText
```


#### Возвращаемое значение

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.


### SendCtcpPingRequest

Отправляет CTCP‐запрос PING.

```
Declare Function SendCtcpPingRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal TimeValue As WString Ptr _
) As Boolean
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>

<dt>UserName</dt>
<dd>Имя пользователя, у которого запрашивают PING.</dd>

<dt>TimeValue</dt>
<dd>Текущее время.</dd>
</dl>

#### Описание

Функция отправляет на сервер строку:

```
PRIVMSG UserName: PING TimeValue
```

Запрос CTCP PING позволит определить задержку сообщений, которая существует непосредственно между двумя клиентами. CTCP PING работает путем отправки целочисленного аргумента (метки времени) целевому клиенту. Клиент может ответить, предоставляя точно такой же числовой параметр. Вычисляется разница между исходной меткой времени и текущей меткой времени, при этом результат отображается пользователю, который инициировал CTCP PING. Чаще всего используется временная метка, использующая миллисекунды из‐за большинства пользователей с широкополосным подключением к интернету с задержкой менее 1 секунды.


#### Возвращаемое значение

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.


### SendCtcpTimeRequest

Отправляет CTCP‐запрос TIME, чтобы узнать локальное время клиента.

```
Declare Function SendCtcpTimeRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>

<dt>UserName</dt>
<dd>Имя пользователя, у которого запрашивают локальное время.</dd>
</dl>

#### Описание

Функция отправляет на сервер строку:

```
PRIVMSG UserName: TIME
```

Запрос CTCP TIME позволяет получить локальное время клиента.


#### Возвращаемое значение

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.


### SendCtcpUserInfoRequest

Отправляет CTCP‐запрос USERINFO, чтобы узнать информацию о пользователе.

```
Declare Function SendCtcpUserInfoRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>

<dt>UserName</dt>
<dd>Имя пользователя, у которого запрашивают информацию.</dd>
</dl>

#### Описание

Функция отправляет на сервер строку:

```
PRIVMSG UserName: USERINFO
```

Запрос CTCP USERINFO позволяет получить информацию о пользователе.


#### Возвращаемое значение

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.


### SendCtcpVersionRequest

Отправляет CTCP‐запрос VERSION, чтобы узнать информацию о версии программы‐клиента пользователя.

```
Declare Function SendCtcpVersionRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean
```


#### Параметры

<dl>
<dt>pIrcClient</dt>
<dd>Указатель на структуру `IrcClient`.</dd>

<dt>UserName</dt>
<dd>Имя пользователя, у которого запрашивают информацию.</dd>
</dl>

#### Описание

Функция отправляет на сервер строку:

```
PRIVMSG UserName: VERSION
```

Запрос CTCP VERSION позволяет получить версию программы‐клиента пользователя.


#### Возвращаемое значение

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.
















Declare Function SendCtcpPingResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal TimeValue As WString Ptr _
) As Boolean

Declare Function SendCtcpTimeResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal TimeValue As WString Ptr _
) As Boolean

Declare Function SendCtcpUserInfoResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal UserInfo As WString Ptr _
) As Boolean

Declare Function SendCtcpVersionResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal Version As WString Ptr _
) As Boolean

Declare Function SendPing( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr _
) As Boolean

Declare Function SendPong( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr _
) As Boolean

Declare Function SendRawMessage( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal RawText As WString Ptr _
) As Boolean





















### SendPing

Отправляет сообщение PING.

Параметры:

`strServer` — сервер, к которому подключён клиент.

На сообщение PING сервер ответит сообщением PONG.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.



















### SendPong

Отправляет сообщение PONG.

Параметры:

`strServer` — сервер, к которому подключён клиент.

Сервер отправляет сообщения PING для проверки подключённости пользователя. Если пользователь вовремя не ответит сообщением PONG, то сервер закроет соединение. Обычно отправка PONG вручную не требуется, так как это берёт на себя библиотека.

В случае успеха функция возвращает значение `ResultType.None`, в случае ошибки возвращает код ошибки.






























### SendRawMessage

Отправляет данные на сервер как они есть.

```
Declare Function SendRawMessage( _
	ByVal RawText As WString Ptr _
) As Boolean
```

#### Параметры

<dl>
<dt>RawText</dt>
<dd>Данные.</dd>
</dl>


#### Описание

Функция отправляет данные на сервер без обработки. Используется в тех случаях, когда стандартные функции отправки сообщений не подходят.


#### Возвращаемое значение

В случае успеха функция возвращает `True`, в случае ошибки возвращает `False`.























	
## События
