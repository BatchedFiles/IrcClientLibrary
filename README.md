# IrcClientLibrary

Клиентская библиотека для работы с протоколом IRC. Инкапсулирует низкоуровневую работу с сокетами, приём и отправку сообщений, автоматические ответы на пинг от сервера. Пригодна для создания ботов, клиентских программ и мессенджеров для работы с IRC‐протоколом.

Библиотека использует асинхронный вызов процедур и функции обратного вызова. Каждое пришедшее сообщение от сервера разбирается по шаблонам, вызывая соответствующие обработчики событий.

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

Sub OnIrcPrivateMessage( _
		ByVal ClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal MessageText As BSTR _
	)
	IrcClientSendPrivateMessage(@Client, pIrcPrefix->Nick, SysAllocString("Да, я тоже."))
End Sub

Client.Events.lpfnPrivateMessageEvent = @OnIrcPrivateMessage

IrcClientOpenConnectionSimple1(@Client, SysAllocString("chat.freenode.net"), SysAllocString("LeoFitz"))
IrcClientJoinChannel(@Client, SysAllocString("#freebasic-ru"))

IrcClientStartReceiveDataLoop(@Client)

IrcClientCloseConnection(@Client)
```

Функция `IrcClientStartReceiveDataLoop` используется для остановки текущего потока и вызова асинхронных операций чтения‐записи.

В оконных приложениях вместо функции `IrcClientStartReceiveDataLoop` необходимо использовать `IrcClientMsgStartReceiveDataLoop`.


