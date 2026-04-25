// Golfloch mit automatischer Einloch-Erkennung und Effekten
// Sendet Position ans HUD und reagiert auf den Ball

integer CHANNEL_BALL = -8472639;
integer CHANNEL_SCORE = -8472640;
integer gHoleNumber = 1;  // HIER ANPASSEN für jedes Loch!
vector gHolePos;

// Effekt: Kleines Feuerwerk beim Einlochen
Celebrate()
{
    llParticleSystem([
        PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_INTERP_SCALE_MASK,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
        PSYS_PART_START_COLOR, <1.0, 1.0, 0.0>,
        PSYS_PART_END_COLOR, <1.0, 0.0, 0.0>,
        PSYS_PART_START_ALPHA, 1.0,
        PSYS_PART_END_ALPHA, 0.0,
        PSYS_PART_START_SCALE, <0.1, 0.1, 0.0>,
        PSYS_PART_END_SCALE, <0.5, 0.5, 0.0>,
        PSYS_PART_MAX_AGE, 2.0,
        PSYS_SRC_BURST_PART_COUNT, 100,
        PSYS_SRC_BURST_RATE, 0.01,
        PSYS_SRC_BURST_SPEED_MIN, 1.0,
        PSYS_SRC_BURST_SPEED_MAX, 5.0,
        PSYS_SRC_ACCEL, <0, 0, -1.0>
    ]);
    
    // Sound abspielen (Standard SL Sound oder eigene UUID einfügen)
    llPlaySound("e0a81615-3733-460d-8386-81da0d165f12", 1.0); 
    
    llSleep(2.0);
    llParticleSystem([]); // Partikel wieder ausschalten
}

default
{
    state_entry()
    {
        gHolePos = llGetPos();
        llSetStatus(STATUS_PHANTOM, TRUE);
        llVolumeDetect(TRUE); // Wichtig für die Kollisionserkennung ohne wegzustoßen
        
        llSetText("⛳ Loch " + (string)gHoleNumber, <1,1,1>, 1.0);
        
        // Sofortige Meldung an HUDs in der Nähe
        llRegionSay(CHANNEL_SCORE, "HOLEINFO|" + (string)gHoleNumber + "|" + (string)gHolePos.x + "|" + (string)gHolePos.y + "|" + (string)gHolePos.z);
        
        llSetTimerEvent(5.0); // Regelmäßiger Positions-Sync
        llListen(CHANNEL_SCORE, "", "", "");
    }
    
    timer()
    {
        // Broadcast für HUDs, die neu in die Region kommen
        llRegionSay(CHANNEL_SCORE, "HOLEINFO|" + (string)gHoleNumber + "|" + (string)gHolePos.x + "|" + (string)gHolePos.y + "|" + (string)gHolePos.z);
    }
    
    collision_start(integer num)
    {
        integer i;
        for (i = 0; i < num; i++)
        {
            string name = llToLower(llDetectedName(i));
            // Prüfen, ob das kollidierende Objekt ein Golfball ist
            if (llSubStringIndex(name, "ball") != -1)
            {
                key ballKey = llDetectedKey(i);
                
                // Nachricht an den Ball: Du bist eingelocht!
                llRegionSayTo(ballKey, CHANNEL_BALL, "HOLED");
                
                // Nachricht ans HUD: Erfolg!
                llRegionSay(CHANNEL_BALL, "HOLED"); 
                
                llOwnerSay("TREFFER! Loch " + (string)gHoleNumber + " abgeschlossen.");
                
                Celebrate();
            }
        }
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (message == "GETHOLE|" + (string)gHoleNumber)
        {
            llRegionSay(CHANNEL_SCORE, "HOLEINFO|" + (string)gHoleNumber + "|" + (string)gHolePos.x + "|" + (string)gHolePos.y + "|" + (string)gHolePos.z);
        }
    }
}