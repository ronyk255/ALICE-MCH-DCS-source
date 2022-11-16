#include "Alfred/command.h"
#include "Alfred/service.h"
#include "Alfred/client.h"
#include "Alfred/rpcinfo.h"
#include "Alfred/print.h"
#include "Alfred/alfred.h"

vector<string> Command::names;

bool Command::AlreadyRegistered(const string& name)
{
	for (size_t i = 0; i < names.size(); i++)
	{
		if (names[i] == name)
		{
			return true;
		}
	}

	return false;
}

void Command::RemoveElement(const string& name)
{
	for (size_t i = 0; i < names.size(); i++)
	{
		if (names[i] == name)
		{
			names.erase(names.begin() + i);
			return;
		}
	}
}

Command::Command(string name, ALFRED* alfred)
{
	serviceCallback = NULL;
	clientCallback = NULL;
    rpcinfoCallback = NULL;

    type = ALFRED_TYPES::DIM_TYPE::NONE;
	this->name = name;

	if (!alfred)
	{
        Print::PrintError(string("ALFRED for command ") + name + " not defined!");
		exit(EXIT_FAILURE);	
	}

	this->alfred = alfred;

	if (AlreadyRegistered(name))
	{
        Print::PrintError(string("Command ") + name + " already registered!");
		exit(EXIT_FAILURE);
	}
	else
	{
		names.push_back(name);
	}
}

Command::~Command()
{
	RemoveElement(Name());
}

const void* Command::Execution(void* value)
{
	return value;
}

void Command::ConnectService(Service* serviceCallback)
{
	this->serviceCallback = serviceCallback;
}

void Command::ConnectClient(Client* clientCallback)
{
	this->clientCallback = clientCallback;
}

void Command::ConnectRpcInfo(RpcInfo *rpcinfoCallback)
{
    this->rpcinfoCallback = rpcinfoCallback;
}

void Command::CallService(string name, void* value)
{
	Parent()->GetService(name)->Update(value);
}

void Command::CallClient(string name, void* value)
{
	Parent()->GetClient(name)->Send(value);
}

void* Command::CallRpcInfo(string name, void *value)
{
    return Parent()->GetRpcInfo(name)->Send(value);
}

ALFRED_TYPES::DIM_TYPE Command::Type()
{
	return type;
}

string Command::Name()
{
	return name;
}

ALFRED* Command::Parent()
{
	return alfred;
}

/*----------------------------------------------------------------------------------------------*/

CommandInt::CommandInt(string name, ALFRED* alfred): Command::Command(name, alfred), DimCommand::DimCommand(name.c_str(), "I")
{
    type = ALFRED_TYPES::DIM_TYPE::INT;

    Print::PrintVerbose(string("Command ") + name + " registered!");
}

CommandInt::~CommandInt()
{

}

void CommandInt::commandHandler()
{
	value = getInt();

	void* result = (void*)Execution((void*)&value);

	if (serviceCallback)
	{
		serviceCallback->Update(result);
	}

	if (clientCallback)
	{
		clientCallback->Send(result);
	}

    if (rpcinfoCallback)
    {
        rpcinfoCallback->Send(result);
    }
}

/*----------------------------------------------------------------------------------------------*/

CommandFloat::CommandFloat(string name, ALFRED* alfred): Command::Command(name, alfred), DimCommand::DimCommand(name.c_str(), "F")
{
    type = ALFRED_TYPES::DIM_TYPE::FLOAT;

    Print::PrintVerbose(string("Command ") + name + " registered!");
}

CommandFloat::~CommandFloat()
{

}

void CommandFloat::commandHandler()
{
	value = getFloat();

	void* result = (void*)Execution((void*)&value);

	if (serviceCallback)
	{
		serviceCallback->Update(result);
	}

	if (clientCallback)
	{
		clientCallback->Send(result);
	}

    if (rpcinfoCallback)
    {
        rpcinfoCallback->Send(result);
    }
}

/*----------------------------------------------------------------------------------------------*/

CommandString::CommandString(string name, ALFRED* alfred): Command::Command(name, alfred), DimCommand::DimCommand(name.c_str(), "C")
{
    type = ALFRED_TYPES::DIM_TYPE::STRING;

    Print::PrintVerbose(string("Command ") + name + " registered!");
}

CommandString::~CommandString()
{

}

void CommandString::commandHandler()
{
    value = getString();

    void* result = (void*)Execution((void*)value.c_str());

    if (serviceCallback)
    {
        serviceCallback->Update(result);
    }

    if (clientCallback)
    {
        clientCallback->Send(result);
    }

    if (rpcinfoCallback)
    {
        rpcinfoCallback->Send(result);
    }
}

/*----------------------------------------------------------------------------------------------*/

CommandData::CommandData(string name, string format, ALFRED* alfred): Command::Command(name, alfred), DimCommand::DimCommand(name.c_str(), format.c_str())
{
    type = ALFRED_TYPES::DIM_TYPE::DATA;

    Print::PrintVerbose(string("Command ") + name + " registered!");
}

CommandData::~CommandData()
{
	
}

void CommandData::commandHandler()
{
	value = getData();

	void* result = (void*)Execution(value);

	if (serviceCallback)
	{
		serviceCallback->Update(result);
	}

	if (clientCallback)
	{
		clientCallback->Send(result);
	}

    if (rpcinfoCallback)
    {
        rpcinfoCallback->Send(result);
    }
}
