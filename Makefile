##
# optimiser of matches for a tournament

CXX=g++
CXXFLAGS= -g -O0

# Add .d to Make's recognized suffixes.
SUFFIXES += .d

#We don't need to clean up when we're making these targets
NODEPS:=clean deps
#Find all the C++ files in the src/ directory
SRCS := $(shell ls -1 *.cpp     )
OBJS := $(SRCS:.cpp=.o)
#These are the dependency files, which make will clean up after it creates them
DEPS := $(OBJS:.o=.d)

LIBS := -llibargp

#Don't create dependencies when we're cleaning, for instance
ifeq (0, $(words $(findstring $(MAKECMDGOALS), $(NODEPS))))
    #Chances are, these files don't exist.  GMake will create them and
    #clean up automatically afterwards
    -include $(DEPS)
endif

#This is the rule for creating the dependency files
%.d: %.cpp
	$(CXX) $(CXXFLAGS) -MM -MT '$(patsubst %.cpp,%.o,$<)' $< -MF $@

#This rule does the compilation
%.o: %.cpp %.d %.h
	$(CXX) $(CXXFLAGS) -o $@ -c $<


all: optim.exe

deps : $(DEPS)
	@pwd
	@echo "dependencies... on $(SRCS)"

optim.exe : $(OBJS)
	@echo "building $(OBJS)"
	$(CXX) $(CXX_FLAGS) $^ -o $@ $(LIBS)

clean:
	@echo "clearing..."
	-rm *.o *.d *.exe
