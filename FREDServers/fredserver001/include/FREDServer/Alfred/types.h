#ifndef __TYPES
#define __TYPES

namespace ALFRED_TYPES
{
    enum DIM_TYPE
    {
        NONE,
        INT,
        FLOAT,
        STRING,
        DATA
    };

    enum CONNECT
    {
        COMMAND_SERVICE,
        INFO_SERVICE,
        COMMAND_CLIENT,
        INFO_CLIENT,
        COMMAND_RPCINFO,
        INFO_RPCINFO,
        RPCINFO_SERVICE,
        RPCINFO_CLIENT,
        RPC_SERVICE,
        RPC_CLIENT
    };

    enum CRU_TYPES
    {
      //READ, // old
      //WRITE,
      PATTERN_PLAYER
    };

    enum LLA_TYPES
    {
        START,
        STOP
    };
}

#endif
