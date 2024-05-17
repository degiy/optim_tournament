#ifndef COMMON_H_
#define COMMON_H_

// on set for debug, on for max load

#define MAX_TEAMS 32
//#define MAX_TEAMS 64
#define MAX_SLOTS 32
//#define MAX_SLOTS 64
#define MAX_COURTS 8
//#define MAX_COURTS 8

#define MAX_MATCHES (MAX_COURTS*MAX_SLOTS)

extern short verbose,debug;

typedef unsigned char TeamId;

#endif // COMMON_H_
