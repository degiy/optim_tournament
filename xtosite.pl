#!/bin/perl
#
# generate site thanks to exchange file (xfile)

use Data::Dumper;
use POSIX qw(setlocale LC_CTYPE);
setlocale(LC_CTYPE, 'C');  # Force la locale à "C" (locale ASCII)

# format of exchange file : slot_time; court ; category ; pool ; phase (if any); team 1; team 2; score t1; score t2;
use POSIX qw(strftime setlocale LC_TIME);
$ENV{'TZ'} = 'Europe/Paris';
$gentime = strftime "%H:%M:%S", localtime;

while(<>)
{
    chomp;
    next unless /^[0-9:]+;/;
    @t=split /;/,$_;
    ($slot,$court,$cat,$pool,$phase,$equ1,$equ2,$sc1,$sc2)=@t;
    if ($pool eq 'O') { $pool=chr(1)."Or"; }
    elsif ($pool eq 'P') { $pool=chr(2)."Argent"; }
    elsif ($pool eq 'Q') { $pool=chr(3)."Bronze"; }
    elsif ($pool eq 'R') { $pool=chr(4)."Fer"; }
    push @tall,[$slot,$court,$cat,$pool,$phase,$equ1,$equ2,$sc1,$sc2];
    $htslot{$slot}=1;
    $htcourt{$court}=1;
    $htcat{$cat}=() unless exists $htcat{$cat};
    $htcat{$cat}{$pool}=() unless exists $htcat{$cat}{$pool};
    $phase='-' if $phase eq '';
    $htcat{$cat}{$pool}{$phase}=() unless exists $htcat{$cat}{$pool}{$phase};
    $htequp{$cat}{$pool}{$equ1}=1;
    $htequp{$cat}{$pool}{$equ2}=1;
    my ($club)=$equ1=~/^([^0-9]*)[0-9]??$/;
    #print "club -$club- -$equ1-\n";
    $htclub{$club}{"$cat;$pool;$equ1"}=1;
    ($club)=$equ2=~/^([^0-9]*)[0-9]??$/;
    #print "club -$club- -$equ2-\n";
    $htclub{$club}{"$cat;$pool;$equ2"}=1;
}

# ================ MAIN PAGE =============
open F,"+>./index.html";
&header(0,"Base du site");
print F "Terrains :<ul>\n";
@courts=sort keys %htcourt;
for my $court (@courts)
{
    print F "<li><a href=\"courts/$court/index.html\">$court</a></li>\n";
}
print F "</ul>\n";
print F "Categories :<ul>\n";
@cats=sort keys %htcat;
for my $cat (@cats)
{
    print F "<li><a href=\"cats/$cat/index.html\">$cat</a></li>\n";
}
print F "</ul>\n";
print F "Equipes par club :<ul>\n";
@clubs=sort keys %htclub;
for my $club (@clubs)
{
    my $club2=ucfirst($club);
    print F "<li> $club2 :<ul>\n";
    my $oc='';
    for my $cpe (sort(keys %{$htclub{$club}}))
    {
        my ($c,$p,$e)=split /;/,$cpe;
        unless ($c eq $oc)
        {
            print F "</li>" unless $oc eq '';
            print F "\n<li><a href=\"cats/$c/index.html\">$c</a> : ";
        }
        else
        {
            print F ", ";
        }
        my $e2=&rewrite_team($e);
        print F "<a href=\"cats/$c/$p/$e.html\">$e2</a> (<a href=\"cats/$c/$p/index.html\">poule $p</a>)";
        $oc=$c;
    }
    print F "</li></ul></li>\n";
}
print F "</ul>\n";
print F "<p><a href=\"https://matin.tournoi-jsc-basket.fun\"> lien tournoi matin</a> et <a href=\"qr-code-matin-petit.png\">QR code</a>\n";
print F "<p><a href=\"https://aprem.tournoi-jsc-basket.fun\"> lien tournoi aprem</a> et <a href=\"qr-code-aprem-petit.png\">QR code</a>\n";
print F "<p><a href=\"reglement.html\">Reglement et phases finales</a>\n";
&footer;
&cleanF;

