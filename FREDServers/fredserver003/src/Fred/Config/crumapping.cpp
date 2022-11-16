#include "Fred/Config/crumapping.h"
#include "Parser/utility.h"

CruMapping::CruMapping(vector<string> data)
{
    for (size_t i = 0; i < data.size(); i++)
    {
        if (data[i].find("=") != string::npos)
        {
            string left = data[i].substr(0, data[i].find("="));
            string right = data[i].substr(data[i].find("=") + 1);
            processCruUnit(left, right);
        }
    }
}

void CruMapping::processCruUnit(string& left, string& right)
{
    CruUnit unit;

    unit.cruUnitName = left;

    vector<string> path = Utility::splitString(right, "/");
    if (path.size() == 2)
    {
        CruUnit::Alf alf;
        alf.alfId = path[0];
        alf.serialId = stoi(path[1].substr(path[1].find("_") + 1)); //SERIAL_x

        if (alf.alfId.find("ALF") == 0)
        {
            processLocation(alf.alfId, alf.serialId);
            unit.alf = alf;
        }
    }

    cruUnits.push_back(unit);
}

void CruMapping::processLocation(string alfId, int32_t serialId)
{
    if (!alfs.count(alfId)) //new ALF
    {
        AlfEntry::SerialEntry serialEntry;
        serialEntry.id = serialId;

        AlfEntry NewAlfEntry;
        NewAlfEntry.id = alfId;
        NewAlfEntry.serials[serialId] = serialEntry;

        alfs[alfId] = NewAlfEntry;
    }
    else //already existing ALF
    {
        if (!alfs[alfId].serials.count(serialId)) //new serial
        {
            AlfEntry::SerialEntry NewSerialEntry;
            NewSerialEntry.id = serialId;

            alfs[alfId].serials[serialId] = NewSerialEntry;
        }
    }
}

vector<CruMapping::CruUnit>& CruMapping::getCruUnits()
{
    return cruUnits;
}

map<string, Location::AlfEntry>& CruMapping::alfList()
{
    return alfs;
}
