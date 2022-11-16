#include <ctime>
#include <chrono>
#include <iomanip>

#include <sstream>
#include <algorithm>
#include <string>
#include <iostream>
#include <sstream>
#include "Alfred/print.h"
#include "Mapi/sampa_config.h"



void SampaCmdQueue::addCommand(sampa_config_cmd_t& cmd)
{
	lock.lock();
	stack.push_back(cmd);
	std::cout<<"pushed command to queue: "
	<<std::get<0>(cmd)<<"  "
	<<std::get<1>(cmd)<<"  "
	<<std::get<2>(cmd)<<"  "
	<<std::get<3>(cmd)<<"  "
	<<std::get<4>(cmd)<<"  "
	<<std::endl;
	lock.unlock();
}

bool SampaCmdQueue::getNextCommand(sampa_config_cmd_t& cmd)
{
	bool result = false;
	lock.lock();
	if( !stack.empty() ) {
		cmd = stack.front();
		stack.pop_front();
		std::cout<<"popped command to queue: "
		<<std::get<0>(cmd)<<"  "
		<<std::get<1>(cmd)<<"  "
		<<std::get<2>(cmd)<<"  "
		<<std::get<3>(cmd)<<"  "
		<<std::get<4>(cmd)<<"  "
		<<std::endl;
		result = true;
	}
	lock.unlock();
	return result;
}


SampaConfig::SampaConfig(): request_trid_(100)
{
	//your constructor
}


std::string SampaConfig::readByte(uint32_t daddr, uint32_t raddr)
{
	const sca_rgf_t& rgf = I2C_S_10B_R;
	uint32_t data = addressToD1D0(daddr, raddr);
	HdlcEcFramePayload request{request_trid_, group+3, std::get<1>(rgf), {std::get<0>(rgf)}, adjustByteOrder(rgf, data)};

	request_trid_ = (request_trid_ % 0xfe) + 1;


	uint32_t wdata, wcmd;
	assembleRegisters(request, wcmd, wdata);
	char tstr[500];
	snprintf(tstr,499,"%08X,%08X",wcmd,wdata);
	std::string output = tstr;
	//printf("SampaConfig::processInputMessage: output=\"%s\"\n", output.c_str());
	//output.erase(remove(output.begin(), output.end(), '\n'), output.end());

	return output; //send message to the ALF
}


std::string SampaConfig::writeByte(uint32_t daddr, uint32_t raddr, uint8_t value)
{
	const sca_rgf_t& rgf = I2C_S_10B_W;
	uint32_t data = (uint32_t(value) << 16) | addressToD1D0(daddr, raddr);
	HdlcEcFramePayload request{request_trid_, group+3, std::get<1>(rgf), {std::get<0>(rgf)}, adjustByteOrder(rgf, data)};

	request_trid_ = (request_trid_ % 0xfe) + 1;


	uint32_t wdata, wcmd;
	assembleRegisters(request, wcmd, wdata);
	char tstr[500];
	snprintf(tstr,499,"%08X,%08X",wcmd,wdata);
	std::string output = tstr;
	//printf("SampaConfig::processInputMessage: output=\"%s\"\n", output.c_str());
	//output.erase(remove(output.begin(), output.end(), '\n'), output.end());

	return output; //send message to the ALF
}


string SampaConfig::writeGlobalRegister()
{
	string output;
	std::string cmd1 = writeByte(chip, reg, value);
	std::string cmd2 = readByte(chip, reg);
	//output = cmd1 + "\n" + cmd2 + "\n" + cmd3 + "\n" + cmd4;
	output = cmd1 + "\n" + cmd2;
	//printf("SampaConfig::writeGlobalRegister: output=\"%s\"\n", output.c_str());

	return output;
}


