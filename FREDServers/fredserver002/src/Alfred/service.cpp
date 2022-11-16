#include "Alfred/service.h"
#include "Alfred/print.h"
#include "Alfred/alfred.h"

vector<string> Service::names;

bool Service::AlreadyRegistered(const string& name)
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

void Service::RemoveElement(const string& name)
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

Service::Service(string name, ALFRED* alfred)
{
	service = NULL;
	this->name = name;

    type = ALFRED_TYPES::DIM_TYPE::NONE;

	if (!alfred)
	{
        Print::PrintError(string("ALFRED for service ") + name + " not defined!");
		exit(EXIT_FAILURE);	
	}

	this->alfred = alfred;

	if (AlreadyRegistered(name))
	{
        Print::PrintError(string("Service ") + name + " already registered!");
		exit(EXIT_FAILURE);
	}
	else
	{
		names.push_back(name);
	}
}

Service::~Service()
{
	RemoveElement(Name());
}

size_t Service::GetValueSize()
{
	return size;
}

void Service::Update(const void* value)
{
    switch (type)
    {
        case ALFRED_TYPES::DIM_TYPE::INT:
            ((ServiceInt*)this)->Update(*(int*)value);
            break;
        case ALFRED_TYPES::DIM_TYPE::FLOAT:
            ((ServiceFloat*)this)->Update(*(float*)value);
            break;
        case ALFRED_TYPES::DIM_TYPE::STRING:
            ((ServiceString*)this)->Update((const char*)value);
            break;
        case ALFRED_TYPES::DIM_TYPE::DATA:
            ((ServiceData*)this)->Update(value);
            break;
        default:
            Print::PrintError("Invalid type of service!");
            exit(EXIT_FAILURE);
    }
}

ALFRED_TYPES::DIM_TYPE Service::Type()
{
	return type;
}

string Service::Name()
{
	return name;
}

ALFRED* Service::Parent()
{
	return alfred;
}

/*----------------------------------------------------------------------------------------------*/

ServiceInt::ServiceInt(string name, ALFRED* alfred): Service::Service(name, alfred)
{
	size = sizeof(int);
    value = 0;
    service = new DimService(name.c_str(), value);
    type = ALFRED_TYPES::DIM_TYPE::INT;

    Print::PrintVerbose(string("Service ") + name + " registered!");
}

ServiceInt::~ServiceInt()
{
	delete service;
}

void ServiceInt::Update(int value)
{
    this->value = value;
    service->updateService();
}

/*----------------------------------------------------------------------------------------------*/

ServiceFloat::ServiceFloat(string name, ALFRED* alfred): Service::Service(name, alfred)
{
	size = sizeof(float);
    value = 0.0;
    service = new DimService(name.c_str(), value);
    type = ALFRED_TYPES::DIM_TYPE::FLOAT;

    Print::PrintVerbose(string("Service ") + name + " registered!");
}

ServiceFloat::~ServiceFloat()
{
	delete service;
}

void ServiceFloat::Update(float value)
{
    this->value = value;
    service->updateService();
}

/*----------------------------------------------------------------------------------------------*/

ServiceString::ServiceString(string name, ALFRED* alfred): Service::Service(name, alfred)
{
    value = "";
    service = new DimService(name.c_str(), const_cast<char*>(value.c_str()));
    type = ALFRED_TYPES::DIM_TYPE::STRING;

    Print::PrintVerbose(string("Service ") + name + " registered!");
}

ServiceString::~ServiceString()
{
    delete service;
}

void ServiceString::Update(string value)
{
    this->value = value;
    service->updateService(const_cast<char*>(this->value.c_str()));
}

/*----------------------------------------------------------------------------------------------*/

ServiceData::ServiceData(string name, ALFRED* alfred, size_t size, string format): Service::Service(name, alfred)
{
	this->size = size;
	value = (void*)new uint8_t[size];
	service = new DimService(name.c_str(), format.c_str(), value, size);
    type = ALFRED_TYPES::DIM_TYPE::DATA;

    Print::PrintVerbose(string("Service ") + name + " registered!");
}

ServiceData::~ServiceData()
{
	delete service;
	delete[] (uint8_t*)value;
}

void ServiceData::Update(const void *value)
{
    memcpy(this->value, value, this->size);
    service->updateService();
}
