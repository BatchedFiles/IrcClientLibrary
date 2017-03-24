' Псевдособытия
Declare Sub SendedRawMessage(ByVal AdvData As Any Ptr, ByVal MessageText As WString Ptr)
Declare Sub ReceivedRawMessage(ByVal AdvData As Any Ptr, ByVal MessageText As WString Ptr)
Declare Function ServerMessage(ByVal AdvData As Any Ptr, ByVal ServerCode As WString Ptr, ByVal MessageText As WString Ptr)As ResultType
Declare Function Notice(ByVal AdvData As Any Ptr, ByVal Channel As WString Ptr, ByVal NoticeText As WString Ptr)As ResultType
Declare Function ChannelMessage(ByVal AdvData As Any Ptr, ByVal Channel As WString Ptr, ByVal User As WString Ptr, ByVal MessageText As WString Ptr)As ResultType
Declare Function IrcPrivateMessage(ByVal AdvData As Any Ptr, ByVal User As WString Ptr, ByVal MessageText As WString Ptr)As ResultType
Declare Function UserJoined(ByVal AdvData As Any Ptr, ByVal Channel As WString Ptr, ByVal UserName As WString Ptr)As ResultType
Declare Function UserLeaved(ByVal AdvData As Any Ptr, ByVal Channel As WString Ptr, ByVal UserName As WString Ptr, ByVal MessageText As WString Ptr)As ResultType
Declare Function NickChanged(ByVal AdvData As Any Ptr, ByVal OldNick As WString Ptr, ByVal NewNick As WString Ptr)As ResultType
Declare Function Topic(ByVal AdvData As Any Ptr, ByVal Channel As WString Ptr, ByVal UserName As WString Ptr, ByVal Text As WString Ptr) As ResultType
Declare Function UserQuit(ByVal AdvData As Any Ptr, ByVal UserName As WString Ptr, ByVal MessageText As WString Ptr)As ResultType
Declare Function Kick(ByVal AdvData As Any Ptr, ByVal AdminName As WString Ptr, ByVal Channel As WString Ptr, ByVal KickedUser As WString Ptr)As ResultType
Declare Function Invite(ByVal AdvData As Any Ptr, ByVal FromuserName As WString Ptr, ByVal Channel As WString Ptr)As ResultType
Declare Sub Disconnect(ByVal AdvData As Any Ptr)
Declare Function Ping(ByVal AdvData As Any Ptr, ByVal Server As WString Ptr)As ResultType
Declare Function Pong(ByVal AdvData As Any Ptr, ByVal Server As WString Ptr)As ResultType
Declare Function Mode(ByVal AdvData As Any Ptr, ByVal AdminName As WString Ptr, ByVal Channel As WString Ptr, ByVal UserName As WString Ptr, ByVal Mode As WString Ptr)As ResultType
Declare Function CtcpMessage(ByVal AdvData As Any Ptr, ByVal FromUser As WString Ptr, ByVal UserName As WString Ptr, ByVal MessageType As CtcpMessageType, ByVal Param As WString Ptr)As ResultType
Declare Function CtcpNotice(ByVal AdvData As Any Ptr, ByVal FromUser As WString Ptr, ByVal UserName As WString Ptr, ByVal MessageType As CtcpMessageType, ByVal MessageText As WString Ptr)As ResultType
Declare Sub ServerError(ByVal AdvData As Any Ptr, ByVal Message As WString Ptr)
