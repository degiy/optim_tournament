#include "teams_on_slot.h"
#include "common.h"

TeamsOnSlot::TeamsOnSlot()
{
}

TeamsOnSlot::TeamsOnSlot(TeamId a)
{
    set(a);
}

TeamsOnSlot::TeamsOnSlot(TeamId a, TeamId b)
{
    set(a);
    set(b);
}

bool TeamsOnSlot::TstMatch(TeamId a, TeamId b)
{
    bool ret=true;
    if (test(a)) ret=false;
    else if (test(b)) ret=false;
    return ret;
}

void TeamsOnSlot::AddMatch(TeamId a, TeamId b)
{
    set(a);
    set(b);
}

void TeamsOnSlot::Debug()
{
    for(int i=0;i<cap;i++)
    {
        int digit=i%10;
        if (test(i)) printf("%d",digit); else printf ("-");
    }
}

int TeamsOnSlot::cap=MAX_TEAMS;

void TeamsOnSlot::CapToNbTeams(int nb)
{
    cap=nb;
}
