#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define MAXPLAYERS_INS 49

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

#define WEAPON_KNIFE 32
#define GEAR_AMMOCRATE 2

enum Collision_Group_t
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,				// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER,		// Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEB,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,		// Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,	// For HL2, same as Collision_Group_Player, for
										// TF2, this filters out other players and CBaseObjects
	COLLISION_GROUP_NPC,				// Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,			// for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,				// for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,		// vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,			// Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,		// Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,		// Doors that the player shouldn't collide with
	COLLISION_GROUP_DISSOLVING,			// Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,			// Nonsolid on client and server, pushaway in player code

	COLLISION_GROUP_NPC_ACTOR,			// Used so NPCs in scripts ignore the player.
	COLLISION_GROUP_NPC_SCRIPTED		// USed for NPCs in scripts that should not collide with each other
};

int g_iPlayerCustomGear[MAXPLAYERS_INS+1] = {-1, ...};
int g_iPlayerDeployedWeapon[MAXPLAYERS+1];
int g_iPlayerTempProp[MAXPLAYERS_INS+1] = {-1, ...};
int g_iGearAmmoCrateModel[2] = {-1, ...};
int g_iOffsetGears = -1;
int g_iOffsetMyWeapons = -1;
int g_iPLFBuyzone[MAXPLAYERS_INS+1] = {INVALID_ENT_REFERENCE, ...};	//	INVALID_ENT_REFERENCE = off, entity ref = always in buyzone, otherwise disable buyzone and spawnzone flags
int g_iPlayerLastKnife[MAXPLAYERS_INS+1] = {-1, ...};
float g_fPlayerTempPropCooldown[MAXPLAYERS_INS+1] = {0.0, ...};
float g_fPlayerLastChat[MAXPLAYERS+1];
float g_fPlayerTempPropTimestamp[MAXPLAYERS_INS+1] = {0.0, ...};
float g_vPlayerTempPropOrigin[MAXPLAYERS_INS+1][3];
float g_fGameTime = 9999999999.0;
bool g_bPlayerTempPropSetup[MAXPLAYERS_INS+1] = {false, ...};
ConVar g_ConVarSupplyTimes;
ConVar g_ConVarDuration;
ConVar g_ConVarDeployTime;


public Plugin myinfo = 
{
	name        = "Ins Ammo Crate",
	author      = "Gunslinger",
	description = "Allow player to deploy the ammo crate to resupply",
	version     = "1.0",
	url         = "https://new-page.xyz"
};

public void OnPluginStart()
{
	g_ConVarSupplyTimes = CreateConVar("AmmoCrate_SupplyTimes", "2", "Ammo crate supply times", _, true, 1.0);
	g_ConVarDuration = CreateConVar("AmmoCrate_Duration", "180", "Life time of ammo crate", _, true, 1.0);
	g_ConVarDeployTime = CreateConVar("AmmoCrate_DeployTime", "10.0", "Ammo crate deployment time(second)", _, true, 1.0);

	HookEvent("player_activate", Event_PlayerActivate);
	HookEvent("weapon_deploy", Event_WeaponDeploy, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);

	g_iOffsetGears = FindSendPropInfo("CINSPlayer", "m_iMyGear");
	if (g_iOffsetGears == -1)
		LogError("Offset Error: Unable to find Offset for \"m_iMyGear\"");

	g_iOffsetMyWeapons = FindSendPropInfo("CINSPlayer", "m_hMyWeapons");
	if (g_iOffsetMyWeapons == -1)
		LogError("Offset Error: Unable to find Offset for \"m_hMyWeapons\"");
}

