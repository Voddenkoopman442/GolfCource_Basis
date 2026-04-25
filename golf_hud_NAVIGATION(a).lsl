// Golf HUD - Optimierte Version
// Bessere Synchronisation mit dem Ball und flüssigere Anzeige

integer CHANNEL_BALL = -8472639;
integer CHANNEL_SCORE = -8472640;

key gOwner;
vector gBallPos = ZERO_VECTOR;
vector gHolePos = ZERO_VECTOR;
integer gCurrentHole = 1;
integer gStrokes = 0;
float gDistance = 0.0;
float gBearingToHole = 0.0;

// Schläger & Power
list gClubNames = ["Driver", "Wood", "Wedge", "Putter"];
list gClubPowers = [45.0, 30.0, 15.0, 5.0];
integer gCurrentClub = 1;
list gPowerLevels = ["25%", "50%", "75%", "100%"];
integer gCurrentPowerLevel = 3;

// Button-Namen (müssen mit den Prims im HUD übereinstimmen)
string BUTTON_HIT = "HitButton";
string BUTTON_RESET = "ResetButton";

string GetDirectionName(float angle)
{
    if (angle >= 337.5 || angle < 22.5) return "N";
    else if (angle >= 22.5 && angle < 67.5) return "NE";
    else if (angle >= 67.5 && angle < 112.5) return "E";
    else if (angle >= 112.5 && angle < 157.5) return "SE";
    else if (angle >= 157.5 && angle < 202.5) return "S";
    else if (angle >= 202.5 && angle < 247.5) return "SW";
    else if (angle >= 247.5 && angle < 292.5) return "W";
    else if (angle >= 292.5 && angle < 337.5) return "NW";
    return "?";
}

UpdateDisplay()
{
    string display = "=== HOLE " + (string)gCurrentHole + " ===\n";
    
    if (gHolePos != ZERO_VECTOR && gBallPos != ZERO_VECTOR)
    {
        vector toHole = gHolePos - gBallPos;
        gBearingToHole = llAtan2(toHole.y, toHole.x) * RAD_TO_DEG;
        
        // OpenSim Nord-Korrektur
        gBearingToHole -= 90.0;
        if (gBearingToHole < 0.0) gBearingToHole += 360.0;
        
        gDistance = llVecDist(gBallPos, gHolePos);
        string dirName = GetDirectionName(gBearingToHole);
        
        display += "→ LOCH: " + dirName + " (" + (string)((integer)gBearingToHole) + "°)\n";
        display += "DISTANZ: " + (string)llGetSubString((string)gDistance, 0, 3) + "m\n";
    }
    else
    {
        display += "Suche Ball/Loch...\n";
    }
    
    display += "----------------\n";
    display += "CLUB: " + llList2String(gClubNames, gCurrentClub) + "\n";
    display += "POWER: " + llList2String(gPowerLevels, gCurrentPowerLevel) + "\n";
    display += "STROKES: " + (string)gStrokes;
    
    llSetText(display, <1,1,1>, 1.0);
}

HitBall()
{
    float basePower = llList2Float(gClubPowers, gCurrentClub);
    float mult = (gCurrentPowerLevel + 1) * 0.25;
    float finalPower = basePower * mult;
    
    llRegionSay(CHANNEL_BALL, "HIT|" + (string)finalPower);
    llOwnerSay("Schlag mit " + llList2String(gClubNames, gCurrentClub) + " (" + (string)((integer)(mult*100)) + "%)");
}

default
{
    state_entry()
    {
        gOwner = llGetOwner();
        llListen(CHANNEL_BALL, "", "", "");
        llListen(CHANNEL_SCORE, "", "", "");
        
        // Schnellerer Timer für flüssige Distanzanzeige
        llSetTimerEvent(0.25);
        UpdateDisplay();
    }

    touch_start(integer num)
    {
        string btn = llGetObjectName(); // Oder llGetLinkName(llDetectedLinkNumber(0));
       btn = llGetLinkName(llDetectedLinkNumber(0));

        if (btn == "Driver") gCurrentClub = 0;
        else if (btn == "Wood") gCurrentClub = 1;
        else if (btn == "Wedge") gCurrentClub = 2;
        else if (btn == "Putter") gCurrentClub = 3;
        else if (btn == "Power") 
        {
            gCurrentPowerLevel++;
            if (gCurrentPowerLevel > 3) gCurrentPowerLevel = 0;
        }
        else if (btn == BUTTON_HIT) HitBall();
        else if (btn == BUTTON_RESET) llRegionSay(CHANNEL_BALL, "RESET");

        UpdateDisplay();
    }

    listen(integer channel, string name, key id, string message)
    {
        list params = llParseString2List(message, ["|"], []);
        string cmd = llList2String(params, 0);

        if (channel == CHANNEL_BALL)
        {
            if (cmd == "BALLPOS")
            {
                gBallPos = <llList2Float(params, 1), llList2Float(params, 2), llList2Float(params, 3)>;
                UpdateDisplay();
            }
            else if (cmd == "STROKE")
            {
                gStrokes = llList2Integer(params, 1);
                UpdateDisplay();
            }
        }
        else if (channel == CHANNEL_SCORE)
        {
            if (cmd == "HOLEINFO")
            {
                gCurrentHole = llList2Integer(params, 1);
                gHolePos = <llList2Float(params, 2), llList2Float(params, 3), llList2Float(params, 4)>;
                UpdateDisplay();
            }
        }
    }

    timer()
    {
        // Fordere Position an, falls der Ball nicht von selbst sendet
        llRegionSay(CHANNEL_BALL, "GETPOS");
    }
}