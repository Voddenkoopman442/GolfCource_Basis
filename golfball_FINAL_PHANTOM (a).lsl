
// Golf Ball PHANTOM - Optimierte Version
// Behebt das Problem, dass der Ball nicht fliegt oder am Boden stecken bleibt.

integer CHANNEL_BALL = -8472639;
key gOwner;
vector gStartPos;
integer gStrokes = 0;

vector gVelocity = ZERO_VECTOR;
float gFlightTime = 0.0;
integer gIsFlying = FALSE;

// Pfeil-System
integer gArrowVisible = FALSE;
float gArrowAngle = 0.0;
integer gMenuChannel;
integer gMenuHandle;

// Bodenstrukturen
string gCurrentSurface = "grass";
float gFrictionMultiplier = 1.0;

// === EINSTELLUNGEN ===
float POWER_MULTIPLIER = 1.0;
float FRICTION = 0.98;              
float GRAVITY = 9.8;
float BOUNCE = 0.4;                 

StartBeacon()
{
    llParticleSystem([
        PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
        PSYS_PART_START_COLOR, <1.0, 1.0, 0.0>,
        PSYS_PART_END_COLOR, <1.0, 0.5, 0.0>,
        PSYS_PART_START_ALPHA, 1.0,
        PSYS_PART_END_ALPHA, 1.0,
        PSYS_PART_START_SCALE, <0.3, 0.3, 0.0>,
        PSYS_PART_END_SCALE, <0.3, 0.3, 0.0>,
        PSYS_PART_MAX_AGE, 3.0,
        PSYS_SRC_BURST_PART_COUNT, 20,
        PSYS_SRC_BURST_RATE, 0.1,
        PSYS_SRC_BURST_SPEED_MIN, 3.0,
        PSYS_SRC_BURST_SPEED_MAX, 3.0,
        PSYS_SRC_ACCEL, <0, 0, 5.0>
    ]);
}

StartFlightTrail()
{
    llParticleSystem([
        PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
        PSYS_PART_START_COLOR, <1.0, 1.0, 1.0>,
        PSYS_PART_END_COLOR, <0.8, 0.8, 0.8>,
        PSYS_PART_START_ALPHA, 1.0,
        PSYS_PART_END_ALPHA, 0.0,
        PSYS_PART_START_SCALE, <0.2, 0.2, 0.0>,
        PSYS_PART_END_SCALE, <0.4, 0.4, 0.0>,
        PSYS_PART_MAX_AGE, 1.0,
        PSYS_SRC_BURST_PART_COUNT, 5,
        PSYS_SRC_BURST_RATE, 0.05,
        PSYS_SRC_BURST_SPEED_MIN, 0.1,
        PSYS_SRC_BURST_SPEED_MAX, 0.3
    ]);
}

StopParticles()
{
    llParticleSystem([]);
}

ShowArrow()
{
    float angleRad = gArrowAngle * DEG_TO_RAD;
    llParticleSystem([
        PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK | PSYS_PART_FOLLOW_VELOCITY_MASK,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE,
        PSYS_PART_START_COLOR, <1.0, 0.0, 0.0>,
        PSYS_PART_END_COLOR, <1.0, 0.5, 0.0>,
        PSYS_PART_START_ALPHA, 1.0,
        PSYS_PART_END_ALPHA, 0.3,
        PSYS_PART_START_SCALE, <0.3, 0.3, 0.0>,
        PSYS_PART_END_SCALE, <0.15, 0.15, 0.0>,
        PSYS_PART_MAX_AGE, 2.0,
        PSYS_SRC_BURST_PART_COUNT, 20,
        PSYS_SRC_BURST_RATE, 0.05,
        PSYS_SRC_BURST_SPEED_MIN, 3.0,
        PSYS_SRC_BURST_SPEED_MAX, 3.0,
        PSYS_SRC_ANGLE_BEGIN, 0.0,
        PSYS_SRC_ANGLE_END, 0.05,
        PSYS_SRC_OMEGA, <0, 0, angleRad>,
        PSYS_SRC_ACCEL, <0, 0, 0>
    ]);
    
    string direction = "N";
    if (gArrowAngle >= 337.5 || gArrowAngle < 22.5) direction = "N";
    else if (gArrowAngle >= 22.5 && gArrowAngle < 67.5) direction = "NE";
    else if (gArrowAngle >= 67.5 && gArrowAngle < 112.5) direction = "E";
    else if (gArrowAngle >= 112.5 && gArrowAngle < 157.5) direction = "SE";
    else if (gArrowAngle >= 157.5 && gArrowAngle < 202.5) direction = "S";
    else if (gArrowAngle >= 202.5 && gArrowAngle < 247.5) direction = "SW";
    else if (gArrowAngle >= 247.5 && gArrowAngle < 292.5) direction = "W";
    else if (gArrowAngle >= 292.5 && gArrowAngle < 337.5) direction = "NW";
    llSetText("⛳ Ziel: " + direction + "\n" + (string)((integer)gArrowAngle) + "°", <1, 0, 0>, 1.0);
}

