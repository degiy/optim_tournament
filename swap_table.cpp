#include "swap_table.h"
#include "board.h"
#include "match_cell.h"
#include "teams_on_slot.h"

// load the swap table from a previous board
// here everything down to popcount and bitmaps as we need speed
SwapTable::SwapTable(Board &b)
{
    nb_matches=b.cells.size();
    table.resize(b.slots.size());
    slots.resize(b.slots.size());
    for (short i=0;i<b.slots.size();i++)
    {
        table[i].resize(b.slots[i].capacity);
        slots[i]=b.slots[i].teams;
        MatchCell* pt=&(b.cells[b.slots[i].head.next]);
        short c;
        for (c=0;c<b.slots[i].nb;c++)
        {
            TeamsOnSlot tos(pt->a,pt->b);
            table[i][c]=tos;
            pt=&(b.cells[pt->next]);
        }
        for (;c<b.slots[i].capacity;c++)
        {
            table[i][c].reset();
        }
    }
}


void SwapTable::Debug()
{
    for (int y=0;y<slots.size();y++)
    {
        printf("- slot %2d : ",y);
        slots[y].Debug();
        printf(" => ");
        for (int x=0;x<table[y].size();x++)
        {
            table[y][x].Debug();
            printf(" ");
        }
        printf("\n");
    }

}

// same algo of scoring as for the board but aimed at swap table
int SwapTable::ScoreIt()
{
    int score=nb_matches; // initial score
    std::bitset<MAX_TEAMS> last_tos=slots[0];
    // substract counter for each 2 consecutive match of each team
    for(int i=1;i<slots.size();i++)
    {
        std::bitset<MAX_TEAMS> cur_tos=slots[i];
        score-=(last_tos&cur_tos).count();
        last_tos=cur_tos;
    }
    // substract one more is 3 consecutive matches
    std::bitset<MAX_TEAMS> lastt_tos=slots[0];
    last_tos=slots[1];
    for(int i=2;i<slots.size();i++)
    {
        std::bitset<MAX_TEAMS> cur_tos=slots[i];
        std::bitset<MAX_TEAMS> tos=lastt_tos&last_tos&cur_tos;
        score-=tos.count();
        lastt_tos=last_tos;
        last_tos=cur_tos;
    }
    return score;
}

// main algo of basic swapping matches (only on slots with neither team playing)
// will swap all possible matches, find the best and return
int SwapTable::BestSwap(int ttl)
{
    int bx,by,bxx,byy;
    int best_score=ScoreIt();
    for(int y=0;y<slots.size()-1;y++)
    {
        for (int x=0;x<table[y].size();x++)
        {
            // match of concern at table[y][x]
            // is it not void ?
            if (table[y][x].count()>0)
            {
                for(int yy=y+1;yy<slots.size();yy++)
                {
                    if ((slots[yy]&table[y][x]).count()==0)
                    {
                        // possibility on this slot because neither team of selected match are playing
                        // find a possible swap for both sides
                        for (int xx=0;xx<table[yy].size();xx++)
                        {
                            if ((slots[y]&table[yy][xx]).count()==0)
                            {
                                // ok we have reciprocity to make the swap
                                DoSwap(x,y,xx,yy);
                                int score=ScoreIt();
                                if (score>best_score)
                                {
                                    if (debug>2) printf(" - increase score from %d to %d moving %d,%d and %d,%d\n",best_score,score,x,y,xx,yy);
                                    best_score=score;
                                    bx=x; by=y; bxx=xx; byy=yy;
                                }
                                else if (debug>3) printf("  - decrease score from %d to %d moving %d,%d and %d,%d\n",best_score,score,x,y,xx,yy);
                                // unswap
                                DoSwap(x,y,xx,yy);
                            }
                        }
                    }
                }
            }
        }
    }
    if (best_score)
    {
        DoSwap(bx,by,bxx,byy);
        if(debug>1) printf(" - best score %d moving %d,%d and %d,%d\n",best_score,bx,by,bxx,byy);
        if(debug>2) Debug();
    }
    return best_score;
}

void SwapTable::DoSwap(int x, int y, int xx, int yy)
{
    // clean matches from stats
    slots[y]&=~table[y][x];
    slots[yy]&=~table[yy][xx];
    // swap of matches
    auto org=table[y][x];
    table[y][x]=table[yy][xx];
    table[yy][xx]=org;
   // update of stats for slot
    slots[y]|=table[y][x];
    slots[yy]|=table[yy][xx];
}
