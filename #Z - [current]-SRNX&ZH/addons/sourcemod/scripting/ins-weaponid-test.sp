#include <sourcemod>

int g_iOffsetGears = -1;

public void OnPluginStart()
{
	RegConsoleCmd("sm_gears", GearsCallback, "", 0);
	HookEvent("weapon_deploy", EventWeaponDeploy, EventHookMode_Post);

	g_iOffsetGears = FindSendPropInfo("CINSPlayer", "m_iMyGear");
	if (g_iOffsetGears == -1)
		LogError("Offset Error: Unable to find Offset for \"m_iMyGear\"");
}

public Action GearsCallback(int client, int args)
{
	if (!client) return;

	if (g_iOffsetGears != -1)
	{
		for (int i = 0;i < 7;i++)
		{
			int gearId = GetEntData(client, g_iOffsetGears+(4*i));
			if (gearId == -1) continue;
			
			PrintToChat(client, "[TEST] GearsID[%d]: %d", i, gearId);
		}
	}
	return;
}

public Action EventWeaponDeploy(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int deployWeapon = GetEventInt(event, "weaponid");

	PrintToChat(client, "[TEST] Deploy weaponID: %d", deployWeapon);
}