ShowMenu()
{
    string msg = "Zielhilfe\nRichtung: " + (string)((integer)gArrowAngle) + "°";
    list buttons = ["← 45°", "← 15°", "← 5°", "→ 5°", "→ 15°", "→ 45°", "Fertig", "Reset"];
    llListenRemove(gMenuHandle);
    gMenuChannel = -1 - (integer)llFrand(999999);
    gMenuHandle = llListen(gMenuChannel, "", gOwner, "");
    llDialog(gOwner, msg, buttons, gMenuChannel);
    llSetTimerEvent(30.0);
}

DetectSurface()
{
    vector pos = llGetPos();
    list results = llCastRay(pos, pos + <0, 0, -10>, [RC_MAX_HITS, 1, RC_DETECT_PHANTOM, FALSE]);
    if (llList2Integer(results, -1) > 0)
    {
        string hitName = llToLower(llList2String(results, 1));
        if (llSubStringIndex(hitName, "water") != -1 || llSubStringIndex(hitName, "wasser") != -1)
        {
            gCurrentSurface = "water";
            gFrictionMultiplier = 0.3;
            llSetColor(<0.3, 0.5, 1.0>, ALL_SIDES);
            llOwnerSay("Im Wasser! +1 Strafschlag");
            gStrokes++;
            llSleep(2.0);
            llSetPos(gStartPos);
            gVelocity = ZERO_VECTOR;
            gIsFlying = FALSE;
            llSetColor(<1.0, 1.0, 1.0>, ALL_SIDES);
            StartBeacon();
        }
        else if (llSubStringIndex(hitName, "sand") != -1 || llSubStringIndex(hitName, "bunker") != -1)
        {
            gCurrentSurface = "sand";
            gFrictionMultiplier = 2.5;
            llSetColor(<1.0, 0.9, 0.6>, ALL_SIDES);
        }
        else if (llSubStringIndex(hitName, "rough") != -1)
        {
            gCurrentSurface = "rough";
            gFrictionMultiplier = 1.8;
            llSetColor(<0.6, 0.8, 0.4>, ALL_SIDES);
        }
        else
        {
            gCurrentSurface = "grass";
            gFrictionMultiplier = 1.0;
            llSetColor(<1.0, 1.0, 1.0>, ALL_SIDES);
        }
    }
}

integer CheckCollisions(vector currentPos, vector nextPos)
{
    list results = llCastRay(currentPos, nextPos, [RC_MAX_HITS, 1, RC_DETECT_PHANTOM, FALSE]);
    if (llList2Integer(results, -1) > 0)
    {
        gVelocity = gVelocity * -BOUNCE;
        return TRUE;
    }
    return FALSE;
}