# ================ COURTS ================
@courts=sort keys %htcourt;
print "courts : ",join(' ',@courts,"\n");

mkdir "./courts";
for my $court (@courts)
{
    mkdir "./courts/$court";
    open F,"+>./courts/$court/index.html";
    &header(2,"Liste des terrains");
    print F "Matches sur Terrain <b>$court</b><p>\n";
    my $tfil=&filter(1,$court);
    &table('court',$tfil,
           'Heure','Equipe 1',              'Equipe 2',              'Cat.','Poule','Phase',
           0,      5,                       6,                       2,     3,      4,
           'slot', 'team#../../cats#2#3',   'team#../../cats#2#3',   'z',   'z',    'z');
    &footer;
    &cleanF;
}

# all slots
@slots=sort keys %htslot;
print "slots : ",join(' ',@slots,"\n");

# =============== CATEGORIES ===========
@cats=sort keys %htcat;
mkdir "./cats";
for my $cat (@cats)
{
    mkdir "./cats/$cat";
    open F,"+>./cats/$cat/index.html";
    &header(2,"$cat");
    print F "Categorie <b>$cat</b><p><ul>\n";
    @pools=sort keys %{$htcat{$cat}};
    foreach $pool (@pools)
    {
        my $p2=&cleanP($pool);
        mkdir "./cats/$cat/$p2";
        print F "<li><a href=\"$pool/index.html\">Poule $pool</a><ul>\n";
        @teams=sort keys %{$htequp{$cat}{$pool}};
        foreach $team (@teams)
        {
            $prettyteam=&rewrite_team($team);
            print F "<li><a href=\"$pool/$team.html\">$prettyteam</a></li> ";
            push @t_cat_pool_team,[$cat,$pool,$team];
        }
        print F " </ul> </li>\n";
        push @t_cat_pool,[ $cat,$pool];
    }
    print F "</ul>\n";
    &footer;
    &cleanF;
}

# =============== POOLS ===============
for my $ecp (@t_cat_pool)
{
    my ($cat,$pool)=@$ecp;
    my $p2=&cleanP($pool);
    open F,"+>./cats/$cat/$p2/index.html";
    &header(3,"$cat/$pool");
    print F "Poule <b>${cat}${pool}</b><p><p>\n";
    print F "Matchs (clickables): <p>\n";
    my $tfil=&filter2(2,3,$cat,$pool);
    my $tscore=&scoring($tfil);
    &table('score',$tfil,
           'Heure','Equipe 1','Equipe 2','Phase','Terrain',
           0,      5,         6,         4,      1,
           'slot', 'team',    'team',    'z',    'z');
    print F "<p>Classement : <p>\n";
    my $tss=&sort_scores($tscore);
    &table('sumup',$tss,
           'Rang','Equipe','Points','M. joues','M. gagnes','M. perdus','M. nuls','Pts. marques','Pts. encaisses','Diff. pts.',
           0,     1,       2,       3,          4,          5,         6,        7,             8,               9,
           'z',   'team/', 'z',     'z',        'z',        'z',       'z',     'z',            'z',             'z');

    &footer;
    &cleanF;
}

# format of exchange file : slot_time; court ; category ; pool ; phase (if any); team 1; team 2; score t1; score t2;
# =============== TEAMS ===============
for my $ecpt (@t_cat_pool_team)
{
    my ($cat,$pool,$team)=@$ecpt;
    my $p2=&cleanP($pool);
    open F,"+>./cats/$cat/$p2/$team.html";
    &header(3,"$cat/$pool/$team");
    print F "Equipe <b>",&rewrite_team($team),"</b> (<a href=\"index.html\">${cat}${pool}</a>)<p>\n";
    print F "Matchs : <p>\n";
    my $tfil=&filter2(2,3,56,$cat,$pool,$team);
    &keepone($tfil,5,6,$team);
    &table('team',$tfil,
           'Heure','Terrain','Contre','Phase',
           0,1,5,4,
           'slot','z','team','z');

    &footer;
    &cleanF;
}

# ============== Utilities =========

