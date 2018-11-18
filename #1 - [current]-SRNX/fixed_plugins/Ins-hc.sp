#pragma semicolon 1

#define _Insurgency_

#include <NewPage>

#include <sdkhooks>
#include <sdktools>

#define GEAR_UAV 1
#define MAXPLAYERS_INS 49

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

int g_iUAVCount = 0;
int g_iOffsetGears = -1;
bool g_bUAVOnline = false;
ConVar g_hCvarUAVCounts;
ConVar g_hCvarUAVCooldown;
ConVar g_hCvarUAVTime;
Handle g_hUAVTimer;
float g_fUAVCDTime[MAXPLAYERS_INS+1] = 0.0;
float g_fPlayerWeaponBlocked[MAXPLAYERS_INS+1] = {0.0, ...};

int g_iWeaponListNum;
int g_iOffsetMyWeapons = -1;
float g_iWeaponCooldown[MAXPLAYERS_INS+1];
ConVar g_hCvarWeaponCD;
ConVar g_hCvarWeaponList;
char g_cWeaponList[32][32];

public Plugin myinfo = 
{
	name        = "Ins Hardcore",
	author      = "Gunslinger",
	description = "",
	version     = "1.0",
	url         = "https://new-page.xyz"
};

public void OnPluginStart()
{
	g_hCvarWeaponCD = CreateConVar("sm_blockweapon_cd", "90.0", "Weapon cd time", _, true, 1.0);
	g_hCvarWeaponList = CreateConVar("sm_blockweapon_list", "weapon_anm14,weapon_rpg7,weapon_at4,weapon_law,weapon_m203_incendiary,weapon_gp25_incendiary,weapon_m320_incendiary,weapon_m79_incen,weapon_molotov", "Weapon list");
	g_hCvarUAVCounts = CreateConVar("UAV_Counts", "7", "Scan counts of UAV", _, true, 1.0);
	g_hCvarUAVCooldown = CreateConVar("UAV_Cooldown", "180", "Cooldown time of UAV (second)", _, true, 0.0);
	g_hCvarUAVTime = CreateConVar("UAV_Time", "2.0", "Glowing time of every scan (second)", _, true, 1.0);

	HookEvent("grenade_detonate", Event_GrenadeDetonate, EventHookMode_Post);
	HookEvent("weapon_deploy", Event_WeaponDeploy, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_activate", Event_PlayerActivate);
	HookEvent("weapon_fire", Event_WeaponFire);

	g_iOffsetGears = FindSendPropInfo("CINSPlayer", "m_iMyGear");
	if (g_iOffsetGears == -1)
		LogError("Offset Error: Unable to find Offset for \"m_iMyGear\"");
	
	g_iOffsetMyWeapons = FindSendPropInfo("CINSPlayer", "m_hMyWeapons");
	if (g_iOffsetMyWeapons == -1)
		LogError("Offset Error: Unable to find Offset for \"m_hMyWeapons\"");
}

public void OnMapStart()
{
	PrecacheSound("Lua_sounds/uav_inbound.ogg");
	PrecacheSound("ui/sfx/ringing_04.wav");

	g_bUAVOnline = false;
}

public void OnConfigsExecuted()
{
	char weaponlist[512];
	g_hCvarWeaponList.GetString(weaponlist, 512);
	g_iWeaponListNum = ExplodeString(weaponlist, ",", g_cWeaponList, 32, 32);
}

public void OnClientConnected(int client)
{
	g_fUAVCDTime[client] = 0.0;
	g_iWeaponCooldown[client] = 0.0;
}

public Action Event_PlayerActivate(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsFakeClient(client))
		SDKHook(client, SDKHook_PreThinkPost, SHook_OnPreThink);
}

