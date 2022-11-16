#ifndef INSTRUCTIONS_H
#define INSTRUCTIONS_H

#include <string>
#include <vector>
#include <map>

using namespace std;

class Instructions
{
public:
    Instructions(vector<string> data = vector<string>(), string currentPath = ".");

    enum Type
    {
        SCA,
        SWT,
        IC,
        CRORC,
        CRU
    };

    struct Instruction
    {
        string name;
        Type type;
        string equation;
        vector<string> inVars; // IN_VARs, variables to insert input values in the sequence files
        vector<string> vars; // VARs, the variables proceded by "@" in the sequence files
        vector<string> outVars; // OUT_VARs are the VARs that are published

        vector<string> message;
        //bool subscribe;
    };

    map<string, Instruction>& getInstructions();
    vector<string>& getTopics();

private:
    string path;
    vector<string> topics;
    map<string, Instruction> instructions;

    vector<string> processConfigFile(string file);
    vector<string> processSequenceFile(string file);
    vector<string> processSequenceVars(const vector<string>& message);
};

#endif // INSTRUCTIONS_H
