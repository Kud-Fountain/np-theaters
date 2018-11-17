#pragma semicolon 1

#include <sdkhooks>
#include <sdktools>

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

int g_iWeaponListNum;
int g_iOffsetMyWeapons = -1;
float g_fPlayerWeaponBlocked[MAXPLAYERS_INS+1] = {0.0, ...};
float g_iWeaponCooldown[MAXPLAYERS_INS+1];
ConVar g_hCvarWeaponCD;
ConVar g_hCvarWeaponList;
char g_cWeaponList[32][32];

public Plugin myinfo = 
{
	name        = "Ins Weapon Blocker",
	author      = "Gunslinger",
	description = "Add Cooldown time for Weapon",
	version     = "1.0",
	url         = "https://new-page.xyz"
};

public void OnPluginStart()
{
	g_hCvarWeaponCD = CreateConVar("sm_blockweapon_cd", "70.0", "Weapon cd time", _, true, 1.0);
	g_hCvarWeaponList = CreateConVar("sm_blockweapon_list", "weapon_anm14,weapon_rpg7,weapon_at4,weapon_law,weapon_m203_incendiary,weapon_gp25_incendiary,weapon_m320_incendiary,weapon_m79_incen,weapon_molotov", "Weapon list");

	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("weapon_deploy", Event_WeaponDeploy, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_activate", Event_PlayerActivate);

	g_iOffsetMyWeapons = FindSendPropInfo("CINSPlayer", "m_hMyWeapons");
	if (g_iOffsetMyWeapons == -1)
		LogError("Offset Error: Unable to find Offset for \"m_hMyWeapons\"");
}

public void OnConfigsExecuted()
{
	char weaponlist[512];
	g_hCvarWeaponList.GetString(weaponlist, 512);
	g_iWeaponListNum = ExplodeString(weaponlist, ",", g_cWeaponList, 32, 32);
}

public void OnClientConnected(int client)
{
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

//CD未结算时，禁止玩家切出信号枪
public Action Event_WeaponDeploy(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsValidClient(client))
		return Plugin_Continue;

	float enginetime = GetEngineTime();

	g_fPlayerWeaponBlocked[client] = 0.0;

	if (IsBlockWeapon(client))
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

	return Plugin_Continue;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		g_iWeaponCooldown[i] = 0.0;
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

bool IsValidClient(int index)
{
	return (index > 0 && index <= MaxClients && IsClientInGame(index) && !IsFakeClient(index) && !IsClientSourceTV(index));
}