public void OnMapStart()
{
	g_iGearAmmoCrateModel[0] = PrecacheModel("models/generic/ammocrate3.mdl");
	g_iGearAmmoCrateModel[1] = PrecacheModel("models/generic/ammocrate1.mdl");

	CreateTimer(0.1, ThinkTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action Event_PlayerActivate(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_iPLFBuyzone[client] = INVALID_ENT_REFERENCE;

	if (!IsFakeClient(client))
		SDKHook(client, SDKHook_PreThinkPost, SHook_OnPreThink);
}

public void SHook_OnPreThink(client)
{
	if (!IsPlayerAlive(client)) return;

	int iFlags = GetEntProp(client, Prop_Send, "m_iPlayerFlags");
	bool bChanged = false;

	if (g_iPLFBuyzone[client] != INVALID_ENT_REFERENCE)
	{
		if (iFlags & INS_PL_SPAWNZONE)
		{
			g_iPLFBuyzone[client] = INVALID_ENT_REFERENCE;
		}
		else if (IsValidEdict(g_iPLFBuyzone[client]))
		{
			int iStock = RoundToNearest(GetEntPropFloat(g_iPLFBuyzone[client], Prop_Data, "m_flLocalTime"));
			if (iStock > 0)
			{
				if (iFlags & ~INS_PL_BUYZONE)
				{
					bChanged = true;
					iFlags |= INS_PL_BUYZONE;
				}
			}
			else
			{
				g_iPLFBuyzone[client] = INVALID_ENT_REFERENCE;
			}
		}
		else
		{
			g_iPLFBuyzone[client] = INVALID_ENT_REFERENCE;
		}
	}

	int iAimTarget = GetClientAimTarget(client, false);
	if (iAimTarget > MaxClients)
	{
		if (FindDataMapInfo(iAimTarget, "m_ModelName") != -1)
		{
			char sClassName[64];
			GetEntPropString(iAimTarget, Prop_Data, "m_iName", sClassName, sizeof(sClassName));
			if (StrEqual(sClassName, "LuaCustomModel", true))
			{
				char sModelPath[128];
				GetEntPropString(iAimTarget, Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
				if (StrContains(sModelPath, "ammocrate3.mdl", true) != -1)
				{
					if (g_iPLFBuyzone[client] != INVALID_ENT_REFERENCE && g_iPLFBuyzone[client] == EntIndexToEntRef(iAimTarget))
					{
						PrintCenterText(client, "按 \"装备配置键 (M)\" 来重新补给\n \n弹药补给剩余量:  [%d / %d]", RoundToNearest(GetEntPropFloat(iAimTarget, Prop_Data, "m_flLocalTime")), g_ConVarSupplyTimes.IntValue);
						if (GetClientButtons(client) & INS_USE && GetEngineTime()-g_fPlayerLastChat[client] >= 1.0)
						{
							FakeClientCommand(client, "inventory_resupply");
							g_fPlayerLastChat[client] = GetEngineTime();
						}
					}
				}
			}
		}
	}

	if (g_iPlayerDeployedWeapon[client] == WEAPON_KNIFE && g_iPlayerCustomGear[client] == 18)	// #Deployed WEAPON_KNIFE (30)
	{			
		int iButtons = GetClientButtons(client);
		if ((iButtons & INS_AIM || iButtons & INS_AIM_TOGGLE) && GetEntityFlags(client) & FL_ONGROUND)
		{
			if (g_fPlayerTempPropTimestamp[client] == 0.0 && g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]) && GetEntPropEnt(g_iPlayerTempProp[client], Prop_Data, "m_hOwnerEntity") != MaxClients+2)
			{
				char targetname[64];
				GetEntPropString(g_iPlayerTempProp[client], Prop_Data, "m_iName", targetname, sizeof(targetname));
				if (StrEqual(targetname, "LuaCustomModel", true))
				{
					LogToGame("%N is installing new gear id %d therefore remove old one %d", client, g_iPlayerCustomGear[client], g_iPlayerTempProp[client]);
					char sModelPath[128];
					GetEntPropString(g_iPlayerTempProp[client], Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
					if (StrContains(sModelPath, "ammocrate", true) != -1)
						PrintToChatAll("\x04弹药箱 \x01并已被 \x08%s%N进行了替换", "AC4029FF", client);
					RequestFrame(DeleteEntity, EntIndexToEntRef(g_iPlayerTempProp[client]));
				}
				g_iPlayerTempProp[client] = -1;
			}

			if (g_iPlayerTempProp[client] == -1 || !IsValidEntity(g_iPlayerTempProp[client]))
			{
				g_bPlayerTempPropSetup[client] = false;
				g_iPlayerTempProp[client] = CreateEntityByName("prop_dynamic_override");
				SetEntPropEnt(g_iPlayerTempProp[client], Prop_Data, "m_hOwnerEntity", -1);
				if (g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]))
				{
					int iHealth = 1000;
					DispatchKeyValue(g_iPlayerTempProp[client], "model", "models/generic/ammocrate3.mdl");
					DispatchKeyValue(g_iPlayerTempProp[client], "physdamagescale", "0.0");
					DispatchKeyValue(g_iPlayerTempProp[client], "targetname", "LuaCustomModel");
					DispatchKeyValue(g_iPlayerTempProp[client], "Solid", "6");
					DispatchSpawn(g_iPlayerTempProp[client]);
					SetVariantInt(iHealth);
					AcceptEntityInput(g_iPlayerTempProp[client], "SetHealth");
					SetEntityRenderMode(g_iPlayerTempProp[client], RENDER_TRANSALPHA);
					SetEntityMoveType(g_iPlayerTempProp[client], MOVETYPE_VPHYSICS);
					SetEntProp(g_iPlayerTempProp[client], Prop_Data, "m_iMaxHealth", iHealth);
					g_fPlayerTempPropTimestamp[client] = GetEngineTime()+60.0;
				}
			}

			if (g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]))
			{
				g_fGameTime = GetEngineTime();
				if (!g_bPlayerTempPropSetup[client])
				{
					if (g_fPlayerTempPropCooldown[client] != 0.0)
					{
						if (g_fGameTime >= g_fPlayerTempPropCooldown[client])
							g_fPlayerTempPropCooldown[client] = 0.0;
					}

					if (g_fPlayerTempPropCooldown[client] == 0.0)
					{
						SetEntProp(g_iPlayerTempProp[client], Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
						float vAngle[3], vPos[3], fDistance;
						bool bFailed = false;
						GetClientEyeAngles(client, vAngle);
						GetClientEyePosition(client, vPos);
						float fAngle = vAngle[1];
						Handle hTrace = TR_TraceRayFilterEx(vPos, vAngle, MASK_SOLID, RayType_Infinite, Filter_Not_PlayersAndEntity, client);
						if (TR_DidHit(hTrace))
						{
							TR_GetEndPosition(g_vPlayerTempPropOrigin[client], hTrace);
							TR_GetPlaneNormal(hTrace, vAngle);
							GetVectorAngles(vAngle, vAngle);
							vAngle[0] += 90.0;
							if (vAngle[0] >= 340.0 && vAngle[0] <= 380.0) vAngle[1] = fAngle-270.0;
							else bFailed = true;
						}
						else
						{
							bFailed = true;
							g_vPlayerTempPropOrigin[client][0] = -9000.0;
						}
						CloseHandle(hTrace);

						fDistance = GetVectorDistance(g_vPlayerTempPropOrigin[client], vPos);
						if (!bFailed && fDistance <= 100.0)
						{
							float vMins[3], vMaxs[3];
							GetEntPropVector(g_iPlayerTempProp[client], Prop_Data, "m_vecMins", vMins);
							GetEntPropVector(g_iPlayerTempProp[client], Prop_Data, "m_vecMaxs", vMaxs);
							ScaleVector(vMins, 0.9);
							ScaleVector(vMaxs, 0.9);
							g_vPlayerTempPropOrigin[client][2] += 20.0;
							TR_TraceHullFilter(g_vPlayerTempPropOrigin[client], g_vPlayerTempPropOrigin[client], vMins, vMaxs, MASK_SOLID, TraceEntityFilterSolidIncludeClient, g_iPlayerTempProp[client]);
							g_vPlayerTempPropOrigin[client][2] -= 20.0;
							if (!TR_DidHit())
							{
								TeleportEntity(g_iPlayerTempProp[client], g_vPlayerTempPropOrigin[client], vAngle, NULL_VECTOR);
								g_bPlayerTempPropSetup[client] = true;
								SetEntityRenderColor(g_iPlayerTempProp[client], 255, 255, 255, 0);
								SetEntProp(g_iPlayerTempProp[client], Prop_Data, "m_CollisionGroup", COLLISION_GROUP_NONE);
								g_fPlayerTempPropTimestamp[client] = g_fGameTime + g_ConVarDeployTime.FloatValue;
								if (g_fGameTime-g_fPlayerLastChat[client] >= 3.0)
								{
									g_fPlayerLastChat[client] = g_fGameTime;
									FakeClientCommand(client, "say 正在布置弹药箱...");
								}
								LogToGame("%N is installing gear id %d", client, g_iPlayerCustomGear[client]);
							}
							else
							{
								if (vAngle[0] >= 340.0 && vAngle[0] <= 395.0)
								{
									PrintCenterText(client, "该位置无法放置，请选择其他位置");
									SetEntityRenderColor(g_iPlayerTempProp[client], 255, 100, 100, 200);
									TeleportEntity(g_iPlayerTempProp[client], g_vPlayerTempPropOrigin[client], vAngle, NULL_VECTOR);
								}
								else
								{
									PrintCenterText(client, "该位置无法放置，只能在平地布置");
									TeleportEntity(g_iPlayerTempProp[client], Float:{-4000.0, 0.0, -4000.0}, NULL_VECTOR, NULL_VECTOR);
								}
								g_fPlayerTempPropTimestamp[client] = g_fGameTime+60.0;
							}
						}
						else
						{
							g_fPlayerTempPropTimestamp[client] = g_fGameTime+60.0;
							g_bPlayerTempPropSetup[client] = false;
							if (fDistance <= 500.0)
							{
								if (vAngle[0] < 340.0 || vAngle[0] > 395.0)
								{
									PrintCenterText(client, "该位置无法放置，只能在平地布置");
									TeleportEntity(g_iPlayerTempProp[client], Float:{-4000.0, 0.0, -4000.0}, NULL_VECTOR, NULL_VECTOR);
								}
								else
								{
									PrintCenterText(client, "距离过远  (%0.1f 米)", fDistance*0.01905);
									SetEntityRenderColor(g_iPlayerTempProp[client], 255, 100, 100, 200);
									TeleportEntity(g_iPlayerTempProp[client], g_vPlayerTempPropOrigin[client], vAngle, NULL_VECTOR);
								}
							}
							else
							{
								TeleportEntity(g_iPlayerTempProp[client], Float:{-4000.0, 0.0, -4000.0}, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
				else
				{
					if (g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]))
					{
						float vPos[3], fDistance;
						bool bFailed = true;
						GetClientEyePosition(client, vPos);
						fDistance = GetVectorDistance(g_vPlayerTempPropOrigin[client], vPos);
						if (fDistance <= 100.0)
						{
							g_vPlayerTempPropOrigin[client][2] += 16.0;
							Handle hTrace = TR_TraceRayFilterEx(vPos, g_vPlayerTempPropOrigin[client], MASK_SOLID, RayType_EndPoint, Filter_Not_PlayersAndEntity, client);
							g_vPlayerTempPropOrigin[client][2] -= 16.0;
							if (!TR_DidHit(hTrace))
							{
								// Retrieve view and target eyes position
								float vAngle[3], vAngleVec[3], fVector[3], fDir[3];

								// Calculate view direction
								GetClientEyeAngles(client, vAngle);
								vAngle[0] = vAngle[2] = 0.0;
								GetAngleVectors(vAngle, vAngleVec, NULL_VECTOR, NULL_VECTOR);
										
								fVector[0] = g_vPlayerTempPropOrigin[client][0]-vPos[0];
								fVector[1] = g_vPlayerTempPropOrigin[client][1]-vPos[1];
								fVector[2] = 0.0;

								// Check dot product. If it's negative, that means the viewer is facing
								// backwards to the target.
								NormalizeVector(fVector, fDir);
								if (GetVectorDotProduct(vAngleVec, fDir) >= 0.5)
								{
									bFailed = false;
											
									float fRemainTime = g_fPlayerTempPropTimestamp[client]-g_fGameTime;
									if (fRemainTime > 0.0)
									{
										float fDirection[3];
										fDirection[0] = GetRandomFloat(-1.0, 1.0);
										fDirection[1] = GetRandomFloat(-1.0, 1.0);
										fDirection[2] = GetRandomFloat(-1.0, 1.0);
										g_vPlayerTempPropOrigin[client][2] += 12.0;
										TE_SetupSparks(g_vPlayerTempPropOrigin[client], fDirection, 1, 1);
										g_vPlayerTempPropOrigin[client][2] -= 12.0;
										TE_SendToAll();
										int iAlpha = 80+RoundToNearest(175*(8.0-fRemainTime)/10);
										if (iAlpha < 180) iAlpha = 180;
										PrintCenterText(client, "正在布置弹药箱...\n\n%0.1f s", fRemainTime);
										SetEntityRenderColor(g_iPlayerTempProp[client], 255, 255, 255, iAlpha);
									}
									else
									{
										LogToGame("%N is finished install gear id %d", client, g_iPlayerCustomGear[client]);
										PrintCenterText(client, " ");
										ClientCommand(client, "toggleprimarysecondary");
										g_fPlayerTempPropTimestamp[client] = 0.0;
										SetEntPropFloat(g_iPlayerTempProp[client], Prop_Data, "m_flLocalTime", g_ConVarSupplyTimes.FloatValue);
										FakeClientCommand(client, "say 弹药箱已布置！");
										SetVariantColor({255, 255, 102, 255});
										new Handle:hData;
										CreateDataTimer(0.1, Timer_GearAmmoCrate, hData, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
										WritePackCell(hData, EntIndexToEntRef(g_iPlayerTempProp[client]));
										WritePackFloat(hData, GetEngineTime());
										SetEntityRenderMode(g_iPlayerTempProp[client], RENDER_NORMAL);
										SetEntityRenderColor(g_iPlayerTempProp[client], 255, 255, 255, 255);
										AcceptEntityInput(g_iPlayerTempProp[client], "SetGlowColor");
										SetEntProp(g_iPlayerTempProp[client], Prop_Send, "m_bShouldGlow", true);
										SetEntPropFloat(g_iPlayerTempProp[client], Prop_Send, "m_flGlowMaxDist", 2000.0);
										SetEntProp(g_iPlayerTempProp[client], Prop_Data, "m_takedamage", 2);
										SDKHook(g_iPlayerTempProp[client], SDKHook_OnTakeDamage, SHook_OnTakeDamageGear);
										HookSingleEntityOutput(g_iPlayerTempProp[client], "OnHealthChanged", OnGearDamaged, false);
										g_iPlayerCustomGear[client] = 0;
									}
								}
								else PrintCenterText(client, "已取消布置");
							}
							else PrintCenterText(client, "已取消布置");
							CloseHandle(hTrace);
						}
						else PrintCenterText(client, "已取消布置, 距离过远 (%0.1f 米)", fDistance*0.01905);
						if (bFailed)
						{
							LogToGame("%N is failed installing gear id %d (%d)", client, g_iPlayerCustomGear[client], g_iPlayerTempProp[client]);
							RequestFrame(DeleteEntity, EntIndexToEntRef(g_iPlayerTempProp[client]));
							SetEntityRenderColor(g_iPlayerTempProp[client], 255, 255, 255, 0);
							g_bPlayerTempPropSetup[client] = false;
							g_fPlayerTempPropCooldown[client] = g_fGameTime+0.6;
						}
					}
					else
					{
						PrintCenterText(client, " ");
						SetEntityRenderColor(g_iPlayerTempProp[client], 255, 255, 255, 0);
						g_bPlayerTempPropSetup[client] = false;
						g_fPlayerTempPropCooldown[client] = g_fGameTime+0.6;
					}
				}
			}
		}
		else
		{
			if (g_fPlayerTempPropTimestamp[client] != 0.0 && g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]))
			{
				LogToGame("%N is cancelled installing gear id %d (%d)", client, g_iPlayerCustomGear[client], g_iPlayerTempProp[client]);
				RequestFrame(DeleteEntity, EntIndexToEntRef(g_iPlayerTempProp[client]));
				g_iPlayerTempProp[client] = -1;
				PrintCenterText(client, "已取消布置");
				g_fPlayerTempPropCooldown[client] = GetEngineTime()+0.6;
			}
			g_fPlayerTempPropTimestamp[client] = 0.0;
			g_bPlayerTempPropSetup[client] = false;
		}
	}

	if (bChanged)
		SetEntProp(client, Prop_Send, "m_iPlayerFlags", iFlags);
	return;
}

public Action Event_WeaponDeploy(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iPlayerDeployedWeapon[client] = GetEventInt(event, "weaponid");
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2)
		return Plugin_Continue;

	// #Resupply Check
	int iKnife = GetPlayerWeaponByName(client, "weapon_knife");
	if (iKnife <= MaxClients || !IsValidEdict(iKnife))
		iKnife = GivePlayerItem(client, "weapon_knife");
	if (iKnife > MaxClients && IsValidEdict(iKnife))
		g_iPlayerLastKnife[client] = EntIndexToEntRef(iKnife);

	INS_OnPlayerResupplyed(client);

	return Plugin_Continue;
}

