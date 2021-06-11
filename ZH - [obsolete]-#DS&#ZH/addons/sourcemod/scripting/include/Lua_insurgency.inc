	#define		MAXPLAYERS_INS		49

/*				Player Flags			*/
	#define		INS_PL_ZOOM				(1 << 0)		// 1		// Force to zoom
	#define		INS_PL_1				(1 << 1)		// 2		// It could be ducking but massive buggy to use
	#define		INS_PL_RUN				(1 << 2)		// 4		// Force to run if keep setting this, player cant normal walk or slow walk
	#define		INS_PL_WALK				(1 << 3)		// 8		// Force to walk only but player still can run just cannot normal walking
	#define		INS_PL_4				(1 << 4)		// 16		// 
	#define		INS_PL_FOCUS			(1 << 5)		// 32		// Zoom Focus (Buggy)
	#define		INS_PL_SLIDE			(1 << 6)		// 64		// Force to sliding, if you keep setting this, player forever sliding lol
	#define		INS_PL_BUYZONE			(1 << 7)		// 128		// Buyzone, Resupply everywhere! (Note: Buyzone makes no friendlyfire damage)
	#define		INS_PL_8				(1 << 8)		// 256		// 
	#define		INS_PL_BLOCKZONE		(1 << 9)		// 512		// Restricted Zone, Player will be restricted, (Note: This flag applied with INS_PL_LOWERZONE)
	#define		INS_PL_LOWERZONE		(1 << 10)		// 1024		// Weapon Lower Zone
	#define		INS_PL_SPAWNZONE		(1 << 11)		// 2048		// ENTER SPAWN ZONE (Also can resupply)
	#define		INS_PL_12				(1 << 12)		// 4096		//
	
/*				Player Buttons			*/
	#define		INS_ATTACK1				(1 << 0)
	#define		INS_JUMP				(1 << 1)
	#define		INS_DUCK				(1 << 2)
	#define		INS_PRONE				(1 << 3)
	#define		INS_FORWARD				(1 << 4)
	#define		INS_BACKWARD			(1 << 5)
	#define		INS_USE					(1 << 6)
	#define		INS_LEFT				(1 << 9)
	#define		INS_RIGHT				(1 << 10)
	#define		INS_RELOAD				(1 << 11)
	#define		INS_FIREMODE			(1 << 12)
	#define		INS_LEAN_LEFT			(1 << 13)
	#define		INS_LEAN_RIGHT			(1 << 14)
	#define		INS_SPRINT				(1 << 15)
	#define		INS_WALK				(1 << 16)
	#define		INS_SPECIAL1			(1 << 17)
	#define		INS_AIM					(1 << 18)
	#define		INS_SCOREBOARD			(1 << 19)
	#define		INS_FLASHLIGHT			(1 << 22)
	#define		INS_AIM_TOGGLE			(1 << 27)
	#define		INS_ACCESSORY			(1 << 28)
/*

enum INS_GameState
{
	StartGame = 0,
	GamemodeReset,
	GamemodeStarted,
	RoundDraw,
	SecurityWin,
	InsurgentWin,
	RoundResult,
	PreRoundReset,
	RoundReset,
	RoundStarted,
	GameOver
}

public InitGameStateHooks()
{
	HookEntityOutput("ins_rulesproxy", "OnStartGame", INS_GameStateUpdate);
	HookEntityOutput("ins_rulesproxy", "OnGamemodeStarted", INS_GameStateUpdate);
	HookEntityOutput("ins_rulesproxy", "OnRoundDraw", INS_GameStateUpdate);
	HookEntityOutput("ins_rulesproxy", "OnSecurityWin", INS_GameStateUpdate);
	HookEntityOutput("ins_rulesproxy", "OnInsurgentWin", INS_GameStateUpdate);
	HookEntityOutput("ins_rulesproxy", "OnRoundResult", INS_GameStateUpdate);
	HookEntityOutput("ins_rulesproxy", "OnGameOver", INS_GameStateUpdate);
	HookEntityOutput("ins_rulesproxy", "OnGamemodeReset", INS_GameStateUpdate);
	HookEntityOutput("ins_rulesproxy", "OnPreRoundReset", INS_GameStateUpdate);
	HookEntityOutput("ins_rulesproxy", "OnRoundReset", INS_GameStateUpdate);
	HookEntityOutput("ins_rulesproxy", "OnRoundStarted", INS_GameStateUpdate);
}
*/

