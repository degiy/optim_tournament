#include "swap_table.h"
#include "board.h"
#include "match_cell.h"
#include "teams_on_slot.h"

// load the swap table from a previous board
// here everything down to popcount and bitmaps as we need speed
SwapTable::SwapTable(Board &b,char* a_break,char* spare_slots) : break_n{0}, break_x{0}, break_y{0}
{
    // manage lunch break if any and a splice to add void slots
    short splice_x=0;
    short splice_n=0;
    short sz=b.slots.size();
    if (a_break) ParseBreak(a_break);
    if (spare_slots)
    {
        ParseSplice(spare_slots,splice_x,splice_n);
        sz+=splice_n;
    }
    nb_matches=b.cells.size();
    table.resize(sz);
    slots.resize(sz);
    int i,j; // need two indexes as we could add slots in the process
    for (i=0,j=0;j<sz;i++,j++)
    {
        table[j].resize(b.slots[i].capacity);
        slots[j]=b.slots[i].teams;
        MatchCell* pt=&(b.cells[b.slots[i].head.next]);
        short c;
        for (c=0;c<b.slots[i].nb;c++)
        {
            TeamsOnSlot tos(pt->a,pt->b);
            table[j][c]=tos;
            pt=&(b.cells[pt->next]);
        }
        for (;c<b.slots[i].capacity;c++)
        {
            table[j][c].reset();
        }
        if ((splice_n)&&(j==splice_x))
        {
            //time to splice
            while (splice_n-->0)
            {
                j++;
                table[j].resize(b.slots[i].capacity);
                slots[j].reset();
                for (c=0;c<b.slots[i].capacity;c++)
                {
                    table[j][c].reset();
                }
            }
        }
    }
}

void SwapTable::ParseBreak(char *syntax)
{
   sscanf(syntax, "%hu:%hu:%hu", &break_x, &break_y, &break_n);
   if (debug) printf("need break for %hu slots between %hu and %hu\n",break_n,break_x,break_y);
}

void SwapTable::ParseSplice(char *syntax, short &x, short &n)
{
   sscanf(syntax, "%hu:%hu", &x, &n);
   if (debug) printf("splice %hu slots after slot %hu\n",n,x);
}

SwapTable::SwapTable(SwapTable &s)
{
    nb_matches=s.nb_matches;
    table=s.table;
    slots=s.slots;
}


void SwapTable::Debug()
{
    for (int y=0;y<slots.size();y++)
    {
        printf("    - slot %2d : ",y);
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
    int score;
    int initial_score,best_score;
    initial_score=best_score=ScoreIt();
    if (ttl==0) return initial_score;
    SwapTable best_table(*this);
    SwapTable backup_table(*this);

    for(int y=0;y<slots.size()-1;y++)
    {
        for (int x=0;x<table[y].size();x++)
        {
            // match of concern at table[y][x]
            // is it not void ?
            if (table[y][x].any())
            {
                for(int yy=y+1;yy<slots.size();yy++)
                {
                    auto m=slots[yy]&table[y][x];
                    if (m.none())
                    {
                        // possibility on this slot because neither team of selected match are playing
                        // find a possible swap for both sides
                        for (int xx=0;xx<table[yy].size();xx++)
                        {
                            if ((slots[y]&table[yy][xx]).none())
                            {
                                // ok we have reciprocity to make the swap
                                DoSwap(x,y,xx,yy);
                                score=BestSwap(ttl-1);
                                if (score>best_score)
                                {
                                    if (debug>2) printf("%*c - increase score from %d to %d moving %d,%d and %d,%d (simple)\n",16-ttl,32,best_score,score,x,y,xx,yy);
                                    best_score=score;
                                    best_table=*this;
                                }
                                else if (debug>3) printf("%*c  - decrease score from %d to %d moving %d,%d and %d,%d (simple)\n",16-ttl,32,best_score,score,x,y,xx,yy);
                                // return to old table
                                *this=backup_table;
                            }
                        }
                    }
                    else if (m.count()==1)
                    {
                        // the more complex move : one of the team (a) is playing on this time slot but not both
                        // (maybe both), we need to check is we can switch the match (a,c)
                        // (but this works only if the other team of the match (c) is not playing on the original time slot from (a,b))
                        for (int xx=0;xx<table[yy].size();xx++)
                        {
                            auto m=table[y][x]&table[yy][xx];
                            if (m.any())
                            {
                                // we have a match with one of our two teams that is playing both matches
                                m^=table[yy][xx]; // get the other team of the match on slot 2
                                // check if this particular team happen to play on original slot 1
                                m&=slots[y];
                                if (m.none())
                                {
                                    // nope : perfect we can make the move
                                    DoSwap(x,y,xx,yy);
                                    score=BestSwap(ttl-1);
                                    if (score>best_score)
                                    {
                                        if (debug>2) printf("%*c - increase score from %d to %d moving %d,%d and %d,%d (complex)\n",16-ttl,32,best_score,score,x,y,xx,yy);
                                        best_score=score;
                                        best_table=*this;
                                    }
                                    else if (debug>3) printf("%*c  - decrease score from %d to %d moving %d,%d and %d,%d (complex)\n",16-ttl,32,best_score,score,x,y,xx,yy);
                                    // return to old table
                                    *this=backup_table;
                                }
                                // no need to stay on the loop, as we already find the (a,c) match
                                xx=999;
                            }
                        }
                    }
                }
            }
            else
            {
                // we have a void cell, that doesn't mean we can't swap it.
                // in fact we can swap it more easily
                for(int yy=y+1;yy<slots.size();yy++)
                {
                    for (int xx=0;xx<table[yy].size();xx++)
                    {
                        // skip to swap both empty cells (no added value to that)
                        if ( (table[yy][xx].any()) && ((slots[y]&table[yy][xx]).none()) )
                        {
                            // ok we can swap because none of the two team was playing in original slot
                            DoSwap(x,y,xx,yy);
                            score=BestSwap(ttl-1);
                            if (score>best_score)
                            {
                                if (debug>2) printf("%*c - increase score from %d to %d moving %d,%d and %d,%d (void)\n",16-ttl,32,best_score,score,x,y,xx,yy);
                                best_score=score;
                                best_table=*this;
                            }
                            else if (debug>3) printf("%*c  - decrease score from %d to %d moving %d,%d and %d,%d (void)\n",16-ttl,32,best_score,score,x,y,xx,yy);
                            // return to old table
                            *this=backup_table;
                        }
                    }
                }
            }
        }
    }
    if (best_score>initial_score)
    {
        *this=best_table;
        if(debug>1) printf("%*c - best score %d\n",16-ttl,32,best_score);
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