public void DeleteEntity(any refentity)
{
	int entity = EntRefToEntIndex(refentity);
	if (entity > MaxClients && IsValidEntity(refentity))
	{
		LogToGame("Entity %d (%d) has been removed", entity, refentity);
		RemoveEdict(entity);
	}
}

public Action Timer_GearAmmoCrate(Handle timer, Handle data)
{
	ResetPack(data);
	int refentity = ReadPackCell(data);
	if (refentity != INVALID_ENT_REFERENCE && IsValidEntity(refentity))
	{
		int iStock = RoundToNearest(GetEntPropFloat(refentity, Prop_Data, "m_flLocalTime"));
		float fSpawnTime = g_fGameTime-ReadPackFloat(data);
		if (iStock > 0 && fSpawnTime <= g_ConVarDuration.FloatValue)
		{
			float vOrigin[3], fDistance = 9999.0, vTargetOrigin[3];
			GetEntPropVector(refentity, Prop_Data, "m_vecAbsOrigin", vOrigin);
			for (int i = 1;i < MaxClients;i++)
			{
				if (!IsClientInGame(i))
					continue;

				if (!IsPlayerAlive(i))
					continue;
					
				int client = i;
				GetClientAbsOrigin(client, vTargetOrigin);
				fDistance = GetVectorDistance(vOrigin, vTargetOrigin);
				if (fDistance <= 65.0)
				{
					if (GetEntProp(client, Prop_Send, "m_iPlayerFlags") & INS_PL_SPAWNZONE)
					{
						SetEntPropFloat(refentity, Prop_Data, "m_flLocalTime", 0.0);
						break;
					}
					g_iPLFBuyzone[client] = refentity;
				}
				else if (g_iPLFBuyzone[client] == refentity || !IsValidEdict(g_iPLFBuyzone[client]))
				{
					g_iPLFBuyzone[client] = INVALID_ENT_REFERENCE;
				}
			}
			return Plugin_Continue;
		}
		else
		{
			for (int i = 1;i <= MaxClients;i++)
			{
				if (g_iPLFBuyzone[i] == refentity)
					g_iPLFBuyzone[i] = INVALID_ENT_REFERENCE;
			}
			LogToGame("Ammo Crate %d is out of stock", refentity);
			PlayGameSoundToAll("ui/sfx/crate_01.wav");
			PrintToChatAll("\x04弹药箱 \x01已经没有库存了！");
			if (g_iGearAmmoCrateModel[1] != -1)
			{
				SetEntPropEnt(refentity, Prop_Data, "m_hOwnerEntity", MaxClients+2);
				SetEntityModel(refentity, "models/generic/ammocrate1.mdl");
				SetEntProp(refentity, Prop_Send, "m_bShouldGlow", false);
				SetVariantString("OnUser1 !self:kill::5.0:1");
				AcceptEntityInput(refentity, "AddOutput");
				AcceptEntityInput(refentity, "FireUser1");
			}
			else
			{
				LogToGame("Ammo Crate %d is out of stock but model is not precached", refentity);
				RequestFrame(DeleteEntity, refentity);
			}
		}
	}

	KillTimer(timer);
	return Plugin_Handled;
}