#define	SHAKE_START					0			// Starts the screen shake for all players within the radius.
#define	SHAKE_STOP					1			// Stops the screen shake for all players within the radius.
#define	SHAKE_AMPLITUDE				2			// Modifies the amplitude of an active screen shake for all players within the radius.
#define	SHAKE_FREQUENCY				3			// Modifies the frequency of an active screen shake for all players within the radius.
#define	SHAKE_START_RUMBLEONLY		4			// Starts a shake effect that only rumbles the controller, no screen effect.
#define	SHAKE_START_NORUMBLE		5			// Starts a shake that does NOT rumble the controller.

/**
 * Shakes a client's screen with the specified amptitude,
 * frequency & duration.
 * 
 * @param client		Client Index.
 * @param command		Shake Mode, use one of the SHAKE_ definitions.
 * @param amplitude		Shake magnitude/amplitude.
 * @param frequency		Shake noise frequency.
 * @param duration		Shake lasts this long.
 * @return				True on success, false otherwise.
 */
stock bool:ClientScreenShake(client, command=SHAKE_START, Float:amplitude=50.0, Float:frequency=150.0, Float:duration=3.0)
{
	if (command == SHAKE_STOP) {
		amplitude = 0.0;
	}
	else if (amplitude <= 0.0) {
		return false;
	}
	
	new Handle:userMessage = StartMessageOne("Shake", client);
	
	if (userMessage == INVALID_HANDLE)
		return false;

	BfWriteByte(userMessage,	command);	// Shake Command
	BfWriteFloat(userMessage,	amplitude);	// shake magnitude/amplitude
	BfWriteFloat(userMessage,	frequency);	// shake noise frequency
	BfWriteFloat(userMessage,	duration);	// shake lasts this long

	EndMessage();

	return true;
}

stock bool:ClientScreenFade(client, duration, mode, holdtime=-1, r=0, g=0, b=0, a=255, bool:reliable=true)
{
	new Handle:userMessage = StartMessageOne("Fade", client, USERMSG_RELIABLE);
	
	if (userMessage == INVALID_HANDLE)
		return false;

	new color[4];
	color[0] = r;
	color[1] = g;
	color[2] = b;
	color[3] = a;

	BfWriteShort(userMessage,	duration);	// Fade duration
	BfWriteShort(userMessage,	holdtime);	// Fade hold time
	BfWriteShort(userMessage,	mode);		// What to do
	BfWriteByte(userMessage,	r);			// Color R
	BfWriteByte(userMessage,	g);			// Color G
	BfWriteByte(userMessage,	b);			// Color B
	BfWriteByte(userMessage,	a);			// Color Alpha
	EndMessage();
	
	return true;
}

stock GetClientHeadOrigin(client, Float:fOrigin[3], Float:z = 0.0)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return false;
	GetClientAbsOrigin(client, fOrigin);
	new Float:fSize = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	switch(GetEntProp(client, Prop_Send, "m_iCurrentStance"))
	{
		case 0: fOrigin[2] += 75.0*fSize+z;	// Standing
		case 1: fOrigin[2] += 49.0*fSize+z;	// Duck
		case 2: fOrigin[2] += 24.0*fSize+z;	// Prone
	}
	return true;
}

stock GetPlayerCount(team = -1, bool:alive = false, bool:bots = true, bool:spec = false)
{
	new count = 0;
	for (new i = 1;i <= MaxClients;i++)
	{
		if (!IsClientInGame(i)) continue;
		new iTeam = GetClientTeam(i);
		if (iTeam <= 1 && !spec) continue;
		if (iTeam == team || team == -1)
		{
			if (alive && !IsPlayerAlive(i)) continue;
			if (!bots && IsFakeClient(i)) continue;
			count++;
		}
	}
	return count;
}

