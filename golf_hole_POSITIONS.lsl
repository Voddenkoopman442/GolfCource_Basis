// Golfloch mit Position-Broadcasting
// Sendet Position regelmäßig ans HUD

integer CHANNEL_BALL = -8472639;
integer CHANNEL_SCORE = -8472640;
integer gHoleNumber = 1;  // HIER ANPASSEN für jedes Loch!
vector gHolePos;

default
{
    state_entry()
    {
        gHolePos = llGetPos();
        llSetStatus(STATUS_PHANTOM, TRUE);
        llVolumeDetect(TRUE);
        llSetText("⛳ Hole " + (string)gHoleNumber, <1,1,1>, 1.0);
        
        // Sende Position sofort
        llRegionSay(CHANNEL_SCORE, "HOLEINFO|" + (string)gHoleNumber + "|" + (string)gHolePos.x + "|" + (string)gHolePos.y + "|" + (string)gHolePos.z);
        
        // Timer für regelmäßiges Senden
        llSetTimerEvent(5.0);
        
        llListen(CHANNEL_SCORE, "", "", "");
        
        llOwnerSay("Loch " + (string)gHoleNumber + " bereit an: " + (string)gHolePos);
    }
    
    timer()
    {
        // Sende Position regelmäßig
        llRegionSay(CHANNEL_SCORE, "HOLEINFO|" + (string)gHoleNumber + "|" + (string)gHolePos.x + "|" + (string)gHolePos.y + "|" + (string)gHolePos.z);
    }
    
    listen(integer channel, string name, key id, string message)
    {
        list params = llParseString2List(message, ["|"], []);
        string cmd = llList2String(params, 0);
        
        if (cmd == "GETHOLE")
        {
            integer requestedHole = llList2Integer(params, 1);
            if (requestedHole == gHoleNumber)
            {
                // HUD fragt nach diesem Loch - antworte sofort
                llRegionSay(CHANNEL_SCORE, "HOLEINFO|" + (string)gHoleNumber + "|" + (string)gHolePos.x + "|" + (string)gHolePos.y + "|" + (string)gHolePos.z);
            }
        }
    }
    
    collision_start(integer num)
    {
        integer i;
        for (i = 0; i < num; i++)
        {
            string name = llDetectedName(i);
            if (llSubStringIndex(name, "olf") != -1)
            {
                key owner = llGetOwnerKey(llDetectedKey(i));
                llRegionSay(CHANNEL_BALL, "HOLED|" + (string)gHoleNumber + "|" + (string)gHolePos.x + "|" + (string)gHolePos.y + "|" + (string)gHolePos.z);
                llRegionSayTo(owner, 0, "⛳ EINGELOCHT in Loch " + (string)gHoleNumber + "!");
            }
        }
    }
}
