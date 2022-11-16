#include "Database/multitype.h"
#include <typeinfo>

MultiBase::~MultiBase()
{
}

MultiBase::MultiWrapper::MultiWrapper(int value)
{
	this->intVal = value;
}

MultiBase::MultiWrapper::MultiWrapper(double value)
{
	this->doubleVal = value;
}

MultiBase::MultiWrapper::MultiWrapper(string value)
{
	this->stringVal = value;
}

int MultiBase::MultiWrapper::getInt()
{
	return this->intVal;
}

double MultiBase::MultiWrapper::getDouble()
{
	return this->doubleVal;
}

string MultiBase::MultiWrapper::getString()
{
	return this->stringVal;
}

template <typename Type> MultiType<Type>::MultiType()
{

}

template <typename Type> MultiType<Type>::MultiType(Type value)
{
	this->value = value;
}

template <typename Type> MultiType<Type>::~MultiType()
{
}

template <typename Type> Type MultiType<Type>::operator()()
{
	return this->value;
}

template <typename Type> Type MultiType<Type>::operator()(Type value)
{
	this->value = value;
	return this->value;
}

template <typename Type> string MultiType<Type>::getType()
{
	return string(typeid(Type).name());
}

template <typename Type> int MultiType<Type>::getInt()
{
	MultiWrapper wrapper(this->value);

	if (getType() == "i")
	{	
		return wrapper.getInt();
	}
	else if (getType() == "d")
	{
		return int(wrapper.getDouble());
	}

	return 0;
}

template <typename Type> double MultiType<Type>::getDouble()
{
	MultiWrapper wrapper(this->value);

	if (getType() == "d")
	{
		return wrapper.getDouble();
	}
	else if (getType() == "i")
	{	
		return double(wrapper.getInt());
	}

	return 0.0;
}

template <typename Type> string MultiType<Type>::getString()
{
	MultiWrapper wrapper(this->value);

	if (getType() == "i")
	{
		return to_string(wrapper.getInt());
	}
	else if (getType() == "d")
	{
		return to_string(wrapper.getDouble());
	}

	return wrapper.getString();
}

template <typename Type> bool MultiType<Type>::isInt()
{
    return getType() == "i";
}

template <typename Type> bool MultiType<Type>::isDouble()
{
    return getType() == "d";
}

template <typename Type> bool MultiType<Type>::isNumeric()
{
    return isInt() || isDouble();
}

template <typename Type> bool MultiType<Type>::isString()
{
    return getType() == "Ss";
}

template class MultiType<int>;
template class MultiType<double>;
template class MultiType<string>;
