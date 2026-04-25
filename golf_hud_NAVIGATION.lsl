// Golf HUD mit Navigation und Richtungsanzeige
// Zeigt: Richtung zum Loch, Ball-Position, Distanz

integer CHANNEL_BALL = -8472639;
integer CHANNEL_SCORE = -8472640;

key gOwner;
vector gBallPos = ZERO_VECTOR;
vector gHolePos = ZERO_VECTOR;
integer gCurrentHole = 1;
integer gStrokes = 0;
float gDistance = 0.0;
float gBearingToHole = 0.0;

// Schläger
list gClubNames = ["Driver", "Wood", "Wedge", "Putter"];
list gClubPowers = [40.0, 25.0, 10.0, 3.0];
integer gCurrentClub = 1;

// Power-Stufen
list gPowerLevels = ["25%", "50%", "75%", "100%"];
integer gCurrentPowerLevel = 3;

string BUTTON_DRIVER = "Driver";
string BUTTON_WOOD = "Wood";
string BUTTON_WEDGE = "Wedge";
string BUTTON_PUTTER = "Putter";
string BUTTON_POWER = "Power";
string BUTTON_HIT = "HitButton";
string BUTTON_RESET = "ResetButton";

string GetDirectionName(float angle)
{
    // Konvertiere Winkel zu Himmelsrichtung
    if (angle >= 337.5 || angle < 22.5) return "N";
    else if (angle >= 22.5 && angle < 67.5) return "NE";
    else if (angle >= 67.5 && angle < 112.5) return "E";
    else if (angle >= 112.5 && angle < 157.5) return "SE";
    else if (angle >= 157.5 && angle < 202.5) return "S";
    else if (angle >= 202.5 && angle < 247.5) return "SW";
    else if (angle >= 247.5 && angle < 292.5) return "W";
    else if (angle >= 292.5 && angle < 337.5) return "NW";
    return "N";
}

UpdateDisplay()
{
    string display = "=== HOLE " + (string)gCurrentHole + " ===\n";
    
    // Richtung zum Loch berechnen
    if (gHolePos != ZERO_VECTOR && gBallPos != ZERO_VECTOR)
    {
        vector toHole = gHolePos - gBallPos;
        gBearingToHole = llAtan2(toHole.y, toHole.x) * RAD_TO_DEG;
        
        // Korrektur für OpenSim (-90°)
        gBearingToHole -= 90.0;
        if (gBearingToHole < 0.0) gBearingToHole += 360.0;
        
        gDistance = llVecDist(gBallPos, gHolePos);
        
        string dirName = GetDirectionName(gBearingToHole);
        display += "→ LOCH: " + dirName + " " + (string)((integer)gBearingToHole) + "°\n";
        display += "DIST: " + (string)((integer)gDistance) + "m\n";
    }
    else
    {
        display += "→ LOCH: ---\n";
        display += "DIST: ---\n";
    }
    
    display += "\nBALL: " + (string)((integer)gBallPos.x) + "," + (string)((integer)gBallPos.y) + "\n";
    display += "\n";
    display += "CLUB: " + llList2String(gClubNames, gCurrentClub) + "\n";
    display += "POWER: " + llList2String(gPowerLevels, gCurrentPowerLevel) + "\n";
    display += "STROKES: " + (string)gStrokes;
    
    llSetText(display, <1.0, 1.0, 0.0>, 1.0);
}

HitBall()
{
    // Berechne finale Power
    float clubPower = llList2Float(gClubPowers, gCurrentClub);
    float powerMultiplier = (gCurrentPowerLevel + 1) * 0.25;
    float finalPower = clubPower * powerMultiplier;
    
    // Sende HIT-Befehl an Ball (Ball berechnet Richtung aus Pfeil)
    string message = "HIT|" + (string)finalPower;
    
    llRegionSay(CHANNEL_BALL, message);
    
    string clubName = llList2String(gClubNames, gCurrentClub);
    string powerLevel = llList2String(gPowerLevels, gCurrentPowerLevel);
    llOwnerSay(clubName + " @ " + powerLevel + " = " + (string)((integer)finalPower) + "m");
}

