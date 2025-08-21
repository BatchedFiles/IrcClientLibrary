# IrcClientLibrary

Клиентская библиотека для работы с протоколом IRC. Инкапсулирует низкоуровневую работу с сокетами, приём и отправку сообщений, автоматические ответы на пинг от сервера. Пригодна для создания ботов, клиентских программ и мессенджеров для работы с IRC‐протоколом.

Библиотека использует асинхронный вызов процедур и функции обратного вызова. Каждое пришедшее сообщение от сервера разбирается по шаблонам, вызывая соответствующие обработчики событий.

Функции библиотеки работают со структурой `IrcClient`.

## Компиляция

```Batch
fbc -x simplebot.exe -i src test\simplebot.bas src\IrcClient.bas
```

## Быстрый старт

Этот пример консольного приложения показывает как создать соединение с сервером IRC, зайти на канал и отправить личное сообщение пользователю.

```FreeBASIC
#include once "IrcClient.bi"

Sub OnIrcPrivateMessage( _
		ByVal pClientData As LPCLIENTDATA, _
		ByVal pIrcPrefix As IrcPrefix Ptr, _
		ByVal MessageText As BSTR _
	)
	Dim pClient As IrcClient Ptr = pClientData
	Dim Message As BSTR = SysAllocString(WStr("Yes, me too"))
	IrcClientSendPrivateMessage(pClient, pIrcPrefix->Nick, Message)
	SysFreeString(Message)
End Sub

Dim Ev As IrcEvents
Ev.lpfnPrivateMessageEvent = @OnIrcPrivateMessage

Dim pClient As IrcClient Ptr = CreateIrcClient()
IrcClientSetCallback(pClient, @Ev, pClient)

IrcClientOpenConnectionSimple1( _
	pClient, _
	SysAllocString("irc.pouque.net"), _
	SysAllocString("LeoFitz") _
)
IrcClientJoinChannel(pClient, SysAllocString("#chlor"))

IrcClientMainLoop(pClient)

IrcClientCloseConnection(pClient)
```

