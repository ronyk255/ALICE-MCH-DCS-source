# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.17

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Disable VCS-based implicit rules.
% : %,v


# Disable VCS-based implicit rules.
% : RCS/%


# Disable VCS-based implicit rules.
% : RCS/%,v


# Disable VCS-based implicit rules.
% : SCCS/s.%


# Disable VCS-based implicit rules.
% : s.%


.SUFFIXES: .hpux_make_needs_suffix_list


# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake3

# The command to remove a file.
RM = /usr/bin/cmake3 -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /opt/fredserver

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /opt/fredserver

# Include any dependencies generated for this target.
include CMakeFiles/Alfred.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/Alfred.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/Alfred.dir/flags.make

CMakeFiles/Alfred.dir/src/Alfred/alfred.cpp.o: CMakeFiles/Alfred.dir/flags.make
CMakeFiles/Alfred.dir/src/Alfred/alfred.cpp.o: src/Alfred/alfred.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/opt/fredserver/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/Alfred.dir/src/Alfred/alfred.cpp.o"
	/opt/rh/devtoolset-7/root/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/Alfred.dir/src/Alfred/alfred.cpp.o -c /opt/fredserver/src/Alfred/alfred.cpp

CMakeFiles/Alfred.dir/src/Alfred/alfred.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/Alfred.dir/src/Alfred/alfred.cpp.i"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /opt/fredserver/src/Alfred/alfred.cpp > CMakeFiles/Alfred.dir/src/Alfred/alfred.cpp.i

CMakeFiles/Alfred.dir/src/Alfred/alfred.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/Alfred.dir/src/Alfred/alfred.cpp.s"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /opt/fredserver/src/Alfred/alfred.cpp -o CMakeFiles/Alfred.dir/src/Alfred/alfred.cpp.s

CMakeFiles/Alfred.dir/src/Alfred/client.cpp.o: CMakeFiles/Alfred.dir/flags.make
CMakeFiles/Alfred.dir/src/Alfred/client.cpp.o: src/Alfred/client.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/opt/fredserver/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building CXX object CMakeFiles/Alfred.dir/src/Alfred/client.cpp.o"
	/opt/rh/devtoolset-7/root/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/Alfred.dir/src/Alfred/client.cpp.o -c /opt/fredserver/src/Alfred/client.cpp

CMakeFiles/Alfred.dir/src/Alfred/client.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/Alfred.dir/src/Alfred/client.cpp.i"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /opt/fredserver/src/Alfred/client.cpp > CMakeFiles/Alfred.dir/src/Alfred/client.cpp.i

CMakeFiles/Alfred.dir/src/Alfred/client.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/Alfred.dir/src/Alfred/client.cpp.s"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /opt/fredserver/src/Alfred/client.cpp -o CMakeFiles/Alfred.dir/src/Alfred/client.cpp.s

CMakeFiles/Alfred.dir/src/Alfred/command.cpp.o: CMakeFiles/Alfred.dir/flags.make
CMakeFiles/Alfred.dir/src/Alfred/command.cpp.o: src/Alfred/command.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/opt/fredserver/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Building CXX object CMakeFiles/Alfred.dir/src/Alfred/command.cpp.o"
	/opt/rh/devtoolset-7/root/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/Alfred.dir/src/Alfred/command.cpp.o -c /opt/fredserver/src/Alfred/command.cpp

CMakeFiles/Alfred.dir/src/Alfred/command.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/Alfred.dir/src/Alfred/command.cpp.i"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /opt/fredserver/src/Alfred/command.cpp > CMakeFiles/Alfred.dir/src/Alfred/command.cpp.i

CMakeFiles/Alfred.dir/src/Alfred/command.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/Alfred.dir/src/Alfred/command.cpp.s"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /opt/fredserver/src/Alfred/command.cpp -o CMakeFiles/Alfred.dir/src/Alfred/command.cpp.s

CMakeFiles/Alfred.dir/src/Alfred/info.cpp.o: CMakeFiles/Alfred.dir/flags.make
CMakeFiles/Alfred.dir/src/Alfred/info.cpp.o: src/Alfred/info.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/opt/fredserver/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Building CXX object CMakeFiles/Alfred.dir/src/Alfred/info.cpp.o"
	/opt/rh/devtoolset-7/root/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/Alfred.dir/src/Alfred/info.cpp.o -c /opt/fredserver/src/Alfred/info.cpp

CMakeFiles/Alfred.dir/src/Alfred/info.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/Alfred.dir/src/Alfred/info.cpp.i"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /opt/fredserver/src/Alfred/info.cpp > CMakeFiles/Alfred.dir/src/Alfred/info.cpp.i