public void SHook_OnPreThink(client)
{
	if (!IsPlayerAlive(client)) return;

	int iFlags = GetEntProp(client, Prop_Send, "m_iPlayerFlags");
	bool bChanged = false;

	if (iFlags & ~INS_PL_BLOCKZONE && iFlags & INS_PL_LOWERZONE)
	{
		bChanged = true;
		iFlags &= ~INS_PL_LOWERZONE;
	}

	if (g_fPlayerWeaponBlocked[client] != 0.0)
	{
		bChanged = true;
		if (iFlags & ~INS_PL_LOWERZONE)
			iFlags |= INS_PL_LOWERZONE;
		if (g_fPlayerWeaponBlocked[client] > 0.0 && GetEngineTime() >= g_fPlayerWeaponBlocked[client])
		{
			if (iFlags & INS_PL_LOWERZONE)
				iFlags &= ~INS_PL_LOWERZONE;
			g_fPlayerWeaponBlocked[client] = 0.0;
		}
	}

	if (bChanged)
		SetEntProp(client, Prop_Send, "m_iPlayerFlags", iFlags);
	return;
}

public Action Event_GrenadeDetonate(Event event, const char[] name, bool dontBroadcast)
{
	int entity = GetEventInt(event, "entityid");

	if (entity > MaxClients)
	{
		char sGrenadeName[48];
		GetEntityClassname(entity, sGrenadeName, sizeof(sGrenadeName));

		int client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (StrEqual(sGrenadeName, "grenade_flare"))
		{
			SetEntityGravity(entity, 0.02);
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
			if (!IsFakeClient(client))
			{
				if (!g_bUAVOnline)
				{
					g_bUAVOnline = true;
					g_iUAVCount = GetConVarInt(g_hCvarUAVCounts)+1;
					CreateTimer(0.0, Timer_UAVOnline, client, TIMER_FLAG_NO_MAPCHANGE);
					g_hUAVTimer = CreateTimer(2.4, Timer_UAVOnline, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					if (IsPlayerAlive(client)) FakeClientCommand(client, "say 无人机已上线！");
					LogToGame("%N has called for UAV", client);
					PlayGameSoundToAll("Lua_sounds/uav_inbound.ogg");
					g_fUAVCDTime[client] = GetEngineTime() + g_hCvarUAVCooldown.FloatValue + g_hCvarUAVCounts.FloatValue * g_hCvarUAVTime.FloatValue;
				}
			}
		}
	}
}

public Action Timer_UAVOnline(Handle timer, any client)
{
	if (g_bUAVOnline && g_hUAVTimer != INVALID_HANDLE)
	{
		if (g_iUAVCount > 0)
		{
			g_iUAVCount--;
			for (int target = 1; target <= MaxClients; target++)
			{
				if (IsClientInGame(target) && GetClientTeam(target) == 3 && IsPlayerAlive(target))
				{
					SetEntProp(target, Prop_Send, "m_bGlowEnabled", 1);
					EmitSoundToAll("ui/sfx/ringing_04.wav", target, _, _, _, 1.0);
				}
			}
			CreateTimer(1.5, Timer_UAVOnline_GlowOff, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			for (int target = 1; target <= MaxClients; target++)
				if (IsClientInGame(target) && GetClientTeam(target) == 3 && IsPlayerAlive(target))
					SetEntProp(target, Prop_Send, "m_bGlowEnabled", 0);

			g_iUAVCount = 0;
			KillTimer(timer);
			g_hUAVTimer = INVALID_HANDLE;
			g_bUAVOnline = false;
			if (IsClientInGame(client) && IsPlayerAlive(client))
				FakeClientCommand(client, "say 无人机已下线！");
		}
	}
	else
	{
		for (int target = 1; target <= MaxClients; target++)
			if (IsClientInGame(target) && GetClientTeam(target) == 3 && IsPlayerAlive(target))
				SetEntProp(target, Prop_Send, "m_bGlowEnabled", 0);

		g_iUAVCount = 0;
		KillTimer(timer);
		g_hUAVTimer = INVALID_HANDLE;
		g_bUAVOnline = false;
		if (IsClientInGame(client) && IsPlayerAlive(client))
			FakeClientCommand(client, "say 无人机已下线！");
	}
}

public Action Timer_UAVOnline_GlowOff(Handle timer)
{
	for (int target = 1; target <= MaxClients; target++)
		if (IsClientInGame(target) && GetClientTeam(target) == 3 && IsPlayerAlive(target))
			SetEntProp(target, Prop_Send, "m_bGlowEnabled", 0);
}

// UAV CD未结算时，禁止玩家切出信号枪
public Action Event_WeaponDeploy(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int deployWeapon = GetEventInt(event, "weaponid");

	float enginetime = GetEngineTime();

	g_fPlayerWeaponBlocked[client] = 0.0;

	if (deployWeapon == 94)	// #Deployed weapon_p2a1 flaregun (94)
	{
		if (g_fUAVCDTime[client] != 0.0)
		{
			if (enginetime > g_fUAVCDTime[client] && !g_bUAVOnline)
				g_fUAVCDTime[client] = 0.0;
			else
			{
				int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if (iWeapon > MaxClients && IsValidEntity(iWeapon))
					ClientCommand(client, "invprev");
				else
					ClientCommand(client, "toggleprimarysecondary");

				g_fPlayerWeaponBlocked[client] = g_fUAVCDTime[client];

				if (g_fUAVCDTime[client] < 0)
					PrintToChat(client, "\x05无人机 \x01无法同时使用2台无人机");
				else
					PrintToChat(client, "\x05无人机 \x01在 \x08%s%0.1f 秒内冷却完毕", "FA8072FF", g_fUAVCDTime[client] - enginetime);
			}
		}
	}
	else if (IsBlockWeapon(client))
	{
		if (g_iWeaponCooldown[client] != 0.0)
		{
			if (enginetime > g_iWeaponCooldown[client])
				g_iWeaponCooldown[client] = 0.0;
			else
			{
				int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if (iWeapon > MaxClients && IsValidEntity(iWeapon))
					ClientCommand(client, "invprev");
				else
					ClientCommand(client, "toggleprimarysecondary");

				g_fPlayerWeaponBlocked[client] = g_iWeaponCooldown[client];

				PrintToChat(client, "\x01该武器在 \x08%s%0.1f \x01秒内冷却完毕才可使用", "FA8072FF", g_iWeaponCooldown[client] - enginetime);
			}
		}
	}
}

void PlayGameSoundToAll(const char[] sample)
{
	for (int j = 1;j < MaxClients; j++)
		if (IsClientInGame(j))
			ClientCommand(j, "playgamesound %s", sample);
}

public void NP_Ins_OnPlayerResupplyed(int client)
{
	if (!IsPlayerAlive(client) || g_iOffsetGears == -1)
		return;
		
	for (int i = 0;i < 7;i++)
	{
		if (GetEntData(client, g_iOffsetGears+(4*i)) == GEAR_UAV)
		{
			int iWeapon = GivePlayerItem(client, "weapon_p2a1");
			if (iWeapon > MaxClients && IsValidEdict(iWeapon))
				LogToGame("%N has given p2a1 flaregun (%d)", client, iWeapon);
		}
	}
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_fUAVCDTime[i] = 0.0;
		g_iWeaponCooldown[i] = 0.0;
	}
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsValidClient(client))
		return Plugin_Continue;

	if (IsBlockWeapon(client))
	{
		g_iWeaponCooldown[client] = g_hCvarWeaponCD.FloatValue + GetEngineTime();
		g_fPlayerWeaponBlocked[client] = g_iWeaponCooldown[client];
	}

	return Plugin_Continue;
}

bool IsBlockWeapon(int client)
{
	char weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));

	for (int i = 0; i < g_iWeaponListNum; i++)
	{
		if (StrContains(g_cWeaponList[i], weaponname) > -1)
			return true;
	}

	return false;
}