stock GetRandomPlayer(without_client = -1, team = -1, bool:alive = false, bool:bots = true, bool:spec = false)
{
	new count = -1, iPlayers[MAXPLAYERS_INS+1];
	for (new i = 1;i <= MaxClients;i++)
	{
		if (!IsClientInGame(i)) continue;
		if (i == without_client) continue;
		new iTeam = GetClientTeam(i);
		if (iTeam <= 1 && !spec) continue;
		if (iTeam == team || team == -1)
		{
			if (alive && !IsPlayerAlive(i)) continue;
			if (!bots && IsFakeClient(i)) continue;
			iPlayers[++count] = i;
		}
	}
	return count > -1?iPlayers[GetRandomInt(0, count)]:-1;
}
/*
public INS_GameStateUpdate(const String:output[], caller, activator, Float:delay)
{
	if (StrEqual(output, "OnStartGame", false))
		g_iGameState = _:StartGame;
	else if (StrEqual(output, "OnGamemodeStarted", false))
		g_iGameState = _:GamemodeStarted;
	else if (StrEqual(output, "OnRoundDraw", false))
		g_iGameState = _:RoundDraw;
	else if (StrEqual(output, "OnSecurityWin", false))
		g_iGameState = _:SecurityWin;
	else if (StrEqual(output, "OnInsurgentWin", false))
		g_iGameState = _:InsurgentWin;
	else if (StrEqual(output, "OnRoundResult", false))
		g_iGameState = _:RoundResult;
	else if (StrEqual(output, "OnGameOver", false))
		g_iGameState = _:GameOver;
	else if (StrEqual(output, "OnGamemodeReset", false))
		g_iGameState = _:GamemodeReset;
	else if (StrEqual(output, "OnPreRoundReset", false))
		g_iGameState = _:PreRoundReset;
	else if (StrEqual(output, "OnRoundReset", false))
		g_iGameState = _:RoundReset;
	else if (StrEqual(output, "OnRoundStarted", false))
		g_iGameState = _:RoundStarted;
//	PrintToChatAll("GameState Updated %d", g_iGameState);
//	LogToGame("GameState Updated %d", g_iGameState);
}

stock INS_GameState:GetGameState()
{
	return INS_GameState:g_iGameState;
}
*/
stock SetGameState(value)
{
	return GameRules_SetProp("m_iGameState", value);
}

stock GetGameState()
{
	return GameRules_GetProp("m_iGameState");
}

stock GetCounterAttack()
{
	return GameRules_GetProp("m_bCounterAttack");
}

stock bool:GetTimerPause()
{
	return bool:GameRules_GetProp("m_bTimerPaused");
}

stock Float:GetRoundLengthTime()
{
	return GameRules_GetPropFloat("m_flRoundLength");
}

stock Float:GetRoundStartTime()
{
	return GameRules_GetPropFloat("m_flRoundStartTime");
}

stock SetTimerPause(bool:pause)
{
	GameRules_SetProp("m_bTimerPaused", pause);
	return pause;
}

stock Float:SetRoundTime(Float:time)
{
	return Float:GameRules_SetPropFloat("m_flRoundLength", (GetGameTime()-GameRules_GetPropFloat("m_flRoundStartTime"))+time);
}

stock Float:GetRoundTime()
{
	return GameRules_GetPropFloat("m_flRoundLength")-(GetGameTime()-GameRules_GetPropFloat("m_flRoundStartTime"));
}

stock GetPlayerSquad(client, entity = -1, offset = -1)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
		return -1;
	if (offset == -1)
		offset = FindSendPropOffs("CINSPlayerResource", "m_iSquad");
	if (offset == -1)
		return -1;

	if (entity == -1)
		entity = FindEntityByClassname(MaxClients+1, "ins_player_manager");
	if (entity == -1)
		return -1;

	return GetEntData(entity, offset+(4*client));
}

stock GetPlayerSquadSlot(client, entity = -1, offset = -1)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
		return -1;
	if (offset == -1)
		offset = FindSendPropOffs("CINSPlayerResource", "m_iSquadSlot");
	if (offset == -1)
		return -1;

	if (entity == -1)
		entity = FindEntityByClassname(MaxClients+1, "ins_player_manager");
	if (entity == -1)
		return -1;

	return GetEntData(entity, offset+(4*client));
}