sub sort_scores
{
    my ($psrc)=@_;
    my @dst=();
    my ($max,$i,$cost,$imax,$line);
    my $rank=1;

    while($#$psrc>=0)
    {
        $max=0-(1<<20);
        for ($i=0;$i<=$#$psrc;$i++)
        {
            $cost= ($psrc->[$i]->[2])<<20;
            $cost+=(($psrc->[$i]->[8])+(1<<9))<<10;
            $cost+=($psrc->[$i]->[6]);
            if ($cost>$max)
            {
                $max=$cost;
                $imax=$i;
            }
        }
        my $line=splice @$psrc,$imax,1;
        $line->[0]=$rank++;
        push @dst,$line;
    }
    return \@dst;
}

sub scoring
{
    my ($tfil)=@_;
    # first find all the teams from the table
    my %teams=();
    my ($pt,$t,%hpts,%hwin,%hlost,%hdraw,%hplus,%hminus,%hdiff,@tn,%hplay);
    #print "scoring :\n";
    for $pt (@$tfil)
    {
        $teams{$pt->[5]}=1;
        $teams{$pt->[6]}=1;
    }
    # init hash tables for individual scores
    @tn=sort(keys(%teams));
    for $t (@tn)
    {
        #print "  ",$t,"\n";
        $hpts{$t}=0;
        $hwin{$t}=0;
        $hlost{$t}=0;
        $hdraw{$t}=0;
        $hplus{$t}=0;
        $hminus{$t}=0;
        $hdiff{$t}=0;
        $hplay{$t}=0;
    }
    # make the scoring
    for $pt (@$tfil)
    {
        my ($r,$r,$r,$r,$r,$t1,$t2,$sc1,$sc2)=@$pt;
        next unless $s1 or $sc2;
        # we have a score
        $hplay{$t1}++;
        $hplay{$t2}++;
        $hdiff{$t1}+=$sc1-$sc2;
        $hdiff{$t2}+=$sc2-$sc1;
        $hplus{$t1}+=$sc1;
        $hminus{$t1}-=$sc2;
        $hplus{$t2}+=$sc2;
        $hminus{$t2}-=$sc1;
        if ($sc1>$sc2)
        {
            # team 1 victorious
            $hwin{$t1}++;
            $hlost{$t2}++;
            $hpts{$t1}+=4;
            $hpts{$t2}+=1;
        }
        elsif ($sc1<$sc2)
        {
            # team 2 victorious
            $hwin{$t2}++;
            $hlost{$t1}++;
            $hpts{$t2}+=4;
            $hpts{$t1}+=1;
        }
        else
        {
            # draw
            $hdraw{$t2}++;
            $hdraw{$t1}++;
            $hpts{$t2}+=2;
            $hpts{$t1}+=2;
        }
        $pt->[5]=&rewrite_team($t1)." ($sc1)";
        $pt->[6]=&rewrite_team($t2)." ($sc2)";
    }
    # now the ranking
    @tsc=();
    for $t (@tn)
    {
        push @tsc,[ 1,$t,$hpts{$t},$hplay{$t},$hwin{$t},$hlost{$t},$hdraw{$t},$hplus{$t},$hminus{$t},$hdiff{$t} ];
    }
    #print Dumper(\@tsc);
    return \@tsc;
}

sub filter
{
    my ($col,$val)=@_;
    #print "col=$col, val=$val\n";
    my @tfil=();
    my ($pt);
    for $pt (@tall)
    {
        #print "pt ",$pt->[$col],"\n";
        if ($pt->[$col] eq $val)
        {
            push @tfil,[@{$pt}];
        }
    }
    return \@tfil;
}

sub filter2
{
    my (@ar)=@_;
    my ($nb,$pt,$keep,$kind,$val,$i,$id,$keep2);
    $nb=($#ar+1)/2;
    my @tfil=();
    for $pt (@tall)
    {
        $keep=1;
        # logical AND
        for ($i=0;$i<$nb;$i++)
        {
            $kind=$ar[$i];
            $val=$ar[$i+$nb];
            if ($kind>=10)
            {
                # logical OR (except on column 0)
                $keep2=0;
                while ($kind>0)
                {
                    $id=$kind%10;
                    if ($pt->[$id] eq $val) { $keep2=1; }
                    $kind/=10;
                }
                $keep=0 unless $keep2==1;
            }
            else
            {
                # single value
                unless ($pt->[$kind] eq $val) { $keep=0; }
            }
        }
        if ($keep==1)
        {
            push @tfil,[@{$pt}];
        }
    }
    return \@tfil;
}

sub keepone
{
    my ($tfil,$col1,$col2,$ref)=@_;
    for $pt (@$tfil)
    {
        if ($pt->[$col1] eq $ref) { $pt->[$col1] = $pt->[$col2]; }
        elsif ($pt->[$col2] eq $ref) { $pt->[$col2] = $pt->[$col1]; }
    }
}

sub table
{
    my (@ar)=@_;
    my ($pt,$nb,$i,$cell,$css,$cl);
    my $kind=shift @ar;
    my $tfil=shift @ar;
    $nb=($#ar+1)/3;
    print F "<table class=\"${kind}\"><thead><tr> ";
    for($i=0;$i<$nb;$i++) { print F "<th>",$ar[$i],"</th> "; }
    print F "</tr></thead>\n<tbody>\n";
    for $pt (@$tfil)
    {
        print F "<tr class=\"alt\"> ";
        for ($i=0;$i<$nb;$i++)
        {
            $cell=$pt->[$ar[$nb+$i]];
            $css=$ar[$nb+$nb+$i];
            if ($css=~/^team/)
            {
                $cell=&rewrite_team($cell);
                if ($css=~/^team\/(.*)$/)
                {
                    my $path=$1;
                    my $team=$pt->[$ar[$nb+$i]];
                    $cell="<a href=\"${path}${team}.html\">$cell</a>";
                }
                elsif ($css=~/^team#/)
                {
                    my @t=split /#/,$css;
                    shift @t;
                    my $path='';
                    for $p (@t)
                    {
                        if ($p=~/^[0-9]+$/)
                        {
                            $path.=$pt->[$p];
                            $path.='/';
                        }
                        else
                        {
                            $path.="$p/";
                        }
                    }
                    my $team=$pt->[$ar[$nb+$i]];
                    $cell="<a href=\"${path}${team}.html\">$cell</a>";
                }
                $css='team';
            }
            $cl="class=\"$css\"";
            $cl='' if $css eq 'z';
            print F "<td $cl>$cell</td> ";
        }
        print F "</tr>\n";
    }
    print F "</tbody></table>\n";
}

sub rewrite_team
{
    my ($t)=@_;
    my $t2=ucfirst($t);
    if ($t2 =~/[0-9]$/) { $t2=~s/^(.*)([0-9])$/\1 \2/; }
    return $t2;
}

sub header
{
    my ($depth,$title)=@_;
    print F "<!DOCTYPE html>\n";
    my $path = "../" x $depth;
    print F "<html>\n<head><meta charset=\"UTF-8\"><title>$title</title><link rel=\"stylesheet\" href=\"${path}style.css\">\n";
    print F "<script src=\"${path}table_rows.js\"></script>";
    print F "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"></head>\n<body>\n";
    print F "<div class=\"button-bar\">\n";
    print F "<button onclick=\"javascript:history.back()\">Retour</button>\n";
    print F "<button onclick=\"window.location.href=\'${path}index.html\'\">Menu</button>\n";
    print F "<button id=\"refreshButton\" onclick=\"checkHeaderAndRefresh()\">mettre a jour</button>\n";
    print F "<button onclick=\"incSize()\">+ gros</button>\n";
    print F "<button onclick=\"decSize()\">+ petit</button>\n";
    print F "<button onclick=\"javascript:history.forward()\">Avance</button></div>\n"
}

sub footer
{
    print F "<p><i>genere a $gentime</i>\n";
    print F "</body></html>";
}


sub cleanF
{
    seek(F, 0, 0);
    my @lines = <F>;
    seek(F, 0, 0);
    truncate(F, 0);

    foreach my $line (@lines) {
        $line=~tr/[\x01-\x07]//d;  # suppress orders hints
        print F $line;
    }

    close(F);
}

sub cleanP
{
    my ($ret)=@_;
    $ret=~tr/[\x01-\x07]//d;
    return $ret;
}
