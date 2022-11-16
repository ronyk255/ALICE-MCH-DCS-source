#ifndef ITERATIVEMAPI_H
#define ITERATIVEMAPI_H

#include <iostream>
#include <string>
#include <algorithm>
#include <vector>
#include "Fred/Mapi/mapi.h"

using namespace std;

class Iterativemapi: public Mapi
{
public:
    void newRequest(string request);
};

#endif // ITERATIVEMAPI_H
