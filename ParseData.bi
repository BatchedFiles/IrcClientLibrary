#ifndef BATCHEDFILES_IRCCLIENT_PARSEDATA_BI
#define BATCHEDFILES_IRCCLIENT_PARSEDATA_BI

#include "IrcClient.bi"

Declare Function ParseData( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal ReceivedData As WString Ptr _
) As Boolean

#endif