CMakeFiles/Alfred.dir/src/Alfred/info.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/Alfred.dir/src/Alfred/info.cpp.s"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /opt/fredserver/src/Alfred/info.cpp -o CMakeFiles/Alfred.dir/src/Alfred/info.cpp.s

CMakeFiles/Alfred.dir/src/Alfred/print.cpp.o: CMakeFiles/Alfred.dir/flags.make
CMakeFiles/Alfred.dir/src/Alfred/print.cpp.o: src/Alfred/print.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/opt/fredserver/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Building CXX object CMakeFiles/Alfred.dir/src/Alfred/print.cpp.o"
	/opt/rh/devtoolset-7/root/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/Alfred.dir/src/Alfred/print.cpp.o -c /opt/fredserver/src/Alfred/print.cpp

CMakeFiles/Alfred.dir/src/Alfred/print.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/Alfred.dir/src/Alfred/print.cpp.i"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /opt/fredserver/src/Alfred/print.cpp > CMakeFiles/Alfred.dir/src/Alfred/print.cpp.i

CMakeFiles/Alfred.dir/src/Alfred/print.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/Alfred.dir/src/Alfred/print.cpp.s"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /opt/fredserver/src/Alfred/print.cpp -o CMakeFiles/Alfred.dir/src/Alfred/print.cpp.s

CMakeFiles/Alfred.dir/src/Alfred/rpc.cpp.o: CMakeFiles/Alfred.dir/flags.make
CMakeFiles/Alfred.dir/src/Alfred/rpc.cpp.o: src/Alfred/rpc.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/opt/fredserver/CMakeFiles --progress-num=$(CMAKE_PROGRESS_6) "Building CXX object CMakeFiles/Alfred.dir/src/Alfred/rpc.cpp.o"
	/opt/rh/devtoolset-7/root/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/Alfred.dir/src/Alfred/rpc.cpp.o -c /opt/fredserver/src/Alfred/rpc.cpp

CMakeFiles/Alfred.dir/src/Alfred/rpc.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/Alfred.dir/src/Alfred/rpc.cpp.i"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /opt/fredserver/src/Alfred/rpc.cpp > CMakeFiles/Alfred.dir/src/Alfred/rpc.cpp.i

CMakeFiles/Alfred.dir/src/Alfred/rpc.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/Alfred.dir/src/Alfred/rpc.cpp.s"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /opt/fredserver/src/Alfred/rpc.cpp -o CMakeFiles/Alfred.dir/src/Alfred/rpc.cpp.s

CMakeFiles/Alfred.dir/src/Alfred/rpcinfo.cpp.o: CMakeFiles/Alfred.dir/flags.make
CMakeFiles/Alfred.dir/src/Alfred/rpcinfo.cpp.o: src/Alfred/rpcinfo.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/opt/fredserver/CMakeFiles --progress-num=$(CMAKE_PROGRESS_7) "Building CXX object CMakeFiles/Alfred.dir/src/Alfred/rpcinfo.cpp.o"
	/opt/rh/devtoolset-7/root/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/Alfred.dir/src/Alfred/rpcinfo.cpp.o -c /opt/fredserver/src/Alfred/rpcinfo.cpp

CMakeFiles/Alfred.dir/src/Alfred/rpcinfo.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/Alfred.dir/src/Alfred/rpcinfo.cpp.i"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /opt/fredserver/src/Alfred/rpcinfo.cpp > CMakeFiles/Alfred.dir/src/Alfred/rpcinfo.cpp.i

CMakeFiles/Alfred.dir/src/Alfred/rpcinfo.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/Alfred.dir/src/Alfred/rpcinfo.cpp.s"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /opt/fredserver/src/Alfred/rpcinfo.cpp -o CMakeFiles/Alfred.dir/src/Alfred/rpcinfo.cpp.s

CMakeFiles/Alfred.dir/src/Alfred/service.cpp.o: CMakeFiles/Alfred.dir/flags.make
CMakeFiles/Alfred.dir/src/Alfred/service.cpp.o: src/Alfred/service.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/opt/fredserver/CMakeFiles --progress-num=$(CMAKE_PROGRESS_8) "Building CXX object CMakeFiles/Alfred.dir/src/Alfred/service.cpp.o"
	/opt/rh/devtoolset-7/root/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/Alfred.dir/src/Alfred/service.cpp.o -c /opt/fredserver/src/Alfred/service.cpp