void PlayGameSoundToAll(const char[] sample)
{
	for (int j = 1;j < MaxClients; j++)
		if (IsClientInGame(j))
			ClientCommand(j, "playgamesound %s", sample);
}

public bool Filter_Not_PlayersAndEntity(int entity, int contentsMask, any client)
{
	if (entity > MaxClients && entity != g_iPlayerTempProp[client])
		return true;
	return false;
}

public bool TraceEntityFilterSolidIncludeClient(int entity, int contentsMask, any prop)
{
	return entity > 0 && entity != prop;
}

public Action SHook_OnTakeDamageGear(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (GetEntPropEnt(victim, Prop_Data, "m_hOwnerEntity") == MaxClients+2)
		return Plugin_Continue;
	int aTeam = (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) ? GetClientTeam(attacker) : -1);
	if (aTeam == 2)
	{
		if (damagetype == 268435456 && damage == 1000.0)
			return Plugin_Handled;
		if (damagetype & DMG_SLASH)
		{
			damage = float(GetEntProp(victim, Prop_Data, "m_iMaxHealth"))/5.0;
			if (damage < 200.0 || damage > 1000.0)
				damage = 200.0;
		}
		else damage /= 2.0;
		return Plugin_Changed;
	}
	if (damagetype & DMG_BURN)
	{
		damage *= 2.0;
		return Plugin_Changed;
	}
	else if (damagetype & DMG_BLAST)
	{
		damage *= 10.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void OnGearDamaged(const char[] output, int caller, int activator, float delay)
{
	if (GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity") == MaxClients+2)
		return;
	int iHp = GetEntProp(caller, Prop_Data, "m_iHealth");
	if (iHp <= 0)
	{
		char sModelPath[128];
		GetEntPropString(caller, Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
		for (int client = 1;client <= MaxClients;client++)
		{
			if (g_iPlayerTempProp[client] == caller)
			{
				g_iPlayerTempProp[client] = -1;
				break;
			}
		}
		if (StrContains(sModelPath, "ammocrate", true) != -1)
		{
			if (activator > 0 && activator <= MaxClients && IsClientInGame(activator))
			{
				PrintToChatAll("\x04弹药箱 \x01已被 \x08%s%N 摧毁", "AC4029FF", activator);
				LogToGame("弹药箱 %d 已被 %N 摧毁", caller, activator);
			}
			else
			{
				PrintToChatAll("\x04弹药箱 \x01已被摧毁");
				LogToGame("弹药箱 %d 已被 #%d 摧毁", caller, activator);
			}
			PlayGameSoundToAll("ui/sfx/crate_01.wav");
		}
		AcceptEntityInput(caller, "kill");
	}
	return;
}

public Action ThinkTimer(Handle timer)
{
	for (int i = 1;i < MaxClients;i++)
	{	
		if (!IsClientInGame(i))
			continue;

		if (!IsPlayerAlive(i))
			continue;

		int client = i;
		if (g_iPlayerLastKnife[client] != -1)
		{
			// #Resupply Check
			int iKnife = GetPlayerWeaponByName(client, "weapon_knife");
			if (iKnife > MaxClients && IsValidEdict(iKnife))
				iKnife = EntIndexToEntRef(iKnife);
			else
			{
				iKnife = GivePlayerItem(client, "weapon_knife");
				if (iKnife <= MaxClients || !IsValidEdict(iKnife))
					iKnife = -1;
				else iKnife = EntIndexToEntRef(iKnife);
			}
			if (iKnife != -1 && iKnife != g_iPlayerLastKnife[client])
			{
				g_iPlayerLastKnife[client] = iKnife;
				INS_OnPlayerResupplyed(client);
			}
		}
	}
}

void INS_OnPlayerResupplyed(int client)
{
	if (!IsPlayerAlive(client))
		return;
	
	g_iPlayerDeployedWeapon[client] = -1;
	g_iPlayerCustomGear[client] = -1;
	g_fPlayerTempPropTimestamp[client] = 0.0;
	g_bPlayerTempPropSetup[client] = false;

	if (g_iOffsetGears != -1)
	{
		for (int i = 0;i < 7;i++)
		{
			int gearId = GetEntData(client, g_iOffsetGears+(4*i));
			if (gearId == -1) continue;
			
			if (gearId == GEAR_AMMOCRATE)
			{
				PrintToChat(client, "\x08%s你拥有一个 \x01弹药箱\x08%s, 可使用小刀布置 (\x01鼠标右键\x08%s)", "FF8C00FF", "FF8C00FF", "FF8C00FF");
				g_iPlayerCustomGear[client] = 18;
			}
		}
	}
	else
	{
		LogToGame("Failed to run \"m_iMyGear\" on \"CheckPlayerGears\"");
		LogError("Failed to run \"m_iMyGear\" on \"CheckPlayerGears\"");
	}

	if (g_iPLFBuyzone[client] != INVALID_ENT_REFERENCE)
	{
		LogToGame("[AMMO CRATE] %N has been resupplyed (%d / %d)", client, g_iPLFBuyzone[client], EntRefToEntIndex(g_iPLFBuyzone[client]));
		PrintToChatAll("\x01玩家 \x08%s%N  使用了\x04弹药箱\x01并重新补给了", "AC4029FF", client);
		SetEntPropFloat(g_iPLFBuyzone[client], Prop_Data, "m_flLocalTime", GetEntPropFloat(g_iPLFBuyzone[client], Prop_Data, "m_flLocalTime")-1.0);
	}
}

int GetPlayerWeaponByName(int client, const char[]weaponname)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_iOffsetMyWeapons == -1)
		return -1;

	for (int i = 0;i < 48;i++)
	{
		int weapon = GetEntDataEnt2(client, g_iOffsetMyWeapons+(4*i));
		if (weapon == -1) break;

		if (!IsValidEntity(weapon) || weapon <= MaxClients)
			continue;

		char classname[64];
		GetEntityClassname(weapon, classname, sizeof(classname));
		if (StrEqual(classname, weaponname, false))
			return weapon;
	}
	return -1;
}