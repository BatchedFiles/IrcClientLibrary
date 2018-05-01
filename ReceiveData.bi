#ifndef BATCHEDFILES_IRCCLIENT_RECEIVEDATA_BI
#define BATCHEDFILES_IRCCLIENT_RECEIVEDATA_BI

#include "IrcClient.bi"

Declare Function ReceiveData( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal ReceivedData As WString Ptr _
) As Boolean

#endif
