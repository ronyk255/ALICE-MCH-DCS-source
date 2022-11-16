#include <iostream>
#include <string>

using namespace std;

class MultiBase
{
public:
    virtual string getType() = 0;
    virtual int getInt() = 0;
    virtual double getDouble() = 0;
    virtual string getString() = 0;

    virtual bool isInt() = 0;
    virtual bool isDouble() = 0;
    virtual bool isNumeric() = 0;
    virtual bool isString() = 0;

    virtual ~MultiBase();

protected:
    class MultiWrapper
    {
    public:
        MultiWrapper(int value);
        MultiWrapper(double value);
        MultiWrapper(string value);

        int getInt();
        double getDouble();
        string getString();

    private:
        int intVal;
        double doubleVal;
        string stringVal;
    };
};

template <typename Type> class MultiType: public MultiBase
{
private:
    Type value;

public:
    MultiType();
    MultiType(Type value);
    ~MultiType();

    Type operator()();
    Type operator()(Type value);

    string getType();
    int getInt();
    double getDouble();
    string getString();

    bool isInt();
    bool isDouble();
    bool isNumeric();
    bool isString();
};
