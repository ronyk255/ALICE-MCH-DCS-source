/* Uncomment commented lines and recompile to use MAPI example
*/

#include <stdio.h>
#include <fstream>
#include "Fred/fred.h"
//#include "Fred/global.h"
#include "Alfred/print.h"
/*#include "Mapi/mapiexample.h"*/
#include "Mapi/sampa_config.h"

int main(int argc, char** argv)
{
	bool parseOnly = Fred::commandLineArguments(argc, argv);
	//	pair<string, string> config = Fred::readConfigFile();
	Fred fred(parseOnly, Fred::readConfigFile(), "./sections");
	
	std::vector<int> chamblinks {12,24,12,24,26,26,26,26}; 
	std::vector<int> crulinks;
	std::vector<string> chambers {"1L","1R","2L","2R","5R","5L","6R","6L"};
	
	 //ch1L  
   for (int i=30; i <= 35; i++){crulinks.emplace_back(i);}
  for (int i=36; i <= 39; i++){crulinks.emplace_back(i);}
	for (int i=310; i <= 311; i++){crulinks.emplace_back(i);}
//ch1R
	for (int i=50; i <= 55; i++){crulinks.emplace_back(i);}
 for (int i=10; i <= 19; i++){crulinks.emplace_back(i);}
	for (int i=110; i <= 111; i++){crulinks.emplace_back(i);}
 for (int i=56; i <= 59; i++){crulinks.emplace_back(i);}
	for (int i=510; i <= 511; i++){crulinks.emplace_back(i);}
	
//ch2L
	for (int i=312; i <= 317; i++){crulinks.emplace_back(i);}
 for (int i=318; i <= 323; i++){crulinks.emplace_back(i);}
//ch2R
	for (int i=512; i <= 517; i++){crulinks.emplace_back(i);}
	for (int i=112; i <= 123; i++){crulinks.emplace_back(i);}
 for (int i=518; i <= 523; i++){crulinks.emplace_back(i);}
 //ch5R
 for (int i=318; i <= 322; i++){crulinks.emplace_back(i);}
	for (int i=312; i <= 317; i++){crulinks.emplace_back(i);}
	for (int i=50; i <= 55; i++){crulinks.emplace_back(i);}
	for (int i=512; i <= 517; i++){crulinks.emplace_back(i);}
	for (int i=56; i <= 58; i++){crulinks.emplace_back(i);}

//ch5L
	for (int i=16; i <= 17; i++){crulinks.emplace_back(i);}
	for (int i=111; i <= 111; i++){crulinks.emplace_back(i);}
	for (int i=19; i <= 19; i++){crulinks.emplace_back(i);}
	for (int i=110; i <= 110; i++){crulinks.emplace_back(i);}
	for (int i=10; i <= 15; i++){crulinks.emplace_back(i);}
	for (int i=112; i <= 117; i++){crulinks.emplace_back(i);}
	for (int i=30; i <= 35; i++){crulinks.emplace_back(i);}
	for (int i=118;i  <= 120; i++){crulinks.emplace_back(i);}

	//ch6R
	for (int i=312; i <= 314; i++){crulinks.emplace_back(i);}
	for (int i=318; i <= 323; i++){crulinks.emplace_back(i);}
	for (int i=50; i <= 55; i++){crulinks.emplace_back(i);}
	for (int i=512; i <= 522; i++){crulinks.emplace_back(i);}
//ch6L
	for (int i=10; i <= 12; i++){crulinks.emplace_back(i);}
	for (int i=16; i <= 19; i++){crulinks.emplace_back(i);}
	for (int i=110; i <= 117; i++){crulinks.emplace_back(i);}
	for (int i=30; i <= 35; i++){crulinks.emplace_back(i);}
	for (int i=36; i <= 39; i++){crulinks.emplace_back(i);}
	for (int i=310; i <= 310; i++){crulinks.emplace_back(i);}
 

	SampaConfig sampaConfig[crulinks.size()];
	int t = 0;
	try
	{   
		for (int r=0; r < chambers.size(); r++)
		{
			for (int i=1; i <= chamblinks[r]; i++)	
			{
				if (t >= crulinks.size())
				{
					printf("Size of sampa objects greater than size of links: ERROR!");
					return 0;
				}
				fred.registerMapiObject("FRED1/SAMPA_CONFIGCH"+chambers[r]+"/SOLAR"+std::to_string(crulinks[t])+"/SAMPA_REG", &sampaConfig[t]);
				t++;
			}
			
		}
	}

	catch (exception& e)
	{
		exit(EXIT_FAILURE);
	}

	fred.Start();
	return 0;
}

