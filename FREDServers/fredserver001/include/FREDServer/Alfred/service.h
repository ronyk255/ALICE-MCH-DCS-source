#ifndef __SERVICE
#define __SERVICE

#include <cstdlib>
#include <string>
#include <vector>
#include <dim/dis.hxx>

#include "Alfred/types.h"

using namespace std;

class ALFRED;

class Service
{
protected:
	DimService *service;
	size_t size;

    ALFRED_TYPES::DIM_TYPE type;
	string name;
	ALFRED* alfred;

	static vector<string> names;
	static bool AlreadyRegistered(const string& name);
	static void RemoveElement(const string& name);

	Service(string name, ALFRED* alfred);

public:
	virtual ~Service();
	
	size_t GetValueSize();
	
	void Update(const void* value);

    ALFRED_TYPES::DIM_TYPE Type();
	string Name();
	ALFRED* Parent();
};

/*----------------------------------------------------------------------------------------------*/

class ServiceInt: public Service
{
private:
    int value;

public:
	ServiceInt(string name, ALFRED* alfred);
	~ServiceInt();

    void Update(int value);
};

/*----------------------------------------------------------------------------------------------*/

class ServiceFloat: public Service
{
private:
    float value;

public:
	ServiceFloat(string name, ALFRED* alfred);
	~ServiceFloat();

    void Update(float value);
};

/*----------------------------------------------------------------------------------------------*/

class ServiceString: public Service
{
private:
    string value;

public:
    ServiceString(string name, ALFRED* alfred);
    ~ServiceString();

    void Update(string value);
};

/*----------------------------------------------------------------------------------------------*/

class ServiceData: public Service
{
private:
    void* value;

public:
	ServiceData(string name, ALFRED* alfred, size_t size, string format);
	~ServiceData();

    void Update(const void* value);
};

#endif