default
{
    state_entry()
    {
        gOwner = llGetOwner();
        llListen(CHANNEL_BALL, "", "", "");
        llListen(CHANNEL_SCORE, "", "", "");
        llSetStatus(STATUS_PHANTOM, TRUE);
        llSetTimerEvent(1.0);
        UpdateDisplay();
        llOwnerSay("=== GOLF HUD MIT NAVIGATION ===");
        llOwnerSay("Zeigt Richtung zum Loch!");
        llOwnerSay("1. Touch Ball für Pfeil-Richtung");
        llOwnerSay("2. Wähle Schläger + Power");
        llOwnerSay("3. Touch HIT!");
    }
    
    on_rez(integer start_param)
    {
        llResetScript();
    }
    
    touch_start(integer num)
    {
        if (llDetectedKey(0) != gOwner) return;
        
        string primName = llGetLinkName(llDetectedLinkNumber(0));
        
        if (primName == BUTTON_DRIVER)
        {
            gCurrentClub = 0;
            llOwnerSay("Driver (40m)");
            UpdateDisplay();
        }
        else if (primName == BUTTON_WOOD)
        {
            gCurrentClub = 1;
            llOwnerSay("Wood (25m)");
            UpdateDisplay();
        }
        else if (primName == BUTTON_WEDGE)
        {
            gCurrentClub = 2;
            llOwnerSay("Wedge (10m)");
            UpdateDisplay();
        }
        else if (primName == BUTTON_PUTTER)
        {
            gCurrentClub = 3;
            llOwnerSay("Putter (3m)");
            UpdateDisplay();
        }
        else if (primName == BUTTON_POWER)
        {
            // Cycle through power levels
            gCurrentPowerLevel++;
            if (gCurrentPowerLevel >= llGetListLength(gPowerLevels))
                gCurrentPowerLevel = 0;
            
            llOwnerSay("Power: " + llList2String(gPowerLevels, gCurrentPowerLevel));
            UpdateDisplay();
        }
        else if (primName == BUTTON_HIT)
        {
            HitBall();
        }
        else if (primName == BUTTON_RESET)
        {
            llRegionSay(CHANNEL_BALL, "RESET");
            llOwnerSay("Ball reset");
        }
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (channel == CHANNEL_BALL)
        {
            list params = llParseString2List(message, ["|"], []);
            string cmd = llList2String(params, 0);
            
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
            else if (cmd == "BALLREZZED")
            {
                gCurrentHole = llList2Integer(params, 1);
                gStrokes = 0;
                UpdateDisplay();
            }
            else if (cmd == "HOLED")
            {
                llOwnerSay("=== EINGELOCHT! ===");
                llOwnerSay("Hole " + (string)gCurrentHole + " in " + (string)gStrokes + " strokes!");
                llRegionSay(CHANNEL_SCORE, "SCORE|" + (string)gCurrentHole + "|" + (string)gStrokes);
            }
        }
        else if (channel == CHANNEL_SCORE)
        {
            list params = llParseString2List(message, ["|"], []);
            if (llList2String(params, 0) == "HOLEINFO")
            {
                gCurrentHole = llList2Integer(params, 1);
                gHolePos = <llList2Float(params, 2), llList2Float(params, 3), llList2Float(params, 4)>;
                
                llOwnerSay("Loch " + (string)gCurrentHole + " Position: " + (string)gHolePos);
                UpdateDisplay();
            }
        }
    }
    
    timer()
    {
        llRegionSay(CHANNEL_BALL, "GETPOS");
        
        // Frage auch nach Loch-Info
        llRegionSay(CHANNEL_SCORE, "GETHOLE|" + (string)gCurrentHole);
    }
}
