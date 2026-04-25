// Golf Scorecard System
integer CHANNEL_SCORE = -8472640;
list gScores = [];
list gPlayerNames = [];
integer gTotalHoles = 18;

SaveScore(key player, integer hole, integer strokes)
{
    string playerName = llKey2Name(player);
    integer playerIndex = llListFindList(gPlayerNames, [playerName]);
    
    if (playerIndex == -1)
    {
        gPlayerNames += [playerName];
        list newScores = [];
        integer i;
        for (i = 0; i < gTotalHoles; i++)
        {
            newScores += [0];
        }
        gScores += newScores;
        playerIndex = llGetListLength(gPlayerNames) - 1;
    }
    
    integer scoreIndex = (playerIndex * gTotalHoles) + (hole - 1);
    gScores = llListReplaceList(gScores, [strokes], scoreIndex, scoreIndex);
}

string GetScorecard(string playerName)
{
    integer playerIndex = llListFindList(gPlayerNames, [playerName]);
    if (playerIndex == -1)
    {
        return "No scores recorded for " + playerName;
    }
    
    string card = "SCORECARD - " + playerName + "\n";
    card += "Hole | Score\n";
    card += "-------------\n";
    
    integer total = 0;
    integer i;
    for (i = 0; i < gTotalHoles; i++)
    {
        integer scoreIndex = (playerIndex * gTotalHoles) + i;
        integer score = llList2Integer(gScores, scoreIndex);
        if (score > 0)
        {
            card += (string)(i+1) + "    | " + (string)score + "\n";
            total += score;
        }
    }
    
    card += "-------------\n";
    card += "Total: " + (string)total;
    
    return card;
}

default
{
    state_entry()
    {
        llListen(CHANNEL_SCORE, "", "", "");
        llSetText("Golf Scorecard\nTouch for scores", <0,1,0>, 1.0);
    }
    
    touch_start(integer num)
    {
        key toucher = llDetectedKey(0);
        string name = llKey2Name(toucher);
        llRegionSayTo(toucher, 0, GetScorecard(name));
    }
    
    listen(integer channel, string name, key id, string message)
    {
        list params = llParseString2List(message, ["|"], []);
        string cmd = llList2String(params, 0);
        
        if (cmd == "SCORE")
        {
            integer hole = llList2Integer(params, 1);
            integer strokes = llList2Integer(params, 2);
            key player = llGetOwnerKey(id);
            
            SaveScore(player, hole, strokes);
            
            llRegionSayTo(player, 0, "Score saved: Hole " + (string)hole + " = " + (string)strokes + " strokes");
        }
        else if (cmd == "SETHOLES")
        {
            gTotalHoles = llList2Integer(params, 1);
            llOwnerSay("Total holes set to: " + (string)gTotalHoles);
        }
    }
}
