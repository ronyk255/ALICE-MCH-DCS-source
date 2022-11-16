#include "Fred/Config/location.h"
#include "Fred/Config/mapping.h"
#include "Parser/utility.h"

Mapping::Mapping(vector<string> data)
{
    for (size_t i = 0; i < data.size(); i++)
    {
        if (data[i].find("=") != string::npos)
        {
            string left = data[i].substr(0, data[i].find("="));
            string right = data[i].substr(data[i].find("=") + 1);
            processUnit(left, right);
        }
    }
}

void Mapping::processUnit(string& left, string& right)
{
    Unit unit;

    size_t leftBr = left.find("[");
    size_t rightBr = left.find("]");

    if (leftBr == string::npos || rightBr == string::npos || rightBr <= leftBr)
    {
        throw runtime_error("Unit IDs have to be specified in brackets");
    }

    string name = left.substr(0, leftBr) + MAPPING_UNIT_DELIMITER + left.substr(rightBr + 1);
    string unitIds = left.substr(leftBr + 1, rightBr - leftBr - 1);

    unit.unitName = name;

    vector<string> ids = Utility::splitString(unitIds, ",");
    for (size_t i = 0; i < ids.size(); i++)
    {
        if (ids[i] == "x") unit.unitIds.push_back(-1);
        else unit.unitIds.push_back(stoi(ids[i]));
    }

    vector<string> paths = Utility::splitString(right, ",");
    for (size_t i = 0; i < paths.size(); i++)
    {
        AlfEntry::SerialEntry::CardType cardType = AlfEntry::SerialEntry::CardType::CRU;
        size_t leftBr = paths[i].find("(");
        size_t rightBr = paths[i].find(")");
        if (leftBr == 0 && rightBr != string::npos)
        {
            string cardTypeName = paths[i].substr(leftBr + 1, rightBr - leftBr - 1);
            if (cardTypeName == "CRU")
            {
                cardType = AlfEntry::SerialEntry::CardType::CRU;
            }
            else if (cardTypeName == "CRORC")
            {
                cardType = AlfEntry::SerialEntry::CardType::CRORC;
            }
            else
            {
                throw runtime_error("Unknown card type: " + cardTypeName);
            }

            paths[i] = paths[i].substr(rightBr + 1);
        }

        vector<string> path = Utility::splitString(paths[i], "/");
        if (path.size() == 3 || path.size() == 4)
        {
            Unit::Alf alf;
            alf.version = path.size() == 3 ? AlfEntry::Version::v0 : AlfEntry::Version::v1;
            alf.alfId = path[0]; //ALF_x
            alf.serialId = stoi(path[1].substr(path[1].find("_") + 1)); //SERIAL_x
            if (alf.version == AlfEntry::Version::v0)
            {
                alf.endpointId = -1;
                alf.linkId = stoi(path[2].substr(path[2].find("_") + 1)); //LINK_x
            }
            else
            {
                alf.endpointId = stoi(path[2].substr(path[2].find("_") + 1)); //ENDPOINT_x
                alf.linkId = stoi(path[3].substr(path[3].find("_") + 1)); //LINK_x
            }

            if (path[0].find("ALF") == 0)
            {
                processLocation(alf.alfId, alf.serialId, alf.endpointId, alf.linkId, cardType);
                unit.alfs.first = alf;
            }
            else if (path[0].find("CANALF") == 0)
            {
                if (alf.version == AlfEntry::Version::v1)
                {
                    throw runtime_error("CANALF doesn't have an endpoint");
                }
                processLocation(alf.alfId, alf.serialId, alf.endpointId, alf.linkId, AlfEntry::SerialEntry::CardType::CRU);
                unit.alfs.second = alf;
            }
        }
        else if (path.size() == 2) // CRU level
        {
            if (cardType != AlfEntry::SerialEntry::CardType::CRU)
            {
                throw runtime_error("CRORC doesn't have CRU level services");
            }

            Unit::Alf alf;
            alf.version = AlfEntry::Version::v1;
            alf.alfId = path[0]; //ALF_x
            alf.serialId = stoi(path[1].substr(path[1].find("_") + 1)); //SERIAL_x
            alf.endpointId = -1;
            alf.linkId = -1;

            if (path[0].find("ALF") != 0)
            {
                throw runtime_error("CANALF doesn't have CRU level services");
            }

            processLocation(alf.alfId, alf.serialId, alf.endpointId, alf.linkId, cardType);
            unit.alfs.first = alf;
        }
    }

    units.push_back(unit);
}

void Mapping::processLocation(string alfId, int32_t serialId, int32_t endpointId, int32_t linkId, AlfEntry::SerialEntry::CardType cardType)
{
    if (!alfs.count(alfId)) //new ALF
    {
        AlfEntry::SerialEntry::EndpointEntry endpointEntry;
        endpointEntry.id = endpointId;
        endpointEntry.links.push_back(linkId);

        AlfEntry::SerialEntry serialEntry;
        serialEntry.id = serialId;
        serialEntry.endpoints[endpointId] = endpointEntry;
        serialEntry.cardType = cardType;

        AlfEntry NewAlfEntry;
        NewAlfEntry.id = alfId;
        NewAlfEntry.serials[serialId] = serialEntry;
        NewAlfEntry.version = (endpointId == -1 && linkId != -1) ? AlfEntry::Version::v0 : AlfEntry::Version::v1;

        alfs[alfId] = NewAlfEntry;
    }
    else //already existing ALF
    {
        if (((endpointId == -1 && linkId != -1) ? AlfEntry::Version::v0 : AlfEntry::Version::v1) != alfs[alfId].version)
        {
            throw runtime_error("ALF_" + alfId + " - version mismatch");
        }

        if (!alfs[alfId].serials.count(serialId)) //new serial
        {
            AlfEntry::SerialEntry::EndpointEntry endpointEntry;
            endpointEntry.id = endpointId;
            endpointEntry.links.push_back(linkId);

            AlfEntry::SerialEntry NewSerialEntry;
            NewSerialEntry.id = serialId;
            NewSerialEntry.endpoints[endpointId] = endpointEntry;
            NewSerialEntry.cardType = cardType;

            alfs[alfId].serials[serialId] = NewSerialEntry;
        }
        else //already existing serial
        {
            if (alfs[alfId].serials[serialId].cardType != cardType)
            {
                throw runtime_error("ALF_" + alfId + "/SERIAL_" + to_string(serialId) + " - card type mismatch");
            }

            if (!alfs[alfId].serials[serialId].endpoints.count(endpointId)) //new endpoint
            {
                AlfEntry::SerialEntry::EndpointEntry NewEndpointEntry;
                NewEndpointEntry.id = endpointId;
                NewEndpointEntry.links.push_back(linkId);

                alfs[alfId].serials[serialId].endpoints[endpointId] = NewEndpointEntry;
            }
            else //already existing endpoint
            {
                alfs[alfId].serials[serialId].endpoints[endpointId].links.push_back(linkId);
            }
        }
    }
}

vector<Mapping::Unit>& Mapping::getUnits()
{
    return units;
}

map<string, Location::AlfEntry>& Mapping::alfList()
{
    return alfs;
}