//https://forums.alliedmods.net/showpost.php?p=2424570&postcount=3
stock hexToRGB(int Hex, int RGBA[4], bool withAlpha = true)
{
	if (withAlpha/*Hex > 0xFFFFFF*/) // Hell No...
	{
		RGBA[0] = ((Hex >> 24) & 0xFF);
		RGBA[1] = ((Hex >> 16) & 0xFF);
		RGBA[2] = ((Hex >> 8) & 0xFF);
		RGBA[3] = ((Hex) & 0xFF);
	}
	else
	{
		RGBA[0] = ((Hex >> 16) & 0xFF);
		RGBA[1] = ((Hex >> 8) & 0xFF);
		RGBA[2] = ((Hex) & 0xFF);
	}
}

/* Available icons
	"icon_bulb"
	"icon_caution"
	"icon_alert"
	"icon_alert_red"
	"icon_tip"
	"icon_skull"
	"icon_no"
	"icon_run"
	"icon_interact"
	"icon_button"
	"icon_door"
	"icon_arrow_plain"
	"icon_arrow_plain_white_dn"
	"icon_arrow_plain_white_up"
	"icon_arrow_up"
	"icon_arrow_right"
	"icon_fire"
	"icon_present"
	"use_binding"
*/

// Range = 0.0 for all range 
stock void DisplayInstructorHint(int iTargetEntity, float fTime, float fHeight, float fRange, bool bFollow, bool bShowOffScreen, char[] sIconOnScreen, char[] sIconOffScreen, char[] sCmd, bool bShowTextAlways, int iColor[3], char[] sText)
{
	int iEntity = CreateEntityByName("env_instructor_hint");
	if(iEntity <= 0)
		return;
		
	char sBuffer[32];
	FormatEx(sBuffer, sizeof(sBuffer), "%d", iTargetEntity);
	
	// Target
	DispatchKeyValue(iTargetEntity, "targetname", sBuffer);
	DispatchKeyValue(iEntity, "hint_target", sBuffer);
	
	// Static
	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bFollow);
	DispatchKeyValue(iEntity, "hint_static", sBuffer);
	
	// Timeout
	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fTime));
	DispatchKeyValue(iEntity, "hint_timeout", sBuffer);
	
	// Height
	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fHeight));
	DispatchKeyValue(iEntity, "hint_icon_offset", sBuffer);
	
	// Range
	FormatEx(sBuffer, sizeof(sBuffer), "%d", RoundToFloor(fRange));
	DispatchKeyValue(iEntity, "hint_range", sBuffer);
	
	// Show off screen
	FormatEx(sBuffer, sizeof(sBuffer), "%d", !bShowOffScreen);
	DispatchKeyValue(iEntity, "hint_nooffscreen", sBuffer);
	
	// Icons
	DispatchKeyValue(iEntity, "hint_icon_onscreen", sIconOnScreen);
	DispatchKeyValue(iEntity, "hint_icon_offscreen", sIconOffScreen);
	
	// Command binding
	DispatchKeyValue(iEntity, "hint_binding", sCmd);
	
	// Show text behind walls
	FormatEx(sBuffer, sizeof(sBuffer), "%d", bShowTextAlways);
	DispatchKeyValue(iEntity, "hint_forcecaption", sBuffer);
	
	// Text color
	FormatEx(sBuffer, sizeof(sBuffer), "%d %d %d", iColor[0], iColor[1], iColor[2]);
	DispatchKeyValue(iEntity, "hint_color", sBuffer);
	
	//Text
	ReplaceString(sText, 254, "\n", " ");
	Format(sText, 254, "%s", sText);
	DispatchKeyValue(iEntity, "hint_caption", sText);

	if (fTime > 0.0)
	{
		Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:kill::%f:1", fTime);
		SetVariantString(sBuffer);
		AcceptEntityInput(iEntity, "AddOutput");
		AcceptEntityInput(iEntity, "FireUser1");
	}
	
	DispatchSpawn(iEntity);
	AcceptEntityInput(iEntity, "ShowHint");
}








/*				COLORS							*/

#define		COLOR_INSURGENTS			"AC4029FF"
#define		COLOR_SECURITY				"84961CFF"
#define		COLOR_SPECTATOR				"F2EBD8FF"