CMakeFiles/Alfred.dir/src/Alfred/service.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/Alfred.dir/src/Alfred/service.cpp.i"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /opt/fredserver/src/Alfred/service.cpp > CMakeFiles/Alfred.dir/src/Alfred/service.cpp.i

CMakeFiles/Alfred.dir/src/Alfred/service.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/Alfred.dir/src/Alfred/service.cpp.s"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /opt/fredserver/src/Alfred/service.cpp -o CMakeFiles/Alfred.dir/src/Alfred/service.cpp.s

CMakeFiles/Alfred.dir/src/Alfred/dimutilities.cpp.o: CMakeFiles/Alfred.dir/flags.make
CMakeFiles/Alfred.dir/src/Alfred/dimutilities.cpp.o: src/Alfred/dimutilities.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/opt/fredserver/CMakeFiles --progress-num=$(CMAKE_PROGRESS_9) "Building CXX object CMakeFiles/Alfred.dir/src/Alfred/dimutilities.cpp.o"
	/opt/rh/devtoolset-7/root/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/Alfred.dir/src/Alfred/dimutilities.cpp.o -c /opt/fredserver/src/Alfred/dimutilities.cpp

CMakeFiles/Alfred.dir/src/Alfred/dimutilities.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/Alfred.dir/src/Alfred/dimutilities.cpp.i"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /opt/fredserver/src/Alfred/dimutilities.cpp > CMakeFiles/Alfred.dir/src/Alfred/dimutilities.cpp.i

CMakeFiles/Alfred.dir/src/Alfred/dimutilities.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/Alfred.dir/src/Alfred/dimutilities.cpp.s"
	/opt/rh/devtoolset-7/root/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /opt/fredserver/src/Alfred/dimutilities.cpp -o CMakeFiles/Alfred.dir/src/Alfred/dimutilities.cpp.s

# Object files for target Alfred
Alfred_OBJECTS = \
"CMakeFiles/Alfred.dir/src/Alfred/alfred.cpp.o" \
"CMakeFiles/Alfred.dir/src/Alfred/client.cpp.o" \
"CMakeFiles/Alfred.dir/src/Alfred/command.cpp.o" \
"CMakeFiles/Alfred.dir/src/Alfred/info.cpp.o" \
"CMakeFiles/Alfred.dir/src/Alfred/print.cpp.o" \
"CMakeFiles/Alfred.dir/src/Alfred/rpc.cpp.o" \
"CMakeFiles/Alfred.dir/src/Alfred/rpcinfo.cpp.o" \
"CMakeFiles/Alfred.dir/src/Alfred/service.cpp.o" \
"CMakeFiles/Alfred.dir/src/Alfred/dimutilities.cpp.o"

# External object files for target Alfred
Alfred_EXTERNAL_OBJECTS =

lib/libAlfred.so: CMakeFiles/Alfred.dir/src/Alfred/alfred.cpp.o
lib/libAlfred.so: CMakeFiles/Alfred.dir/src/Alfred/client.cpp.o
lib/libAlfred.so: CMakeFiles/Alfred.dir/src/Alfred/command.cpp.o
lib/libAlfred.so: CMakeFiles/Alfred.dir/src/Alfred/info.cpp.o
lib/libAlfred.so: CMakeFiles/Alfred.dir/src/Alfred/print.cpp.o
lib/libAlfred.so: CMakeFiles/Alfred.dir/src/Alfred/rpc.cpp.o
lib/libAlfred.so: CMakeFiles/Alfred.dir/src/Alfred/rpcinfo.cpp.o
lib/libAlfred.so: CMakeFiles/Alfred.dir/src/Alfred/service.cpp.o
lib/libAlfred.so: CMakeFiles/Alfred.dir/src/Alfred/dimutilities.cpp.o
lib/libAlfred.so: CMakeFiles/Alfred.dir/build.make
lib/libAlfred.so: CMakeFiles/Alfred.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/opt/fredserver/CMakeFiles --progress-num=$(CMAKE_PROGRESS_10) "Linking CXX shared library lib/libAlfred.so"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/Alfred.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/Alfred.dir/build: lib/libAlfred.so

.PHONY : CMakeFiles/Alfred.dir/build

CMakeFiles/Alfred.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/Alfred.dir/cmake_clean.cmake
.PHONY : CMakeFiles/Alfred.dir/clean

CMakeFiles/Alfred.dir/depend:
	cd /opt/fredserver && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /opt/fredserver /opt/fredserver /opt/fredserver /opt/fredserver /opt/fredserver/CMakeFiles/Alfred.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/Alfred.dir/depend

