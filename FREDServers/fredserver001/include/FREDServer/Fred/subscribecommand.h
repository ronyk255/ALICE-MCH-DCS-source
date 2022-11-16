#ifndef SUBSCRIBECOMMAND_H
#define SUBSCRIBECOMMAND_H

#include <string>
#include "Alfred/command.h"

class Fred;
struct ChainTopic;

class SubscribeCommand: public CommandString
{
public:
    SubscribeCommand(string name, Fred* fred, ChainTopic* topic, int32_t placeId);
    ~SubscribeCommand();

private:
    ChainTopic* topic;
    int32_t placeId;

    const void* Execution(void* value);
};

#endif // SUBSCRIBECOMMAND_H
