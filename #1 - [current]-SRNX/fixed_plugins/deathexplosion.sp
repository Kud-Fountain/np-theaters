#include <sdktools>

#pragma semicolon 1

#define SOUND_BOOM1 "weapons/ied/ied_detonate_02.wav"

ConVar  g_cvarExplodeRadius,
		g_cvarExplodePlayer;

public Plugin:myinfo = 
{
	name = "Death Explode",
	author = "Gunslinger",
	description = "Explode when player dead.",
	version = "1.0",
	url = ""
};

public void OnPluginStart() {
	g_cvarExplodeRadius = CreateConVar("sm_explode_radius", "1145", "Sets who explosions radius");
	g_cvarExplodePlayer = CreateConVar("sm_explode_player", "", "Set player who death will explode");
	AutoExecConfig(false);

	HookEvent("player_death", DeathCallback);
}

public void OnMapStart() {
	PrecacheSound(SOUND_BOOM1, true);
}

public Action DeathCallback(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(!client)
		return Plugin_Handled;

	if(!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	char steamid[32], target[32];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	g_cvarExplodePlayer.GetString(target, sizeof(target));

	if(!strcmp(steamid, target))
		PerformExplode(client);

	return Plugin_Handled;
}

void PerformExplode(int client) {
	int radius = GetConVarInt(g_cvarExplodeRadius);

	float location[3];
	GetClientAbsOrigin(client, location);

	EmitAmbientSound(SOUND_BOOM1, location, client, SNDLEVEL_RAIDSIREN);
 
	int particle = CreateEntityByName("info_particle_system");

	char name[64];
	TeleportEntity(particle, location, NULL_VECTOR, NULL_VECTOR);
	GetEntPropString(client, Prop_Data, "m_iName", name, sizeof(name));
	DispatchKeyValue(particle, "targetname", "insparticle");
	DispatchKeyValue(particle, "parentname", name);
	DispatchKeyValue(particle, "effect_name", "ins_car_explosion");
	DispatchSpawn(particle);
	SetVariantString(name);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CreateTimer(5.0, DeleteParticle, particle);

	HurtOtherPlayers(client, radius, true);
}

void HurtOtherPlayers(int target, int radius, bool teamonly) {
	int maxClients = GetMaxClients();
	float vec[3];
	GetClientAbsOrigin(target, vec);
	for (int i = 1; i < maxClients; ++i) {
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || target == i
				|| (teamonly && GetClientTeam(i) != GetClientTeam(target)))
			continue;
		
		float pos[3];
		GetClientEyePosition(i, pos);
		float distance = GetVectorDistance(vec, pos);
		if (distance > radius)
			continue;

		int damage = 250;
		damage = RoundToFloor(damage * (radius - distance) / radius);
		if (damage >= 100)
			ForcePlayerSuicide(i);
		else
			SlapPlayer(i, damage, false);
	}
}

public Action DeleteParticle(Handle timer, int particle)
{
	if (IsValidEntity(particle))
	{
		char classN[64];
		GetEdictClassname(particle, classN, sizeof(classN));
		if (StrEqual(classN, "info_particle_system", false))
			RemoveEdict(particle);
	}
}