string SampaConfig::checkGlobalRegister(string output, const sampa_config_cmd_t& cmd)
{
	std::istringstream f(output);
	std::string line;
	uint32_t w1, w2;
	HdlcEcFramePayload reply;

	int trid = std::get<0>(cmd);
	int chip = std::get<1>(cmd);
	int chan = std::get<2>(cmd);
	int reg = std::get<3>(cmd);
	int value = std::get<4>(cmd);
	int group = chip / 10;
	chip = chip % 10;

	// 1st line
	//if( !std::getline(f, line) ) return "failure";
	//if( line != "success" ) return "failure";

	// 2nd line
	//if( !std::getline(f, line) ) return "failure";
	sscanf(line.c_str(),"%X,%X", &w1, &w2);
	disassembleRegisters(reply, w1, w2);
	//printf("line=\"%s\"  w1=%08X  w2=%08X  channel=%d  error=%d  data=%08X\n",
	//line.c_str(), (int)w1, (int)w2, (int)reply.channel, (int)reply.error, (int)reply.data);
	//std::cout << line << "  " << w1 << "  " << w2 << "  channel="<<r.channel<<"  error="<<r.error<<std::endl;
	//if( (reply.trid) != trid ) return "failure";
	//if( (reply.channel) != group+3 ) return "failure";
	//if( (reply.data & 0xFF) != 0x04 ) return "failure";

	// Exception for soft-reset command
	if( (reg != 0x0e) || (value != 0x05) ) {
		// 3rd line
		if( !std::getline(f, line) ) return "failure";
		sscanf(line.c_str(),"%X,%X", &w1, &w2);
		//printf("line=\"%s\"  w1=%08X  w2=%08X  channel=%d  error=%d  data=%08X\n",
		//line.c_str(), (int)w1, (int)w2, (int)reply.channel, (int)reply.error, (int)reply.data);
		//std::cout << line << "  " << w1 << "  " << w2 << std::endl;
		disassembleRegisters(reply, w1, w2);
		//if( (reply.channel) != group+3 ) return "failure";
		//if( (reply.data & 0xFF) != 0x04 ) return "failure";
		uint32_t retvalue = (reply.data >> 8) & 0xFF;
		std::cout<<"value="<<value<<"  retvalue="<<retvalue<<std::endl;
		//if( value != retvalue ) return "failure";
	}

	string response = "success";

	return response; //send answer back to WinCC
}


string SampaConfig::writeChannelRegister()
{
	string output;
	std::string cmd1 = writeByte(chip, 0x17, reg);
	std::string cmd2 = writeByte(chip, 0x18, value & 0xFF);
	std::string cmd3 = writeByte(chip, 0x19, (value>>8) & 0xFF);
	std::string cmd4 = writeByte(chip, 0x1A, ((chan) & 0x1F) + 0x40);

	std::string cmd5 = writeByte(chip, 0x17, reg);
	std::string cmd6 = writeByte(chip, 0x1A, (chan) & 0x1F);

	std::string cmd7 = readByte(chip, 0x1B);
	std::string cmd8 = readByte(chip, 0x1C);

	//output = cmd1 + "\n" + cmd2 + "\n" + cmd3 + "\n" + cmd4;
	output = cmd1 + "\n" + cmd2 + "\n" + cmd3 + "\n" + cmd4 + "\n" + cmd5 + "\n"
	+ cmd6 + "\n" + cmd7 + "\n" + cmd8;
	//printf("SampaConfig::writeGlobalRegister: output=\"%s\"\n", output.c_str());

	return output;
}


