#include <sdktools>

#pragma semicolon 1

ConVar g_cvarExplodePlayer;
#define SOUND_BOOM1 "weapons/ied/ied_detonate_02.wav"

public Plugin:myinfo = 
{
	name = "nekomiya bomb",
	author = "Gunslinger",
	description = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart() {
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
	float location[3];
	GetClientAbsOrigin(client, location);

	EmitAmbientSound(SOUND_BOOM1, location, client, SNDLEVEL_RAIDSIREN);
	//EmitAmbientSound(SOUND_BOOM2, location, client, SNDLEVEL_RAIDSIREN);
 
	int particle = CreateEntityByName("info_particle_system");
	int explosion = CreateEntityByName("env_explosion_ins");

	char name[64];
	TeleportEntity(particle, location, NULL_VECTOR, NULL_VECTOR);
	GetEntPropString(client, Prop_Data, "m_iName", name, sizeof(name));
	DispatchKeyValue(particle, "targetname", "insparticle");
	DispatchKeyValue(particle, "parentname", name);
	DispatchKeyValue(particle, "effect_name", "ins_car_explosion");
	DispatchSpawn(particle);
	SetVariantString(name);
	ActivateEntity(particle);

	TeleportEntity(explosion, location, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(explosion, "szExplosiveName", "grenade_ied");
	DispatchSpawn(explosion);
	ActivateEntity(explosion);

	AcceptEntityInput(explosion, "Explode");
	AcceptEntityInput(particle, "start");
	CreateTimer(8.0, DeleteParticle, particle);
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