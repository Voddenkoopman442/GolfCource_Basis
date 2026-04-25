// Lokales Scoreboard fuer ein einzelnes Loch
// Zeigt Zwischenstand am aktuellen Loch
// OpenSim 0.9.2 kompatibel

integer CHANNEL_BALL = -8472639;
integer CHANNEL_SCORE = -8472640;

// *** KONFIGURATION ***
integer HOLE_NUMBER = 1;     // Aendern fuer jedes Loch (1, 2, 3, etc.)
integer PAR = 4;             // Par fuer dieses Loch

// Speicher fuer aktuelle Spieler am Loch
list gPlayers = [];          // Spieler-Namen
list gStrokes = [];          // Schlagzahl am aktuellen Loch
list gTotalScores = [];      // Gesamtscore bis zu diesem Loch

UpdateDisplay()
{
    string display = "HOLE " + (string)HOLE_NUMBER + " (Par " + (string)PAR + ")\n";
    display += "==================\n";
    
    if (llGetListLength(gPlayers) == 0)
    {
        display += "No players yet\n";
        display += "\nTouch for leaderboard";
    }
    else
    {
        integer i;
        for (i = 0; i < llGetListLength(gPlayers); i++)
        {
            string name = llList2String(gPlayers, i);
            integer strokes = llList2Integer(gStrokes, i);
            integer total = llList2Integer(gTotalScores, i);
            
            // Zeige nur ersten Vornamen fuer Platzersparnis
            list nameParts = llParseString2List(name, [" "], []);
            string shortName = llList2String(nameParts, 0);
            
            if (strokes > 0)
            {
                // Spieler hat bereits geschlagen
                display += shortName + ": " + (string)strokes;
                
                // Zeige +/- zum Par
                integer toPar = strokes - PAR;
                if (toPar > 0)
                {
                    display += " (+" + (string)toPar + ")";
                }
                else if (toPar < 0)
                {
                    display += " (" + (string)toPar + ")";
                }
                else
                {
                    display += " (PAR)";
                }
                
                display += "\n";
            }
        }
        
        display += "\nTouch for full scores";
    }
    
    llSetText(display, <1.0, 1.0, 0.0>, 1.0);
}

integer FindPlayer(string name)
{
    return llListFindList(gPlayers, [name]);
}

AddOrUpdatePlayer(string name, integer strokes, integer total)
{
    integer index = FindPlayer(name);
    
    if (index == -1)
    {
        // Neuer Spieler
        gPlayers += [name];
        gStrokes += [strokes];
        gTotalScores += [total];
    }
    else
    {
        // Update existierenden Spieler
        gStrokes = llListReplaceList(gStrokes, [strokes], index, index);
        gTotalScores = llListReplaceList(gTotalScores, [total], index, index);
    }
    
    UpdateDisplay();
}

ClearHole()
{
    // Loesche alle Spieler wenn neuer Durchgang startet
    gPlayers = [];
    gStrokes = [];
    gTotalScores = [];
    UpdateDisplay();
}

default
{
    state_entry()
    {
        llListen(CHANNEL_BALL, "", "", "");
        llListen(CHANNEL_SCORE, "", "", "");
        
        UpdateDisplay();
        
        // Optional: Faerbe das Scoreboard
        llSetColor(<0.2, 0.3, 0.2>, ALL_SIDES);
    }
    
    on_rez(integer start_param)
    {
        llResetScript();
    }
    
    touch_start(integer num)
    {
        key toucher = llDetectedKey(0);
        string name = llKey2Name(toucher);
        
        // Zeige detaillierte Scores im Chat
        if (llGetListLength(gPlayers) == 0)
        {
            llRegionSayTo(toucher, 0, "No scores yet for Hole " + (string)HOLE_NUMBER);
            return;
        }
        
        string msg = "=== HOLE " + (string)HOLE_NUMBER + " SCORES ===\n";
        integer i;
        for (i = 0; i < llGetListLength(gPlayers); i++)
        {
            string playerName = llList2String(gPlayers, i);
            integer strokes = llList2Integer(gStrokes, i);
            integer total = llList2Integer(gTotalScores, i);
            
            msg += playerName + ": ";
            
            if (strokes > 0)
            {
                msg += (string)strokes + " strokes";
                
                integer toPar = strokes - PAR;
                if (toPar > 0)
                    msg += " (+" + (string)toPar + ")";
                else if (toPar < 0)
                    msg += " (" + (string)toPar + ")";
                else
                    msg += " (PAR)";
                    
                msg += " | Total: " + (string)total;
            }
            else
            {
                msg += "Playing...";
            }
            
            msg += "\n";
        }
        
        llRegionSayTo(toucher, 0, msg);
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (channel == CHANNEL_BALL)
        {
            list params = llParseString2List(message, ["|"], []);
            string cmd = llList2String(params, 0);
            
            if (cmd == "STROKE")
            {
                // Update Schlagzahl fuer Spieler an diesem Loch
                integer hole = llList2Integer(params, 1);
                
                // Nur wenn es DIESES Loch ist
                if (hole == HOLE_NUMBER)
                {
                    key owner = llGetOwnerKey(id);
                    string playerName = llKey2Name(owner);
                    integer strokes = llList2Integer(params, 2);
                    
                    // Fuege Spieler hinzu oder update (Total noch unbekannt)
                    AddOrUpdatePlayer(playerName, strokes, 0);
                }
            }
            else if (cmd == "HOLED")
            {
                // Ball eingelocht an diesem Loch
                integer hole = llList2Integer(params, 1);
                
                if (hole == HOLE_NUMBER)
                {
                    key owner = llGetOwnerKey(id);
                    string playerName = llKey2Name(owner);
                    
                    // Hole finale Schlagzahl aus gStrokes
                    integer index = FindPlayer(playerName);
                    if (index != -1)
                    {
                        integer finalStrokes = llList2Integer(gStrokes, index);
                        // Sende an zentrale Scorecard
                        llRegionSay(CHANNEL_SCORE, "HOLESCORE|" + (string)HOLE_NUMBER + "|" + playerName + "|" + (string)finalStrokes);
                    }
                }
            }
        }
        else if (channel == CHANNEL_SCORE)
        {
            list params = llParseString2List(message, ["|"], []);
            string cmd = llList2String(params, 0);
            
            if (cmd == "HOLESCORE")
            {
                // Update von zentraler Scorecard mit Gesamtscore
                integer hole = llList2Integer(params, 1);
                
                if (hole == HOLE_NUMBER)
                {
                    string playerName = llList2String(params, 2);
                    integer strokes = llList2Integer(params, 3);
                    integer total = llList2Integer(params, 4);
                    
                    AddOrUpdatePlayer(playerName, strokes, total);
                }
            }
            else if (cmd == "CLEARHOLE")
            {
                // Admin-Befehl zum Zuruecksetzen
                integer hole = llList2Integer(params, 1);
                if (hole == HOLE_NUMBER || hole == 0)
                {
                    ClearHole();
                }
            }
        }
    }
}