string SampaConfig::checkChannelRegister(string output, const sampa_config_cmd_t& cmd)
{
	std::istringstream f(output);
	std::string line;
	uint32_t w1, w2;
	HdlcEcFramePayload reply;

	int trid = std::get<0>(cmd);
	int chip = std::get<1>(cmd);
	int chan = std::get<2>(cmd);
	int reg = std::get<3>(cmd);
	int value = std::get<4>(cmd);
	int group = chip / 10;
	chip = chip % 10;

	// 1st line
	if( !std::getline(f, line) ) return "failure";
	if( line != "success" ) return "failure";

	for(int i = 0; i < 6; i++) {
		if( !std::getline(f, line) ) return "failure";
		sscanf(line.c_str(),"%X,%X", &w1, &w2);
		disassembleRegisters(reply, w1, w2);
		//printf("line=\"%s\"  w1=%08X  w2=%08X  channel=%d  error=%d  data=%08X\n",
		//line.c_str(), (int)w1, (int)w2, (int)reply.channel, (int)reply.error, (int)reply.data);
		//std::cout << line << "  " << w1 << "  " << w2 << "  channel="<<r.channel<<"  error="<<r.error<<std::endl;
		if( i == 0 ) {
			if( (reply.trid) != trid ) return "failure";
		}
		if( (reply.channel) != group+3 ) return "failure";
		if( (reply.data & 0xFF) != 0x04 ) return "failure";
	}

	uint32_t retvalue = 0;

	// 1st data word
	if( !std::getline(f, line) ) return "failure";
	sscanf(line.c_str(),"%X,%X", &w1, &w2);
	//printf("line=\"%s\"  w1=%08X  w2=%08X  channel=%d  error=%d  data=%08X\n",
	//line.c_str(), (int)w1, (int)w2, (int)reply.channel, (int)reply.error, (int)reply.data);
	//std::cout << line << "  " << w1 << "  " << w2 << std::endl;
	disassembleRegisters(reply, w1, w2);
	if( (reply.channel) != group+3 ) return "failure";
	if( (reply.data & 0xFF) != 0x04 ) return "failure";
	retvalue += (reply.data >> 8) & 0xFF;

	// 2nd data word
	if( !std::getline(f, line) ) return "failure";
	sscanf(line.c_str(),"%X,%X", &w1, &w2);
	//printf("line=\"%s\"  w1=%08X  w2=%08X  channel=%d  error=%d  data=%08X\n",
	//line.c_str(), (int)w1, (int)w2, (int)reply.channel, (int)reply.error, (int)reply.data);
	//std::cout << line << "  " << w1 << "  " << w2 << std::endl;
	disassembleRegisters(reply, w1, w2);
	if( (reply.channel) != group+3 ) return "failure";
	if( (reply.data & 0xFF) != 0x04 ) return "failure";
	retvalue += (((reply.data >> 8) & 0xFF) << 8) & 0xFF00;


	std::cout<<"value="<<value<<"  retvalue="<<retvalue<<std::endl;
	if( value != retvalue ) return "failure";


	string response = "success";

	return response; //send answer back to WinCC
}

