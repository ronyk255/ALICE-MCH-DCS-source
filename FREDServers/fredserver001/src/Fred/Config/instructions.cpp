#include "Fred/Config/instructions.h"
#include "Parser/parser.h"
#include "Parser/utility.h"
#include "Alfred/print.h"
#include <regex>

Instructions::Instructions(vector<string> data, string currentPath)
{
    if (currentPath[currentPath.size() - 1] == '/') currentPath.erase(currentPath.size() - 1);

    size_t idx = 0;
    while (idx < data.size())
    {
        if (data[idx].find("PATH") != string::npos)
        {
            topics = processConfigFile(currentPath + "/" + data[idx].substr(data[idx].find("=") + 1));
        }
        idx++;
    }
}

vector<string> Instructions::processConfigFile(string file)
{
    this->path = file;

    vector<string> topics;

    vector<string> lines = Parser::readFile(this->path, ".");
    if (!lines.empty())
    {
        vector<string> rest = lines;
        while (!rest.empty())
        {
            string name;
            vector<string> temp;
            vector<string> subsection = Parser::getSubsection(rest, "{}", name, temp);
            rest = temp;

            regex rgx ("^(\\w|-|/|:)+$");

            if(!std::regex_match(name, rgx))
            {
                throw runtime_error("Topic " + name + " in file " + file + " contains bad character(s)");
            }

            Instruction instruction;
            //instruction.subscribe = false;
            instruction.name = name;

            topics.push_back(name);

            for (size_t i = 0; i < subsection.size(); i++)
            {
                string left = subsection[i].substr(0, subsection[i].find("="));
                string right = subsection[i].substr(subsection[i].find("=") + 1);

                if (left == "TYPE")
                {
                    if (right == "SWT")
                    {
                        instruction.type = Type::SWT;
                    }
                    else if (right == "SCA")
                    {
                        instruction.type = Type::SCA;
                    }
                    else if (right == "IC")
                    {
                        instruction.type = Type::IC;
                    }
                    else if (right == "CRORC")
                    {
                        instruction.type = Type::CRORC;
                    }
                    else if(right == "CRU")
                    {
                        instruction.type = Type::CRU;
                    }
                    else throw runtime_error(this->path + " has invalid type name " + right + " in topic " + name);
                }
                //else if (left == "SUBSCRIBE")
                //{
                //    instruction.subscribe = right == "TRUE" ? true : false;
                //}
                else if (left == "EQUATION")
                {
                    instruction.equation = right;
                }
                else if (left == "IN_VAR")
                {
                    instruction.inVars = Utility::splitString(right, ","); //Process IN_VARs
                }
                else if (left == "OUT_VAR")
                {
                    instruction.outVars = Utility::splitString(right, ","); //Process OUT_VARs
                }
                else if (left == "MESSAGE")
                {
                    instruction.message = Utility::splitString(right, "\\n"); //allow usage of \n in MESSAGE part
                }
                else if (left == "FILE")
                {
                    instruction.message = processSequenceFile(this->path.substr(0, this->path.find_last_of("/")) + "/" + right);
                    if (instruction.message.empty()) throw runtime_error("Sequence File in TOPIC " + name + " topic doesn't exist or is empty");
                }
                else throw runtime_error(this->path + " has invalid instruction name " + left + " in topic " + name + "!");
            }

            if (!instruction.message.empty()) instruction.vars = processSequenceVars(instruction.message); //Process VARs

            for (auto it = instruction.outVars.begin(); it != instruction.outVars.end(); it++)
            {
                if (find(instruction.vars.begin(), instruction.vars.end(), *it) == instruction.vars.end())
                {
                    if (*it == "EQUATION") //EQUATION keyword for returining the result of the equation
                    {
                        if (instruction.equation == "") throw runtime_error("The EQUATION in TOPIC " + instruction.name + " is published but no equation is provided!");
                    }
                    else throw runtime_error("OUT_VAR " + *it + " in TOPIC " + instruction.name + " string is published without being decleared in the sequence!");
                }
            }
 
            instruction.inVars.insert(instruction.inVars.begin(), "_ID_"); //number determined by location of element in the mapping
            instructions[instruction.name] = instruction;
        }

        return topics;

    } //if not empty
    else throw runtime_error("Instructions parsing failure!");
}

vector<string> Instructions::processSequenceFile(string file)
{
    return Parser::readFile(file, ".");
}

/*
 * Get VARs from sequence  
 */
vector<string> Instructions::processSequenceVars(const vector<string>& message)
{
    vector<string> vars;

    for (size_t i = 0; i < message.size(); i++)
    {
        string line = message[i];
        size_t atPos = line.find('@');
        if (atPos != string::npos)
        {
            vars.push_back(line.substr(atPos + 1));
        }
    }

    return vars;
}

map<string, Instructions::Instruction>& Instructions::getInstructions()
{
    return instructions;
}

vector<string>& Instructions::getTopics()
{
    return topics;
}
