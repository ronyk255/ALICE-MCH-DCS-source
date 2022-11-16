#include <cstdio>
#include <iostream>
#include <iomanip>
#include <sstream>
#include <cctype>
#include <algorithm>
#include <climits>
#include <cmath>
#include "Parser/utility.h"
#include "Parser/calculator.h"
#include "Alfred/print.h"
#include "Parser/processmessage.h"
#include "Fred/Protocols/SCA.h"
#include "Fred/Protocols/SWT.h"
#include "Fred/Protocols/IC.h"
#include "Fred/Protocols/CRORC.h"
#include "Fred/Protocols/CRU.h"

vector<double> Utility::splitString2Num(const string &text, string by)
{
    vector<double> result;

    vector<string> nums = splitString(text, by);

    for (size_t j = 0; j < nums.size(); j++)
    {
        if (nums[j].find('x') != string::npos)
        {
            result.push_back(double(stoll(nums[j].substr(nums[j].find('x') + 1), NULL, 16)));
        }
        else
        {
            result.push_back(stod(nums[j]));
        }
    }

    return result;
}

vector<string> Utility::splitString(const string& text, string by)
{
    vector<string> result;
    string temp = text;
    
    while(temp.size())
    {
        size_t index = temp.find(by);
        if(index != string::npos)
        {
            result.push_back(temp.substr(0, index));
            temp = temp.substr(index + by.length());
        }
        else
        {
            result.push_back(temp);
            temp = "";
            break;
        }
    }

    return result;
}

vector<vector<string> > Utility::splitMessage(const string& text)
{
    vector<vector<string> > result;

    vector<string> lines = splitString(text, "\n");

    for (size_t i = 0; i < lines.size(); i++)
    {
        result.push_back(splitString(lines[i], ","));
    }

    return result;
}

vector<vector<double> > Utility::splitMessage2Num(const string &text)
{
    vector<vector<double> > result;
    vector<string> lines = splitString(text, "\n");

    for (size_t i = 0; i < lines.size(); i++)
    {
        result.push_back(splitString2Num(lines[i], ","));
    }

    return result;
}

void Utility::removeWhiteSpaces(string& text)
{
    text.erase(remove_if(text.begin(), text.end(), [](unsigned char c){return isspace(c);}), text.end());
    text.erase(remove_if(text.begin(), text.end(), [](unsigned char c){return iscntrl(c);}), text.end());
}

void Utility::removeComment(string& text)
{
    size_t pos = text.find("#");
    if (pos != string::npos)
    {
        text.erase(pos);
    }
}

void Utility::printVector(const vector<string> &data)
{
    for (int j = 0; j < data.size(); j++) cout << data[j] << "\n";
}

void Utility::printVector(const vector<int32_t> &data)
{
    for (int j = 0; j < data.size(); j++) cout << data[j] << "\n";
}

double Utility::calculateEquation(string& equation, vector<string>& variables, vector<double>& values)
{
    map<string, int64_t> varMap;

    for (size_t i = 0; i < values.size(); i++)
    {
        if (trunc(values[i]) == values[i])
        {
            varMap[variables[i]] = int64_t(values[i]);
        }
        else
        {
            size_t pos = -1;
            while ((pos = equation.find(variables[i], pos + 1) != string::npos))
            {
                equation.insert(pos + variables[i].size(), "/1000");
            }
            varMap[variables[i]] = int64_t(values[i] * 1000);
        }
    }

    try
    {
        return (calculator::eval(equation, varMap));
    }
    catch (const calculator::error& err)
    {
        Print::PrintError("Cannot parse equation!");
    }

    return 0;
}

string Utility::readbackToString(vector<double> data)
{
    string result;

    for (size_t v = 0; v < data.size(); v++)
    {
        result += to_string(data[v]);
        if (v < data.size() - 1) result += "\n";
    }

    return result;
}

void Utility::checkMessageIntegrity(const string& request, const string& response, Instructions::Type type)
{
    try
    {
        switch (type)
        {
            case Instructions::Type::SWT: SWT::checkIntegrity(request, response);
                break;
            case Instructions::Type::SCA: SCA::checkIntegrity(request, response);
                break;
            case Instructions::Type::IC: IC::checkIntegrity(request, response);
                break;
            case Instructions::Type::CRORC: CRORC::checkIntegrity(request, response);
                break;
            case Instructions::Type::CRU: CRU::checkIntegrity(request, response);
                break;
        }
    }
    catch (exception& e)
    {
        throw runtime_error(e.what());
    }
}

uint128_t Utility::stringToLargeNumber(const string& number)
{
    bool isHex = false;
    string num = number;
    if (num.find("0x") != string::npos)
    {
        num = num.substr(num.find("0x") + 2);
        isHex = true;
    }

    if (num.size() == 0 || !all_of(num.begin(), num.end(), isHex ? ::isxdigit : ::isdigit))
    {
        throw invalid_argument("Not correctly formated number!");
    }

    if (isHex)
    {
        if (num.size() > 16)
        {
            string high = num.substr(0, num.size() - 16);
            string low = num.substr(num.size() - 16);

            uint128_t result = stoull(high, NULL, 16);
            result <<= 64;
            result |= stoull(low, NULL, 16);
            return result;
        }
        else
        {
            return stoull(num, NULL, 16);
        }
    }
    else
    {
        if (num.size() > 19)
        {
            string high = num.substr(0, num.size() - 19);
            string low = num.substr(num.size() - 19);

            uint128_t result = stoull(high, NULL, 10);
            result *= 10000000000000000000u;
            result |= stoull(low, NULL, 10);
            return result;
        }
        else
        {
            return stoull(num, NULL, 10);
        }
    }
}

uint32_t Utility::stringToNumber(const string& number)
{
    bool isHex = false;
    string num = number;
    if (num.find("0x") != string::npos)
    {
        num = num.substr(num.find("0x") + 2);
        isHex = true;
    }

    return stoul(num, NULL, isHex ? 16 : 10);
}

string Utility::largeNumberToHexString(const uint128_t number, bool addZeros)
{
    stringstream ss;

    if (addZeros)
    {
        ss << hex << setfill('0') << setw(16) << (uint64_t)(number >> 64) << setfill('0') << setw(16) << (uint64_t)(number & 0xFFFFFFFFFFFFFFFF);
    }
    else
    {
        if (number >> 64)
        {
            ss << hex << (uint64_t)(number >> 64) << setfill('0') << setw(16) << (uint64_t)(number & 0xFFFFFFFFFFFFFFFF);
        }
        else
        {
            ss << hex << (uint64_t)(number & 0xFFFFFFFFFFFFFFFF);
        }
    }

    return string("0x") + ss.str();
}

Utility::Utility()
{

}