void SampaConfig::processExecution()
{
	std::string name = "SampaConfig";
	bool running;
	string input = this->waitForRequest(running); // wait for incomming request from WinCC, received response is returned by the function

	if (!running) // if FRED was stopped (by ctrl c) while waiting for request from WinCC, return from processExecution function
	{
		return;
	}

	auto tStart = std::chrono::steady_clock::now();
	const std::chrono::time_point<std::chrono::system_clock> now1 = std::chrono::system_clock::now();
	const std::time_t t_c1 = std::chrono::system_clock::to_time_t(now1);
	Print::PrintError(name + "processExecution request received at " + std::asctime(std::localtime(&t_c1)));

	//input - message received from DIM command
	// string request = "12345678";

	vector<string> v;
	//vector<vector<string>> vs;
	stringstream ss(input);
	// printf("SampaConfig::processInputMessage_input: input()=\"%d\"\n", input.c_str());

	while (ss.good()) {
		string substr;
		getline(ss,substr,',');
		v.push_back(substr);
	}

	// printf("SampaConfig::processInputMessage_vsize: v.size()=\"%d\"\n", v.size());

	/*	for (size_t i=0; i < v.size(); i++) {
		printf("SampaConfig::processInputMessageinitial: v[i]=\"%s\"\n", v[i].c_str());
	}*/

	int r2=0,r1=0;
	string output,answer;
	sampa_config_cmd_t cmd;
	int nRegs = (v.size() > 0) ? std::stoi(v[0]) : 0;
	//if (v.size() % 22 == 0 && v.size() % 218 != 0) { // processes pedestal configs 22 per board
	//  nRegs = 22;
	//}
	//if (v.size() % 22 != 0 && v.size() % 218 == 0) { // processes pedestal configs 22 per board
	//  nRegs = 218;
	//}

	if (nRegs == 0) {
		//Print::PrintError(name + "processExecution v.size()=" + std::to_string(v.size()));
		return;
	}

	const size_t nIterations = 3;

	for (size_t i=1; i < v.size(); i += nRegs) { //12

		output = ""; // maybe clean output string? in case of more iterations of the loop are executed, please check
		//answer = "";
		r1 = i;
		r2 = r1 + nRegs;

		string msg;

		//std::cout<<"SampaConfig::processInputMessage: input=\""<<input<<"\"\n";
		// printf("SampaConfig::processInputMessage: input=\"%s\"\n", input.c_str());

		while (r1 < r2)
		{
			//  printf("SampaConfig::processInputMessage: v[%d]=\"%s\"\n",r1, v[r1].c_str());
			istringstream istr(v[r1]);
			istr >> chip >> chan >> reg >> value;
			if( !istr ) {
				if( sscanf(v[r1].c_str(), "%i %i %i %i", &chip, &chan, &reg, &value) != 4 ) {
					//    printf("SampaConfig::processInputMessage: failed parsing input\n");
					group = chip = chan = reg = value = -1;
					//return v[r2];
					this->publishAnswer("Wrong Format"); // don't know what error to publish, maybe you meant v[r2] to be published to the WinCC?
					// please check if you want to publish to _ERR or _ANS DIM service, as explained below
					return;
				}
			}

			group = chip / 10;
			chip = chip % 10;

			if( chan < 0 ) msg = writeGlobalRegister();
			else msg = writeChannelRegister();
		//	printf("SampaConfig::processInputMessage_vsize: msg=\"%d\"\n", msg.size());
			if (output.empty()) output = msg;
			else {
				output += "\n";
				output += msg;
			}
			r1++;
		}

	  // do up to nIterations attempts to configure this board
    std::string result;
    for (size_t iter = 0; iter < nIterations; iter++) {
      result = "";

      //	printf("SampaConfig::executeAlfSequence before\n");
      //  printf("SampaConfig::executeAlfSequence: output=\"%s\"\n\n", output.c_str());
      output = this->executeAlfSequence(output); // this function allows you to send request to ALF as many times as you need from single WinCC call
      // it returns back response from the ALF
      printf("SampaConfig::executeAlfSequence after\n");
      //output - message received from the ALF

      // // here is the code from original processOutput function
      //	printf("SampaConfig::processOutputMessage: output2=\"%s\"\n\n", output.c_str());

      bool ok = true;
      std::string line;
      if (output == "") {
        result = "failure";
        ok = false;
      } else {
        std::istringstream iss(output);
        if (std::getline(iss, line) && line == "failure") {
          result = "failure";
          ok = false;
        } else {
          result = "success";
          while (std::getline(iss, line)) {
            uint32_t command, data;
            std::istringstream iss2(line);
            std::string scommand, sdata;
            if (!std::getline(iss, scommand, ',')) {
              break;
            }
            if (!std::getline(iss, sdata, ',')) {
               break;
            }

            sscanf(sdata.c_str(), "0x%X", &data);
            if (((data & 0x04000000) == 0) && ((data & 0x68000000) != 0)) {
              result = "failure";
              ok = false;
            }
          }
        }
      }

      if (ok) {
        break;
      }
	  }

		answer += result + " ";

		if( chan < 0 )
		{
			//return checkGlobalRegister(output, cmd);
			// printf("firstcheckGlobal");
			// this->publishAnswer(checkGlobalRegister(output, cmd));
		}
		else
		{
			//printf("firstcheckChannel");
			//return checkChannelRegister(output, cmd);
			//this->publishAnswer(checkChannelRegister(output, cmd));
		}
	}

//	Print::PrintError(name + " processExecution answer= \"" + answer + "\"");
	//	printf("SampaConfig::processOutputMessage: answer=\"%s\"\n ", answer.c_str());
	this->publishAnswer(answer);
	auto tEnd = std::chrono::steady_clock::now();

	const std::chrono::time_point<std::chrono::system_clock> now2 = std::chrono::system_clock::now();
	const std::time_t t_c2 = std::chrono::system_clock::to_time_t(now2);
	//Print::PrintError(name + " processExecution answer published at " + std::asctime(std::localtime(&t_c2)) + ", took " + std::to_string(std::chrono::duration<double>(tEnd - tStart).count()) + " s");
}