#define		COLOR_ALICEBLUE				"F0F8FFFF"
#define		COLOR_ALLIES				"4D7942FF" // SAME AS ALLIES TEAM IN DOD:S
#define		COLOR_ANCIENT				"EB4B4BFF" // SAME AS ANCIENT ITEM RARITY IN DOTA 2
#define		COLOR_ANTIQUEWHITE			"FAEBD7FF"
#define		COLOR_AQUA					"00FFFFFF"
#define		COLOR_AQUAMARINE			"7FFFD4FF"
#define		COLOR_ARCANA				"ADE55CFF" // SAME AS ARCANA ITEM RARITY IN DOTA 2
#define		COLOR_AXIS					"FF4040FF" // SAME AS AXIS TEAM IN DOD:S
#define		COLOR_AZURE					"007FFFFF"
#define		COLOR_BEIGE					"F5F5DCFF"
#define		COLOR_BISQUE				"FFE4C4FF"
#define		COLOR_BLACK					"000000FF"
#define		COLOR_BLANCHEDALMOND		"FFEBCDFF"
#define		COLOR_BLUE					"99CCFFFF" // SAME AS BLU/COUNTER-TERRORIST TEAM COLOR
#define		COLOR_BLUEVIOLET			"8A2BE2FF"
#define		COLOR_BROWN					"A52A2AFF"
#define		COLOR_BURLYWOOD				"DEB887FF"
#define		COLOR_CADETBLUE				"5F9EA0FF"
#define		COLOR_CHARTREUSE			"7FFF00FF"
#define		COLOR_CHOCOLATE				"D2691EFF"
#define		COLOR_COLLECTORS			"AA0000FF" // SAME AS COLLECTOR'S ITEM QUALITY IN TF2
#define		COLOR_COMMON				"B0C3D9FF" // SAME AS COMMON ITEM RARITY IN DOTA 2
#define		COLOR_COMMUNITY				"70B04AFF" // SAME AS COMMUNITY ITEM QUALITY IN TF2
#define		COLOR_CORAL					"FF7F50FF"
#define		COLOR_CORNFLOWERBLUE		"6495EDFF"
#define		COLOR_CORNSILK				"FFF8DCFF"
#define		COLOR_CORRUPTED				"A32C2EFF" // SAME AS CORRUPTED ITEM QUALITY IN DOTA 2
#define		COLOR_CRIMSON				"DC143CFF"
#define		COLOR_CYAN					"00FFFFFF"
#define		COLOR_DARKBLUE				"00008BFF"
#define		COLOR_DARKCYAN				"008B8BFF"
#define		COLOR_DARKGOLDENROD			"B8860BFF"
#define		COLOR_DARKGRAY				"A9A9A9FF"
#define		COLOR_DARKGREY				"A9A9A9FF"
#define		COLOR_DARKGREEN				"006400FF"
#define		COLOR_DARKKHAKI				"BDB76BFF"
#define		COLOR_DARKMAGENTA			"8B008BFF"
#define		COLOR_DARKOLIVEGREEN		"556B2FFF"
#define		COLOR_DARKORANGE			"FF8C00FF"
#define		COLOR_DARKORCHID			"9932CCFF"
#define		COLOR_DARKRED				"8B0000FF"
#define		COLOR_DARKSALMON			"E9967AFF"
#define		COLOR_DARKSEAGREEN			"8FBC8FFF"
#define		COLOR_DARKSLATEBLUE			"483D8BFF"
#define		COLOR_DARKSLATEGRAY			"2F4F4FFF"
#define		COLOR_DARKSLATEGREY			"2F4F4FFF"
#define		COLOR_DARKTURQUOISE			"00CED1FF"
#define		COLOR_DARKVIOLET			"9400D3FF"
#define		COLOR_DEEPPINK				"FF1493FF"
#define		COLOR_DEEPSKYBLUE			"00BFFFFF"
#define		COLOR_DIMGRAY				"696969FF"
#define		COLOR_DIMGREY				"696969FF"
#define		COLOR_DODGERBLUE			"1E90FFFF"
#define		COLOR_EXALTED				"CCCCCDFF" // SAME AS EXALTED ITEM QUALITY IN DOTA 2
#define		COLOR_FIREBRICK				"B22222FF"
#define		COLOR_FLORALWHITE			"FFFAF0FF"
#define		COLOR_FORESTGREEN			"228B22FF"
#define		COLOR_FROZEN				"4983B3FF" // SAME AS FROZEN ITEM QUALITY IN DOTA 2
#define		COLOR_FUCHSIA				"FF00FFFF"
#define		COLOR_FULLBLUE				"0000FFFF"
#define		COLOR_FULLRED				"FF0000FF"
#define		COLOR_GAINSBORO				"DCDCDCFF"
#define		COLOR_GENUINE				"4D7455FF" // SAME AS GENUINE ITEM QUALITY IN TF2
#define		COLOR_GHOSTWHITE			"F8F8FFFF"
#define		COLOR_GOLD					"FFD700FF"
#define		COLOR_GOLDENROD				"DAA520FF"
#define		COLOR_GRAY					"CCCCCCFF" // SAME AS SPECTATOR TEAM COLOR
#define		COLOR_GREY					"CCCCCCFF"
#define		COLOR_GREEN					"3EFF3EFF"
#define		COLOR_GREENYELLOW			"ADFF2FFF"
#define		COLOR_HAUNTED				"38F3ABFF" // SAME AS HAUNTED ITEM QUALITY IN TF2
#define		COLOR_HONEYDEW				"F0FFF0FF"
#define		COLOR_HOTPINK				"FF69B4FF"
#define		COLOR_IMMORTAL				"E4AE33FF" // SAME AS IMMORTAL ITEM RARITY IN DOTA 2
#define		COLOR_INDIANRED				"CD5C5CFF"
#define		COLOR_INDIGO				"4B0082FF"
#define		COLOR_IVORY					"FFFFF0FF"
#define		COLOR_KHAKI					"F0E68CFF"
#define		COLOR_LAVENDER				"E6E6FAFF"
#define		COLOR_LAVENDERBLUSH			"FFF0F5FF"
#define		COLOR_LAWNGREEN				"7CFC00FF"
#define		COLOR_LEGENDARY				"D32CE6FF" // SAME AS LEGENDARY ITEM RARITY IN DOTA 2
#define		COLOR_LEMONCHIFFON			"FFFACDFF"
#define		COLOR_LIGHTBLUE				"ADD8E6FF"
#define		COLOR_LIGHTCORAL			"F08080FF"
#define		COLOR_LIGHTCYAN				"E0FFFFFF"
#define		COLOR_LIGHTGOLDENRODYELLOW	"FAFAD2FF"
#define		COLOR_LIGHTGRAY				"D3D3D3FF"
#define		COLOR_LIGHTGREY				"D3D3D3FF"
#define		COLOR_LIGHTGREEN			"99FF99FF"
#define		COLOR_LIGHTPINK				"FFB6C1FF"
#define		COLOR_LIGHTSALMON			"FFA07AFF"
#define		COLOR_LIGHTSEAGREEN			"20B2AAFF"
#define		COLOR_LIGHTSKYBLUE			"87CEFAFF"
#define		COLOR_LIGHTSLATEGRAY		"778899FF"
#define		COLOR_LIGHTSLATEGREY		"778899FF"
#define		COLOR_LIGHTSTEELBLUE		"B0C4DEFF"
#define		COLOR_LIGHTYELLOW			"FFFFE0FF"
#define		COLOR_LIME					"00FF00FF"
#define		COLOR_LIMEGREEN				"32CD32FF"
#define		COLOR_LINEN					"FAF0E6FF"
#define		COLOR_MAGENTA				"FF00FFFF"
#define		COLOR_MAROON				"800000FF"
#define		COLOR_MEDIUMAQUAMARINE		"66CDAAFF"
#define		COLOR_MEDIUMBLUE			"0000CDFF"
#define		COLOR_MEDIUMORCHID			"BA55D3FF"
#define		COLOR_MEDIUMPURPLE			"9370D8FF"
#define		COLOR_MEDIUMSEAGREEN		"3CB371FF"
#define		COLOR_MEDIUMSLATEBLUE		"7B68EEFF"
#define		COLOR_MEDIUMSPRINGGREEN		"00FA9AFF"
#define		COLOR_MEDIUMTURQUOISE		"48D1CCFF"
#define		COLOR_MEDIUMVIOLETRED		"C71585FF"
#define		COLOR_MIDNIGHTBLUE			"191970FF"
#define		COLOR_MINTCREAM				"F5FFFAFF"
#define		COLOR_MISTYROSE				"FFE4E1FF"
#define		COLOR_MOCCASIN				"FFE4B5FF"
#define		COLOR_MYTHICAL				"8847FFFF" // SAME AS MYTHICAL ITEM RARITY IN DOTA 2
#define		COLOR_NAVAJOWHITE			"FFDEADFF"
#define		COLOR_NAVY					"000080FF"
#define		COLOR_NORMAL				"B2B2B2FF" // SAME AS NORMAL ITEM QUALITY IN TF2
#define		COLOR_OLDLACE				"FDF5E6FF"
#define		COLOR_OLIVE					"9EC34FFF"
#define		COLOR_OLIVEDRAB				"6B8E23FF"
#define		COLOR_ORANGE				"FFA500FF"
#define		COLOR_ORANGERED				"FF4500FF"
#define		COLOR_ORCHID				"DA70D6FF"
#define		COLOR_PALEGOLDENROD			"EEE8AAFF"
#define		COLOR_PALEGREEN				"98FB98FF"
#define		COLOR_PALETURQUOISE			"AFEEEEFF"
#define		COLOR_PALEVIOLETRED			"D87093FF"
#define		COLOR_PAPAYAWHIP			"FFEFD5FF"
#define		COLOR_PEACHPUFF				"FFDAB9FF"
#define		COLOR_PERU					"CD853FFF"
#define		COLOR_PINK					"FFC0CBFF"
#define		COLOR_PLUM					"DDA0DDFF"
#define		COLOR_POWDERBLUE			"B0E0E6FF"
#define		COLOR_PURPLE				"800080FF"
#define		COLOR_RARE					"4B69FFFF" // SAME AS RARE ITEM RARITY IN DOTA 2
#define		COLOR_RED					"FF4040FF" // SAME AS RED/TERRORIST TEAM COLOR
#define		COLOR_ROSYBROWN				"BC8F8FFF"
#define		COLOR_ROYALBLUE				"4169E1FF"
#define		COLOR_SADDLEBROWN			"8B4513FF"
#define		COLOR_SALMON				"FA8072FF"
#define		COLOR_SANDYBROWN			"F4A460FF"
#define		COLOR_SEAGREEN				"2E8B57FF"
#define		COLOR_SEASHELL				"FFF5EEFF"
#define		COLOR_SELFMADE				"70B04AFF" // SAME AS SELF-MADE ITEM QUALITY IN TF2
#define		COLOR_SIENNA				"A0522DFF"
#define		COLOR_SILVER				"C0C0C0FF"
#define		COLOR_SKYBLUE				"87CEEBFF"
#define		COLOR_SLATEBLUE				"6A5ACDFF"
#define		COLOR_SLATEGRAY				"708090FF"
#define		COLOR_SLATEGREY				"708090FF"
#define		COLOR_SNOW					"FFFAFAFF"
#define		COLOR_SPRINGGREEN			"00FF7FFF"
#define		COLOR_STEELBLUE				"4682B4FF"
#define		COLOR_STRANGE				"CF6A32FF" // SAME AS STRANGE ITEM QUALITY IN TF2
#define		COLOR_TAN					"D2B48CFF"
#define		COLOR_TEAL					"008080FF"
#define		COLOR_THISTLE				"D8BFD8FF"
#define		COLOR_TOMATO				"FF6347FF"
#define		COLOR_TURQUOISE				"40E0D0FF"
#define		COLOR_UNCOMMON				"B0C3D9FF" // SAME AS UNCOMMON ITEM RARITY IN DOTA 2
#define		COLOR_UNIQUE				"FFD700FF" // SAME AS UNIQUE ITEM QUALITY IN TF2
#define		COLOR_UNUSUAL				"8650ACFF" // SAME AS UNUSUAL ITEM QUALITY IN TF2
#define		COLOR_VALVE					"A50F79FF" // SAME AS VALVE ITEM QUALITY IN TF2
#define		COLOR_VINTAGE				"476291FF" // SAME AS VINTAGE ITEM QUALITY IN TF2
#define		COLOR_VIOLET				"EE82EEFF"
#define		COLOR_WHEAT					"F5DEB3FF"
#define		COLOR_WHITE					"FFFFFFFF"
#define		COLOR_WHITESMOKE			"F5F5F5FF"
#define		COLOR_YELLOW				"FFFF00FF"
#define		COLOR_YELLOWGREEN			"9ACD32FF"