default
{
    state_entry()
    {
        gOwner = llGetOwner();
        gStartPos = llGetPos();
        llSetStatus(STATUS_PHYSICS, FALSE);
        llSetStatus(STATUS_PHANTOM, TRUE);
        llSetColor(<1.0, 1.0, 1.0>, ALL_SIDES);
        llSetPrimitiveParams([PRIM_SIZE, <0.1, 0.1, 0.1>, PRIM_TYPE, PRIM_TYPE_SPHERE, 0, <0.0, 1.0, 0.0>, 0.0, <0.0, 0.0, 0.0>, <1.0, 1.0, 0.0>]);
        llListen(CHANNEL_BALL, "", "", "");
        llSetTimerEvent(0.5);
        StartBeacon();
        llSetText("⛳ Golf Ball\n[Touch = Zielhilfe]", <1, 1, 0>, 1.0);
        gArrowAngle = 0.0;
    }
    
    on_rez(integer start_param) { llResetScript(); }
    
    touch_start(integer num)
    {
        if (llDetectedKey(0) != gOwner) return;
        if (!gIsFlying)
        {
            gArrowVisible = TRUE;
            ShowArrow();
            ShowMenu();
        }
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (channel == gMenuChannel)
        {
            if (message == "← 5°") gArrowAngle -= 5.0;
            else if (message == "← 15°") gArrowAngle -= 15.0;
            else if (message == "← 45°") gArrowAngle -= 45.0;
            else if (message == "→ 5°") gArrowAngle += 5.0;
            else if (message == "→ 15°") gArrowAngle += 15.0;
            else if (message == "→ 45°") gArrowAngle += 45.0;
            else if (message == "Fertig") { llListenRemove(gMenuHandle); llOwnerSay("Richtung: " + (string)((integer)gArrowAngle) + "°"); return; }
            else if (message == "Reset") gArrowAngle = 0.0;
            
            if (gArrowAngle < 0.0) gArrowAngle += 360.0;
            if (gArrowAngle >= 360.0) gArrowAngle -= 360.0;
            ShowArrow();
            ShowMenu();
        }
        else if (channel == CHANNEL_BALL)
        {
            list params = llParseString2List(message, ["|"], []);
            string cmd = llList2String(params, 0);
            
            if (cmd == "HIT")
            {
                float power = llList2Float(params, 1);
                float angleRad = (gArrowAngle + 90.0) * DEG_TO_RAD;
                vector direction = <llCos(angleRad), llSin(angleRad), 0.4>; // Erhöhter Startwinkel
                direction = llVecNorm(direction);
                
                llSetPos(llGetPos() + <0, 0, 0.2>); // Kleiner Hopser nach oben beim Start
                gVelocity = direction * (power * POWER_MULTIPLIER);
                gIsFlying = TRUE;
                gArrowVisible = FALSE;
                StartFlightTrail();
                gStrokes++;
                llRegionSay(CHANNEL_BALL, "STROKE|" + (string)gStrokes);
                llSetTimerEvent(0.05);
            }
            else if (cmd == "RESET") { llSetPos(gStartPos); gVelocity = ZERO_VECTOR; gIsFlying = FALSE; StopParticles(); StartBeacon(); gStrokes = 0; llSetColor(<1.0, 1.0, 1.0>, ALL_SIDES); llSetTimerEvent(0.5); }
            else if (cmd == "GETPOS") 
            { 
                vector currentPos = llGetPos(); 
                llRegionSay(CHANNEL_BALL, "BALLPOS|" + (string)currentPos.x + "|" + (string)currentPos.y + "|" + (string)currentPos.z); 
            }
            else if (cmd == "HOLED") { StopParticles(); llDie(); }
        }
    }
    
    timer()
    {
        if (!gIsFlying)
        {
            vector pos = llGetPos();
            llRegionSay(CHANNEL_BALL, "BALLPOS|" + (string)pos.x + "|" + (string)pos.y + "|" + (string)pos.z);
            if (gArrowVisible) ShowArrow();
        }
        else
        {
            vector pos = llGetPos();
            float dt = 0.05;
            gVelocity += <0, 0, -GRAVITY> * dt;
            gVelocity = gVelocity * (FRICTION / gFrictionMultiplier);
            
            vector nextPos = pos + (gVelocity * dt);
            CheckCollisions(pos, nextPos);
            
            float groundHeight = llGround(ZERO_VECTOR);
            if (nextPos.z < groundHeight + 0.05)
            {
                nextPos.z = groundHeight + 0.05;
                if (llFabs(gVelocity.z) > 0.5) gVelocity.z = llFabs(gVelocity.z) * BOUNCE;
                else gVelocity.z = 0;
                
                DetectSurface();
                if (llVecMag(<gVelocity.x, gVelocity.y, 0>) < 0.2 && llFabs(gVelocity.z) < 0.1)
                {
                    gIsFlying = FALSE;
                    gVelocity = ZERO_VECTOR;
                    StopParticles();
                    StartBeacon();
                    llSetText("⛳ Ball - " + gCurrentSurface + "\n" + (string)gStrokes + " Schläge", <1, 1, 0>, 1.0);
                    llSetTimerEvent(0.5);
                }
            }
            llSetPos(nextPos);
            llRegionSay(CHANNEL_BALL, "BALLPOS|" + (string)nextPos.x + "|" + (string)nextPos.y + "|" + (string)nextPos.z);
        }
    }
}