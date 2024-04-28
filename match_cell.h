#ifndef MATCH_CELL_H_
#define MATCH_CELL_H_

#include "common.h"

class MatchCell
{
public:
    MatchCell();

    short next;
    TeamId a;
    TeamId b;
};

#endif // MATCH_CELL_H_
