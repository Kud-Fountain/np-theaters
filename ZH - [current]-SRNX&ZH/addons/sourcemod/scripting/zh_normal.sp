#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <smlib/clients>
#include <smlib/entities>
#include <scp>
#include <Lua_insurgency>

new bool:ZH_DEBUG					=						false;

#define GAMEDESC "僵尸暴动 "
#define PLUGIN_VERSION "1.2"
#define PLUGIN_DESCRIPTION "x_x"
public Plugin:myinfo =
{
	name = "#Lua Zombie Horde Checkpoint [CN]",
	author = "D.Freddo, Modified by:Kud",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://group.lua.kr"
}

#define		MAXPLAYER			10		// MAX SECURITY PLAYER SLOTS

#define		TEAM_NONE			0
#define		TEAM_SPECTATOR		1
#define		TEAM_SURVIVORS		2
#define		TEAM_ZOMBIES		3

/**			WEAPON INDEX VALUES			**/
#define		WEAPON_FLAREGUN		25
#define		WEAPON_HEALTHKIT	21
#define		WEAPON_LAW			3
#define		WEAPON_AT4			2
#define		WEAPON_KABAR		30

#define ZOMBIE_DUMMY_WEAPON					"weapon_model10"
#define ZOMBIE_COMMON_INDEX					0
#define ZOMBIE_CLASSIC_INDEX				1
#define ZOMBIE_KNIGHT_INDEX					2
#define ZOMBIE_STALKER_INDEX				3
#define ZOMBIE_BURNER_INDEX					4
#define ZOMBIE_SMOKER_INDEX					5
#define ZOMBIE_IED_INDEX					6
// #define ZOMBIE_BLINKER_INDEX				7
#define ZOMBIE_LEAPER_INDEX					7

#define MAX_ZOMBIE_CLASSES					8

#define PARTICLE_DISPATCH_FROM_ENTITY		(1 << 0)
#define PARTICLE_DISPATCH_RESET_PARTICLES	(1 << 1)
#define STATUS_INUAVRADAR					(1 << 0)
#define STATUS_INPORTABLERADAR				(1 << 1)
#define STATUS_INIEDJAMMER					(1 << 2)
#define STATUS_INAMMOCRATEZONE				(1 << 3)

#define HP		0
#define SPEED	1
#define SIZE	2
#define CLASS	0
#define VAR		1

enum ParticleAttachment_t
{
	PATTACH_ABSORIGIN = 0,			// Create at absorigin, but don't follow
	PATTACH_ABSORIGIN_FOLLOW,		// Create at absorigin, and update to follow the entity
	PATTACH_CUSTOMORIGIN,			// Create at a custom origin, but don't follow
	PATTACH_CUSTOMORIGIN_FOLLOW,	// Create at a custom origin, follow relative position to specified entity
	PATTACH_POINT,					// Create on attachment point, but don't follow
	PATTACH_POINT_FOLLOW,			// Create on attachment point, and update to follow the entity
	PATTACH_EYES_FOLLOW,			// Create on eyes of the attached entity, and update to follow the entity

	PATTACH_WORLDORIGIN,			// Used for control points that don't attach to an entity

	MAX_PATTACH_TYPES,
};

/*//
	#define HITGROUP_GENERIC     0
	#define HITGROUP_HEAD        1
	#define HITGROUP_CHEST       2
	#define HITGROUP_STOMACH     3
	#define HITGROUP_LEFTARM     4    
	#define HITGROUP_RIGHTARM    5
	#define HITGROUP_LEFTLEG     6
	#define HITGROUP_RIGHTLEG    7
	#define HITGROUP_GEAR        10            // alerts NPC, but doesn't do damage or bleed (1/100th damage)
*///

new bool:g_bLateLoad	=	false;
new DEBUGGING_ENABLED	=	0;
new bool:g_bUpdatedSpawnPoint = false;
new g_iRemoveProps = -1;
// new bool:g_bNightMap = false;
new Float:g_fGameTime = 9999999999.0;
new g_iHelicopterRef = INVALID_ENT_REFERENCE;
new Float:g_fHeliLastSeqTime = 0.0;
new Float:g_fHeliPlayerLoopSoundVol[MAXPLAYERS_INS+1] = {0.0, ...};
new g_iHeliEvacPositionIndex = -1;
new Float:g_vHeliEvacPosition[30][3];
new Float:g_vHeliEvacGroundPosition[3];
new bool:g_bHeliEvacStarted = false;
new Float:g_fHeliEvacTime = 0.0;
new g_iHeliEvacParticle = INVALID_ENT_REFERENCE;
new Float:g_fPlayerDrugTime[MAXPLAYERS_INS+1] = {0.0, ...};
new Float:g_fFootstepEffect[MAXPLAYERS_INS+1] = {0.0, ...};
new Float:g_fThunderSound = 0.0;
new g_iPlayerResource = -1;

new Float:FCVAR_HELICOPTER_EVAC_CHANCE					=			100.0;

//	(1) cu_chi_tunnels -8415 5016 228   (-8689 -6335 -106)        -9183 1243 1256  (-8835 1313 130)
new g_iFixMapLocation = -1;

// Game cvars
new Float:FCVAR_GAME_COUNTERATTACK_ALWAYS_CHANCE		=			100.00; //55
new Float:FCVAR_GAME_COUNTERATTACK_WEAPON_CACHE_HEALTH	=			250.00;
new Float:FCVAR_FLAG_BOT_RETURN_TIME					=			20.0;
new Float:FCVAR_FLAG_BOT_RETURN_TIME_MAX				=			40.0;
new Float:FCVAR_FLAG_BOT_RETURN_DISTANCE				=			600.0;

// Bot cvars
//new Float:FCVAR_BOT_WEAPONCACHE_PICKUP_CHANCE_WITHOUT_TOUCH			=			16.66;
new Float:FCVAR_BOT_WEAPONCACHE_INTEL_MODE_CHANCE						=			10.10;
// new Float:FCVAR_BOT_WEAPONCACHE_PICKUP_CHANCE							=			1.11; // 2.22
// new Float:FCVAR_BOT_WEAPONCACHE_PICKUP_CHANCE_DELAY						=			10.0;
// new Float:FCVAR_BOT_WEAPONCACHE_PICKUP_COOLDOWN							=			12.00;
// new Float:FCVAR_BOT_WEAPONCACHE_BLOW_CHANCE								=			40.40;
//new Float:FCVAR_BOT_SUPPRESSED_DUCK_CHANCE								=			44.44;

// Player cvars
new CVAR_PLAYER_HEALTH									=			100;
new CVAR_PLAYER_GLOW_HEALTH								=			55;
new CVAR_PLAYER_HEALTHKIT_HEAL_MIN						=			35;
new CVAR_PLAYER_HEALTHKIT_HEAL_MAX						=			45; //50
/*new CVAR_PLAYER_HEALTHKIT_MEDIC_HEAL_MIN				=			50;
new CVAR_PLAYER_HEALTHKIT_MEDIC_HEAL_MAX				=			70;		*/
new CVAR_PLAYER_HEALTHKIT_MIN_HEALTH					=			55; //65
new CVAR_PLAYER_HEALTHKIT_MAX_HEALTH					=			60; //75
new CVAR_PLAYER_HEALTHKIT_MEDIC_MIN_HEALTH				=			75; //80
new CVAR_PLAYER_HEALTHKIT_MEDIC_MAX_HEALTH				=			85; //90
/*		No Random Healing HP Config
new Float:FCVAR_PLAYER_HEALTHKIT_BANDAGE_BASE_TIME		=			1.2;	// seconds per 10 hp
new Float:FCVAR_PLAYER_HEALTHKIT_BANDAGE_MIN_TIME		=			5.0;
new Float:FCVAR_PLAYER_HEALTHKIT_MEDIC_BANDAGE_BASE_TIME=			0.8;	// seconds per 10 hp
new Float:FCVAR_PLAYER_HEALTHKIT_MEDIC_BANDAGE_MIN_TIME	=			4.5;	*/
new Float:FCVAR_PLAYER_HEALTHKIT_BANDAGE_BASE_TIME		=			1.5;	// seconds per 10 hp //0.8
new Float:FCVAR_PLAYER_HEALTHKIT_BANDAGE_MIN_TIME		=			2.5;	//3.5
new Float:FCVAR_PLAYER_HEALTHKIT_MEDIC_BANDAGE_BASE_TIME=			0.5;	// seconds per 10 hp //0.5
new Float:FCVAR_PLAYER_HEALTHKIT_MEDIC_BANDAGE_MIN_TIME	=			1.5;	//3.0
new bool:BCVAR_PLAYER_HEALTHKIT_MEDIC_INF_BANDAGE		=			true;
new Float:FCVAR_PLAYER_HEALTHKIT_TEAMMATE_DISTANCE_INIT	=			90.0;
new Float:FCVAR_PLAYER_HEALTHKIT_TEAMMATE_DISTANCE_MAX	=			140.0;
//new CVAR_PLAYER_MEDIC_GLOW_PLAYERS_WHEN_LOWHP			=			60;
new Float:FCVAR_PLAYER_NEARDEATH_FADEOUT_INTERVAL_MIN	=			30.0;
new Float:FCVAR_PLAYER_NEARDEATH_FADEOUT_INTERVAL_MAX	=			60.0;
new Float:FCVAR_PLAYER_MEDIC_REQUEST_COOLTIME			=			5.0;
/*		Specials	*/
new Float:FCVAR_PLAYER_RECON_UAV_COOLDOWN				=			180.0;	// UAV RunTime(2.4*15 = 36s)+Delays

/*		YELLS		*/
new Float:FCVAR_PLAYER_YELL_COOLDOWN_MIN				=			2.0;
new Float:FCVAR_PLAYER_YELL_COOLDOWN_MAX				=			6.0;
new Float:FCVAR_PLAYER_YELL_COOLDOWN_FRIENDLYFIRE		=			0.8;
new Float:FCVAR_PLAYER_YELL_CHANCE_KILL					=			50.0;
new Float:FCVAR_PLAYER_YELL_CHANCE_HS_KILL				=			100.0;
new Float:FCVAR_PLAYER_YELL_CHANCE_GRENADE				=			66.0;
new Float:FCVAR_PLAYER_YELL_CHANCE_ROCKET				=			80.0;
new Float:FCVAR_PLAYER_YELL_CHANCE_SUPPRESS				=			40.0;
new Float:FCVAR_PLAYER_BURN_CHANCE_FIRE					=			30.0;
new Float:FCVAR_PLAYER_BURN_CHANCE_EXPLOSIVE			=			40.0;
new Float:FCVAR_PLAYER_BURN_MIN_TIME					=			2.0;
new Float:FCVAR_PLAYER_BURN_MAX_TIME					=			5.0;

/*		SPAWN		*/
	// Players
new Float:FCVAR_PLAYER_SPAWN_PROTECTION							=			6.66;
new CVAR_PLAYER_REINFORCEMENT_RATIO								=			20;
new CVAR_PLAYER_REINFORCEMENT_MIN								=			1;
new CVAR_PLAYER_REINFORCEMENT_MAX								=			8; //6
new Float:FCVAR_PLAYER_REINFORCEMENT_DEPLOY_TIME				=			60.0; //90
//new Float:FCVAR_PLAYER_REINFORCEMENT_COUNTER_DEPLOY_TIME		=			50.0;
new Float:FCVAR_PLAYER_REINFORCEMENT_COUNTER_DEPLOY_TIME		=			999.0;
new Float:FCVAR_PLAYER_REINFORCEMENT_END_TIME					=			0.0; //80
new CVAR_PLAYER_REINFORCEMENT_MAX_PER_POINT						=			2;
new Float:FCVAR_PLAYER_BLEEDING_BULLET_CHANCE					=			8.88;
//new Float:FCVAR_PLAYER_BLEEDING_EXPLOSIVE_CHANCE				=			44.44;
new Float:FCVAR_PLAYER_BLEEDING_INTERVAL_MIN					=			8.0; //10
new Float:FCVAR_PLAYER_BLEEDING_INTERVAL_MAX					=			10.0; //20
new CVAR_PLAYER_BLEEDING_DAMAGE_MIN								=			9; //2
new CVAR_PLAYER_BLEEDING_DAMAGE_MAX								=			15; //6
new Float:FCVAR_PLAYER_INFECTION_CHANCE							=		50.0; //33.3
new Float:FCVAR_PLAYER_INFECTION_TIMEINTERVAL_MIN				=		8.0; //10
new Float:FCVAR_PLAYER_INFECTION_TIMEINTERVAL_MAX				=		10.0; //20
new CVAR_PLAYER_INFECTION_DAMAGE_MIN 							=		9; //2
new CVAR_PLAYER_INFECTION_DAMAGE_MAX 							=		15; //6
new String:SCVAR_INFECTION_DAMAGE_CLASSNAME[128] 				=		"Infection";
	// Bots
new Float:FCVAR_BOT_RESPAWN_WHEN_LIVE_TOO_LONG					=			40.0;
new Float:FCVAR_BOT_SPAWN_EXP_BURN_NO_DAMAGE_TIME				=			5.0;
new CVAR_BOT_REINFORCEMENT_TOKEN_MIN							=			15;
new CVAR_BOT_REINFORCEMENT_TOKEN_MIN_ALONE						=			5;
new Float:FCVAR_BOT_REINFORCEMENT_TOKEN_BASE_MIN				=			1.111;
new Float:FCVAR_BOT_REINFORCEMENT_TOKEN_BASE_MAX				=			3.111;
new CVAR_BOT_REINFORCEMENT_RATIO								=			10;
new CVAR_BOT_REINFORCEMENT_MIN									=			1;
new CVAR_BOT_REINFORCEMENT_MAX									=			99;
new Float:FCVAR_BOT_REINFORCEMENT_DEPLOY_TIME_BASE				=			0.666;
new Float:FCVAR_BOT_REINFORCEMENT_DEPLOY_TIME_BASE_MAX			=			10.0;
new Float:FCVAR_BOT_REINFORCEMENT_COUNTER_DEPLOY_TIME_BASE		=			0.555;
new Float:FCVAR_BOT_REINFORCEMENT_COUNTER_DEPLOY_TIME_MAX		=			8.0;
new Float:FCVAR_BOT_REINFORCEMENT_FINAL_COUNTER_DEPLOY_TIME_MIN	=			0.10;
new Float:FCVAR_BOT_REINFORCEMENT_FINAL_COUNTER_DEPLOY_TIME_MAX	=			2.22;
new Float:FCVAR_BOT_REINFORCEMENT_END_TIME						=			90.0;
new Float:FCVAR_BOT_REINFORCEMENT_COUNTER_END_TIME				=			5.0;
new CVAR_BOT_REINFORCEMENT_MAX_PER_POINT						=			15;
new Float:FCVAR_BOT_REINFORCEMENT_BACKATTACK_CHANCE				=			30.0;
new Float:FCVAR_BOT_REINFORCEMENT_COUNTER_BACKATTACK_CHANCE		=			50.0;
new Float:FCVAR_FINAL_COUNTERATTACK_TIME						=			270.0;

/*		HEARTBEATS		*/
/*new Float:FCVAR_PLAYER_HEARTBEAT_INTERVAL				=			1.5;
new Float:FCVAR_PLAYER_HEARTBEAT_FAST_INTERVAL			=			0.8;	*/

/**
		ZOMBIES
						**/
new CVAR_ZOMBIE_COMMON_HEALTH_MIN						=		400;
new CVAR_ZOMBIE_COMMON_HEALTH_MAX						=		500;
new CVAR_ZOMBIE_COMMON_BOT_HEALTH_MIN					=		350; //300
new CVAR_ZOMBIE_COMMON_BOT_HEALTH_MAX					=		450; //500
new Float:FCVAR_ZOMBIE_COMMON_SIZE_MIN					=		0.90;
new Float:FCVAR_ZOMBIE_COMMON_SIZE_MAX					=		1.00;
new CVAR_ZOMBIE_COMMON_COLOR_RED						=		255;
new CVAR_ZOMBIE_COMMON_COLOR_GREEN						=		255;
new CVAR_ZOMBIE_COMMON_COLOR_BLUE						=		255;
new Float:FCVAR_ZOMBIE_COMMON_SPEED_MIN					=		1.14; //1.14
new Float:FCVAR_ZOMBIE_COMMON_SPEED_MAX					=		1.16; //1.16
new Float:FCVAR_ZOMBIE_COMMON_BOT_SPEED_MIN				=		1.15; //1.15
new Float:FCVAR_ZOMBIE_COMMON_BOT_SPEED_MAX				=		1.25; //1.25
new Float:FCVAR_ZOMBIE_COMMON_DAMAGE_MIN 				=		12.0; //12
new Float:FCVAR_ZOMBIE_COMMON_DAMAGE_MAX 				=		18.0; //18
new Float:FCVAR_ZOMBIE_COMMON_DAMAGE_BACKATTACK_MIN 	=		24.0; //24
new Float:FCVAR_ZOMBIE_COMMON_DAMAGE_BACKATTACK_MAX 	=		28.0; //28
/*
new Float:FCVAR_ZOMBIE_BLINKER_BLINK_CHANCE				=		77.7;
new Float:FCVAR_ZOMBIE_BLINKER_BLINK_DAMAGE_RATIO		=		0.4;
new Float:FCVAR_ZOMBIE_BLINKER_CHANCE					=		16.6; // 55.5
new CVAR_ZOMBIE_BLINKER_RESTRICT						=		0;
new CVAR_ZOMBIE_BLINKER_MAX_SPAWN						=		-2;
new Float:FCVAR_ZOMBIE_BLINKER_MAX_SPAWN_PER_SURVIVORS	=		0.4;
new Float:FCVAR_ZOMBIE_BLINKER_MAX_SPAWN_PER_ZOMBIES	=		0.0;
new CVAR_ZOMBIE_BLINKER_HEALTH_MIN						=		1000; //300
new CVAR_ZOMBIE_BLINKER_HEALTH_MAX						=		1500; //360
new CVAR_ZOMBIE_BLINKER_BOT_HEALTH_MIN					=		1000; //200
new CVAR_ZOMBIE_BLINKER_BOT_HEALTH_MAX					=		1500; //360
// new Float:FCVAR_ZOMBIE_BLINKER_PENALTY_TIME				=		60.0;
// new Float:FCVAR_ZOMBIE_BLINKER_BOT_PENALTY_TIME			=		50.0;
new Float:FCVAR_ZOMBIE_BLINKER_SIZE_MIN					=		0.92;
new Float:FCVAR_ZOMBIE_BLINKER_SIZE_MAX					=		0.95;
new CVAR_ZOMBIE_BLINKER_COLOR_RED						=		222;
new CVAR_ZOMBIE_BLINKER_COLOR_GREEN						=		222;
new CVAR_ZOMBIE_BLINKER_COLOR_BLUE						=		222;
new CVAR_ZOMBIE_BLINKER_COLOR_ALPHA						=		177;
new Float:FCVAR_ZOMBIE_BLINKER_SPEED_MIN				=		1.24; //1.14
new Float:FCVAR_ZOMBIE_BLINKER_SPEED_MAX				=		1.26; //1.16
new Float:FCVAR_ZOMBIE_BLINKER_BOT_SPEED_MIN			=		1.22; //1.12
new Float:FCVAR_ZOMBIE_BLINKER_BOT_SPEED_MAX			=		1.24; //1.14
new Float:FCVAR_ZOMBIE_BLINKER_DAMAGE_MIN 				=		10.0;
new Float:FCVAR_ZOMBIE_BLINKER_DAMAGE_MAX 				=		16.0;
new Float:FCVAR_ZOMBIE_BLINKER_DAMAGE_BACKATTACK_MIN 	=		20.0;
new Float:FCVAR_ZOMBIE_BLINKER_DAMAGE_BACKATTACK_MAX 	=		24.0;
*/
new Float:FCVAR_ZOMBIE_STALKER_CHANCE					=		16.6; //24.4
new CVAR_ZOMBIE_STALKER_RESTRICT						=		0;
new CVAR_ZOMBIE_STALKER_MAX_SPAWN						=		-2;
new Float:FCVAR_ZOMBIE_STALKER_MAX_SPAWN_PER_SURVIVORS	=		1.55;
new Float:FCVAR_ZOMBIE_STALKER_MAX_SPAWN_PER_ZOMBIES	=		0.0;
new CVAR_ZOMBIE_STALKER_HEALTH_MIN						=		1500; //300
new CVAR_ZOMBIE_STALKER_HEALTH_MAX						=		2000; //400
new CVAR_ZOMBIE_STALKER_BOT_HEALTH_MIN					=		1500; //200
new CVAR_ZOMBIE_STALKER_BOT_HEALTH_MAX					=		2000; //300
// new Float:FCVAR_ZOMBIE_STALKER_PENALTY_TIME				=		40.0;
// new Float:FCVAR_ZOMBIE_STALKER_BOT_PENALTY_TIME			=		20.0;
new Float:FCVAR_ZOMBIE_STALKER_SIZE_MIN					=		0.65;
new Float:FCVAR_ZOMBIE_STALKER_SIZE_MAX					=		0.74;
new CVAR_ZOMBIE_STALKER_COLOR_RED						=		255;
new CVAR_ZOMBIE_STALKER_COLOR_GREEN						=		255;
new CVAR_ZOMBIE_STALKER_COLOR_BLUE						=		255;
new Float:FCVAR_ZOMBIE_STALKER_SPEED_MIN				=		1.20; //1.20
new Float:FCVAR_ZOMBIE_STALKER_SPEED_MAX				=		1.22; //1.22
new Float:FCVAR_ZOMBIE_STALKER_BOT_SPEED_MIN			=		1.10; //1.10
new Float:FCVAR_ZOMBIE_STALKER_BOT_SPEED_MAX			=		1.16; //1.16
new Float:FCVAR_ZOMBIE_STALKER_DAMAGE_MIN 				=		10.0;
new Float:FCVAR_ZOMBIE_STALKER_DAMAGE_MAX 				=		16.0;
new Float:FCVAR_ZOMBIE_STALKER_DAMAGE_BACKATTACK_MIN 	=		20.0;
new Float:FCVAR_ZOMBIE_STALKER_DAMAGE_BACKATTACK_MAX 	=		24.0;

new Float:FCVAR_ZOMBIE_KNIGHT_CHANCE					=		5.0; //11.1
new CVAR_ZOMBIE_KNIGHT_RESTRICT							=		0;
new CVAR_ZOMBIE_KNIGHT_MAX_SPAWN						=		-2;
new Float:FCVAR_ZOMBIE_KNIGHT_MAX_SPAWN_PER_SURVIVORS	=		0.6;
new Float:FCVAR_ZOMBIE_KNIGHT_MAX_SPAWN_PER_ZOMBIES		=		0.0;
new CVAR_ZOMBIE_KNIGHT_HEALTH_MIN						=		10000; //2800
new CVAR_ZOMBIE_KNIGHT_HEALTH_MAX						=		10500; //3400
new CVAR_ZOMBIE_KNIGHT_BOT_HEALTH_MIN					=		10000; //1500
new CVAR_ZOMBIE_KNIGHT_BOT_HEALTH_MAX					=		10500; //3000
// new Float:FCVAR_ZOMBIE_KNIGHT_PENALTY_TIME				=		50.0;
// new Float:FCVAR_ZOMBIE_KNIGHT_BOT_PENALTY_TIME			=		30.0;
new Float:FCVAR_ZOMBIE_KNIGHT_SIZE_MIN					=		1.50; //1.36
new Float:FCVAR_ZOMBIE_KNIGHT_SIZE_MAX					=		1.58; //1.44
new CVAR_ZOMBIE_KNIGHT_COLOR_RED						=		255;
new CVAR_ZOMBIE_KNIGHT_COLOR_GREEN						=		166;
new CVAR_ZOMBIE_KNIGHT_COLOR_BLUE						=		166;
new Float:FCVAR_ZOMBIE_KNIGHT_SPEED_MIN					=		1.10; //1.1
new Float:FCVAR_ZOMBIE_KNIGHT_SPEED_MAX					=		1.12; //1.12
new Float:FCVAR_ZOMBIE_KNIGHT_BOT_SPEED_MIN				=		1.10; //1.10
new Float:FCVAR_ZOMBIE_KNIGHT_BOT_SPEED_MAX				=		1.15; //1.15
new Float:FCVAR_ZOMBIE_KNIGHT_DAMAGE_MIN 				=		16.0;
new Float:FCVAR_ZOMBIE_KNIGHT_DAMAGE_MAX 				=		20.0;
new Float:FCVAR_ZOMBIE_KNIGHT_DAMAGE_BACKATTACK_MIN 	=		26.0;
new Float:FCVAR_ZOMBIE_KNIGHT_DAMAGE_BACKATTACK_MAX 	=		30.0;

new Float:FCVAR_ZOMBIE_BURNER_ATTACK_BURN_CHANCE		=		66.6;
new Float:FCVAR_ZOMBIE_BURNER_ATTACK_BURN_TIME_MIN		=		3.0;
new Float:FCVAR_ZOMBIE_BURNER_ATTACK_BURN_TIME_MAX		=		6.6;
new Float:FCVAR_ZOMBIE_BURNER_CHANCE					=		16.6; //22.2
new CVAR_ZOMBIE_BURNER_RESTRICT							=		0;
new CVAR_ZOMBIE_BURNER_MAX_SPAWN						=		-2;
new Float:FCVAR_ZOMBIE_BURNER_MAX_SPAWN_PER_SURVIVORS	=		1.15;
new Float:FCVAR_ZOMBIE_BURNER_MAX_SPAWN_PER_ZOMBIES		=		0.0;
new CVAR_ZOMBIE_BURNER_HEALTH_MIN						=		1500; //300
new CVAR_ZOMBIE_BURNER_HEALTH_MAX						=		2000; //500
new CVAR_ZOMBIE_BURNER_BOT_HEALTH_MIN					=		1500; //300
new CVAR_ZOMBIE_BURNER_BOT_HEALTH_MAX					=		2000; //450
// new Float:FCVAR_ZOMBIE_BURNER_PENALTY_TIME				=		40.0;
// new Float:FCVAR_ZOMBIE_BURNER_BOT_PENALTY_TIME			=		30.0;
new Float:FCVAR_ZOMBIE_BURNER_SIZE_MIN					=		0.8;
new Float:FCVAR_ZOMBIE_BURNER_SIZE_MAX					=		0.9;
new CVAR_ZOMBIE_BURNER_COLOR_RED						=		99;
new CVAR_ZOMBIE_BURNER_COLOR_GREEN						=		99;
new CVAR_ZOMBIE_BURNER_COLOR_BLUE						=		99;
new Float:FCVAR_ZOMBIE_BURNER_SPEED_MIN					=		1.16; //1.16
new Float:FCVAR_ZOMBIE_BURNER_SPEED_MAX					=		1.20; //1.20
new Float:FCVAR_ZOMBIE_BURNER_BOT_SPEED_MIN				=		1.20; //1.20
new Float:FCVAR_ZOMBIE_BURNER_BOT_SPEED_MAX				=		1.25; //1.25
new Float:FCVAR_ZOMBIE_BURNER_HURT_BULLET_DETONATE_CHANCE			=		0.5; //0.33
new Float:FCVAR_ZOMBIE_BURNER_DAMAGE_MIN 				=		12.0;
new Float:FCVAR_ZOMBIE_BURNER_DAMAGE_MAX 				=		18.0;
new Float:FCVAR_ZOMBIE_BURNER_DAMAGE_BACKATTACK_MIN 	=		24.0;
new Float:FCVAR_ZOMBIE_BURNER_DAMAGE_BACKATTACK_MAX 	=		28.0;

new Float:FCVAR_ZOMBIE_SMOKER_CHANCE					=		16.6; //11.1
new CVAR_ZOMBIE_SMOKER_RESTRICT							=		0;
new CVAR_ZOMBIE_SMOKER_MAX_SPAWN						=		-2;
new Float:FCVAR_ZOMBIE_SMOKER_MAX_SPAWN_PER_SURVIVORS	=		0.255;
new Float:FCVAR_ZOMBIE_SMOKER_MAX_SPAWN_PER_ZOMBIES		=		0.0;
new CVAR_ZOMBIE_SMOKER_HEALTH_MIN						=		1500; //300
new CVAR_ZOMBIE_SMOKER_HEALTH_MAX						=		2000; //350
new CVAR_ZOMBIE_SMOKER_BOT_HEALTH_MIN					=		1500; //250
new CVAR_ZOMBIE_SMOKER_BOT_HEALTH_MAX					=		2000; //350
// new Float:FCVAR_ZOMBIE_SMOKER_PENALTY_TIME				=		60.0;
// new Float:FCVAR_ZOMBIE_SMOKER_BOT_PENALTY_TIME			=		50.0;
new Float:FCVAR_ZOMBIE_SMOKER_SIZE_MIN					=		0.9;
new Float:FCVAR_ZOMBIE_SMOKER_SIZE_MAX					=		1.0;
new CVAR_ZOMBIE_SMOKER_COLOR_RED						=		188;
new CVAR_ZOMBIE_SMOKER_COLOR_GREEN						=		188;
new CVAR_ZOMBIE_SMOKER_COLOR_BLUE						=		188;
new Float:FCVAR_ZOMBIE_SMOKER_SPEED_MIN					=		1.10; //1.10
new Float:FCVAR_ZOMBIE_SMOKER_SPEED_MAX					=		1.15; //1.15
new Float:FCVAR_ZOMBIE_SMOKER_BOT_SPEED_MIN				=		1.20; //1.20
new Float:FCVAR_ZOMBIE_SMOKER_BOT_SPEED_MAX				=		1.25; //1.25
new Float:FCVAR_ZOMBIE_SMOKER_DAMAGE_MIN 				=		12.0;
new Float:FCVAR_ZOMBIE_SMOKER_DAMAGE_MAX 				=		16.0;
new Float:FCVAR_ZOMBIE_SMOKER_DAMAGE_BACKATTACK_MIN 	=		20.0;
new Float:FCVAR_ZOMBIE_SMOKER_DAMAGE_BACKATTACK_MAX 	=		24.0;

new Float:FCVAR_ZOMBIE_IED_CHANCE								=		18.0; //12.22
new CVAR_ZOMBIE_IED_RESTRICT									=		0;
new CVAR_ZOMBIE_IED_MAX_SPAWN									=		-2;
new Float:FCVAR_ZOMBIE_IED_MAX_SPAWN_PER_SURVIVORS				=		1.00;
new Float:FCVAR_ZOMBIE_IED_MAX_SPAWN_PER_ZOMBIES				=		0.0;
new CVAR_ZOMBIE_IED_HEALTH_MIN									=		1500; //300
new CVAR_ZOMBIE_IED_HEALTH_MAX									=		2000; //350
new CVAR_ZOMBIE_IED_BOT_HEALTH_MIN								=		1500; //200
new CVAR_ZOMBIE_IED_BOT_HEALTH_MAX								=		2000; //320
// new Float:FCVAR_ZOMBIE_IED_PENALTY_TIME							=		60.0;
// new Float:FCVAR_ZOMBIE_IED_BOT_PENALTY_TIME						=		50.0;
new Float:FCVAR_ZOMBIE_IED_SIZE_MIN								=		0.9;
new Float:FCVAR_ZOMBIE_IED_SIZE_MAX								=		1.0;
new CVAR_ZOMBIE_IED_COLOR_RED									=		122;
new CVAR_ZOMBIE_IED_COLOR_GREEN									=		122;
new CVAR_ZOMBIE_IED_COLOR_BLUE									=		122;
new Float:FCVAR_ZOMBIE_IED_SPEED_MIN							=		1.20; //1.20
new Float:FCVAR_ZOMBIE_IED_SPEED_MAX							=		1.30; //1.30
new Float:FCVAR_ZOMBIE_IED_BOT_SPEED_MIN						=		1.20; //1.20
new Float:FCVAR_ZOMBIE_IED_BOT_SPEED_MAX						=		1.30; //1.30
new Float:FCVAR_ZOMBIE_IED_DAMAGE_MIN 							=		12.0;
new Float:FCVAR_ZOMBIE_IED_DAMAGE_MAX 							=		16.0;
new Float:FCVAR_ZOMBIE_IED_DAMAGE_BACKATTACK_MIN 				=		20.0;
new Float:FCVAR_ZOMBIE_IED_DAMAGE_BACKATTACK_MAX 				=		24.0;
new Float:FCVAR_ZOMBIE_IED_HURT_BULLET_DETONATE_CHANCE			=			6.66;
new Float:FCVAR_ZOMBIE_IED_HURT_EXPLOSIVE_DETONATE_CHANCE		=			33.33;
new Float:FCVAR_ZOMBIE_IED_HURT_BURN_DETONATE_CHANCE			=			6.66;
new Float:FCVAR_ZOMBIE_IED_C4_DETONATE_DISTANCE					=			400.0;
new Float:FCVAR_ZOMBIE_IED_GRENADE_DETONATE_DISTANCE			=			300.0;
new Float:FCVAR_ZOMBIE_IED_C4_CHANCE							=			6.66;
	new Float:FCVAR_ZOMBIE_IED_C4_BADASS_CHANCE					=			15.0;

new Float:FCVAR_ZOMBIE_LEAPER_LEAP_DISTANCE_MIN			=			100.0;
new Float:FCVAR_ZOMBIE_LEAPER_LEAP_DISTANCE_MAX			=			1200.0;
new Float:FCVAR_ZOMBIE_LEAPER_LEAP_DELAY_MIN			=			0.5;
new Float:FCVAR_ZOMBIE_LEAPER_LEAP_DELAY_MAX			=			1.2;
new Float:FCVAR_ZOMBIE_LEAP_READY_SPEED					=			0.33;
new Float:FCVAR_ZOMBIE_LEAPER_CHANCE					=		16.6; //12.12
new CVAR_ZOMBIE_LEAPER_RESTRICT							=		0;
new CVAR_ZOMBIE_LEAPER_MAX_SPAWN						=		-2;
new Float:FCVAR_ZOMBIE_LEAPER_MAX_SPAWN_PER_SURVIVORS	=		1.33;
new Float:FCVAR_ZOMBIE_LEAPER_MAX_SPAWN_PER_ZOMBIES		=		0.0;
new CVAR_ZOMBIE_LEAPER_HEALTH_MIN						=		1500; //300
new CVAR_ZOMBIE_LEAPER_HEALTH_MAX						=		2000; //400
new CVAR_ZOMBIE_LEAPER_BOT_HEALTH_MIN					=		1500; //250
new CVAR_ZOMBIE_LEAPER_BOT_HEALTH_MAX					=		2000; //350
// new Float:FCVAR_ZOMBIE_LEAPER_PENALTY_TIME				=		40.0;
// new Float:FCVAR_ZOMBIE_LEAPER_BOT_PENALTY_TIME			=		20.0;
new Float:FCVAR_ZOMBIE_LEAPER_SIZE_MIN					=		0.9;
new Float:FCVAR_ZOMBIE_LEAPER_SIZE_MAX					=		1.0;
new CVAR_ZOMBIE_LEAPER_COLOR_RED						=		120;
new CVAR_ZOMBIE_LEAPER_COLOR_GREEN						=		102;
new CVAR_ZOMBIE_LEAPER_COLOR_BLUE						=		255;
new Float:FCVAR_ZOMBIE_LEAPER_SPEED_MIN				=		1.20; //1.20
new Float:FCVAR_ZOMBIE_LEAPER_SPEED_MAX				=		1.25; //1.25
new Float:FCVAR_ZOMBIE_LEAPER_BOT_SPEED_MIN				=		1.20; //1.20
new Float:FCVAR_ZOMBIE_LEAPER_BOT_SPEED_MAX				=		1.25; //1.25
new Float:FCVAR_ZOMBIE_LEAPER_DAMAGE_MIN 				=		10.0;
new Float:FCVAR_ZOMBIE_LEAPER_DAMAGE_MAX 				=		16.0;
new Float:FCVAR_ZOMBIE_LEAPER_DAMAGE_BACKATTACK_MIN 	=		20.0;
new Float:FCVAR_ZOMBIE_LEAPER_DAMAGE_BACKATTACK_MAX 	=		24.0;

new Float:FCVAR_ZOMBIE_BURN_MIN_TIME					=			6.0;
new Float:FCVAR_ZOMBIE_BURN_MAX_TIME					=			20.0;
new Float:FCVAR_ZOMBIE_BURN_DAMAGE						=			5.0;
new Float:FCVAR_ZOMBIE_BURN_BONUS_SPEED_MIN				=			0.14; //0.14
new Float:FCVAR_ZOMBIE_BURN_BONUS_SPEED_MAX				=			0.18; //0.20
new Float:FCVAR_ZOMBIE_BLEEDING_MIN_TIME				=			3.0;
new Float:FCVAR_ZOMBIE_BLEEDING_MAX_TIME				=			6.0;
new Float:FCVAR_ZOMBIE_BLEED_REDUCE_SPEED_MIN			=			0.06;
new Float:FCVAR_ZOMBIE_BLEED_REDUCE_SPEED_MAX			=			0.10;
new Float:FCVAR_ZOMBIE_BONUS_SPEED_DISTANCE				=			1300.0;
new Float:FCVAR_ZOMBIE_BONUS_SPEED						=			0.6;


// Game handle and offsets
new Handle:g_hGameConfig = INVALID_HANDLE;
new Handle:g_hPlayerRespawn = INVALID_HANDLE;
new Handle:g_hPlayerForceChangeTeam = INVALID_HANDLE;
new Handle:g_hCvarBotCount = INVALID_HANDLE;
new Handle:g_hCvarBotLevel = INVALID_HANDLE;
new Handle:g_hCvarLobbySize = INVALID_HANDLE;
new Handle:g_hCvarAlwaysCounterAttack = INVALID_HANDLE;
new Handle:g_hCvarCounterAttackDelay = INVALID_HANDLE;
new Handle:g_hFcvarCounterAttackTime = INVALID_HANDLE;
new Handle:g_hCvarFinalCounterAttackDelay = INVALID_HANDLE;
// new Handle:g_hFcvarFinalCounterAttackTime = INVALID_HANDLE;
new g_iOffsetWaterlevel = -1;
new g_iOffsetWeaponCacheGlow = -1;
new g_iOffsetCPNumbers = -1;
new g_iOffsetCPIndex = -1;
new g_iOffsetCPType = -1;
new g_iOffsetCPPositions = -1;
new g_iPlayerManager = -1;
new g_iOffsetSquad = -1;
new g_iOffsetSquadSlot = -1;
new g_iOffsetDeployTimer = -1;
new g_iOffsetGears = -1;
new g_iOffsetChamberRound = -1;
new Float:g_fRoundTimeLeft = -1.0;
new g_iOffsetMyWeapons = -1;
new g_iOffsetScore = -1;
//new g_iOffsetAssists = -1;
new g_iOffsetFirstDeploy = -1;
new g_iPlayerFirstDeployCheck[MAXPLAYERS_INS+1] = {-1, ...};
new Float:g_fPlayerFirstDeployTimestamp[MAXPLAYERS_INS+1] = {0.0, ...};
/*	new g_iTomahawkModel[2] = {-1, -1};
new g_iClientViewEntity[MAXPLAYERS_INS+1] = {-1, ...};
new g_iClientViewOldSequence[MAXPLAYERS_INS+1] = {-1, ...};
new Float:g_fClientViewOldCycle[MAXPLAYERS_INS+1] = {0.0, ...};		*/
new g_iPlayerDeployedWeapon[MAXPLAYERS_INS+1] = {-1, ...};
new g_iPlayerCustomGear[MAXPLAYERS_INS+1] = {-1, ...};
new g_iPlayerTempProp[MAXPLAYERS_INS+1] = {-1, ...};
new Float:g_fPlayerTempPropTimestamp[MAXPLAYERS_INS+1] = {0.0, ...};
new Float:g_vPlayerTempPropOrigin[MAXPLAYERS_INS+1][3];
new g_iGearRadarModel[2] = {-1, ...};
new g_iGearIEDJammerModel[2] = {-1, ...};
new g_iGearBarricade[7] = {-1, ...};
new g_iGearAmmoCrateModel[2] = {-1, ...};
new Float:g_fPlayerTempPropCooldown[MAXPLAYERS_INS+1] = {0.0, ...};
new bool:g_bPlayerTempPropSetup[MAXPLAYERS_INS+1] = {false, ...};
new g_iStuckCheckTime = 2500;
new g_iPlayersList[MAXPLAYER] = {-1, ...};
new bool:g_bPlayerBandageSound[MAXPLAYERS_INS+1] = {false, ...};
new bool:g_bMedicPlayer[MAXPLAYERS_INS+1] = {false, ...};
new Float:g_fMedicLastHealTime[MAXPLAYERS_INS+1] = {0.0, ...};
new Float:g_fMedicBannedTime[MAXPLAYERS_INS+1] = {0.0, ...};
new bool:g_bMedicForceToChange[MAXPLAYERS_INS+1] = false;
new g_iLastManStand = -1;

new g_iGamemode = 1;
new g_iGameState = 0;
new g_iEntityCount = 0;
new Float:g_fLastEdictCheck = 0.0;
new g_iObjRes = -1;
new g_iNumControlPoints = -1;
new g_iCurrentControlPoint = -1;
new bool:g_bCounterAttack = false;
new bool:g_bFinalCP = false;
new bool:g_bFinalCPMusic = false;
new g_iOnFireBy	= 0;
new Handle:g_hWeaponCacheFireExplode = INVALID_HANDLE;
//new g_fObjectHealth = 200;
new Handle:g_hAmmoExplodeEffectTimer = INVALID_HANDLE;
new String:g_sMovingCacheModel[128] = "models/static_props/weapon_cache_01.mdl";
new g_iMovingCacheModelSkin = 0;
new Handle:g_hCounterAttackRespawnTimer = INVALID_HANDLE;
new g_iPointFlag = INVALID_ENT_REFERENCE;
new g_iPointFlagSpawnGlow = INVALID_ENT_REFERENCE;
new g_iPointFlagOwner = -1;
new Float:g_vIntelReturn[3];
new bool:g_bNoTakingCache = false;
new bool:g_bDoNotPlayFlagPickUp = false;
new Float:g_fWeaponCacheHealth = 300.0;
new Float:g_fCacheLastHitTime = 0.0;
new Float:g_fFlagDropTime = 0.0;
new String:g_sFlagSoundLast[52];
new bool:g_bSkipCacheCheck = false;
//new bool:g_bSkipSpawnCheck = false;
new bool:g_bCounterAttackReadyTime = false;
new Float:g_fReinforcementPlayerDeployTime = 0.0;
new Float:g_fReinforcementBotDeployTime = 0.0;
new bool:g_bReinforcementPlayerEnd = false;
new g_iReinforcementPlayerCount = 0;
new bool:g_bReinforcementBotEnd = false;
new g_iReinforcementBotCount = 0;
new bool:g_bKillNoticePlayed = false;
new bool:g_bAlone = false;
new String:g_sCurrentMap[32];
new g_iSecurityAlive = 0;
new g_iSecurityDead = 0;
new g_iEnemyAlive = 0;
new g_iEnemyDead = 0;
new g_iSpriteLaser = -1;
new bool:g_bTochedControlPoint = false;
new Float:g_fSpawnUpdateLastFailedTime = 0.0;

// Object array
#define MAX_OBJECTIVE				16
new bool:g_bIsMovingCache[2048] = {false, ...};
new bool:g_bIsOnFire[2048] = {false, ...};
new Float:g_vCPPositions[MAX_OBJECTIVE][3];
new g_iCPType[MAX_OBJECTIVE] = {-9, ...};
new g_iCPIndex[MAX_OBJECTIVE] = {-1, ...};

// UAV
new g_iUAVCount = 0;
new bool:g_bUAVOnline = false;
////new g_iBeaconBeam;
new g_iBeaconHalo;
new Handle:g_hCvarUAVCounts = INVALID_HANDLE;
new Handle:g_hUAVTimer = INVALID_HANDLE;
new Float:g_fUAVLastTime = 0.0;

// Spawn array
#define MAX_SPAWNZONE				64
#define MAX_SPAWNZONE_ENTITIES		128
#define MAX_SPAWNPOINT				28
#define MAX_SPAWNPOINT_ENTITIES		1024
#define MAX_SPAWNPOINT_INFOS		8192
new g_iSpawnPointsRef[MAX_SPAWNPOINT_ENTITIES], g_iSpawnPointsIndex = -1;
new g_iSpawnZoneRef[MAX_SPAWNZONE_ENTITIES], g_iSpawnZoneIndex = -1;
new g_iSpawnPointsInfo[MAX_SPAWNPOINT_INFOS][4], g_iSpawnPointsInfoMaxIndex = -1;
//	g_iSpawnPointsInfo[index][0: spawnpoint index | 1: counter attack | 2: CP | 3: Team] = spawnpoint ref
new g_iSpawnPointsInfoIndex[MAX_OBJECTIVE];
//	g_iSpawnPointsInfoIndex[control point] = start index
//new g_iBlockZoneRef[128], g_iBlockZoneIndex = -1;
new g_iNextSpawnPointsIndex = -1;
new Float:g_vNextSpawnPoints[MAX_SPAWNPOINT][3];

// Bots
new g_iTeleportOnSpawn[MAXPLAYERS_INS+1] = {0, ...};
new Float:g_fSpawnTime[MAXPLAYERS_INS+1] = {0.0, ...};
new g_iZombieModels[5] = {-1, ...};
new Float:g_fZombieObjectDamaged[MAXPLAYERS_INS+1];		//	[0: HP, 1: Speed, 2: Size]
new Float:g_fZombieNextStats[MAXPLAYERS_INS+1][3];		//	[0: HP, 1: Speed, 2: Size]
//new g_iSuicideBombKnifeModel = -1;
new g_iSuicideBombWeaponModels[10] = {-1, ...};
new g_iZombieSpawnCount[MAX_ZOMBIE_CLASSES] = {0, ...};
new g_iZombieClass[MAXPLAYERS_INS+1][2];
new g_iPlayerStatus[MAXPLAYERS_INS+1] = {0, ...};

// Players array
new Float:g_fPlayerAmbientTime[MAXPLAYERS_INS+1] = {0.0, ...};
new String:g_sPlayerClassTemplate[MAXPLAYERS_INS+1][128];
new WelcomeToTheCompany[MAXPLAYERS_INS+1] = {0, ...};
new Float:g_fSuppressedTime[MAXPLAYERS_INS+1] = {0.0, ...};
new g_bHasSquad[MAXPLAYERS_INS+1] = {false, ...};
new bool:g_bIsInCaptureZone[MAXPLAYERS_INS+1] = {false, ...};
new Float:g_fLastYellTime[MAXPLAYERS_INS+1] = {0.0, ...};
new g_iPlayerBleeding[MAXPLAYERS_INS+1] = {0, ...};
new Float:g_fPlayerBleedTime[MAXPLAYERS_INS+1] = {0.0, ...};
new g_iLastHitgroup[MAXPLAYERS_INS+1] = {0, ...};
new bool:g_bWasFiredLAW[MAXPLAYERS_INS+1] = {false, ...};
new Float:g_fProtectionTime[MAXPLAYERS_INS+1] = {0.0, ...};
new Float:g_fBurnTime[MAXPLAYERS_INS+1] = {0.0, ...};
new g_iBurnedBy[MAXPLAYERS_INS+1] = {-1, ...};
new Float:g_fNextBurnTime[MAXPLAYERS_INS+1] = {0.0, ...};
//new Float:g_fLastWarningTime[MAXPLAYERS_INS+1] = {0.0, ...};
new Float:g_fLastKillTime[MAXPLAYERS_INS+1] = {0.0, ...};
//new Float:g_fHeartBeatTime[MAXPLAYERS_INS+1] = {0.0, ...};
new Handle:g_hFFTimer[MAXPLAYERS_INS+1] = {INVALID_HANDLE, ...};
new Handle:g_hYellTimer[MAXPLAYERS_INS+1] = {INVALID_HANDLE, ...};
new Handle:g_hSuppressTimer[MAXPLAYERS_INS+1] = {INVALID_HANDLE, ...};
new g_iLastSpecTarget[MAXPLAYERS_INS+1] = {-1, ...};
new g_iCustomFlagIndex[MAXPLAYERS_INS+1] = {INVALID_ENT_REFERENCE, ...};
new g_iPlayerHealthkitDeploy[MAXPLAYERS_INS+1] = {-1, ...};
new Float:g_fPlayerHealthkitBandaging[MAXPLAYERS_INS+1] = {0.0, ...};
new g_iPlayerHealthkitTarget[MAXPLAYERS_INS+1] = {-1, ...};
new g_iPlayerHealthkitHealingBy[MAXPLAYERS_INS+1] = {-1, ...};
new Float:g_fPlayerDeathFadeOutNextTime[MAXPLAYERS_INS+1] = {0.0, ...};
new g_iPlayerLastKnife[MAXPLAYERS_INS+1] = {-1, ...};
new Float:g_fPlayerWeaponBlocked[MAXPLAYERS_INS+1] = {0.0, ...};
new Float:g_fLastMedicCall[MAXPLAYERS_INS+1] = {0.0, ...};
new Float:g_fLastHealingTime[MAXPLAYERS_INS+1] = {0.0, ...};
new g_iLastHealTarget[MAXPLAYERS_INS+1] = {-1, ...};
new g_iPlayerInfected[MAXPLAYERS_INS+1] = {0, ...};
new Float:g_fNextInfection[MAXPLAYERS_INS+1] = {0.0, ...};
new Float:g_fDeathOrigin[MAXPLAYERS_INS+1][3];
new g_iAttachedParticleRef[MAXPLAYERS_INS+1] = {INVALID_ENT_REFERENCE, ...};
//new g_iPlayerHasHelmet[MAXPLAYERS_INS+1] = {0, ...};
new g_iZombieBurnSound[MAXPLAYERS_INS+1]  = {0, ...};
new g_iPlayerArmor[MAXPLAYERS_INS+1] = {0, ...};
new g_iPlayerLastHP[MAXPLAYERS_INS+1] = {100, ...};
new g_iPlayerBonusScore[MAXPLAYERS_INS+1] = {0, ...};
new Float:g_fPlayerLastChat[MAXPLAYERS_INS+1] = {0.0, ...};
new Float:g_fPlayerLastLeaped[MAXPLAYERS_INS+1] = {0.0, ...};
new Float:g_fPlayerLastSteped[MAXPLAYERS_INS+1] = {0.0, ...};
new g_iPlayerStance[MAXPLAYERS_INS+1] = {0, ...};

// Player flags
new g_iPLFBuyzone[MAXPLAYERS_INS+1] = {INVALID_ENT_REFERENCE, ...};	//	INVALID_ENT_REFERENCE = off, entity ref = always in buyzone, otherwise disable buyzone and spawnzone flags
new g_iPLFBlockzone[MAXPLAYERS_INS+1] = {0, ...};	//	0 = normal, 1 = block zone

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	Format(gameDesc, sizeof(gameDesc), "%s v%s", GAMEDESC, PLUGIN_VERSION);
	return Plugin_Changed;
}

public OnPluginStart()
{
	CreateConVar(GAMEDESC, PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	g_hCvarUAVCounts = CreateConVar("UAV_Counts", "15", "Counts of UAV, 1 time = 2.4s", FCVAR_PLUGIN, true, 1.0);

//	RegAdminCmd("sm_st", Command_SpawnTest, ADMFLAG_SLAY, "sm_st <#userid|name>");
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_SLAY, "sm_respawn <#userid|name>");
	RegAdminCmd("sm_zclass", Command_SetZombieClass, ADMFLAG_ROOT, "sm_zclass <#userid|name>");
	RegAdminCmd("pt", Command_Particle, ADMFLAG_SLAY, "pt <particle>");
	RegAdminCmd("cvar", Command_SetVar, ADMFLAG_ROOT, "cvar <var> <value>");
	RegAdminCmd("debugitem", Command_DebugItem, ADMFLAG_ROOT, "Debugging");
	RegAdminCmd("sm_setgear", Command_SetGear, ADMFLAG_ROOT, "Set Gear");
	RegAdminCmd("sm_locktest", Command_LockTest, ADMFLAG_ROOT, "Set Gear");
	RegAdminCmd("gp", Command_GetPos, ADMFLAG_ROOT, "GetPos");
	RegAdminCmd("setbody", Command_SetBody, ADMFLAG_ROOT, "Set Body");
	RegAdminCmd("setskin", Command_SetSkin, ADMFLAG_ROOT, "Set Skin");
	RegAdminCmd("h", Command_HeliTest, ADMFLAG_ROOT, "Heli Test");
//	RegConsoleCmd("insradial", Command_Radial);
	RegConsoleCmd("kill", Command_Blocked);
	RegConsoleCmd("inventory_sell_all", Command_Inventory_Sell_All);
	RegConsoleCmd("inventory_sell_gear", Command_Inventory_Sell_Gear);
	RegConsoleCmd("say_team", Command_TeamSay);

	AddNormalSoundHook(NormalSHook:NormalSoundHook);
	AddGameLogHook(Event_GameLog);

	HookEvent("controlpoint_starttouch", Event_Catpurezone_Enter);
	HookEvent("controlpoint_endtouch", Event_Catpurezone_Exit);
	HookEvent("teamplay_broadcast_audio", Event_BroadcastAudio, EventHookMode_Pre);
	HookEvent("controlpoint_captured", Event_ObjectReached, EventHookMode_Post);
	HookEvent("object_destroyed", Event_ObjectReached, EventHookMode_Post);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_timer_changed", Event_RoundTimerChanged);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("player_activate", Event_PlayerActivate);
	HookEvent("player_pick_squad", Event_PlayerPickSquad, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_suppressed", Event_PlayerSuppressed);
	HookEvent("player_say", Event_PlayerSay);
	HookEvent("player_blind", Event_PlayerBlind, EventHookMode_Post);
	HookEvent("grenade_thrown", Event_ExplosiveDeployed);
	HookEvent("missile_launched", Event_ExplosiveDeployed);
	HookEvent("grenade_detonate", Event_GrenadeDetonate, EventHookMode_Post);
	HookEvent("missile_detonate", Event_MissileDetonate, EventHookMode_Post);
	HookEvent("flag_pickup", Event_FlagPickUp);
	HookEvent("flag_drop", Event_FlagDrop);
	HookEvent("weapon_deploy", Event_WeaponDeploy, EventHookMode_Pre);
	HookEvent("weapon_holster", Event_WeaponHolster, EventHookMode_Post);

	g_hGameConfig = LoadGameConfigFile("insurgency.games");
	if (g_hGameConfig == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Unable to find \"insurgency.games.txt\"!");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Signature, "ForceRespawn");
	g_hPlayerRespawn = EndPrepSDKCall();
	if (g_hPlayerRespawn == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Unable to find signature for \"ForceRespawn\"!");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Signature, "ForceChangeTeam");
//	PrepSDKCall_SetVirtual(418);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // team
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain); // unknown bool
	g_hPlayerForceChangeTeam = EndPrepSDKCall();
	if (g_hPlayerForceChangeTeam == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Unable to find signature for \"ForceChangeTeam\"!");
	}
	g_iOffsetWaterlevel	= FindSendPropInfo("CBasePlayer", "m_nWaterLevel");
	if (g_iOffsetWaterlevel == -1)
		LogError("Offset Error: Unable to find Offset for \"m_nWaterLevel\"");

	g_iOffsetWeaponCacheGlow = FindSendPropInfo("CObjWeaponCache", "m_bGlowEnabled");
	if (g_iOffsetWeaponCacheGlow == -1)
		LogError("Offset Error: Unable to find Offset for \"CObjWeaponCache\" for \"m_bGlowEnabled\"");

	g_iOffsetCPNumbers = FindSendPropOffs("CINSObjectiveResource", "m_iNumControlPoints");
	if (g_iOffsetCPNumbers == -1)
		LogError("Offset Error: Unable to find Offset for \"m_iNumControlPoints\"");

	g_iOffsetCPIndex = FindSendPropOffs("CINSObjectiveResource", "m_nActivePushPointIndex");
	if (g_iOffsetCPIndex == -1)
		LogError("Offset Error: Unable to find Offset for \"m_nActivePushPointIndex\"");

	g_iOffsetCPType = FindSendPropOffs("CINSObjectiveResource", "m_iObjectType");
	if (g_iOffsetCPType == -1)
		LogError("Offset Error: Unable to find Offset for \"m_iObjectType\"");

	g_iOffsetCPPositions = FindSendPropOffs("CINSObjectiveResource", "m_vCPPositions");
	if (g_iOffsetCPPositions == -1)
		LogError("Offset Error: Unable to find Offset for \"m_vCPPositions\"");

	g_iOffsetSquad = FindSendPropOffs("CINSPlayerResource", "m_iSquad");
	if (g_iOffsetSquad == -1)
		LogError("Offset Error: Unable to find Offset for \"m_iSquad\"");

	g_iOffsetSquadSlot = FindSendPropOffs("CINSPlayerResource", "m_iSquadSlot");
	if (g_iOffsetSquadSlot == -1)
		LogError("Offset Error: Unable to find Offset for \"m_iSquadSlot\"");

	g_iOffsetDeployTimer = FindSendPropInfo("CINSWeaponBallistic", "m_DeployTimer");
	if (g_iOffsetDeployTimer == -1)
		LogError("Offset Error: Unable to find Offset for \"m_DeployTimer\"");
	else g_iOffsetDeployTimer += 8;

	g_iOffsetGears = FindSendPropOffs("CINSPlayer", "m_iMyGear");
	if (g_iOffsetGears == -1)
		LogError("Offset Error: Unable to find Offset for \"m_iMyGear\"");

	g_iOffsetChamberRound = FindSendPropInfo("CINSWeaponBallistic", "m_bChamberedRound");
	if (g_iOffsetChamberRound == -1)
		LogError("Offset Error: Unable to find Offset for \"m_bChamberedRound\"");

	g_iOffsetMyWeapons = FindSendPropOffs("CINSPlayer", "m_hMyWeapons");
	if (g_iOffsetMyWeapons == -1)
		LogError("Offset Error: Unable to find Offset for \"m_hMyWeapons\"");

	g_iOffsetScore = FindSendPropOffs("CINSPlayerResource", "m_iPlayerScore");
	if (g_iOffsetScore == -1)
		LogError("Offset Error: Unable to find Offset for \"m_iPlayerScore\"");
/*
	g_iOffsetAssists = FindSendPropOffs("CINSPlayerResource", "m_iAssists");
	if (g_iOffsetAssists == -1)
		LogError("Offset Error: Unable to find Offset for \"m_iAssists\"");	*/

	g_iOffsetFirstDeploy = FindSendPropInfo("CINSWeaponBallistic", "m_bFirstDeploy");
	if (g_iOffsetFirstDeploy == -1)
		LogError("Offset Error: Unable to find Offset for \"m_bFirstDeploy\"");


	g_hCvarBotCount = FindConVar("ins_bot_count_checkpoint");
	if (g_hCvarBotCount == INVALID_HANDLE)
		LogError("Couldn't find \"ins_bot_count_checkpoint\" convar to use!");

	g_hCvarBotLevel = FindConVar("ins_bot_difficulty");
	if (g_hCvarBotLevel == INVALID_HANDLE)
		LogError("Couldn't find \"ins_bot_difficulty\" convar to use!");
	else
	{
		new flags = GetConVarFlags(g_hCvarBotLevel);
		if (flags & FCVAR_NOTIFY)
			SetConVarFlags(g_hCvarBotLevel, flags^FCVAR_NOTIFY);
	}

	g_hCvarLobbySize = FindConVar("mp_coop_lobbysize");
	if (g_hCvarLobbySize == INVALID_HANDLE)
		LogError("Couldn't find \"mp_coop_lobbysize\" convar to use!");

	g_hCvarAlwaysCounterAttack = FindConVar("mp_checkpoint_counterattack_always");
	if (g_hCvarAlwaysCounterAttack == INVALID_HANDLE)
		LogError("Couldn't find \"mp_checkpoint_counterattack_always\" convar to use!");

	g_hCvarCounterAttackDelay = FindConVar("mp_checkpoint_counterattack_delay");
	if (g_hCvarCounterAttackDelay == INVALID_HANDLE)
		SetFailState("Couldn't find \"mp_checkpoint_counterattack_delay\" convar to use!");

	g_hFcvarCounterAttackTime = FindConVar("mp_checkpoint_counterattack_duration");
	if (g_hFcvarCounterAttackTime == INVALID_HANDLE)
		SetFailState("Couldn't find \"mp_checkpoint_counterattack_duration\" convar to use!");

	g_hCvarFinalCounterAttackDelay = FindConVar("mp_checkpoint_counterattack_delay_finale");
	if (g_hCvarFinalCounterAttackDelay == INVALID_HANDLE)
		SetFailState("Couldn't find \"mp_checkpoint_counterattack_delay_finale\" convar to use!");

/*	g_hFcvarFinalCounterAttackTime = FindConVar("mp_checkpoint_counterattack_duration_finale");
	if (g_hFcvarFinalCounterAttackTime == INVALID_HANDLE)
		SetFailState("Couldn't find \"mp_checkpoint_counterattack_duration_finale\" convar to use!");	*/

//	HookConVarChange(g_hCvarUAVCounts, ConVarChanged);
	LoadTranslations("common.phrases");
}

public Action:NormalSoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (entity > 0 && entity <= MaxClients)
	{
		if (IsClientInGame(entity) && GetClientTeam(entity) == TEAM_ZOMBIES)
		{
			// Zombies
			// if (StrContains(sample, "footsteps", false) == -1 && StrContains(sample, "null", false) == -1 && StrContains(sample, "jumpland", false) == -1 && StrContains(sample, "weapons", false) == -1 && StrContains(sample, "universal", false) == -1)
				// PrintToChatAll("%N - %s", entity, sample);
			if (StrContains(sample, "footsteps", false) != -1 || StrContains(sample, "jumpland", false) != -1)
			{
				// Footsteps or Jump'd @ SNDCHAN_BODY
				// jumpland/jump @ jumping, jumpland/land @ landed
				if (g_iZombieClass[entity][VAR] == 1)
				{
					g_iZombieClass[entity][VAR] = 0;
					g_fPlayerLastLeaped[entity] = g_fGameTime;
				}
				if (g_iZombieClass[entity][CLASS] == ZOMBIE_SMOKER_INDEX)
				{
					g_fGameTime = GetGameTime();
					if (g_fFootstepEffect[entity] <= g_fGameTime)
					{
						g_fFootstepEffect[entity] = g_fGameTime+1.5;
						TE_SetupParticleEffect("smokegrenade_spray_b", PATTACH_WORLDORIGIN, entity);
						TE_SendToAll();
					}
				}
				else if (g_iZombieClass[entity][CLASS] == ZOMBIE_BURNER_INDEX)
				{
					g_fGameTime = GetGameTime();
					if (g_fFootstepEffect[entity] <= g_fGameTime)
					{
						g_fFootstepEffect[entity] = g_fGameTime+2.2;
						TE_SetupParticleEffect("molotov_trail", PATTACH_WORLDORIGIN, entity);
						TE_SendToAll();
					}
				}
				return Plugin_Continue;
			}
			else if (g_iZombieBurnSound[entity] > 0 || (g_iZombieClass[entity][CLASS] == ZOMBIE_IED_INDEX && g_iZombieClass[entity][VAR] < -1 && StrContains(sample, "/ied/", false) == -1))
			{
				if (StrContains(sample, "moan_loop", false) == -1)
					return Plugin_Handled;
			}
			else if (StrContains(sample, "voice/responses", false) != -1)
			{
				decl String:scream_sound[128];
				if (StrContains(sample, "explosion_near", false) == -1)
				{
					switch(g_iZombieClass[entity][CLASS])
					{
						case ZOMBIE_CLASSIC_INDEX, ZOMBIE_KNIGHT_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/classic/zombie_voice_idle%d.wav", GetRandomInt(1, 14));
						case ZOMBIE_STALKER_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/stalker/idle%d.wav", GetRandomInt(1, 3));
						case ZOMBIE_IED_INDEX:		Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/ied/zombine_idle%d.wav", GetRandomInt(1, 4));
						case ZOMBIE_LEAPER_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/fast/%s.wav", GetRandomInt(0, 1) == 0?"fz_alert_close1":"fz_frenzy1");
						default:					Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/common/alert%d.ogg", GetRandomInt(1, 2));
					}
				}
				else
				{
					switch(g_iZombieClass[entity][CLASS])
					{
						case ZOMBIE_CLASSIC_INDEX, ZOMBIE_KNIGHT_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/classic/zombie_alert%d.wav", GetRandomInt(1, 3));
						case ZOMBIE_STALKER_INDEX:	scream_sound = "Lua_sounds/zombiehorde/zombies/stalker/alert1.wav";
						case ZOMBIE_IED_INDEX:		Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/ied/zombine_alert%d.wav", GetRandomInt(1, 7));
						case ZOMBIE_LEAPER_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/fast/%s.wav", GetRandomInt(0, 1) == 0?"fz_alert_close1":"fz_frenzy1");
						default:					Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/common/scream%d.ogg", GetRandomInt(1, 4));
					}
				}
				EmitSoundToAll(scream_sound, entity, SNDCHAN_VOICE, _, _, 1.0);
				return Plugin_Handled;
			}
			else if (StrContains(sample, "voice/radial", false) != -1)
			{
				decl String:scream_sound[128];
				switch(g_iZombieClass[entity][CLASS])
				{
					case ZOMBIE_CLASSIC_INDEX, ZOMBIE_KNIGHT_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/classic/zombie_alert%d.wav", GetRandomInt(1, 3));
					case ZOMBIE_STALKER_INDEX:	scream_sound = "Lua_sounds/zombiehorde/zombies/stalker/alert1.wav";
					case ZOMBIE_IED_INDEX:		Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/ied/zombine_alert%d.wav", GetRandomInt(1, 7));
					case ZOMBIE_LEAPER_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/fast/%s.wav", GetRandomInt(0, 1) == 0?"fz_alert_close1":"fz_frenzy1");
					default:					Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/common/scream%d.ogg", GetRandomInt(1, 4));
				}
				EmitSoundToAll(scream_sound, entity, SNDCHAN_VOICE, _, _, 1.0);
				return Plugin_Handled;
			}
			else if (StrContains(sample, "player/voice/insurgents/command", false) != -1)
			{
				decl String:scream_sound[128];
				switch(g_iZombieClass[entity][CLASS])
				{
					case ZOMBIE_CLASSIC_INDEX, ZOMBIE_KNIGHT_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/classic/zombie_alert%d.wav", GetRandomInt(1, 3));
					case ZOMBIE_STALKER_INDEX:	scream_sound = "Lua_sounds/zombiehorde/zombies/stalker/alert1.wav";
					case ZOMBIE_IED_INDEX:		Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/ied/zombine_alert%d.wav", GetRandomInt(1, 7));
					case ZOMBIE_LEAPER_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/fast/%s.wav", GetRandomInt(0, 1) == 0?"fz_alert_close1":"fz_frenzy1");
					default:					Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/common/scream%d.ogg", GetRandomInt(1, 4));
				}
				EmitSoundToAll(scream_sound, entity, SNDCHAN_VOICE, _, _, 1.0);
				return Plugin_Handled;
			}
			else if (StrContains(sample, "player/voice/bot", false) != -1)
			{
				decl String:scream_sound[128];
				if (StrContains(sample, "idle", false) == -1)
				{
					switch(g_iZombieClass[entity][CLASS])
					{
						case ZOMBIE_CLASSIC_INDEX, ZOMBIE_KNIGHT_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/classic/zombie_alert%d.wav", GetRandomInt(1, 3));
						case ZOMBIE_STALKER_INDEX:	scream_sound = "Lua_sounds/zombiehorde/zombies/stalker/alert1.wav";
						case ZOMBIE_IED_INDEX:		Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/ied/zombine_alert%d.wav", GetRandomInt(1, 7));
						case ZOMBIE_LEAPER_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/fast/%s.wav", GetRandomInt(0, 1) == 0?"fz_alert_close1":"fz_frenzy1");
						default:					Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/common/scream%d.ogg", GetRandomInt(1, 4));
					}
				}
				else
				{
					switch(g_iZombieClass[entity][CLASS])
					{
						case ZOMBIE_CLASSIC_INDEX, ZOMBIE_KNIGHT_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/classic/zombie_voice_idle%d.wav", GetRandomInt(1, 14));
						case ZOMBIE_STALKER_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/stalker/idle%d.wav", GetRandomInt(1, 3));
						case ZOMBIE_IED_INDEX:		Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/ied/zombine_idle%d.wav", GetRandomInt(1, 4));
						case ZOMBIE_LEAPER_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/fast/%s.wav", GetRandomInt(0, 1) == 0?"fz_alert_close1":"fz_frenzy1");
						default:					Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/common/alert%d.ogg", GetRandomInt(1, 2));
					}
				}
				EmitSoundToAll(scream_sound, entity, SNDCHAN_VOICE, _, _, 1.0);
				return Plugin_Handled;
			}
			else if (StrContains(sample, "knife_slash", false) != -1)
			{
				decl String:scream_sound[128];
				switch(g_iZombieClass[entity][CLASS])
				{
					case ZOMBIE_CLASSIC_INDEX, ZOMBIE_KNIGHT_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/classic/claw_strike%d.wav", GetRandomInt(1, 3));
					case ZOMBIE_STALKER_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/stalker/attack%d.wav", GetRandomInt(1, 3));
//					case ZOMBIE_IED_INDEX:		Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/ied/   %d.wav", GetRandomInt(1, 2));
					default:					scream_sound = "Lua_sounds/zombiehorde/zombies/common/attack1.ogg";
				}
				EmitSoundToAll(scream_sound, entity, SNDCHAN_WEAPON, _, _, 1.0);
				return Plugin_Handled;
			}
			else if (StrContains(sample, "pl_deathshout", false) != -1 || StrContains(sample, "headshot_tp", false) != -1 || StrContains(sample, "headshot_helmet_tp", false) != -1)
			{
				decl String:scream_sound[128];
				switch(g_iZombieClass[entity][CLASS])
				{
					case ZOMBIE_CLASSIC_INDEX, ZOMBIE_KNIGHT_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/classic/zombie_die%d.wav", GetRandomInt(1, 3));
					case ZOMBIE_STALKER_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/stalker/die%d.wav", GetRandomInt(1, 2));
					case ZOMBIE_IED_INDEX:		Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/ied/zombine_die%d.wav", GetRandomInt(1, 2));
					default:					Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/common/die%d.ogg", GetRandomInt(1, 2));
				}
				EmitSoundToAll(scream_sound, entity, SNDCHAN_STATIC, _, _, 1.0);
				return (StrContains(sample, "headshot", false) == -1)?Plugin_Handled:Plugin_Continue;
			}
			else if (StrContains(sample, "pl_damage", false) != -1 || StrContains(sample, "suppressed/", false) != -1 || StrContains(sample, "damage/", false) != -1)
			{
				decl String:scream_sound[128];
				switch(g_iZombieClass[entity][CLASS])
				{
					case ZOMBIE_CLASSIC_INDEX, ZOMBIE_KNIGHT_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/classic/zombie_pain%d.wav", GetRandomInt(1, 6));
					case ZOMBIE_STALKER_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/stalker/pain%d.wav", GetRandomInt(1, 3));
					case ZOMBIE_IED_INDEX:		Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/ied/zombine_pain%d.wav", GetRandomInt(1, 4));
					default:					Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/common/pain%d.ogg", GetRandomInt(1, 3));
				}
				EmitSoundToAll(scream_sound, entity, SNDCHAN_VOICE, _, _, 1.0);
				return Plugin_Handled;
			}
		}
//		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_Blocked(client, args)
{
	if (!g_bUpdatedSpawnPoint) return Plugin_Handled;
	return Plugin_Continue;
}

public Action:Command_Inventory_Sell_All(client, args)
{
	if (client <= 0) return Plugin_Continue;
//	ClientCommand(client, "play ui/sfx/noise_04.wav");
	if (g_bMedicPlayer[client])
		CreateTimer(float(GetEntProp(g_iPlayerResource, Prop_Send, "m_iPing", _, client))/1000.0, Timer_SetFirstAid, client, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:Timer_SetFirstAid(Handle:timer, any:client)
{
	if (IsClientInGame(client))
		FakeClientCommand(client, "inventory_buy_gear 8");
}

public Action:Command_Inventory_Sell_Gear(client, args)
{
	if (client <= 0 || args < 1) return Plugin_Continue;
//	ClientCommand(client, "play ui/sfx/noise_04.wav");
	new String:sCmd[512];
	GetCmdArg(1, sCmd, sizeof(sCmd));
	new iGear = StringToInt(sCmd);
	if (iGear == 8 && g_bMedicPlayer[client])
	{
		if (GetRandomInt(0, 3) != 0)
			ClientCommand(client, "playgamesound Radial_Security.Subordinate_%s_Negative_Radio", GetRandomInt(0, 3) != 0 ? "UnSupp" : "Supp");
		else
			ClientCommand(client, "playgamesound Radial_Security.Leader_%s_Negative_Radio", GetRandomInt(0, 3) != 0 ? "UnSupp" : "Supp");
		return Plugin_Handled;
	}
	else if (iGear >= 14 && iGear <= 21)
	{
		if (GetRandomInt(0, 3) != 0)
			ClientCommand(client, "playgamesound Radial_Security.Subordinate_%s_Negative_Radio", GetRandomInt(0, 3) != 0 ? "UnSupp" : "Supp");
		else
			ClientCommand(client, "playgamesound Radial_Security.Leader_%s_Negative_Radio", GetRandomInt(0, 3) != 0 ? "UnSupp" : "Supp");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

//new bool:g_bIgnoreFirstRoundStart = false;
public Action:HQAudioHook(UserMsg:MsgId, Handle:hBitBuffer, const iPlayers[], iNumPlayers, bool:bReliable, bool:bInit)
{
	return Plugin_Handled;
/*	decl String:event_name[256]="";
	new curbyte;
	while(BfGetNumBytesLeft(hBitBuffer))
	{
		curbyte = BfReadByte(hBitBuffer);
//		if (!IsCharAlpha(curbyte) || !IsCharAlpha(curbyte) || IsCharSpace(curbyte))
//			continue;
//		Format(strRest, sizeof(strRest), "%s%d", strRest, curbyte);
		Format(event_name, sizeof(event_name), "%s%c", event_name, curbyte); 
	}
//	LogToGame("%s", event_name);
	if (StrContains(event_name, "CounterAttackCoOp", false) != -1 || StrContains(event_name, "Restrict", false) != -1)
	{
		return Plugin_Handled;
	}
	else if (!g_bIgnoreFirstRoundStart && StrContains(event_name, "StartCoOp_Game", false) != -1)
	{
		g_bIgnoreFirstRoundStart = true;
		return Plugin_Handled;
	}
	//HQAudio - USERMSGHOOK: CounterAttackCoOp_End?
	//HQAudio - USERMSGHOOK: CounterAttackCoOp_Start@@
	//StartCoOp_Game (?)
	//StartCoOp_Round
	//CounterAttackCoOp_Start
	return Plugin_Continue;	*/
}

public Action:HQAudioHookNight(UserMsg:MsgId, Handle:hBitBuffer, const iPlayers[], iNumPlayers, bool:bReliable, bool:bInit)
{
	decl String:event_name[256]="";
	new curbyte;
	while(BfGetNumBytesLeft(hBitBuffer))
	{
		curbyte = BfReadByte(hBitBuffer);
		Format(event_name, sizeof(event_name), "%s%c", event_name, curbyte); 
	}
	if (StrContains(event_name, "StartCoOp_Round", false) != -1)
	{
		decl String:sSoundFile[128];
		Format(sSoundFile, sizeof(sSoundFile), "hq/outpost/outpost_roundstart%d_night.ogg", GetRandomInt(1, 13));
		PlayGameSoundToAll(sSoundFile);
		UnhookUserMessage(GetUserMessageId("HQAudio"), HQAudioHookNight, true);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnPluginEnd()
{
	if (g_iGameState == 4)
	{
		for (new client = 1;client <= MaxClients;client++)
		{
			if (!IsClientInGame(client)) continue;
	//		if (g_iPointFlag != INVALID_ENT_REFERENCE && g_iPointFlagOwner == client)
	//		{
	//			AcceptEntityInput(g_iPointFlag, "Kill"); // Should killed on while loop
	//			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	//		}
			if (IsPlayerAlive(client))
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		}
		new ent = MaxClients+1;
		while ((ent = FindEntityByClassname(ent, "point_flag")) != -1)
		{
			LogToGame("Plugin Unload - Point Flag %d (%d) has been killed", EntIndexToEntRef(ent), ent);
			decl Float:vPos[3];
			GetEntPropVector(g_iCPIndex[g_iCurrentControlPoint], Prop_Data, "m_vecAbsOrigin", vPos);
			SetEntData(g_iCPIndex[g_iCurrentControlPoint], g_iOffsetWeaponCacheGlow, 0);
			vPos[2] += 2000.0;
			TeleportEntity(g_iCPIndex[g_iCurrentControlPoint], vPos, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(ent, "Kill");
			if (g_iPointFlagSpawnGlow != INVALID_ENT_REFERENCE && IsValidEntity(g_iPointFlagSpawnGlow) && EntRefToEntIndex(g_iPointFlagSpawnGlow) > MaxClients)
				AcceptEntityInput(g_iPointFlagSpawnGlow, "Kill");
			break;
		}
		for (new i = MaxClients+1;i < GetMaxEntities();i++)
		{
			if (i != INVALID_ENT_REFERENCE && IsValidEntity(i))
			{
				decl String:sClassName[64];
				GetEntityClassname(i, sClassName, 64);
				if (StrEqual(sClassName, "CACHE (FLAME)", true))
				{
					LogToGame("%d. \"CACHE (FLAME)\" has been removed", i); 
					AcceptEntityInput(i, "Kill");
				}
				else if (StrEqual(sClassName, "CACHE (AMMO)", true))
				{
					LogToGame("%d. \"CACHE (AMMO)\" has been removed", i); 
					AcceptEntityInput(i, "Kill");
				}
				else if (StrEqual(sClassName, "LuaTempParticle", true))
				{
					LogToGame("%d. used \"info_particle_system (LuaTempParticle)\" has been removed", i);
					AcceptEntityInput(i, "Kill");
				}
				// else if (StrEqual(sClassName, "info_particle_system", false))
				// {
					// LogToGame("%d. used \"info_particle_system\" has been removed", i);
					// AcceptEntityInput(i, "Kill");
				// }
				else if (StrEqual(sClassName, "prop_dynamic_override", false))
				{
					GetEntPropString(i, Prop_Data, "m_iName", sClassName, sizeof(sClassName));
					if (StrEqual(sClassName, "LuaCustomFlag", true) || StrEqual(sClassName, "LuaCustomModel", true) || StrEqual(sClassName, "LuaCustomHeli", true))
					{
						LogToGame("%s has been killed for plugin unload (Index: %d (%d))", sClassName, i, EntIndexToEntRef(i));
						AcceptEntityInput(i, "Kill");
					}
				}
			}
		}
	}
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
//	if (cvar == g_hCvarUAVCounts)
//		g_iCvarUAVCount = StringToInt(newVal);
}

public Action:Command_SetZombieClass(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_zclass <#userid|name> <class index>");
		return Plugin_Handled;
	}

	new String:arg[65];
	new String:arg2[24];
	new zclass = 0;
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
	zclass = StringToInt(arg2);

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(
						arg,
						client,
						target_list,
						MaxClients,
						COMMAND_FILTER_ALIVE,
						target_name,
						sizeof(target_name),
						tn_is_ml);

	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	// Team filter dead players, re-order target_list array with new_target_count
	new target, team, new_target_count;

	for (new i = 0; i < target_count; i++)
	{
		target = target_list[i];
		team = GetClientTeam(target);

		if (team == TEAM_ZOMBIES)
		{
			target_list[new_target_count] = target; // re-order
			new_target_count++;
		}
	}

	if(new_target_count == COMMAND_TARGET_NONE) // No dead players from  team 2 and 3
	{
		ReplyToTargetError(client, new_target_count);
		return Plugin_Handled;
	}

	target_count = new_target_count; // re-set new value.
	ShowActivity2(client, "[SM] Set Zombie class ", target_name);
	for (new i = 0; i < target_count; i++)
	{
		LogAction(client, target_list[i], "\"%L\" set zombie class %d to \"%L\"", client, zclass, target_list[i]);
		ZH_SetZombieClass(target_list[i], zclass);
		CreateTimer(0.1, Timer_BotSpawn, target_list[i], TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Handled;
}

public Action:Command_Respawn(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_respawn <#userid|name> [force spawn 0/1]");
		return Plugin_Handled;
	}

	new String:arg[65];
	new String:arg2[24];
	new force = 0;
	GetCmdArg(1, arg, sizeof(arg));
	if (args > 1){
		GetCmdArg(2, arg2, sizeof(arg2));
		force = StringToInt(arg2);
	}

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	if (force == 0){
		target_count = ProcessTargetString(
						arg,
						client,
						target_list,
						MaxClients,
						COMMAND_FILTER_DEAD,
						target_name,
						sizeof(target_name),
						tn_is_ml);
	}
	else{
		target_count = ProcessTargetString(
						arg,
						client,
						target_list,
						MaxClients,
						COMMAND_FILTER_CONNECTED,
						target_name,
						sizeof(target_name),
						tn_is_ml);
	}


	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	// Team filter dead players, re-order target_list array with new_target_count
	new target, team, new_target_count;

	for (new i = 0; i < target_count; i++)
	{
		target = target_list[i];
		team = GetClientTeam(target);

		if(team >= 2)
		{
			target_list[new_target_count] = target; // re-order
			new_target_count++;
		}
	}

	if(new_target_count == COMMAND_TARGET_NONE) // No dead players from  team 2 and 3
	{
		ReplyToTargetError(client, new_target_count);
		return Plugin_Handled;
	}

	target_count = new_target_count; // re-set new value.
	ShowActivity2(client, "[SM] Respawned ", target_name);

	for (new i = 0; i < target_count; i++)
	{
		LogAction(client, target_list[i], "\"%L\" respawned \"%L\"", client, target_list[i]);
		RespawnPlayer(target_list[i], 0);
	}

	return Plugin_Handled;
}

public Action:Command_Particle(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: pt \"Particle Effect Name\" \"Attachment\"");
		return Plugin_Handled;
	}

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	PrecacheParticleEffect(arg);
/*	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	TE_SetupParticleEffect(arg, PATTACH_CUSTOMORIGIN, _, pos);
	TE_SendToAll();	*/
	new particle = CreateEntityByName("info_particle_system");
	if (particle > MaxClients && IsValidEntity(particle))
	{
		SetEntPropEnt(particle, Prop_Data, "m_hOwnerEntity", client);
		DispatchKeyValue(particle, "classname", "LuaTempParticle");
		DispatchKeyValue(particle, "effect_name", arg);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", client, particle, 0);
		GetCmdArg(2, arg, sizeof(arg));
		SetVariantString(arg);
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		DispatchSpawn(particle);
		
		AcceptEntityInput(particle, "start");
		ActivateEntity(particle);
		CreateTimer(9.5, MoveParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(10.0, DeleteParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
	}

	return Plugin_Handled;
}

public Action:Command_Flashlight_Custom(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: pt \"Particle Effect Name\"");
		return Plugin_Handled;
	}

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	PrecacheParticleEffect(arg);
/*	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	TE_SetupParticleEffect(arg, PATTACH_CUSTOMORIGIN, _, pos);
	TE_SendToAll();	*/
	new iWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (iWeapon > MaxClients && IsValidEntity(iWeapon))
	{
		new particle = CreateEntityByName("info_particle_system");
		if (particle > MaxClients && IsValidEntity(particle))
		{
			SetEntPropEnt(particle, Prop_Data, "m_hOwnerEntity", client);
			DispatchKeyValue(particle, "classname", "LuaTempParticle");
			DispatchKeyValue(particle, "effect_name", arg);
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", iWeapon, particle, 0);
//			SetVariantString("primary");
			SetVariantString("muzzle");
			AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
			DispatchSpawn(particle);
			
			AcceptEntityInput(particle, "start");
			ActivateEntity(particle);
//			CreateTimer(10.0, DeleteParticle, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(9.5, MoveParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
			SetVariantString("OnUser1 !self:kill::10.0:1");
			AcceptEntityInput(particle, "AddOutput");
			AcceptEntityInput(particle, "FireUser1");
		}
	}

	return Plugin_Handled;
}

public Action:MoveParticle(Handle:timer, any:ref)
{
	if (ref != INVALID_ENT_REFERENCE && IsValidEntity(ref))
		TeleportEntity(ref, Float:{0.0, 0.0, -4096.0}, NULL_VECTOR, NULL_VECTOR);
}

public Action:Command_DebugItem(client, args)
{
	if (client <= 0) return Plugin_Handled;

	if (IsPlayerAlive(client))
	{
		if (g_iOffsetMyWeapons != -1)
		{
			for (new i = 0;i < 48;i++)
			{
				new refGear = GetEntDataEnt2(client, g_iOffsetMyWeapons+(4*i));
				if (refGear == -1) break;
				decl String:sName[128] = "none";
				GetEntityClassname(refGear, sName, sizeof(sName));
				LogToGame("%N - m_hMyWeapons %d.  %s (index: %d)", client, i, sName, refGear);
				PrintToChat(client, "\x04%N - m_hMyWeapons %d.  %s (index: %d)", client, i, sName, refGear);
			}
		}
		else PrintToChat(client, "Failed to run \"m_hMyWeapons\"");
		
		if (g_iOffsetGears != -1)
		{
			for (new i = 0;i < 7;i++)
			{
				/*
					Light: 1, Heavy: 3, Chest Rig: 5, Chest Carrier: 6, Tactical Carrier: 7, NVG: 8, Primary Sling: 11, Secondary Sling: 12
				*/
				new gearId = GetEntData(client, g_iOffsetGears+(4*i));
				if (gearId == -1) continue;
				decl String:sName[32];
				switch(gearId)
				{
					case 2: sName = "UAV";
					case 3: sName = "Healthkit";
					default: sName = "Unknown";
				}
				LogToGame("%N - m_iMyGear %d. %s (id: %d)", client, i, sName, gearId);
				PrintToChat(client, "m_iMyGear %d. %s (id: %d)", i, sName, gearId);
			}
		}
		else PrintToChat(client, "Failed to run \"m_iMyGear\"");
	}
	return Plugin_Handled;
}

public Action:Command_LockTest(client, args)
{
	if (client <= 0) return Plugin_Handled;
	decl String:slots[24];
	GetCmdArg(1, slots, sizeof(slots));
	new offset = FindSendPropOffs("CINSPlayer", "m_LockedWeaponSlots");
	if (offset != -1)
	{
		for (new i = 0;i < 4;i++)
		{
			new value = GetEntDataEnt2(client, offset+i);
			LogToGame("%N - m_LockedWeaponSlots %d.  %d", client, i, value);
			PrintToChat(client, "\x04%N - m_LockedWeaponSlots %d.  %d", client, i, value);
			SetEntDataEnt2(client, offset+i, 1, true);
		}
	}
	else PrintToChat(client, "Failed to run \"m_LockedWeaponSlots\"");
	return Plugin_Handled;
}

public Action:Command_GetPos(client, args)
{
	if (client <= 0) return Plugin_Handled;
	static count = 0;
	if (args >= 1) count = 0;
	decl Float:vPos[3];
	GetClientAbsOrigin(client, vPos);
	PrintToChat(client, "g_vNextSpawnPoints[%d] = Float:{%0.1f, %0.1f, %0.1f};", count, vPos[0], vPos[1], vPos[2]);
	count += 1;
	return Plugin_Handled;
}

public Action:Command_SetBody(client, args)
{
	if (client <= 0 || !IsPlayerAlive(client)) return Plugin_Handled;
	decl String:number[4];
	GetCmdArg(1, number, sizeof(number));
	new old = GetEntProp(client, Prop_Send, "m_nBody");
	SetEntProp(client, Prop_Send, "m_nBody", StringToInt(number));
	PrintToChat(client, "m_nBody %s (before %d)", number, old);
	return Plugin_Handled;
}

public Action:Command_SetSkin(client, args)
{
	if (client <= 0 || !IsPlayerAlive(client)) return Plugin_Handled;
	decl String:model[256];
	GetCmdArg(1, model, sizeof(model));
	new index = PrecacheModel(model);
	new old = GetEntProp(client, Prop_Send, "m_nModelIndex");
	SetEntProp(client, Prop_Send, "m_nModelIndex", index);
	PrintToChat(client, "m_nModelIndex %s (new %d before %d)", model, index, old);
	return Plugin_Handled;
}

public Action:Timer_HeliEvacPositionStore(Handle:timer)
{
//	if (g_iGameState != 4 || g_iHeliEvacPositionIndex > 23 || g_iHelicopterRef != INVALID_ENT_REFERENCE || g_iCurrentControlPoint != g_iNumControlPoints-1)
	if (g_iGameState != 4 || g_iHeliEvacPositionIndex >= sizeof(g_vHeliEvacPosition)-1 || g_iHelicopterRef != INVALID_ENT_REFERENCE || (g_bCounterAttack && GetRoundTime() <= 55.0))
	{
		LogToGame("Evac Helicopter Position Store Timer Stopped");
		KillTimer(timer);
		return Plugin_Handled;
	}
	
	new Float:vWorldMaxs[3];
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vWorldMaxs);
	for (new client = 1;client <= MaxClients;client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_SURVIVORS)
		{
			new Float:vOrigin[3];
			GetClientHeadOrigin(client, vOrigin, 15.0);
			new Float:fDistance = GetVectorDistance(g_vCPPositions[g_iCurrentControlPoint], vOrigin);
			if (fDistance <= 2000.0)
			{
				new Float:vEndOrigin[3];
				TR_TraceRay(vOrigin, Float:{-90.0, 0.0, 0.0}, MASK_SOLID_BRUSHONLY, RayType_Infinite);
				if(TR_DidHit())
				{
					TR_GetEndPosition(vEndOrigin);
					if (vEndOrigin[2]-vOrigin[2] >= 400.0)
					{
						vEndOrigin[2] += 10.0;
						TR_TraceRay(vEndOrigin, Float:{90.0, 0.0, 0.0}, MASK_SOLID_BRUSHONLY, RayType_Infinite);
						vEndOrigin[2] -= 10.0;
						if(TR_DidHit())
						{
							new Float:vGroundOrigin[3];
							TR_GetEndPosition(vGroundOrigin);
							if (GetVectorDistance(vGroundOrigin, vOrigin) <= 100.0)
							{
								new bool:bPass = false;
								if (g_iHeliEvacPositionIndex >= 0)
								{
									for (new i = 0;i <= g_iHeliEvacPositionIndex;i++)
									{
										new Float:vDummyPos1[3], Float:vDummyPos2[3];
										vDummyPos1[0] = g_vHeliEvacPosition[i][0];
										vDummyPos1[1] = g_vHeliEvacPosition[i][1];
										vDummyPos2[0] = vEndOrigin[0];
										vDummyPos2[1] = vEndOrigin[1];
										if (GetVectorDistance(vDummyPos1, vDummyPos2) <= 200.0)
										{
											bPass = true;
											break;
										}
									}
								}
								if (bPass) continue;
								else
								{
									g_iHeliEvacPositionIndex++;
									g_vHeliEvacPosition[g_iHeliEvacPositionIndex][0] = vEndOrigin[0];
									g_vHeliEvacPosition[g_iHeliEvacPositionIndex][1] = vEndOrigin[1];
									if (vEndOrigin[2] >= vWorldMaxs[2]+100.0 && vWorldMaxs[2] >= vOrigin[2]+400.0)
										vEndOrigin[2] = GetRandomFloat(vWorldMaxs[2], vEndOrigin[2]);
									g_vHeliEvacPosition[g_iHeliEvacPositionIndex][2] = vEndOrigin[2];
									LogToGame("Evac Position %d.  %0.1f, %0.1f, %0.1f", g_iHeliEvacPositionIndex+1, g_vHeliEvacPosition[g_iHeliEvacPositionIndex][0], g_vHeliEvacPosition[g_iHeliEvacPositionIndex][1], g_vHeliEvacPosition[g_iHeliEvacPositionIndex][2]);
									if (g_iHeliEvacPositionIndex >= sizeof(g_vHeliEvacPosition)-1)
									{
										KillTimer(timer);
										return Plugin_Handled;
									}
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock HelicopterSpawn(Float:position[3] = {0.0, 0.0, 0.0}, Float:angle[3] = {0.0, 0.0, 0.0}, Seq = 11, bool:Reset = false)
{
	if (g_iGameState >= 3 && g_iGameState <= 5)
	{
		new Float:vPos[3], Float:vAngle[3];
		if (Seq < 0 || Seq > 13)
		{
			LogError("Helicopter %d (%d) failed with Sequence %d, invalid Sequence", EntRefToEntIndex(g_iHelicopterRef), g_iHelicopterRef, Seq);
			return -1;
		}
		if (g_iHelicopterRef != INVALID_ENT_REFERENCE && IsValidEntity(g_iHelicopterRef) && EntRefToEntIndex(g_iHelicopterRef) > MaxClients)
		{
			if (Reset)
			{
				GetEntPropVector(g_iHelicopterRef, Prop_Data, "m_vecAbsOrigin", vPos);
				GetEntPropVector(g_iHelicopterRef, Prop_Data, "m_angRotation", vAngle);
				if (Seq == 9)
					vAngle[1] -= 195.0;
				else if (Seq == 12 && GetEntProp(g_iHelicopterRef, Prop_Send, "m_nSequence") >= 10)
					vAngle[1] -= 40.0;
			}
			AcceptEntityInput(g_iHelicopterRef, "Kill");
			g_iHelicopterRef = INVALID_ENT_REFERENCE;
		}
		else if (Reset)
		{
			LogError("Reset Helicopter %d (%d) failed with Sequence %d, invalid entity", EntRefToEntIndex(g_iHelicopterRef), g_iHelicopterRef, Seq);
			return -1;
		}

		new iHeli = CreateEntityByName("prop_dynamic_override");
		if (iHeli != -1 && IsValidEntity(iHeli))
		{
			DispatchKeyValue(iHeli, "model", "models/props_vehicles/helicopter_rescue.mdl");
			DispatchKeyValue(iHeli, "targetname", "LuaCustomHeli");
			DispatchKeyValue(iHeli, "spawnflags", "4");
			DispatchSpawn(iHeli);
			ActivateEntity(iHeli);
			SetVariantColor({50, 150, 200, 50});
			AcceptEntityInput(iHeli, "SetGlowColor");
			SetEntProp(iHeli, Prop_Send, "m_bShouldGlow", true);
			SetEntPropFloat(iHeli, Prop_Send, "m_flGlowMaxDist", 2000.0);
			if (Reset)
			{
				TeleportEntity(iHeli, vPos, vAngle, NULL_VECTOR);
				TR_TraceRay(vPos, Float:{90.0, 0.0, 0.0}, MASK_SOLID_BRUSHONLY, RayType_Infinite);
				if (TR_DidHit())
				{
					TR_GetEndPosition(g_vHeliEvacGroundPosition);
					if (TR_GetEntityIndex() == 0) g_vHeliEvacGroundPosition[2] += 48.0;
					else
					{
						new Float:vEntPos[3];
						GetEntPropVector(TR_GetEntityIndex(), Prop_Data, "m_vecAbsOrigin", vEntPos);
						g_vHeliEvacGroundPosition[2] = vEntPos[2]+48.0;
					}
				}
			}
			else
			{
				if (angle[1] == 0.0)
				{
					if (GetRandomInt(0, 1) == 0)	angle[1] = GetRandomFloat(0.0, 180.0);
					else							angle[1] = GetRandomFloat(-180.0, 0.0);
				}
				TeleportEntity(iHeli, position, angle, NULL_VECTOR);
				TR_TraceRay(position, Float:{90.0, 0.0, 0.0}, MASK_SOLID_BRUSHONLY, RayType_Infinite);
				if (TR_DidHit())
				{
					TR_GetEndPosition(g_vHeliEvacGroundPosition);
					if (TR_GetEntityIndex() == 0) g_vHeliEvacGroundPosition[2] += 48.0;
					else
					{
						new Float:vEntPos[3];
						GetEntPropVector(TR_GetEntityIndex(), Prop_Data, "m_vecAbsOrigin", vEntPos);
						g_vHeliEvacGroundPosition[2] = vEntPos[2]+48.0;
					}
				}
			}
//			EmitSoundToAll("Lua_sounds/helicopter/heli_loop1.wav", iHeli, SNDCHAN_AUTO, _, _, 1.0);
			SetEntProp(iHeli, Prop_Send, "m_nSequence", Seq, 2);
			SetEntPropFloat(iHeli, Prop_Send, "m_flPlaybackRate", 1.0);
			g_iHelicopterRef = EntIndexToEntRef(iHeli);
			g_fHeliLastSeqTime = GetGameTime();
			CreateTimer(0.05, Timer_EvacHelicopter, g_iHelicopterRef, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			LogToGame("Evac Helicopter spawned %d (%d) with Sequence %d", iHeli, g_iHelicopterRef, Seq);
			return iHeli;
		}
		else LogError("Spawn Helicopter %d (%d) failed with Sequence %d, invalid entity", EntRefToEntIndex(g_iHelicopterRef), g_iHelicopterRef, Seq);
	}
	return -1;
}

public Action:Command_HeliTest(client, args)
{
	if (client <= 0) return Plugin_Continue;
	decl String:cmd[256];
	GetCmdArg(1, cmd, sizeof(cmd));
	if (StrEqual(cmd, "s"))
	{
		decl Float:vOrigin[3], Float:vAngle[3];
		GetEntPropVector(client, Prop_Data, "m_angRotation", vAngle);
		GetClientHeadOrigin(client, vOrigin, 15.0);
//		vOrigin[2] += 80.0;
		decl Float:vWorldMaxs[3];
		GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vWorldMaxs);
		PrintToChat(client, "world %0.2f", vWorldMaxs[2]);
		TR_TraceRay(vOrigin, Float:{-90.0, 0.0, 0.0}, MASK_SOLID_BRUSHONLY, RayType_Infinite);
		if(TR_DidHit())
		{
			TR_GetEndPosition(vOrigin);
			PrintToChat(client, "hit %0.2f", vOrigin[2]);
			if (vOrigin[2] >= vWorldMaxs[2]+100.0)
			{
				PrintToChatAll("Before Height %0.2f", vOrigin[2]);
				vOrigin[2] = GetRandomFloat(vWorldMaxs[2], vOrigin[2]);
				PrintToChatAll("Rand Height %0.2f", vOrigin[2]);
			}
			HelicopterSpawn(vOrigin, _, 10, false);
		}
	}
	else if (StrEqual(cmd, "ts"))
	{
		if (g_iHeliEvacPositionIndex >= 0)
			HelicopterSpawn(g_vHeliEvacPosition[GetRandomInt(0, g_iHeliEvacPositionIndex)], _, 11, false);
	}
	else if (StrEqual(cmd, "d"))
	{
		if (g_iHelicopterRef != INVALID_ENT_REFERENCE && IsValidEntity(g_iHelicopterRef) && EntRefToEntIndex(g_iHelicopterRef) > MaxClients)
			AcceptEntityInput(g_iHelicopterRef, "Kill");
	}
	else if (StrEqual(cmd, "t"))
	{
		if (g_iHeliEvacPositionIndex == -1)
			CreateTimer(0.5, Timer_HeliEvacPositionStore, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		else PrintToChat(client, "Already on-going (%d)", g_iHeliEvacPositionIndex+1);
	}
	else
	{
		HelicopterSpawn(_, _, StringToInt(cmd), true);
	}
	return Plugin_Continue;
}

public Action:Timer_EvacHelicopter(Handle:timer, any:refentity)
{
	if (refentity == INVALID_ENT_REFERENCE || !IsValidEntity(refentity) || EntRefToEntIndex(refentity) <= MaxClients)
	{
		if (refentity == g_iHelicopterRef) g_iHelicopterRef = INVALID_ENT_REFERENCE;
		StopSoundAll("Lua_sounds/helicopter/heli_loop1.wav", SNDCHAN_STATIC);
//		StopSoundAll("Lua_sounds/helicopter/heli_windy_loop1.wav", SNDCHAN_STATIC);
//		PrintToChatAll("%d invalid ent timer killed", refentity);
		if (g_iHeliEvacParticle != INVALID_ENT_REFERENCE && IsValidEntity(g_iHeliEvacParticle) && EntRefToEntIndex(g_iHeliEvacParticle) > MaxClients)
		{
			AcceptEntityInput(g_iHeliEvacParticle, "Kill");
			g_iHeliEvacParticle = INVALID_ENT_REFERENCE;
		}
		for (new i = 0;i < MAXPLAYER;i++)
		{
			if (g_iPlayersList[i] != -1)
				g_fHeliPlayerLoopSoundVol[g_iPlayersList[i]] = 0.0;
		}
		KillTimer(timer);
		return Plugin_Handled;
	}
	if (g_iGameState != 4 && g_iGameState != 3)
	{
		if (GetEntProp(refentity, Prop_Send, "m_nSequence") != 9)
		{
			g_bHeliEvacStarted = false;
			HelicopterSpawn(_, _, 9, true);
		}
		StopSoundAll("Lua_sounds/helicopter/heli_loop1.wav", SNDCHAN_STATIC);
//		StopSoundAll("Lua_sounds/helicopter/heli_windy_loop1.wav", SNDCHAN_STATIC);
//		PrintToChatAll("%d round end timer killed", refentity);
		for (new i = 0;i < MAXPLAYER;i++)
		{
			if (g_iPlayersList[i] != -1)
				g_fHeliPlayerLoopSoundVol[g_iPlayersList[i]] = 0.0;
		}
		KillTimer(timer);
		return Plugin_Handled;
	}

	g_fGameTime = GetGameTime();
	new Float:vClientOrigin[3], Float:fDistance = 10000.0, Float:fSeqTime = g_fGameTime-g_fHeliLastSeqTime, iSeq = GetEntProp(refentity, Prop_Send, "m_nSequence");
//	GetEntPropVector(refentity, Prop_Data, "m_vecAbsOrigin", vOrigin);
	if (fSeqTime >= 19.0 && iSeq == 10)
	{
		if (GetRandomInt(0, 3) == 1)
		{
//			g_fHeliEvacTime = g_fGameTime+15.0;
			SetEntProp(refentity, Prop_Send, "m_nSequence", 12, 2);
			SetEntPropFloat(refentity, Prop_Send, "m_flPlaybackRate", 1.0);
			iSeq = 12;
			g_fHeliLastSeqTime = g_fGameTime;
			fSeqTime = 0.0;
			new Float:vAngle[3];
			GetEntPropVector(refentity, Prop_Data, "m_angRotation", vAngle);
			vAngle[1] -= 40.0;
			TeleportEntity(refentity, NULL_VECTOR, vAngle, NULL_VECTOR);
		}
		else
		{
//			g_fHeliEvacTime = g_fGameTime+25.0;
			SetEntProp(refentity, Prop_Send, "m_nSequence", 11, 2);
			SetEntPropFloat(refentity, Prop_Send, "m_flPlaybackRate", 1.0);
			iSeq = 11;
			g_fHeliLastSeqTime = g_fGameTime;
			fSeqTime = 0.0;
		}
		g_bHeliEvacStarted = true;
		SetRoundTime(90.0);
		g_fRoundTimeLeft = 90.0;
//		SetTimerPause(true);
//		RequestFrame(RoundTime, 3600.0);
		PrintToChatAll("\x08%s撤离直升机已到达！  \x01请在 \x0490秒内撤离 \x01！", COLOR_GOLD);
//		PrintToChatAll("\x08%sEvac Helicopter Arrived!", COLOR_GOLD);
		PlayGameSoundToAll("Training.Warehouse.Driver.1");
		if (g_iHeliEvacParticle == INVALID_ENT_REFERENCE || !IsValidEntity(g_iHeliEvacParticle) || EntRefToEntIndex(g_iHeliEvacParticle) <= MaxClients)
		{
			new particle = CreateEntityByName("info_particle_system");
			if (particle > MaxClients && IsValidEntity(particle))
			{
				DispatchKeyValue(particle, "classname", "LuaTempParticle");
				DispatchKeyValue(particle, "effect_name", "vol_dust_wide");
				DispatchSpawn(particle);
				AcceptEntityInput(particle, "start");
				ActivateEntity(particle);
				TeleportEntity(particle, g_vHeliEvacGroundPosition, NULL_VECTOR, NULL_VECTOR);
				g_iHeliEvacParticle = EntIndexToEntRef(particle);
			}
			particle = CreateEntityByName("info_particle_system");
			if (particle > MaxClients && IsValidEntity(particle))
			{
				DispatchKeyValue(particle, "classname", "LuaTempParticle");
				DispatchKeyValue(particle, "effect_name", "ins_flaregun_trail");
				SetVariantString("!activator");
				AcceptEntityInput(particle, "SetParent", refentity, particle, 0);
				SetVariantString("port_light");
				AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
				DispatchSpawn(particle);
				AcceptEntityInput(particle, "start");
				ActivateEntity(particle);
				SetVariantString("OnUser1 !self:kill::20.0:1");
				AcceptEntityInput(particle, "AddOutput");
				AcceptEntityInput(particle, "FireUser1");
//				decl Float:vPos[3];
//				GetEntPropVector(refentity, Prop_Data, "m_vecAbsOrigin", vPos);
//				TeleportEntity(particle, vPos, NULL_VECTOR, NULL_VECTOR);
			}
			particle = CreateEntityByName("prop_dynamic_glow");
			if (particle > MaxClients && IsValidEntity(particle))
			{
				DispatchKeyValue(particle, "model", "models/generic/flag_pole_animated.mdl");
				DispatchKeyValue(particle, "modelscale", "0.4");
				DispatchKeyValue(particle, "disablereceiveshadows", "0");
				DispatchKeyValue(particle, "disableshadows", "0");
				DispatchKeyValue(particle, "solid", "0");
				DispatchKeyValue(particle, "spawnflags", "256");
				SetVariantString("idle");
				AcceptEntityInput(particle, "SetAnimation");
				SetVariantString("idle");
				AcceptEntityInput(particle, "SetDefaultAnimation");
				SetEntProp(particle, Prop_Send, "m_CollisionGroup", 11);
				SetEntProp(particle, Prop_Data, "m_nSkin", 2);
				
				// Spawn and teleport the entity
				DispatchSpawn(particle);
				new Float:vGroundOrigin[3];
				new Handle:hTrace = TR_TraceRayFilterEx(g_vHeliEvacGroundPosition, Float:{90.0, 0.0, 0.0}, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, ExcludeSelfAndAlive);
				if (TR_DidHit(hTrace))
					TR_GetEndPosition(vGroundOrigin, hTrace);
				else
				{
					vGroundOrigin[0] = g_vHeliEvacGroundPosition[0];
					vGroundOrigin[1] = g_vHeliEvacGroundPosition[1];
					vGroundOrigin[2] = g_vHeliEvacGroundPosition[2];
				}
				CloseHandle(hTrace);
				TeleportEntity(particle, vGroundOrigin, NULL_VECTOR, NULL_VECTOR);

				// Give glowing effect to the entity
				SetEntProp(particle, Prop_Send, "m_bShouldGlow", true);
				SetEntPropFloat(particle, Prop_Send, "m_flGlowMaxDist", 1000000.0);

				SetVariantColor({30, 255, 66, 255});
				AcceptEntityInput(particle, "SetGlowColor");
				AcceptEntityInput(particle, "TurnOn");
			}
		}
	}
	if (iSeq == 11 || iSeq == 12)
	{
		if (g_bHeliEvacStarted)
		{
			TE_SetupBeamRingPoint(g_vHeliEvacGroundPosition, 499.9, 500.0, g_iSpriteLaser, g_iBeaconHalo, 0, 0, 0.1, 3.0, 0.0, {50, 150, 250, 144}, 1, 0);
			TE_SendToAll();
			g_vHeliEvacGroundPosition[2] += 48.0;
			TE_SetupBeamRingPoint(g_vHeliEvacGroundPosition, 499.9, 500.0, g_iSpriteLaser, g_iBeaconHalo, 0, 0, 0.1, 3.0, 0.0, {50, 150, 250, 144}, 1, 0);
			TE_SendToAll();
			g_vHeliEvacGroundPosition[2] -= 48.0;
		}
		if (g_iHeliEvacParticle == INVALID_ENT_REFERENCE || !IsValidEntity(g_iHeliEvacParticle) || EntRefToEntIndex(g_iHeliEvacParticle) <= MaxClients)
		{
			new particle = CreateEntityByName("info_particle_system");
			if (particle > MaxClients && IsValidEntity(particle))
			{
				DispatchKeyValue(particle, "classname", "LuaTempParticle");
				DispatchKeyValue(particle, "effect_name", "vol_dust_wide");
				DispatchSpawn(particle);
				AcceptEntityInput(particle, "start");
				ActivateEntity(particle);
				TeleportEntity(particle, g_vHeliEvacGroundPosition, NULL_VECTOR, NULL_VECTOR);
				g_iHeliEvacParticle = EntIndexToEntRef(particle);
			}
			particle = CreateEntityByName("info_particle_system");
			if (particle > MaxClients && IsValidEntity(particle))
			{
				DispatchKeyValue(particle, "classname", "LuaTempParticle");
				DispatchKeyValue(particle, "effect_name", "ins_flaregun_trail");
				SetVariantString("!activator");
				AcceptEntityInput(particle, "SetParent", refentity, particle, 0);
				SetVariantString("port_light");
				AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
				DispatchSpawn(particle);
				AcceptEntityInput(particle, "start");
				ActivateEntity(particle);
				SetVariantString("OnUser1 !self:kill::20.0:1");
				AcceptEntityInput(particle, "AddOutput");
				AcceptEntityInput(particle, "FireUser1");
//				decl Float:vPos[3];
//				GetEntPropVector(refentity, Prop_Data, "m_vecAbsOrigin", vPos);
//				TeleportEntity(particle, vPos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
	else if (iSeq == 9)
	{
		if (fSeqTime >= 18.0)
		{
			if (g_fHeliEvacTime == 0.0)
			{
				if (refentity == g_iHelicopterRef) g_iHelicopterRef = INVALID_ENT_REFERENCE;
				AcceptEntityInput(refentity, "Kill");
				g_bHeliEvacStarted = false;
				return Plugin_Continue;
			}
		}
		else if (g_fHeliEvacTime == 0.0 && g_bHeliEvacStarted && fSeqTime <= 4.5)
		{
			TE_SetupBeamRingPoint(g_vHeliEvacGroundPosition, 499.9, 500.0, g_iSpriteLaser, g_iBeaconHalo, 0, 0, 0.1, 3.0, 0.0, {50, 150, 250, 144}, 1, 0);
			TE_SendToAll();
			g_vHeliEvacGroundPosition[2] += 48.0;
			TE_SetupBeamRingPoint(g_vHeliEvacGroundPosition, 499.9, 500.0, g_iSpriteLaser, g_iBeaconHalo, 0, 0, 0.1, 3.0, 0.0, {50, 150, 250, 144}, 1, 0);
			TE_SendToAll();
			g_vHeliEvacGroundPosition[2] -= 48.0;
			if (g_iHeliEvacParticle == INVALID_ENT_REFERENCE || !IsValidEntity(g_iHeliEvacParticle) || EntRefToEntIndex(g_iHeliEvacParticle) <= MaxClients)
			{
				new particle = CreateEntityByName("info_particle_system");
				if (particle > MaxClients && IsValidEntity(particle))
				{
					DispatchKeyValue(particle, "classname", "LuaTempParticle");
					DispatchKeyValue(particle, "effect_name", "vol_dust_wide");
					DispatchSpawn(particle);
					AcceptEntityInput(particle, "start");
					ActivateEntity(particle);
					TeleportEntity(particle, g_vHeliEvacGroundPosition, NULL_VECTOR, NULL_VECTOR);
					g_iHeliEvacParticle = EntIndexToEntRef(particle);
				}
				particle = CreateEntityByName("info_particle_system");
				if (particle > MaxClients && IsValidEntity(particle))
				{
					DispatchKeyValue(particle, "classname", "LuaTempParticle");
					DispatchKeyValue(particle, "effect_name", "ins_flaregun_trail");
					SetVariantString("!activator");
					AcceptEntityInput(particle, "SetParent", refentity, particle, 0);
					SetVariantString("port_light");
					AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
					DispatchSpawn(particle);
					AcceptEntityInput(particle, "start");
					ActivateEntity(particle);
					SetVariantString("OnUser1 !self:kill::20.0:1");
					AcceptEntityInput(particle, "AddOutput");
					AcceptEntityInput(particle, "FireUser1");
	//				decl Float:vPos[3];
	//				GetEntPropVector(refentity, Prop_Data, "m_vecAbsOrigin", vPos);
	//				TeleportEntity(particle, vPos, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
	}
	new iPlayers = 0, iEvacPlayers = 0;
	for (new i = 0;i < MAXPLAYER;i++)
	{
		if (g_iPlayersList[i] == -1 || !IsClientInGame(g_iPlayersList[i]))
			continue;
		
		new client = g_iPlayersList[i];
		if (iSeq == 11 || iSeq == 12 || (iSeq == 9 && fSeqTime <= 4.5))
		{
			// if (g_bHeliEvacStarted && iSeq != 9)
				// PrintCenterText(client, "Evac Helicopter leave in %0.1f", fRoundTime);

			if (IsPlayerAlive(client))
			{
				iPlayers++;
				GetClientAbsOrigin(client, vClientOrigin);
				fDistance = GetVectorDistance(g_vHeliEvacGroundPosition, vClientOrigin);
				if (g_bHeliEvacStarted && g_fHeliEvacTime == 0.0)
				{
					if (fDistance <= 280.0)
					{
						if (vClientOrigin[2] >= g_vHeliEvacGroundPosition[2]-120.0 && vClientOrigin[2] <= g_vHeliEvacGroundPosition[2]+200.0)
							iEvacPlayers++;
					}
					else
					{
						if (g_fRoundTimeLeft <= 0.1)
						{
							ForcePlayerSuicide(client);
						}
						else if (fDistance >= 500.0)
						{
							vClientOrigin[2] += 52.0;
							TE_SetupBeamPoints(vClientOrigin, g_vHeliEvacGroundPosition, g_iSpriteLaser, 0, 0, 0, 0.1, 1.0, 1.0, 0, 0.0, {50, 100, 250, 144}, 0);
							TE_SendToClient(client);
						}
					}
				}
			}
		}

		switch(iSeq)
		{
			case 9:	// seq time: 18.0 | Close and Up 8s
			{
				new Float:fVol = 0.0;
				if (fSeqTime <= 10.0) fVol = 1.0;
				else if (fSeqTime <= 15.0) fVol = 0.2;
				if (fVol != g_fHeliPlayerLoopSoundVol[client] || fVol == 1.0)
				{
					if (fVol != 1.0)
					{
						if (g_fHeliPlayerLoopSoundVol[client] > 0.0) StopSound(client, SNDCHAN_STATIC, "Lua_sounds/helicopter/heli_loop1.wav");
						if (fVol > 0.0) EmitSoundToClient(client, "Lua_sounds/helicopter/heli_loop1.wav", _, SNDCHAN_STATIC, _, _, fVol);
						g_fHeliPlayerLoopSoundVol[client] = fVol;
					}
					else
					{
						if (fDistance <= 1000.0) fVol = 0.7;
						else fVol = 0.3;
						if (fVol == 0.7 && !g_bHeliEvacStarted) fVol = 0.3;
						if (g_fHeliPlayerLoopSoundVol[client] != fVol)
						{
							if (g_fHeliPlayerLoopSoundVol[client] > 0.0) StopSound(client, SNDCHAN_STATIC, "Lua_sounds/helicopter/heli_loop1.wav");
							if (fVol > 0.0) EmitSoundToClient(client, "Lua_sounds/helicopter/heli_loop1.wav", _, SNDCHAN_STATIC, _, _, fVol);
							g_fHeliPlayerLoopSoundVol[client] = fVol;
						}
					}
				}
			}
			case 10:	// seq time: 18.0
			{
				new Float:fVol = 0.0;
				if (fSeqTime <= 12.0) fVol = 0.2;
				else fVol = 1.0;
				if (fVol != g_fHeliPlayerLoopSoundVol[client] || fVol == 1.0)
				{
					if (fVol != 1.0)
					{
						if (g_fHeliPlayerLoopSoundVol[client] > 0.0) StopSound(client, SNDCHAN_STATIC, "Lua_sounds/helicopter/heli_loop1.wav");
						if (fVol > 0.0) EmitSoundToClient(client, "Lua_sounds/helicopter/heli_loop1.wav", _, SNDCHAN_STATIC, _, _, fVol);
						g_fHeliPlayerLoopSoundVol[client] = fVol;
					}
					else
					{
						if (fDistance <= 1000.0) fVol = 0.7;
						else fVol = 0.3;
						if (g_fHeliPlayerLoopSoundVol[client] != fVol)
						{
							if (g_fHeliPlayerLoopSoundVol[client] > 0.0) StopSound(client, SNDCHAN_STATIC, "Lua_sounds/helicopter/heli_loop1.wav");
							if (fVol > 0.0) EmitSoundToClient(client, "Lua_sounds/helicopter/heli_loop1.wav", _, SNDCHAN_STATIC, _, _, fVol);
							g_fHeliPlayerLoopSoundVol[client] = fVol;
						}
					}
				}
			}
			case 11:
			{
				new Float:fVol = 0.0;
				if (fDistance <= 1000.0) fVol = 0.7;
				else if (fDistance <= 3000.0) fVol = 0.3;
				if (g_fHeliPlayerLoopSoundVol[client] != fVol)
				{
					if (g_fHeliPlayerLoopSoundVol[client] > 0.0) StopSound(client, SNDCHAN_STATIC, "Lua_sounds/helicopter/heli_loop1.wav");
					if (fVol > 0.0) EmitSoundToClient(client, "Lua_sounds/helicopter/heli_loop1.wav", _, SNDCHAN_STATIC, _, _, fVol);
					g_fHeliPlayerLoopSoundVol[client] = fVol;
				}
			}
			case 12:
			{
				new Float:fVol = 0.0;
				if (fDistance <= 1000.0) fVol = 0.7;
				else if (fDistance <= 3000.0) fVol = 0.3;
				if (g_fHeliPlayerLoopSoundVol[client] != fVol)
				{
					if (g_fHeliPlayerLoopSoundVol[client] > 0.0) StopSound(client, SNDCHAN_STATIC, "Lua_sounds/helicopter/heli_loop1.wav");
					if (fVol > 0.0) EmitSoundToClient(client, "Lua_sounds/helicopter/heli_loop1.wav", _, SNDCHAN_STATIC, _, _, fVol);
					g_fHeliPlayerLoopSoundVol[client] = fVol;
				}
			}
/*
			decl Float:vWorldMaxs[3];
			GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vWorldMaxs);
			PrintToChat(client, "world %0.2f, %0.2f, %0.2f", vWorldMaxs[0], vWorldMaxs[1], vWorldMaxs[2]);
//			vClientOrigin[2] = vWorldMaxs[2];
			TR_TraceRay(vClientOrigin, Float:{-90.0, 0.0, 0.0}, MASK_SOLID_BRUSHONLY, RayType_Infinite);
			if(TR_DidHit())
			{
				TR_GetEndPosition(vClientOrigin);
				PrintToChat(client, "hit %0.2f, %0.2f, %0.2f", vClientOrigin[0], vClientOrigin[1], vClientOrigin[2]);
			}	*/
		}
	}
	
	if (g_fHeliEvacTime == 0.0)
	{
		// if (g_bHeliEvacStarted)
			// PrintCenterTextAll("[%d / %d]  Go to the Evac Helicopter", iEvacPlayers, iPlayers);
		if (g_bHeliEvacStarted)
			PrintCenterTextAll("[%d / %d]  撤离直升机将在 %0.1f 秒后离开", iEvacPlayers, iPlayers, g_fRoundTimeLeft);

		if (iEvacPlayers > 0 && iEvacPlayers >= iPlayers)
		{
			PlayGameSoundToAll("Training.Warehouse.Vip.40.1");
			PlayGameSoundToAll("ui/vote_success.wav");
			PrintToChatAll("\x08%s撤离完毕！  \x01将在 \x0420秒后离开 \x01！", COLOR_GOLD);
			g_fHeliEvacTime = g_fGameTime+20.0;
			SetRoundTime(20.0);
			HelicopterSpawn(_, _, 9, true);
			return Plugin_Continue;
		}
	}
	else
	{
		if (g_fGameTime >= g_fHeliEvacTime)
		{
			new ent = FindEntityByClassname(-1, "ins_rulesproxy");
			if (ent > MaxClients && IsValidEntity(ent))
			{
				SetVariantInt(TEAM_SURVIVORS);
				AcceptEntityInput(ent, "EndRound");
			}
		}
		else PrintCenterTextAll("撤离完毕！  在 %0.1f 秒后离开", g_fHeliEvacTime-g_fGameTime);
	}
	return Plugin_Continue;
}
/*
public Action:Command_Radial(client, args)
{
	if (!IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client) || args < 1 || GetClientTeam(client) != TEAM_SURVIVORS) return Plugin_Continue;

	decl String:command[255];
	GetCmdArg(1, command, sizeof(command));
	if (!StrEqual(command, "medic", false))
		return Plugin_Continue;
	else
	{
		g_fGameTime = GetGameTime();
		if (g_fGameTime < g_fLastMedicCall[client]+FCVAR_PLAYER_MEDIC_REQUEST_COOLTIME)
			return Plugin_Handled;
		else
		{
			new iHp = GetEntProp(client, Prop_Send, "m_iHealth");
			new String:sHp[48];
			if (float(iHp)/float(CVAR_PLAYER_HEALTH) < 0.2)
			{
				iHp = 0;
				Format(sHp, sizeof(sHp), "\x08%s濒临死亡", COLOR_RED);
			}
			else if (float(iHp)/float(CVAR_PLAYER_HEALTH) <= 0.4)
			{
				iHp = 1;
				Format(sHp, sizeof(sHp), "\x08%s严重受伤", COLOR_DARKORANGE);
			}
			else if (float(iHp)/float(CVAR_PLAYER_HEALTH) < 0.8)
			{
				iHp = 2;
				Format(sHp, sizeof(sHp), "\x08%s受伤", COLOR_LIGHTGOLDENRODYELLOW);
			}
			else
			{
				iHp = 3;
				Format(sHp, sizeof(sHp), "\x08%s健康", COLOR_GREEN);
			}
			if (g_fBurnTime[client] != 0.0 || GetEntityFlags(client)&FL_ONFIRE)
				Format(sHp, sizeof(sHp), "%s  \x08%s着火", sHp, COLOR_MAROON);
			if (g_iPlayerBleeding[client] != 0)
				Format(sHp, sizeof(sHp), "%s  \x08%s失血", sHp, COLOR_DARKSLATEBLUE);
			if (StrContains(sHp, "健康", true) != -1 && g_iPlayerBleeding[client] == 0 && StrContains(sHp, "着火", true) == -1)
				return Plugin_Handled;
			else
			{
				FakeClientCommand(client, "say 需要医疗兵帮助！  (%s)", sHp);
				g_fLastMedicCall[client] = g_fGameTime;
				PlayerYell(client, 9, true, _, iHp);
				return Plugin_Handled;
			}
		}
	}
}
*/

public Action:Command_SetGear(client, args)
{
	if (client <= 0) return Plugin_Handled;
	decl String:slots[24];
	GetCmdArg(1, slots, sizeof(slots));
	if (args < 2 || (StringToInt(slots) != 0 && StringToInt(slots) != 2 && StringToInt(slots) != 3))
	{
		ReplyToCommand(client, "[SM] Usage: sm_setgear");
		ReplyToCommand(client, "[SM] Usage: 0	Armor		Heavy: 3, Light: 1");
		ReplyToCommand(client, "[SM] Usage: 2	Vest		Rig: 6, Carrier: 8, Tactical: 10");
		ReplyToCommand(client, "[SM] Usage: 3	Accessory	Pri Sling: 12, Sec Sling: 13, NVG: 15");
		return Plugin_Handled;
	}

	if (IsPlayerAlive(client))
	{
		decl String:value[24];
		GetCmdArg(2, value, sizeof(value));
		new offset = FindSendPropOffs("CINSPlayer", "m_iMyGear");
		if (offset != -1)
		{
			SetEntData(client, offset+(4*StringToInt(slots)), StringToInt(value));
			decl String:sName[32];
			switch(StringToInt(value))
			{
				//case 1: sName = "Light Armor";
				//case 3: sName = "Heavy Armor";
				//case 6: sName = "Chest Rig";
				//case 8: sName = "Chest Carrier";
				//case 10: sName = "Tactical Carrier";
				//case 12: sName = "Primary Sling";
				//case 13: sName = "Secondary Sling";
				//case 15: sName = "NVG";
				//default: sName = "Unknown";
			}
			PrintToChat(client, "\x04%N - m_iMyGear %d. %s (id: %d)", client, StringToInt(slots), sName, StringToInt(value));
		}
		else PrintToChat(client, "Failed to run \"m_iMyGear\"");
	}
	return Plugin_Handled;
}

public Action:Command_SetVar(client, args)
{
	if (args < 2)
		return Plugin_Handled;

	decl String:cvarname[255];
	GetCmdArg(1, cvarname, sizeof(cvarname));
	
	new Handle:hndl = FindConVar(cvarname);
	if (hndl == INVALID_HANDLE)
	{
		LogError("Unable to find cvar \"%s\"", cvarname);
		return Plugin_Handled;
	}
	new flags = GetConVarFlags(hndl);
	if (flags & FCVAR_NOTIFY)
		SetConVarFlags(hndl, flags^FCVAR_NOTIFY);

	decl String:value[255];
	GetCmdArg(2, value, sizeof(value));

	SetConVarString(hndl, value, true);
	if (flags & FCVAR_NOTIFY)
		SetConVarFlags(hndl, flags);
	LogToGame("Set convar \"%s\" to \"%s\"", cvarname, value);
	return Plugin_Handled;
}

public OnMapStart()
{
	LogToGame("Map loaded, setting up...");
	g_fLastEdictCheck = GetGameTime()+120.0;
	PrecacheThings();
	g_bUpdatedSpawnPoint = false;
	g_iRemoveProps = -1;
	g_iLastManStand = -1;
	g_iPlayerResource = GetPlayerResourceEntity();
	if (g_iPlayerResource != -1 && g_iOffsetScore != -1)
		SDKHook(g_iPlayerResource, SDKHook_ThinkPost, SHook_PlayerResourceThinkPost);
	else
		LogError("Player Resource (%d) or Score Offset (%d) is invalid", g_iPlayerResource, g_iOffsetScore);
	g_bSkipCacheCheck = false;
	g_iGamemode = 1;
	decl String:_gamemode[32];
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
	GetConVarString(FindConVar("mp_gamemode"), _gamemode, sizeof(_gamemode));
	if (StrEqual(_gamemode, "checkpoint")) g_iGamemode = 1;
	else
	{
		LogError("Current map \"%s\" has run on \"%s\" game mode, we are only supporting checkpoint. changing map to default map...", g_sCurrentMap, _gamemode);
		ServerCommand("map ministry_coop checkpoint");
		return;
	}
	
	LogToGame("Map: %s", g_sCurrentMap);
	LogToGame("Gamemode: %s (%d)", _gamemode, g_iGamemode);
	g_iPlayerManager = FindEntityByClassname(MaxClients+1, "ins_player_manager");
	if (g_iPlayerManager == -1)
		LogError("Entity Error: Unable to find Entity for \"ins_player_manager\"");
	g_iSpawnPointsIndex = -1;
	g_iSpawnZoneIndex = -1;
//	g_iBlockZoneIndex = -1;
	for (new i = MaxClients+1;i < GetMaxEntities();i++)
	{
		if (i != INVALID_ENT_REFERENCE && IsValidEntity(i))
		{
			decl String:sClassName[32];
			GetEdictClassname(i, sClassName, sizeof(sClassName));
			if (StrEqual(sClassName, "ins_spawnpoint", false))
				g_iSpawnPointsRef[++g_iSpawnPointsIndex] = EntIndexToEntRef(i);
			else if (StrEqual(sClassName, "ins_spawnzone", false))
				g_iSpawnZoneRef[++g_iSpawnZoneIndex] = EntIndexToEntRef(i);
//			else if (StrEqual(sClassName, "ins_blockzone", true))
//				g_iBlockZoneRef[++g_iBlockZoneIndex] = EntIndexToEntRef(i);
		}
	}
	g_iFixMapLocation = -1;
	if (StrContains(g_sCurrentMap, "desert_warfare_vehicles_coop", false) != -1)
	{
		g_iStuckCheckTime = 15000;
	}
	else if (StrContains(g_sCurrentMap, "_apc", false) != -1)
	{
		g_iStuckCheckTime = 15000;
	}
	else
	{
		g_iStuckCheckTime = 5000;
		if (StrEqual(g_sCurrentMap, "ministry_coop", false))
			g_iFixMapLocation = 0;
		else if (StrContains(g_sCurrentMap, "cu_chi_tunnels", false) != -1)
			g_iFixMapLocation = 1;
		else if (StrContains(g_sCurrentMap, "ins_resistance", false) != -1)
			g_iFixMapLocation = 2;
		else if (StrContains(g_sCurrentMap, "launch_control_coop", false) != -1)
			g_iFixMapLocation = 3;
		else if (StrContains(g_sCurrentMap, "prophet_coop", false) != -1)
			g_iFixMapLocation = 4;
		// else if (StrContains(g_sCurrentMap, "de_vertigo_coop", false) != -1)
			// g_iFixMapLocation = 5;
	}
	if (StrContains(g_sCurrentMap, "night", false) == -1 &&
		StrContains(g_sCurrentMap, "contact_coopv2", false) == -1 &&
		StrContains(g_sCurrentMap, "caves_coop3", false) == -1 &&
		StrContains(g_sCurrentMap, "prospect_coop", false) == -1 &&
		StrContains(g_sCurrentMap, "l4d_garage_lots", false) == -1 &&
		StrContains(g_sCurrentMap, "l4d_garage01_alleys", false) == -1 &&
		StrContains(g_sCurrentMap, "nomercy_coop", false) == -1 &&
		StrContains(g_sCurrentMap, "ps7n", false) == -1)
		SetLightStyle(0, "b");
	new iMapEnt = -1;
	// Searching fog lights entities
	while ((iMapEnt = FindEntityByClassname(iMapEnt, "env_cascade_light")) != -1) 
	{
		LogToGame("Map Entity: env_cascade_light (%d) has been removed", iMapEnt);
		AcceptEntityInput(iMapEnt, "Kill");
		break;
	}
	iMapEnt = -1;
	while ((iMapEnt = FindEntityByClassname(iMapEnt, "env_sun")) != -1) 
	{
		LogToGame("Map Entity: env_sun (%d) has been disabled", iMapEnt);
		AcceptEntityInput(iMapEnt, "TurnOff");
//		AcceptEntityInput(iMapEnt, "Kill");
		break;
	}
//	ServerCommand("sv_skyname sky_insurgency03_dark_contact");
	ApplyFog();
	g_iObjRes = FindEntityByClassname(MaxClients+1, "ins_objective_resource");
	if (g_bLateLoad)
	{
/*		- m_nInsurgentCount (Offset 1340) (Save)(64 Bytes)
		- m_nSecurityCount (Offset 1404) (Save)(64 Bytes)
		m_nRequiredPointIndex
		m_iObjectType
		- m_bSecurityLocked (Offset 1660) (Save)(16 Bytes)
		- m_bInsurgentsLocked (Offset 1676) (Save)(16 Bytes)
			GetEntData(g_iObjRes, FindSendPropOffs("CINSObjectiveResource", "m_vCPPositions"));	*/
//		PrintToChatAll("m_nInsurgentCount %d m_nSecurityCount %d m_nRequiredPointIndex %d m_iObjectType %d", GetEntData(g_iObjRes, FindSendPropOffs("CINSObjectiveResource", "m_nInsurgentCount")), GetEntData(g_iObjRes, FindSendPropOffs("CINSObjectiveResource", "m_nSecurityCount")), GetEntData(g_iObjRes, FindSendPropOffs("CINSObjectiveResource", "m_nRequiredPointIndex")), GetEntData(g_iObjRes, FindSendPropOffs("CINSObjectiveResource", "m_iObjectType")));
//		PrintToChatAll("m_bInsurgentsLocked %d m_bSecurityLocked %d m_vCPPositions %0.2f, %0.2f, %0.2f", GetEntData(g_iObjRes, FindSendPropOffs("CINSObjectiveResource", "m_bInsurgentsLocked")), GetEntData(g_iObjRes, FindSendPropOffs("CINSObjectiveResource", "m_bSecurityLocked")), testpos[0], testpos[1], testpos[2]);
//		PrintToChatAll("m_iGameState %d m_flLastPauseTime %0.3f m_flRoundLength %0.3f", GameRules_GetProp("m_iGameState"), GameRules_GetPropFloat("m_flLastPauseTime"), GameRules_GetPropFloat("m_flRoundLength"));
//		PrintToChatAll("m_iRoundPlayedCount %d m_flRoundLength %0.3f", GameRules_GetProp("m_iRoundPlayedCount"), GameRules_GetPropFloat("m_flRoundLength"));
//		PrintToChatAll("m_flRoundStartTime %0.3f m_flGameStartTime %0.3f m_flRoundMaxTime %0.3f", GameRules_GetPropFloat("m_flRoundStartTime"), GameRules_GetPropFloat("m_flGameStartTime"), GameRules_GetPropFloat("m_flRoundMaxTime"));
//		PrintToChatAll("m_flRoundStartTime %0.3f m_flGameStartTime %0.3f m_flRoundLength %0.3f", GameRules_GetPropFloat("m_flRoundStartTime"), GameRules_GetPropFloat("m_flGameStartTime"), GameRules_GetPropFloat("m_flRoundLength"));
//		PrintToChatAll("GetGameTime %0.3f, m_flRoundLength-(GetGameTime-m_flRoundStartTime) = %0.3f seconds left", GetGameTime(), GameRules_GetPropFloat("m_flRoundLength")-(GetGameTime()-GameRules_GetPropFloat("m_flRoundStartTime")));
//		SetTimerPause(false);
//		SetRoundTime(3600.0);
		LogToGame("Late-loading...");
		if (GetGameTime() == 4)
		{
			new ent = FindEntityByClassname(-1, "ins_rulesproxy");
			if (ent > MaxClients && IsValidEntity(ent))
			{
				SetVariantInt(1);
				AcceptEntityInput(ent, "EndRound");
			}
//			g_bIgnoreFirstRoundStart = true;
		}
		if (g_iObjRes > MaxClients && IsValidEntity(g_iObjRes)){
			g_iNumControlPoints = GetEntData(g_iObjRes, g_iOffsetCPNumbers);
			g_iCurrentControlPoint = GetEntData(g_iObjRes, g_iOffsetCPIndex);
/*			GetEntDataArray(g_iObjRes, g_iOffsetCPType, g_iCPType, g_iNumControlPoints, 4);
			for (new i = 0;i < g_iNumControlPoints;i++)
			{
				GetEntDataVector(g_iObjRes, g_iOffsetCPPositions+(12*i), g_vCPPositions[i]);
//				g_iCPType[i] = GetEntData(g_iObjRes, g_iOffsetCPType+(4*i));
				LogToGame("Control Point/Weapon Cache %d (Type: %d) @ %0.2f, %0.2f, %0.2f", i, g_iCPType[i], g_vCPPositions[i][0], g_vCPPositions[i][1], g_vCPPositions[i][2]);
			}
			LogToGame("Late-load Objectvie Update - Number of Points %d, Current Point %d", g_iNumControlPoints, g_iCurrentControlPoint);
			CheckWeaponCache(true);		*/
//			SetWeaponCacheModel(-1, false);
//			CreateTimer(0.0, ObjectUpdate, 1);
		}

		if (g_iNumControlPoints-1 == g_iCurrentControlPoint)
			g_bFinalCP = true;
		g_bCounterAttack = bool:GetCounterAttack();
/*		if (g_bCounterAttack)
		{
			if (g_bFinalCP) LogToGame("Final Counter-Attack is detected");
			else LogToGame("Counter-Attack is detected");
		}
		else if (g_bFinalCP) LogToGame("Final Capture Point!");	*/
		g_fGameTime = GetGameTime();
		for (new client = 1;client <= MaxClients;client++)
		{
			if (!IsClientInGame(client)) continue;
			PlayerJoined(client);
			if (GetClientTeam(client) > TEAM_SPECTATOR)
			{
//				PrintToServer("%N - Squad %d Squad Slot %d", client, GetPlayerSquad(client, g_iPlayerManager, g_iOffsetSquad), GetPlayerSquadSlot(client, g_iPlayerManager, g_iOffsetSquadSlot));
				if (GetPlayerSquad(client, g_iPlayerManager, g_iOffsetSquad) != -1)
				{
					WelcomeToTheCompany[client] = -1;
					g_bHasSquad[client] = true;
				}
				if (GetClientTeam(client) == TEAM_SURVIVORS)
				{
					if (IsLeader(client))
					{
						if (IsMedic(client))
						{
							g_bMedicPlayer[client] = true;
							g_fMedicLastHealTime[client] = g_fGameTime;
							g_bMedicForceToChange[client] = false;
							CreateCustomFlag(client);
						}
						else CreateCustomFlag(client);
					}
					if (IsPlayerAlive(client))
					{
						// #Resupply Check
						new iKnife = GetPlayerWeaponByName(client, "weapon_kabar");
						if (iKnife > MaxClients && IsValidEdict(iKnife))
							iKnife = EntIndexToEntRef(iKnife);
						else
						{
							iKnife = GivePlayerItem(client, "weapon_kabar");
							if (iKnife <= MaxClients || !IsValidEdict(iKnife))
								iKnife = -1;
							else iKnife = EntIndexToEntRef(iKnife);
						}
						if (iKnife != -1)
						{
							g_iPlayerLastKnife[client] = iKnife;
							SetPlayerSkin(client, true);
						}
					}
				}
			}
		}
		SetEntData(g_iObjRes, g_iOffsetCPIndex, 0);
		GameRules_SetProp("m_bCounterAttack", 0);
		g_bCounterAttack = false;
		g_bFinalCP = false;
	}
	else
	{
		for (new i = 0;i < MAXPLAYER;i++)
			g_iPlayersList[i] = -1;
//		g_bIgnoreFirstRoundStart = false;
	}
	if (ZH_DEBUG) g_bUpdatedSpawnPoint = true;	// #DEBUG
	else ServerCommand("cvar nb_stop 1");
	CreateTimer(0.5, LoadSpawnTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	CreateTimer(1.0, HudTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	CreateTimer(0.1, ThinkTimer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	return;
}
/*
stock CreateHelmet(client, type = 0)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetGameState() != 4) return -1;
	if (g_iPlayerHasHelmet[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_iPlayerHasHelmet[client]))
		RemoveHelmet(client);

	new iHelmet = -1;
	iHelmet = CreateEntityByName("prop_dynamic_override");
	if (iHelmet != -1 && IsValidEntity(iHelmet))
	{
		g_iPlayerHasHelmet[client] = EntIndexToEntRef(iHelmet);
		LogToGame("Create Helmet for \"%N\" has created (Type: %s, Index: %d (%d))", client, type, iHelmet, g_iPlayerHasHelmet[client]);
		if (type == 0)
			DispatchKeyValue(iHelmet, "model", "models/characters/us_helmet_head.mdl");

		DispatchKeyValue(iHelmet, "targetname", "LuaPlayerHelmet");
		DispatchKeyValue(iHelmet, "solid", "0");
		DispatchKeyValue(iHelmet, "spawnflags", "4");
		SetEntPropEnt(iHelmet, Prop_Data, "m_hOwnerEntity", client);
		SetVariantString("!activator");
		AcceptEntityInput(iHelmet, "SetParent", client, iHelmet, 0);
		SetVariantString("head");
		AcceptEntityInput(iHelmet, "SetParentAttachment", iHelmet, iHelmet, 0);
			
		decl Float:fPos[3];
		GetClientAbsOrigin(client, fPos);
		TeleportEntity(iHelmet, fPos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchSpawn(iHelmet);
		AcceptEntityInput(iHelmet, "Enable");
		AcceptEntityInput(iHelmet, "TurnOn", iHelmet, iHelmet, 0);
		ActivateEntity(iHelmet);

		return g_iPlayerHasHelmet[client];
	}
	return -1;
}

stock RemoveHelmet(client)
{
	if (g_iPlayerHasHelmet[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_iPlayerHasHelmet[client]))
	{
		new iHelmet = EntRefToEntIndex(g_iPlayerHasHelmet[client]);
		if (iHelmet > MaxClients && IsValidEntity(iHelmet))
		{
			if (IsClientInGame(client))
				LogToGame("Helmet for \"%N\" has been killed (Index: %d (%d))", client, iHelmet, g_iPlayerHasHelmet[client]);
			else
				LogToGame("Helmet for [NOT IN-GAME] \"Client %d\" has been killed (Index: %d (%d))", client, iHelmet, g_iPlayerHasHelmet[client]);
//			SDKUnhook(g_iPlayerHasHelmet[client], SDKHook_SetTransmit, SHook_OnTransmitForCustomFlag);
			AcceptEntityInput(g_iPlayerHasHelmet[client], "Kill");
			g_iPlayerHasHelmet[client] = INVALID_ENT_REFERENCE;
			return true;
		}
	}
	return false;
}
*/

stock GetPlayerWeaponByName(client, const String:weaponname[])
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_iOffsetMyWeapons == -1)
		return -1;

	for (new i = 0;i < 48;i++)
	{
		new weapon = GetEntDataEnt2(client, g_iOffsetMyWeapons+(4*i));
		if (weapon == -1) break;

		if (!IsValidEntity(weapon) || weapon <= MaxClients)
			continue;

		new String:classname[64];
		GetEntityClassname(weapon, classname, sizeof(classname));
		if (StrEqual(classname, weaponname, false))
			return weapon;
	}
	return -1;
}

stock CreateCustomFlag(client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetGameState() != 4) return -1;

	// Types
	// 0, 1: Arab, 2: USA, 3: Medic, 4: Turkey
//	if (type < 0 || type > 4) type = 2;

	new iFlag = -1;
	if (g_iCustomFlagIndex[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_iCustomFlagIndex[client]))
	{
		iFlag = EntRefToEntIndex(g_iCustomFlagIndex[client]);
		if (iFlag > MaxClients)
		{
			SetEntProp(iFlag, Prop_Data, "m_nSkin", !g_bMedicPlayer[client]?2:3);
			if (g_bMedicPlayer[client]) SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
			else SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
			LogToGame("Custom Flag for \"%N\" has been already set and use it instead doing recreate (Skin: %s, Index: %d (%d))", client, !g_bMedicPlayer[client]?"USA":"MEDIC", iFlag, g_iCustomFlagIndex[client]);
			return g_iCustomFlagIndex[client];
		}
		iFlag = -1;
	}
	if (iFlag == -1) iFlag = CreateEntityByName("prop_dynamic_override");
	if (iFlag != -1 && IsValidEntity(iFlag))
	{
		g_iCustomFlagIndex[client] = EntIndexToEntRef(iFlag);
		LogToGame("Custom Flag for \"%N\" Has created (Skin: %s, Index: %d (%d))", client, !g_bMedicPlayer[client]?"USA":"MEDIC", iFlag, g_iCustomFlagIndex[client]);
		DispatchKeyValue(iFlag, "model", "models/generic/flag_pole_animated.mdl");
		DispatchKeyValue(iFlag, "targetname", "LuaCustomFlag");
		DispatchKeyValue(iFlag, "spawnflags", "4");
		SetEntProp(iFlag, Prop_Data, "m_CollisionGroup", 2);
		SetEntPropEnt(iFlag, Prop_Data, "m_hOwnerEntity", client);
		SetVariantString("!activator");
		AcceptEntityInput(iFlag, "SetParent", client, iFlag, 0);
		if (!IsVipModel(client))
		{
			DispatchKeyValueFloat(iFlag, "modelscale", 0.15);
			SetVariantString("grenade1");
		}
		else
		{
			DispatchKeyValueFloat(iFlag, "modelscale", 0.11);
			SetVariantString("primary");
		}
		AcceptEntityInput(iFlag, "SetParentAttachment", iFlag, iFlag, 0);
		DispatchSpawn(iFlag);
		SetEntProp(iFlag, Prop_Data, "m_nSkin", !g_bMedicPlayer[client]?2:3);
		SetVariantString("idle");
		AcceptEntityInput(iFlag, "SetAnimation");
		SetVariantString("idle");
		AcceptEntityInput(iFlag, "SetDefaultAnimation");
		AcceptEntityInput(iFlag, "Enable");
		AcceptEntityInput(iFlag, "TurnOn", iFlag, iFlag, 0);
		ActivateEntity(iFlag);
/*		decl String:addoutput[64];
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::10.0:1");
		SetVariantString(addoutput);
		AcceptEntityInput(iFlag, "AddOutput");
		AcceptEntityInput(iFlag, "FireUser1");	*/
		if (g_bMedicPlayer[client]) SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
		else if (g_iPointFlagOwner != client) SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		SDKHook(g_iCustomFlagIndex[client], SDKHook_SetTransmit, SHook_OnTransmitForCustomFlag);
		return g_iCustomFlagIndex[client];
	}
	return -1;
}

stock RemoveCustomFlags(client)
{
	if (g_iCustomFlagIndex[client] != INVALID_ENT_REFERENCE && IsValidEntity(g_iCustomFlagIndex[client]))
	{
		new iOldFlag = EntRefToEntIndex(g_iCustomFlagIndex[client]);
		if (iOldFlag > MaxClients && IsValidEntity(iOldFlag))
		{
			if (IsClientInGame(client))
			{
				if (g_iPointFlagOwner != client)
					SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
				LogToGame("Custom Flag for \"%N\" has been killed (Index: %d (%d))", client, iOldFlag, g_iCustomFlagIndex[client]);
			}
			else
				LogToGame("Custom Flag for [NOT IN-GAME] \"Client %d\" has been killed (Index: %d (%d))", client, iOldFlag, g_iCustomFlagIndex[client]);
//			SDKUnhook(g_iCustomFlagIndex[client], SDKHook_SetTransmit, SHook_OnTransmitForCustomFlag);
			AcceptEntityInput(g_iCustomFlagIndex[client], "Kill");
			g_iCustomFlagIndex[client] = INVALID_ENT_REFERENCE;
			return true;
		}
	}
	return false;
}

public Action:SHook_OnTransmitForCustomFlag(entity, client)
{
	if (EntIndexToEntRef(entity) == g_iCustomFlagIndex[client])
		return Plugin_Handled;
	else
	{
		new iOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if (iOwner < 1 || iOwner > MaxClients || !IsClientInGame(iOwner))
		{
			LogToGame("Custom Flag for [NOT IN-GAME] \"Client %d\" has been killed (Index: %d (%d))", iOwner, entity, EntIndexToEntRef(entity));
//			SDKUnhook(g_iCustomFlagIndex[client], SDKHook_SetTransmit, SHook_OnTransmitForCustomFlag);
			AcceptEntityInput(entity, "Kill");
		}
		else if (!IsPlayerAlive(iOwner))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}
/*
public Action:SHook_OnTransmitForPlayers(client, viewclient)
{
	if (client != viewclient || g_iGameState != 4) return Plugin_Continue;
	if (GetClientTeam(client) == TEAM_SURVIVORS && GetClientTeam(viewclient) != TEAM_ZOMBIES)
	{
		if (!IsMedic(viewclient))
		{
			if (g_iPointFlagOwner != client && !IsMedic(client))
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		}
		else
		{
			new iHp = GetEntProp(client, Prop_Send, "m_iHealth");
			if (iHp < CVAR_PLAYER_GLOW_HEALTH)
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
			else if (g_iPointFlagOwner != client)
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		}
	}
	return Plugin_Continue;
}
*/
stock bool:UpdateSpawnPositions(iControlpoint = 0, iTeam = -1, iCounterAttack = -1, bool:bCheckPlayers = true, Float:fSkipDistance = 0.0, Float:fMaxDistance = 90000.0, bool:bDebug = false)
{
	if (GetGameState() != 4 || !g_bUpdatedSpawnPoint || (iTeam == TEAM_SURVIVORS && iControlpoint > 0)) return false;

//	g_iSpawnPointsInfo[g_iSpawnPointsInfoMaxIndex] = EntIndexToEntRef(entity);
//	g_iSpawnPointsInfo[g_iSpawnPointsInfoMaxIndex][0] = g_bCounterAttack;
//	g_iSpawnPointsInfoIndex[g_iCurrentControlPoint] = g_iSpawnPointsInfoMaxIndex;
	g_iNextSpawnPointsIndex = -1;
	new iMaxIndex;
	if (iControlpoint < g_iNumControlPoints-1)
		iMaxIndex = g_iSpawnPointsInfoIndex[iControlpoint+1]-1;
	else
		iMaxIndex = g_iSpawnPointsInfoMaxIndex;
	for (new i = g_iSpawnPointsInfoIndex[iControlpoint];i <= iMaxIndex;i++)
	{
		if (iCounterAttack != -1 && g_iSpawnPointsInfo[i][1] != iCounterAttack)
			continue;

		new iSpawnPointRef = g_iSpawnPointsInfo[i][0];
		if (iSpawnPointRef == INVALID_ENT_REFERENCE)
		{
			LogError("[DEBUG] INVALID SpawnPoint (Target CP %d Index %d (Ref %d), CA %d, CP %d TEAM %d)", iControlpoint, EntRefToEntIndex(iSpawnPointRef), iSpawnPointRef, g_iSpawnPointsInfo[i][1], g_iSpawnPointsInfo[i][2], g_iSpawnPointsInfo[i][3]);
			continue;
		}

//		if (iTeam != -1 && GetEntProp(iSpawnPointRef, Prop_Send, "m_iTeamNum") != iTeam)
		if (iTeam != -1 && g_iSpawnPointsInfo[i][3] != iTeam)
			continue;

		new Float:vSpawnPointOrigin[3];
		GetEntPropVector(iSpawnPointRef, Prop_Data, "m_vecOrigin", vSpawnPointOrigin);
		if (GetVectorDistance(vSpawnPointOrigin, g_vCPPositions[iControlpoint]) > fMaxDistance)
			continue;

		new bool:bIsVisibleByPlayer = false;
		if (bCheckPlayers)
		{
			vSpawnPointOrigin[2] += 42.0;
			for (new j = 0;j < MAXPLAYER;j++)
			{
				if (g_iPlayersList[j] == -1 || !IsClientInGame(g_iPlayersList[j]) || !IsPlayerAlive(g_iPlayersList[j]))
					continue;

				new client = g_iPlayersList[j];
				new iFlags = GetEntProp(client, Prop_Send, "m_iPlayerFlags");
				if (iFlags != 0 && iFlags & INS_PL_BLOCKZONE)
				{
					if (GetGameTime()-GetEntPropFloat(client, Prop_Send, "m_flRestrictedZoneTime") >= 8.0)
						continue;
				}
			
				new Float:vClientOrigin[3];
				GetClientHeadOrigin(client, vClientOrigin, 10.0);
/*				GetClientEyePosition(client, vClientOrigin);
				switch(GetEntProp(client, Prop_Send, "m_iCurrentStance"))
				{
					case 0: vClientOrigin[2] += 4.0;	// Standing
					case 1: vClientOrigin[2] += 20.0;	// Duck
					case 2: vClientOrigin[2] += 52.0;	// Prone
				}	*/
				
				new Float:fDistance = GetVectorDistance(vClientOrigin, vSpawnPointOrigin);
				if (fDistance <= 1800.0)
				{
					if (fDistance <= fSkipDistance && iFlags & ~INS_PL_BLOCKZONE)
					{
						bIsVisibleByPlayer = true;
						break;
					}
//					new Handle:hTrace = TR_TraceRayFilterEx(vClientOrigin, vSpawnPointOrigin, MASK_SOLID, RayType_EndPoint, Filter_Not_Players);
					new Handle:hTrace = TR_TraceRayFilterEx(vClientOrigin, vSpawnPointOrigin, MASK_SOLID_BRUSHONLY, RayType_EndPoint, Base_TraceFilter);
					if (TR_DidHit(hTrace))
					{
						CloseHandle(hTrace);
						continue;
					}
					else
					{
						CloseHandle(hTrace);
						if (bDebug) LogToGame("[DEBUG]		Client %d (%N) is visible spawn point %d", client, client, iSpawnPointRef);
						bIsVisibleByPlayer = true;
						break;
					}
				}
			}
			vSpawnPointOrigin[2] -= 42.0;
		}
		if (bIsVisibleByPlayer)
			continue;
		else
		{
			g_vNextSpawnPoints[++g_iNextSpawnPointsIndex][0] = vSpawnPointOrigin[0];
			g_vNextSpawnPoints[g_iNextSpawnPointsIndex][1] = vSpawnPointOrigin[1];
			g_vNextSpawnPoints[g_iNextSpawnPointsIndex][2] = vSpawnPointOrigin[2];
			if (bDebug) LogToGame("[DEBUG]		Spawn Point Updated %d. %0.2f, %0.2f, %0.2f", g_iNextSpawnPointsIndex, g_vNextSpawnPoints[g_iNextSpawnPointsIndex][0], g_vNextSpawnPoints[g_iNextSpawnPointsIndex][1], g_vNextSpawnPoints[g_iNextSpawnPointsIndex][2]);

			if (g_iNextSpawnPointsIndex >= MAX_SPAWNPOINT-1)
				return true;
		}
	}
	if (g_iNextSpawnPointsIndex > -1)
	{
		LogToGame("Spawn Point Updated!  (CP: %d | Team: %d | CA: %d | Check Players: %d | Valid Points: %d)", iControlpoint, iTeam, iCounterAttack, bCheckPlayers, g_iNextSpawnPointsIndex+1);
		return true;
	}
	else
	{
		LogToGame("Spawn Point Failed to Updated...  (CP: %d | Team: %d | CA: %d | Check Players: %d | Valid Points: %d)", iControlpoint, iTeam, iCounterAttack, bCheckPlayers, g_iNextSpawnPointsIndex+1);
//		LogError("Failed to run \"UpdateSpawnPositions(position)\"  [position = %d]", position);
		return false;
	}
}

public bool:Base_TraceFilter(entity, contentsMask, any:data)
{
	if (entity != data)
		return false;
	return true;
} 
/*
public Action:Command_SpawnTest(client, args)
{
	if (args < 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_st <#userid|name> <%d: Sec|%d: Ins> <-2: Sec (%d)|-1: Back (%d)|0: None|1: TP (%d)> [Index for INS]", TEAM_SURVIVORS, TEAM_ZOMBIES, g_iSpawnBackPositionsIndexNext, g_iSpawnBackPositionsIndex, g_iSpawnPositionsIndex);
		return Plugin_Handled;
	}

	new String:arg[65];
	new team;
	new location;
	new index = -1;
	GetCmdArg(2, arg, sizeof(arg));
	team = StringToInt(arg);
//	if (team != TEAM_SURVIVORS && team != TEAM_ZOMBIES)
	if (team != TEAM_SURVIVORS && team != TEAM_ZOMBIES)
	{
		ReplyToCommand(client, "[SM] Usage: sm_st <#userid|name> <%d: Sec|%d: Ins> <-2: Sec (%d)|-1: Back (%d)|0: None|1: TP (%d)> [Index for INS]", TEAM_SURVIVORS, TEAM_ZOMBIES, g_iSpawnBackPositionsIndexNext, g_iSpawnBackPositionsIndex, g_iSpawnPositionsIndex);
		return Plugin_Handled;
	}
	GetCmdArg(3, arg, sizeof(arg));
	location = StringToInt(arg);
	if (location < -2 || location > 1 || location == 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_st <#userid|name> <%d: Sec|%d: Ins> <-2: Sec (%d)|-1: Back (%d)|0: None|1: TP (%d)> [Index for INS]", TEAM_SURVIVORS, TEAM_ZOMBIES, g_iSpawnBackPositionsIndexNext, g_iSpawnBackPositionsIndex, g_iSpawnPositionsIndex);
		return Plugin_Handled;
	}
	if (args >=4 && team == TEAM_ZOMBIES)
	{
		GetCmdArg(4, arg, sizeof(arg));
		index = StringToInt(arg);
		if (location == 1 && index > g_iSpawnPositionsIndex)
			index = GetRandomInt(0, g_iSpawnPositionsIndex);
		else if (location == -1 && index > g_iSpawnBackPositionsIndex)
			index = GetRandomInt(0, g_iSpawnBackPositionsIndex);
		else if (location == -2 && index > g_iSpawnBackPositionsIndexNext)
			index = GetRandomInt(0, g_iSpawnBackPositionsIndexNext);
//		else index = -1;
	}
	GetCmdArg(1, arg, sizeof(arg));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MaxClients], target_count, bool:tn_is_ml;

	target_count = ProcessTargetString(arg, client, target_list, MaxClients, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml);

	if(target_count <= COMMAND_TARGET_NONE) 	// If we don't have dead players
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		if (team == TEAM_SURVIVORS)
		{
			TeleportOnSpawn_Sec(target_list[i], location);
		}
		else
		{
			TeleportOnSpawn(target_list[i], location, index);
		}
		if (index > -1)
			PrintToChat(client, "[SM] Teleported %s to Spawn Point (team: %d, location: %d, index: %d)", target_name, team, location, index);
		else
			PrintToChat(client, "[SM] Teleported %s to Spawn Point (team: %d, location: %d, index: Random)", target_name, team, location, index);
	}

	return Plugin_Handled;
}
*/
public bool ExcludeSelfAndAlive(int entity, int contentsMask, any data)
{
	if (entity == data) 
	{
		return false; 
	}
	else if (entity > 0 && entity <= MaxClients)
	{
		if (IsClientInGame(entity))
		{
			return false;
		}
	}
	
	return true;
}
/*
public OnMapEnd()
{
}
*/

public SHook_PlayerResourceThinkPost(entity)
{
	decl iTotalScore[MaxClients+1];
	GetEntDataArray(entity, g_iOffsetScore, iTotalScore, MaxClients+1);
	for (new i = 1; i <= MaxClients;i++)
	{
		if (IsClientInGame(i) && g_iPlayerBonusScore[i] > 0)
			iTotalScore[i] += g_iPlayerBonusScore[i];
	}
	SetEntDataArray(entity, g_iOffsetScore, iTotalScore, MaxClients+1);
}

public SHook_OnPreThink(client)
{
	if (g_iCurrentControlPoint == -1 || !IsPlayerAlive(client) || !g_bUpdatedSpawnPoint) return;
	if (g_iGameState != 4) return;
/*		static bool:Debug[10240] = {false, ...};
		new flag = GetEntProp(client, Prop_Send, "m_iPlayerFlags");
		if (!Debug[flag])
		{
			Debug[flag] = true;
			LogMessage("---------------------------------------------");
			for (new i = 1;i <= 31;i++)
			{
				PrintToChat(client, "m_iPlayerFlags %d @ (1<<%d) == %s", flag, i, flag&(1<<i)?"true":"false");
				LogMessage("m_iPlayerFlags %d @ (1<<%d) == %s", flag, i, flag&(1<<i)?"true":"false");
			}
			PrintToChat(client, "Debugged! Found new \"m_iPlayerFlags\" value \"%d\"", flag);
			LogMessage("Debugged! Found new \"m_iPlayerFlags\" value \"%d\"", flag);
		}	*/
/*
*/
//	new stance = GetEntProp(client, Prop_Send, "m_iCurrentStance");	// 0 stand 1 duck 2 prone
//	if (stance == 0)
//		SetEntProp(client, Prop_Send, "m_iCurrentStance", 1);
	new iFlags = GetEntProp(client, Prop_Send, "m_iPlayerFlags"), bool:bChanged = false;
	if (g_iPointFlag != INVALID_ENT_REFERENCE && g_iPointFlagOwner == client)
	{
		if (iFlags & INS_PL_SPAWNZONE)
		{
			LogToGame("Intel Captured by %N  (Kill flag %d)", client, g_iPointFlag);
			g_bNoTakingCache = true;
			AcceptEntityInput(g_iPointFlag, "Kill");
			FakeClientCommand(client, "say 情报已获取！");
			if (!g_bMedicPlayer[client])
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
			g_iPointFlag = INVALID_ENT_REFERENCE;
			g_iPointFlagOwner = -1;
			PlayGameSoundToAll("Player.Security_Infiltration_SecCapturedIntel");
			
			decl Float:vPos[3];
			GetEntPropVector(g_iCPIndex[g_iCurrentControlPoint], Prop_Data, "m_vecAbsOrigin", vPos);
			SetEntData(g_iCPIndex[g_iCurrentControlPoint], g_iOffsetWeaponCacheGlow, 1);
			vPos[2] += 2000.0;
			TeleportEntity(g_iCPIndex[g_iCurrentControlPoint], vPos, NULL_VECTOR, NULL_VECTOR);
			if (g_iPointFlagSpawnGlow != INVALID_ENT_REFERENCE && IsValidEntity(g_iPointFlagSpawnGlow) && EntRefToEntIndex(g_iPointFlagSpawnGlow) > MaxClients)
			{
				AcceptEntityInput(g_iPointFlagSpawnGlow, "Kill");
				g_iPointFlagSpawnGlow = INVALID_ENT_REFERENCE;
			}
			// Captured
			//	hq/security/wecaptured1~10.ogg - Sec
			//	hq/security/theycaptured1~10.ogg - Ins, but using 10 for RPG killed by bots?
		}
	}
	if (GetEntProp(client, Prop_Send, "m_bJumping") == 1)
	{
		if (iFlags & INS_PL_ZOOM && iFlags & ~INS_PL_LOWERZONE)
		{
			bChanged = true;
			iFlags |= INS_PL_LOWERZONE;
		}
/*		else if (iFlags & ~INS_PL_ZOOM && iFlags & INS_PL_LOWERZONE && iFlags & ~INS_PL_BLOCKZONE)
		{
			bChanged = true;
			iFlags &= ~INS_PL_LOWERZONE;
		}	*/
	}
	else if (iFlags & ~INS_PL_BLOCKZONE && iFlags & INS_PL_LOWERZONE)
	{
		bChanged = true;
		iFlags &= ~INS_PL_LOWERZONE;
	}
/*	if (g_iPLFBuyzone[client] != 0 || g_bCounterAttackReadyTime)
	{
		if (g_bCounterAttackReadyTime || (g_iPLFBuyzone[client] == 1 && iFlags & ~INS_PL_SPAWNZONE && iFlags & ~INS_PL_BUYZONE))
		{
			if (!g_bCounterAttackReadyTime)
			{
				bChanged = true;
				iFlags |= INS_PL_BUYZONE;
			}
			else
			{
				decl Float:vPos[3];
				GetClientAbsOrigin(client, vPos);
				if (GetVectorDistance(vPos, g_vCPPositions[g_iCurrentControlPoint]) <= 600.0)
				{
					bChanged = true;
					iFlags |= INS_PL_BUYZONE;
				}
			}
		}
		else if (g_iPLFBuyzone[client] != 0 && (iFlags & INS_PL_SPAWNZONE || iFlags & INS_PL_BUYZONE))
		{
			bChanged = true;
			iFlags &= ~INS_PL_SPAWNZONE;
			iFlags &= ~INS_PL_BUYZONE;
		}
	}	*/
	if (g_iPLFBuyzone[client] != INVALID_ENT_REFERENCE)
	{
		if (iFlags & INS_PL_SPAWNZONE)
		{
			g_iPLFBuyzone[client] = INVALID_ENT_REFERENCE;
			PrintCenterText(client, " ");
		}
		else if (IsValidEdict(g_iPLFBuyzone[client]))
		{
			new iStock = RoundToNearest(GetEntPropFloat(g_iPLFBuyzone[client], Prop_Data, "m_flLocalTime"));
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
				PrintCenterText(client, " ");
			}
		}
		else
		{
			g_iPLFBuyzone[client] = INVALID_ENT_REFERENCE;
			PrintCenterText(client, " ");
		}
	}
	if (iFlags & INS_PL_BLOCKZONE)
	{
/*		if (iFlags & ~INS_PL_WALK)
		{
			bChanged = true;
			iFlags |= INS_PL_WALK;
		}	*/
//		iFlags &= ~INS_PL_BLOCKZONE;
/*		if (iFlags & INS_PL_RUN)
		{
			bChanged = true;
			iFlags &= ~INS_PL_RUN;
		}	*/
		if (GetEntProp(client, Prop_Send, "m_bWasSliding") == 0)
			SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 130.0);
	}
//	PrintToChat(client, "%0.1f   |   %0.1f", GetEntPropFloat(client, Prop_Send, "m_flRestrictedZoneTime"), GetGameTime());
/*	if (g_iPLFBlockzone[client] == 1)
	{
		if (iFlags & ~INS_PL_BLOCKZONE)
		{
			bChanged = true;
			iFlags |= INS_PL_BLOCKZONE;
		}
	}
	else if (iFlags & INS_PL_BLOCKZONE)
	{
		bChanged = true;
		iFlags &= ~INS_PL_BLOCKZONE;
	}
	if (g_iCPType[g_iCurrentControlPoint] == 0 && g_iCPIndex[g_iCurrentControlPoint] != INVALID_ENT_REFERENCE && (g_bCounterAttack || GetCounterAttack()))
	{
		decl Float:vPos[3], Float:vTargetPos[3];
		GetEntPropVector(g_iCPIndex[g_iCurrentControlPoint], Prop_Data, "m_vecAbsOrigin", vPos);
		GetClientAbsOrigin(client, vTargetPos);
		if (GetVectorDistance(vPos, vTargetPos) > 1600)
		{
			if (iFlags & ~INS_PL_BLOCKZONE)
			{
				bChanged = true;
				iFlags |= INS_PL_BLOCKZONE; // INS_PL_LOWERZONE will be set by the server when player's time (mp_restricted_area_wpn_time) has reached
				g_fGameTime = GetGameTime();
				if (g_fLastWarningTime[client] <= g_fGameTime)
				{
					g_fLastWarningTime[client] = g_fGameTime+10.0;
					ClientCommand(client, "playgamesound Player.Security_RestrictedArea");
				}
			}
		}
		else
		{
			if (iFlags & INS_PL_BLOCKZONE && g_iPLFBlockzone[client] == 0)
			{
				bChanged = true;
				iFlags &= ~INS_PL_BLOCKZONE;
				iFlags &= ~INS_PL_LOWERZONE;
			}
		}
	}	*/
	if (g_fPlayerWeaponBlocked[client] != 0.0)
	{
		bChanged = true;
		if (iFlags & ~INS_PL_LOWERZONE)
			iFlags |= INS_PL_LOWERZONE;
		if (g_fPlayerWeaponBlocked[client] > 0.0 && GetGameTime() >= g_fPlayerWeaponBlocked[client])
		{
			if (iFlags & INS_PL_LOWERZONE)
				iFlags &= ~INS_PL_LOWERZONE;
			g_fPlayerWeaponBlocked[client] = 0.0;
		}
	}
	
	/*
		1: Repairing Barricade
		2: Trying/Installing Barricade
		3: Holding First Aid
		4: Trying/Bandaging First Aid by Self
		5: Trying/Bandaging First Aid for Teammate
	*/
	new iWorkStatus = 0;
	new iAimTarget = GetClientAimTarget(client, false);
	if (iAimTarget > MaxClients)
	{
		if (FindDataMapInfo(iAimTarget, "m_ModelName") != -1)
		{
			new String:sClassName[64];
			GetEntPropString(iAimTarget, Prop_Data, "m_iName", sClassName, sizeof(sClassName));
			if (StrEqual(sClassName, "LuaCustomModel", true))
			{
				new String:sModelPath[128];
				GetEntPropString(iAimTarget, Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
				if (StrContains(sModelPath, "ammocrate3.mdl", true) != -1)
				{
					if (g_iPLFBuyzone[client] != INVALID_ENT_REFERENCE && g_iPLFBuyzone[client] == EntIndexToEntRef(iAimTarget))
					{
						PrintCenterText(client, "按 \"装备配置键 (M)\" 来重新补给\n \n弹药补给剩余量:  [%d / 4]", RoundToNearest(GetEntPropFloat(iAimTarget, Prop_Data, "m_flLocalTime")));
						if (GetClientButtons(client) & INS_USE && GetGameTime()-g_fPlayerLastChat[client] >= 1.0)
						{
							FakeClientCommand(client, "inventory_resupply");
							g_fPlayerLastChat[client] = GetGameTime();
						}
					}
				}
				else if (GetEntPropEnt(iAimTarget, Prop_Data, "m_hOwnerEntity") == 0)
				{
					if (StrContains(sModelPath, "burned.mdl", true) != -1)
					{
						new Float:vOrigin[3], Float:vTargetOrigin[3];
						GetEntPropVector(iAimTarget, Prop_Data, "m_vecAbsOrigin", vOrigin);
						GetClientAbsOrigin(client, vTargetOrigin);
						if (GetVectorDistance(vOrigin, vTargetOrigin) <= 80.0)
						{
							if (GetClientButtons(client) & INS_USE)
							{
								PrintCenterText(client, " ");
								g_iPlayerBonusScore[client] += 50;
								if (GetRandomFloat(0.1, 100.0) <= 65.0) SetEntPropEnt(iAimTarget, Prop_Data, "m_hOwnerEntity", MaxClients+1);
								else SetEntPropEnt(iAimTarget, Prop_Data, "m_hOwnerEntity", -1);
								if (StrContains(sModelPath, "sec_hub", true) != -1)
								{
									LogToGame("%N is fixed portable radar %d", client, iAimTarget);
									SetVariantColor({100, 100, 255, 255});
									SetEntityModel(iAimTarget, "models/static_props/sec_hub.mdl");
									FakeClientCommand(client, "say 便携雷达已修复！");
								}
								else
								{
									LogToGame("%N is ied jammer radar %d", client, iAimTarget);
									SetVariantColor({100, 255, 100, 255});
									SetEntityModel(iAimTarget, "models/static_props/ins_radio.mdl");
									FakeClientCommand(client, "say IED干扰器已修复！");
								}
								new Float:fDirection[3];
								fDirection[0] = GetRandomFloat(-1.0, 1.0);
								fDirection[1] = GetRandomFloat(-1.0, 1.0);
								fDirection[2] = GetRandomFloat(-1.0, 1.0);
								new Float:vMaxs[3];
								GetEntPropVector(iAimTarget, Prop_Data, "m_vecMaxs", vMaxs);
								vOrigin[2] += vMaxs[2]/2;
								TE_SetupSparks(vOrigin, fDirection, 1, 1);
								TE_SendToAll();
								AcceptEntityInput(iAimTarget, "SetGlowColor");
							}
							else
							{
								if (StrContains(sModelPath, "sec_hub", true) != -1)
									PrintCenterText(client, "按 \"使用键 (F)\" 来修复便捷雷达");
								else
									PrintCenterText(client, "按 \"使用键 (F)\" 来修复IED干扰器");
							}
						}
					}
					else if (GetEntPropFloat(iAimTarget, Prop_Data, "m_flLocalTime") == 1.0 && (StrContains(sModelPath, "sandbagwall", true) != -1 || StrContains(sModelPath, "prop_fortification_hesco", true) != -1 || StrContains(sModelPath, "barrier", true) != -1))
					{
						new Float:vOrigin[3], Float:vTargetOrigin[3];
						GetEntPropVector(iAimTarget, Prop_Data, "m_vecAbsOrigin", vOrigin);
						GetClientAbsOrigin(client, vTargetOrigin);
						if (GetVectorDistance(vOrigin, vTargetOrigin) <= 80.0)
						{
							if (StrEqual(g_sPlayerClassTemplate[client], "Gnalvl_engineer_usmc_1", true) || StrEqual(g_sPlayerClassTemplate[client], "Gnalvl_engineer_usmc_1", true))
							{
								if (g_iPlayerDeployedWeapon[client] == WEAPON_KABAR && GetClientButtons(client) & INS_USE)	// #Deployed weapon_kabar (1)
								{
									new iHp = GetEntProp(iAimTarget, Prop_Data, "m_iHealth");
									new iMaxHp = GetEntProp(iAimTarget, Prop_Data, "m_iMaxHealth");
									iHp += 1;
									iWorkStatus = 1;
									new Float:fDirection[3];
									fDirection[0] = GetRandomFloat(-1.0, 1.0);
									fDirection[1] = GetRandomFloat(-1.0, 1.0);
									fDirection[2] = GetRandomFloat(-1.0, 1.0);
									new Float:vMaxs[3];
									GetEntPropVector(iAimTarget, Prop_Data, "m_vecMaxs", vMaxs);
									vOrigin[2] += vMaxs[2]/2;
									TE_SetupSparks(vOrigin, fDirection, 1, 1);
									TE_SendToAll();
									if (iHp < iMaxHp) PrintCenterText(client, "修复中... [%d  /  %d]", iHp, iMaxHp);
									else
									{
										iHp = iMaxHp;
										PrintCenterText(client, " ");
										g_iPlayerBonusScore[client] += 100;
										if (iMaxHp > 1250)
										{
											LogToGame("%N is fixed barricade %d", client, iAimTarget);
											SetEntPropFloat(iAimTarget, Prop_Data, "m_flLocalTime", 0.0);
											FakeClientCommand(client, "say 路障已修复！");
										}
										else
										{
											LogToGame("%N is fixed barricade %d for the last time", client, iAimTarget);
											SetEntPropFloat(iAimTarget, Prop_Data, "m_flLocalTime", 2.0);
											FakeClientCommand(client, "say 路障已修复但撑不了多久了！");
										}
									}
									new iColor = RoundToNearest((float(iHp) / 2000.0) * 255.0);
									SetEntityRenderColor(iAimTarget, iColor, iColor, iColor, 255);
									decl iColors[4] = {255, 255, 255, 255};
									iColors[1] = iColors[2] = iColor;
									SetVariantColor(iColors);
									AcceptEntityInput(iAimTarget, "SetGlowColor");
									SetEntProp(iAimTarget, Prop_Data, "m_iHealth", iHp);
									DispatchKeyValue(iAimTarget, "targetname", "LuaCustomModel");
								}
								else PrintCenterText(client, "按 \"使用键 (F) 和切出刀\" 来维修路障");
							}
							else PrintCenterText(client, "呼叫 \"霰弹专家\" 来维修路障");
						}
					}
				}
			}
		}
	}
	
	if (iWorkStatus == 0 && g_iPlayerDeployedWeapon[client] == WEAPON_KABAR)	// #Deployed weapon_kabar (1)
	{
		if (g_iPlayerCustomGear[client] > -1)
		{
			// Custom Knife View Model Firing Cycle Sequence
/*			if (g_iClientViewEntity[client] == -1 || !IsValidEntity(g_iClientViewEntity[client]))
				g_iClientViewEntity[client] = GetViewModelIndex(client);
			if (g_iClientViewEntity[client] != -1 && IsValidEntity(g_iClientViewEntity[client]))
			{
				new iSequence = GetEntProp(g_iClientViewEntity[client], Prop_Send, "m_nSequence");
				new Float:fCycle = GetEntPropFloat(g_iClientViewEntity[client], Prop_Data, "m_flCycle");
				if (fCycle < g_fClientViewOldCycle[client] && iSequence == g_iClientViewOldSequence[client])
				{
					switch (iSequence)
					{
						case 1: SetEntProp(g_iClientViewEntity[client], Prop_Send, "m_nSequence", 2);
						case 2: SetEntProp(g_iClientViewEntity[client], Prop_Send, "m_nSequence", 3);
						case 3: SetEntProp(g_iClientViewEntity[client], Prop_Send, "m_nSequence", 1);
					}
				}
				g_iClientViewOldSequence[client] = iSequence;
				g_fClientViewOldCycle[client] = fCycle;
			}		*/
			
			if (g_iPlayerCustomGear[client] > 0)
			{
				new iButtons = GetClientButtons(client);
				if ((iButtons & INS_AIM || iButtons & INS_AIM_TOGGLE) && GetEntityFlags(client) & FL_ONGROUND)
				{
					iWorkStatus = 2;
//					PrintToChatAll("%f   /  %d", g_fPlayerTempPropTimestamp[client], g_fPlayerTempPropTimestamp[client] == 0.0);
					if (g_fPlayerTempPropTimestamp[client] == 0.0 && g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]) && GetEntPropEnt(g_iPlayerTempProp[client], Prop_Data, "m_hOwnerEntity") != MaxClients+2)
					{
						decl String:targetname[64];
						GetEntPropString(g_iPlayerTempProp[client], Prop_Data, "m_iName", targetname, sizeof(targetname));
						if (StrEqual(targetname, "LuaCustomModel", true))
						{
							LogToGame("%N is installing new gear id %d therefore remove old one %d", client, g_iPlayerCustomGear[client], g_iPlayerTempProp[client]);
							// PrintToServer("Removing #12");
							new String:sModelPath[128];
							GetEntPropString(g_iPlayerTempProp[client], Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
							if (StrContains(sModelPath, "sec_hub", true) != -1)
								PrintToChatAll("\x04便携雷达 \x01并已被 \x08%s%N进行了替换", GetPlayerChatColor(client), client);
							else if (StrContains(sModelPath, "ins_radio", true) != -1)
								PrintToChatAll("\x04IED干扰器 \x01并已被 \x08%s%N进行了替换", GetPlayerChatColor(client), client);
							else if (StrContains(sModelPath, "ammocrate", true) != -1)
								PrintToChatAll("\x04弹药箱 \x01并已被 \x08%s%N进行了替换", GetPlayerChatColor(client), client);
							else if (StrContains(sModelPath, "sandbagwall", true) != -1 || StrContains(sModelPath, "prop_fortification_hesco", true) != -1 || StrContains(sModelPath, "barrier", true) != -1)
								PrintToChatAll("\x04路障 \x01并已被 \x08%s%N进行了替换", GetPlayerChatColor(client), client);
							RequestFrame(DeleteEntity, EntIndexToEntRef(g_iPlayerTempProp[client]));
						}
						g_iPlayerTempProp[client] = -1;
					}
					if (g_iPlayerTempProp[client] == -1 || !IsValidEntity(g_iPlayerTempProp[client]))
					{
						g_bPlayerTempPropSetup[client] = false;
						g_iPlayerTempProp[client] = CreateEntityByName("prop_dynamic_override");
						SetEntPropEnt(g_iPlayerTempProp[client], Prop_Data, "m_hOwnerEntity", -1);
//						g_iPlayerTempProp[client] = CreateEntityByName("dynamic_prop");
//						FakeClientCommand(client, "prop_dynamic_create static_military/sandbag_wall_short_b.mdl");
						if (g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]))
						{
							new iHealth = 500;
							if (g_iPlayerCustomGear[client] == 15)	//	Radar
								DispatchKeyValue(g_iPlayerTempProp[client], "model", "models/static_props/sec_hub.mdl");
							else if (g_iPlayerCustomGear[client] == 16)	//	IED Jammer
								DispatchKeyValue(g_iPlayerTempProp[client], "model", "models/static_props/ins_radio.mdl");
							else if (g_iPlayerCustomGear[client] == 17)	//	Barricade
							{
								iHealth = 2000;
								new iType = GetRandomInt(1, 4);
								switch(iType)
								{
//									case 0: DispatchKeyValue(g_iPlayerTempProp[client], "model", "models/static_military/sandbag_wall_short_b.mdl");
									case 1: DispatchKeyValue(g_iPlayerTempProp[client], "model", "models/static_fortifications/sandbagwall01.mdl");
									case 2: DispatchKeyValue(g_iPlayerTempProp[client], "model", "models/static_fortifications/sandbagwall02.mdl");
									case 3:
									{
										switch(GetRandomInt(0, 2))
										{
											case 0: DispatchKeyValue(g_iPlayerTempProp[client], "model", "models/generic/barrier_crete00a.mdl");
											case 1: DispatchKeyValue(g_iPlayerTempProp[client], "model", "models/props/concrete_barrier_stw02.mdl");
											case 2: DispatchKeyValue(g_iPlayerTempProp[client], "model", "models/static_fortifications/concrete_barrier_02.mdl");
//											case 3: DispatchKeyValue(g_iPlayerTempProp[client], "model", "models/static_fortifications/concrete_barrier_01.mdl");
										}
									}
									case 4: DispatchKeyValue(g_iPlayerTempProp[client], "model", "models/static_afghan/prop_fortification_hesco_small.mdl");
								}
								if (iType != 3)
									SetEntProp(g_iPlayerTempProp[client], Prop_Data, "m_nSkin", GetRandomInt(0, 1));
								SetEntPropEnt(g_iPlayerTempProp[client], Prop_Data, "m_hOwnerEntity", 0);
							}
							else if (g_iPlayerCustomGear[client] == 18)	//	Ammo Crate
							{
								iHealth = 1000;
								DispatchKeyValue(g_iPlayerTempProp[client], "model", "models/generic/ammocrate3.mdl");
							}
							DispatchKeyValue(g_iPlayerTempProp[client], "physdamagescale", "0.0");
							DispatchKeyValue(g_iPlayerTempProp[client], "targetname", "LuaCustomModel");
							DispatchKeyValue(g_iPlayerTempProp[client], "Solid", "6");
							DispatchSpawn(g_iPlayerTempProp[client]);
//							ActivateEntity(g_iPlayerTempProp[client]);
							SetVariantInt(iHealth);
							AcceptEntityInput(g_iPlayerTempProp[client], "SetHealth");
//							SetVariantInt(5);
//							AcceptEntityInput(g_iPlayerTempProp[client], "CollisionGroup");
//							AcceptEntityInput(g_iPlayerTempProp[client], "EnableCollision");
//							AcceptEntityInput(g_iPlayerTempProp[client], "Enable");
//							AcceptEntityInput(g_iPlayerTempProp[client], "TurnOn", g_iPlayerTempProp[client], g_iPlayerTempProp[client], 0);
							SetEntityRenderMode(g_iPlayerTempProp[client], RENDER_TRANSALPHA);
							SetEntityMoveType(g_iPlayerTempProp[client], MOVETYPE_VPHYSICS);
/*							for (new i = 1;i <= MaxClients;i++)
							{
								if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INSURGENTS)
								{
									SetEntPropEnt(g_iPlayerTempProp[client], Prop_Data, "m_hOwnerEntity", i);
									break;
								}
							}	*/
							SetEntProp(g_iPlayerTempProp[client], Prop_Data, "m_iMaxHealth", iHealth);
//							PrintToChatAll("%d", GetEntProp(g_iPlayerTempProp[client], Prop_Data, "m_CollisionGroup"));
							g_fPlayerTempPropTimestamp[client] = GetGameTime()+60.0;
						}
					}

					if (g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]))
					{
						g_fGameTime = GetGameTime();
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
								new Float:vAngle[3], Float:vPos[3], Float:fDistance, bool:bFailed = false;
								GetClientEyeAngles(client, vAngle);
								GetClientEyePosition(client, vPos);
								new Float:fAngle = vAngle[1];
//								new Handle:hTrace = TR_TraceRayFilterEx(vPos, vAngle, MASK_SOLID, RayType_Infinite, Filter_Not_ClientAndEntity, client);
								new Handle:hTrace = TR_TraceRayFilterEx(vPos, vAngle, MASK_SOLID, RayType_Infinite, Filter_Not_PlayersAndEntity, client);
								if (TR_DidHit(hTrace))
								{
									TR_GetEndPosition(g_vPlayerTempPropOrigin[client], hTrace);
									TR_GetPlaneNormal(hTrace, vAngle);
									GetVectorAngles(vAngle, vAngle);
									vAngle[0] += 90.0;
									if (g_iPlayerCustomGear[client] == 15)
									{
										if (vAngle[0] >= 340.0 && vAngle[0] <= 380.0) vAngle[1] = fAngle+180.0;
										else bFailed = true;
									}
									else if (g_iPlayerCustomGear[client] == 16)
									{
										if (vAngle[0] >= 340.0 && vAngle[0] <= 380.0) vAngle[1] = fAngle-90.0;
										else bFailed = true;
									}
									else if (g_iPlayerCustomGear[client] == 17)
									{
										new String:sModelPath[128];
										GetEntPropString(g_iPlayerTempProp[client], Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
										if (!StrEqual(sModelPath, "models/static_fortifications/sandbagwall02.mdl", true))
										{
											if (vAngle[0] >= 340.0 && vAngle[0] <= 395.0) vAngle[1] = fAngle+180.0;
											else bFailed = true;
											if (StrEqual(sModelPath, "models/static_afghan/prop_fortification_hesco_small.mdl", true))
												g_vPlayerTempPropOrigin[client][2] += 0.3;
										}
										else
										{
											if (vAngle[0] >= 340.0 && vAngle[0] <= 395.0) vAngle[1] = fAngle;
											else bFailed = true;
										}
									}
									else if (g_iPlayerCustomGear[client] == 18)
									{
										if (vAngle[0] >= 340.0 && vAngle[0] <= 380.0) vAngle[1] = fAngle-270.0;
										else bFailed = true;
									}
//									PrintToChatAll("%0.1f, %0.1f, %0.1f", vAngle[0], vAngle[1], vAngle[2]);
/*									}
									else
									{
										vAngle[0] = 0.0;
//										TeleportEntity(g_iPlayerTempProp[client], Float:{-4000.0, 0.0, -4000.0}, NULL_VECTOR, NULL_VECTOR);
										bFailed = true;
									}	*/
								}
								else
								{
									bFailed = true;
									g_vPlayerTempPropOrigin[client][0] = -9000.0;
								}
								CloseHandle(hTrace);

								fDistance = GetVectorDistance(g_vPlayerTempPropOrigin[client], vPos);
								if (!bFailed && (g_iPlayerCustomGear[client] != 17 && fDistance <= 100.0) || (g_iPlayerCustomGear[client] == 17 && fDistance <= 140.0))
								{
									new Float:vMins[3], Float:vMaxs[3];
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
										if (g_iPlayerCustomGear[client] == 15)
										{
											g_fPlayerTempPropTimestamp[client] = g_fGameTime+5.0;
											if (g_fGameTime-g_fPlayerLastChat[client] >= 3.0)
											{
												g_fPlayerLastChat[client] = g_fGameTime;
												FakeClientCommand(client, "say 正在布置便携雷达...");
											}
										}
										else if (g_iPlayerCustomGear[client] == 16)
										{
											g_fPlayerTempPropTimestamp[client] = g_fGameTime+6.0;
											if (g_fGameTime-g_fPlayerLastChat[client] >= 3.0)
											{
												g_fPlayerLastChat[client] = g_fGameTime;
												FakeClientCommand(client, "say 正在布置IED干扰器...");
											}
										}
										else if (g_iPlayerCustomGear[client] == 17)
										{
											g_fPlayerTempPropTimestamp[client] = g_fGameTime+5.0;
											if (g_fGameTime-g_fPlayerLastChat[client] >= 3.0)
											{
												g_fPlayerLastChat[client] = g_fGameTime;
												FakeClientCommand(client, "say 正在布置路障...");
											}
										}
										else if (g_iPlayerCustomGear[client] == 18)
										{
											g_fPlayerTempPropTimestamp[client] = g_fGameTime+8.0;
											if (g_fGameTime-g_fPlayerLastChat[client] >= 3.0)
											{
												g_fPlayerLastChat[client] = g_fGameTime;
												FakeClientCommand(client, "say 正在布置弹药箱...");
											}
										}
//										g_fPlayerTempPropTimestamp[client] = g_fGameTime+1.0;
//										ClientCommand(client, "insradial need_backup");
										LogToGame("%N is installing gear id %d", client, g_iPlayerCustomGear[client]);
									}
									else
									{
	//									RequestFrame(DeleteEntity, EntIndexToEntRef(g_iPlayerTempProp[client]));
	//									g_iPlayerTempProp[client] = -1;
	//									g_fPlayerTempPropCooldown[client] = g_fGameTime+1.5;
//										new iHit = TR_GetEntityIndex(INVALID_HANDLE);
//										if (iHit >= 1 && iHit <= MaxClients)
//											TeleportEntity(g_iPlayerTempProp[client], Float:{-4000.0, 0.0, -4000.0}, NULL_VECTOR, NULL_VECTOR);
//										else
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
//											SetEntityRenderColor(g_iPlayerTempProp[client], 255, 255, 255, 0);
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
//										SetEntityRenderColor(g_iPlayerTempProp[client], 255, 255, 255, 0);
										TeleportEntity(g_iPlayerTempProp[client], Float:{-4000.0, 0.0, -4000.0}, NULL_VECTOR, NULL_VECTOR);
									}
								}
							}
						}
						else
						{
							if (g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]))
							{
								new Float:vPos[3], Float:fDistance, bool:bFailed = true;
								GetClientEyePosition(client, vPos);
								fDistance = GetVectorDistance(g_vPlayerTempPropOrigin[client], vPos);
								if ((g_iPlayerCustomGear[client] != 17 && fDistance <= 100.0) || (g_iPlayerCustomGear[client] == 17 && fDistance <= 140.0))
								{
									g_vPlayerTempPropOrigin[client][2] += 16.0;
									new Handle:hTrace = TR_TraceRayFilterEx(vPos, g_vPlayerTempPropOrigin[client], MASK_SOLID, RayType_EndPoint, Filter_Not_PlayersAndEntity, client);
									g_vPlayerTempPropOrigin[client][2] -= 16.0;
									if (!TR_DidHit(hTrace))
									{
										// Retrieve view and target eyes position
										decl Float:vAngle[3], Float:vAngleVec[3], Float:fVector[3], Float:fDir[3];

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
											
											new Float:fRemainTime = g_fPlayerTempPropTimestamp[client]-g_fGameTime;
											if (fRemainTime > 0.0)
											{
												new Float:fDirection[3];
												fDirection[0] = GetRandomFloat(-1.0, 1.0);
												fDirection[1] = GetRandomFloat(-1.0, 1.0);
												fDirection[2] = GetRandomFloat(-1.0, 1.0);
												// new Float:vMaxs[3];
//												GetEntPropVector(g_iPlayerTempProp[client], Prop_Data, "m_vecMaxs", vMaxs);
//												g_vPlayerTempPropOrigin[client][2] += vMaxs[2]/2;
												g_vPlayerTempPropOrigin[client][2] += 12.0;
												TE_SetupSparks(g_vPlayerTempPropOrigin[client], fDirection, 1, 1);
												g_vPlayerTempPropOrigin[client][2] -= 12.0;
//												g_vPlayerTempPropOrigin[client][2] -= vMaxs[2]/2;
												TE_SendToAll();
												new iAlpha = 80+RoundToNearest(175*(8.0-fRemainTime)/10);
												if (g_iPlayerCustomGear[client] == 15)
													PrintCenterText(client, "正在布置便携雷达...\n\n%0.1f s", fRemainTime);
												else if (g_iPlayerCustomGear[client] == 16)
													PrintCenterText(client, "正在布置IED干扰器...\n\n%0.1f s", fRemainTime);
												else if (g_iPlayerCustomGear[client] == 17)
												{
													if (iAlpha < 180)
													{
														new String:sModelPath[128];
														GetEntPropString(g_iPlayerTempProp[client], Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
														if (StrContains(sModelPath, "prop_fortification_hesco", true) != -1)
															iAlpha = 180;
													}
													PrintCenterText(client, "正在布置路障...\n\n%0.1f s", fRemainTime);
												}
												else if (g_iPlayerCustomGear[client] == 18)
												{
													if (iAlpha < 180) iAlpha = 180;
													PrintCenterText(client, "正在布置弹药箱...\n\n%0.1f s", fRemainTime);
												}
												SetEntityRenderColor(g_iPlayerTempProp[client], 255, 255, 255, iAlpha);
											}
											else
											{
												LogToGame("%N is finished install gear id %d", client, g_iPlayerCustomGear[client]);
												PrintCenterText(client, " ");
												SwapWeaponToPrimary(client);
//												ClientCommand(client, "lastinv");
												g_fPlayerTempPropTimestamp[client] = 0.0;
												if (g_iPlayerCustomGear[client] == 15)
												{
													g_iPlayerBonusScore[client] += 100;
													FakeClientCommand(client, "say 便携雷达已布置！");
													SetVariantColor({100, 100, 255, 255});
													new Handle:hData;
													CreateDataTimer(1.0, Timer_GearPortableRadar, hData, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
													WritePackCell(hData, EntIndexToEntRef(g_iPlayerTempProp[client]));
													WritePackFloat(hData, GetGameTime());
												}
												else if (g_iPlayerCustomGear[client] == 16)
												{
													g_iPlayerBonusScore[client] += 100;
													FakeClientCommand(client, "say IED干扰器已布置！");
													SetVariantColor({100, 255, 100, 255});
													new Handle:hData;
													CreateDataTimer(0.5, Timer_GearIEDJammer, hData, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
													WritePackCell(hData, EntIndexToEntRef(g_iPlayerTempProp[client]));
													WritePackFloat(hData, GetGameTime());
												}
												else if (g_iPlayerCustomGear[client] == 17)
												{
													g_iPlayerBonusScore[client] += 100;
													SetVariantColor({255, 255, 255, 255});
													FakeClientCommand(client, "say 路障已布置！");
												}
												else if (g_iPlayerCustomGear[client] == 18)
												{
													g_iPlayerBonusScore[client] += 200;
													SetEntPropFloat(g_iPlayerTempProp[client], Prop_Data, "m_flLocalTime", 4.0);
													FakeClientCommand(client, "say 弹药箱已布置！");
													SetVariantColor({255, 255, 102, 255});
													new Handle:hData;
													CreateDataTimer(0.1, Timer_GearAmmoCrate, hData, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
													WritePackCell(hData, EntIndexToEntRef(g_iPlayerTempProp[client]));
													WritePackFloat(hData, GetGameTime());
												}
												SetEntityRenderMode(g_iPlayerTempProp[client], RENDER_NORMAL);
												SetEntityRenderColor(g_iPlayerTempProp[client], 255, 255, 255, 255);
												AcceptEntityInput(g_iPlayerTempProp[client], "SetGlowColor");
												SetEntProp(g_iPlayerTempProp[client], Prop_Send, "m_bShouldGlow", true);
												SetEntPropFloat(g_iPlayerTempProp[client], Prop_Send, "m_flGlowMaxDist", 2000.0);
												g_iPlayerCustomGear[client] = 0;
//												SetEntProp(g_iPlayerTempProp[client], Prop_Data, "m_nSolidType", 6);
		//										SetEntProp(g_iPlayerTempProp[client], Prop_Data, "m_usSolidFlags", 2048);
	//											SetEntProp(g_iPlayerTempProp[client], Prop_Send, "m_nSolidType", 6);
//												SetEntProp(g_iPlayerTempProp[client], Prop_Send, "m_usSolidFlags", 2048);
												SetEntProp(g_iPlayerTempProp[client], Prop_Data, "m_takedamage", 2);
												SDKHook(g_iPlayerTempProp[client], SDKHook_Touch, SHook_OnTouch);
												SDKHook(g_iPlayerTempProp[client], SDKHook_OnTakeDamage, SHook_OnTakeDamageGear);
												HookSingleEntityOutput(g_iPlayerTempProp[client], "OnHealthChanged", OnGearDamaged, false);
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
									// PrintToServer("Removing #5");
									RequestFrame(DeleteEntity, EntIndexToEntRef(g_iPlayerTempProp[client]));
//									PrintCenterText(client, " ");
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
						// PrintToServer("Removing #6");
						LogToGame("%N is cancelled installing gear id %d (%d)", client, g_iPlayerCustomGear[client], g_iPlayerTempProp[client]);
						RequestFrame(DeleteEntity, EntIndexToEntRef(g_iPlayerTempProp[client]));
						g_iPlayerTempProp[client] = -1;
						PrintCenterText(client, "已取消布置");
						g_fPlayerTempPropCooldown[client] = GetGameTime()+0.6;
					}
					g_fPlayerTempPropTimestamp[client] = 0.0;
					g_bPlayerTempPropSetup[client] = false;
				}
			}
		}
	}
	if (iWorkStatus == 0 && g_iPlayerDeployedWeapon[client] == WEAPON_HEALTHKIT)	// #Deployed weapon_healthkit (40)
	{
		iWorkStatus = 3;
		if (Healthkit_HasHolding(client))
		{
			new iType = -1;	// 0: Self, 1: Teammate
			new iTarget;
			new bool:bMedic = g_bMedicPlayer[client]?true:false;
			new iButtons = GetClientButtons(client);
			new iCheckHealing = Healthkit_CheckHealing(client); // -1: None, 0: Self, 1: Teammate, 2: Healing by Teammate
			if (iCheckHealing == -1 && (g_iPlayerHealthkitTarget[client] != -1 || g_iPlayerHealthkitHealingBy[client] != -1))
			{
				if (g_iPlayerHealthkitTarget[client] != client && g_iPlayerHealthkitTarget[client] > -1)
				{
					PrintCenterText(g_iPlayerHealthkitTarget[client], " ");
					g_fPlayerHealthkitBandaging[g_iPlayerHealthkitTarget[client]] = 0.0;
					g_iPlayerHealthkitHealingBy[g_iPlayerHealthkitTarget[client]] = -1;
				}
				if (g_iPlayerHealthkitHealingBy[client] != client && g_iPlayerHealthkitHealingBy[client] > -1)
				{
					PrintCenterText(g_iPlayerHealthkitHealingBy[client], " ");
					g_iPlayerHealthkitTarget[g_iPlayerHealthkitHealingBy[client]] = -1;
				}
				PrintCenterText(client, " ");
				g_fPlayerHealthkitBandaging[client] = 0.0;
				g_iPlayerHealthkitTarget[client] = -1;
				g_iPlayerHealthkitHealingBy[client] = -1;
			}
			if (iButtons & INS_ATTACK1)
			{
				iWorkStatus = 4;
				if (iCheckHealing != 2 || (iCheckHealing == 2 && bMedic))
				{
					if (iCheckHealing == 1)
					{
						g_fPlayerHealthkitBandaging[g_iPlayerHealthkitTarget[client]] = 0.0;
						g_iPlayerHealthkitHealingBy[g_iPlayerHealthkitTarget[client]] = -1;
						PrintCenterText(g_iPlayerHealthkitTarget[client], " ");
					}
					g_iPlayerHealthkitTarget[client] = client;
					g_iPlayerHealthkitHealingBy[client] = client;
					iTarget = client;
					iType = 0;
					iCheckHealing = 0;
				}
			}
			else if (iButtons & INS_AIM || iButtons & INS_AIM_TOGGLE)
			{
				iWorkStatus = 5;
				iType = 1;
				if (iCheckHealing == 1)
				{
					iTarget = g_iPlayerHealthkitTarget[client];
					new Float:fTargetPos[3], Float:fPlayerPos[3];
					GetClientAbsOrigin(client, fPlayerPos);
					GetClientAbsOrigin(iTarget, fTargetPos);
					if (GetVectorDistance(fPlayerPos, fTargetPos) > FCVAR_PLAYER_HEALTHKIT_TEAMMATE_DISTANCE_MAX)
					{
						PrintCenterText(client, " ");
						PrintCenterText(iTarget, " ");
						g_fPlayerHealthkitBandaging[iTarget] = 0.0;
						g_iPlayerHealthkitTarget[client] = -1;
						g_iPlayerHealthkitHealingBy[iTarget] = -1;
						iType = -1;
						iTarget = -1;
					}
				}
				else if (iCheckHealing == 0)
				{
					PrintCenterText(client, " ");
					g_fPlayerHealthkitBandaging[client] = 0.0;
					g_iPlayerHealthkitTarget[client] = -1;
					g_iPlayerHealthkitHealingBy[client] = -1;
					iCheckHealing = -1;
				}
			}
			else
			{
				if (iCheckHealing == 0)
				{
					PrintCenterText(client, " ");
					g_fPlayerHealthkitBandaging[client] = 0.0;
					g_iPlayerHealthkitTarget[client] = -1;
					g_iPlayerHealthkitHealingBy[client] = -1;
					iCheckHealing = -1;
				}
				else if (iCheckHealing == 1)
				{
					PrintCenterText(client, " ");
					g_fPlayerHealthkitBandaging[g_iPlayerHealthkitTarget[client]] = 0.0;
					g_iPlayerHealthkitHealingBy[g_iPlayerHealthkitTarget[client]] = -1;
					PrintCenterText(g_iPlayerHealthkitTarget[client], " ");
					g_iPlayerHealthkitTarget[client] = -1;
					iCheckHealing = -1;
				}
			}
			if (iType != -1)
			{
				new iHp, iNewHp;
				if (g_fPlayerHealthkitBandaging[iTarget] != 0.0)
				{
					iNewHp = iHp = GetEntProp(iTarget, Prop_Send, "m_iHealth");
					new Float:fRemainTime, Float:fBandageTime;
					if (!bMedic)
					{
						fBandageTime = ((CVAR_PLAYER_HEALTHKIT_MAX_HEALTH-iHp)/10)*FCVAR_PLAYER_HEALTHKIT_BANDAGE_BASE_TIME;
	//					if (g_iPlayerBleeding[iTarget] != 0) fBandageTime += 1.0;
						fRemainTime = (fBandageTime>=FCVAR_PLAYER_HEALTHKIT_BANDAGE_MIN_TIME?fBandageTime:FCVAR_PLAYER_HEALTHKIT_BANDAGE_MIN_TIME)+g_fPlayerHealthkitBandaging[iTarget]-g_fGameTime;
					}
					else
					{
						fBandageTime = ((CVAR_PLAYER_HEALTHKIT_MEDIC_MAX_HEALTH-iHp)/10)*FCVAR_PLAYER_HEALTHKIT_MEDIC_BANDAGE_BASE_TIME;
	//					if (g_iPlayerBleeding[iTarget] != 0) fBandageTime += 1.0;
						fRemainTime = (fBandageTime>=FCVAR_PLAYER_HEALTHKIT_MEDIC_BANDAGE_MIN_TIME?fBandageTime:FCVAR_PLAYER_HEALTHKIT_MEDIC_BANDAGE_MIN_TIME)+g_fPlayerHealthkitBandaging[iTarget]-g_fGameTime;
					}
					if (fRemainTime > 0.0)
					{
						/*if (GetEntProp(client, Prop_Send, "m_iCurrentStance") == 0)
						{
							SetEntProp(client, Prop_Send, "m_iCurrentStance", 1);
							SetEntProp(client, Prop_Data, "m_bDuckEnabled", 1);
						}*/
						if (iType == 0)
							PrintCenterText(client, "正在绑绷带...\n\n%0.1f 秒", fRemainTime);
						else if (iType == 1)
						{
							PrintCenterText(client, "正在绑绷带...\n\n%N    %0.1f 秒", iTarget, fRemainTime);
							PrintCenterText(iTarget, "正在绑绷带...\n\n%N    %0.1f 秒", client, fRemainTime);
							if (g_iLastHealTarget[client] != iTarget || g_fGameTime-g_fLastHealingTime[client] >= 15.0)
							{
								g_iLastHealTarget[client] = iTarget;
								g_fLastHealingTime[client] = g_fGameTime;
								decl String:sSoundFile[128];
//								if (iHp <= CVAR_PLAYER_GLOW_HEALTH || g_iPlayerBleeding[iTarget] != 0 || (g_fBurnTime[iTarget] != 0.0 || GetEntityFlags(iTarget)&FL_ONFIRE))
								if (iHp > CVAR_PLAYER_GLOW_HEALTH)
									Format(sSoundFile, sizeof(sSoundFile), "lua_sounds/medic/letme/medic_letme_bandage%d.ogg", GetRandomInt(1, 18));
								else
									Format(sSoundFile, sizeof(sSoundFile), "lua_sounds/medic/letme/medic_letme_heal%d.ogg", GetRandomInt(1, 7));
								EmitSoundToAll(sSoundFile, client, SNDCHAN_VOICE, _, _, 1.0);
							}
							if (bMedic && !g_bMedicForceToChange[client]) g_fMedicLastHealTime[client] = g_fGameTime;
						}
					}
					else
					{
						PrintCenterText(client, "已治疗 ！");
						if (iType == 1) PrintCenterText(iTarget, "已治疗 ！");
						// StopSound(client, SNDCHAN_STATIC, "Lua_sounds/bandaging.wav");
						EmitSoundToAll("player/focus_exhale.wav", iTarget, SNDCHAN_STATIC, _, _, 1.0);
						new iAmmoOffset = GetEntProp(g_iPlayerHealthkitDeploy[client], Prop_Data, "m_iPrimaryAmmoType");
						new iAmmo = GetEntProp(client, Prop_Data, "m_iAmmo", _, iAmmoOffset);
						if (!bMedic || !BCVAR_PLAYER_HEALTHKIT_MEDIC_INF_BANDAGE)
						{
//							ClientCommand(client, "lastinv");
	//						new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo") + (GetEntProp(g_iPlayerHealthkitDeploy[client], Prop_Data, "m_iPrimaryAmmoType") * 4);
							if (iAmmo <= 1)
							{
	//							RemovePlayerItem(client, g_iPlayerHealthkitDeploy[client]);
	//							SDKHooks_DropWeapon(client, g_iPlayerHealthkitDeploy[client], NULL_VECTOR, NULL_VECTOR);
								SwapWeaponToPrimary(client);
								AcceptEntityInput(g_iPlayerHealthkitDeploy[client], "Kill");
							}
							else SetEntProp(client, Prop_Data, "m_iAmmo", iAmmo-1, _, iAmmoOffset);
//							g_iPlayerHealthkitDeploy[client] = -1;
						}
						if (!bMedic)
						{
							if (iHp < CVAR_PLAYER_HEALTHKIT_MAX_HEALTH)
							{
								iNewHp = iHp+GetRandomInt(CVAR_PLAYER_HEALTHKIT_HEAL_MIN, CVAR_PLAYER_HEALTHKIT_HEAL_MAX);
								if (iNewHp > CVAR_PLAYER_HEALTHKIT_MAX_HEALTH) iNewHp = CVAR_PLAYER_HEALTHKIT_MAX_HEALTH;
							}
							LogToGame("\"%N\" has used first aid! (HP: %d -> %d, Target: %N, Bleeding: %d, Infected: %d)", client, iHp, iNewHp, iTarget, g_iPlayerBleeding[iTarget], g_iPlayerInfected[iTarget]);
							if (iType == 0)
							{
								g_iPlayerBonusScore[client] += 40;
								if (iNewHp >= CVAR_PLAYER_HEALTHKIT_MIN_HEALTH)
								{
									SwapWeaponToPrimary(client);
									g_fLastMedicCall[client] = 0.0;
									g_iPlayerHealthkitDeploy[client] = -1;
								}
								PrintToChatAll("\x08%s%N \x01对自己使用了医疗包   (%d \x04-> \x01%d HP)", GetPlayerChatColor(client), client, iHp, iNewHp);
							}
							else if (iType == 1)
							{
								g_iPlayerBonusScore[client] += 100;
								if (iNewHp >= CVAR_PLAYER_HEALTHKIT_MIN_HEALTH)
								{
									SwapWeaponToPrimary(client);
									g_fLastMedicCall[iTarget] = 0.0;
									decl String:sSoundFile[128];
									Format(sSoundFile, sizeof(sSoundFile), "lua_sounds/medic/healed/medic_healed%d.ogg", GetRandomInt(1, 38));
									EmitSoundToAll(sSoundFile, client, SNDCHAN_VOICE, _, _, 1.0);
									CreateTimer(GetRandomFloat(2.0, 2.5), Timer_MedicThanks, iTarget, TIMER_FLAG_NO_MAPCHANGE);
									g_iPlayerHealthkitDeploy[client] = -1;
								}
								else if (iAmmo <= 1)
								{
									decl String:sSoundFile[128];
									Format(sSoundFile, sizeof(sSoundFile), "lua_sounds/medic/thx/medic_thanks%d.ogg", GetRandomInt(1, 20));
									EmitSoundToAll(sSoundFile, iTarget, SNDCHAN_VOICE, _, _, 1.0);
								}
								PrintToChatAll("\x08%s%N \x01对\x08%s%N使用了医疗包   \x01(%d \x04-> \x01%d HP)", GetPlayerChatColor(client), client, GetPlayerChatColor(iTarget), iTarget, iHp, iNewHp);
							}
						}
						else
						{
							if (iHp < CVAR_PLAYER_HEALTHKIT_MEDIC_MAX_HEALTH)
							{
//								iNewHp = iHp+GetRandomInt(RoundToNearest(float(CVAR_PLAYER_HEALTHKIT_HEAL_MIN)*1.5), RoundToNearest(float(CVAR_PLAYER_HEALTHKIT_HEAL_MAX)*1.5));
								iNewHp = iHp+GetRandomInt(CVAR_PLAYER_HEALTHKIT_HEAL_MIN, CVAR_PLAYER_HEALTHKIT_HEAL_MAX);
								if (iNewHp > CVAR_PLAYER_HEALTHKIT_MEDIC_MAX_HEALTH) iNewHp = CVAR_PLAYER_HEALTHKIT_MEDIC_MAX_HEALTH;
							}
							LogToGame("[MEDIC] \"%N\" has used first aid! (HP: %d -> %d, Target: %N, Bleeding: %d, Infected: %d)", client, iHp, iNewHp, iTarget, g_iPlayerBleeding[iTarget], g_iPlayerInfected[iTarget]);
							if (iType == 0)
							{
								g_iPlayerBonusScore[client] += 20;
//								if (iNewHp >= CVAR_PLAYER_HEALTHKIT_MEDIC_MAX_HEALTH-15)
								if (iNewHp >= CVAR_PLAYER_HEALTHKIT_MEDIC_MIN_HEALTH)
								{
									// SwapWeaponToPrimary(client);
									// g_iPlayerHealthkitDeploy[client] = -1;
									g_fLastMedicCall[client] = 0.0;
								}
								PrintToChatAll("\x08%s[医疗]  \x08%s%N \x01对自己使用了医疗包   (%d \x04-> \x01%d HP)", COLOR_GOLD, GetPlayerChatColor(client), client, iHp, iNewHp);
							}
							else if (iType == 1)
							{
								g_iPlayerBonusScore[client] += 50;
								if (g_bMedicForceToChange[client])
								{
									g_bMedicForceToChange[client] = false;
									g_fMedicLastHealTime[client] = g_fGameTime;
								}
//								if (iNewHp >= CVAR_PLAYER_HEALTHKIT_MEDIC_MAX_HEALTH-15)
								if (iNewHp >= CVAR_PLAYER_HEALTHKIT_MEDIC_MIN_HEALTH)
								{
									// SwapWeaponToPrimary(client);
									// g_iPlayerHealthkitDeploy[client] = -1;
									g_fLastMedicCall[iTarget] = 0.0;
									decl String:sSoundFile[128];
									Format(sSoundFile, sizeof(sSoundFile), "lua_sounds/medic/healed/medic_healed%d.ogg", GetRandomInt(1, 38));
									EmitSoundToAll(sSoundFile, client, SNDCHAN_VOICE, _, _, 1.0);
									CreateTimer(GetRandomFloat(2.0, 2.5), Timer_MedicThanks, iTarget, TIMER_FLAG_NO_MAPCHANGE);
								}
								PrintToChatAll("\x08%s[医疗]  \x08%s%N \x01对\x08%s%N使用了医疗包   \x01(%d \x04-> \x01%d HP)", COLOR_GOLD, GetPlayerChatColor(client), client, GetPlayerChatColor(iTarget), iTarget, iHp, iNewHp);
							}
						}
/*						if (g_iPlayerManager != -1 && g_iOffsetAssists != -1)
						{
							new iScore = GetEntData(g_iPlayerManager, g_iOffsetAssists+(client*4));
							SetEntData(g_iPlayerManager, g_iOffsetAssists+(client*4), iScore+10);
//							new iScore = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iPlayerScore", _, client);
//							SetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iPlayerScore", iScore+60, _, client);
							PrintToChat(client, "Score %d -> %d", iScore, GetEntData(g_iPlayerManager, g_iOffsetAssists+(client*4)));
						}	*/
						if (iHp != iNewHp) SetEntProp(iTarget, Prop_Send, "m_iHealth", iNewHp);
						// SetEntityMoveType(client, MOVETYPE_WALK);
						g_fPlayerHealthkitBandaging[iTarget] = 0.0;
						g_iPlayerHealthkitTarget[client] = -1;
						g_iPlayerHealthkitHealingBy[iTarget] = -1;
						g_iPlayerBleeding[iTarget] = 0;
						g_fPlayerBleedTime[iTarget] = 0.0;
						g_iPlayerInfected[iTarget] = 0;
						g_fNextInfection[iTarget] = 0.0;
						SetEntityRenderColor(iTarget, 255, 255, 255, 255);
					}
				}
				else
				{
					if (iType == 0)
					{
						iHp = GetEntProp(client, Prop_Send, "m_iHealth");
						if (!Healthkit_CheckCondition(client, bMedic, iHp))
						{
							iTarget = -1;
							PrintCenterText(client, "\n\n无需治疗  (%d HP)", iHp);
						}
					}
					else if (iType == 1)
					{
						iTarget = iAimTarget;
						if (iTarget > 0 && iTarget <= MaxClients && IsPlayerAlive(iTarget) && GetClientTeam(iTarget) == TEAM_SURVIVORS)
						{
							new Float:fTargetPos[3], Float:fPlayerPos[3], Float:fDistance;
							GetClientAbsOrigin(client, fPlayerPos);
							GetClientAbsOrigin(iTarget, fTargetPos);
							fDistance = GetVectorDistance(fPlayerPos, fTargetPos);
							if (fDistance <= FCVAR_PLAYER_HEALTHKIT_TEAMMATE_DISTANCE_MAX*1.5)
							{
								iHp = GetEntProp(iTarget, Prop_Send, "m_iHealth");
								if (Healthkit_CheckCondition(iTarget, bMedic, iHp))
								{
									if (fDistance <= FCVAR_PLAYER_HEALTHKIT_TEAMMATE_DISTANCE_INIT)
									{
										if (!bMedic)
										{
											if (g_iPlayerHealthkitHealingBy[iTarget] == -1)
											{
												g_iPlayerHealthkitHealingBy[iTarget] = client;
												g_iPlayerHealthkitTarget[client] = iTarget;
												if (Healthkit_HasHolding(iTarget)) SwapWeaponToPrimary(iTarget);
											}
											else iTarget = -1;
										}
										else
										{
											if (g_iPlayerHealthkitHealingBy[iTarget] == -1)
											{
												g_iPlayerHealthkitHealingBy[iTarget] = client;
												g_iPlayerHealthkitTarget[client] = iTarget;
												if (Healthkit_HasHolding(iTarget)) SwapWeaponToPrimary(iTarget);
											}
											else
											{
												if (GetEntityFlags(iTarget) & FL_ONGROUND && GetEntityFlags(client) & FL_ONGROUND && GetEntData(g_iPlayerHealthkitDeploy[client], g_iOffsetDeployTimer) <= -0.9)
												{
													/*if (GetEntProp(client, Prop_Send, "m_iCurrentStance") == 0)
													{
														SetEntProp(client, Prop_Send, "m_iCurrentStance", 1);
														SetEntProp(client, Prop_Data, "m_bDuckEnabled", 1);
													}*/
													if (g_iPlayerHealthkitHealingBy[iTarget] != iTarget)
													{
														g_iPlayerHealthkitTarget[g_iPlayerHealthkitHealingBy[iTarget]] = -1;
														if (Healthkit_HasHolding(g_iPlayerHealthkitHealingBy[iTarget])) SwapWeaponToPrimary(iTarget);
													}
													g_iPlayerHealthkitHealingBy[iTarget] = client;
													g_iPlayerHealthkitTarget[client] = iTarget;
													if (Healthkit_HasHolding(iTarget)) SwapWeaponToPrimary(iTarget);
													TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
//													SetEntityMoveType(client, MOVETYPE_NONE);
													// SetEntityMoveType(iTarget, MOVETYPE_WALK);
//													EmitSoundToAll("Lua_sounds/bandaging.wav", client, SNDCHAN_STATIC, _, _, 0.8);
													// StopSound(iTarget, SNDCHAN_STATIC, "Lua_sounds/bandaging.wav");
												}
												iTarget = -1; // Set to -1 for Handling its own;
											}
										}
									}
									else
									{
										PrintCenterText(client, "%N\n\n距离过远  (%0.1f 米)", iTarget, fDistance*0.01905);
										iTarget = -1;
									}
								}
								else
								{
									PrintCenterText(client, "%N\n\n无需治疗  (%d HP)", iTarget, iHp);
									iTarget = -1;
								}
							}
							else iTarget = -1;
						}
						else iTarget = -1;
					}
					if (iTarget > 0)
					{
						if (GetEntityFlags(client) & FL_ONGROUND && ((iType == 1 && GetEntityFlags(iTarget) & FL_ONGROUND) || iType == 0))
						{
							if (GetEntData(g_iPlayerHealthkitDeploy[client], g_iOffsetDeployTimer) <= -0.9)	// when deploytimer has ended value has -1.0
							{
								/*if (GetEntProp(client, Prop_Send, "m_iCurrentStance") == 0)
								{
									SetEntProp(client, Prop_Send, "m_iCurrentStance", 1);
									SetEntProp(client, Prop_Data, "m_bDuckEnabled", 1);
								}*/
								if (iType == 1 && Healthkit_HasHolding(iTarget)) SwapWeaponToPrimary(iTarget);
								g_iPlayerHealthkitHealingBy[iTarget] = client;
								g_iPlayerHealthkitTarget[client] = iTarget;
								TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
//								SetEntityMoveType(client, MOVETYPE_NONE);
//								EmitSoundToAll("Lua_sounds/bandaging.wav", client, SNDCHAN_STATIC, _, _, 0.8);
								g_fPlayerHealthkitBandaging[iTarget] = g_fGameTime;
							}
						}
					}
				}
			}
			else
			{
				if (iCheckHealing == 0)
				{
					PrintCenterText(client, " ");
					g_fPlayerHealthkitBandaging[client] = 0.0;
					g_iPlayerHealthkitTarget[client] = -1;
					g_iPlayerHealthkitHealingBy[client] = -1;
				}
				else if (iCheckHealing == 1)
				{
					if (g_iPlayerHealthkitTarget[client] > -1)
					{
						g_fPlayerHealthkitBandaging[g_iPlayerHealthkitTarget[client]] = 0.0;
						g_iPlayerHealthkitHealingBy[g_iPlayerHealthkitTarget[client]] = -1;
						PrintCenterText(g_iPlayerHealthkitTarget[client], " ");
					}
					PrintCenterText(client, " ");
					g_iPlayerHealthkitTarget[client] = -1;
				}
			}
		}
	}
	if (g_iSecurityAlive > 1 && (iWorkStatus == 0 || iWorkStatus == 3))
	{
		if (!g_bMedicPlayer[client] && GetClientButtons(client) & INS_USE)
		{
			if (g_fLastMedicCall[client] <= g_fGameTime)
			{
				new iHp = GetEntProp(client, Prop_Send, "m_iHealth");
				new String:sHp[128];
				if (float(iHp)/float(CVAR_PLAYER_HEALTH) < 0.2)
				{
					iHp = 0;
					Format(sHp, sizeof(sHp), "\x08%s濒临死亡", COLOR_RED);
				}
				else if (float(iHp)/float(CVAR_PLAYER_HEALTH) <= 0.4)
				{
					iHp = 1;
					Format(sHp, sizeof(sHp), "\x08%s严重受伤", COLOR_DARKORANGE);
				}
				else if (float(iHp)/float(CVAR_PLAYER_HEALTH) <= 0.7)
				{
					iHp = 2;
					Format(sHp, sizeof(sHp), "\x08%s受伤", COLOR_YELLOW);
				}
				else
				{
					iHp = 3;
					Format(sHp, sizeof(sHp), "\x08%s健康", COLOR_GREEN);
				}
				if (g_fBurnTime[client] != 0.0 || GetEntityFlags(client)&FL_ONFIRE)
					Format(sHp, sizeof(sHp), "%s  \x08%s着火", sHp, COLOR_MAROON);
				if (g_iPlayerBleeding[client] != 0)
					Format(sHp, sizeof(sHp), "%s  \x08%s失血", sHp, COLOR_BROWN);
				if (g_iPlayerInfected[client] != 0)
					Format(sHp, sizeof(sHp), "%s  \x08%s被感染", sHp, COLOR_PURPLE);
				// if (StrContains(sHp, "Healthy", true) == -1 || g_iPlayerBleeding[client] != 0 || g_iPlayerInfected[client] != 0 || StrContains(sHp, "On Fire", true) != -1)
				if (StrContains(sHp, "健康", true) == -1 || g_iPlayerBleeding[client] != 0 || g_iPlayerInfected[client] != 0)
				{
					SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
					PrintToChatAll("\x08%s%N : \x01呼叫医疗兵！  (%s\x01)", GetPlayerChatColor(client), client, sHp);
					g_fLastMedicCall[client] = g_fGameTime+FCVAR_PLAYER_MEDIC_REQUEST_COOLTIME;
					PlayerYell(client, 9, true, _, iHp);
				}
			}
		}
	}
	
	if (bChanged)
		SetEntProp(client, Prop_Send, "m_iPlayerFlags", iFlags);
	return;
}

public bool:SHook_OnShouldCollide(int client, int collisiongroup, int contentsmask, bool originalResult)
{
//	PrintToChat(client, "%d, %d, %d", collisiongroup, contentsmask, originalResult);
//	collisiongroup = 8;
//	contentsmask = MASK_PLAYERSOLID;
//	originalResult = true;
	return true;
}

public Action:SHook_OnPlayerTouch(client, touch)
{
	if (touch > 0 && touch <= MaxClients && GetClientTeam(touch) == TEAM_ZOMBIES)
	{
		if (g_iPlayerStance[client] == 2)
		{
			if (g_fGameTime-g_fPlayerLastSteped[touch] >= 2.0)
			{
				g_fPlayerLastSteped[touch] = g_fGameTime;
				decl String:scream_sound[128];
				switch(g_iZombieClass[touch][CLASS])
				{
					case ZOMBIE_CLASSIC_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/classic/claw_strike%d.wav", GetRandomInt(1, 3));
					case ZOMBIE_STALKER_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/stalker/attack%d.wav", GetRandomInt(1, 3));
//					case ZOMBIE_IED_INDEX:		Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/ied/   %d.wav", GetRandomInt(1, 2));
					default:					scream_sound = "Lua_sounds/zombiehorde/zombies/common/attack1.ogg";
				}
				EmitSoundToAll(scream_sound, touch, SNDCHAN_WEAPON, _, _, 1.0);
				EmitSoundToAll("Lua_sounds/zombiehorde/zombies/classic/zombie_hit.wav", client, SNDCHAN_BODY, _, _, 1.0);
				// TE_SetupParticleEffect("smokegrenade_spray_b", PATTACH_WORLDORIGIN, client);
				// TE_SendToAll();
				SDKHooks_TakeDamage(client, touch, touch, 15.0, DMG_SLASH, GetEntPropEnt(touch, Prop_Data, "m_hActiveWeapon"), NULL_VECTOR, NULL_VECTOR);
			}
		}
		else
		{
			if (g_iZombieClass[touch][CLASS] != ZOMBIE_IED_INDEX && g_iZombieClass[touch][VAR] == 1)
			{
				g_iZombieClass[touch][VAR] = 0;
				decl String:scream_sound[128];
				switch(g_iZombieClass[touch][CLASS])
				{
					case ZOMBIE_CLASSIC_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/classic/claw_strike%d.wav", GetRandomInt(1, 3));
					case ZOMBIE_STALKER_INDEX:	Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/stalker/attack%d.wav", GetRandomInt(1, 3));
//					case ZOMBIE_IED_INDEX:		Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/ied/   %d.wav", GetRandomInt(1, 2));
					default:					scream_sound = "Lua_sounds/zombiehorde/zombies/common/attack1.ogg";
				}
				EmitSoundToAll(scream_sound, touch, SNDCHAN_WEAPON, _, _, 1.0);
				EmitSoundToAll("Lua_sounds/zombiehorde/zombies/classic/zombie_hit.wav", client, SNDCHAN_BODY, _, _, 1.0);
				SDKHooks_TakeDamage(client, touch, touch, 15.0, DMG_SLASH, GetEntPropEnt(touch, Prop_Data, "m_hActiveWeapon"), NULL_VECTOR, NULL_VECTOR);
				new Float:fVel[3], Float:fResetVel[3] = {0.0, 0.0, 0.0}, Float:fKnockback;
				GetEntPropVector(touch, Prop_Data, "m_vecAbsVelocity", fVel);
				fResetVel[2] = fVel[2]/3.0;
				ScaleVector(fVel, GetRandomFloat(2.0, 3.0));
				// PrintToChatAll("<< %0.2f", fVel[2]);
				if (fVel[2] > 300.0) fVel[2] = 300.0;
				else if (fVel[2] < -200.0) fVel[2] = -200.0;
				else if (fVel[2] >= -30.00 && fVel[2] <= 150.0) fVel[2] = 150.0;
				fKnockback = GetVectorLength(fVel, false);
				// PrintToChatAll(">> %0.2f", fVel[2]);
				// if (fKnockback > 600.0) fKnockback = 600.0;
				// DamageOnClientKnockBack(client, touch, fKnockback);
				TeleportEntity(touch, NULL_VECTOR, NULL_VECTOR, fResetVel);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVel);
				LogToGame("Zombie \"%N\" Leaped and knockbacked \"%N\" and knockback force %0.2f", touch, client, fKnockback);
			}
		}
	}
}

public Action:SHook_OnTouch(entity, touch)
{
	if (touch > 0 && touch <= MaxClients)
	{
/*		new String:sClassName[64];
		GetEntPropString(entity, Prop_Data, "m_iName", sClassName, sizeof(sClassName));
		if (StrEqual(sClassName, "LuaCustomModel", true))
			SDKHooks_TakeDamage(entity, client, client, 10.0, DMG_SLASH, -1, NULL_VECTOR, NULL_VECTOR);	*/
		if (g_fGameTime >= g_fZombieObjectDamaged[touch] && GetClientTeam(touch) == TEAM_ZOMBIES)
		{
			g_fZombieObjectDamaged[touch] = g_fGameTime+GetRandomFloat(2.0, 4.0);
			if (g_iZombieClass[touch][VAR] != 1)
				SDKHooks_TakeDamage(entity, touch, touch, GetRandomFloat(125.0, 350.0), DMG_SLASH, -1, NULL_VECTOR, NULL_VECTOR);
			else
				SDKHooks_TakeDamage(entity, touch, touch, GetRandomFloat(250.0, 500.0), DMG_SLASH, -1, NULL_VECTOR, NULL_VECTOR);
			decl String:sSoundFile[128];
			Format(sSoundFile, sizeof(sSoundFile), "Lua_sounds/zombiehorde/zombies/fast/zombie_on_car_0%d.wav", GetRandomInt(1, 4));
			EmitSoundToAll(sSoundFile, entity, SNDCHAN_AUTO, _, _, 1.0);
			EmitSoundToAll("Lua_sounds/zombiehorde/zombies/classic/zombie_hit.wav", touch, SNDCHAN_WEAPON, _, _, 1.0);
			TE_SetupParticleEffect("smokegrenade_spray_b", PATTACH_WORLDORIGIN, entity);
			TE_SendToAll();
//			SHook_OnTakeDamageGear(entity, touch, touch, 10.0, 1, -1, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

public Action:SHook_OnTakeDamageGear(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
//	PrintToChatAll("Equipment %d damaged %0.1f (%d) by %d (%d) with %d weapon id", victim, damage, damagetype, attacker, inflictor, weapon);
	if (GetEntPropEnt(victim, Prop_Data, "m_hOwnerEntity") == MaxClients+2)
		return Plugin_Continue;
	new aTeam = (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) ? GetClientTeam(attacker) : -1);
	if (aTeam == TEAM_SURVIVORS)
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
//	PrintToChatAll("caller %d, activator %d, delay %0.2f", output, caller, activator, delay);
	if (GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity") == MaxClients+2)
		return;
	new iHp = GetEntProp(caller, Prop_Data, "m_iHealth");
	if (iHp > 0)
	{
		new iMaxHp = GetEntProp(caller, Prop_Data, "m_iMaxHealth");
		new iColor = 255;
		if (iMaxHp > 500)
		{
			iColor = RoundToNearest((float(iHp) / 2000.0) * 255.0);
			decl iColors[4] = {255, 255, 255, 255};
			iColors[1] = iColors[2] = iColor;
			SetVariantColor(iColors);
			AcceptEntityInput(caller, "SetGlowColor");
			if (GetEntPropFloat(caller, Prop_Data, "m_flLocalTime") == 0.0)
			{
				new iFixMaxHp = RoundToCeil(float(iMaxHp)*0.75);
				if (iFixMaxHp > iHp)
				{
					if (iFixMaxHp < 1500) iFixMaxHp = 1000;
					DisplayInstructorHint(caller, 5.0, 0.0, 1000.0, true, true, "icon_interact", "icon_interact", "", true, {255, 215, 0}, "路障被破坏了！呼叫霰弹专家来进行修理！");
					SetEntProp(caller, Prop_Data, "m_iMaxHealth", iFixMaxHp);
					SetEntPropFloat(caller, Prop_Data, "m_flLocalTime", 1.0);
					DispatchKeyValue(caller, "targetname", "LuaCustomModel");
					PrintToChatAll("\x04路障 \x01被破坏了。  \x08%s呼叫霰弹专家来进行修理！", COLOR_GOLD);
				}
			}
		}
		else iColor = RoundToNearest((float(iHp) / float(iMaxHp)) * 255.0);
		SetEntityRenderColor(caller, iColor, iColor, iColor, 255);
//		PrintToChatAll("%d / %d = %d", iHp, iMaxHp, iColor);
	}
	else
	{
		new String:sModelPath[128];
		GetEntPropString(caller, Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
		for (new client = 1;client <= MaxClients;client++)
		{
			if (g_iPlayerTempProp[client] == caller)
			{
				g_iPlayerTempProp[client] = -1;
				break;
			}
		}
//		GetEntPropVector(caller, Prop_Data, "m_vecAbsOrigin", vOrigin);
		if (StrContains(sModelPath, "sec_hub", true) != -1)
		{
			if (activator > 0 && activator <= MaxClients && IsClientInGame(activator))
			{
				PrintToChatAll("\x04便携雷达 \x01 已被 \x08%s%N 摧毁 ", GetPlayerChatColor(activator), activator);
				LogToGame("Portable Radar %d is destroyed by %N", caller, activator);
			}
			else
			{
				PrintToChatAll("\x04便携雷达 \x01已被摧毁");
				LogToGame("Portable Radar %d is destroyed by #%d", caller, activator);
			}
			switch(GetRandomInt(0, 2))
			{
/*				case 0: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_01.ogg", vOrigin);
				case 1: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_02.ogg", vOrigin);
				case 2: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_03.ogg", vOrigin);	*/
				case 0: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_01.ogg");
				case 1: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_02.ogg");
				case 2: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_03.ogg");
			}
		}
		else if (StrContains(sModelPath, "ins_radio", true) != -1)
		{
			if (activator > 0 && activator <= MaxClients && IsClientInGame(activator))
			{
				PrintToChatAll("\x04IED干扰器 \x01已被 \x08%s%N 摧毁", GetPlayerChatColor(activator), activator);
				LogToGame("IED干扰器 %d 已被 %N 摧毁", caller, activator);
			}
			else
			{
				PrintToChatAll("\x04IED干扰器 \x01已被摧毁");
				LogToGame("IED干扰器 %d 已被 #%d 摧毁", caller, activator);
			}
			switch(GetRandomInt(0, 2))
			{
/*				case 0: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_01.ogg", vOrigin);
				case 1: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_02.ogg", vOrigin);
				case 2: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_03.ogg", vOrigin);	*/
				case 0: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_01.ogg");
				case 1: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_02.ogg");
				case 2: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_03.ogg");
			}
		}
		else if (StrContains(sModelPath, "ammocrate", true) != -1)
		{
			if (activator > 0 && activator <= MaxClients && IsClientInGame(activator))
			{
				PrintToChatAll("\x04弹药箱 \x01已被 \x08%s%N 摧毁", GetPlayerChatColor(activator), activator);
				LogToGame("弹药箱 %d 已被 %N 摧毁", caller, activator);
			}
			else
			{
				PrintToChatAll("\x04弹药箱 \x01已被摧毁");
				LogToGame("弹药箱 %d 已被 #%d 摧毁", caller, activator);
			}
			PlayGameSoundToAll("ui/sfx/crate_01.wav");
		}
		else
		{
			if (activator > 0 && activator <= MaxClients && IsClientInGame(activator))
			{
				PrintToChatAll("\x04路障 \x01已被 \x08%s%N 摧毁", GetPlayerChatColor(activator), activator);
				LogToGame("Barricade %d is destroyed by %N", caller, activator);
			}
			else
			{
				PrintToChatAll("\x04路障 \x01已被摧毁");
				LogToGame("Barricade %d is destroyed by #%d", caller, activator);
			}
			PlayGameSoundToAll("Vehicle.ExplodeFarDistant");
		}
		AcceptEntityInput(caller, "kill");
	}
	return;
}

public Action:Timer_MedicThanks(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return;
	
	decl String:sSoundFile[128];
	Format(sSoundFile, sizeof(sSoundFile), "lua_sounds/medic/thx/medic_thanks%d.ogg", GetRandomInt(1, 20));
	EmitSoundToAll(sSoundFile, client, SNDCHAN_VOICE, _, _, 1.0);
}

public Action:Timer_GearPortableRadar(Handle:timer, Handle:data)
{
	ResetPack(data);
	new refentity = ReadPackCell(data);
	if (g_iGameState == 4 && refentity != INVALID_ENT_REFERENCE && IsValidEntity(refentity))
	{
		new Float:fSpawnTime = GetGameTime()-ReadPackFloat(data);
		if (fSpawnTime <= 45.0)
		{
//			SetEntPropEnt(refentity, Prop_Data, "m_hOwnerEntity", -1);
			new iSetting = GetEntPropEnt(refentity, Prop_Data, "m_hOwnerEntity");
			if (iSetting < 0 || iSetting == MaxClients+1)
			{
				if (iSetting == -1 && GetRandomFloat(0.1, 100.0) <= 0.8)
				{
					LogToGame("Portable Radar %d is broken by random chance", refentity);
					if (g_iGearRadarModel[1] != -1)
					{
						switch(GetRandomInt(0, 2))
						{
			/*				case 0: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_01.ogg", vOrigin);
							case 1: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_02.ogg", vOrigin);
							case 2: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_03.ogg", vOrigin);	*/
							case 0: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_01.ogg");
							case 1: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_02.ogg");
							case 2: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_03.ogg");
						}
						DisplayInstructorHint(EntRefToEntIndex(refentity), 5.0, 0.0, 1000.0, true, true, "icon_interact", "icon_interact", "", true, {255, 215, 0}, "便携雷达被破坏了！快修理！");
						SetVariantColor({255, 100, 100, 255});
						AcceptEntityInput(refentity, "SetGlowColor");
						SetEntPropEnt(refentity, Prop_Data, "m_hOwnerEntity", 0);
						SetEntityModel(refentity, "models/static_props/sec_hub_burned.mdl");
						DispatchKeyValue(refentity, "targetname", "LuaCustomModel");
						PrintToChatAll("\x04便携雷达 \x01被破坏了。  \x08%s快修理！", COLOR_GOLD);
						new Float:vOrigin[3];
						GetEntPropVector(refentity, Prop_Data, "m_vecAbsOrigin", vOrigin);
						new Float:fDirection[3];
						fDirection[0] = GetRandomFloat(-1.0, 1.0);
						fDirection[1] = GetRandomFloat(-1.0, 1.0);
						fDirection[2] = GetRandomFloat(-1.0, 1.0);
						new Float:vMaxs[3];
						GetEntPropVector(refentity, Prop_Data, "m_vecMaxs", vMaxs);
						vOrigin[2] += vMaxs[2]/2;
						TE_SetupSparks(vOrigin, fDirection, 1, 1);
						TE_SendToAll();
					}
					else SetEntPropEnt(refentity, Prop_Data, "m_hOwnerEntity", MaxClients+1);
				}
				else
				{
					new bool:bFound = false;
					new Float:vOrigin[3], Float:fDistance = 9999.0, Float:vTargetOrigin[3];
					GetEntPropVector(refentity, Prop_Data, "m_vecAbsOrigin", vOrigin);

					for (new client = 1;client <= MaxClients;client++)
					{
						if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TEAM_ZOMBIES)
							continue;
						
						GetClientAbsOrigin(client, vTargetOrigin);
						fDistance = GetVectorDistance(vOrigin, vTargetOrigin);
						if (fDistance <= 900.0)
						{
							g_iPlayerStatus[client] |= STATUS_INPORTABLERADAR;
							if (g_iPlayerStatus[client] == 0 || g_iPlayerStatus[client] & ~STATUS_INUAVRADAR)
							{
								bFound = true;
								SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
								CreateTimer(0.98, Timer_GearPortableRadar_OffTarget, client, TIMER_FLAG_NO_MAPCHANGE);
							}
						}
					}
					if (bFound) EmitSoundToAll("ui/sfx/beep2.wav", refentity, _, _, _, 0.3);
				}
			}
			return Plugin_Continue;
		}
		else
		{
			LogToGame("Portable Radar %d is out of battery", refentity);
			switch(GetRandomInt(0, 2))
			{
/*				case 0: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_01.ogg", vOrigin);
				case 1: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_02.ogg", vOrigin);
				case 2: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_03.ogg", vOrigin);	*/
				case 0: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_01.ogg");
				case 1: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_02.ogg");
				case 2: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_03.ogg");
			}
			PrintToChatAll("\x04便携雷达 \x01已经没有电了！");
			if (g_iGearRadarModel[1] != -1)
			{
				SetEntPropEnt(refentity, Prop_Data, "m_hOwnerEntity", MaxClients+2);
				SetEntityModel(refentity, "models/static_props/sec_hub_burned.mdl");
				SetEntProp(refentity, Prop_Send, "m_bShouldGlow", false);
//				SDKUnhook(EntRefToEntIndex(refentity), SDKHook_Touch, SHook_OnTouch);
//				SDKUnhook(EntRefToEntIndex(refentity), SDKHook_OnTakeDamage, SHook_OnTakeDamageGear);
//				UnhookSingleEntityOutput(EntRefToEntIndex(refentity), "OnHealthChanged", OnGearDamaged);
				SetVariantString("OnUser1 !self:kill::5.0:1");
				AcceptEntityInput(refentity, "AddOutput");
				AcceptEntityInput(refentity, "FireUser1");
			}
			else
			{
				LogToGame("Portable Radar %d is out of battery but model is not precached", refentity);
				RequestFrame(DeleteEntity, refentity);
			}
		}
	}
	KillTimer(timer);
	return Plugin_Handled;
}

public Action:Timer_GearPortableRadar_OffTarget(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		g_iPlayerStatus[client] &= ~STATUS_INPORTABLERADAR;
		if (g_iPlayerStatus[client] == 0 || g_iPlayerStatus[client] & ~STATUS_INUAVRADAR)
		{
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		}
	}
}

public Action:Timer_GearIEDJammer(Handle:timer, Handle:data)
{
	ResetPack(data);
	new refentity = ReadPackCell(data);
	if (g_iGameState == 4 && refentity != INVALID_ENT_REFERENCE && IsValidEntity(refentity))
	{
		new Float:fSpawnTime = g_fGameTime-ReadPackFloat(data);
		if (fSpawnTime <= 80.0)
		{
			new iSetting = GetEntPropEnt(refentity, Prop_Data, "m_hOwnerEntity");
			if (iSetting < 0 || iSetting == MaxClients+1)
			{
				if (iSetting == -1 && GetRandomFloat(0.1, 100.0) <= 0.6)
				{
					if (g_iGearIEDJammerModel[1] != -1)
					{
						LogToGame("IED Jammer %d is broken by random chance", refentity);
						switch(GetRandomInt(0, 2))
						{
			/*				case 0: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_01.ogg", vOrigin);
							case 1: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_02.ogg", vOrigin);
							case 2: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_03.ogg", vOrigin);	*/
							case 0: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_01.ogg");
							case 1: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_02.ogg");
							case 2: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_03.ogg");
						}
						DisplayInstructorHint(EntRefToEntIndex(refentity), 5.0, 0.0, 1000.0, true, true, "icon_interact", "icon_interact", "", true, {255, 215, 0}, "IED干扰器被破坏了！快修理！");
						SetVariantColor({255, 100, 100, 255});
						AcceptEntityInput(refentity, "SetGlowColor");
						SetEntPropEnt(refentity, Prop_Data, "m_hOwnerEntity", 0);
						SetEntityModel(refentity, "models/static_props/ins_radio_burned.mdl");
						DispatchKeyValue(refentity, "targetname", "LuaCustomModel");
						PrintToChatAll("\x04IED干扰器 \x01被破坏了。  \x08%s快修理！", COLOR_GOLD);
						new Float:vOrigin[3];
						GetEntPropVector(refentity, Prop_Data, "m_vecAbsOrigin", vOrigin);
						new Float:fDirection[3];
						fDirection[0] = GetRandomFloat(-1.0, 1.0);
						fDirection[1] = GetRandomFloat(-1.0, 1.0);
						fDirection[2] = GetRandomFloat(-1.0, 1.0);
						new Float:vMaxs[3];
						GetEntPropVector(refentity, Prop_Data, "m_vecMaxs", vMaxs);
						vOrigin[2] += vMaxs[2]/2;
						TE_SetupSparks(vOrigin, fDirection, 1, 1);
						TE_SendToAll();
					}
					else SetEntPropEnt(refentity, Prop_Data, "m_hOwnerEntity", MaxClients+1);
				}
				else
				{
					new bool:bFound = false;
					new Float:vOrigin[3], Float:fDistance = 9999.0, Float:vTargetOrigin[3];
					GetEntPropVector(refentity, Prop_Data, "m_vecAbsOrigin", vOrigin);
					for (new client = 1;client <= MaxClients;client++)
					{
						if (g_iZombieClass[client][CLASS] != ZOMBIE_IED_INDEX || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TEAM_ZOMBIES)
							continue;
						
						GetClientAbsOrigin(client, vTargetOrigin);
						fDistance = GetVectorDistance(vOrigin, vTargetOrigin);
						if (fDistance <= 1200.0)
						{
							bFound = true;
							g_iPlayerStatus[client] |= STATUS_INIEDJAMMER;
							g_iPlayerCustomGear[client] = refentity;
							CreateTimer(0.48, Timer_GearIEDJammer_OffTarget, client, TIMER_FLAG_NO_MAPCHANGE);
						}
					}
					if (bFound)
					{
						if (g_fGameTime-GetEntPropFloat(refentity, Prop_Data, "m_flLocalTime") >= 5.0)
						{
							SetEntPropFloat(refentity, Prop_Data, "m_flLocalTime", g_fGameTime);
							new String:sSound[128];
							switch(GetRandomInt(0, 3))
							{
								case 0: Format(sSound, sizeof(sSound), "Lua_sounds/zombiehorde/zombies/ied/zombine_alert%d.wav", GetRandomInt(1, 7));
								case 1: Format(sSound, sizeof(sSound), "Lua_sounds/zombiehorde/zombies/ied/zombine_charge%d.wav", GetRandomInt(1, 2));
								case 2: Format(sSound, sizeof(sSound), "Lua_sounds/zombiehorde/zombies/ied/zombine_idle%d.wav", GetRandomInt(1, 4));
								case 3: Format(sSound, sizeof(sSound), "Lua_sounds/zombiehorde/zombies/ied/zombine_readygrenade%d.wav", GetRandomInt(1, 2));
							}
//							Format(sSound, sizeof(sSound), "Lua_sounds/zombiehorde/zombies/classic/zombie_voice_idle%d.wav", GetRandomInt(1, 14));
							EmitSoundToAll(sSound, refentity, _, _, _, 0.35);
						}
					}
				}
			}
			return Plugin_Continue;
		}
		else
		{
			LogToGame("IED Jammer %d is out of battery", refentity);
			switch(GetRandomInt(0, 2))
			{
/*				case 0: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_01.ogg", vOrigin);
				case 1: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_02.ogg", vOrigin);
				case 2: EmitAmbientSound("soundscape/emitters/oneshot/broken_tv_03.ogg", vOrigin);	*/
				case 0: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_01.ogg");
				case 1: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_02.ogg");
				case 2: PlayGameSoundToAll("soundscape/emitters/oneshot/broken_tv_03.ogg");
			}
			PrintToChatAll("\x04IED干扰器 \x01已经没有电了！");
			if (g_iGearIEDJammerModel[1] != -1)
			{
				SetEntPropEnt(refentity, Prop_Data, "m_hOwnerEntity", MaxClients+2);
				SetEntityModel(refentity, "models/static_props/ins_radio_burned.mdl");
				SetEntProp(refentity, Prop_Send, "m_bShouldGlow", false);
//				SDKUnhook(EntRefToEntIndex(refentity), SDKHook_Touch, SHook_OnTouch);
//				SDKUnhook(EntRefToEntIndex(refentity), SDKHook_OnTakeDamage, SHook_OnTakeDamageGear);
//				UnhookSingleEntityOutput(EntRefToEntIndex(refentity), "OnHealthChanged", OnGearDamaged);
				SetVariantString("OnUser1 !self:kill::5.0:1");
				AcceptEntityInput(refentity, "AddOutput");
				AcceptEntityInput(refentity, "FireUser1");
			}
			else
			{
				LogToGame("IED Jammer %d is out of battery but model is not precached", refentity);
				RequestFrame(DeleteEntity, refentity);
			}
		}
	}
	KillTimer(timer);
	return Plugin_Handled;
}

public Action:Timer_GearAmmoCrate(Handle:timer, Handle:data)
{
	ResetPack(data);
	new refentity = ReadPackCell(data);
	if (g_iGameState == 4 && refentity != INVALID_ENT_REFERENCE && IsValidEntity(refentity))
	{
		new iStock = RoundToNearest(GetEntPropFloat(refentity, Prop_Data, "m_flLocalTime"));
		new Float:fSpawnTime = g_fGameTime-ReadPackFloat(data);
		if (iStock > 0 && fSpawnTime <= 120.0)
		{
			new Float:vOrigin[3], Float:fDistance = 9999.0, Float:vTargetOrigin[3];
			GetEntPropVector(refentity, Prop_Data, "m_vecAbsOrigin", vOrigin);
			for (new i = 0;i < MAXPLAYER;i++)
			{
				if (g_iPlayersList[i] == -1 || !IsPlayerAlive(g_iPlayersList[i]))
					continue;
					
				new client = g_iPlayersList[i];
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
					g_iPlayerLastHP[client] = GetEntProp(client, Prop_Send, "m_iHealth");
				}
				else if (g_iPLFBuyzone[client] == refentity || !IsValidEdict(g_iPLFBuyzone[client]))
				{
					g_iPLFBuyzone[client] = INVALID_ENT_REFERENCE;
					PrintCenterText(client, " ");
				}
			}
			return Plugin_Continue;
		}
		else
		{
			for (new i = 1;i <= MaxClients;i++)
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
//				SDKUnhook(EntRefToEntIndex(refentity), SDKHook_Touch, SHook_OnTouch);
//				SDKUnhook(EntRefToEntIndex(refentity), SDKHook_OnTakeDamage, SHook_OnTakeDamageGear);
//				UnhookSingleEntityOutput(EntRefToEntIndex(refentity), "OnHealthChanged", OnGearDamaged);
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

public Action:Timer_GearIEDJammer_OffTarget(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
		g_iPlayerStatus[client] &= ~STATUS_INIEDJAMMER;
}

public Action:LoadSpawnTimer(Handle:timer)
{
	if (g_bUpdatedSpawnPoint)
	{
		KillTimer(timer);
		return Plugin_Handled;
	}
	else
	{
		new Handle:hStopBot = FindConVar("nb_stop");
		if (GetClientCount(false) < 1)
		{
			if (GetConVarInt(hStopBot) == 0) SetConVarInt(hStopBot, 1);
			return Plugin_Continue;
		}
		if (GetConVarInt(hStopBot) == 1)
		{
			HookUserMessage(GetUserMessageId("HQAudio"), HQAudioHook, true);
			SetConVarInt(g_hCvarBotCount, 1);
			g_iSpawnPointsInfoMaxIndex = -1;
			SetConVarInt(g_hCvarAlwaysCounterAttack, 1);
			SetConVarInt(hStopBot, 0);
			SetConVarInt(g_hCvarCounterAttackDelay, 0);
			ServerCommand("cvar mp_timer_pregame 0");
//			ServerCommand("cvar mp_timer_postround 20");
			ServerCommand("cvar mp_timer_postround 15");
			ServerCommand("exec sourcemod/betterbots.cfg");
			for (new i = 0;i < MAX_OBJECTIVE;i++)
				g_iSpawnPointsInfoIndex[i] = -1;

/*			new Float:fRand = GetRandomFloat(0.01, 0.10);
			PrintToChatAll("\x01Loading Map Info...    \x08%s%0.2f %%  \x08%s(This may freeze lag 10 seconds)", COLOR_BLUE, fRand, COLOR_GOLD);
			LogToGame("Loading Map Info...     %0.2f %%  (This may freeze lag 10 seconds)", fRand);	*/
//			if (GetTeamClientCount(TEAM_ZOMBIES) == 0) ServerCommand("ins_bot_add_t2 1");
		}
		new iGameState = GetGameState();
		if (iGameState == 2 && GetTeamClientCount(TEAM_SURVIVORS) > 0)
		{
			ServerCommand("mp_waitingforplayers_cancel 1");
//			SetRoundTime(0.1);
		}
		if (iGameState == 3 && GetTeamClientCount(TEAM_SURVIVORS) > 0)
		{
			SetGameState(4);
			g_bCounterAttack = false;
		}
		for (new client = 1;client <= MaxClients;client++)
		{
			if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_ZOMBIES) continue;
			g_iTeleportOnSpawn[client] = 0;
			SDKCall(g_hPlayerRespawn, client);
		}
		if (iGameState == 4)
		{
			g_iNumControlPoints = GetEntData(g_iObjRes, g_iOffsetCPNumbers);
			GetEntDataArray(g_iObjRes, g_iOffsetCPType, g_iCPType, g_iNumControlPoints, 4);
			for (new i = 0;i < g_iNumControlPoints;i++)
			{
				GetEntDataArray(g_iObjRes, g_iOffsetCPType, g_iCPType, g_iNumControlPoints, 4);
				GetEntDataVector(g_iObjRes, g_iOffsetCPPositions+(12*i), g_vCPPositions[i]);
			}
			g_iCurrentControlPoint = GetEntData(g_iObjRes, g_iOffsetCPIndex);
			new iNearestPoint = -1, Float:fNearestDistance = 90000.0;
			for (new entity = MaxClients+1;entity < GetMaxEntities();entity++)
			{
				if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
				{
					new String:sClassName[32];
					GetEntityClassname(entity, sClassName, sizeof(sClassName));
					if (StrEqual(sClassName, "ins_spawnpoint", false) && GetEntProp(entity, Prop_Data, "m_iDisabled") == 0)
					{
						new iTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");
						if (g_iCurrentControlPoint > 0 && iTeam == TEAM_SURVIVORS)
							continue;
						++g_iSpawnPointsInfoMaxIndex;
						g_iSpawnPointsInfo[g_iSpawnPointsInfoMaxIndex][0] = EntIndexToEntRef(entity);
						g_iSpawnPointsInfo[g_iSpawnPointsInfoMaxIndex][1] = !g_bCounterAttack?0:1;
						g_iSpawnPointsInfo[g_iSpawnPointsInfoMaxIndex][2] = g_iCurrentControlPoint;
						g_iSpawnPointsInfo[g_iSpawnPointsInfoMaxIndex][3] = iTeam;
						if (g_iSpawnPointsInfoIndex[g_iCurrentControlPoint] == -1)
						{
//							PrintToChatAll("CP %d starting index %d", g_iCurrentControlPoint, g_iSpawnPointsInfoMaxIndex);
							g_iSpawnPointsInfoIndex[g_iCurrentControlPoint] = g_iSpawnPointsInfoMaxIndex;
						}
					}
					else if (!g_bCounterAttack && StrEqual(sClassName, "point_controlpoint", false))
					{
						decl Float:vPos[3];
						GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
						new Float:fDistance = GetVectorDistance(vPos, g_vCPPositions[g_iCurrentControlPoint]);
						if (fDistance <= fNearestDistance)
						{
							iNearestPoint = entity;
							fNearestDistance = fDistance;
						}
					}
				}
			}
			if (!g_bCounterAttack)
			{
				if (iNearestPoint != -1)
				{
					SetVariantInt(TEAM_SURVIVORS);
					AcceptEntityInput(iNearestPoint, "SetOwner");
					GameRules_SetProp("m_bCounterAttack", 1);
				}
				else
				{
					for (new entity = MaxClients+1;entity < GetMaxEntities();entity++)
					{
						if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
						{
							new String:sClassName[32];
							GetEntityClassname(entity, sClassName, sizeof(sClassName));
							if (StrEqual(sClassName, "point_controlpoint", false))
							{
								SetVariantInt(TEAM_SURVIVORS);
								AcceptEntityInput(entity, "SetOwner");
								continue;
							}
						}
					}
				}
				g_bCounterAttack = true;
				new Float:fPercent = float(g_iCurrentControlPoint*4)/float(g_iNumControlPoints*4)*100.0;
				if (fPercent < 10.00)
				{
					if (fPercent == 0.00) fPercent = 0.5/float(g_iNumControlPoints*4)*100.0;
					PrintToChatAll("\x01读取地图信息...    \x08%s%0.2f %%", COLOR_BLUE, fPercent);
					LogToGame("Loading Map Info...     %0.2f %%", fPercent);
				}
				else
				{
					PrintToChatAll("\x01读取地图信息...   \x08%s%0.2f %%", COLOR_BLUE, fPercent);
					LogToGame("Loading Map Info...   %0.2f %%", fPercent);
				}
			}
			else
			{
				if (g_iCurrentControlPoint != g_iNumControlPoints-1)
				{
					SetEntData(g_iObjRes, g_iOffsetCPIndex, g_iCurrentControlPoint+1);
					new Float:fPercent = float((g_iCurrentControlPoint*4)+1)/float(g_iNumControlPoints*4)*100.0;
					if (fPercent < 10.00)
					{
						PrintToChatAll("\x01读取地图信息...    \x08%s%0.2f %%", COLOR_BLUE, fPercent);
						LogToGame("Loading Map Info...    %0.2f %%", fPercent);
					}
					else
					{
						PrintToChatAll("\x01读取地图信息...   \x08%s%0.2f %%", COLOR_BLUE, fPercent);
						LogToGame("Loading Map Info...   %0.2f %%", fPercent);
					}
					g_bCounterAttack = false;
				}
				else
				{
					SetConVarInt(hStopBot, 0);
					if (g_iSpawnPointsInfoMaxIndex > 9)
					{
						// Need to be alive spawnpoints per CP
						// CA 0|1 [INS: 1, SEC: 1]
						/*new iCount = 0;
						new bool:bSec[g_iNumControlPoints];
						new bool:bIns[g_iNumControlPoints];
						new bool:bSecCA[g_iNumControlPoints];
						new bool:bInsCA[g_iNumControlPoints];
						for (new i = 0;i <= g_iSpawnPointsInfoMaxIndex;i++)
						{
							new iSpawnPointRef = g_iSpawnPointsInfo[i][0];
							if (iSpawnPointRef == INVALID_ENT_REFERENCE || !IsValidEdict(iSpawnPointRef) || !IsValidEntity(iSpawnPointRef) || EntRefToEntIndex(iSpawnPointRef) <= MaxClients)
								continue;
							new iSpawnPointCA = g_iSpawnPointsInfo[i][1];
							new iSpawnPointCP = g_iSpawnPointsInfo[i][2];
							new iSpawnPointTeam = GetEntProp(iSpawnPointRef, Prop_Send, "m_iTeamNum");
							new iSpawnPoint = EntRefToEntIndex(iSpawnPointRef);
							if (iSpawnPointTeam == TEAM_SURVIVORS)
							{
								if (!bSec[iSpawnPointCP] && iSpawnPointCA == 0)
								{
									LogToGame("Spawnpoint %d (%d) has been skipped for Survivors CP %d", iSpawnPoint, iSpawnPointRef, iSpawnPointCP);
									bSec[iSpawnPointCP] = true;
									continue;
								}
								else if (!bSecCA[iSpawnPointCP] && iSpawnPointCA == 1)
								{
									LogToGame("Spawnpoint %d (%d) has been skipped for Survivors CP %d [CA]", iSpawnPoint, iSpawnPointRef, iSpawnPointCP);
									bSecCA[iSpawnPointCP] = true;
									continue;
								}
							}
							else if (iSpawnPointTeam == TEAM_ZOMBIES)
							{
								if (!bIns[iSpawnPointCP] && iSpawnPointCA == 0)
								{
									LogToGame("Spawnpoint %d (%d) has been skipped for INSURGENT CP %d", iSpawnPoint, iSpawnPointRef, iSpawnPointCP);
									bIns[iSpawnPointCP] = true;
									continue;
								}
								else if (!bInsCA[iSpawnPointCP] && iSpawnPointCA == 1)
								{
									LogToGame("Spawnpoint %d (%d) has been skipped for INSURGENT CP %d [CA]", iSpawnPoint, iSpawnPointRef, iSpawnPointCP);
									bInsCA[iSpawnPointCP] = true;
									continue;
								}
							}
							iCount++;
							LogToGame("Spawnpoint %d (%d) has been removed for TEAM %d CP %d CA %d", iSpawnPoint, iSpawnPointRef, iSpawnPointTeam, iSpawnPointCP, iSpawnPointCA);
							RemoveEdict(iSpawnPointRef);
						}
						LogToGame("ins_spawnpoint (Total %d) has been removed", iCount);	*/
						g_bCounterAttack = false;
						PrintToChatAll("\x01读取地图信息...   \x08%s100.00 %%", COLOR_GREEN);
						PrintToChatAll("\x08%s(%d) 地图信息读取完毕，正在重启游戏...", COLOR_GOLD, g_iSpawnPointsInfoMaxIndex+1);
						LogToGame("Loading Map Info...   100.00 %%");
						LogToGame("(%d) Map Info Loading Complete, restart the game...", g_iSpawnPointsInfoMaxIndex+1);
						new ent = FindEntityByClassname(-1, "ins_rulesproxy");
						if (ent > MaxClients && IsValidEntity(ent))
						{
							SetVariantInt(1);
							AcceptEntityInput(ent, "EndRound");
						}
						SetGameState(2);
						SetRoundTime(15.0);
						ServerCommand("exec server_checkpoint.cfg");
	//					ServerCommand("mp_restartgame 1");
						CreateTimer(1.0, SpawnUpdateDone, _, TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(15.0, UnHookHQRadio, _, TIMER_FLAG_NO_MAPCHANGE);
					}
					else ServerCommand("map %s checkpoint", g_sCurrentMap);
					KillTimer(timer);
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:SpawnUpdateDone(Handle:timer)
{
	new iMaxRounds = GetConVarInt(FindConVar("mp_maxrounds"));
	if (iMaxRounds > 0) ServerCommand("cvar mp_maxrounds %d", iMaxRounds+1);
	g_bUpdatedSpawnPoint = true;
//	SetRoundTime(18.9);
}

public Action:UnHookHQRadio(Handle:timer)
{
	UnhookUserMessage(GetUserMessageId("HQAudio"), HQAudioHook, true);
}

stock UpdateBotsToken(iPlayers = 0)
{
	static LastToken = 0;
	if (g_bReinforcementBotEnd || g_bCounterAttack)
		return CVAR_BOT_REINFORCEMENT_MAX_PER_POINT;

	if (iPlayers < 1)
	{
		iPlayers = 0;
		for (new i = 0;i < MAXPLAYER;i++)
		{
			if (g_iPlayersList[i] != -1 && GetClientTeam(g_iPlayersList[i]) == TEAM_SURVIVORS)
				iPlayers++;
		}
	}
	CVAR_BOT_REINFORCEMENT_MAX_PER_POINT = RoundToNearest(float(iPlayers)*GetRandomFloat(FCVAR_BOT_REINFORCEMENT_TOKEN_BASE_MIN, FCVAR_BOT_REINFORCEMENT_TOKEN_BASE_MAX)*GetConVarFloat(g_hCvarLobbySize)/float(CVAR_BOT_REINFORCEMENT_MAX));
	if (CVAR_BOT_REINFORCEMENT_MAX_PER_POINT < CVAR_BOT_REINFORCEMENT_TOKEN_MIN)
	{
		if (!g_bAlone)	CVAR_BOT_REINFORCEMENT_MAX_PER_POINT = CVAR_BOT_REINFORCEMENT_TOKEN_MIN;
		else			CVAR_BOT_REINFORCEMENT_MAX_PER_POINT = CVAR_BOT_REINFORCEMENT_TOKEN_MIN_ALONE;
	}
	if (LastToken != CVAR_BOT_REINFORCEMENT_MAX_PER_POINT)
	{
		LogToGame("Player Reinforcement Token Updated >> %d", CVAR_BOT_REINFORCEMENT_MAX_PER_POINT);
		LastToken = CVAR_BOT_REINFORCEMENT_MAX_PER_POINT;
	}
	return CVAR_BOT_REINFORCEMENT_MAX_PER_POINT;
}

stock UpdateBotsConfig(iPlayers = 0, bool:bNotice = true, bool:bOnlyNoticeWhenUpdated = false)
{
	if (iPlayers < 1)
	{
		iPlayers = 0;
		for (new i = 0;i < MAXPLAYER;i++)
		{
			if (g_iPlayersList[i] != -1 && GetClientTeam(g_iPlayersList[i]) == TEAM_SURVIVORS)
				iPlayers++;
		}
	}

	// #Bot Numbers
	new iBotCount = 0;
	switch(iPlayers)
	{
		case 11, 12: iBotCount = 37;
		case 9, 10: iBotCount = 30;	
		case 7, 8: iBotCount = 24;
		case 5, 6: iBotCount = 15;
		case 4: iBotCount = 9;
		case 3: iBotCount = 7;
		case 2: iBotCount = 5;
		case 0, 1: iBotCount = 3;
		default: iBotCount = 3;
	}
//	iBotCount = 2;
	new bool:bUpdate = false;
	if (GetConVarInt(g_hCvarBotCount) != iBotCount)
	{
		SetConVarInt(g_hCvarBotCount, iBotCount);
		bUpdate = true;
	}
	if (GetConVarInt(g_hCvarBotLevel) != 3)
		SetConVarInt(g_hCvarBotLevel, 3);
	if (!bOnlyNoticeWhenUpdated)
		bUpdate = true;
	if (bNotice && bUpdate)
	{
		if (iBotCount >= 25) PrintToChatAll("\x08%s难度： \x04人间炼狱", COLOR_INSURGENTS);
		else if (iBotCount >= 14) PrintToChatAll("\x08%s难度：  \x05困难", COLOR_INSURGENTS);
		else if (iBotCount >= 9) PrintToChatAll("\x08%s难度：  \x05正常", COLOR_INSURGENTS);
		else PrintToChatAll("\x08%s难度：  \x01简单", COLOR_INSURGENTS);
	}
}

public QueryConVar_HLSS(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{

}

public Action:HudTimer(Handle:timer)
{
	if (g_iGameState < 4 || !g_bUpdatedSpawnPoint)
	{
		decl String:language[64];
		g_fGameTime = GetGameTime();
		for (new client = 1;client <= MaxClients;client++)
		{
			if (!IsClientInGame(client) || IsFakeClient(client)) continue;
			GetClientInfo(client, "cl_language", language, sizeof(language));
			if (StrContains(language, "korea", false) == -1)
				PrintHintText(client, "游戏即将开始！");
			else
				PrintHintText(client, "채팅창에 \n \n /HELP \n \n 를 입력하시면 게임 정보가 나옵니다");

			if (g_fPlayerAmbientTime[client] <= g_fGameTime)
			{
				g_fPlayerAmbientTime[client] = g_fGameTime+58.0;
				EmitSoundToClient(client, "Lua_sounds/zombiehorde/zr_ambience.ogg", _, _, _, _, 0.44);
			}
			QueryClientConVar(client, "voice_inputfromfile", QueryConVar_HLSS);
		}
		return;
	}
	/*	for (new entity = MaxClients+1;entity < GetMaxEntities();entity++)
	{
		if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
		{
			new String:sClassName[32], Float:vPos[3];
			GetEntityClassname(entity, sClassName, sizeof(sClassName));
			if (StrEqual(sClassName, "point_controlpoint", false))
			{
				SetVariantInt(TEAM_SURVIVORS);
				AcceptEntityInput(entity, "SetOwner");
				continue;
			}
		}
	}	*/
/*	if (g_iNextSpawnPointsIndex > -1)
	{
		new g_HaloSprite = PrecacheModel("sprites/glow01.vmt");
		for (new i = 0;i <= g_iNextSpawnPointsIndex;i++)
		{
			TE_SetupBeamRingPoint(g_vNextSpawnPoints[i], 15.0, 20.0, g_iSpriteLaser, g_HaloSprite, 0, 1, 1.0, 1.0, 1.0, {255, 255, 0, 200}, 1, 0);
			TE_SendToAll();
//			PrintToChatAll("%d.  %0.1f,  %0.1f,  %0.1f  [Disabled %d,  Team %d]", entity, vPos[0], vPos[1], vPos[2], GetEntProp(entity, Prop_Send, "m_bDisabled"), GetEntProp(entity, Prop_Send, "m_iTeamNum"));
		}
	}	*/

	for (new i = 0;i < MAX_ZOMBIE_CLASSES;i++)
		g_iZombieSpawnCount[i] = 0;
	g_fGameTime = GetGameTime();
	new iLobbySize = GetConVarInt(g_hCvarLobbySize);
	new iEnemyDeadCount = 0, iEnemyAliveCount = 0, iPlayerDeadCount = 0, iPlayerAliveCount = 0, iPlayers[iLobbySize], iSpectatorCount = 0, iSpectators[iLobbySize];
	if (g_fThunderSound <= g_fGameTime)
	{
		g_fThunderSound = g_fGameTime+GetRandomFloat(30.0, 90.0);
		switch(GetRandomInt(0, 13))
		{
			case 0: PlayGameSoundToAll("soundscape/emitters/oneshot/thunderstorm_close_01.ogg");
			case 1: PlayGameSoundToAll("soundscape/emitters/oneshot/thunderstorm_close_02.ogg");
			case 2, 6, 8: PlayGameSoundToAll("soundscape/emitters/oneshot/thunderstorm_distant_01.ogg");
			case 3, 9: PlayGameSoundToAll("soundscape/emitters/oneshot/thunderstorm_distant_02.ogg");
			case 4, 7, 10: PlayGameSoundToAll("soundscape/emitters/oneshot/thunderstorm_distant_03.ogg");
			case 5, 11: PlayGameSoundToAll("soundscape/emitters/oneshot/thunderstorm_overhead_01.ogg");
			case 12: PlayGameSoundToAll("soundscape/emitters/oneshot/thunderstorm_overhead_02.ogg");
			case 13: PlayGameSoundToAll("soundscape/emitters/oneshot/thunderstorm_overhead_03.ogg");
		}
	}
	for (new client = 1;client <= MaxClients;client++)
	{
		if (!IsClientInGame(client)) continue;

		new iTeam = GetClientTeam(client);
		if (IsPlayerAlive(client))
		{
//			new iHeartBeats = 0;
			new iHp = GetEntProp(client, Prop_Send, "m_iHealth");
			if (iTeam == TEAM_SURVIVORS)
			{
				if (g_fPlayerDrugTime[client] != 0.0 && g_fGameTime >= g_fPlayerDrugTime[client])
				{
					ServerCommand("sm_drug #%d 0", GetClientUserId(client));
					g_fPlayerDrugTime[client] = 0.0;
				}
				if (g_iStuckCheckTime > 0)
				{
					new iStuckTime = GetEntProp(client, Prop_Data, "m_StuckLast");
					if (iStuckTime >= g_iStuckCheckTime)
					{
	//					SetEntProp(client, Prop_Data, "m_StuckLast", 0);
						LogToGame("Player \"%N\" has stuck! teleport/respawn to nearby player/point...", client);
						new Float:vPos[3], Float:vTargetPos[3], Float:fDistance, Float:fNearestDistance = 2000.0, Float:vNearest[3] = {-9000.0, 0.0, 0.0};
						GetClientAbsOrigin(client, vPos);
						for (new i = 1;i <= MaxClients;i++)
						{
							if (i == client || !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_SURVIVORS || GetEntProp(i, Prop_Data, "m_StuckLast") > 300) continue;
							GetClientAbsOrigin(i, vTargetPos);
							fDistance = GetVectorDistance(vTargetPos, vPos);
							if (fDistance <= fNearestDistance && fDistance >= 120.0)
							{
								vNearest[0] = vTargetPos[0];
								vNearest[1] = vTargetPos[1];
								vNearest[2] = vTargetPos[2];
								fNearestDistance = fDistance;
							}
						}
						if (vNearest[0] != -9000.0)
							vNearest[2] += 2.0;
						else
						{
							if (!GetCounterAttack())
							{
								new iMaxIndex;
								if (g_iCurrentControlPoint < g_iNumControlPoints-1)
									iMaxIndex = g_iSpawnPointsInfoIndex[g_iCurrentControlPoint+1]-1;
								else
									iMaxIndex = g_iSpawnPointsInfoMaxIndex;
								for (new i = g_iSpawnPointsInfoIndex[g_iCurrentControlPoint];i <= iMaxIndex;i++)
								{
									new iSpawnPointRef = g_iSpawnPointsInfo[i][0];
									if (iSpawnPointRef == INVALID_ENT_REFERENCE)
										continue;

	//								if (GetEntProp(iSpawnPointRef, Prop_Send, "m_iTeamNum") != TEAM_SURVIVORS)
									if (g_iSpawnPointsInfo[i][3] != TEAM_SURVIVORS)
										continue;

									GetEntPropVector(iSpawnPointRef, Prop_Data, "m_vecOrigin", vTargetPos);
									if (vTargetPos[0] == 0.0 && vTargetPos[1] == 0.0 && vTargetPos[2] == 0.0) continue;

									fDistance = GetVectorDistance(vTargetPos, vPos);
									if (fDistance <= fNearestDistance)
									{
										vNearest[0] = vTargetPos[0];
										vNearest[1] = vTargetPos[1];
										vNearest[2] = vTargetPos[2];
										fNearestDistance = fDistance;
									}
								}
								if (vNearest[0] != -9000.0)
								{
									new Handle:hTrace = TR_TraceRayFilterEx(vNearest, Float:{90.0, 0.0, 0.0}, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, ExcludeSelfAndAlive);
									if (TR_DidHit(hTrace))
									{
										TR_GetEndPosition(vNearest, hTrace);
										vNearest[2] += 12.0;
									}
									CloseHandle(hTrace);
								}
								else
								{
									RespawnPlayer(client, 0);
									PrintToChatAll("\x01玩家 \x08%s%N \x01 因为卡住而被重新复活了", GetPlayerChatColor(client), client);
								}
							}
							else
							{
								vNearest[0] = g_vCPPositions[g_iCurrentControlPoint][0];
								vNearest[1] = g_vCPPositions[g_iCurrentControlPoint][1];
								vNearest[2] = g_vCPPositions[g_iCurrentControlPoint][2];
								if (g_iCPType[g_iCurrentControlPoint] == 0) vNearest[2] += 12.0;
							}
						}
						if (vNearest[0] != -9000.0)
						{
							TeleportEntity(client, vNearest, NULL_VECTOR, NULL_VECTOR);
							PrintToChatAll("\x01玩家 \x08%s%N \x01 因为卡住而被传送了", GetPlayerChatColor(client), client);
						}
					}
					else if (iStuckTime >= 500) PrintCenterText(client, "被实体卡住了\n将在 %0.1f 秒后传送", (float(g_iStuckCheckTime)-float(iStuckTime))/1000.0);
				}
			
				if (iHp <= CVAR_PLAYER_GLOW_HEALTH || g_iPlayerBleeding[client] != 0 || g_iPlayerInfected[client] != 0 || (g_fLastMedicCall[client] != 0.0 && g_fLastMedicCall[client] >= g_fGameTime))
					SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
				else if (g_iPointFlagOwner != client && !g_bMedicPlayer[client] && g_iPlayerBleeding[client] == 0 && g_iPlayerInfected[client] == 0 && (g_fLastMedicCall[client] == 0.0 || g_fLastMedicCall[client] <= g_fGameTime))
					SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
				iPlayerAliveCount++;
				if (!IsFakeClient(client))
				{
					new String:sHp[128] = " 健康 ", bool:bReqMedic = false;
					if (float(iHp)/float(CVAR_PLAYER_HEALTH) <= 0.2)
					{
//						iHeartBeats = 2;
						sHp = " 濒临死亡 ";
						bReqMedic = true;
						if (g_fPlayerDeathFadeOutNextTime[client] != 0.0)
						{
							if (g_fPlayerDeathFadeOutNextTime[client] <= g_fGameTime)
							{
								CreateTimer(1.08, Timer_FadeOutCall, client, TIMER_FLAG_NO_MAPCHANGE);
								FadeClientVolume(client, 98.0, 6.0, 2.0, 1.0);
								ClientScreenFade(client, 666, FFADE_OUT|FFADE_PURGE, 3000, 0, 0, 0, 255);
								CreateTimer(3.5, Timer_FadeIn, client, TIMER_FLAG_NO_MAPCHANGE);
								g_fPlayerDeathFadeOutNextTime[client] = 10.0+g_fGameTime+GetRandomFloat(FCVAR_PLAYER_NEARDEATH_FADEOUT_INTERVAL_MIN, FCVAR_PLAYER_NEARDEATH_FADEOUT_INTERVAL_MAX);
//								g_fPlayerDeathFadeOutNextTime[client] = g_fGameTime+10.0;
								LogToGame("%N is having near death fade-out...", client);
							}
						}
						else
							g_fPlayerDeathFadeOutNextTime[client] = g_fGameTime+GetRandomFloat(FCVAR_PLAYER_NEARDEATH_FADEOUT_INTERVAL_MIN, FCVAR_PLAYER_NEARDEATH_FADEOUT_INTERVAL_MAX);
//							g_fPlayerDeathFadeOutNextTime[client] = g_fGameTime+10.0;
					}
					else
					{
						g_fPlayerDeathFadeOutNextTime[client] = 0.0;
						if (float(iHp)/float(CVAR_PLAYER_HEALTH) <= 0.4)
						{
	//						iHeartBeats = 1;
							sHp = " 严重受伤 ";
							bReqMedic = true;
						}
						else if (float(iHp)/float(CVAR_PLAYER_HEALTH) <= 0.7)
						{
							sHp = " 受伤 ";
							bReqMedic = true;
						}
					}
					new String:sStatus[64];
					if (g_fBurnTime[client] != 0.0 || GetEntityFlags(client)&FL_ONFIRE)
					{
//						bReqMedic = true;
						sStatus = "着火";
					}
					if (g_iPlayerBleeding[client] != 0)
					{
						bReqMedic = true;
						if (sStatus[0] != '\0') Format(sStatus, sizeof(sStatus), "%s | 失血", sStatus);
						else sStatus = "失血";
					}
					if (g_iPlayerInfected[client] != 0)
					{
						bReqMedic = true;
						if (sStatus[0] != '\0') Format(sStatus, sizeof(sStatus), "%s | 感染", sStatus);
						else sStatus = "感染";
					}
					if (sStatus[0] != '\0') Format(sHp, sizeof(sHp), " %s \n \n%s", sStatus, sHp);
					if ((g_fLastMedicCall[client] != 0.0 && g_fLastMedicCall[client] >= g_fGameTime) || g_bMedicPlayer[client] || g_iSecurityAlive <= 1)
						bReqMedic = false;
					if (!bReqMedic)
					{
						if (!g_bCounterAttackReadyTime)
							PrintHintText(client, "%s", sHp);
						else
							PrintHintText(client, "%s\n \n [准备好应对尸潮] ", sHp);
					}
					else
					{
						if (!g_bCounterAttackReadyTime)
							PrintHintText(client, "%s\n [F]  呼叫医疗兵 ", sHp);
						else
							PrintHintText(client, "%s\n [准备好应对尸潮] \n [F]  呼叫医疗兵 ", sHp);
					}
					/*
							Line 1:			UAV [300 / 100]
							Line 2:
							Line 3:		  On Fire | Bleeding
							Line 4:			
							Line 5:				Healthy
					*/
				}
/*				else
				{
					if (float(iHp)/float(CVAR_PLAYER_HEALTH) <= 0.1)
						iHeartBeats = 2;
					else if (float(iHp)/float(CVAR_PLAYER_HEALTH) <= 0.4)
						iHeartBeats = 1;
				}	*/
			}
			else if (iTeam == TEAM_ZOMBIES)
			{
				// PrintToChatAll("%N - [%d / %d]", client, iHp, GetEntProp(client, Prop_Data, "m_iMaxHealth"));
				iEnemyAliveCount++;
				if (g_iZombieClass[client][CLASS] > -1)
					g_iZombieSpawnCount[g_iZombieClass[client][CLASS]]++;

				if (g_bCounterAttack && !g_bCounterAttackReadyTime)
				{
					if (g_fGameTime-g_fSpawnTime[client] >= 30.0)
					{
						if (!g_bIsInCaptureZone[client])
						{
							new Float:fOrigin[3], Float:fPlayerOrigin[3], bool:bPlayerNearby = false;
							GetClientHeadOrigin(client, fOrigin, 10.0);
/*								GetClientEyePosition(client, fOrigin);
							switch(GetEntProp(client, Prop_Send, "m_iCurrentStance"))
							{
								case 0: fOrigin[2] += 4.0;	// Standing
								case 1: fOrigin[2] += 20.0;	// Duck
								case 2: fOrigin[2] += 52.0;	// Prone
							}	*/
							for (new j = 0;j < MAXPLAYER;j++)
							{
								if (g_iPlayersList[j] == -1 || !IsPlayerAlive(g_iPlayersList[j]))
									continue;

								new i = g_iPlayersList[j];
								GetClientHeadOrigin(i, fPlayerOrigin, 10.0);
/*									GetClientEyePosition(i, fPlayerOrigin);
								switch(GetEntProp(i, Prop_Send, "m_iCurrentStance"))
								{
									case 0: fPlayerOrigin[2] += 4.0;	// Standing
									case 1: fPlayerOrigin[2] += 20.0;	// Duck
									case 2: fPlayerOrigin[2] += 52.0;	// Prone
								}	*/
								new Handle:hTrace = TR_TraceRayFilterEx(fOrigin, fPlayerOrigin, MASK_SOLID_BRUSHONLY, RayType_EndPoint, Base_TraceFilter);
								if (TR_DidHit(hTrace))
								{
									CloseHandle(hTrace);
								}
								else
								{
									CloseHandle(hTrace);
									bPlayerNearby = true;
									break;
								}
								if (GetVectorDistance(fOrigin, fPlayerOrigin) <= 800.0)
								{
									bPlayerNearby = true;
									break;
								}
							}

							if (!bPlayerNearby)
							{
								SDKCall(g_hPlayerRespawn, client);
//									ForcePlayerSuicide(client);
								LogToGame("%N has been respawned for counterattack respawn (No players within 800 ft and no visible)", client);
							}
							else g_fSpawnTime[client] = g_fGameTime;
						}
						else g_fSpawnTime[client] = g_fGameTime;
					}
				}
				else if (g_fSpawnTime[client] != 0.0 && g_fGameTime-g_fSpawnTime[client] >= FCVAR_BOT_RESPAWN_WHEN_LIVE_TOO_LONG)
				{
					if (g_bIsInCaptureZone[client])
					{
						g_fSpawnTime[client] = g_fGameTime-(FCVAR_BOT_RESPAWN_WHEN_LIVE_TOO_LONG/2.0);
						LogToGame("%N has lived too long but is in the cp zone", client);
					}
					else if (g_iPointFlagOwner == client)
					{
						g_fSpawnTime[client] = g_fGameTime-(FCVAR_BOT_RESPAWN_WHEN_LIVE_TOO_LONG/2.0);
						LogToGame("%N has lived too long but carrying object", client);
					}
					else
					{
						new bool:bUpdate = false;
						new Float:vPos[3], Float:fDistance;//, Float:vNearest[3] = {-9000.0, 0.0, 0.0};
						GetClientEyePosition(client, vPos);
						fDistance = GetVectorDistance(g_vCPPositions[g_iCurrentControlPoint], vPos);
						if (fDistance <= 1200.0)
						{
							bUpdate = true;
							g_fSpawnTime[client] = g_fGameTime-(FCVAR_BOT_RESPAWN_WHEN_LIVE_TOO_LONG/2.0);
							LogToGame("%N has lived too long but around cp zone in %0.2f", client, fDistance);
						}
						else
						{
							new Float:vTargetPos[3], Float:fBotAngle[3], Float:fBotAngleVec[3], Float:fVector[3], Float:fDir[3];
							GetClientEyeAngles(client, fBotAngle);
							fBotAngle[0] = fBotAngle[2] = 0.0;
							GetAngleVectors(fBotAngle, fBotAngleVec, NULL_VECTOR, NULL_VECTOR);
							for (new j = 0;j < MAXPLAYER;j++)
							{
								if (g_iPlayersList[j] == -1 || !IsPlayerAlive(g_iPlayersList[j]))
									continue;
								
								new i = g_iPlayersList[j];
								GetClientEyePosition(i, vTargetPos);
								fDistance = GetVectorDistance(vTargetPos, vPos);
								if (fDistance <= 1200.0)
								{
									bUpdate = true;
									g_fSpawnTime[client] = g_fGameTime-(FCVAR_BOT_RESPAWN_WHEN_LIVE_TOO_LONG/2.0);
									LogToGame("%N has lived too long but player %N is around in %0.2f", client, i, fDistance);
									break;
								}
								else
								{
									fVector[0] = vTargetPos[0]-vPos[0];
									fVector[1] = vTargetPos[1]-vPos[1];
									fVector[2] = 0.0;

									// Check dot product. If it's negative, that means the viewer is facing backwards to the target.
									NormalizeVector(fVector, fDir);
									if (GetVectorDotProduct(fBotAngleVec, fDir) >= 0.5)
									{
										new Handle:hTrace = TR_TraceRayFilterEx(vPos, vTargetPos, MASK_SOLID, RayType_EndPoint, Filter_Not_Players);
										if (!TR_DidHit(hTrace))
										{
											CloseHandle(hTrace);
											bUpdate = true;
											g_fSpawnTime[client] = g_fGameTime-(FCVAR_BOT_RESPAWN_WHEN_LIVE_TOO_LONG/2.0);
											LogToGame("%N has lived too long but visible by player %N in %0.2f", client, i, fDistance);
											break;
										}
										else CloseHandle(hTrace);
									}
								}
							}
						}
						if (!bUpdate)
						{
							ForcePlayerSuicide(client);
							LogToGame("%N has been killed because lived too long (probably looping around)", client);
						}
					}
				}

				if (g_iFixMapLocation == 1)
				{
					// cu_chi_tunnels -8415 5016 228   (Fix -8689 -6335 -106)        -9183 1243 1256  (Fix -8835 1313 130)
					new Float:vOrigin[3];
					GetClientAbsOrigin(client, vOrigin);
					if (GetVectorDistance(vOrigin, Float:{-8145.0, 5016.0, 228.0}) <= 20.0)
						TeleportEntity(client, Float:{-8689.0, -6335.0, -106.0}, NULL_VECTOR, NULL_VECTOR);
					else if (GetVectorDistance(vOrigin, Float:{-9183.0, 1243.0, 1256.0}) <= 20.0)
						TeleportEntity(client, Float:{-8835.0, 1313.0, 130.0}, NULL_VECTOR, NULL_VECTOR);
				}
			}
			
/*			// Heartbeats
			if (iHeartBeats > 0)
			{
				if ((iHeartBeats == 1 && g_fHeartBeatTime[client]+FCVAR_PLAYER_HEARTBEAT_INTERVAL <= g_fGameTime) || (iHeartBeats == 2 && g_fHeartBeatTime[client]+FCVAR_PLAYER_HEARTBEAT_FAST_INTERVAL <= g_fGameTime))
				{
					g_fHeartBeatTime[client] = g_fGameTime;
					EmitSoundToClient(client, "Lua_sounds/heartbeat.ogg", _, SNDCHAN_AUTO, _, _, 0.13);
					for (new i = 1;i <= MaxClients;i++)
					{
						if (!IsClientInGame(i) || IsFakeClient(i) || client == i) continue;
						EmitSoundToClient(i, "Lua_sounds/heartbeat.ogg", client, SNDCHAN_AUTO, _, _, 0.22);
					}
				}
			}	*/
		}
		else
		{
			if (!IsFakeClient(client)) QueryClientConVar(client, "voice_inputfromfile", QueryConVar_HLSS);
			if (iTeam == TEAM_SURVIVORS && g_bHasSquad[client])
			{
				iPlayerDeadCount++;
				for (new i = 0;i < iLobbySize;i++)
				{
					if (iPlayers[i] < 1)
					{
//						PrintToServer("\"%N\" has in %d", client, i);
						iPlayers[i] = client;
						break;
					}
					else
					{
						if (GetEntPropFloat(iPlayers[i], Prop_Send, "m_flDeathTime") > GetEntPropFloat(client, Prop_Send, "m_flDeathTime"))
						{
//							PrintToServer("\"%N\" has in %d (was \"%N\")", client, i, iPlayers[i]);
							if (i+1 < iLobbySize)
							{
								for (new j = iLobbySize-2;j >= i;j--)
								{
									if (iPlayers[j] > 0)
									{
//										PrintToServer("\"%N\" has moved back to %d", iPlayers[j], j+1);
										iPlayers[j+1] = iPlayers[j];
										iPlayers[j] = 0;
									}
								}
							}
							iPlayers[i] = client;
							break;
						}
					}
				}
			}
			else if (iTeam == TEAM_ZOMBIES && g_iZombieClass[client][VAR] >= -1)
			{
				iEnemyDeadCount++;
			}
			else if (iTeam == TEAM_SPECTATOR)
			{
				iSpectators[iSpectatorCount++] = client;
			}
		}
	}
	g_iSecurityAlive = iPlayerAliveCount;
	g_iSecurityDead = iPlayerDeadCount;
	UpdateBotsConfig(iPlayerAliveCount+iPlayerDeadCount, true, true);
	UpdateBotsToken(iPlayerAliveCount+iPlayerDeadCount);

	if (g_iLastManStand == -1 && g_iSecurityAlive == 1 && g_iSecurityDead > 0)
	{
		for (new j = 0;j < MAXPLAYER;j++)
		{
			if (g_iPlayersList[j] == -1 || !IsPlayerAlive(g_iPlayersList[j]))
				continue;

			g_iLastManStand = g_iPlayersList[j];
			//EmitSoundToAll("Lua_sounds/zombiehorde/lasthuman.ogg", _, SNDCHAN_AUTO);
			break;
		}
	}

	if (g_bCounterAttack)
	{
//		if ((g_fReinforcementPlayerDeployTime == 0.0 && g_fRoundTimeLeft < FCVAR_PLAYER_REINFORCEMENT_COUNTER_DEPLOY_TIME/*+20.0*/) || (g_fReinforcementPlayerDeployTime != 0.0 && g_fRoundTimeLeft <= g_fGameTime-g_fReinforcementPlayerDeployTime/*+20.0*/))

/*		if ((g_fReinforcementPlayerDeployTime == 0.0 && ((!g_bFinalCP && g_fRoundTimeLeft < FCVAR_PLAYER_REINFORCEMENT_COUNTER_DEPLOY_TIME) || (g_bFinalCP && g_fRoundTimeLeft < FCVAR_PLAYER_REINFORCEMENT_DEPLOY_TIME))) || (g_fReinforcementPlayerDeployTime != 0.0 && g_fRoundTimeLeft <= g_fGameTime-g_fReinforcementPlayerDeployTime))
		if ((g_fReinforcementPlayerDeployTime == 0.0 && ((!g_bFinalCP && g_fRoundTimeLeft < FCVAR_PLAYER_REINFORCEMENT_COUNTER_DEPLOY_TIME) || (g_bFinalCP && g_fRoundTimeLeft < FCVAR_PLAYER_REINFORCEMENT_DEPLOY_TIME))) || (g_fReinforcementPlayerDeployTime != 0.0 && g_fRoundTimeLeft <= g_fGameTime-g_fReinforcementPlayerDeployTime))
		{
			if (iPlayerDeadCount > 0 && !g_bReinforcementPlayerEnd && !g_bAlone)
			{
				g_bReinforcementPlayerEnd = true;
				if (g_bFinalCP) CreateTimer(3.0, Timer_SecurityOutOfReinforcements);
			}
		}
		else
		{	*/
		g_bReinforcementPlayerEnd = true;
		if (g_iNumControlPoints-1 == g_iCurrentControlPoint)
		{
			if (!g_bFinalCPMusic && g_fRoundTimeLeft <= 100.1)
			{
				g_bFinalCPMusic = true;
				EmitSoundToAll("Lua_sounds/Natural_Killers.ogg", _, SNDCHAN_AUTO, _, _, 0.77);
			}
			
			if (g_iHeliEvacPositionIndex >= 0)
			{
				if (g_fRoundTimeLeft > 15.0 && g_fRoundTimeLeft <= 20.0 && g_iHelicopterRef == INVALID_ENT_REFERENCE && !g_bHeliEvacStarted)
				{
					if (g_iHeliEvacPositionIndex > 0)
						HelicopterSpawn(g_vHeliEvacPosition[GetRandomInt(0, g_iHeliEvacPositionIndex)], _, 10, false);
					else if (g_iHeliEvacPositionIndex == 0)
						HelicopterSpawn(g_vHeliEvacPosition[0], _, 10, false);
				}
			}
			else if (g_fRoundTimeLeft <= 0.3)
			{
				new ent = FindEntityByClassname(-1, "ins_rulesproxy");
				if (ent > MaxClients && IsValidEntity(ent))
				{
					SetVariantInt(TEAM_SURVIVORS);
					AcceptEntityInput(ent, "EndRound");
				}
			}
		}
//		}
		if (!g_bReinforcementBotEnd)
		{
			if (!g_bFinalCP && g_fRoundTimeLeft <= FCVAR_BOT_REINFORCEMENT_COUNTER_END_TIME)
			{
				g_fReinforcementBotDeployTime = 0.0;
				g_bReinforcementBotEnd = true;
				CreateTimer(0.0, Timer_EnemyOutOfReinforcements, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	else if (iPlayerDeadCount > 0 && !g_bReinforcementPlayerEnd)
	{
		if (g_fRoundTimeLeft <= FCVAR_PLAYER_REINFORCEMENT_END_TIME || g_iReinforcementPlayerCount >= CVAR_PLAYER_REINFORCEMENT_MAX_PER_POINT)
		{
			g_bReinforcementPlayerEnd = true;
			CreateTimer(3.0, Timer_SecurityOutOfReinforcements);
		}
	}
	if (iPlayerAliveCount == 1 && iPlayerDeadCount == 0) g_bAlone = true;
	else g_bAlone = false;
	if (iPlayerDeadCount > 0 && iPlayerAliveCount > 0)
	{
		if (!g_bReinforcementPlayerEnd)
		{
//				new iPlayerRatio = RoundToCeil(float(iPlayerDeadCount)/float(iPlayerDeadCount+iPlayerAliveCount)*100.0);
			new bool:bDeploy = false;
			new iPlayerRequireCount = RoundToCeil((iPlayerDeadCount+iPlayerAliveCount)*CVAR_PLAYER_REINFORCEMENT_RATIO/100.0);
			if (iPlayerRequireCount < CVAR_PLAYER_REINFORCEMENT_MIN) iPlayerRequireCount = CVAR_PLAYER_REINFORCEMENT_MIN;
			else if (iPlayerRequireCount > CVAR_PLAYER_REINFORCEMENT_MAX) iPlayerRequireCount = CVAR_PLAYER_REINFORCEMENT_MAX;
			if (iPlayerRequireCount <= iPlayerDeadCount || g_fReinforcementPlayerDeployTime != 0.0)
			{
				if (g_fReinforcementPlayerDeployTime == 0.0)
				{
					new Float:fDeployTime = g_bCounterAttack && !g_bFinalCP ? FCVAR_PLAYER_REINFORCEMENT_COUNTER_DEPLOY_TIME:FCVAR_PLAYER_REINFORCEMENT_DEPLOY_TIME;
//					if (g_bFinalCP && g_bCounterAttack) fDeployTime += 15.0;
//					new Float:fDeployTime = FCVAR_PLAYER_REINFORCEMENT_DEPLOY_TIME;
//					if (g_bCounterAttack) fDeployTime = !g_bFinalCP ? FCVAR_PLAYER_REINFORCEMENT_COUNTER_DEPLOY_TIME:FCVAR_PLAYER_REINFORCEMENT_DEPLOY_TIME;
					if (g_fRoundTimeLeft >= fDeployTime/*+20.0*/)
					{
						g_fReinforcementPlayerDeployTime = g_fGameTime+fDeployTime;
						CreateTimer(3.0, Timer_SecurityReinforcementSetup, g_fReinforcementPlayerDeployTime, TIMER_FLAG_NO_MAPCHANGE);
	//						PrintToChatAll("\x08%sSurvivors \x01Reinforcements has been setup!", COLOR_SECURITY);
						LogToGame("Survivors Team has setup for reinforcements! (Time: %0.2f, Dead Players: %d, Require Count %d)", g_fReinforcementPlayerDeployTime-g_fGameTime, iPlayerDeadCount, iPlayerRequireCount);
					}
					else
					{
						g_bReinforcementPlayerEnd = true;
					}
				}
				else if (g_fReinforcementPlayerDeployTime <= g_fGameTime)
				{
					bDeploy = true;
//					if (g_fLastEdictCheck-g_fGameTime <= 1.0) g_fLastEdictCheck = g_fGameTime+3.0;
					g_fReinforcementPlayerDeployTime = 0.0;
					g_iReinforcementPlayerCount++;
					PrintCenterTextAll("我们的支援已经到达了！\n \n \n \n \n \n \n \n \n \n \n ");
					LogToGame("幸存者队伍已被部署 (次数: %d)", g_iReinforcementPlayerCount);
					if (iPlayerAliveCount == 1 && iPlayerDeadCount > 1)
						PlayGameSoundToAll("Player.Security_Hero_Cap");
					else
					{
						new String:sSoundFile[64];
						switch(GetRandomInt(1, 28))
						{
							case 1, 2: sSoundFile = "Lua_sounds/defend01.ogg";
							case 3: sSoundFile = "hq/security/roundstart_flashpoint2.ogg";
							case 4: sSoundFile = "hq/security/roundstart_flashpoint8.ogg";
							case 5: sSoundFile = "hq/security/roundstart_infiltrate2.ogg";
							case 6: sSoundFile = "hq/security/roundstart_infiltrate9.ogg";
							case 7: sSoundFile = "hq/security/roundstart_occupy2.ogg";
							case 8: sSoundFile = "hq/security/roundstart_occupy3.ogg";
							case 9: sSoundFile = "hq/security/roundstart_occupy4.ogg";
							case 10: sSoundFile = "hq/security/roundstart_occupy6.ogg";
							case 11: sSoundFile = "hq/security/roundstart_occupy8.ogg";
							case 12: sSoundFile = "hq/security/roundstart_occupy9.ogg";
							case 13: sSoundFile = "hq/security/roundstart_strike5.ogg";
							case 14: sSoundFile = "hq/security/roundstart_strike9.ogg";
							case 15: sSoundFile = "hq/security/roundstart_strike10.ogg";
							case 16: sSoundFile = "hq/security/roundstart_vendetta2.ogg";
							case 17: sSoundFile = "hq/security/roundstart_vendetta4.ogg";
							case 18: sSoundFile = "hq/security/roundstart_vendetta5.ogg";
							case 19: sSoundFile = "hq/security/roundstart_vendetta9.ogg";
							case 20: sSoundFile = "hq/security/roundstart_vendetta10.ogg";
							case 21: sSoundFile = "hq/security/theyhave1.ogg";
							case 22: sSoundFile = "hq/security/theyhave2.ogg";
							case 23: sSoundFile = "hq/security/theyhave3.ogg";
							case 24: sSoundFile = "hq/security/theyhave5.ogg";
							case 25: sSoundFile = "hq/security/theyhave8.ogg";
							case 26: sSoundFile = "hq/security/theyhave9.ogg";
							case 27: sSoundFile = "hq/security/theyhave10.ogg";
							case 28: sSoundFile = "hq/security/defendcache5.ogg";
						}
						EmitSoundToAll(sSoundFile, _, SNDCHAN_AUTO, _, _, 1.0);
					}
				}
			}
			new iPrintCount = iPlayerRequireCount;
			if (iPlayerDeadCount > iPlayerRequireCount)
			{
				if (iPlayerDeadCount < CVAR_PLAYER_REINFORCEMENT_MAX)
				{
					iPrintCount = iPlayerDeadCount;
				}
				else
				{
					iPrintCount = CVAR_PLAYER_REINFORCEMENT_MAX;
				}
			}
			else if (g_fReinforcementPlayerDeployTime != 0.0)
			{
				if (iPlayerDeadCount < iPlayerRequireCount)
					iPrintCount = iPlayerDeadCount;
			}
			new bool:bSpecUpdate = iSpectatorCount<=0?true:false;
			new String:sSoundFile[64];
			switch(GetRandomInt(1, 6))
			{
				case 1: sSoundFile = "player/voice/botsurvival/subordinate/aggressiveinv2.ogg";
				case 2: sSoundFile = "player/voice/botsurvival/subordinate/aggressiveinv4.ogg";
				case 3: sSoundFile = "player/voice/botsurvival/subordinate/aggressiveinv15.ogg";
				case 4: sSoundFile = "player/voice/botsurvival/subordinate/aggressiveinv16.ogg";
				case 5: sSoundFile = "player/voice/botsurvival/leader/aggressiveinv14.ogg";
				case 6: sSoundFile = "player/voice/botsurvival/leader/aggressiveinv15.ogg";
			}
			for (new i = 0;i < iLobbySize;i++)
			{
				if (iPlayers[i] > 0)
				{
					if (!bDeploy)
					{
						g_iLastSpecTarget[iPlayers[i]] = GetEntPropEnt(iPlayers[i], Prop_Send, "m_hObserverTarget");
						if (g_iLastSpecTarget[iPlayers[i]] < 1 || g_iLastSpecTarget[iPlayers[i]] > MaxClients || !IsClientInGame(g_iLastSpecTarget[iPlayers[i]]) || !IsPlayerAlive(g_iLastSpecTarget[iPlayers[i]]))
							g_iLastSpecTarget[iPlayers[i]] = -1;
						new String:sStatus[32] = "正在招募中...";
						if (i >= CVAR_PLAYER_REINFORCEMENT_MAX)
						{
							if (g_fReinforcementPlayerDeployTime != 0.0)
								Format(sStatus, sizeof(sStatus), "(%0.0f) 等待下一波增援...", g_fReinforcementPlayerDeployTime-g_fGameTime);
							else
								sStatus = "Wait for next deployment...";
						}
						else if (g_fReinforcementPlayerDeployTime != 0.0)
						{
							if (g_fReinforcementPlayerDeployTime-g_fGameTime > 5.9)
								Format(sStatus, sizeof(sStatus), " %0.0f %s 后复活", g_fReinforcementPlayerDeployTime-g_fGameTime, g_fReinforcementPlayerDeployTime-g_fGameTime>9.9?"秒":"秒");
							else
								if (g_iLastSpecTarget[iPlayers[i]] > 0) Format(sStatus, sizeof(sStatus), "在玩家 %N 上部署", g_iLastSpecTarget[iPlayers[i]]);
								else sStatus = "部署中...";
						}
						PrintHintText(iPlayers[i], "离下一波支援时间\n还有\n \n[%d / %d]\n %s ", iPlayerDeadCount, iPrintCount, sStatus);
						/*
								Line 1:		Reinforcement
								Line 2:		 Position. 2
								Line 3:			
								Line 4:		  [i / 6]
								Line 5:	  Spawn in  5 seconds...
							 Line 5(2):	     Deploying on NAME...
						*/
						
						if (!bSpecUpdate)
						{
							bSpecUpdate = true;
							if (g_fReinforcementPlayerDeployTime != 0.0)
							{
								if (g_fReinforcementPlayerDeployTime-g_fGameTime > 5.9)
								Format(sStatus, sizeof(sStatus), " %0.0f %s 后复活", g_fReinforcementPlayerDeployTime-g_fGameTime, g_fReinforcementPlayerDeployTime-g_fGameTime>9.9?"秒":"秒");
								else sStatus = "Deploying...";
							}
							else sStatus = "招募中...";
							for (new s = 0;s < iLobbySize;s++)
							{
								if (iSpectators[s] > 0)
									PrintHintText(iSpectators[s], "支援\n状态\n \n[%d / %d]\n %s ", iPlayerDeadCount, iPrintCount, sStatus);
								else break;
							}
						}
					}
					else if (i < CVAR_PLAYER_REINFORCEMENT_MAX)
					{
						EmitSoundToClient(iPlayers[i], sSoundFile);
						RespawnPlayer(iPlayers[i], 1);

						if (!bSpecUpdate)
						{
							bSpecUpdate = true;
							for (new s = 0;s < iLobbySize;s++)
							{
								if (iSpectators[s] > 0)
									PrintHintText(iSpectators[s], "支援\n状态\n \n \n 已部署 ");
								else break;
							}
						}
					}
				}
				else break;
			}
		}
		else
		{
			for (new i = 0;i < iLobbySize;i++)
			{
				if (iPlayers[i] > 0)
					PrintHintText(iPlayers[i], " \n \n没有支援了\n \n ");
				if (iSpectators[i] > 0)
					PrintHintText(iSpectators[i], " \n \n没有支援了\n \n ");
			}
		}
/*		else
		{
			for (new i = 0;i < iLobbySize;i++)
			{
				if (iPlayers[i] > 0)
				{
					PrintHintText("Wait for counter-attack ends");
				}
				else break;
			}
		}	*/
	}
	else g_fReinforcementPlayerDeployTime = 0.0;
	if (g_bCounterAttack)
	{
		new Float:fCounterAttackStartTime = (g_iNumControlPoints-1 != g_iCurrentControlPoint)?
		GetConVarFloat(g_hFcvarCounterAttackTime)-GetConVarFloat(g_hCvarCounterAttackDelay)
		:
		FCVAR_FINAL_COUNTERATTACK_TIME-GetConVarFloat(g_hCvarFinalCounterAttackDelay);
		if (g_fRoundTimeLeft-2.0 >= fCounterAttackStartTime)
		{
			g_bCounterAttackReadyTime = true;
		}
		else
		{
			if (g_bCounterAttackReadyTime)
			{
//				PlayGameSoundToAll("Player.Security_Outpost_NextWave");
				ZH_ZombieAlert();
				g_fSpawnUpdateLastFailedTime = 0.0;
				g_bCounterAttackReadyTime = false;
				g_bReinforcementBotEnd = false;
//				CreateTimer(0.0, Timer_CheckBotDistanceForNextObject, _, TIMER_FLAG_NO_MAPCHANGE);
				for (new client = 1;client <= MaxClients;client++)
				{
					if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TEAM_ZOMBIES)
						continue;

					new Float:fOrigin[3], Float:fPlayerOrigin[3], bool:bPlayerNearby = false;
					GetClientHeadOrigin(client, fOrigin, 10.0);
/*					GetClientEyePosition(client, fOrigin);
					switch(GetEntProp(client, Prop_Send, "m_iCurrentStance"))
					{
						case 0: fOrigin[2] += 4.0;	// Standing
						case 1: fOrigin[2] += 20.0;	// Duck
						case 2: fOrigin[2] += 52.0;	// Prone
					}	*/
					for (new j = 0;j < MAXPLAYER;j++)
					{
						if (g_iPlayersList[j] == -1 || !IsPlayerAlive(g_iPlayersList[j]))
							continue;

						new i = g_iPlayersList[j];
						GetClientHeadOrigin(i, fPlayerOrigin, 10.0);
/*						GetClientEyePosition(i, fPlayerOrigin);
						switch(GetEntProp(i, Prop_Send, "m_iCurrentStance"))
						{
							case 0: fPlayerOrigin[2] += 4.0;	// Standing
							case 1: fPlayerOrigin[2] += 20.0;	// Duck
							case 2: fPlayerOrigin[2] += 52.0;	// Prone
						}	*/
						new Handle:hTrace = TR_TraceRayFilterEx(fOrigin, fPlayerOrigin, MASK_SOLID_BRUSHONLY, RayType_EndPoint, Base_TraceFilter);
						if (TR_DidHit(hTrace))
						{
							CloseHandle(hTrace);
						}
						else
						{
							CloseHandle(hTrace);
							bPlayerNearby = true;
							break;
						}
						if (GetVectorDistance(fOrigin, fPlayerOrigin) <= 800.0)
						{
							bPlayerNearby = true;
							break;
						}
					}

					if (!bPlayerNearby)
					{
//						ForcePlayerSuicide(client);
						SDKCall(g_hPlayerRespawn, client);
						if (!IsPlayerAlive(client)) iEnemyDeadCount--;
						LogToGame("%N has been respawned for counterattack spawn (No players within 800 ft and no visible)", client);
					}
					else g_fSpawnTime[client] = g_fGameTime;
				}
			}
			if (g_iNumControlPoints-1 == g_iCurrentControlPoint && !g_bFinalCPMusic && g_fRoundTimeLeft <= 100.1)
			{
				g_bFinalCPMusic = true;
				EmitSoundToAll("Lua_sounds/Natural_Killers.ogg", _, SNDCHAN_AUTO, _, _, 0.77);
			}
			if (!g_bReinforcementBotEnd && !g_bFinalCP)
			{
				if (g_fRoundTimeLeft <= FCVAR_BOT_REINFORCEMENT_COUNTER_END_TIME || (g_bAlone && g_fRoundTimeLeft <= FCVAR_BOT_REINFORCEMENT_COUNTER_END_TIME*1.5))
				{
					g_fReinforcementBotDeployTime = 0.0;
					g_bReinforcementBotEnd = true;
					CreateTimer(0.0, Timer_EnemyOutOfReinforcements, _, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	else
	{
		if (!g_bReinforcementBotEnd)
		{
			if (g_fRoundTimeLeft <= FCVAR_BOT_REINFORCEMENT_END_TIME || g_iReinforcementBotCount >= CVAR_BOT_REINFORCEMENT_MAX_PER_POINT)
			{
				g_fReinforcementBotDeployTime = 0.0;
				g_bReinforcementBotEnd = true;
				CreateTimer(5.0, Timer_EnemyOutOfReinforcements, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
//	PrintToChatAll("ReinforceBotEnd %d  CAReadyTime %d", g_bReinforcementBotEnd, g_bCounterAttackReadyTime);
	g_iEnemyAlive = iEnemyAliveCount;
	g_iEnemyDead = iEnemyDeadCount;
	if (!g_bReinforcementBotEnd && !g_bCounterAttackReadyTime)
	{
		if (iEnemyDeadCount > 0 && g_fGameTime >= g_fSpawnUpdateLastFailedTime)
		{
			new bool:bDeploy = false;
			new bool:bBackSpawn = false;
			if (g_iCurrentControlPoint > 0 || g_bCounterAttack)
			{
				if (!g_bCounterAttack)
					bBackSpawn = GetRandomFloat(0.01, 100.00) <= FCVAR_BOT_REINFORCEMENT_BACKATTACK_CHANCE?true:false;
				else if (!g_bFinalCP)
					bBackSpawn = GetRandomFloat(0.01, 100.00) <= FCVAR_BOT_REINFORCEMENT_COUNTER_BACKATTACK_CHANCE?true:false;
			}
			new iEnemyRequireCount = RoundToCeil((iEnemyDeadCount+iEnemyAliveCount)*CVAR_BOT_REINFORCEMENT_RATIO/100.0);
			if (iEnemyRequireCount < CVAR_BOT_REINFORCEMENT_MIN) iEnemyRequireCount = CVAR_BOT_REINFORCEMENT_MIN;
			else if (iEnemyRequireCount > CVAR_BOT_REINFORCEMENT_MAX) iEnemyRequireCount = CVAR_BOT_REINFORCEMENT_MAX;
			if (iEnemyRequireCount <= iEnemyDeadCount)
			{
				if (g_fReinforcementBotDeployTime == 0.0)
				{
					if (!g_bCounterAttack)
					{
//						g_fReinforcementBotDeployTime = !g_bFinalCP?g_fGameTime+FCVAR_BOT_REINFORCEMENT_DEPLOY_TIME:g_fGameTime+FCVAR_BOT_REINFORCEMENT_FINAL_COUNTER_DEPLOY_TIME;
						g_fReinforcementBotDeployTime = g_fGameTime+FCVAR_BOT_REINFORCEMENT_DEPLOY_TIME_BASE+FCVAR_BOT_REINFORCEMENT_DEPLOY_TIME_BASE_MAX-(iPlayerAliveCount*FCVAR_BOT_REINFORCEMENT_DEPLOY_TIME_BASE);
					}
					else
					{
						if (!g_bFinalCP)	g_fReinforcementBotDeployTime = g_fGameTime+FCVAR_BOT_REINFORCEMENT_COUNTER_DEPLOY_TIME_BASE+FCVAR_BOT_REINFORCEMENT_COUNTER_DEPLOY_TIME_MAX-(iPlayerAliveCount*FCVAR_BOT_REINFORCEMENT_COUNTER_DEPLOY_TIME_BASE);
						// else if (g_iHelicopterRef != INVALID_ENT_REFERENCE) g_fReinforcementBotDeployTime = g_fGameTime+GetRandomFloat(FCVAR_BOT_REINFORCEMENT_FINAL_COUNTER_DEPLOY_TIME_MAX, FCVAR_BOT_REINFORCEMENT_FINAL_COUNTER_DEPLOY_TIME_MAX*2.0);
						else if (g_iHelicopterRef != INVALID_ENT_REFERENCE) g_fReinforcementBotDeployTime = g_fGameTime+FCVAR_BOT_REINFORCEMENT_FINAL_COUNTER_DEPLOY_TIME_MAX;
						else g_fReinforcementBotDeployTime = g_fGameTime+GetRandomFloat(FCVAR_BOT_REINFORCEMENT_FINAL_COUNTER_DEPLOY_TIME_MIN, FCVAR_BOT_REINFORCEMENT_FINAL_COUNTER_DEPLOY_TIME_MAX);
/*						if (!g_bAlone)	g_fReinforcementBotDeployTime = g_fGameTime+FCVAR_BOT_REINFORCEMENT_COUNTER_DEPLOY_TIME;
						else			g_fReinforcementBotDeployTime += g_fGameTime+(FCVAR_BOT_REINFORCEMENT_COUNTER_DEPLOY_TIME*GetRandomFloat(1.5, 2.0));	*/
					}
					LogToGame("Zombies Team has setup for reinforcements! (Time: %0.2f, Dead Players: %d, Require Count %d)", g_fReinforcementBotDeployTime-g_fGameTime, iEnemyDeadCount, iEnemyRequireCount);
				}
//				else if (g_fReinforcementBotDeployTime < g_fGameTime || (g_bCounterAttack && g_bFinalCP && iEnemyDeadCount > 0 && iEnemyAliveCount <= 3))
/*				else if (g_fReinforcementBotDeployTime < g_fGameTime ||
						(g_bCounterAttack && g_bFinalCP && iEnemyDeadCount > 0 && iEnemyAliveCount <= 3) ||
						(g_bCounterAttack && iPlayerAliveCount >= 2 && iEnemyDeadCount > 0 && iEnemyAliveCount <= 3) ||
						(g_bCounterAttack && !g_bAlone && iPlayerAliveCount == 1 && g_fRoundTimeLeft >= 30.0 && iEnemyDeadCount > 0 && iEnemyAliveCount <= 3) ||
						(g_bCounterAttack && g_bAlone && iEnemyDeadCount > 0 && iEnemyAliveCount <= 2))	*/
				else if (g_fReinforcementBotDeployTime < g_fGameTime || g_bCounterAttack &&
						( (g_bFinalCP && iEnemyDeadCount > 0 && iEnemyAliveCount <= RoundToCeil(float(iPlayerAliveCount)/1.2)) ||
						(iEnemyDeadCount > 0 && iEnemyAliveCount <= RoundToCeil(float(iPlayerAliveCount)/1.2)) ||
						(g_bAlone && iEnemyDeadCount > 0 && iEnemyAliveCount <= 3) )
						)
					bDeploy = true;
			}
			else g_fReinforcementBotDeployTime = 0.0;
			if (bDeploy)
			{
				new iRespawnCount = 0;
				new iSpawnLocation = 0;	// -2: Previous CP Spawn, -1: Back Spawn, 0: Normal Spawn, 1: Near Spawn, 2: Far away Spawn
				new bool:bUpdated = false;
				if (!g_bFinalCP)
				{
					if (!g_bCounterAttack)
					{
						if (!bBackSpawn)
						{
							if (!g_bTochedControlPoint)
								bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint, TEAM_ZOMBIES, 0, true, 900.0);

							if (!bUpdated)
							{
								bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint, TEAM_ZOMBIES, 1, true, 600.0);
								if (!bUpdated)
								{
/*									if (g_iCurrentControlPoint+1 != g_iNumControlPoints-1)
									{
										bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint+1, TEAM_SURVIVORS, -1, true, 1000.0);
										if (!bUpdated)
										{
											bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint+1, TEAM_ZOMBIES, 0, true, 500.0);
											if (!bUpdated)
											{
												bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint+1, TEAM_ZOMBIES, 1, true, 500.0);
												iSpawnLocation = 2;
											}
											else iSpawnLocation = 2;
										}
										else iSpawnLocation = 2;
									}		*/
								}
								else iSpawnLocation = 1;
							}
							else iSpawnLocation = 1;
						}
						else
						{
							switch(g_iCurrentControlPoint)
							{
								case -1:
								{
									bUpdated = false;
								}
								case 0:
								{
									bUpdated = UpdateSpawnPositions(0, TEAM_SURVIVORS, 0, true, 1200.0, 2500.0);
									iSpawnLocation = -1;
								}
/*								case 1:
								{
									bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint-1, TEAM_ZOMBIES, 0, true, 1200.0);
									iSpawnLocation = -1;
									if (!bUpdated)
									{
										bUpdated = UpdateSpawnPositions(0, TEAM_SURVIVORS, 0, true, 1200.0, 2500.0);
										iSpawnLocation = -2;
									}
								}	*/
								default:
								{
									bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint-1, TEAM_ZOMBIES, 0, true, 1200.0, 2500.0);
									iSpawnLocation = -1;
								/*	if (!bUpdated)
									{
										bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint-2, TEAM_ZOMBIES, 1, true, 1200.0, 2500.0);
										iSpawnLocation = -2;
									}	*/
								}
							}
						}
					}
					else
					{
						if (!bBackSpawn)
						{
							bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint, TEAM_ZOMBIES, 1, false);
							iSpawnLocation = 1;
						}
						else
						{
							switch(g_iCurrentControlPoint)
							{
								case -1:
								{
									bUpdated = false;
								}
								case 0:
								{
									bUpdated = UpdateSpawnPositions(0, TEAM_SURVIVORS, 0, true, 1200.0, 2500.0);
									iSpawnLocation = -1;
								}
/*								case 1:
								{
									bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint-1, TEAM_ZOMBIES, 0, true, 1200.0);
									iSpawnLocation = -1;
									if (!bUpdated)
									{
										bUpdated = UpdateSpawnPositions(0, TEAM_SURVIVORS, 0, true, 1200.0, 2500.0);
										iSpawnLocation = -2;
									}
								}	*/
								default:
								{
									bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint-1, TEAM_ZOMBIES, 0, true, 1200.0, 2500.0);
									iSpawnLocation = -1;
								/*	if (!bUpdated)
									{
										bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint-2, TEAM_ZOMBIES, 1, true, 1200.0, 2500.0);
										iSpawnLocation = -2;
									}	*/
								}
							}
						}
					}
				}
				else	// Final CP
				{
					if (!g_bCounterAttack)
					{
						if (!g_bTochedControlPoint)
							bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint, TEAM_ZOMBIES, 0, true, 600.0);

						if (!bUpdated)
						{
							bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint, TEAM_ZOMBIES, 1, true, 1500.0);
							if (!bUpdated)
							{
								bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint-1, TEAM_ZOMBIES, -1, true, 1500.0);
								iSpawnLocation = -1;
								if (!bUpdated)
								{
									bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint-2, TEAM_ZOMBIES, -1, true, 1000.0);
									iSpawnLocation = -2;
								}
								else iSpawnLocation = 1;
							}
							else iSpawnLocation = 1;
						}
						else iSpawnLocation = -1;
					}
					else
					{
						if (g_iFixMapLocation != 0 && g_iFixMapLocation != 3)
						{
							bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint, TEAM_ZOMBIES, 1, false);
							iSpawnLocation = 1;
/*							switch(GetRandomInt(0, 3))
							{
								case 0:
								{
									bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint, TEAM_SURVIVORS, -1, true, 1000.0);		// [BUG] Spawns A Security
									if (bUpdated) iSpawnLocation = -1;
									else
									{
										bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint, TEAM_ZOMBIES, 1, false);
										iSpawnLocation = 1;
									}
								}
								case 1, 2, 3:
								{
									bUpdated = UpdateSpawnPositions(g_iCurrentControlPoint, TEAM_ZOMBIES, 1, false);
									iSpawnLocation = 1;
								}
							}			*/
						}
						else if (g_iFixMapLocation == 0)	// miinstry_coop
						{
							switch(GetRandomInt(0, 3))
							{
								case 0:
								{
//												안쪽 금속 센서 스폰
									bUpdated = true;
									iSpawnLocation = -1;
									g_iNextSpawnPointsIndex = 4;
									g_vNextSpawnPoints[0] = Float:{-2932.8, -438.2, 62.6};
									g_vNextSpawnPoints[1] = Float:{-2928.5, -625.4, 70.4};
									g_vNextSpawnPoints[2] = Float:{-3112.8, -624.9, 70.2};
									g_vNextSpawnPoints[3] = Float:{-3094.5, -389.8, 70.4};
									g_vNextSpawnPoints[4] = Float:{-3093.4, -507.8, 70.7};
								}
								case 1:
								{
//												골목 스폰
									bUpdated = true;
									iSpawnLocation = 1;
									g_iNextSpawnPointsIndex = 9;
									g_vNextSpawnPoints[0] = Float:{-2473.6, -3290.3, 66.6};
									g_vNextSpawnPoints[1] = Float:{-2366.7, -3301.7, 66.6};
									g_vNextSpawnPoints[2] = Float:{-2286.6, -3300.0, 66.6};
									g_vNextSpawnPoints[3] = Float:{-2254.8, -3436.4, 66.3};
									g_vNextSpawnPoints[4] = Float:{-2478.1, -3437.1, 66.8};
									g_vNextSpawnPoints[5] = Float:{-2481.2, -3559.1, 66.8};
									g_vNextSpawnPoints[6] = Float:{-2408.5, -3659.4, 66.6};
									g_vNextSpawnPoints[7] = Float:{-2253.2, -3528.8, 66.4};
									g_vNextSpawnPoints[8] = Float:{-2145.3, -3451.9, 66.6};
									g_vNextSpawnPoints[9] = Float:{-2113.1, -3192.8, 66.6};
								}
								case 2:
								{
//												지하 추자장 쪽 스폰
									bUpdated = true;
									iSpawnLocation = -1;
									g_iNextSpawnPointsIndex = 11;
									g_vNextSpawnPoints[0] = Float:{-1569.2, -1475.9, -275.8};
									g_vNextSpawnPoints[1] = Float:{-1457.0, -1455.0, -275.1};
									g_vNextSpawnPoints[2] = Float:{-1364.8, -1441.8, -275.1};
									g_vNextSpawnPoints[3] = Float:{-1330.6, -1492.7, -275.1};
									g_vNextSpawnPoints[4] = Float:{-1424.3, -1502.4, -275.3};
									g_vNextSpawnPoints[5] = Float:{-1521.6, -1531.8, -275.3};
									g_vNextSpawnPoints[6] = Float:{-1595.7, -1621.8, -275.4};
									g_vNextSpawnPoints[7] = Float:{-1481.9, -1614.7, -275.6};
									g_vNextSpawnPoints[8] = Float:{-1515.6, -2211.2, -275.6};
									g_vNextSpawnPoints[9] = Float:{-1469.1, -2153.2, -275.8};
									g_vNextSpawnPoints[10] = Float:{-1483.1, -2264.1, -275.9};
									g_vNextSpawnPoints[11] = Float:{-1768.8, -1954.4, -275.1};
								}
								case 3:
								{
//												지하 주차장과 금속 센서 사이의 컴퓨터 방 안쪽 스폰
									bUpdated = true;
									iSpawnLocation = -1;
									g_iNextSpawnPointsIndex = 8;
									g_vNextSpawnPoints[0] = Float:{-2885.4, -1318.0, 68.1};
									g_vNextSpawnPoints[1] = Float:{-2879.0, -1224.0, 67.8};
									g_vNextSpawnPoints[2] = Float:{-2871.4, -1106.4, 67.1};
									g_vNextSpawnPoints[3] = Float:{-2947.6, -1101.5, 67.1};
									g_vNextSpawnPoints[4] = Float:{-2954.9, -1215.3, 67.7};
									g_vNextSpawnPoints[5] = Float:{-2960.3, -1299.1, 68.2};
									g_vNextSpawnPoints[6] = Float:{-3036.5, -1294.2, 68.2};
									g_vNextSpawnPoints[7] = Float:{-3029.2, -1180.4, 67.6};
									g_vNextSpawnPoints[8] = Float:{-3020.6, -1045.0, 66.9};
								}
							}
						}
						else if (g_iFixMapLocation == 3)	// launch_control_coop
						{
							switch(GetRandomInt(0, 2))
							{
								case 0:
								{
//												사일로 옆문 지하 계단통로
									bUpdated = true;
									iSpawnLocation = 1;
									g_iNextSpawnPointsIndex = 8;
									g_vNextSpawnPoints[0] = Float:{-241.3, 1742.1, -329.9};
									g_vNextSpawnPoints[1] = Float:{-244.0, 1801.9, -329.9};
									g_vNextSpawnPoints[2] = Float:{-502.9, 1780.9, -406.9};
									g_vNextSpawnPoints[3] = Float:{-606.4, 1790.6, -406.9};
									g_vNextSpawnPoints[4] = Float:{-727.3, 1802.0, -406.9};
									g_vNextSpawnPoints[5] = Float:{-259.8, 2288.7, -583.9};
									g_vNextSpawnPoints[6] = Float:{-250.7, 2375.1, -583.9};
									g_vNextSpawnPoints[7] = Float:{-253.4, 2469.0, -605.9};
									g_vNextSpawnPoints[8] = Float:{-255.5, 2545.4, -661.9};
								}
								case 1:
								{
//												반대편 숲속
									bUpdated = true;
									iSpawnLocation = 1;
									g_iNextSpawnPointsIndex = 15;
									g_vNextSpawnPoints[0] = Float:{-4132.8, 556.7, -28.3};
									g_vNextSpawnPoints[1] = Float:{-4370.1, 635.5, -35.3};
									g_vNextSpawnPoints[2] = Float:{-4262.5, 900.7, -33.3};
									g_vNextSpawnPoints[3] = Float:{-4441.0, 1046.6, -35.1};
									g_vNextSpawnPoints[4] = Float:{-4634.0, 833.0, -6.0};
									g_vNextSpawnPoints[5] = Float:{-4636.3, 540.6, 8.0};
									g_vNextSpawnPoints[6] = Float:{-4776.8, 819.0, 40.5};
									g_vNextSpawnPoints[7] = Float:{-4677.5, 1118.2, -39.1};
									g_vNextSpawnPoints[8] = Float:{-4540.9, 1352.2, -7.1};
									g_vNextSpawnPoints[9] = Float:{-4299.7, 1514.6, 82.2};
									g_vNextSpawnPoints[10] = Float:{-3900.6, 1384.8, 37.2};
									g_vNextSpawnPoints[11] = Float:{-3664.1, 1451.8, -43.6};
									g_vNextSpawnPoints[12] = Float:{-3898.3, 1675.0, 14.1};
									g_vNextSpawnPoints[13] = Float:{-4180.9, 1900.3, 12.6};
									g_vNextSpawnPoints[14] = Float:{-3984.0, 2088.1, 22.4};
									g_vNextSpawnPoints[15] = Float:{-3556.8, 1979.6, -12.0};
								}
								case 2:
								{
//												A거점 스폰
									bUpdated = true;
									iSpawnLocation = 1;
									g_iNextSpawnPointsIndex = 18;
									g_vNextSpawnPoints[0] = Float:{-1264.8, 643.8, -62.9};
									g_vNextSpawnPoints[1] = Float:{-1301.9, 609.9, -62.9};
									g_vNextSpawnPoints[2] = Float:{-1279.9, 559.6, -62.9};
									g_vNextSpawnPoints[3] = Float:{-1336.6, 544.8, -62.9};
									g_vNextSpawnPoints[4] = Float:{-1280.6, 499.5, -62.9};
									g_vNextSpawnPoints[5] = Float:{-1346.0, 496.0, -62.9};
									g_vNextSpawnPoints[6] = Float:{-1281.4, 450.3, -62.9};
									g_vNextSpawnPoints[7] = Float:{-1356.1, 423.7, -62.9};
									g_vNextSpawnPoints[8] = Float:{-1281.7, 379.8, -62.9};
									g_vNextSpawnPoints[9] = Float:{-1292.6, 320.7, -62.9};
									g_vNextSpawnPoints[10] = Float:{-1371.5, 317.4, -62.9};
									g_vNextSpawnPoints[11] = Float:{-1453.7, 324.1, -62.9};
									g_vNextSpawnPoints[12] = Float:{-1465.0, 395.5, -62.9};
									g_vNextSpawnPoints[13] = Float:{-1460.7, 432.1, -86.9};
									g_vNextSpawnPoints[14] = Float:{-1453.4, 491.5, -126.9};
									g_vNextSpawnPoints[15] = Float:{-1446.9, 544.2, -142.9};
									g_vNextSpawnPoints[16] = Float:{-1515.9, 557.1, -142.9};
									g_vNextSpawnPoints[17] = Float:{-1587.9, 559.1, -142.9};
									g_vNextSpawnPoints[18] = Float:{-1599.7, 502.8, -142.9};
								}
							}
						}
						else if (g_iFixMapLocation == 4)	// prophet_coop
						{
							bUpdated = true;
							iSpawnLocation = 1;
							g_iNextSpawnPointsIndex = 25;
							g_vNextSpawnPoints[0] = Float:{-1919.9, 187.1, 368.0};
							g_vNextSpawnPoints[1] = Float:{-1983.1, 186.3, 368.0};
							g_vNextSpawnPoints[2] = Float:{-1983.1, 106.4, 368.0};
							g_vNextSpawnPoints[3] = Float:{-1910.2, 106.2, 368.0};
							g_vNextSpawnPoints[4] = Float:{-1923.4, 48.7, 368.0};
							g_vNextSpawnPoints[5] = Float:{-1982.5, 48.7, 368.0};
							g_vNextSpawnPoints[6] = Float:{-1982.5, -20.4, 368.0};
							g_vNextSpawnPoints[7] = Float:{-1910.7, -20.6, 368.0};
							g_vNextSpawnPoints[8] = Float:{-1910.7, -81.8, 368.0};
							g_vNextSpawnPoints[9] = Float:{-1981.0, -82.0, 368.0};
							g_vNextSpawnPoints[10] = Float:{-1981.0, -158.9, 368.0};
							g_vNextSpawnPoints[11] = Float:{-1910.2, -159.5, 368.0};
							g_vNextSpawnPoints[12] = Float:{-1918.0, -204.9, 368.0};
							g_vNextSpawnPoints[13] = Float:{-1978.3, -204.8, 368.0};
							g_vNextSpawnPoints[14] = Float:{-2115.6, 59.0, 342.7};
							g_vNextSpawnPoints[15] = Float:{-2128.0, -21.0, 336.5};
							g_vNextSpawnPoints[16] = Float:{-2205.7, -37.5, 297.6};
							g_vNextSpawnPoints[17] = Float:{-2225.4, 48.7, 287.8};
							g_vNextSpawnPoints[18] = Float:{-2062.2, 19.1, 128.0};
							g_vNextSpawnPoints[19] = Float:{-2059.8, -50.6, 128.0};
							g_vNextSpawnPoints[20] = Float:{-1952.0, -54.4, 128.0};
							g_vNextSpawnPoints[21] = Float:{-1940.2, 34.3, 128.0};
							g_vNextSpawnPoints[22] = Float:{-1857.1, 119.2, 128.0};
							g_vNextSpawnPoints[23] = Float:{-1842.3, -148.1, 128.0};
							g_vNextSpawnPoints[24] = Float:{-1440.9, -138.9, 128.0};
							g_vNextSpawnPoints[25] = Float:{-1460.2, 90.8, 128.0};
						}
					}
				}
				
				if (bUpdated)
				{
//					if (g_fLastEdictCheck-g_fGameTime <= 1.0) g_fLastEdictCheck = g_fGameTime+3.0;
					g_fReinforcementBotDeployTime = 0.0;
					g_iReinforcementBotCount++;
				/*	if (g_iCurrentControlPoint < 3)
						PlayGameSoundToAll("Player.Security_Outpost_NextWave");
					else
					{
						GetRandomInt(0, 5) != 0?
						PlayGameSoundToAll("Player.Security_Outpost_NextWave"):
						PlayGameSoundToAll("Player.Security_Outpost_NextLevel_20AndAbove");
					}
					new String:sColor[9] = COLOR_GHOSTWHITE, String:sLocation[25] = "Incoming";
					if (!g_bFinalCP)
					{
						switch(iSpawnLocation)
						{
							case 2:
							{
								sColor = COLOR_GHOSTWHITE;
								sLocation = "Incoming from far away";
							}
							case 0, 1:
							{
								sColor = COLOR_GHOSTWHITE;
								sLocation = "Incoming";
							}
							case -1:
							{
								sColor = COLOR_GREEN;
								sLocation = "Right behind ";
							}
							case -2:
							{
								sColor = COLOR_FORESTGREEN;
								sLocation = "Behind ";
							}
						}
						if (iSpawnLocation < 0)
						{
							decl String:sSoundFile[128];
							Format(sSoundFile, sizeof(sSoundFile), "soundscape/emitters/oneshot/dist_crowd_warzone_0%d.ogg", GetRandomInt(1, 7));
							PlayGameSoundToAll(sSoundFile);
							if (GetRandomInt(0, 1) == 0)
								PlayGameSoundToAll("soundscape/emitters/oneshot/mil_radio_03.ogg");
							else PlayGameSoundToAll("soundscape/emitters/oneshot/mil_radio_04.ogg");
							{
								PrintToChatAll("\x08%sZombies \x01incoming from \x08%s%s\x01!", COLOR_INSURGENTS, sColor, sLocation);
								PrintCenterTextAll("Zombies incoming from\n\n%s !", iSpawnLocation == -2?"              Behind":"         Right behind");
							}
						}
						else PrintToChatAll("\x08%sInsurgents \x08%sIncoming\x01!", COLOR_INSURGENTS, COLOR_GHOSTWHITE);
					}
					else PrintToChatAll("\x08%sInsurgents \x08%s%s\x01!", COLOR_INSURGENTS, sColor, sLocation);	*/
					LogToGame("Zombies (%d) deployed on location: %d, point: %d, deploy count: %d", iRespawnCount, iSpawnLocation, g_iCurrentControlPoint, g_iReinforcementBotCount);
					for (new i = 1;i <= MaxClients;i++)
					{
						if (!IsClientInGame(i) || IsPlayerAlive(i) || GetClientTeam(i) != TEAM_ZOMBIES || g_iZombieClass[i][VAR] < -1) continue;
						if (iRespawnCount < CVAR_BOT_REINFORCEMENT_MAX)
						{
							iRespawnCount++;
							RespawnPlayer(i, iSpawnLocation);
							if (iRespawnCount >= CVAR_BOT_REINFORCEMENT_MAX || (bBackSpawn && iRespawnCount >= 10))
								break;
						}
					}
				}
				else g_fSpawnUpdateLastFailedTime = g_fGameTime+1.5;
			}
		}
		else g_fReinforcementBotDeployTime = 0.0;
	}
	if (g_fFlagDropTime != 0.0 && g_iPointFlag != INVALID_ENT_REFERENCE && g_iPointFlagOwner == -1 && g_fFlagDropTime+FCVAR_FLAG_BOT_RETURN_TIME <= g_fGameTime)
	{
		new Float:vFlagPos[3], Float:vTargetPos[3], Float:fDistance, Float:fNearestDistance = FCVAR_FLAG_BOT_RETURN_DISTANCE, Float:vNearest[3] = {-9000.0, 0.0, 0.0};
		if (g_fFlagDropTime+FCVAR_FLAG_BOT_RETURN_TIME_MAX <= g_fGameTime) fNearestDistance = 900000.0;
		GetEntPropVector(g_iPointFlag, Prop_Data, "m_vecAbsOrigin", vFlagPos);
		for (new i = 1;i <= MaxClients;i++)
		{
			if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != TEAM_ZOMBIES) continue;
			GetClientAbsOrigin(i, vTargetPos);
			fDistance = GetVectorDistance(vTargetPos, vFlagPos);
			if (fDistance <= fNearestDistance)
			{
				vNearest[0] = vTargetPos[0];
				vNearest[1] = vTargetPos[1];
				vNearest[2] = vTargetPos[2];
				fNearestDistance = fDistance;
			}
		}
		if (vNearest[0] != -9000.0)
		{
//			g_bDoNotPlayFlagPickUp = true;
			vNearest[2] += 10.0;
			TeleportEntity(g_iPointFlag, vNearest, NULL_VECTOR, NULL_VECTOR);
			g_fFlagDropTime = 0.0;
		}
	}
	return;
}

public Action:Timer_TurnOffBlockZone(Handle:timer, any:client)
{
	g_iPLFBlockzone[client] = 0;
}

public Action:Timer_FadeOutCall(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_iGameState != 4) return;
	new String:sSoundFile[64];
	switch(GetRandomInt(1, 7))
	{
		case 1: sSoundFile = "player/voice/botsurvival/subordinate/flashbanged14.ogg";
		case 2: sSoundFile = "player/voice/botsurvival/leader/flashbanged17.ogg";
		case 3: sSoundFile = "player/voice/botsurvival/subordinate/flashbanged17.ogg";
		case 4: sSoundFile = "player/voice/botsurvival/leader/flashbanged18.ogg";
		case 5: sSoundFile = "player/voice/botsurvival/subordinate/flashbanged20.ogg";
		case 6: sSoundFile = "player/voice/botsurvival/leader/flashbanged20.ogg";
		case 7: sSoundFile = "player/voice/botsurvival/subordinate/flashbanged21.ogg";
	}
	EmitSoundToAll(sSoundFile, client, SNDCHAN_VOICE, _, _, 1.0);
	FakeClientCommand(client, "say 我什么都看不到了！  (低血量黑屏)");
}

public Action:Timer_FadeIn(Handle:timer, any:client)
{
	if (!IsClientInGame(client)) return;
	ClientScreenFade(client, 6500, FFADE_IN|FFADE_PURGE, 1, 0, 0, 0, 255);
}

public Action:Timer_SecurityReinforcementSetup(Handle:timer, any:time)
{
	if (!g_bReinforcementPlayerEnd && GetGameState() == 4 && !GetCounterAttack() && time == g_fReinforcementPlayerDeployTime)
		PlayGameSoundToAll("Player.Security_ReinforcementsLow");
}

public Action:Timer_EnemyOutOfReinforcements(Handle:timer)
{
	if (g_bReinforcementBotEnd && GetGameState() == 4)
	{
//		PlayGameSoundToAll("Player.Security_EnemyOutOfReinforcements");
		ZH_ZombieAlert();
		PrintToChatAll("\x08%s僵尸 \x01已 \x03纷至沓来...", COLOR_INSURGENTS);
		LogToGame("Zombies is out of fresh bodies...");
	}
}

public ZH_ZombieAlert()
{
	if (g_iGameState != 4 || !g_bUpdatedSpawnPoint) return;
	decl String:scream_sound[128];
	switch(GetRandomInt(0, 2))
	{
		case 0: scream_sound = "Lua_sounds/zombiehorde/zombies/fast/fz_alert_far1.wav";
		default: Format(scream_sound, sizeof(scream_sound), "Lua_sounds/zombiehorde/zombies/common/scream%d.ogg", GetRandomInt(1, 4));
	}
	EmitSoundToAll(scream_sound, _, _, _, _, 1.0);
}

public Action:Timer_SecurityOutOfReinforcements(Handle:timer)
{
	if (g_bReinforcementPlayerEnd && GetGameState() == 4)
	{
		PlayGameSoundToAll("Player.Security_ReinforcementsOut");
		PrintToChatAll("\x08%s幸存者 \x01 \x03已经没有多余的支援了！", COLOR_SECURITY);
		LogToGame("Survivors is out of reinforcement!");
	}
}

public Action:ThinkTimer(Handle:timer)
{
	g_iGameState = GetGameState();
	g_fGameTime = GetGameTime();
	if (g_iGameState == 3 && g_bUpdatedSpawnPoint)
	{
		PrintCenterTextAll("瞄 准 头 部");
		for (new i = 0;i < MAXPLAYER;i++)
		{
			if (g_iPlayersList[i] == -1 || !IsPlayerAlive(g_iPlayersList[i]))
				continue;
				
			new client = g_iPlayersList[i];
			if (g_iPlayerLastKnife[client] != -1)
			{
				// #Resupply Check
				new iKnife = GetPlayerWeaponByName(client, "weapon_kabar");
				if (iKnife > MaxClients && IsValidEdict(iKnife))
					iKnife = EntIndexToEntRef(iKnife);
				else
				{
					iKnife = GivePlayerItem(client, "weapon_kabar");
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
	if (g_iGameState != 4 || !g_bUpdatedSpawnPoint) return;

	g_fRoundTimeLeft = GameRules_GetPropFloat("m_flRoundLength")-(g_fGameTime-GameRules_GetPropFloat("m_flRoundStartTime"));
	for (new client = 1;client <= MaxClients;client++)
	{
		if (!IsClientInGame(client)) continue;
		new bool:bIsBot = IsFakeClient(client);
		new iTeam = GetClientTeam(client);

		if (!bIsBot)
		{
			if (g_fPlayerAmbientTime[client] <= g_fGameTime)
			{
				g_fPlayerAmbientTime[client] = g_fGameTime+58.0;
				EmitSoundToClient(client, "Lua_sounds/zombiehorde/zr_ambience.ogg", _, _, _, _, 0.33);
			}
			if (!g_bPlayerBandageSound[client])
			{
				if (g_iPlayerHealthkitHealingBy[client] != -1 && g_fPlayerHealthkitBandaging[client] != 0.0)
				{
					g_bPlayerBandageSound[client] = true;
					EmitSoundToAll("Lua_sounds/bandaging.wav", client, SNDCHAN_STATIC, _, _, 0.8);
				}
			}
			else
			{
				if (g_iPlayerHealthkitHealingBy[client] == -1 || !IsClientInGame(g_iPlayerHealthkitHealingBy[client]) || !IsPlayerAlive(client) || !IsPlayerAlive(g_iPlayerHealthkitHealingBy[client]))
				{
					g_bPlayerBandageSound[client] = false;
					StopSound(client, SNDCHAN_STATIC, "Lua_sounds/bandaging.wav");
				}
			}
		}
		/*if (g_iSecurityAlive+g_iSecurityDead > 2 && g_bMedicPlayer[client])
		{
			if (g_fGameTime-g_fMedicLastHealTime[client] >= 300.0)
			{
				if (!g_bMedicForceToChange[client])
				{
					if (g_iSecurityAlive > 1)
					{
						g_bMedicForceToChange[client] = true;
						PrintToChat(client, "\x05如果你不治疗你的队友， \x08%s你的职业将会被变更", COLOR_RED);
						PrintToChat(client, "\x05如果你不治疗你的队友， \x08%s你的职业将会被变更", COLOR_RED);
					}
					else g_fMedicLastHealTime[client] += 60.0;
				}
			}
			else if (g_fGameTime-g_fMedicLastHealTime[client] >= 240.8 && g_fGameTime-g_fMedicLastHealTime[client] <= g_fGameTime-g_fMedicLastHealTime[client] < 240.0)
			{
				PrintToChat(client, "\x05在 \x0160 秒内不治疗你的队友\x05， \x08%s你的职业将会被变更", COLOR_RED);
			}
		}*/
		if (IsPlayerAlive(client))
		{
			if (g_fBurnTime[client] != 0.0)
			{
				new waterlevel = GetEntData(client, g_iOffsetWaterlevel);
				if (waterlevel >= 1/* && waterlevel < 5*/) // 5 = round end state
					g_fBurnTime[client] = 0.0;
				else if (g_iPlayerStance[client] == 2)
					g_fBurnTime[client] = 0.0;
				else if (GetEntProp(client, Prop_Send, "m_bWasSliding") == 1)
					g_fBurnTime[client] = 0.0;

				if (g_fGameTime < g_fBurnTime[client])
				{
					if (g_fGameTime >= g_fNextBurnTime[client])
					{
						g_fNextBurnTime[client] = g_fGameTime+1.2;
						IgniteEntity(client, 1.0);
					}
				}
				else
				{
					g_fBurnTime[client] = 0.0;
					g_fNextBurnTime[client] = 0.0;
					if (iTeam == TEAM_SURVIVORS) EmitSoundToAll("player/focus_exhale.wav", client, SNDCHAN_STATIC, _, _, 1.0);
					else
					{
						SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_fZombieNextStats[client][SPEED]);
						ZombieBurnSound(client, false);
					}
				}
			}
			if (g_iPlayerBleeding[client] != 0)
			{
				if (g_fGameTime >= g_fPlayerBleedTime[client])
				{
					new iHealth = GetEntProp(client, Prop_Send, "m_iHealth");
					new iBleedDamage = GetRandomInt(CVAR_PLAYER_BLEEDING_DAMAGE_MIN, CVAR_PLAYER_BLEEDING_DAMAGE_MAX);
					new bool:bMajorBleeding = (float(iBleedDamage) >= float(CVAR_PLAYER_BLEEDING_DAMAGE_MAX)/1.5)?true:false;
					if (bIsBot) iBleedDamage *= 2;
					if (g_iPlayerBleeding[client] > 0 && g_iPlayerBleeding[client] <= MaxClients && IsClientInGame(g_iPlayerBleeding[client]))
						Entity_Hurt(client, iBleedDamage, g_iPlayerBleeding[client], DMG_SLASH, "Bleeding");
					else
						Entity_Hurt(client, iBleedDamage, -1, DMG_SLASH, "Bleeding");
					if (iBleedDamage < iHealth)
					{
						new String:sSound[256];
						if (iTeam == TEAM_SURVIVORS)
						{
							// FakeClientCommand(client, "say I'm bleeding!");
							PrintToChat(client, "\x08%s你正处于出血状态！ 使用 \x01医疗包 \x08%s！", COLOR_DARKORANGE, COLOR_DARKORANGE);
							ClientScreenShake(client, SHAKE_START, GetRandomFloat(10.0, 15.0), GetRandomFloat(10.0, 15.0), GetRandomFloat(1.00, 2.00));
							if (!IsLightModel(client))
								Format(sSound, sizeof(sSound), "player/voice/responses/security/subordinate/unsuppressed/wounded%d.ogg", GetRandomInt(1, 19));
							else
								Format(sSound, sizeof(sSound), "player/voice/responses/security/leader/unsuppressed/wounded%d.ogg", GetRandomInt(1, 18));
							DisplayInstructorHint(client, 5.0, 0.0, 3.0, true, true, "icon_alert", "icon_alert", "", true, {255, 255, 255}, "失血状态！使用[医疗包]");
						}
						else Format(sSound, sizeof(sSound), "player/voice/responses/insurgent/subordinate/unsuppressed/wounded1.ogg");
						EmitSoundToAll(sSound, client, SNDCHAN_VOICE, _, _, 1.0);

						new particle = CreateEntityByName("info_particle_system");
						if (particle > MaxClients && IsValidEntity(particle))
						{
							decl String:addoutput[64];
							DispatchKeyValue(particle, "classname", "LuaTempParticle");
							SetEntPropEnt(particle, Prop_Data, "m_hOwnerEntity", client);
							if (!bMajorBleeding)
							{
								DispatchKeyValue(particle, "effect_name", "gore_blood_droplets_short");
//								CreateTimer(GetRandomFloat(3.0, 4.0), DeleteParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
								Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1", GetRandomFloat(3.0, 4.0));
							}
							else
							{
								DispatchKeyValue(particle, "effect_name", "gore_blood_droplets_long");
//								CreateTimer(GetRandomFloat(4.0, 6.0), DeleteParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
								Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1", GetRandomFloat(4.0, 6.0));
							}
							SetVariantString("!activator");
							AcceptEntityInput(particle, "SetParent", client, particle, 0);
							switch(GetRandomInt(0, 2))
							{
								case 0: SetVariantString("eyes");
								case 1: SetVariantString("primary");
								case 2:
								{
									if (GetRandomInt(0, 1) == 0)
										SetVariantString("lknee");
									else
										SetVariantString("rknee");
								}
							}
							AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
							DispatchSpawn(particle);
							AcceptEntityInput(particle, "start");
							ActivateEntity(particle);
							SetVariantString(addoutput);
							AcceptEntityInput(particle, "AddOutput");
							AcceptEntityInput(particle, "FireUser1");
						}
					}
					g_fPlayerBleedTime[client] = g_fGameTime+(iTeam==TEAM_SURVIVORS?GetRandomFloat(FCVAR_PLAYER_BLEEDING_INTERVAL_MIN, FCVAR_PLAYER_BLEEDING_INTERVAL_MAX):GetRandomFloat(FCVAR_ZOMBIE_BLEEDING_MIN_TIME, FCVAR_ZOMBIE_BLEEDING_MAX_TIME));
//					SDKHooks_TakeDamage(client, -1, -1, iBleedDamage, DMG_DIRECT, -1, NULL_VECTOR, NULL_VECTOR);
				}
			}
			if (iTeam == TEAM_ZOMBIES)
			{
/*				if (GetEntProp(client, Prop_Data, "m_StuckLast") >= 5000)
				{
					LogToGame("%N has killed due to stuck too long", client);
					ForcePlayerSuicide(client);
//					RespawnPlayer(client);
					continue;
				}	*/
				if (g_iPlayerBleeding[client] == 0 && g_fBurnTime[client] == 0.0)
				{
					new iMaxHp = GetEntProp(client, Prop_Data, "m_iMaxHealth");
					new iHp = GetEntProp(client, Prop_Send, "m_iHealth");
					if (iHp < iMaxHp)
					{
						if (iHp <= iMaxHp/2) iMaxHp /= 2;
						iHp = RoundToNearest(GetRandomFloat(0.002, 0.012)*float(iMaxHp))+iHp;
						if (iHp > iMaxHp) iHp = iMaxHp;
						SetEntProp(client, Prop_Send, "m_iHealth", iHp);
					}
				}
				if (g_iZombieClass[client][CLASS] > -1)
				{
					new Float:fBotOrigin[3], Float:fDistance, bool:bFaraway = true;
					GetClientEyePosition(client, fBotOrigin);
					for (new j = 0;j < MAXPLAYER;j++)
					{
						if (g_iPlayersList[j] == -1 || !IsClientInGame(g_iPlayersList[j]) || !IsPlayerAlive(g_iPlayersList[j]))
							continue;

						new target = g_iPlayersList[j];
						new Float:fTargetOrigin[3];
						GetClientEyePosition(target, fTargetOrigin);
						fDistance = GetVectorDistance(fBotOrigin, fTargetOrigin);
						if (g_iZombieClass[client][CLASS] == ZOMBIE_IED_INDEX && g_iZombieClass[client][VAR] >= 66)
						{
		//					new bool:bDucking = false;
							new Float:fDetonateDistance = FCVAR_ZOMBIE_IED_C4_DETONATE_DISTANCE;
							if (g_iZombieClass[client][VAR] <= 68)
								fDetonateDistance = FCVAR_ZOMBIE_IED_GRENADE_DETONATE_DISTANCE;
							GetClientEyePosition(client, fBotOrigin);
							GetClientEyePosition(target, fTargetOrigin);
							fDistance = GetVectorDistance(fBotOrigin, fTargetOrigin);
							if (fDistance <= FCVAR_ZOMBIE_BONUS_SPEED_DISTANCE)
								bFaraway = false;
	//						if (fDistance <= FCVAR_ZOMBIE_IED_DUCKING_DISTANCE)
	//							bDucking = true;
							if (fDistance <= fDetonateDistance)
							{
								new Handle:hTrace = TR_TraceRayFilterEx(fBotOrigin, fTargetOrigin, MASK_SOLID, RayType_EndPoint, Filter_Not_Players);
								if (!TR_DidHit(hTrace))
								{
									// Retrieve view and target eyes position
									decl Float:fBotAngle[3], Float:fBotAngleVec[3], Float:fVector[3], Float:fDir[3];

									// Calculate view direction
									GetClientEyeAngles(client, fBotAngle);
									fBotAngle[0] = fBotAngle[2] = 0.0;
									GetAngleVectors(fBotAngle, fBotAngleVec, NULL_VECTOR, NULL_VECTOR);
									
									fVector[0] = fTargetOrigin[0]-fBotOrigin[0];
									fVector[1] = fTargetOrigin[1]-fBotOrigin[1];
									fVector[2] = 0.0;

									// Check dot product. If it's negative, that means the viewer is facing
									// backwards to the target.
									NormalizeVector(fVector, fDir);
									if (GetVectorDotProduct(fBotAngleVec, fDir) >= 0.6)
									{
										g_iZombieClass[client][VAR] = -g_iZombieClass[client][VAR];
										g_iLastSpecTarget[client] = GetRandomInt(0, 2);
										switch(g_iLastSpecTarget[client])
										{
											case 0: EmitSoundToAll("Lua_sounds/zombiehorde/zombies/ied/zombine_charge1.wav", client, SNDCHAN_VOICE, _, _, 1.0);
											case 1: EmitSoundToAll("Lua_sounds/zombiehorde/zombies/ied/zombine_charge2.wav", client, SNDCHAN_VOICE, _, _, 1.0);
											case 2: EmitSoundToAll("Lua_sounds/zombiehorde/zombies/ied/zombine_readygrenade2.wav", client, SNDCHAN_VOICE, _, _, 1.0);
										}
										new Float:fDetonateTime = GetRandomFloat(3.00, 4.00);
										if (g_iPlayerStatus[client] & STATUS_INIEDJAMMER)
										{
											fDetonateTime *= GetRandomFloat(1.5, 2.5);
											CreateTimer(GetRandomFloat(0.3, 0.6), Timer_JihadNoticeIEDJammer, target, TIMER_FLAG_NO_MAPCHANGE);
										}
										else CreateTimer(GetRandomFloat(0.3, 0.6), Timer_JihadNotice, target, TIMER_FLAG_NO_MAPCHANGE);
										AttachParticle(client, "ins_flaregun_trail_glow_b", false, true, fDetonateTime, 300, 0.0);
										CreateTimer(fDetonateTime, Timer_Jihad, client, TIMER_FLAG_NO_MAPCHANGE);
										LogToGame("Zombie \"%N\" has triggered jihad by \"%N\" on time %0.3f", client, target, fDetonateTime);
										break;
									}
								}
								CloseHandle(hTrace);
							}
						}
						else if (fDistance <= FCVAR_ZOMBIE_BONUS_SPEED_DISTANCE)
						{
							bFaraway = false;
							break;
						}
	/*					if (g_iZombieClass[client][CLASS] >= 66 && bDucking)
							SetEntProp(client, Prop_Data, "m_bDuckToggled", 1);
						else if (GetEntProp(client, Prop_Data, "m_bDuckToggled") != 0)
						{
							SetEntProp(client, Prop_Send, "m_iCurrentStance", 0);
							SetEntProp(client, Prop_Data, "m_bDuckToggled", 0);
						}	*/
					}
					if (bFaraway)
					{
						if (fDistance <= FCVAR_ZOMBIE_BONUS_SPEED_DISTANCE)
						{
							if (GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue") != g_fZombieNextStats[client][SPEED]+FCVAR_ZOMBIE_BONUS_SPEED)
							{
								SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_fZombieNextStats[client][SPEED]+FCVAR_ZOMBIE_BONUS_SPEED);
								// LogToGame("Zombie \"%N\" has faraway from survivors, set speed to %0.2f", client, g_fZombieNextStats[client][SPEED]+FCVAR_ZOMBIE_BONUS_SPEED);
							}
						}
						else if (fDistance <= FCVAR_ZOMBIE_BONUS_SPEED_DISTANCE*2.0)
						{
							if (GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue") < g_fZombieNextStats[client][SPEED]+(FCVAR_ZOMBIE_BONUS_SPEED*2.0))
							{
								SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_fZombieNextStats[client][SPEED]+(FCVAR_ZOMBIE_BONUS_SPEED*2.0));
								// LogToGame("Zombie \"%N\" has faraway from survivors, set speed to %0.2f", client, g_fZombieNextStats[client][SPEED]+FCVAR_ZOMBIE_BONUS_SPEED);
							}
						}
					}
					else
					{
						if (GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue") >= g_fZombieNextStats[client][SPEED]+FCVAR_ZOMBIE_BONUS_SPEED)
						{
							new Float:fSpeed = g_fZombieNextStats[client][SPEED];
							if (g_iPlayerBleeding[client] != 0)
								fSpeed = fSpeed-GetRandomFloat(FCVAR_ZOMBIE_BLEED_REDUCE_SPEED_MIN, FCVAR_ZOMBIE_BLEED_REDUCE_SPEED_MAX);
							else if (g_iZombieBurnSound[client] != 0)
								fSpeed = fSpeed+GetRandomFloat(FCVAR_ZOMBIE_BURN_BONUS_SPEED_MIN, FCVAR_ZOMBIE_BURN_BONUS_SPEED_MAX);
							// LogToGame("Zombie \"%N\" has no longer faraway from survivors, set speed to %0.2f", client, fSpeed);
							SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", fSpeed);
						}
					}
					
					if (g_iZombieClass[client][CLASS] != ZOMBIE_IED_INDEX)
					{
						if (g_iZombieClass[client][VAR] == 0 && g_fGameTime-g_fPlayerLastLeaped[client] >= 3.0)
						{
							if (g_iZombieClass[client][CLASS] != ZOMBIE_LEAPER_INDEX)
							{
								new iTarget = GetClientAimTarget(client, true);
								// if (iTarget > 0 && GetClientTeam(iTarget) == TEAM_SURVIVORS && GetEntityFlags(client) & FL_ONGROUND)
								if (iTarget > 0 && GetClientTeam(iTarget) == TEAM_SURVIVORS)
								{
									if (g_fGameTime-g_fPlayerLastLeaped[iTarget] >= 5.0)
									{
										new Float:vAng[3];
										GetClientEyeAngles(client, vAng);
										if (vAng[0] <= -20.0)
										{
											new Float:fVel[3], Float:fSpeed;
											GetEntPropVector(iTarget, Prop_Data, "m_vecAbsVelocity", fVel);
											// if (fVel[2] > 60.0) fVel[2] = 60.0;
											// else if (fVel[2] < 20.0) fVel[2] = 20.0;
											fSpeed = GetVectorLength(fVel, false);
											if (fSpeed <= 100.0) ZH_ZombieLeapReady(client, iTarget);
											// else PrintToChatAll("%N looking, Speed %0.2f", client, fSpeed);	// #DEBUG
										}
										// else PrintToChatAll("%N looking, vAng[0] %0.2f", client, vAng[0]);	// #DEBUG
									}
								}
							}
							else
							{
								new iTarget = GetClientAimTarget(client, true);
								// if (iTarget > 0 && GetClientTeam(iTarget) == TEAM_SURVIVORS && GetEntityFlags(client) & FL_ONGROUND)
								if (iTarget > 0 && GetClientTeam(iTarget) == TEAM_SURVIVORS)
								{
									ZH_ZombieLeapReady(client, iTarget);
								}
							}
						}
						// else if (g_iZombieClass[client][VAR] == 1)
						// {
							// new iFlags = GetEntProp(client, Prop_Send, "m_iPlayerFlags");
							// if (iFlags & ~INS_PL_SLIDE) SetEntProp(client, Prop_Send, "m_iPlayerFlags", iFlags & INS_PL_SLIDE);
						// }
					}
				}
			}
			else	// Team Security
			{
				g_iPlayerStance[client] = GetEntProp(client, Prop_Send, "m_iCurrentStance");
				if (g_iPlayerLastKnife[client] != -1)
				{
					// #Resupply Check
					new iKnife = GetPlayerWeaponByName(client, "weapon_kabar");
					if (iKnife > MaxClients && IsValidEdict(iKnife))
						iKnife = EntIndexToEntRef(iKnife);
					else
					{
						iKnife = GivePlayerItem(client, "weapon_kabar");
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
				if (g_fProtectionTime[client] != 0.0 && g_fGameTime-g_fProtectionTime[client] > FCVAR_PLAYER_SPAWN_PROTECTION)
				{
					g_fProtectionTime[client] = 0.0;
					SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
					PrintToChat(client, "\x01(( \x08%s重生保护关闭\x01 ))", COLOR_BLUEVIOLET);
				}
				if (g_iPlayerInfected[client] != 0)
				{
					if (g_fGameTime >= g_fNextInfection[client])
					{
						new iHealth = GetEntProp(client, Prop_Send, "m_iHealth");
						new iInfectDamage = GetRandomInt(CVAR_PLAYER_INFECTION_DAMAGE_MIN, CVAR_PLAYER_INFECTION_DAMAGE_MAX);
						if (g_iPlayerInfected[client] > 0 && g_iPlayerInfected[client] <= MaxClients && IsClientInGame(g_iPlayerInfected[client]))
							Entity_Hurt(client, iInfectDamage, g_iPlayerInfected[client], DMG_SLASH, SCVAR_INFECTION_DAMAGE_CLASSNAME);
						else
							Entity_Hurt(client, iInfectDamage, -1, DMG_SLASH, SCVAR_INFECTION_DAMAGE_CLASSNAME);
						if (iInfectDamage < iHealth)
						{
							new String:sSound[256];
							// FakeClientCommand(client, "say *cough cough*");
							PrintToChat(client, "\x08%s你被感染了！ 使用 \x01医疗包 \x08%s！", COLOR_DARKORANGE, COLOR_DARKORANGE);
							ClientScreenShake(client, SHAKE_START, GetRandomFloat(10.0, 15.0), GetRandomFloat(10.0, 15.0), GetRandomFloat(1.00, 2.00));
							DisplayInstructorHint(client, 5.0, 0.0, 3.0, true, true, "icon_alert", "icon_alert", "", true, {255, 255, 255}, "已被感染！  使用【医疗包】");
							Format(sSound, sizeof(sSound), "Lua_sounds/zombiehorde/survivors/cough%d.wav", GetRandomInt(1, 4));
							EmitSoundToAll(sSound, client, SNDCHAN_VOICE, _, _, 1.0);
							ClientCommand(client, "playgamesound Lua_sounds/zombiehorde/survivors/infection%d.ogg", GetRandomInt(1, 3));
						}
						g_fNextInfection[client] = g_fGameTime+GetRandomFloat(FCVAR_PLAYER_INFECTION_TIMEINTERVAL_MIN, FCVAR_PLAYER_INFECTION_TIMEINTERVAL_MAX);
	//					SDKHooks_TakeDamage(client, -1, -1, iBleedDamage, DMG_DIRECT, -1, NULL_VECTOR, NULL_VECTOR);
					}
				}
				if (g_iPointFlag != INVALID_ENT_REFERENCE && g_iPointFlagOwner == client && g_iSpriteLaser != -1 && g_iPointFlagSpawnGlow != INVALID_ENT_REFERENCE)
				{
					if (g_fRoundTimeLeft > 90.0)
					{
						decl Float:vOrigin[3];
						GetClientAbsOrigin(client, vOrigin);
						vOrigin[2] += 24.0;
						TE_SetupBeamPoints(vOrigin, g_vIntelReturn, g_iSpriteLaser, 0, 0, 0, 0.1, 1.0, 1.0, 0, 0.0, {30, 120, 240, 150}, 0);
						TE_SendToAll();
			//			TE_SendToClient(client);
					}
					else
					{
						LogToGame("Late Intel Captured by %N  (Kill flag %d)", client, g_iPointFlag);
						g_bNoTakingCache = true;
						AcceptEntityInput(g_iPointFlag, "Kill");
						FakeClientCommand(client, "say 情报已获取！ (Under 90s Forced Capture)");
						if (!g_bMedicPlayer[client])
							SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
						g_iPointFlag = INVALID_ENT_REFERENCE;
						g_iPointFlagOwner = -1;
						PlayGameSoundToAll("Player.Security_Infiltration_SecCapturedIntel");
						
						decl Float:vPos[3];
						GetEntPropVector(g_iCPIndex[g_iCurrentControlPoint], Prop_Data, "m_vecAbsOrigin", vPos);
						SetEntData(g_iCPIndex[g_iCurrentControlPoint], g_iOffsetWeaponCacheGlow, 1);
						vPos[2] += 2000.0;
						TeleportEntity(g_iCPIndex[g_iCurrentControlPoint], vPos, NULL_VECTOR, NULL_VECTOR);
						if (g_iPointFlagSpawnGlow != INVALID_ENT_REFERENCE && IsValidEntity(g_iPointFlagSpawnGlow) && EntRefToEntIndex(g_iPointFlagSpawnGlow) > MaxClients)
						{
							AcceptEntityInput(g_iPointFlagSpawnGlow, "Kill");
							g_iPointFlagSpawnGlow = INVALID_ENT_REFERENCE;
						}
					}
				}
			}
		}
	}

	if (g_hCvarAlwaysCounterAttack != INVALID_HANDLE)
	{
		if (g_iNumControlPoints-1 != g_iCurrentControlPoint)
		{
			if (g_iCPType[g_iCurrentControlPoint] != 0)
				SetConVarInt(g_hCvarAlwaysCounterAttack, (GetRandomFloat(0.1, 100.00) <= FCVAR_GAME_COUNTERATTACK_ALWAYS_CHANCE)?1:0);
			else
			{
				new iGlow = IsValidEntity(g_iCPIndex[g_iCurrentControlPoint])&&EntRefToEntIndex(g_iCPIndex[g_iCurrentControlPoint])!=-1?GetEntData(g_iCPIndex[g_iCurrentControlPoint], g_iOffsetWeaponCacheGlow):0;
				if (iGlow == 0 || (iGlow != 0 && g_bNoTakingCache))
					SetConVarInt(g_hCvarAlwaysCounterAttack, (GetRandomFloat(0.1, 100.00) <= FCVAR_GAME_COUNTERATTACK_ALWAYS_CHANCE)?1:0);
				else // Cache has been moved by insurgents do not force to weapon cache counter attack bots only moving to original cp position
					SetConVarInt(g_hCvarAlwaysCounterAttack, 0);
			}
		}
		else SetConVarInt(g_hCvarAlwaysCounterAttack, 1);	// Force to counter on final point
	}
	return;
}

public bool:Filter_Flag(entity, contentsMask, any:flag)
{
//	PrintToChatAll("filter %d, entity %d, In Filter %d", flag, entity, (flag & entity));
	return (flag & entity);
}

public bool:Filter_Not_Players(entity, contentsMask)
{
	return (entity > MaxClients);
}

public bool:Filter_Not_ClientAndEntity(entity, contentsMask, any:client)
{
	if (entity != client && entity != g_iPlayerTempProp[client])
		return true;
	return false;
}

public bool:Filter_Not_PlayersAndEntity(entity, contentsMask, any:client)
{
	if (entity > MaxClients && entity != g_iPlayerTempProp[client])
		return true;
	return false;
}

public Action:Timer_JihadNotice(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_iGameState != 4) return;

	FakeClientCommand(client, "say IED，IED！！！");
	switch(GetRandomInt(0, 5))
	{
		case 0: EmitSoundToAll("player/voice/responses/security/subordinate/suppressed/suppressed11.ogg", client, SNDCHAN_VOICE, _, _, 1.0);
		case 1: EmitSoundToAll("player/voice/responses/security/subordinate/suppressed/suppressed12.ogg", client, SNDCHAN_VOICE, _, _, 1.0);
		case 2: EmitSoundToAll("player/voice/responses/security/subordinate/suppressed/suppressed16.ogg", client, SNDCHAN_VOICE, _, _, 1.0);
		case 3: EmitSoundToAll("player/voice/responses/security/subordinate/suppressed/suppressed17.ogg", client, SNDCHAN_VOICE, _, _, 1.0);
		case 4: EmitSoundToAll("player/voice/responses/security/subordinate/suppressed/suppressed23.ogg", client, SNDCHAN_VOICE, _, _, 1.0);
		case 5: EmitSoundToAll("player/voice/responses/security/subordinate/suppressed/suppressed31.ogg", client, SNDCHAN_VOICE, _, _, 1.0);
	}
}

public Action:Timer_JihadNoticeIEDJammer(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_iGameState != 4) return;

	FakeClientCommand(client, "say IED！！！ (已被IED干扰器干扰)");
	switch(GetRandomInt(0, 5))
	{
		case 0: EmitSoundToAll("player/voice/responses/security/subordinate/suppressed/suppressed11.ogg", client, SNDCHAN_VOICE, _, _, 1.0);
		case 1: EmitSoundToAll("player/voice/responses/security/subordinate/suppressed/suppressed12.ogg", client, SNDCHAN_VOICE, _, _, 1.0);
		case 2: EmitSoundToAll("player/voice/responses/security/subordinate/suppressed/suppressed16.ogg", client, SNDCHAN_VOICE, _, _, 1.0);
		case 3: EmitSoundToAll("player/voice/responses/security/subordinate/suppressed/suppressed17.ogg", client, SNDCHAN_VOICE, _, _, 1.0);
		case 4: EmitSoundToAll("player/voice/responses/security/subordinate/suppressed/suppressed23.ogg", client, SNDCHAN_VOICE, _, _, 1.0);
		case 5: EmitSoundToAll("player/voice/responses/security/subordinate/suppressed/suppressed31.ogg", client, SNDCHAN_VOICE, _, _, 1.0);
	}
}

public Action:Timer_Jihad(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || g_iGameState != 4 || g_iZombieClass[client][VAR] >= -1 || g_iZombieClass[client][CLASS] != ZOMBIE_IED_INDEX || !IsPlayerAlive(client))
	{
		if (g_iZombieClass[client][VAR] < -1) g_iZombieClass[client][VAR] = 0;
		return;
	}

//	new iWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
//	if (iWeapon > MaxClients && IsValidEdict(iWeapon))
	new iModel = -g_iZombieClass[client][VAR];
	if (iModel == 72 || iModel == 73 || iModel == 6666) CreateTimer(0.0, Timer_JihadExplode, client, TIMER_FLAG_NO_MAPCHANGE);
	else CreateTimer(GetRandomFloat(0.2, 0.6), Timer_JihadExplode, client, TIMER_FLAG_NO_MAPCHANGE);
	switch(iModel)
	{
		case 66, 67, 68, 69:	PlayGameSoundToAll("Weapon_M67.SpoonEject");
		case 70:				PlayGameSoundToAll("M18.Detonate");
		case 71:				PlayGameSoundToAll("Molotov.LighterStrike");
		case 72:				PlayGameSoundToAll("Weapon_C4.SecurityDetonator");
		case 73, 6666:			PlayGameSoundToAll("Weapon_C4.InsurgentDetonator");
		case 74, 75:			PlayGameSoundToAll("Weapon_M84.Bounce");
		default:				PlayGameSoundToAll("Weapon_C4.InsurgentDetonator");
	}
/*	if (g_iPlayerStatus[client] == 0 || g_iPlayerStatus[client] & ~STATUS_INIEDJAMMER)
		PrintToChatAll("\x08%s[SUICIDE BOMBER]  \x08%s%N :  \x08%sAllahu akbar!", COLOR_SLATEGRAY, COLOR_INSURGENTS, client, COLOR_SALMON);
	else
		PrintToChatAll("\x08%s[SUICIDE BOMBER]  \x08%s%N :  \x08%sAllahu akbar!  \x01(Delayed by IED Jammer)", COLOR_SLATEGRAY, COLOR_INSURGENTS, client, COLOR_SALMON);	*/
	LogToGame("Zombie \"%N\" has triggered detonate", client);
}

public Action:Timer_JihadExplode(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || g_iGameState != 4 || g_iZombieClass[client][VAR] >= -1)
	{
		if (g_iZombieClass[client][VAR] < -1) g_iZombieClass[client][VAR] = 0;
		return;
	}

	new iExplosive;
	new iModel = -g_iZombieClass[client][VAR];
	g_iZombieClass[client][VAR] = 0;
	switch(iModel)
	{
		case 66: iExplosive = CreateEntityByName("grenade_f1");
		case 67: iExplosive = CreateEntityByName("grenade_m67");
		case 68: iExplosive = CreateEntityByName("grenade_m26a2");
		case 69: iExplosive = CreateEntityByName("grenade_geballteladung");
		case 70: iExplosive = CreateEntityByName("grenade_anm14");
		case 71: iExplosive = CreateEntityByName("grenade_molotov");
		case 72: iExplosive = CreateEntityByName("grenade_c4");
		case 73: iExplosive = CreateEntityByName("grenade_ied");
		case 74: iExplosive = CreateEntityByName("rocket_rpg7");
		case 75: iExplosive = CreateEntityByName("rocket_at");
		case 6666: iExplosive = CreateEntityByName("grenade_badass_ied");
		default: iExplosive = CreateEntityByName("grenade_ied");
	}
	if (g_iZombieClass[client][CLASS] == ZOMBIE_BURNER_INDEX)
	{
		switch(iModel)
		{
			case 66, 67, 68, 69:	PlayGameSoundToAll("Weapon_M67.SpoonEject");
			case 70:				PlayGameSoundToAll("M18.Detonate");
			case 71:				PlayGameSoundToAll("Molotov.LighterStrike");
			case 72:				PlayGameSoundToAll("Weapon_C4.SecurityDetonator");
			case 73, 6666:			PlayGameSoundToAll("Weapon_C4.InsurgentDetonator");
			case 74, 75:			PlayGameSoundToAll("Weapon_M84.Bounce");
			default:				PlayGameSoundToAll("Weapon_C4.InsurgentDetonator");
		}
	}
/*	new iWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (iWeapon > MaxClients && IsValidEntity(iWeapon))
	{
		if (g_iSuicideBombKnifeModel != -1)
			SetEntProp(iWeapon, Prop_Send, "m_iWorldModelIndex", g_iSuicideBombKnifeModel);
		g_fGameTime = GetGameTime();
		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextPrimaryAttack", g_fGameTime);
		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextSecondaryAttack", g_fGameTime);
	}	*/
	if (iExplosive > MaxClients && IsValidEdict(iExplosive))
	{
		LogToGame("Zombie \"%N\" has exploded (%d)", client, iExplosive);
		DispatchSpawn(iExplosive);
		new Float:fOrigin[3];
		GetClientAbsOrigin(client, fOrigin);
		fOrigin[2] += 32.0;
		SetEntPropEnt(iExplosive, Prop_Data, "m_hOwnerEntity", client);
		SetEntProp(iExplosive, Prop_Data, "m_nNextThinkTick", 1);
		SetEntProp(iExplosive, Prop_Data, "m_takedamage", 2);
		SetEntProp(iExplosive, Prop_Data, "m_iHealth", 1);
		TeleportEntity(iExplosive, fOrigin, Float:{0.0, 0.0, 0.0}, Float:{90.0, 0.0, 0.0});
//		SetEntityMoveType(iExplosive, MOVETYPE_NONE);
		if (IsPlayerAlive(client))
		{
			if (iModel != 70 && iModel != 71)
			{
				SetEntProp(client, Prop_Send, "m_iHealth", 10);
				SetVariantString("!activator");
				AcceptEntityInput(iExplosive, "SetParent", client, iExplosive, 0);
				SetVariantString("primary");
				AcceptEntityInput(iExplosive, "SetParentAttachment", iExplosive, iExplosive, 0);
			}
			else
			{
//				ForcePlayerSuicide(client);
				SetEntProp(client, Prop_Send, "m_iHealth", 5);
				IgniteEntity(client, 1.8);
			}
		}
		new iPointHurt = CreateEntityByName("point_hurt");
		if (iPointHurt > MaxClients && IsValidEdict(iPointHurt))
		{
			new String:sDmgType[9];
			IntToString(DMG_BLAST, sDmgType, sizeof(sDmgType));
			DispatchKeyValue(iExplosive, "targetname", "hurtme");
			DispatchKeyValue(iPointHurt, "DamageTarget", "hurtme");
			DispatchKeyValue(iPointHurt, "Damage", "100");
			DispatchKeyValue(iPointHurt, "DamageType", sDmgType);	
			DispatchKeyValue(iPointHurt, "classname", "weapon_c4_ied");
			DispatchSpawn(iPointHurt);
			AcceptEntityInput(iPointHurt, "Hurt", client);
			DispatchKeyValue(iExplosive, "targetname", "donthurtme");
//			AcceptEntityInput(iPointHurt, "Kill");
			// PrintToServer("Removing #7");
			RequestFrame(DeleteEntity, EntIndexToEntRef(iPointHurt));
		}
//		AcceptEntityInput(iExplosive, "Explode");
		if (iModel == 72 || iModel == 73)
		{
			fOrigin[2] -= 26.0;
			new Handle:hData;
			CreateDataTimer(0.65, Timer_JihadIEDEffect, hData, TIMER_FLAG_NO_MAPCHANGE);
			WritePackFloat(hData, fOrigin[0]);
			WritePackFloat(hData, fOrigin[1]);
			WritePackFloat(hData, fOrigin[2]);
		}
		else if (iModel == 6666)
		{
			fOrigin[2] -= 26.0;
			new Handle:hData;
			CreateDataTimer(0.65, Timer_JihadBadassEffect, hData, TIMER_FLAG_NO_MAPCHANGE);
			WritePackFloat(hData, fOrigin[0]);
			WritePackFloat(hData, fOrigin[1]);
			WritePackFloat(hData, fOrigin[2]);
		}
		else if (iModel == 69)
		{
			fOrigin[2] -= 26.0;
			new Handle:hData;
			CreateDataTimer(0.05, Timer_JihadBadassEffect, hData, TIMER_FLAG_NO_MAPCHANGE);
			WritePackFloat(hData, fOrigin[0]);
			WritePackFloat(hData, fOrigin[1]);
			WritePackFloat(hData, fOrigin[2]);
		}
		else if (iModel == 70 || iModel == 71)
		{
			fOrigin[2] -= 26.0;
			new Handle:hData;
			CreateDataTimer(0.2, Timer_FireExplodeEffect, hData, TIMER_FLAG_NO_MAPCHANGE);
			WritePackFloat(hData, fOrigin[0]);
			WritePackFloat(hData, fOrigin[1]);
			WritePackFloat(hData, fOrigin[2]);
		}
	}
}

public Action:Timer_JihadBadassEffect(Handle:timer, Handle:data)
{
	ResetPack(data);
	if (g_iGameState != 4) return;

	new particle = CreateEntityByName("info_particle_system");
	if (particle > MaxClients && IsValidEntity(particle))
	{
		decl Float:fOrigin[3];
		fOrigin[0] = ReadPackFloat(data);
		fOrigin[1] = ReadPackFloat(data);
		fOrigin[2] = ReadPackFloat(data);

		DispatchKeyValue(particle, "classname", "LuaTempParticle");
		DispatchKeyValue(particle, "effect_name", "ins_car_explosion");
		DispatchSpawn(particle);
		AcceptEntityInput(particle, "start");
		ActivateEntity(particle);
		SetVariantString("OnUser1 !self:kill::10.0:1");
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
//		CreateTimer(10.0, DeleteParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
		TeleportEntity(particle, fOrigin, NULL_VECTOR, NULL_VECTOR);
		for (new j = 0;j < MAXPLAYER; j++)
		{
			if (g_iPlayersList[j] == -1) continue;
			new i = g_iPlayersList[j];
			decl Float:distance, Float:targetpos[3];
			GetClientEyePosition(i, targetpos);
			distance = GetVectorDistance(fOrigin, targetpos)*0.01905; // meters
			if (distance <= 25.0)
			{
				new Float:amp = 25.0;
				new Float:fre = 30.0;
				if (distance <= 15.0)
				{
					amp = GetRandomFloat(25.0, 30.0);
					fre = GetRandomFloat(30.0, 35.0);
				}
				else{
					amp = GetRandomFloat(20.0, 25.0);
					fre = GetRandomFloat(30.0, 35.0);
				}
				PlayerYell(i, 3, true, FCVAR_PLAYER_YELL_CHANCE_GRENADE, _, FCVAR_PLAYER_YELL_COOLDOWN_MIN);
				ClientScreenShake(i, SHAKE_START, amp, fre, GetRandomFloat(1.50, 2.00));
			}
		}
	}
}

public Action:Timer_JihadIEDEffect(Handle:timer, Handle:data)
{
	ResetPack(data);
	if (g_iGameState != 4) return;

	decl Float:fOrigin[3];
	fOrigin[0] = ReadPackFloat(data);
	fOrigin[1] = ReadPackFloat(data);
	fOrigin[2] = ReadPackFloat(data);
	for (new j = 0;j < MAXPLAYER; j++)
	{
		if (g_iPlayersList[j] == -1) continue;
		new i = g_iPlayersList[j];
		decl Float:distance, Float:targetpos[3];
		GetClientEyePosition(i, targetpos);
		distance = GetVectorDistance(fOrigin, targetpos)*0.01905; // meters
		if (distance <= 25.0)
		{
			new Float:amp = 25.0;
			new Float:fre = 30.0;
			if (distance <= 15.0)
			{
				amp = GetRandomFloat(25.0, 30.0);
				fre = GetRandomFloat(30.0, 35.0);
			}
			else{
				amp = GetRandomFloat(20.0, 25.0);
				fre = GetRandomFloat(30.0, 35.0);
			}
			PlayerYell(i, 3, true, FCVAR_PLAYER_YELL_CHANCE_GRENADE, _, FCVAR_PLAYER_YELL_COOLDOWN_MIN);
			ClientScreenShake(i, SHAKE_START, amp, fre, GetRandomFloat(1.50, 2.00));
		}
	}
}

public Action:Timer_FireExplodeEffect(Handle:timer, Handle:data)
{
	ResetPack(data);
	if (g_iGameState != 4) return;

	new particle = CreateEntityByName("info_particle_system");
	if (particle > MaxClients && IsValidEntity(particle))
	{
		decl Float:fOrigin[3];
		fOrigin[0] = ReadPackFloat(data);
		fOrigin[1] = ReadPackFloat(data);
		fOrigin[2] = ReadPackFloat(data);

		DispatchKeyValue(particle, "classname", "LuaTempParticle");
		DispatchKeyValue(particle, "effect_name", "ins_grenade_explosion");
		DispatchSpawn(particle);
		AcceptEntityInput(particle, "start");
		ActivateEntity(particle);
		SetVariantString("OnUser1 !self:kill::3.0:1");
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
//		CreateTimer(3.0, DeleteParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
		TeleportEntity(particle, fOrigin, NULL_VECTOR, NULL_VECTOR);
		for (new j = 0;j < MAXPLAYER; j++)
		{
			if (g_iPlayersList[j] == -1) continue;
			new i = g_iPlayersList[j];
			decl Float:distance, Float:targetpos[3];
			GetClientEyePosition(i, targetpos);
			distance = GetVectorDistance(fOrigin, targetpos)*0.01905; // meters
			if (distance <= 15.0)
			{
				new Float:amp = 25.0;
				new Float:fre = 30.0;
				amp = GetRandomFloat(15.0, 20.0);
				fre = GetRandomFloat(25.0, 30.0);
				PlayerYell(i, 3, true, FCVAR_PLAYER_YELL_CHANCE_GRENADE, _, FCVAR_PLAYER_YELL_COOLDOWN_MIN);
				ClientScreenShake(i, SHAKE_START, amp, fre, GetRandomFloat(1.50, 2.00));
			}
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (g_fGameTime >= g_fLastEdictCheck && g_iGameState == 4)
	{
		CheckAllEntity();
		if (g_iEntityCount < 1800)
			g_fLastEdictCheck = g_fGameTime+10.0;
		else
			g_fLastEdictCheck = g_fGameTime+2.0;
	}
}
/*
public OnEntityDestroyed(entity)
{
	LogToGame("Entity (%d) has been removed", entity);
}
*/

stock CheckAllEntity()
{
	g_iEntityCount = 0;
	for (new i = 1;i < GetMaxEntities();i++)
	{
		if (i != INVALID_ENT_REFERENCE && IsValidEdict(i))
		{
			g_iEntityCount++;
/*			if (i > MaxClients)
			{
				decl String:sClassName[64];
				GetEntityClassname(i, sClassName, sizeof(sClassName));
				if (StrContains(sClassName, "weapon_", false) != -1 && !StrEqual(sClassName, "weapon_kabar", false) && StrContains(sClassName, "obj_", false) == -1)
				{
					if (GetEntProp(i, Prop_Send, "m_iState") == 0)
					{
						new iOwner = GetEntProp(i, Prop_Send, "m_hOwnerEntity"), bool:bNoOwner = true;
						if (iOwner != -1)
						{
							if (iOwner < -1) iOwner = EntRefToEntIndex(iOwner);
							for (new client = 1;client <= MaxClients;client++)
							{
								if (!IsClientInGame(client) || !IsPlayerAlive(client)) continue;
								if (client == iOwner)
								{
									new bool:bHaveWeapon = false;
									for (new z = 0;z < 48;z++)
									{
										new weapon = GetEntDataEnt2(client, g_iOffsetMyWeapons+(4*z));
										if (weapon == -1) break;

										if (!IsValidEntity(weapon) || weapon <= MaxClients)
											continue;
										
										if (weapon == i)
										{
											bHaveWeapon = true;
											break;
										}
									}
									if (bHaveWeapon)
									{
										bNoOwner = false;
										LogToGame("Dropped weapon \"%s\" (%d) found but has owner %N", sClassName, i, client);
									}
									break;
								}
							}
						}
						if (bNoOwner)
						{
							// PrintToServer("Removing #8");
							g_iEntityCount--;
							LogToGame("Dropped weapon \"%s\" (%d) removed", sClassName, i);
							RequestFrame(DeleteEntity, EntIndexToEntRef(i));
//								AcceptEntityInput(i, "Kill");
						}
					}
				}
			}	*/
		}
	}
	LogToGame("Spawned Entities Count : %d", g_iEntityCount);
//	LogMessage("Spawned Entities Count : %d", g_iEntityCount);

	if (g_iEntityCount >= 1950 && g_iRemoveProps < 1)
	{
		new iCount = 0;
		if (g_iRemoveProps == -1)
		{
			LogError("Starting To Entity Remove Count at %d Type 0", g_iEntityCount);
			LogToGame("Starting To Entity Remove Count at %d Type 0", g_iEntityCount);
			for (new i = MaxClients+1;i < GetMaxEntities();i++)
			{
				if (IsValidEntity(i))
				{
					if (FindDataMapInfo(i, "m_ModelName") != -1)
					{
						new String:sClassName[64], bool:bRemove = false;
						GetEntityClassname(i, sClassName, sizeof(sClassName));
						if (StrEqual(sClassName, "env_sprite", false)) bRemove = true;
						else if (StrEqual(sClassName, "beam", false)) bRemove = true;
						else if (StrEqual(sClassName, "spotlight_end", false)) bRemove = true;
						else if (StrEqual(sClassName, "point_spotlight", false)) bRemove = true;
						if (bRemove)
						{
	//						LogToGame("%d. %s", i, sClassName);
							RemoveEdict(i);
							iCount++;
						}
					}
				}
			}
			g_iRemoveProps = 0;
			PrintToChatAll("\x08%sMAX ENTITY WARNING   \x01Entity has been removed \x04(%d)", COLOR_PURPLE, iCount);
			PrintToChatAll("\x08%sMAX ENTITY WARNING   \x01Entity has been removed \x04(%d)", COLOR_PURPLE, iCount);
			PrintToChatAll("\x08%sMAX ENTITY WARNING   \x01Entity has been removed \x04(%d)", COLOR_PURPLE, iCount);
		}
		else
		{
			LogError("Starting To Entity Remove Count at %d Type 1", g_iEntityCount);
			LogToGame("Starting To Entity Remove Count at %d Type 1", g_iEntityCount);
			for (new i = MaxClients+1;i < GetMaxEntities();i++)
			{
				if (IsValidEntity(i))
				{
					if (FindDataMapInfo(i, "m_ModelName") != -1)
					{
						new String:sClassName[64], bool:bRemove = false;
						GetEntityClassname(i, sClassName, sizeof(sClassName));
						if (StrContains(sClassName, "prop_", false) != -1) bRemove = true;
						else if (StrEqual(sClassName, "ins_blockzone", false)) bRemove = true;
						if (bRemove)
						{
							if (FindDataMapInfo(i, "m_iName") != -1)
							{
								decl String:targetname[64];
								GetEntPropString(i, Prop_Data, "m_iName", targetname, sizeof(targetname));
								if (StrContains(targetname, "LuaCustom", true) != -1)
									continue;
							}
							new String:sModelPath[128];
							GetEntPropString(i, Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
							if (StrContains(sModelPath, ".mdl", false) != -1)
							{
	//							LogToGame("%d. %s [%s]", i, sClassName, sModelPath);
								RemoveEdict(i);
								iCount++;
							}
						}
					}
				}
			}
			g_iRemoveProps = 1;
			PrintToChatAll("\x08%sMAX ENTITY WARNING   \x01Entity has been removed \x04(%d)", COLOR_PURPLE, iCount);
			PrintToChatAll("\x08%sMAX ENTITY WARNING   \x01Entity has been removed \x04(%d)", COLOR_PURPLE, iCount);
			PrintToChatAll("\x08%sMAX ENTITY WARNING   \x01Entity has been removed \x04(%d)", COLOR_PURPLE, iCount);
		}
		LogError("Entity Removed Count %d (Seq %d)/Total %d (was %d)", iCount, g_iRemoveProps, g_iEntityCount-iCount, g_iEntityCount);
		LogToGame("Entity Removed Count %d (Seq %d)/Total %d (was %d)", iCount, g_iRemoveProps, g_iEntityCount-iCount, g_iEntityCount);
		g_iEntityCount -= iCount;
	//	PrintToChatAll("Removed Count %d (%d+%d)/Total %d", iCount+iCount2, iCount, iCount2, iTotalCount);
	}
	else if (g_iRemoveProps == 1)
	{
		LogError("!!!!! EDICT WARNING [%d/2048] - MAP: %s", g_iEntityCount, g_sCurrentMap);
		LogToGame("!!!!! EDICT WARNING [%d/2048] - MAP: %s", g_iEntityCount, g_sCurrentMap);
		PrintToChatAll("\x01[%d/1950] \x08%sMAX ENTITY SPAWN WARNING, changing map to default map", g_iEntityCount, COLOR_PURPLE);
		PrintToChatAll("\x01[%d/1950] \x08%sMAX ENTITY SPAWN WARNING, changing map to default map", g_iEntityCount, COLOR_PURPLE);
		PrintToChatAll("\x01[%d/1950] \x08%sMAX ENTITY SPAWN WARNING, changing map to default map", g_iEntityCount, COLOR_PURPLE);
		PrintToChatAll("\x01[%d/1950] \x08%sMAX ENTITY SPAWN WARNING, changing map to default map", g_iEntityCount, COLOR_PURPLE);
		g_fLastEdictCheck = GetGameTime()+10.0;
		CreateTimer(3.0, Timer_MapChange, _, TIMER_FLAG_NO_MAPCHANGE);
	}
/*		if (g_iEntityCount >= 1900 && g_iEntityCount < 1950)
		PrintToChatAll("\x01[%d/1950] \x08%sMAX ENTITY SPAWN WARNING", g_iEntityCount, COLOR_PURPLE);
	if (g_iEntityCount >= 1950)
	{
	}	*/
}

public Action:Timer_MapChange(Handle:timer)
	ServerCommand("map ministry_coop checkpoint");

public Action:SHook_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
/*	if (GetClientTeam(victim) == TEAM_SURVIVORS)
	{
		if (GetClientTeam(attacker) == TEAM_SURVIVORS)
		{
			if (IsFakeClient(victim) || IsFakeClient(attacker))
			{
				damage = 0.0;
				return Plugin_Handled;
			}
		}
	}	*/
	g_iLastHitgroup[victim] = hitgroup;
	return Plugin_Continue;
}

public Action:SHook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (g_iGameState < 4 || !g_bUpdatedSpawnPoint)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	new bool:bChanged = false;
	new vTeam = GetClientTeam(victim);
	new aTeam = (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) ? GetClientTeam(attacker) : -1);
	if (DEBUGGING_ENABLED > 1)
		LogToGame("[DEBUG] %N (%d left) - dmg: %0.2f, dmgtype: %d, attacker: %d, inflictor: %d, weapon: %d, damageForce: {%0.3f, %0.3f, %0.3f}, damagePosition: {%0.3f, %0.3f, %0.3f}", victim, GetClientHealth(victim), damage, damagetype, attacker, inflictor, weapon, damageForce[0], damageForce[1], damageForce[2], damagePosition[0], damagePosition[1], damagePosition[2]);

	if (damagetype & DMG_BURN)
	{
		if (g_iZombieClass[victim][CLASS] == ZOMBIE_BURNER_INDEX)
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		if (RoundToNearest(damage) < GetEntProp(victim, Prop_Send, "m_iHealth"))
		{
			new bool:bSkip = false;
			if (weapon == -1 && inflictor > MaxClients && attacker > MaxClients && inflictor == attacker && IsValidEntity(attacker))
			{
				decl String:sClassName[32];
				GetEntityClassname(attacker, sClassName, 32);
				if (StrEqual(sClassName, "entityflame", true))
				{
					bSkip = true;
					if (vTeam == TEAM_SURVIVORS) PlayerYell(victim, 10, false, 100.00, _, 1.5);
					else
					{
						damage = FCVAR_ZOMBIE_BURN_DAMAGE;
						bChanged = true;
					}
				}
			}
			if (!bSkip && GetRandomFloat(0.1, 100.00) <= FCVAR_PLAYER_BURN_CHANCE_FIRE)
			{
				if (vTeam == TEAM_SURVIVORS && g_fBurnTime[victim] <= g_fGameTime)
				{
					DisplayInstructorHint(victim, 5.0, 0.0, 3.0, true, true, "icon_fire", "icon_fire", "", true, {255, 255, 255}, "着火了！快[趴下]！");
					decl String:sSoundFile[128];
					if (!IsLightModel(victim))
						Format(sSoundFile, sizeof(sSoundFile), "player/voice/responses/security/subordinate/damage/molotov_incendiary_detonated%d.ogg", GetRandomInt(6, 7));
					else
						Format(sSoundFile, sizeof(sSoundFile), "player/voice/responses/security/leader/damage/molotov_incendiary_detonated%d.ogg", GetRandomInt(4, 5));
					EmitSoundToAll(sSoundFile, victim, SNDCHAN_STATIC, _, _, 1.0);
					PrintToChat(victim, "\x08%s你着火了！ \x01按 \x08%s趴下 \x01来熄灭火焰！", COLOR_DARKORANGE, COLOR_DARKORANGE);
				}
				if (vTeam == TEAM_ZOMBIES) g_iPlayerBleeding[victim] = 0;
				g_iBurnedBy[victim] = attacker;
				g_fBurnTime[victim] = g_fGameTime+(vTeam==TEAM_SURVIVORS?GetRandomFloat(FCVAR_PLAYER_BURN_MIN_TIME, FCVAR_PLAYER_BURN_MAX_TIME):GetRandomFloat(FCVAR_ZOMBIE_BURN_MIN_TIME, FCVAR_ZOMBIE_BURN_MAX_TIME));
				ZombieBurnSound(victim, true);
	//			new iFlags = GetEntityFlags(victim);
	//			if (!(iFlags&FL_ONFIRE)) IgniteEntity(victim, 1.0);
			}
		}
	}
	else if (damagetype & DMG_BLAST && damage >= 20.0)
	{
		if (g_iZombieClass[victim][CLASS] != ZOMBIE_BURNER_INDEX && GetRandomFloat(0.1, 100.00) <= FCVAR_PLAYER_BURN_CHANCE_EXPLOSIVE)
		{
			if (RoundToNearest(damage) < GetEntProp(victim, Prop_Send, "m_iHealth"))
			{
				if (vTeam == TEAM_SURVIVORS && g_fBurnTime[victim] <= g_fGameTime)
				{
					DisplayInstructorHint(victim, 5.0, 0.0, 3.0, true, true, "icon_fire", "icon_fire", "", true, {255, 255, 255}, "着火了！快[趴下]！");
					decl String:sSoundFile[128];
					if (!IsLightModel(victim))
						Format(sSoundFile, sizeof(sSoundFile), "player/voice/responses/security/subordinate/damage/molotov_incendiary_detonated%d.ogg", GetRandomInt(6, 7));
					else
						Format(sSoundFile, sizeof(sSoundFile), "player/voice/responses/security/leader/damage/molotov_incendiary_detonated%d.ogg", GetRandomInt(4, 5));
					EmitSoundToAll(sSoundFile, victim, SNDCHAN_STATIC, _, _, 1.0);
					PrintToChat(victim, "\x08%s你着火了！ \x01按 \x08%s趴下 \x01来熄灭火焰！", COLOR_DARKORANGE, COLOR_DARKORANGE);
				}
				if (vTeam == TEAM_ZOMBIES) g_iPlayerBleeding[victim] = 0;
				g_iBurnedBy[victim] = attacker;
				g_fBurnTime[victim] = g_fGameTime+(vTeam==TEAM_SURVIVORS?GetRandomFloat(FCVAR_PLAYER_BURN_MIN_TIME, FCVAR_PLAYER_BURN_MAX_TIME):GetRandomFloat(FCVAR_ZOMBIE_BURN_MIN_TIME, FCVAR_ZOMBIE_BURN_MAX_TIME));
				ZombieBurnSound(victim, true);
	//			new iFlags = GetEntityFlags(victim);
	//			if (!(iFlags&FL_ONFIRE)) IgniteEntity(victim, 1.0);
			}
		}
	}
	new bBleeding = false;
	if (g_iPlayerBleeding[victim] == 0)
	{
		if (aTeam != vTeam && g_iZombieClass[victim][CLASS] != ZOMBIE_BURNER_INDEX)
		{
			if (vTeam == TEAM_SURVIVORS || (vTeam == TEAM_ZOMBIES && g_iZombieBurnSound[victim] == 0))
			{
				if (damagetype & DMG_BULLET)
				{
					if (GetRandomFloat(0.1, 100.00) <= FCVAR_PLAYER_BLEEDING_BULLET_CHANCE)
						bBleeding = true;
				}
				else if (damagetype & DMG_BLAST)
				{
//					if (GetRandomFloat(0.1, 100.00) <= FCVAR_PLAYER_BLEEDING_EXPLOSIVE_CHANCE)
					if (GetRandomFloat(0.1, 100.00) <= damage/3.0)
						bBleeding = true;
				}
				else if (damagetype & DMG_SLASH)
				{
//					if (GetRandomFloat(0.1, 100.00) <= FCVAR_PLAYER_BLEEDING_EXPLOSIVE_CHANCE)
					if (GetRandomFloat(0.1, 100.00) <= damage/3.0)
						bBleeding = true;
				}

				if (bBleeding)
				{
					CreateTimer(0.1, Timer_NoticeBleeding, victim, TIMER_FLAG_NO_MAPCHANGE);
					g_iPlayerBleeding[victim] = attacker;
					g_fPlayerBleedTime[victim] = GetGameTime()+(vTeam==TEAM_SURVIVORS?GetRandomFloat(FCVAR_PLAYER_BLEEDING_INTERVAL_MIN, FCVAR_PLAYER_BLEEDING_INTERVAL_MAX):GetRandomFloat(FCVAR_ZOMBIE_BLEEDING_MIN_TIME, FCVAR_ZOMBIE_BLEEDING_MAX_TIME));
				}
			}
		}
	}
	if (vTeam == TEAM_ZOMBIES)
	{
		if (damagetype & DMG_FALL)
		{
			if (damage > 100.0)
			{
				damage = 100.0;
				return Plugin_Changed;
			}
		}
		if (damagetype & DMG_SLASH && weapon > MaxClients)
		{
			if (damage <= 259.0)
			{
				bChanged = true;
				if (g_iLastHitgroup[victim] != 1)
					damage *= GetRandomFloat(0.5, 2.0);
				else damage *= GetRandomFloat(3.0, 5.0);
			}
		}
		if (aTeam == TEAM_SURVIVORS)
		{
			if (damagetype & DMG_BULLET)
			{
				if (g_iZombieClass[victim][VAR] != 1) DamageOnClientKnockBack(victim, attacker, damage/1.5);
				switch(g_iLastHitgroup[victim])
				{
					case 1:	// Head
					{
						damage *= 4.0;
						bChanged = true;
					}

					default:
					{
						damage *= 3.0;
						bChanged = true;
					}
				}
			}
			else if (damagetype & DMG_BURN || damagetype & DMG_BLAST)
			{
				if (g_fGameTime < g_fSpawnTime[victim]+FCVAR_BOT_SPAWN_EXP_BURN_NO_DAMAGE_TIME)
				{
					damage = 0.0;
					return Plugin_Changed;
				}
				else
				{
					bChanged = true;
/*					if (damagetype & DMG_BURN)
						damage *= 3.0;
					else	*/
					if (damagetype & DMG_BLAST) damage *= GetRandomFloat(1.5, 4.5);
				}
			}
		}
		else if (aTeam == TEAM_ZOMBIES)
		{
			if (damagetype & DMG_SLASH)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
/*		new String:sWeaponName[64] = "none";
		new String:sWeaponShortName[32] = "None";
		if (weapon > MaxClients)
		{
			GetEntityClassname(weapon, sWeaponName, 32);
			Format(sWeaponShortName, sizeof(sWeaponShortName), "%s", sWeaponName);
			ReplaceString(sWeaponShortName, sizeof(sWeaponShortName), "weapon_", "", false);
		}	*/
		
/*		if (g_iLastHitgroup[victim] == 1)
		{
			if (g_iPlayerHasHelmet[victim] != INVALID_ENT_REFERENCE)
			{
				if (g_iPlayerHasHelmet[victim] <= 2)	// Ins (1), US (2) helmet
				{
					bChanged = true;
					damage *= 0.4;
				}
				else if (g_iPlayerHasHelmet[victim] == 3)	// K6-3 helmet
				{
					bChanged = true;
					damage *= 0.1;
				}
				AcceptEntityInput(g_iPlayerHasHelmet[victim], "ClearParent");
				SetVariantString("OnUser1 !self:kill::10.0:1");
				AcceptEntityInput(g_iPlayerHasHelmet[victim], "AddOutput");
				AcceptEntityInput(g_iPlayerHasHelmet[victim], "FireUser1");
				TeleportEntity(g_iPlayerHasHelmet[victim], NULL_VECTOR, NULL_VECTOR, damageForce);
				g_iPlayerHasHelmet[victim] = INVALID_ENT_REFERENCE;
			}
		}		*/
		if (g_iZombieClass[victim][CLASS] == ZOMBIE_IED_INDEX)
		{
			new bool:bDetonate = false;
			if (aTeam == TEAM_SURVIVORS && (g_iPlayerStatus[victim] & ~STATUS_INIEDJAMMER))
			{
				if (damagetype & DMG_BULLET && (g_iLastHitgroup[victim] == 2 || g_iLastHitgroup[victim] == 3))
				{
					new iHP = GetEntProp(victim, Prop_Send, "m_iHealth");
					if (damage < float(iHP-1))
					{
						if (GetRandomFloat(0.1, 100.00) <= FCVAR_ZOMBIE_IED_HURT_BULLET_DETONATE_CHANCE)
							bDetonate = true;
					}
				}
				else if (damagetype & DMG_BLAST)
				{
					if (GetRandomFloat(0.1, 100.00) <= FCVAR_ZOMBIE_IED_HURT_EXPLOSIVE_DETONATE_CHANCE)
						bDetonate = true;
				}
				else if (damagetype & DMG_BURN)
				{
					if (GetRandomFloat(0.1, 100.00) <= FCVAR_ZOMBIE_IED_HURT_BURN_DETONATE_CHANCE)
						bDetonate = true;
				}
			}
			if (bDetonate)
			{
				switch(g_iZombieClass[victim][VAR])
				{
					case 66, 67, 68, 69:	PlayGameSoundToAll("Weapon_M67.SpoonEject");
					case 70:				PlayGameSoundToAll("M18.Detonate");
					case 71:				PlayGameSoundToAll("Molotov.LighterStrike");
					case 72:				PlayGameSoundToAll("Weapon_C4.SecurityDetonator");
					case 73, 6666:			PlayGameSoundToAll("Weapon_C4.InsurgentDetonator");
					case 74, 75:			PlayGameSoundToAll("Weapon_M84.Bounce");
					default:				PlayGameSoundToAll("Weapon_C4.InsurgentDetonator");
				}
				g_iZombieClass[victim][VAR] = -g_iZombieClass[victim][VAR];
				CreateTimer(0.0, Timer_JihadExplode, victim, TIMER_FLAG_NO_MAPCHANGE);
				if (IsPlayerAlive(attacker))
					FakeClientCommand(attacker, "say IED爆炸了！");
				else
					PrintToChatAll("\x08%sIED被 \x01 \x08%s%N引爆了", COLOR_INSURGENTS, GetPlayerChatColor(attacker), attacker);
			}
		}
		else if (g_iZombieClass[victim][CLASS] == ZOMBIE_BURNER_INDEX)
		{
			if (aTeam == TEAM_SURVIVORS && damagetype & DMG_BULLET && (g_iLastHitgroup[victim] == 2 || g_iLastHitgroup[victim] == 3))
			{
				if (GetRandomFloat(0.00, 100.00) <= FCVAR_ZOMBIE_BURNER_HURT_BULLET_DETONATE_CHANCE)
				{
					switch(GetRandomInt(0, 3))
					{
						case 1:
						{
							PlayGameSoundToAll("M18.Detonate");
							g_iZombieClass[victim][VAR] = -70;
						}
						default:
						{
							PlayGameSoundToAll("Molotov.LighterStrike");
							g_iZombieClass[victim][VAR] = -71;
						}
					}
					CreateTimer(0.0, Timer_JihadExplode, victim, TIMER_FLAG_NO_MAPCHANGE);
					if (IsPlayerAlive(attacker)) FakeClientCommand(attacker, "say 燃烧僵尸爆炸了！");
				}
			}
		}
	}
	else if (vTeam == TEAM_SURVIVORS)
	{
//		if (g_bAlone && !g_bCounterAttack && GetEntProp(victim, Prop_Data, "m_takedamage") == 2 && g_iGameState == 4)
		if (g_bAlone && GetEntProp(victim, Prop_Data, "m_takedamage") == 2 && g_iGameState == 4)
		{
			new iHP = GetEntProp(victim, Prop_Send, "m_iHealth");
			if (damage >= iHP)
			{
				if (g_iReinforcementPlayerCount < CVAR_PLAYER_REINFORCEMENT_MAX_PER_POINT)
				{
					g_iReinforcementPlayerCount += 2;
					damage = 0.0;
					RespawnPlayer(victim, 0);
					if (g_iReinforcementPlayerCount >= CVAR_PLAYER_REINFORCEMENT_MAX_PER_POINT)
					{
						g_bReinforcementPlayerEnd = true;
						CreateTimer(3.0, Timer_SecurityOutOfReinforcements);
					}

					g_iLastHitgroup[victim] = 1;
					g_iPlayerBleeding[victim] = 0;
					g_iPlayerInfected[victim] = 0;
					new Handle:deathevent = CreateEvent("player_death", true);
					SetEventInt(deathevent, "userid", GetClientUserId(victim));
					SetEventInt(deathevent, "attacker", (aTeam != -1)?GetClientUserId(attacker):attacker);
					SetEventInt(deathevent, "attackerteam", (aTeam != -1)?aTeam:0);
					SetEventInt(deathevent, "weaponid", -1);
					SetEventInt(deathevent, "team", vTeam);
//					SetEventString(deathevent, "weapon", "Knock out);
					FireEvent(deathevent, false);
					return Plugin_Changed;
				}
			}
		}
		if (aTeam == TEAM_ZOMBIES)
		{
			if (g_iPlayerInfected[victim] == 0 && !bBleeding)
			{
				if (g_iZombieClass[attacker][CLASS] != ZOMBIE_BURNER_INDEX)
				{
					if (GetRandomFloat(0.1, 100.00) <= FCVAR_PLAYER_INFECTION_CHANCE)
					{
						CreateTimer(0.1, Timer_NoticeInfected, victim, TIMER_FLAG_NO_MAPCHANGE);
						g_iPlayerInfected[victim] = attacker;
						g_fNextInfection[victim] = GetGameTime()+GetRandomFloat(FCVAR_PLAYER_INFECTION_TIMEINTERVAL_MIN, FCVAR_PLAYER_INFECTION_TIMEINTERVAL_MAX);
					}
				}
			}
			if (damagetype & DMG_SLASH && g_iZombieClass[attacker][CLASS] > -1 && weapon > MaxClients)
			{
				new bool:bIsBackattack = (damage <= 259.0 ? false : true);
				if (g_iZombieClass[attacker][CLASS] == ZOMBIE_COMMON_INDEX || g_iZombieClass[attacker][CLASS] == ZOMBIE_CLASSIC_INDEX)
				{
					if (!bIsBackattack)
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_COMMON_DAMAGE_MIN, FCVAR_ZOMBIE_COMMON_DAMAGE_MAX);
					}
					else
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_COMMON_DAMAGE_BACKATTACK_MIN, FCVAR_ZOMBIE_COMMON_DAMAGE_BACKATTACK_MAX);
					}
					switch(g_iPlayerArmor[victim])
					{
						case 1: damage *= 1.25;
						case 3: return Plugin_Changed;
						default: damage *= 1.5;
					}
					return Plugin_Changed;
				}
/*				else if (g_iZombieClass[attacker][CLASS] == ZOMBIE_BLINKER_INDEX)
				{
					if (!bIsBackattack)
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_BLINKER_DAMAGE_MIN, FCVAR_ZOMBIE_BLINKER_DAMAGE_MAX);
					}
					else
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_BLINKER_DAMAGE_BACKATTACK_MIN, FCVAR_ZOMBIE_BLINKER_DAMAGE_BACKATTACK_MAX);
					}
					return Plugin_Changed;
				}	*/
				else if (g_iZombieClass[attacker][CLASS] == ZOMBIE_KNIGHT_INDEX)
				{
					if (!bIsBackattack)
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_KNIGHT_DAMAGE_MIN, FCVAR_ZOMBIE_KNIGHT_DAMAGE_MAX);
					}
					else
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_KNIGHT_DAMAGE_BACKATTACK_MIN, FCVAR_ZOMBIE_KNIGHT_DAMAGE_BACKATTACK_MAX);
					}
					switch(g_iPlayerArmor[victim])
					{
						case 1: damage *= 1.25;
						case 3: return Plugin_Changed;
						default: damage *= 1.5;
					}
					return Plugin_Changed;
				}
				else if (g_iZombieClass[attacker][CLASS] == ZOMBIE_STALKER_INDEX)
				{
					if (!bIsBackattack)
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_STALKER_DAMAGE_MIN, FCVAR_ZOMBIE_STALKER_DAMAGE_MAX);
					}
					else
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_STALKER_DAMAGE_BACKATTACK_MIN, FCVAR_ZOMBIE_STALKER_DAMAGE_BACKATTACK_MAX);
					}
					switch(g_iPlayerArmor[victim])
					{
						case 1: damage *= 1.25;
						case 3: return Plugin_Changed;
						default: damage *= 1.5;
					}
					return Plugin_Changed;
				}
				else if (g_iZombieClass[attacker][CLASS] == ZOMBIE_BURNER_INDEX)
				{
					if (GetEntData(victim, g_iOffsetWaterlevel) < 2)
					{
						if (FCVAR_ZOMBIE_BURNER_ATTACK_BURN_CHANCE >= GetRandomFloat(0.1, 100.000))
						{
							decl String:sSoundFile[128];
							if (vTeam == TEAM_SURVIVORS && g_fBurnTime[victim] <= g_fGameTime)
							{
								DisplayInstructorHint(victim, 5.0, 0.0, 3.0, true, true, "icon_fire", "icon_fire", "", true, {255, 255, 255}, "着火了！快[趴下]！");
								if (!IsLightModel(victim))
									Format(sSoundFile, sizeof(sSoundFile), "player/voice/responses/security/subordinate/damage/molotov_incendiary_detonated%d.ogg", GetRandomInt(6, 7));
								else
									Format(sSoundFile, sizeof(sSoundFile), "player/voice/responses/security/leader/damage/molotov_incendiary_detonated%d.ogg", GetRandomInt(4, 5));
								EmitSoundToAll(sSoundFile, victim, SNDCHAN_STATIC, _, _, 1.0);
								PrintToChat(victim, "\x08%s你着火了！ \x01按 \x08%s趴下 \x01来熄灭火焰！", COLOR_DARKORANGE, COLOR_DARKORANGE);
							}
							g_iBurnedBy[victim] = attacker;
							g_fBurnTime[victim] = g_fGameTime+GetRandomFloat(FCVAR_ZOMBIE_BURNER_ATTACK_BURN_TIME_MIN, FCVAR_ZOMBIE_BURNER_ATTACK_BURN_TIME_MAX);
							Format(sSoundFile, sizeof(sSoundFile), "Lua_sounds/zombiehorde/zombies/classic/zo_attack%d.wav", GetRandomInt(1, 2));
							EmitSoundToAll(sSoundFile, attacker, SNDCHAN_VOICE, _, _, 1.0);
						}
					}
					if (!bIsBackattack)
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_BURNER_DAMAGE_MIN, FCVAR_ZOMBIE_BURNER_DAMAGE_MAX);
					}
					else
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_BURNER_DAMAGE_BACKATTACK_MIN, FCVAR_ZOMBIE_BURNER_DAMAGE_BACKATTACK_MAX);
					}
					switch(g_iPlayerArmor[victim])
					{
						case 1: damage *= 1.25;
						case 3: return Plugin_Changed;
						default: damage *= 1.5;
					}
					return Plugin_Changed;
				}
				else if (g_iZombieClass[attacker][CLASS] == ZOMBIE_SMOKER_INDEX)
				{
					if (!bIsBackattack)
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_SMOKER_DAMAGE_MIN, FCVAR_ZOMBIE_SMOKER_DAMAGE_MAX);
					}
					else
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_SMOKER_DAMAGE_BACKATTACK_MIN, FCVAR_ZOMBIE_SMOKER_DAMAGE_BACKATTACK_MAX);
					}
					switch(g_iPlayerArmor[victim])
					{
						case 1: damage *= 1.25;
						case 3: return Plugin_Changed;
						default: damage *= 1.5;
					}
					return Plugin_Changed;
				}
				else if (g_iZombieClass[attacker][CLASS] == ZOMBIE_IED_INDEX)
				{
					if (!bIsBackattack)
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_IED_DAMAGE_MIN, FCVAR_ZOMBIE_IED_DAMAGE_MAX);
					}
					else
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_IED_DAMAGE_BACKATTACK_MIN, FCVAR_ZOMBIE_IED_DAMAGE_BACKATTACK_MAX);
					}
					switch(g_iPlayerArmor[victim])
					{
						case 1: damage *= 1.25;
						case 3: return Plugin_Changed;
						default: damage *= 1.5;
					}
					return Plugin_Changed;
				}
				else if (g_iZombieClass[attacker][CLASS] == ZOMBIE_LEAPER_INDEX)
				{
					if (!bIsBackattack)
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_LEAPER_DAMAGE_MIN, FCVAR_ZOMBIE_LEAPER_DAMAGE_MAX);
					}
					else
					{
						damage = GetRandomFloat(FCVAR_ZOMBIE_LEAPER_DAMAGE_BACKATTACK_MIN, FCVAR_ZOMBIE_LEAPER_DAMAGE_BACKATTACK_MAX);
					}
					switch(g_iPlayerArmor[victim])
					{
						case 1: damage *= 1.25;
						case 3: return Plugin_Changed;
						default: damage *= 1.5;
					}
					return Plugin_Changed;
				}
			}
/*			if (damagetype & DMG_BULLET && g_iLastHitgroup[victim] != 1)
			{
				bChanged = true;
				if (damage < 110.1)
					damage *= GetRandomFloat(0.25, 0.50);
				else
					damage *= GetRandomFloat(0.15, 0.40);
			}		*/
		}
		else
		{
			if (attacker != victim && aTeam == TEAM_SURVIVORS)
			{
				if (damagetype & ~DMG_BURN)
				{
					LogToGame("%N has attacked by teammate (%N) | Hitgroup: %d, Damage: %0.1f", victim, attacker, g_iLastHitgroup[victim], damage);
					LogMessage("%N has attacked by teammate (%N) | Hitgroup: %d, Damage: %0.1f", victim, attacker, g_iLastHitgroup[victim], damage);
					if (damagetype & DMG_BULLET && !IsFakeClient(attacker))
					{
						new Float:vAngle[3];
						if (GetRandomInt(0, 1) == 0)
							vAngle[0] = GetRandomFloat(-15.0, -20.0);
						else
							vAngle[0] = GetRandomFloat(15.0, 20.0);
						if (GetRandomInt(0, 1) == 0)
							vAngle[1] = GetRandomFloat(-15.0, -20.0);
						else
							vAngle[1] = GetRandomFloat(15.0, 20.0);
						vAngle[2] = 0.0;
						SetEntPropVector(attacker, Prop_Send, "m_aimPunchAngle", vAngle);
						SetEntPropVector(attacker, Prop_Send, "m_aimPunchAngleVel", vAngle);
						g_hFFTimer[attacker] = CreateTimer(GetRandomFloat(0.4, 0.6), AimPunchReset, attacker, TIMER_FLAG_NO_MAPCHANGE);
					}
					if (damagetype & ~DMG_BURN && damagetype & ~DMG_BLAST)
						PlayerYell(victim, 1, true);
					return Plugin_Continue;
				}
			}
		}
	}
	if (bChanged) return Plugin_Changed;
	return Plugin_Continue;
}

public Action:Timer_NoticeBleeding(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return;
	
	new String:sSound[256];
	if (GetClientTeam(client) == TEAM_SURVIVORS)
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
		PrintToChat(client, "\x08%s你正处于出血状态！ 使用 \x01医疗包 \x08%s！", COLOR_DARKORANGE, COLOR_DARKORANGE);
		if (!IsLightModel(client))
			Format(sSound, sizeof(sSound), "player/voice/responses/security/subordinate/unsuppressed/wounded%d.ogg", GetRandomInt(1, 19));
		else
			Format(sSound, sizeof(sSound), "player/voice/responses/security/leader/unsuppressed/wounded%d.ogg", GetRandomInt(1, 18));
	}
	else
	{
		Format(sSound, sizeof(sSound), "player/voice/responses/insurgent/subordinate/unsuppressed/wounded1.ogg");
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_fZombieNextStats[client][SPEED]-GetRandomFloat(FCVAR_ZOMBIE_BLEED_REDUCE_SPEED_MIN, FCVAR_ZOMBIE_BLEED_REDUCE_SPEED_MAX));
	}
	EmitSoundToAll(sSound, client, SNDCHAN_VOICE, _, _, 1.0);
}

public Action:Timer_NoticeInfected(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return;

	SetEntityRenderColor(client, 145, 255, 145, 255);
	PrintToChat(client, "\x08%s你已被感染，使用 \x01医疗包 \x08%s！", COLOR_DARKORANGE, COLOR_DARKORANGE);
}

public Action:ObjectOnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (g_iGameState != 4 || attacker <= -1) return Plugin_Handled;
	if (victim == -1 || g_iCPType[g_iCurrentControlPoint] != 0 || g_iCPIndex[g_iCurrentControlPoint] == INVALID_ENT_REFERENCE)
	{
//		LogToGame("[NOT ACTIVATED] Object Weapon Cache %d damaged by %d (inflictor %d) damage %0.2f (Type %d), weapon %d", victim, attacker, inflictor, damage, damagetype, weapon);
		damage = 0.0;
/*		if (weapon == -1 && inflictor > MaxClients && attacker > MaxClients && inflictor == attacker && IsValidEntity(attacker))
		{
			decl String:sClassName[32];
			GetEntityClassname(attacker, sClassName, 32);
			if (StrEqual(sClassName, "CACHE (FLAME)", true) || StrEqual(sClassName, "entityflame", true))
			{
				LogToGame("It was \"%s\" killing it now...", sClassName);
				AcceptEntityInput(attacker, "Kill");
			}
		}	*/
		return Plugin_Changed;
	}

//	LogToGame("Object Weapon Cache %d == %d (%d == %d) damaged by %d (inflictor %d) damage %0.2f (Type %d), weapon %d", victim, EntRefToEntIndex(g_iCPIndex[g_iCurrentControlPoint]), EntIndexToEntRef(victim), g_iCPIndex[g_iCurrentControlPoint], attacker, inflictor, damage, damagetype, weapon);
	if (victim == EntRefToEntIndex(g_iCPIndex[g_iCurrentControlPoint]))
	{
		if (!GetCounterAttack())
		{
//			LogToGame("Object Weapon Cache %d damaged by %d (inflictor %d) damage %0.2f (Type %d), weapon %d", victim, attacker, inflictor, damage, damagetype, weapon);
			if (g_bIsMovingCache[victim] || (g_hWeaponCacheFireExplode != INVALID_HANDLE && damagetype & ~DMG_BLAST))
			{
				damage = 0.0;
				return Plugin_Changed;
			}
			if (attacker > 0 && attacker <= MaxClients && (IsClientInGame(attacker) && GetClientTeam(attacker) == TEAM_ZOMBIES || !IsClientInGame(attacker)))
			{
		//		if (g_iOnFireBy != attacker)
		//		{
					damage = 0.0;
					return Plugin_Changed;
		//		}
		//		else
		//		{
		//			return Plugin_Continue;
		//		}
			}
			if (damagetype & DMG_BLAST && g_hWeaponCacheFireExplode == INVALID_HANDLE && !g_bIsOnFire[victim] && GetRandomInt(0, 2) == 0)
			{
				CreateTimer(0.1, CheckObjectAfterExplosion, victim, TIMER_FLAG_NO_MAPCHANGE);
				g_iOnFireBy = attacker;
				return Plugin_Continue;
			}
			/*
			new String:sWeaponName[64] = "none";
			new String:sWeaponShortName[32] = "None";
			if (weapon > MaxClients && IsValidEntity(weapon))
			{
				GetEntityClassname(weapon, sWeaponName, 32);
				Format(sWeaponShortName, sizeof(sWeaponShortName), "%s", sWeaponName);
				ReplaceString(sWeaponShortName, sizeof(sWeaponShortName), "weapon_", "", false);
			}
			*/
			if (!g_bIsOnFire[victim])
			{
				if (damagetype & DMG_BULLET)
				{
		//			PrintToChatAll("weapon %s (%d) dmg %0.2f (TEST %0.2f <= %0.2f)", sWeaponShortName, weapon, damage, GetRandomFloat(0.1, 100.0), damage*0.02);
		/*			if (
						(damage >= 130 && GetRandomInt(0, 20) == 0)	||	// 7.62 (150~160) or slug (288)
						(damage <= 50 && GetRandomInt(0, 40) == 0)		// Normal shotguns (40 * 12)
					)	*/
					if (GetRandomFloat(0.0, 100.0) <= damage*0.035)
					{
						g_bIsOnFire[victim] = true;
						g_iOnFireBy = attacker;
						new Float:fTime;
						if (GetRandomInt(0, 12) != 0)
						{
							LogToGame("Object Weapon Cache %d is set on fire by attacker %N (%d)", victim, attacker, attacker);
							CreateTimer(0.01, CheckObjectForShouting, victim);
							fTime = GetRandomFloat(2.22, 9.99);
							g_hWeaponCacheFireExplode = CreateTimer(fTime, ExplodeWeaponCache, victim, TIMER_FLAG_NO_MAPCHANGE);
						}
						else
						{
							LogToGame("Object Weapon Cache %d is going to blow in a second by attacker %N (%d)", victim, attacker, attacker);
							if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && IsPlayerAlive(attacker))
							{
								if (GetRandomInt(0, 1) == 0) PlaySoundOnPlayer(attacker, "player/voice/botsurvival/subordinate/incominggrenade7.ogg");
								else PlaySoundOnPlayer(attacker, "player/voice/botsurvival/subordinate/incominggrenade8.ogg");
								FakeClientCommand(attacker, "say 快跑！");
							}
							fTime = GetRandomFloat(0.5, 1.5);
							g_hWeaponCacheFireExplode = CreateTimer(fTime, ExplodeWeaponCache, victim, TIMER_FLAG_NO_MAPCHANGE);
						}
						damage = 0.0;
						SetVariantFloat(fTime);
						AcceptEntityInput(victim, "IgniteLifetime");
//						AcceptEntityInput(victim, "Ignite");
					}
					else damage *= 0.4;
					return Plugin_Changed;
				}
				else if (damagetype & DMG_SLASH)
				{
					if (GetRandomInt(0, 5) == 0)
					{
						damage = 0.0;
						g_bIsOnFire[victim] = true;
						g_iOnFireBy = attacker;
						new Float:fTime;
						if (GetRandomInt(0, 6) != 0)
						{
							LogToGame("Object Weapon Cache %d is set on fire by attacker %N (%d)", victim, attacker, attacker);
//							AcceptEntityInput(victim, "Ignite");
							CreateTimer(0.01, CheckObjectForShouting, victim);
							fTime = GetRandomFloat(3.33, 9.99);
							g_hWeaponCacheFireExplode = CreateTimer(fTime, ExplodeWeaponCache, victim, TIMER_FLAG_NO_MAPCHANGE);
						}
						else
						{
							LogToGame("Object Weapon Cache %d is going to blow in a second by attacker %N (%d) with stupid knife", victim, attacker, attacker);
							if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && IsPlayerAlive(attacker))
							{
								PlaySoundOnPlayer(attacker, "player/voice/botsurvival/subordinate/incominggrenade24.ogg");
								FakeClientCommand(attacker, "say 操...");
							}
							fTime = GetRandomFloat(0.5, 1.0);
							g_hWeaponCacheFireExplode = CreateTimer(fTime, ExplodeWeaponCache, victim, TIMER_FLAG_NO_MAPCHANGE);
						}
						SetVariantFloat(fTime);
						AcceptEntityInput(victim, "IgniteLifetime");
					}
					else
					{
						damage = GetRandomFloat(10.0, 60.0);
						damagetype = DMG_GENERIC;
						if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker)) PrintToChat(attacker, "\x08%sDon't be stupid", COLOR_INSURGENTS);
					}
					return Plugin_Changed;
				}
				else if (damagetype & DMG_BURN && ((attacker > 0 && attacker <= MaxClients) || (inflictor > 0 && inflictor <= MaxClients))) // Don't get burn by world
				{
					if (!(attacker > 0 && attacker <= MaxClients) && inflictor > 0 && inflictor <= MaxClients)
					{
						if (IsClientInGame(inflictor))
							attacker = inflictor;
						else
						{
							damage *= 0.0;
							return Plugin_Changed;
						}
					}
					if (GetRandomInt(0, 6) == 0)
					{
						damage = 0.0;
						g_bIsOnFire[victim] = true;
						g_iOnFireBy = attacker;
						LogToGame("Object Weapon Cache %d is set on fire by attacker %N (%d)", victim, attacker, attacker);
						CreateTimer(0.01, CheckObjectForShouting, victim);
						new Float:fTime = GetRandomFloat(2.22, 8.88);
						SetVariantFloat(fTime);
						AcceptEntityInput(victim, "IgniteLifetime");
//						AcceptEntityInput(victim, "Ignite");
						g_hWeaponCacheFireExplode = CreateTimer(fTime, ExplodeWeaponCache, victim, TIMER_FLAG_NO_MAPCHANGE);
					}
					else damage *= 0.6;
					return Plugin_Changed;
				}
				else if (damagetype & ~DMG_BLAST)	// If not explosive damage
					damage = 0.0;
				else
					return Plugin_Continue;	// Let explosives dealing damages
			}
			else if (damagetype & DMG_BULLET)
			{
				damage = 0.0;
				return Plugin_Changed;
			}
			else if (damagetype & DMG_BURN)
			{
				if (inflictor > MaxClients && attacker > MaxClients && inflictor == attacker)	// Ignite (entityflame) damage
				{
					attacker = g_iOnFireBy;
				}
				damage = 0.0;		// Probably gonna blow up by timer until than prevent damage
				return Plugin_Changed;
			}
			else if (damagetype & ~DMG_BLAST)	// If not explosive no damage
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		else
		{
			if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == TEAM_ZOMBIES)
			{
//				LogToGame("Counter Object Weapon Cache %d damaged by %d (inflictor %d) damage %0.2f (Type %d), weapon %d", victim, attacker, inflictor, damage, damagetype, weapon);
				if (damagetype & DMG_BURN) damage *= 0.15;
				else if (damagetype & DMG_BULLET) damage *= 0.08;
				else damage *= 0.75;
				g_fWeaponCacheHealth -= damage;
				if (g_fWeaponCacheHealth <= 0.1 && g_fWeaponCacheHealth > -9999.9)
				{
					g_fWeaponCacheHealth = -9999.9;
					PrintToChatAll("\x08%s武器储备 \x01已被 \x08%s叛乱分子破坏", COLOR_SECURITY, COLOR_INSURGENTS);
					CreateTimer(0.0, ExplosionEffect, victim, TIMER_FLAG_NO_MAPCHANGE);
					PlayGameSoundToAll("Player.Security_Outpost_CacheDestroyed");
					new ent = FindEntityByClassname(-1, "ins_rulesproxy");
					if (ent > MaxClients && IsValidEntity(ent))
					{
						SetVariantInt(TEAM_ZOMBIES);
						AcceptEntityInput(ent, "EndRound");
					}
					else
					{
						for (new j = 0;j < MAXPLAYER; j++)
						{
							if (g_iPlayersList[j] == -1 || !IsPlayerAlive(g_iPlayersList[j]))
								continue;
							ForcePlayerSuicide(g_iPlayersList[j]);
						}
					}
		//			SDKUnhook(victim, SDKHook_OnTakeDamage, CounterAttackObjectOnTakeDamage);
					decl Float:vObjPos[3], Float:vTargetPos[3], Float:fDistance;
					GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", vObjPos);
					for (new j = 0;j < MAXPLAYER; j++)
					{
						if (g_iPlayersList[j] == -1) continue;
						new i = g_iPlayersList[j];
						
						GetClientAbsOrigin(i, vTargetPos);
						fDistance = GetVectorDistance(vObjPos, vTargetPos);
						if (fDistance < 1500)
							EmitSoundToClient(i, "weapons/WeaponCache/Cache_Explode.wav", victim, SNDCHAN_STATIC, 140, _, 1.0);	// 140dB
						else if (fDistance < 5000)
							EmitSoundToClient(i, "weapons/WeaponCache/Cache_Explode_Distant.wav", victim, SNDCHAN_STATIC, 110, _, 1.0);		// 110dB
						else
							EmitSoundToClient(i, "weapons/WeaponCache/Cache_Explode_far_Distant.wav", victim, SNDCHAN_STATIC, 150, _, 1.0);	// 150dB
					}
				}
				else
				{
					if (g_fCacheLastHitTime <= g_fGameTime)
					{
						g_fCacheLastHitTime = g_fGameTime+5.0;
						PlayGameSoundToAll("Player.Security_Outpost_CacheTakesDamage");
					}
					PrintToChatAll("\x08%s武器储备 \x05%0.0f \x01/ \x05%0.0f", COLOR_GOLD, g_fWeaponCacheHealth, FCVAR_GAME_COUNTERATTACK_WEAPON_CACHE_HEALTH);
				}
			}
			else
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}

	// Let explosives dealing damages
	return Plugin_Continue;
}

public Action:CheckObjectForShouting(Handle:timer, any:iobject)
{
	if (iobject > MaxClients && IsValidEntity(iobject) && g_iCPType[g_iCurrentControlPoint] == 0 && EntRefToEntIndex(g_iCPIndex[g_iCurrentControlPoint]) == iobject)
	{
		if (g_iOnFireBy > 0 && g_iOnFireBy <= MaxClients && IsClientInGame(g_iOnFireBy) && IsPlayerAlive(g_iOnFireBy))
		{
			PlayerYell(g_iOnFireBy, 0, true);
			FakeClientCommand(g_iOnFireBy, "say 快跑！武器储备在燃烧！");
		}
	}
	return Plugin_Continue;
}

public Action:CheckObjectAfterExplosion(Handle:timer, any:iobject)
{
	if (GetGameState() != 4) return;
	if (g_hWeaponCacheFireExplode == INVALID_HANDLE && iobject > MaxClients && IsValidEntity(iobject) && g_iCPType[g_iCurrentControlPoint] == 0 && EntRefToEntIndex(g_iCPIndex[g_iCurrentControlPoint]) == iobject)
	{
		g_bIsOnFire[iobject] = true;
		LogToGame("Object Weapon Cache %d is set on fire by attacker %N (%d)", iobject, g_iOnFireBy, g_iOnFireBy);
		if (g_iOnFireBy > 0 && g_iOnFireBy <= MaxClients && IsClientInGame(g_iOnFireBy) && IsPlayerAlive(g_iOnFireBy))
		{
			PlayerYell(g_iOnFireBy, 0, true);
			FakeClientCommand(g_iOnFireBy, "say 快跑！武器储备在燃烧！");
		}
		new Float:fTime = GetRandomFloat(1.11, 6.66);
		SetVariantFloat(fTime);
		AcceptEntityInput(iobject, "IgniteLifetime");
//		AcceptEntityInput(iobject, "Ignite");
		g_hWeaponCacheFireExplode = CreateTimer(fTime, ExplodeWeaponCache, iobject, TIMER_FLAG_NO_MAPCHANGE);
		LogToGame("Object Weapon Cache %d has been survived from explosion, set on fire (attacker: %d)", iobject, (g_iOnFireBy>0&&IsClientInGame(g_iOnFireBy))?g_iOnFireBy:iobject);
	}
//	else g_iOnFireBy = 0;
	return;
}

public Action:ExplodeWeaponCache(Handle:timer, any:iobject)
{
	if (g_hWeaponCacheFireExplode != INVALID_HANDLE && timer == g_hWeaponCacheFireExplode && iobject > MaxClients && IsValidEntity(iobject))
	{
		g_hWeaponCacheFireExplode = INVALID_HANDLE;
//		SDKUnhook(iobject, SDKHook_OnTakeDamage, ObjectOnTakeDamage);
//		Entity_Hurt(iobject, 5000, (g_iOnFireBy>0&&IsClientInGame(g_iOnFireBy))?g_iOnFireBy:-1, DMG_BLAST, "Allahu Akbar");
		decl String:weapon[15] = "c4_clicker";
		Entity_Hurt(iobject, 1000, 
			g_iOnFireBy > 0 && g_iOnFireBy <= MaxClients && IsClientInGame(g_iOnFireBy) && GetClientTeam(g_iOnFireBy) == TEAM_SURVIVORS ?
			g_iOnFireBy : GetRandomPlayer(g_iOnFireBy, TEAM_SURVIVORS, false, true, false)
		, DMG_BLAST, weapon);
		LogToGame("Object Weapon Cache %d has been blow up (attacker: %d)", iobject, (g_iOnFireBy>0&&IsClientInGame(g_iOnFireBy))?g_iOnFireBy:-1);
	}
	return Plugin_Continue;
}

public Action:Event_PlayerTeam(Event event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bHasSquad[client] = false;
	if (g_bMedicPlayer[client]) g_bMedicPlayer[client] = false;
	if (!IsFakeClient(client))
	{
		if (GetEventInt(event, "team") <= 1)
		{
	//		RemoveHelmet(client);
			RemoveCustomFlags(client);
			g_sPlayerClassTemplate[client] = "";
			if (g_fPlayerTempPropTimestamp[client] != 0.0 && g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]))
			{
				// PrintToServer("Removing #3");
				decl String:targetname[64];
				GetEntPropString(g_iPlayerTempProp[client], Prop_Data, "m_iName", targetname, sizeof(targetname));
				if (StrEqual(targetname, "LuaCustomModel", true))
				{
					LogToGame("%N is installing gear id %d but moved team before complete %d", client, g_iPlayerCustomGear[client], g_iPlayerTempProp[client]);
					RequestFrame(DeleteEntity, EntIndexToEntRef(g_iPlayerTempProp[client]));
				}
			}
		}
	}
}

public Action:Event_PlayerPickSquad(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bHasSquad[client] = true;
	GetEventString(event, "class_template", g_sPlayerClassTemplate[client], sizeof(g_sPlayerClassTemplate[]));
	if (StrContains(g_sPlayerClassTemplate[client], "medic", false) != -1)
	{
		if (GetGameTime() > g_fMedicBannedTime[client])
		{
			g_bMedicPlayer[client] = true;
			g_fMedicLastHealTime[client] = GetGameTime();
			g_bMedicForceToChange[client] = false;
			PrintToChatAll("\x08%s新医疗玩家：  \x08%s%N", COLOR_GOLD, GetPlayerChatColor(client), client);
		}
		else
		{
			g_bHasSquad[client] = false;
			new Float:fBanTime = g_fMedicBannedTime[client]-GetGameTime();
			ChangeClientTeam(client, TEAM_SPECTATOR);
			PrintCenterText(client, "在 %0.0f 秒内你将不能扮演医疗兵\n \n作为医疗兵你需要治疗你的队友", fBanTime);
			PrintToChat(client, "\x04在 \x01%0.0f 秒内你将不能扮演医疗兵, \x05作为医疗兵你需要治疗你的队友", fBanTime);
			PrintToChat(client, "\x04在 \x01%0.0f 秒内你将不能扮演医疗兵, \x05作为医疗兵你需要治疗你的队友", fBanTime);
			PrintToChat(client, "\x04在 \x01%0.0f 秒内你将不能扮演医疗兵, \x05作为医疗兵你需要治疗你的队友", fBanTime);
			PrintToChat(client, "\x04在 \x01%0.0f 秒内你将不能扮演医疗兵, \x05作为医疗兵你需要治疗你的队友", fBanTime);
			if (GetRandomInt(0, 3) != 0)
				ClientCommand(client, "playgamesound Radial_Security.Subordinate_%s_Negative_Radio", GetRandomInt(0, 3) != 0 ? "UnSupp" : "Supp");
			else
				ClientCommand(client, "playgamesound Radial_Security.Leader_%s_Negative_Radio", GetRandomInt(0, 3) != 0 ? "UnSupp" : "Supp");
			// CreateTimer(0.1, Timer_MoveToSurvivors, client, TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Continue;
		}
	}
	else if (g_bMedicPlayer[client])
		g_bMedicPlayer[client] = false;
	if (!IsFakeClient(client))
	{
		if (WelcomeToTheCompany[client] == 0)
			CreateTimer(1.0, WelcomeToTheCompany_rly, client, TIMER_FLAG_NO_MAPCHANGE);
		if (GetGameState() <= 2)
		{
			RespawnPlayer(client, 0);
			FakeClientCommand(client, "inventory_confirm");
		}
	}
	if (GetClientTeam(client) == TEAM_SURVIVORS)
	{
		if (StrContains(g_sPlayerClassTemplate[client], "medic", false) == -1)
			RemoveCustomFlags(client);
		else
			CreateCustomFlag(client);
	}
	if (DEBUGGING_ENABLED)
		LogToGame("Player \"%N\" has picked class template \"%s\"", client, g_sPlayerClassTemplate[client]);
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Event event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new iTeam = -1;
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || (iTeam = GetClientTeam(client)) <= TEAM_SPECTATOR)
		return Plugin_Continue;

	g_bIsInCaptureZone[client] = false;
	g_fSuppressedTime[client] = 0.0;
	g_fBurnTime[client] = 0.0;
	g_iPlayerBleeding[client] = 0;
	g_fPlayerBleedTime[client] = 0.0;
	g_fNextBurnTime[client] = 0.0;
	g_fProtectionTime[client] = 0.0;
	g_iLastHitgroup[client] = 0;
	g_iBurnedBy[client] = -1;
	g_iPlayerDeployedWeapon[client] = -1;
	g_iPlayerCustomGear[client] = -1;
	g_iPlayerLastKnife[client] = -1;
	g_fPlayerLastSteped[client] = 0.0;
//	g_iPlayerHasHelmet[client] = INVALID_ENT_REFERENCE;
/*	new bool:bIsBot = IsFakeClient(client);
	if (bIsBot)
	{
//		SetEntProp(client, Prop_Data, "m_afButtonForced", 0);
//		SetEntProp(client, Prop_Data, "m_afButtonDisabled", 0);
		SetEntProp(client, Prop_Data, "m_bDuckToggled", 0);
	}	*/
	if (iTeam == TEAM_SURVIVORS)
	{
		g_iPLFBuyzone[client] = INVALID_ENT_REFERENCE;
		g_iPlayerInfected[client] = 0;
		g_fNextInfection[client] = 0.0;
		g_fPlayerDrugTime[client] = 0.0;
		g_fLastMedicCall[client] = 0.0;
		g_iLastHealTarget[client] = -1;
		g_fLastHealingTime[client] = 0.0;
		g_iPlayerHealthkitDeploy[client] = -1;
		g_iPlayerHealthkitTarget[client] = -1;
		g_iPlayerHealthkitHealingBy[client] = -1;
		g_fPlayerDeathFadeOutNextTime[client] = 0.0;
		g_iPlayerArmor[client] = 0;
		g_fPlayerLastLeaped[client] = 0.0;
		if (g_iLastManStand != -1 && g_iLastManStand != client)
		{
			g_iLastManStand = -1;
			//StopSoundAll("Lua_sounds/zombiehorde/lasthuman.ogg", SNDCHAN_AUTO);
		}
		if (g_iGameState == 4 && g_bUpdatedSpawnPoint)
		{
			FakeClientCommand(client, "inventory_resupply");	// Fixing bugged animation when spawn sometimes
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
			if (CVAR_PLAYER_HEALTH != 100)
			{
				SetEntProp(client, Prop_Send, "m_iMaxHealth", CVAR_PLAYER_HEALTH);
				SetEntProp(client, Prop_Send, "m_iHealth", CVAR_PLAYER_HEALTH);
			}
			// #Resupply Check
			new iKnife = GetPlayerWeaponByName(client, "weapon_kabar");
			if (iKnife <= MaxClients || !IsValidEdict(iKnife))
				iKnife = GivePlayerItem(client, "weapon_kabar");
			if (iKnife > MaxClients && IsValidEdict(iKnife))
				g_iPlayerLastKnife[client] = EntIndexToEntRef(iKnife);
			INS_OnPlayerResupplyed(client);
			if (g_iTeleportOnSpawn[client] != 0)
			{
				if (TeleportOnSpawn_Sec(client, g_iTeleportOnSpawn[client]))
					g_fProtectionTime[client] = g_fGameTime-(FCVAR_PLAYER_SPAWN_PROTECTION/1.5);
				else if (g_iCurrentControlPoint > 0)
				{
					TeleportOnSpawn_Sec(client, 1);
					g_fProtectionTime[client] = g_fGameTime-(FCVAR_PLAYER_SPAWN_PROTECTION/1.5);
				}
				else
				{
					g_fProtectionTime[client] = !g_bCounterAttack?g_fGameTime:g_fGameTime/1.5;
				}
			}
			else
			{
				g_fProtectionTime[client] = !g_bCounterAttack?g_fGameTime:g_fGameTime/1.5;
			}
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			PrintToChat(client, "\x01(( \x08%s重生保护\x01 ))", COLOR_AZURE);
			if (IsLeader(client))
			{
				CreateTimer(0.05, Timer_CreateCustomFlag, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else
		{
			// #Resupply Check
			new iKnife = GetPlayerWeaponByName(client, "weapon_kabar");
			if (iKnife <= MaxClients || !IsValidEdict(iKnife))
				iKnife = GivePlayerItem(client, "weapon_kabar");
			if (iKnife > MaxClients && IsValidEdict(iKnife))
				g_iPlayerLastKnife[client] = EntIndexToEntRef(iKnife);
			INS_OnPlayerResupplyed(client);
			if (g_bMedicPlayer[client])
			{
				decl String:language[64];
				GetClientInfo(client, "cl_language", language, sizeof(language));
				new Handle:panel = CreatePanel();
				if (StrContains(language, "korea", false) == -1)
				{
					SetPanelTitle(panel, "你正在扮演 [医疗兵]");
					DrawPanelText(panel, " ");
					DrawPanelItem(panel, "使用[医疗包]来治疗你的队友 (3号槽位)");
					DrawPanelText(panel, " ");
					DrawPanelText(panel, "请注意[有光圈的队友]");
					DrawPanelItem(panel, "他们已受伤并需要你的治疗！");
					DrawPanelText(panel, " ");
					DrawPanelText(panel, " ");
					//DrawPanelText(panel, "如果你在5分钟之内不治疗队友，你的职业将会被强制变更");
					DrawPanelItem(panel, "确认并关闭");
				}
				else
				{
					SetPanelTitle(panel, "당신은 지금  [메딕] 병과로 플레이 중입니다");
					DrawPanelText(panel, " ");
					DrawPanelItem(panel, "[First Aid] 를 사용해 아군을 치료하세요  (3번 슬롯)");
					DrawPanelText(panel, " ");
					DrawPanelText(panel, "[빛나는 플레이어] 들을 주시하세요");
					DrawPanelItem(panel, "그러한 플레이어들은 치료가 필요합니다 !");
					DrawPanelText(panel, " ");
					DrawPanelText(panel, " ");
					//DrawPanelText(panel, "5분 넘게 아군을 치료하지 않을 경우 강제로 병과가 변경됩니다.");
					DrawPanelItem(panel, "확인 및 닫기");
				}
				SendPanelToClient(panel, client, Handler_MedicMenu, 0);
				CloseHandle(panel);
			}
		}
	}
	else if (iTeam == TEAM_ZOMBIES)
	{
//		SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER_MOVEMENT); //COLLISION_GROUP_PUSHAWAY
//		SetEntityRenderFx(client, RENDERFX_NONE);
		g_iZombieClass[client] = {-1, 0};
		g_iPlayerStatus[client] = 0;
		g_fZombieNextStats[client] = Float:{300.0, 1.0, 1.0};
		g_fZombieObjectDamaged[client] = 0.0;
		g_fSpawnTime[client] = GetGameTime();
		if (g_bUpdatedSpawnPoint)
		{
			ZombieBurnSound(client, false);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			FakeClientCommand(client, "inventory_sell_all");
			RequestFrame(ZH_Frame_SetZombieClass, client);
			if (g_iTeleportOnSpawn[client] != 0) TeleportEntity(client, Float:{0.0, 0.0, 2000.0}, NULL_VECTOR, NULL_VECTOR);
			CreateTimer(0.2, Timer_BotSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			ZH_SetZombieModel(client);
		}
	}
//	LogToGame("%N Spawned on team %d", client, iTeam);
	return Plugin_Continue;
}

stock ZH_SetZombieModel(client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return false;
	static iModel = -1;
	iModel += 1;
	if (iModel > 4) iModel = 0;
	if (g_iZombieModels[iModel] != -1)
		SetEntProp(client, Prop_Send, "m_nModelIndex", g_iZombieModels[iModel]);
	else
	{
		LogError("Zombie <%d> %N has selected random insurgent model (index %d) but not precached", client, client, iModel);
		return false;
	}
	return true;
}

public Action:Timer_BotSpawn(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_iGameState != 4) return;

	if (g_iZombieClass[client][CLASS] != -1)
	{
		new bool:bSpawn = true;
		new iKnife = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if (iKnife <= MaxClients || !IsValidEntity(iKnife))
			bSpawn = false;
		else
		{
			new String:sWeaponName[64];
			GetEntityClassname(iKnife, sWeaponName, sizeof(sWeaponName));
			if (!StrEqual(sWeaponName, "weapon_kabar"))
				bSpawn = false;
		}
		if (bSpawn)
		{
			ZH_SetZombieModel(client);
			g_iZombieSpawnCount[g_iZombieClass[client][CLASS]]++;
			switch(g_iZombieClass[client][CLASS])
			{
				case ZOMBIE_IED_INDEX:
				{
					SetEntPropFloat(iKnife, Prop_Data, "m_flNextPrimaryAttack", g_fSpawnTime[client]+3600.0);
					SetEntPropFloat(iKnife, Prop_Data, "m_flNextSecondaryAttack", g_fSpawnTime[client]+3600.0);
					new iModel = 0;
					if (g_iZombieClass[client][VAR] != 6666) iModel = g_iZombieClass[client][VAR]-66;
					else iModel = 7;
					if (iModel > -1 && g_iSuicideBombWeaponModels[iModel] != -1)
						SetEntProp(iKnife, Prop_Send, "m_iWorldModelIndex", g_iSuicideBombWeaponModels[iModel]);
				}
				
				default:
				{
					SetEntProp(iKnife, Prop_Send, "m_iWorldModelIndex", -1);
					GivePlayerItem(client, ZOMBIE_DUMMY_WEAPON);
				}
			}
			new iHp = RoundToZero(g_fZombieNextStats[client][HP]);
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
			SetEntProp(client, Prop_Data, "m_iMaxHealth", iHp);
			SetEntProp(client, Prop_Send, "m_iHealth", iHp);
			SetEntProp(client, Prop_Send, "m_nBody", GetRandomInt(0, 17));
			if (g_fZombieNextStats[client][SPEED] != 1.0)
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_fZombieNextStats[client][SPEED]);
			ResizePlayer(client, g_fZombieNextStats[client][SIZE]);

			if (g_iTeleportOnSpawn[client] != 0)
				TeleportOnSpawn(client, g_iTeleportOnSpawn[client]);
		}
		else
		{
			LogToGame("Bot <%d> %N has spawned and respawn because failed to setup (Class %d)", client, client, g_iZombieClass[client][CLASS]);
			RespawnPlayer(client, g_iTeleportOnSpawn[client]);
		}
	}
	else
	{
		LogToGame("Bot <%d> %N has spawned and respawn because failed to setup (Class -1)", client, client);
		RespawnPlayer(client, g_iTeleportOnSpawn[client]);
	}
}

public Action:Timer_CreateCustomFlag(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return;
	CreateCustomFlag(client);
}

stock ZombieBurnSound(client, bool:enable = true)
{
	if ((enable && g_iZombieBurnSound[client] > 0) || (!enable && g_iZombieBurnSound[client] == 0) || g_iZombieClass[client][CLASS] == ZOMBIE_IED_INDEX) return;
	
	if (enable)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_ZOMBIES)
		{
			decl String:sSound[128];
			g_iZombieBurnSound[client] = GetRandomInt(1, 4);
			Format(sSound, sizeof(sSound), "Lua_sounds/zombiehorde/zombies/classic/moan_loop%d.wav", g_iZombieBurnSound[client]);
			EmitSoundToAll(sSound, client, SNDCHAN_STATIC, _, _, 0.8);
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_fZombieNextStats[client][SPEED]+GetRandomFloat(FCVAR_ZOMBIE_BURN_BONUS_SPEED_MIN, FCVAR_ZOMBIE_BURN_BONUS_SPEED_MAX));
		}
	}
	else if (!enable)
	{
		if (g_iZombieBurnSound[client])
		{
			decl String:sSound[128];
			Format(sSound, sizeof(sSound), "Lua_sounds/zombiehorde/zombies/classic/moan_loop%d.wav", g_iZombieBurnSound[client]);
			StopSound(client, SNDCHAN_STATIC, sSound);
			g_iZombieBurnSound[client] = 0;
		}
	}
	return;
}
/*
stock GetZombieCount(class_index)
{
	if (class_index < 0 || class_index >= MAX_ZOMBIE_CLASSES) return -1;

	new iCount = 0;
	for (new i = 1;i <= MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_ZOMBIES && IsPlayerAlive(i) && g_iZombieClass[i][CLASS] == class_index)
			iCount++;
	}
	return iCount;
}
*/
public ZH_Frame_SetZombieClass(any:client)
{
	ZH_SetZombieClass(client, -1, 1.0);
}

stock ZH_SetZombieClass(client, force_class = -1, Float:fHP = 1.0)
{
	// Return (-2 = Retry, -1 = Failed, Otherwise Class Index)
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return -1;

	if (g_iGameState != 4)
	{
		ZH_SetZombieModel(client);
		return -1;
	}

	if (g_iAttachedParticleRef[client] != INVALID_ENT_REFERENCE && IsValidEdict(g_iAttachedParticleRef[client]))
	{
		new iParticle = EntRefToEntIndex(g_iAttachedParticleRef[client]);
		if (iParticle > MaxClients && IsValidEntity(iParticle))
		{
			AcceptEntityInput(iParticle, "Kill");
			g_iAttachedParticleRef[client] = INVALID_ENT_REFERENCE;
		}
	}
	if (force_class == -1)
	{
		new bool:bArrayZombieClassCheck[MAX_ZOMBIE_CLASSES] = {false, ...}, iLoop = 0;
		while (iLoop < MAX_ZOMBIE_CLASSES-1) // -1 because of common class
		{
			force_class = GetRandomInt(1, MAX_ZOMBIE_CLASSES-1);
			if (bArrayZombieClassCheck[force_class])
				continue;
			else
			{
				new Float:fCVAR_Chance = 100.0;
				new iCVAR_MaxSpawn = -1;
				new Float:fCVAR_MaxSpawn_Survivors = 1.0;
				new Float:fCVAR_MaxSpawn_Zombies = 1.0;
/*				if (force_class == ZOMBIE_BLINKER_INDEX)
				{
					fCVAR_Chance = FCVAR_ZOMBIE_BLINKER_CHANCE;
					iCVAR_MaxSpawn = CVAR_ZOMBIE_BLINKER_MAX_SPAWN;
					fCVAR_MaxSpawn_Survivors = FCVAR_ZOMBIE_BLINKER_MAX_SPAWN_PER_SURVIVORS;
					fCVAR_MaxSpawn_Zombies = FCVAR_ZOMBIE_BLINKER_MAX_SPAWN_PER_ZOMBIES;
				}
				else */
				if (force_class == ZOMBIE_KNIGHT_INDEX)
				{
					fCVAR_Chance = FCVAR_ZOMBIE_KNIGHT_CHANCE;
					iCVAR_MaxSpawn = CVAR_ZOMBIE_KNIGHT_MAX_SPAWN;
					fCVAR_MaxSpawn_Survivors = FCVAR_ZOMBIE_KNIGHT_MAX_SPAWN_PER_SURVIVORS;
					fCVAR_MaxSpawn_Zombies = FCVAR_ZOMBIE_KNIGHT_MAX_SPAWN_PER_ZOMBIES;
				}
				else if (force_class == ZOMBIE_STALKER_INDEX)
				{
					fCVAR_Chance = FCVAR_ZOMBIE_STALKER_CHANCE;
					iCVAR_MaxSpawn = CVAR_ZOMBIE_STALKER_MAX_SPAWN;
					fCVAR_MaxSpawn_Survivors = FCVAR_ZOMBIE_STALKER_MAX_SPAWN_PER_SURVIVORS;
					fCVAR_MaxSpawn_Zombies = FCVAR_ZOMBIE_STALKER_MAX_SPAWN_PER_ZOMBIES;
				}
				else if (force_class == ZOMBIE_BURNER_INDEX)
				{
					fCVAR_Chance = FCVAR_ZOMBIE_BURNER_CHANCE;
					iCVAR_MaxSpawn = CVAR_ZOMBIE_BURNER_MAX_SPAWN;
					fCVAR_MaxSpawn_Survivors = FCVAR_ZOMBIE_BURNER_MAX_SPAWN_PER_SURVIVORS;
					fCVAR_MaxSpawn_Zombies = FCVAR_ZOMBIE_BURNER_MAX_SPAWN_PER_ZOMBIES;
				}
				else if (force_class == ZOMBIE_SMOKER_INDEX)
				{
					fCVAR_Chance = FCVAR_ZOMBIE_SMOKER_CHANCE;
					iCVAR_MaxSpawn = CVAR_ZOMBIE_SMOKER_MAX_SPAWN;
					fCVAR_MaxSpawn_Survivors = FCVAR_ZOMBIE_SMOKER_MAX_SPAWN_PER_SURVIVORS;
					fCVAR_MaxSpawn_Zombies = FCVAR_ZOMBIE_SMOKER_MAX_SPAWN_PER_ZOMBIES;
				}
				else if (force_class == ZOMBIE_IED_INDEX)
				{
					fCVAR_Chance = FCVAR_ZOMBIE_IED_CHANCE;
					iCVAR_MaxSpawn = CVAR_ZOMBIE_IED_MAX_SPAWN;
					fCVAR_MaxSpawn_Survivors = FCVAR_ZOMBIE_IED_MAX_SPAWN_PER_SURVIVORS;
					fCVAR_MaxSpawn_Zombies = FCVAR_ZOMBIE_IED_MAX_SPAWN_PER_ZOMBIES;
				}
				else if (force_class == ZOMBIE_LEAPER_INDEX)
				{
					fCVAR_Chance = FCVAR_ZOMBIE_LEAPER_CHANCE;
					iCVAR_MaxSpawn = CVAR_ZOMBIE_LEAPER_MAX_SPAWN;
					fCVAR_MaxSpawn_Survivors = FCVAR_ZOMBIE_LEAPER_MAX_SPAWN_PER_SURVIVORS;
					fCVAR_MaxSpawn_Zombies = FCVAR_ZOMBIE_LEAPER_MAX_SPAWN_PER_ZOMBIES;
				}
				else
				{
//					LogToGame("[ZH] Out of zombie class index for %d", force_class);
					force_class = GetRandomInt(0, 1) == 0?ZOMBIE_COMMON_INDEX:ZOMBIE_CLASSIC_INDEX;
					break;
				}
				if (fCVAR_Chance < 0.11)
				{
//					PrintToServer("[ZH] Class index %d has lower chance than 0.11 and refuse to run", force_class);
					iLoop++;
					bArrayZombieClassCheck[force_class] = true;
					continue;
				}
/*				else // if (force_class == ZOMBIE_COMMON_INDEX)
				{
					fCVAR_Chance = FCVAR_ZOMBIE_COMMON_CHANCE;
					iCVAR_MaxSpawn = CVAR_ZOMBIE_COMMON_MAX_SPAWN;
					fCVAR_MaxSpawn_Survivors = FCVAR_ZOMBIE_COMMON_MAX_SPAWN_PER_SURVIVORS;
					fCVAR_MaxSpawn_Zombies = FCVAR_ZOMBIE_COMMON_MAX_SPAWN_PER_ZOMBIES;
				}	*/

				if (GetRandomFloat(0.10, 100.00) > fCVAR_Chance)
				{
					iLoop++;
					bArrayZombieClassCheck[force_class] = true;
					continue;
				}

				if (iCVAR_MaxSpawn == -1)
					break;
				else if (iCVAR_MaxSpawn == -2)
				{
//					if (force_class == ZOMBIE_SMOKER_INDEX)
//						PrintToChatAll("Min Count %d  <=  Spawn Count %d", RoundToNearest(g_iSecurityAlive*fCVAR_MaxSpawn_Survivors), g_iZombieSpawnCount[force_class]);
					if (RoundToNearest(g_iSecurityAlive*fCVAR_MaxSpawn_Survivors) <= g_iZombieSpawnCount[force_class])
					{
						iLoop++;
						bArrayZombieClassCheck[force_class] = true;
						continue;
					}
					else
						break;
				}
				else if (iCVAR_MaxSpawn == -3)
				{
					if (RoundToNearest(g_iSecurityAlive*fCVAR_MaxSpawn_Zombies) <= g_iZombieSpawnCount[force_class])
					{
						iLoop++;
						bArrayZombieClassCheck[force_class] = true;
						continue;
					}
					else
						break;
				}
				else if (iCVAR_MaxSpawn > 0 && iCVAR_MaxSpawn > g_iZombieSpawnCount[force_class])
					break;
				else
				{
					iLoop++;
					bArrayZombieClassCheck[force_class] = true;
					continue;
				}
			}
		}
		if (iLoop >= MAX_ZOMBIE_CLASSES-1)	// Failed to select zombies in while
		{
			force_class = GetRandomInt(0, 1) == 0?ZOMBIE_COMMON_INDEX:ZOMBIE_CLASSIC_INDEX;
		}
	}
	if (force_class < 0 || force_class >= MAX_ZOMBIE_CLASSES) force_class = ZOMBIE_COMMON_INDEX;
	new bool:IsBot = IsFakeClient(client);
	if (force_class == ZOMBIE_COMMON_INDEX || force_class == ZOMBIE_CLASSIC_INDEX)
	{
		g_iZombieClass[client][CLASS] = force_class;
		new iHp = CVAR_ZOMBIE_COMMON_BOT_HEALTH_MAX;
		new Float:fSpeed = FCVAR_ZOMBIE_COMMON_SPEED_MAX;
		if (IsBot)
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_COMMON_BOT_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_COMMON_BOT_HEALTH_MIN, CVAR_ZOMBIE_COMMON_BOT_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_COMMON_BOT_SPEED_MIN, FCVAR_ZOMBIE_COMMON_BOT_SPEED_MAX);
		}
		else
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_COMMON_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_COMMON_HEALTH_MIN, CVAR_ZOMBIE_COMMON_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_COMMON_SPEED_MIN, FCVAR_ZOMBIE_COMMON_SPEED_MAX);
		}
		g_fZombieNextStats[client][SIZE] = GetRandomFloat(FCVAR_ZOMBIE_COMMON_SIZE_MIN, FCVAR_ZOMBIE_COMMON_SIZE_MAX);
		SetEntityRenderColor(client, CVAR_ZOMBIE_COMMON_COLOR_RED, CVAR_ZOMBIE_COMMON_COLOR_GREEN, CVAR_ZOMBIE_COMMON_COLOR_BLUE, 255);
		if (fHP == 1.0)	g_fZombieNextStats[client][HP] = float(iHp);
		else g_fZombieNextStats[client][HP] = float(iHp)*fHP;
		g_fZombieNextStats[client][SPEED] = fSpeed;
		LogToGame("[ZH]  \"%N\"  Class: %s,   HP: %d,   Movement: %0.2f,   Size: %0.2f", client, force_class==ZOMBIE_COMMON_INDEX?"Common":"Classic", iHp, fSpeed, g_fZombieNextStats[client][SIZE]);

		switch(GetRandomInt(0, 6))
		{
			case 3:
			{
				FakeClientCommand(client, "inventory_buy_gear 2");
			}
			case 5:
			{
				FakeClientCommand(client, "inventory_buy_gear 4");
			}
		}
		FakeClientCommand(client, "inventory_resupply");
		return force_class;
	}
/*	else if (force_class == ZOMBIE_BLINKER_INDEX)
	{
		if (CVAR_ZOMBIE_BLINKER_RESTRICT != 0)
		{
			if (CVAR_ZOMBIE_BLINKER_RESTRICT == 1 && IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
			else if (CVAR_ZOMBIE_BLINKER_RESTRICT == 2 && !IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
		}
		g_iZombieClass[client][CLASS] = ZOMBIE_BLINKER_INDEX;
		new iHp = CVAR_ZOMBIE_BLINKER_BOT_HEALTH_MAX;
		new Float:fSpeed = FCVAR_ZOMBIE_BLINKER_SPEED_MAX;
		if (IsBot)
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_BLINKER_BOT_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_BLINKER_BOT_HEALTH_MIN, CVAR_ZOMBIE_BLINKER_BOT_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_BLINKER_BOT_SPEED_MIN, FCVAR_ZOMBIE_BLINKER_BOT_SPEED_MAX);
		}
		else
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_BLINKER_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_BLINKER_HEALTH_MIN, CVAR_ZOMBIE_BLINKER_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_BLINKER_SPEED_MIN, FCVAR_ZOMBIE_BLINKER_SPEED_MAX);
		}
		g_fZombieNextStats[client][SIZE] = GetRandomFloat(FCVAR_ZOMBIE_BLINKER_SIZE_MIN, FCVAR_ZOMBIE_BLINKER_SIZE_MAX);
		SetEntityRenderFx(client, RENDERFX_STROBE_FASTER);
		SetEntityRenderColor(client, CVAR_ZOMBIE_BLINKER_COLOR_RED, CVAR_ZOMBIE_BLINKER_COLOR_GREEN, CVAR_ZOMBIE_BLINKER_COLOR_BLUE, CVAR_ZOMBIE_BLINKER_COLOR_ALPHA);
		if (fHP == 1.0)	g_fZombieNextStats[client][HP] = float(iHp);
		else g_fZombieNextStats[client][HP] = float(iHp)*fHP;
		g_fZombieNextStats[client][SPEED] = fSpeed;
		LogToGame("[ZH]  \"%N\"  Class: Blinker,   HP: %d,   Movement: %0.2f,   Size: %0.2f", client, iHp, fSpeed, g_fZombieNextStats[client][SIZE]);

		switch(GetRandomInt(0, 6))
		{
			case 3:
			{
				FakeClientCommand(client, "inventory_buy_gear 2");
			}
			case 5:
			{
				FakeClientCommand(client, "inventory_buy_gear 4");
			}
		}
		FakeClientCommand(client, "inventory_resupply");
		return ZOMBIE_BLINKER_INDEX;
	}	*/
	else if (force_class == ZOMBIE_KNIGHT_INDEX)
	{
		if (CVAR_ZOMBIE_KNIGHT_RESTRICT != 0)
		{
			if (CVAR_ZOMBIE_KNIGHT_RESTRICT == 1 && IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
			else if (CVAR_ZOMBIE_KNIGHT_RESTRICT == 2 && !IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
		}
		g_iZombieClass[client][CLASS] = ZOMBIE_KNIGHT_INDEX;
		new iHp = CVAR_ZOMBIE_KNIGHT_BOT_HEALTH_MAX;
		new Float:fSpeed = FCVAR_ZOMBIE_KNIGHT_SPEED_MAX;
		if (IsBot)
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_KNIGHT_BOT_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_KNIGHT_BOT_HEALTH_MIN, CVAR_ZOMBIE_KNIGHT_BOT_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_KNIGHT_BOT_SPEED_MIN, FCVAR_ZOMBIE_KNIGHT_BOT_SPEED_MAX);
		}
		else
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_KNIGHT_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_KNIGHT_HEALTH_MIN, CVAR_ZOMBIE_KNIGHT_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_KNIGHT_SPEED_MIN, FCVAR_ZOMBIE_KNIGHT_SPEED_MAX);
		}
		g_fZombieNextStats[client][SIZE] = GetRandomFloat(FCVAR_ZOMBIE_KNIGHT_SIZE_MIN, FCVAR_ZOMBIE_KNIGHT_SIZE_MAX);
		SetEntityRenderColor(client, CVAR_ZOMBIE_KNIGHT_COLOR_RED, CVAR_ZOMBIE_KNIGHT_COLOR_GREEN, CVAR_ZOMBIE_KNIGHT_COLOR_BLUE, 255);
		if (fHP == 1.0)	g_fZombieNextStats[client][HP] = float(iHp);
		else g_fZombieNextStats[client][HP] = float(iHp)*fHP;
		g_fZombieNextStats[client][SPEED] = fSpeed;
		LogToGame("[ZH]  \"%N\"  Class: Knight,   HP: %d,   Movement: %0.2f,   Size: %0.2f", client, iHp, fSpeed, g_fZombieNextStats[client][SIZE]);

		switch(GetRandomInt(0, 6))
		{
			case 3:
			{
				FakeClientCommand(client, "inventory_buy_gear 2");
			}
			case 5:
			{
				FakeClientCommand(client, "inventory_buy_gear 4");
			}
		}
		FakeClientCommand(client, "inventory_resupply");
		return ZOMBIE_KNIGHT_INDEX;
	}
	else if (force_class == ZOMBIE_STALKER_INDEX)
	{
		if (CVAR_ZOMBIE_STALKER_RESTRICT != 0)
		{
			if (CVAR_ZOMBIE_STALKER_RESTRICT == 1 && IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
			else if (CVAR_ZOMBIE_STALKER_RESTRICT == 2 && !IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
		}
		g_iZombieClass[client][CLASS] = ZOMBIE_STALKER_INDEX;
		new iHp = CVAR_ZOMBIE_STALKER_BOT_HEALTH_MAX;
		new Float:fSpeed = FCVAR_ZOMBIE_STALKER_SPEED_MAX;
		if (IsBot)
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_STALKER_BOT_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_STALKER_BOT_HEALTH_MIN, CVAR_ZOMBIE_STALKER_BOT_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_STALKER_BOT_SPEED_MIN, FCVAR_ZOMBIE_STALKER_BOT_SPEED_MAX);
		}
		else
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_STALKER_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_STALKER_HEALTH_MIN, CVAR_ZOMBIE_STALKER_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_STALKER_SPEED_MIN, FCVAR_ZOMBIE_STALKER_SPEED_MAX);
		}
		g_fZombieNextStats[client][SIZE] = GetRandomFloat(FCVAR_ZOMBIE_STALKER_SIZE_MIN, FCVAR_ZOMBIE_STALKER_SIZE_MAX);
		SetEntityRenderColor(client, CVAR_ZOMBIE_STALKER_COLOR_RED, CVAR_ZOMBIE_STALKER_COLOR_GREEN, CVAR_ZOMBIE_STALKER_COLOR_BLUE, 255);
		if (fHP == 1.0)	g_fZombieNextStats[client][HP] = float(iHp);
		else g_fZombieNextStats[client][HP] = float(iHp)*fHP;
		g_fZombieNextStats[client][SPEED] = fSpeed;
		LogToGame("[ZH]  \"%N\"  Class: Stalker,   HP: %d,   Movement: %0.2f,   Size: %0.2f", client, iHp, fSpeed, g_fZombieNextStats[client][SIZE]);

		switch(GetRandomInt(0, 6))
		{
			case 3:
			{
				FakeClientCommand(client, "inventory_buy_gear 2");
			}
			case 5:
			{
				FakeClientCommand(client, "inventory_buy_gear 4");
			}
		}
		FakeClientCommand(client, "inventory_resupply");
		return ZOMBIE_STALKER_INDEX;
	}
	else if (force_class == ZOMBIE_BURNER_INDEX)
	{
		if (CVAR_ZOMBIE_BURNER_RESTRICT != 0)
		{
			if (CVAR_ZOMBIE_BURNER_RESTRICT == 1 && IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
			else if (CVAR_ZOMBIE_BURNER_RESTRICT == 2 && !IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
		}
		g_iZombieClass[client][CLASS] = ZOMBIE_BURNER_INDEX;
		new iHp = CVAR_ZOMBIE_BURNER_BOT_HEALTH_MAX;
		new Float:fSpeed = FCVAR_ZOMBIE_BURNER_SPEED_MAX;
		if (IsBot)
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_BURNER_BOT_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_BURNER_BOT_HEALTH_MIN, CVAR_ZOMBIE_BURNER_BOT_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_BURNER_BOT_SPEED_MIN, FCVAR_ZOMBIE_BURNER_BOT_SPEED_MAX);
		}
		else
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_BURNER_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_BURNER_HEALTH_MIN, CVAR_ZOMBIE_BURNER_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_BURNER_SPEED_MIN, FCVAR_ZOMBIE_BURNER_SPEED_MAX);
		}
		g_fZombieNextStats[client][SIZE] = GetRandomFloat(FCVAR_ZOMBIE_BURNER_SIZE_MIN, FCVAR_ZOMBIE_BURNER_SIZE_MAX);
		SetEntityRenderColor(client, CVAR_ZOMBIE_BURNER_COLOR_RED, CVAR_ZOMBIE_BURNER_COLOR_GREEN, CVAR_ZOMBIE_BURNER_COLOR_BLUE, 255);
		if (fHP == 1.0)	g_fZombieNextStats[client][HP] = float(iHp);
		else g_fZombieNextStats[client][HP] = float(iHp)*fHP;
		g_fZombieNextStats[client][SPEED] = fSpeed;
		LogToGame("[ZH]  \"%N\"  Class: Burner,   HP: %d,   Movement: %0.2f,   Size: %0.2f", client, iHp, fSpeed, g_fZombieNextStats[client][SIZE]);
//		IgniteEntity(client, 1.3);
		CreateTimer(0.5, SetupZombiesEffect, client, TIMER_FLAG_NO_MAPCHANGE);
		g_fBurnTime[client] = -1.0;

		switch(GetRandomInt(0, 6))
		{
			case 3:
			{
				FakeClientCommand(client, "inventory_buy_gear 2");
			}
			case 5:
			{
				FakeClientCommand(client, "inventory_buy_gear 4");
			}
		}
		FakeClientCommand(client, "inventory_resupply");
		return ZOMBIE_BURNER_INDEX;
	}
	else if (force_class == ZOMBIE_SMOKER_INDEX)
	{
		if (CVAR_ZOMBIE_SMOKER_RESTRICT != 0)
		{
			if (CVAR_ZOMBIE_SMOKER_RESTRICT == 1 && IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
			else if (CVAR_ZOMBIE_SMOKER_RESTRICT == 2 && !IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
		}
		g_iZombieClass[client][CLASS] = ZOMBIE_SMOKER_INDEX;
		new iHp = CVAR_ZOMBIE_SMOKER_BOT_HEALTH_MAX;
		new Float:fSpeed = FCVAR_ZOMBIE_SMOKER_SPEED_MAX;
		if (IsBot)
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_SMOKER_BOT_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_SMOKER_BOT_HEALTH_MIN, CVAR_ZOMBIE_SMOKER_BOT_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_SMOKER_BOT_SPEED_MIN, FCVAR_ZOMBIE_SMOKER_BOT_SPEED_MAX);
		}
		else
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_SMOKER_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_SMOKER_HEALTH_MIN, CVAR_ZOMBIE_SMOKER_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_SMOKER_SPEED_MIN, FCVAR_ZOMBIE_SMOKER_SPEED_MAX);
		}
		g_fZombieNextStats[client][SIZE] = GetRandomFloat(FCVAR_ZOMBIE_SMOKER_SIZE_MIN, FCVAR_ZOMBIE_SMOKER_SIZE_MAX);
		SetEntityRenderColor(client, CVAR_ZOMBIE_SMOKER_COLOR_RED, CVAR_ZOMBIE_SMOKER_COLOR_GREEN, CVAR_ZOMBIE_SMOKER_COLOR_BLUE, 255);
		if (fHP == 1.0)	g_fZombieNextStats[client][HP] = float(iHp);
		else g_fZombieNextStats[client][HP] = float(iHp)*fHP;
		g_fZombieNextStats[client][SPEED] = fSpeed;
		LogToGame("[ZH]  \"%N\"  Class: Smoker,   HP: %d,   Movement: %0.2f,   Size: %0.2f", client, iHp, fSpeed, g_fZombieNextStats[client][SIZE]);
//		IgniteEntity(client, 1.3);
		CreateTimer(0.5, SetupZombiesEffect, client, TIMER_FLAG_NO_MAPCHANGE);

		switch(GetRandomInt(0, 6))
		{
			case 3:
			{
				FakeClientCommand(client, "inventory_buy_gear 2");
			}
			case 5:
			{
				FakeClientCommand(client, "inventory_buy_gear 4");
			}
		}
		FakeClientCommand(client, "inventory_resupply");
		return ZOMBIE_SMOKER_INDEX;
	}
	else if (force_class == ZOMBIE_IED_INDEX)
	{
		if (CVAR_ZOMBIE_IED_RESTRICT != 0)
		{
			if (CVAR_ZOMBIE_IED_RESTRICT == 1 && IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
			else if (CVAR_ZOMBIE_IED_RESTRICT == 2 && !IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
		}
		if (GetRandomFloat(0.1, 100.00) <= FCVAR_ZOMBIE_IED_C4_CHANCE)
		{
			switch(GetRandomInt(0, 2))
			{
				case 0:	g_iZombieClass[client][VAR] = 72;	// C4
				case 1, 2:
				{
					if (GetRandomFloat(0.1, 100.00) <= FCVAR_ZOMBIE_IED_C4_BADASS_CHANCE)
						g_iZombieClass[client][VAR] = 6666;
					else g_iZombieClass[client][VAR] = 73;
				}
			}
		}
		else
		{
			switch(GetRandomInt(0, 5))
			{
				case 0, 1:	g_iZombieClass[client][VAR] = 66;	// 12;
				case 2, 3:	g_iZombieClass[client][VAR] = 67;	// 11;
				case 4, 5:	g_iZombieClass[client][VAR] = 68;	// M26A2
				case 6:		g_iZombieClass[client][VAR] = 69;	// Geballte Ladung
			}
		}
		g_iZombieClass[client][CLASS] = ZOMBIE_IED_INDEX;
		new iHp = CVAR_ZOMBIE_IED_BOT_HEALTH_MAX;
		new Float:fSpeed = FCVAR_ZOMBIE_IED_SPEED_MAX;
		if (IsBot)
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_IED_BOT_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_IED_BOT_HEALTH_MIN, CVAR_ZOMBIE_IED_BOT_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_IED_BOT_SPEED_MIN, FCVAR_ZOMBIE_IED_BOT_SPEED_MAX);
		}
		else
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_IED_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_IED_HEALTH_MIN, CVAR_ZOMBIE_IED_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_IED_SPEED_MIN, FCVAR_ZOMBIE_IED_SPEED_MAX);
		}
		g_fZombieNextStats[client][SIZE] = GetRandomFloat(FCVAR_ZOMBIE_IED_SIZE_MIN, FCVAR_ZOMBIE_IED_SIZE_MAX);
		SetEntityRenderColor(client, CVAR_ZOMBIE_IED_COLOR_RED, CVAR_ZOMBIE_IED_COLOR_GREEN, CVAR_ZOMBIE_IED_COLOR_BLUE, 255);
		if (fHP == 1.0)	g_fZombieNextStats[client][HP] = float(iHp);
		else g_fZombieNextStats[client][HP] = float(iHp)*fHP;
		g_fZombieNextStats[client][SPEED] = fSpeed;
		LogToGame("[ZH]  \"%N\"  Class: IED,   HP: %d,   Movement: %0.2f,   Size: %0.2f", client, iHp, fSpeed, g_fZombieNextStats[client][SIZE]);
//		IgniteEntity(client, 1.3);
//		CreateTimer(0.5, SetupZombiesEffect, client, TIMER_FLAG_NO_MAPCHANGE);

		switch(GetRandomInt(0, 6))
		{
			case 3:
			{
				FakeClientCommand(client, "inventory_buy_gear 2");
			}
			case 5:
			{
				FakeClientCommand(client, "inventory_buy_gear 4");
			}
		}
		FakeClientCommand(client, "inventory_resupply");
		return ZOMBIE_IED_INDEX;
	}
	else if (force_class == ZOMBIE_LEAPER_INDEX)
	{
		if (CVAR_ZOMBIE_LEAPER_RESTRICT != 0)
		{
			if (CVAR_ZOMBIE_LEAPER_RESTRICT == 1 && IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
			else if (CVAR_ZOMBIE_LEAPER_RESTRICT == 2 && !IsBot)
			{
				ZH_SetZombieClass(client, -1);
				return -2;
			}
		}
		g_iZombieClass[client][CLASS] = ZOMBIE_LEAPER_INDEX;
		new iHp = CVAR_ZOMBIE_LEAPER_BOT_HEALTH_MAX;
		new Float:fSpeed = FCVAR_ZOMBIE_LEAPER_SPEED_MAX;
		if (IsBot)
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_LEAPER_BOT_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_LEAPER_BOT_HEALTH_MIN, CVAR_ZOMBIE_LEAPER_BOT_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_LEAPER_BOT_SPEED_MIN, FCVAR_ZOMBIE_LEAPER_BOT_SPEED_MAX);
		}
		else
		{
			// g_fZombiePenaltyTimestamp[client] = GetGameTime()+FCVAR_ZOMBIE_LEAPER_PENALTY_TIME;
			iHp = GetRandomInt(CVAR_ZOMBIE_LEAPER_HEALTH_MIN, CVAR_ZOMBIE_LEAPER_HEALTH_MAX);
			fSpeed = GetRandomFloat(FCVAR_ZOMBIE_LEAPER_SPEED_MIN, FCVAR_ZOMBIE_LEAPER_SPEED_MAX);
		}
		g_fZombieNextStats[client][SIZE] = GetRandomFloat(FCVAR_ZOMBIE_LEAPER_SIZE_MIN, FCVAR_ZOMBIE_LEAPER_SIZE_MAX);
		SetEntityRenderColor(client, CVAR_ZOMBIE_LEAPER_COLOR_RED, CVAR_ZOMBIE_LEAPER_COLOR_GREEN, CVAR_ZOMBIE_LEAPER_COLOR_BLUE, 255);
		if (fHP == 1.0)	g_fZombieNextStats[client][HP] = float(iHp);
		else g_fZombieNextStats[client][HP] = float(iHp)*fHP;
		g_fZombieNextStats[client][SPEED] = fSpeed;
		LogToGame("[ZH]  \"%N\"  Class: Leaper,   HP: %d,   Movement: %0.2f,   Size: %0.2f", client, iHp, fSpeed, g_fZombieNextStats[client][SIZE]);

		switch(GetRandomInt(0, 6))
		{
			case 3:
			{
				FakeClientCommand(client, "inventory_buy_gear 2");
			}
			case 5:
			{
				FakeClientCommand(client, "inventory_buy_gear 4");
			}
		}
		FakeClientCommand(client, "inventory_resupply");
		return ZOMBIE_KNIGHT_INDEX;
	}

	LogError("[ZH]  There are no zombie class index for \"%d\"", force_class);
	ZH_SetZombieClass(client, -1);
	return -2;
}

stock void DamageOnClientKnockBack(client, attacker, Float:knockbackAmount)
{
	// If nemesis knockback disabled, then stop
	if (g_iGameState != 4 || !g_bUpdatedSpawnPoint)
		return;
	
	// Initialize vectors
	new Float:vClientLoc[3], Float:vEyeAngle[3], Float:vAttackerLoc[3];
	
	// Get victim's and attacker's position
	GetClientEyePosition(attacker, vAttackerLoc);
	GetClientEyeAngles(attacker, vEyeAngle);

	// Calculate knockback end-vector
	TR_TraceRayFilter(vAttackerLoc, vEyeAngle, MASK_ALL, RayType_Infinite, FilterPlayers);
	TR_GetEndPosition(vClientLoc);

	DamageOnClientKnockBackOrigin(client, vClientLoc, vAttackerLoc, knockbackAmount);
}

stock void DamageOnClientKnockBackOrigin(client, Float:vClientLoc[3], Float:vAttackerLoc[3], Float:knockbackAmount)
{
	// If nemesis knockback disabled, then stop
	if (g_iGameState != 4 || !g_bUpdatedSpawnPoint)
		return;
	
	// Initialize vectors
	new Float:vVelocity[3];

	// Get vector from the given starting and ending points
	MakeVectorFromPoints(vAttackerLoc, vClientLoc, vVelocity);
	
	// Normalize the vector (equal magnitude at varying distances)
	NormalizeVector(vVelocity, vVelocity);

	// Apply the magnitude by scaling the vector
	ScaleVector(vVelocity, knockbackAmount);
	// if (GetClientTeam(client) == TEAM_SURVIVORS)
	// {
		// #DEBUG
		// PrintToChatAll("B - vVelocity[2] = %0.2f", vVelocity[2]);
		// if (vVelocity[2] > 600.0) vVelocity[2] = 600.0;
		// else if (vVelocity[2] < 100.0) vVelocity[2] = 100.0;
		// PrintToChatAll("R - vVelocity[2] = %0.2f", vVelocity[2]);
	// }

	// Push the player
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
}

public bool:FilterPlayers(entity, contentsMask)
{
	// If entity is a player, continue tracing
	return !(1 <= entity <= MaxClients);
}

public bool:TraceEntityFilterSolid(entity, contentsMask, any:client)
//	return entity > 1 && entity != client;
	return entity > MaxClients;

public bool:TraceEntityFilterSolidIncludeClient(entity, contentsMask, any:prop)
{
//	PrintToChatAll("ent %d, contentsMask %d, prop %d", entity, contentsMask, prop);
	return entity > 0 && entity != prop;
}

stock TeleportOnSpawn_Sec(client, location = 0, target = -1)
{
	g_iTeleportOnSpawn[client] = 0;
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return false;

	if (location == 1)
	{
		new iTarget = g_iLastSpecTarget[client];
		if (iTarget < 1 || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		{
			iTarget = GetRandomPlayer(client, TEAM_SURVIVORS, true, true, false);
			g_iLastSpecTarget[client] = iTarget;
		}
		if (iTarget != -1)
			CreateTimer(0.1, Timer_TeleportOnSpawn_Sec, client, TIMER_FLAG_NO_MAPCHANGE);
		else
		{
			LogError("!!! %N is trying to teleport on teammate but there are none ._.");
			return false;
		}
		return true;
	}
	return false;
}

public Action:Timer_TeleportOnSpawn_Sec(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	new iTarget = g_iLastSpecTarget[client];
	if (iTarget < 1 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
		iTarget = GetRandomPlayer(client, TEAM_SURVIVORS, true, true, false);
	if (iTarget != -1)
	{
		decl Float:vPos[3];
		GetClientAbsOrigin(iTarget, vPos);
		vPos[2] += 6.0;
		TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
		PrintToChat(iTarget, "\x08%s%N \x01在你身边部署了！", GetPlayerChatColor(client), client);
	}
	return;
}

stock TeleportOnSpawn(client, location = 0, index = -1)
{
	g_iTeleportOnSpawn[client] = 0;
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_iNextSpawnPointsIndex < 0)
		return false;

	// -2: Previous CP Spawn, -1: Back Spawn, 0: Normal Spawn, 1: Near Spawn, 2: Far away Spawn
	index = GetRandomInt(0, g_iNextSpawnPointsIndex);
	TeleportEntity(client, g_vNextSpawnPoints[index], NULL_VECTOR, NULL_VECTOR);
	return true;
}

public Action:Event_PlayerSuppressed(Event event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsFakeClient(client))
	{
/*		if (g_fSuppressedTime[client] == 0.0 && g_iZombieClass[client][CLASS] < 30 && g_iZombieClass[client][CLASS] > -1 && GetRandomFloat(0.1, 100.00) <= FCVAR_BOT_SUPPRESSED_DUCK_CHANCE)
		{
			LogToGame("\"%N\" has get suppressed therefore ducking a while...", client);
			g_fSuppressedTime[client] = GetGameTime()+GetRandomFloat(4.0, 12.0);
//			SetEntProp(client, Prop_Data, "m_afButtonForced", (1<<2));
//			SetEntProp(client, Prop_Data, "m_afButtonDisabled", (1<<15));
			SetEntProp(client, Prop_Data, "m_bDuckToggled", 1);
//			SetEntProp(client, Prop_Data, "m_bDuckEnabled", 1);
		}	*/
	}
	else
	{
		g_fSuppressedTime[client] = GetGameTime();
	}

	if (attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == TEAM_SURVIVORS && GetClientTeam(client) == TEAM_ZOMBIES)
	{
		decl Float:distance, Float:targetpos[3], Float:pos[3];
		GetClientHeadOrigin(client, pos, 10.0);
		GetClientHeadOrigin(attacker, targetpos, 10.0);
		distance = GetVectorDistance(pos, targetpos)*0.01905; // meteres
//		PrintToChat(attacker, "Suppressed %N - %0.2fm", client, distance);
		if (distance >= 10.0 && distance <= 80.0)
		{
			new Handle:hTrace = TR_TraceRayFilterEx(pos, targetpos, MASK_SOLID, RayType_EndPoint, Filter_Not_Players);
			if (!TR_DidHit(hTrace))
			{
				new Handle:hData;
				g_hSuppressTimer[attacker] = CreateDataTimer(0.2, Timer_SuppressingTimer, hData, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(hData, GetClientUserId(attacker));
				WritePackCell(hData, GetClientUserId(client));
			}
			CloseHandle(hTrace);
		}
	}
	return Plugin_Continue;
}

public Action:Timer_SuppressingTimer(Handle:timer, Handle:hData)
{
	ResetPack(hData);
	new attacker = GetClientOfUserId(ReadPackCell(hData));
	if (IsClientInGame(attacker) && timer == g_hSuppressTimer[attacker] && GetGameTime()-g_fLastKillTime[attacker] >= FCVAR_PLAYER_YELL_COOLDOWN_MIN*2)
	{
		new client = GetClientOfUserId(ReadPackCell(hData));
		if (IsClientInGame(client) && IsPlayerAlive(client) && IsPlayerAlive(attacker))
			PlayerYell(attacker, 7, false, FCVAR_PLAYER_YELL_CHANCE_SUPPRESS);
	}
}

stock SetEntityGlowProp(entity, String:model[128], color[4], Float:distance)
{
	if (entity < 1 || !IsValidEntity(entity) || g_iGameState != 4) return false;

	// Create & set dynamic glow entity and give properties
	new iGlowEntity = CreateEntityByName("prop_dynamic_glow");
	if (iGlowEntity > MaxClients && IsValidEntity(iGlowEntity))
	{
		new Float:fOrigin[3], Float:fAngle[3];
		if (model[0] == '\0')
			return false;
		
		// Find the location of the weapon
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", fOrigin);
		GetEntPropVector(entity, Prop_Send, "m_angRotation", fAngle);
		DispatchKeyValue(iGlowEntity, "model", model);
		DispatchKeyValue(iGlowEntity, "disablereceiveshadows", "1");
		DispatchKeyValue(iGlowEntity, "disableshadows", "1");
		DispatchKeyValue(iGlowEntity, "solid", "0");
		DispatchKeyValue(iGlowEntity, "spawnflags", "256");
		SetEntProp(iGlowEntity, Prop_Send, "m_CollisionGroup", 11);
		
		// Spawn and teleport the entity
		DispatchSpawn(iGlowEntity);
		TeleportEntity(iGlowEntity, fOrigin, fAngle, NULL_VECTOR);

		// Give glowing effect to the entity
		SetEntProp(iGlowEntity, Prop_Send, "m_bShouldGlow", true);
		SetEntPropFloat(iGlowEntity, Prop_Send, "m_flGlowMaxDist", distance);

		SetVariantColor(color);
		AcceptEntityInput(iGlowEntity, "SetGlowColor");

		// Set the activator and group the entity
		SetVariantString("!activator");
		AcceptEntityInput(iGlowEntity, "SetParent", entity);
		AcceptEntityInput(iGlowEntity, "TurnOn");
		return true;
	}
	return false;
}

public Action:Event_ExplosiveDeployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsPlayerAlive(client))
	{
		new entity = GetEventInt(event, "entityid");
		if (entity > MaxClients && IsValidEntity(entity))
		{
			new String:sWeaponName[64];
			GetEntityClassname(entity, sWeaponName, sizeof(sWeaponName));
			if (!StrEqual(sWeaponName, "grenade_flare"))
			{
/*				new String:sModelPath[128];
				GetEntPropString(entity, Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
				if (sModelPath[0] == '\0')
				{
					new iWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
					if (iWeapon > MaxClients && IsValidEntity(iWeapon))
					{
						GetEntPropString(iWeapon, Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
						ReplaceString(sModelPath, sizeof(sModelPath), "v_nam_hafthohlladung", "w_hafthohlladung", true);
						ReplaceString(sModelPath, sizeof(sModelPath), "_sec", "", true);
						ReplaceString(sModelPath, sizeof(sModelPath), "_ins", "", true);
						ReplaceString(sModelPath, sizeof(sModelPath), "v_", "w_", true);
					}
				}
				if (GetClientTeam(client) == TEAM_SURVIVORS)
					SetEntityGlowProp(entity, sModelPath, {0, 191, 255, 255}, 800.0);
				else
					SetEntityGlowProp(entity, sModelPath, {255, 69, 0, 255}, 600.0);	*/
				if (!IsFakeClient(client))
				{
					decl String:sPrefix[18] = "正在扔";
					if (StrEqual(sWeaponName, "grenade_molotov")) sWeaponName = "燃烧瓶";
					else if (StrEqual(sWeaponName, "grenade_anm14")) sWeaponName = "AN-M14燃烧弹";
					else if (StrEqual(sWeaponName, "grenade_f1")) sWeaponName = "F1手雷";
					else if (StrEqual(sWeaponName, "grenade_m67")) sWeaponName = "M67手雷";
					else if (StrEqual(sWeaponName, "grenade_m26a2")) sWeaponName = "M26A2冲击弹";
					else if (StrEqual(sWeaponName, "grenade_geballteladung")) sWeaponName = "Geballte Ladung";
					else if (StrEqual(sWeaponName, "grenade_m84"))
					{
						LogMessage("%N is throwing a M84 Flashbang", client);
						LogToGame("%N is throwing a M84 Flashbang", client);
						sWeaponName = "M84 Flashbang";
					}
					else if (StrEqual(sWeaponName, "grenade_m18")) sWeaponName = "M18烟雾弹";
					else if (StrEqual(sWeaponName, "grenade_m18_impact")) sWeaponName = "M18烟雾榴弹";
					else if (StrEqual(sWeaponName, "grenade_rifle_enfield")){
						sPrefix = "正在发射";
						sWeaponName = "Enfield Grenade";
					}
					else if (StrEqual(sWeaponName, "grenade_hafthohlladung")){
						sPrefix = "Hafthohlladung";
						sWeaponName = "Planted";
					}
					else if (StrEqual(sWeaponName, "grenade_m203_he")){
						sPrefix = "正在发射";
						sWeaponName = "M203榴弹";
					}
					else if (StrEqual(sWeaponName, "grenade_m203_smoke")){
						sPrefix = "正在发射";
						sWeaponName = "M203烟雾弹";
					}
					else if (StrEqual(sWeaponName, "grenade_m203_incid")){
						sPrefix = "正在发射";
						sWeaponName = "M203燃烧弹";
					}
					else if (StrEqual(sWeaponName, "grenade_gp25_he")){
						sPrefix = "正在发射";
						sWeaponName = "GP-25榴弹";
					}
					else if (StrEqual(sWeaponName, "grenade_gp25_smoke")){
						sPrefix = "正在发射";
						sWeaponName = "GP-25烟雾弹";
					}
					else if (StrEqual(sWeaponName, "grenade_m79")){
						sPrefix = "正在发射";
						sWeaponName = "M79榴弹";
					}
					else if (StrEqual(sWeaponName, "grenade_m79_napalm")){
						sPrefix = "正在发射";
						sWeaponName = "M79燃烧弹";
					}
					else if (StrEqual(sWeaponName, "grenade_m79_smoke")){
						sPrefix = "正在发射";
						sWeaponName = "M79烟雾弹";
					}
					else if (StrEqual(sWeaponName, "rocket_rpg7")){
						sPrefix = "正在发射";
						sWeaponName = "RPG-7";
						PlayerYell(client, 4, true);
					}
					else if (StrEqual(sWeaponName, "rocket_at4")){
						// It can be m72 law too
						sPrefix = "正在发射";
						if (g_bWasFiredLAW[client]) sWeaponName = "M72 LAW";
						else sWeaponName = "AT-4";
						PlayerYell(client, 4, true);
					}
	/*				else if (StrEqual(sWeaponName, "grenade_flare")){
						sPrefix = "Firing";
						sWeaponName = "Flare";
					}	*/
					else if (StrEqual(sWeaponName, "healthkit")){
						sPrefix = "正在部署";
						sWeaponName = "医疗包";
					}
					else if (StrEqual(sWeaponName, "grenade_c4")){
						sPrefix = "";
//						sPrefix = "正在部署";
//						sWeaponName = "C4";
						RequestFrame(CheckPlantedC4, EntIndexToEntRef(entity));
					}
					else if (StrEqual(sWeaponName, "grenade_ied")){
						sPrefix = "扔";
						sWeaponName = "IED";
					}
//					CreateTimer(0.1, Timer_GrenadeYellCheck, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					if (sPrefix[0] != '\0') FakeClientCommand(client, "say %s %s!", sPrefix, sWeaponName);
				}
			}
//			else ClientCommand(client, "lastinv");
			else SwapWeaponToPrimary(client);
		}
	}
}

public CheckPlantedC4(any:entity)
{
	if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity))
	{
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		new Float:vVel[3];
		GetEntPropVector(entity, Prop_Data, "m_vecVelocity", vVel);
		if (vVel[0] == 0.0 && vVel[2] == 0.0)
		{
//			CreateTimer(0.0, Timer_C4, entity);
//			CreateTimer(0.1, Timer_C4, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
/*
			PrecacheModel("sprites/laser.vmt");
			new Float:vAngle[3], Float:vOrigin[3];
			new String:output[32], String:targetname[32];
			GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngle);
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vOrigin);
			
			new iBeam = CreateEntityByName("env_beam");
			Format(targetname, sizeof(targetname), "LuaCustomBeamTarget%d", iBeam);
			TeleportEntity(iBeam, vOrigin, vAngle, NULL_VECTOR);
			DispatchKeyValue(iBeam, "texture", "sprites/laser.vmt");
			DispatchKeyValue(iBeam, "targetname", "LuaCustomEnvBeam");
			DispatchKeyValue(iBeam, "TouchType", "4");
			DispatchKeyValue(iBeam, "LightningStart", beam);
			DispatchKeyValue(iBeam, "BoltWidth", "4.0");
			DispatchKeyValue(iBeam, "life", "0");
			DispatchKeyValue(iBeam, "rendercolor", "0 0 0");
			DispatchKeyValue(iBeam, "renderamt", "0");
			DispatchKeyValue(iBeam, "HDRColorScale", "1.0");
			DispatchKeyValue(iBeam, "decalname", "Bigshot");
			DispatchKeyValue(iBeam, "StrikeTime", "0");
			DispatchKeyValue(iBeam, "TextureScroll", "35");
			Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
			DispatchKeyValue(ent, "OnTouchedByEntity", tmp);   
			SetEntPropVector(ent, Prop_Data, "m_vecEndPos", end);
			SetEntPropFloat(ent, Prop_Data, "m_fWidth", 4.0);
			AcceptEntityInput(ent, "TurnOff");
			
			Format(output, sizeof(output), "%s,Kill,,0,-1", beam);
			DispatchKeyValue(ent, "OnBreak", output);
*/
			if (client > 0 && client <= MaxClients && IsClientInGame(client))
				FakeClientCommand(client, "say C4已布置！");
		}
		else if (client > 0 && client <= MaxClients && IsClientInGame(client))
			FakeClientCommand(client, "say 扔C4了！");
	}
}
/*
public Action:Timer_C4(Handle:timer, any:refentity)
{
	if (refentity != INVALID_ENT_REFERENCE && IsValidEntity(refentity) && g_iGameState == 4)
	{
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
*/
public Action:Event_GrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new entity = GetEventInt(event, "entityid");
	if (entity > MaxClients)
	{
		new String:sGrenadeName[48];
		GetEntityClassname(entity, sGrenadeName, sizeof(sGrenadeName));
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (!StrEqual(sGrenadeName, "grenade_flare"))
		{
			if (client > 0 && IsClientInGame(client))
			{
				if (GetClientTeam(client) != TEAM_SURVIVORS)
				{
					ReplaceString(sGrenadeName, sizeof(sGrenadeName), "grenade_", "", true);
					if (StrContains("molotov;anm14;m84;m18;m203_smoke;m203_incid;gp25_smoke;m79_napalm;m79_smoke;healthkit;ied;c4;badass_ied", sGrenadeName) == -1) // C4 and IED has removed due to detonate delay
					{
						new Float:xyz[3];
						xyz[0] = GetEventFloat(event, "x");
						xyz[1] = GetEventFloat(event, "y");
						xyz[2] = GetEventFloat(event, "z");
						for (new j = 0;j < MAXPLAYER; j++)
						{
							if (g_iPlayersList[j] == -1) continue;
							new i = g_iPlayersList[j];
							decl Float:distance, Float:targetpos[3];
							GetClientEyePosition(i, targetpos);
							distance = GetVectorDistance(xyz, targetpos)*0.01905; // meters
							if (distance <= 25.0)
							{
								new Float:amp = 25.0;
								new Float:fre = 30.0;
								if (distance <= 15.0)
								{
									amp = GetRandomFloat(25.0, 30.0);
									fre = GetRandomFloat(30.0, 35.0);
								}
								else{
									amp = GetRandomFloat(20.0, 25.0);
									fre = GetRandomFloat(30.0, 35.0);
								}
								if (i != client)
									PlayerYell(i, 3, true, FCVAR_PLAYER_YELL_CHANCE_GRENADE, _, FCVAR_PLAYER_YELL_COOLDOWN_MIN);
								ClientScreenShake(i, SHAKE_START, amp, fre, GetRandomFloat(1.50, 2.00));
							}
						}
					}
				}
			}
		}
		else
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
					g_iPlayerBonusScore[client] += 200;
					g_fUAVLastTime = GetGameTime();
				}
/*				else if (IsRecon(client))
				{
					g_iUAVCount += GetConVarInt(g_hCvarUAVCounts);
					FakeClientCommand(client, "say UAV EXTENDED!");
					LogToGame("%N has extended UAV", client);
				}	*/
			}
		}
	}
}

public Action:Timer_UAVOnline(Handle:timer, any:client)
{
	if (g_bUAVOnline && g_hUAVTimer != INVALID_HANDLE)
	{
		if (g_iUAVCount > 0)
		{
			g_iUAVCount--;
			for (new target = 1; target <= MaxClients; target++)
			{
				if (IsClientInGame(target) && GetClientTeam(target) == TEAM_ZOMBIES && IsPlayerAlive(target))
				{
					g_iPlayerStatus[target] |= STATUS_INUAVRADAR;
					if (g_iPlayerStatus[target] == 0 || g_iPlayerStatus[target] & ~STATUS_INPORTABLERADAR)
						SetEntProp(target, Prop_Send, "m_bGlowEnabled", 1);
					EmitSoundToAll("ui/sfx/ringing_04.wav", target, _, _, _, 1.0);
				}
			}
			CreateTimer(1.5, Timer_UAVOnline_GlowOff, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			for (new target = 1; target <= MaxClients; target++)
			{
				if (IsClientInGame(target) && target != g_iPointFlagOwner && GetClientTeam(target) == TEAM_ZOMBIES && IsPlayerAlive(target))
					SetEntProp(target, Prop_Send, "m_bGlowEnabled", 0);
			}
			g_iUAVCount = 0;
			KillTimer(timer);
			g_hUAVTimer = INVALID_HANDLE;
			g_bUAVOnline = false;
			if (IsClientInGame(client) && IsPlayerAlive(client) && g_iGameState == 4)
				FakeClientCommand(client, "say 无人机已下线！");
		}
	}
	else
	{
		for (new target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target) && target != g_iPointFlagOwner && GetClientTeam(target) == TEAM_ZOMBIES && IsPlayerAlive(target))
				SetEntProp(target, Prop_Send, "m_bGlowEnabled", 0);
		}
		g_iUAVCount = 0;
		KillTimer(timer);
		g_hUAVTimer = INVALID_HANDLE;
		g_bUAVOnline = false;
		if (IsClientInGame(client) && IsPlayerAlive(client) && g_iGameState == 4)
			FakeClientCommand(client, "say 无人机已下线！");
	}
}

public Action:Timer_UAVOnline_GlowOff(Handle:timer)
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target) && target != g_iPointFlagOwner && GetClientTeam(target) == TEAM_ZOMBIES && IsPlayerAlive(target))
		{
			g_iPlayerStatus[target] &= ~STATUS_INUAVRADAR;
			if (g_iPlayerStatus[target] == 0 || g_iPlayerStatus[target] & ~STATUS_INPORTABLERADAR)
			{
//				PrintToChatAll("%N is off %d (%d)", target, g_iPlayerStatus[target], g_iPlayerStatus[target] & STATUS_INPORTABLERADAR);
				SetEntProp(target, Prop_Send, "m_bGlowEnabled", 0);
			}
		}
	}
}

public Action:Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
	{
		LogMessage("%N is blinded!", client);
		LogToGame("%N is blinded!", client);
	}
}

public Action:Event_MissileDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new rocket = GetEventInt(event, "id");
	if (rocket == 14 || rocket == 15) // AT4 (M72 LAW) || RPG-7
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client > 0 && IsClientInGame(client) && GetClientTeam(client) != TEAM_SURVIVORS)
		{
			new Float:xyz[3];
			xyz[0] = GetEventFloat(event, "x");
			xyz[1] = GetEventFloat(event, "y");
			xyz[2] = GetEventFloat(event, "z");
			for (new j = 0;j < MAXPLAYER; j++)
			{
				if (g_iPlayersList[j] == -1) continue;
				new i = g_iPlayersList[j];
				decl Float:distance, Float:targetpos[3];
				GetClientEyePosition(i, targetpos);
				distance = GetVectorDistance(xyz, targetpos)*0.01905; // meters
				if (distance <= 30.0)
				{
					new Float:amp = 25.0;
					new Float:fre = 30.0;
					if (distance <= 20.0)
					{
						amp = GetRandomFloat(45.0, 50.0);
						fre = GetRandomFloat(80.0, 100.0);
					}
					else
					{
						amp = GetRandomFloat(25.0, 30.0);
						fre = GetRandomFloat(50.0, 70.0);
					}
					if (i != client) PlayerYell(i, 3, true, FCVAR_PLAYER_YELL_CHANCE_ROCKET, _, FCVAR_PLAYER_YELL_COOLDOWN_MIN);
					ClientScreenShake(i, SHAKE_START, amp, fre, GetRandomFloat(1.25, 2.00));
				}
			}
		}
	}
}

public Action:Event_FlagPickUp(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new iTeam = GetClientTeam(client);
	g_iPointFlagOwner = client;
	g_fFlagDropTime = 0.0;
	LogToGame("Point Flag %d Picked up by \"%N\" (team: %d)", g_iPointFlag, client, iTeam);

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
	if (iTeam == TEAM_ZOMBIES)
	{
		if (!g_bDoNotPlayFlagPickUp)
		{
			if (g_sFlagSoundLast[0] != '\0') StopSoundAll(g_sFlagSoundLast, SNDCHAN_STATIC);
			Format(g_sFlagSoundLast, sizeof(g_sFlagSoundLast), "hq/security/theytook%d.ogg", GetRandomInt(1, 10));
			EmitSoundToAll(g_sFlagSoundLast, _, SNDCHAN_STATIC, _, _, 1.0);
//			PlayGameSoundToAll("Player.Security_Infiltration_InsTookIntel");	//	Ins pickup
		//	hq/security/theytook1~10.ogg
		}
		else g_bDoNotPlayFlagPickUp = false;
	}
	else
	{
		if (IsFakeClient(client))
		{
			new Float:vBotPos[3];
			GetClientAbsOrigin(client, vBotPos);
			vBotPos[2] += 2.0;
//			SDKCall(g_hPlayerRespawn, client);
			new Float:vFlagPos[3], Float:vTargetPos[3], Float:fDistance, Float:fNearestDistance = 99999.0;//, Float:vNearest[3] = {-9000.0, 0.0, 0.0};
			new iNearest = -1;
			GetEntPropVector(g_iPointFlag, Prop_Data, "m_vecAbsOrigin", vFlagPos);
			for (new j = 0;j < MAXPLAYER; j++)
			{
				if (g_iPlayersList[j] == -1 || !IsPlayerAlive(g_iPlayersList[j]))
					continue;
				new i = g_iPlayersList[j];
				GetClientAbsOrigin(i, vTargetPos);
				fDistance = GetVectorDistance(vTargetPos, vFlagPos);
				if (fDistance <= fNearestDistance)
				{
					iNearest = i;
//					vNearest[0] = vTargetPos[0];
//					vNearest[1] = vTargetPos[1];
//					vNearest[2] = vTargetPos[2];
					fNearestDistance = fDistance;
				}
			}
			LogToGame("Bot %N picked up %d flag, Kill or force to capture", client, g_iPointFlag);
			if (iNearest != -1)
			{
				// PrintToServer("Removing #9");
				if (g_iPointFlag != INVALID_ENT_REFERENCE && IsValidEntity(g_iPointFlag))
					RequestFrame(DeleteEntity, EntIndexToEntRef(g_iPointFlag));
//					AcceptEntityInput(g_iPointFlag, "Kill");
//				vNearest[2] += 10.0;
				CreatePointFlag(iNearest, false);
//				TeleportEntity(g_iPointFlag, vNearest, NULL_VECTOR, NULL_VECTOR);
//				TeleportEntity(client, vBotPos, NULL_VECTOR, NULL_VECTOR);
			}
			else
			{
				if (!g_bMedicPlayer[client])
					SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
				g_iPointFlag = INVALID_ENT_REFERENCE;
				g_iPointFlagSpawnGlow = INVALID_ENT_REFERENCE;
				g_iPointFlagOwner = -1;
				PlayGameSoundToAll("Player.Security_Infiltration_SecCapturedIntel");
				
				decl Float:vPos[3];
				GetEntPropVector(g_iCPIndex[g_iCurrentControlPoint], Prop_Data, "m_vecAbsOrigin", vPos);
				SetEntData(g_iCPIndex[g_iCurrentControlPoint], g_iOffsetWeaponCacheGlow, 1);
				vPos[2] += 2000.0;
				TeleportEntity(g_iCPIndex[g_iCurrentControlPoint], vPos, NULL_VECTOR, NULL_VECTOR);
				FakeClientCommand(client, "say 情报已获取！ (Bots only remain)");
			}
			return Plugin_Continue;
		}
		if (g_iPointFlagSpawnGlow == INVALID_ENT_REFERENCE)
		{
			CreatePointFlagSpawnGlow(client, true);
		}
		else
		{
			SetEntProp(g_iPointFlagSpawnGlow, Prop_Send, "m_bShouldGlow", true);
		}
		if (g_sFlagSoundLast[0] != '\0') StopSoundAll(g_sFlagSoundLast, SNDCHAN_STATIC);
		Format(g_sFlagSoundLast, sizeof(g_sFlagSoundLast), "hq/security/wetook%d.ogg", GetRandomInt(1, 10));
		EmitSoundToAll(g_sFlagSoundLast, _, SNDCHAN_STATIC, _, _, 1.0);
		DisplayInstructorHint(client, 8.0, 0.0, 0.0, true, true, "icon_tip", "icon_tip", "", true, {255, 255, 255}, "返回基地并获取情报！");
//		PlayGameSoundToAll("Player.Security_Infiltration_SecTookIntel");		//	Sec pickup
//		hq/security/wetook1~10.ogg
		g_bDoNotPlayFlagPickUp = false;
	}
	return Plugin_Continue;
}

public Action:Event_FlagDrop(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new iTeam = GetClientTeam(client);
	g_iPointFlagOwner = -1;
	g_fFlagDropTime = GetGameTime();
	LogToGame("Point Flag %d Dropped from \"%N\" (team: %d)", g_iPointFlag, client, iTeam);

	if (IsClientInGame(client) && g_bMedicPlayer[client])
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	if (iTeam == TEAM_ZOMBIES)
	{
		if (g_sFlagSoundLast[0] != '\0') StopSoundAll(g_sFlagSoundLast, SNDCHAN_STATIC);
		Format(g_sFlagSoundLast, sizeof(g_sFlagSoundLast), "hq/security/wekilled%d.ogg", GetRandomInt(1, 10));
		EmitSoundToAll(g_sFlagSoundLast, _, SNDCHAN_STATIC, _, _, 1.0);
//		PlayGameSoundToAll("Player.Security_Infiltration_KilledCarrier");	//	Ins drop
		//	hq/security/wekilled1~10.ogg
	}
	else
	{
		if (g_iPointFlagSpawnGlow == INVALID_ENT_REFERENCE)
		{
			CreatePointFlagSpawnGlow(-1, false);
		}
		else
		{
			SetEntProp(g_iPointFlagSpawnGlow, Prop_Send, "m_bShouldGlow", false);
		}
		if (g_sFlagSoundLast[0] != '\0') StopSoundAll(g_sFlagSoundLast, SNDCHAN_STATIC);
		Format(g_sFlagSoundLast, sizeof(g_sFlagSoundLast), "hq/security/friendlycarrierdead%d.ogg", GetRandomInt(1, 10));
		EmitSoundToAll(g_sFlagSoundLast, _, SNDCHAN_STATIC, _, _, 1.0);
//		PlayGameSoundToAll("Player.Security_Infiltration_CarrierDead");		//	Sec drop
	}
		//	hq/security/friendlycarrierdead1~10.ogg
	return Plugin_Continue;
}

stock StopSoundAll(const String:sound[], channel = SNDCHAN_AUTO)
{
	if (sound[0] == '\0') return;

	for (new j = 0;j < MAXPLAYER; j++)
	{
		if (g_iPlayersList[j] == -1) continue;
		StopSound(g_iPlayersList[j], channel, sound);
	}
	return;
}

public OnClientPostAdminCheck(client)
{
	if (!IsFakeClient(client)){
		if (!GetAdminFlag(GetUserAdmin(client), Admin_Root)) CreateTimer(90.0, CheckSpec, client, TIMER_FLAG_NO_MAPCHANGE);
		else CreateTimer(1.0, MoveToSpec, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:MoveToSpec(Handle:timer, any:client)
	if (IsClientInGame(client))
		ChangeClientTeam(client, 1);

public Action:CheckSpec(Handle:timer, any:client)
{
	if (IsClientInGame(client) && WelcomeToTheCompany[client] == 0 && !IsFakeClient(client)){
		ChangeClientTeam(client, 1);
		PrintToChat(client, "\x08%s因挂机时间太长，你已被移动到观察者", COLOR_VALVE);
	}
}

public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)
{
	PlayGameSoundToAll("Inventory.MouseOver");	//	Inventory.MouseClick
}

public SHook_WeaponSwitch(client, weapon)
{
	if (g_iPlayerFirstDeployCheck[client] != -1 && weapon != g_iPlayerFirstDeployCheck[client])
	{
		if (IsValidEntity(g_iPlayerFirstDeployCheck[client]) && GetGameTime() < g_fPlayerFirstDeployTimestamp[client])
			SetEntData(g_iPlayerFirstDeployCheck[client], g_iOffsetFirstDeploy, 1);
		g_iPlayerFirstDeployCheck[client] = -1;
	}
	if (GetEntData(weapon, g_iOffsetFirstDeploy) == 1)
		g_iPlayerFirstDeployCheck[client] = weapon;
	else g_iPlayerFirstDeployCheck[client] = -1;
}

public Action:Event_WeaponDeploy(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iPlayerDeployedWeapon[client] = GetEventInt(event, "weaponid");
	if (!IsFakeClient(client))
	{
		new iWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if (iWeapon == g_iPlayerFirstDeployCheck[client])
			g_fPlayerFirstDeployTimestamp[client] = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack")-0.5;
	}
	if (g_fPlayerTempPropTimestamp[client] != 0.0 && g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]))
	{
		decl String:targetname[64];
		GetEntPropString(g_iPlayerTempProp[client], Prop_Data, "m_iName", targetname, sizeof(targetname));
		if (StrEqual(targetname, "LuaCustomModel", true))
		{
			LogToGame("%N is installing gear id %d but swaped weapon before complete %d", client, g_iPlayerCustomGear[client], g_iPlayerTempProp[client]);
			RequestFrame(DeleteEntity, EntIndexToEntRef(g_iPlayerTempProp[client]));
			g_iPlayerTempProp[client] = -1;
			g_fPlayerTempPropTimestamp[client] = 0.0;
			g_bPlayerTempPropSetup[client] = false;
			PrintCenterText(client, " ");
		}
	}
	if (g_iPlayerDeployedWeapon[client] == WEAPON_HEALTHKIT)	// #Deployed weapon_healthkit (40)
	{
		if (g_bUpdatedSpawnPoint)
		{
			new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (iWeapon > MaxClients && IsValidEntity(iWeapon))
			{
				if (Healthkit_CheckHealing(client) != 2)
				{
					g_fPlayerHealthkitBandaging[client] = 0.0;
					g_iPlayerHealthkitDeploy[client] = iWeapon;
					g_fPlayerWeaponBlocked[client] = -1.0;
				}
				else
				{
					g_iPlayerDeployedWeapon[client] = -1;
					SwapWeaponToPrimary(client);
				}
			}
			else
			{
				LogError("\"%N\" is deploy weapon healthkit but ActiveWeapon (%d) is not valid", client, iWeapon);
				PrintToChat(client, "\x08%sSomethings wrong", COLOR_RED);
				g_fPlayerWeaponBlocked[client] = 0.0;
				g_iPlayerHealthkitDeploy[client] = -1;
				SwapWeaponToPrimary(client);
			}
		}
		else
		{
			g_iPlayerDeployedWeapon[client] = -1;
			SwapWeaponToPrimary(client);
		}
	}
	else
	{
		g_fPlayerWeaponBlocked[client] = 0.0;
		if (g_iPlayerHealthkitTarget[client] != -1)
		{
			g_iPlayerHealthkitHealingBy[g_iPlayerHealthkitTarget[client]] = -1;
			g_iPlayerHealthkitTarget[client] = -1;
		}
		g_iPlayerHealthkitDeploy[client] = -1;
		if (Healthkit_CheckHealing(client) != 2 && g_fPlayerHealthkitBandaging[client] != 0.0)
		{
			g_fPlayerHealthkitBandaging[client] = 0.0;
		}
		if (g_iPlayerDeployedWeapon[client] == WEAPON_FLAREGUN)	// #Deployed weapon_p2a1 flaregun (121)
		{
			if (g_fUAVLastTime != 0.0)
			{
				if (g_fGameTime >= g_fUAVLastTime+FCVAR_PLAYER_RECON_UAV_COOLDOWN)
					g_fUAVLastTime = 0.0;
				else
				{
					new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
					if (iWeapon > MaxClients && IsValidEntity(iWeapon))
					{
						g_fPlayerWeaponBlocked[client] = g_fUAVLastTime+FCVAR_PLAYER_RECON_UAV_COOLDOWN;
						ClientCommand(client, "invprev");
					}
					else SwapWeaponToPrimary(client);
					PrintToChat(client, "\x05无人机 \x01在 \x08%s%0.1f 秒内冷却完毕", COLOR_SALMON, (FCVAR_PLAYER_RECON_UAV_COOLDOWN+g_fUAVLastTime)-g_fGameTime);
				}
			}
		}
		else
		{
			if (g_iPlayerDeployedWeapon[client] == WEAPON_LAW)	// #Deployed weapon_law rocket launcher (47)
				g_bWasFiredLAW[client] = true;
			else if (g_iPlayerDeployedWeapon[client] == WEAPON_AT4)	// #Deployed weapon_at4 rocket launcher(3)
				g_bWasFiredLAW[client] = false;
		}
	}
}
/*
stock GetViewModelIndex(client) 
{ 
	new ent = MaxClients+1;
	while ((ent = FindEntityByClassname(ent, "predicted_viewmodel")) != -1)
	{
		new Owner = GetEntPropEnt(ent, Prop_Send, "m_hOwner");
		if (Owner != client)
			continue; 
         
		return EntIndexToEntRef(ent);
	}
	return -1;
}
*/

stock bool:Healthkit_HasHolding(client)
{
	return bool:(g_iPlayerHealthkitDeploy[client] > MaxClients && IsValidEntity(g_iPlayerHealthkitDeploy[client]));
}

stock Healthkit_CheckHealing(client)
{
	if (g_iPlayerHealthkitTarget[client] > 0 && g_iPlayerHealthkitTarget[client] != client)
	{
		new target = g_iPlayerHealthkitTarget[client];
		if (IsClientInGame(target) && IsPlayerAlive(target) && g_iPlayerHealthkitHealingBy[target] == client && g_fPlayerHealthkitBandaging[target] != 0.0 && GetEntityFlags(target) & FL_ONGROUND && GetEntityFlags(client) & FL_ONGROUND)
			return 1;
	}

	if (g_fPlayerHealthkitBandaging[client] != 0.0)
	{
		if (g_iPlayerHealthkitTarget[client] == client && g_iPlayerHealthkitHealingBy[client] == client && GetEntityFlags(client) & FL_ONGROUND)
			return 0;
		else if (g_iPlayerHealthkitHealingBy[client] > 0 && g_iPlayerHealthkitTarget[client] != client)
		{
			new healer = g_iPlayerHealthkitHealingBy[client];
			if (IsClientInGame(healer) && IsPlayerAlive(healer) && g_iPlayerHealthkitTarget[healer] == client && GetEntityFlags(healer) & FL_ONGROUND && GetEntityFlags(client) & FL_ONGROUND)
				return 2;
		}
	}
	return -1;
}

stock bool:Healthkit_CheckCondition(client, bool:medic, hp)
{
	if (g_iPlayerBleeding[client] != 0 || g_iPlayerInfected[client] != 0)
		return true;

	if (!medic)
	{
		if (hp < CVAR_PLAYER_HEALTHKIT_MIN_HEALTH)
			return true;
	}
	else
	{
		if (hp < CVAR_PLAYER_HEALTHKIT_MEDIC_MIN_HEALTH)
			return true;
	}
	return false;
}

public Action:Event_WeaponHolster(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iWeaponId = GetEventInt(event, "weaponid");
	if (iWeaponId == WEAPON_HEALTHKIT)	// #Holstered weapon_healthkit (40)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		g_iPlayerHealthkitDeploy[client] = -1;
		new iCheckHealing = Healthkit_CheckHealing(client);
		if (iCheckHealing == 0)
		{
			PrintCenterText(client, " ");
			g_fPlayerHealthkitBandaging[client] = 0.0;
			g_iPlayerHealthkitTarget[client] = -1;
			g_iPlayerHealthkitHealingBy[client] = -1;
		}
		else if (iCheckHealing == 1)
		{
			PrintCenterText(client, " ");
			g_fPlayerHealthkitBandaging[g_iPlayerHealthkitTarget[client]] = 0.0;
			g_iPlayerHealthkitHealingBy[g_iPlayerHealthkitTarget[client]] = -1;
			PrintCenterText(g_iPlayerHealthkitTarget[client], " ");
			g_iPlayerHealthkitTarget[client] = -1;
		}
	}
}

public Action:AimPunchReset(Handle:timer, any:attacker)
{
	if (attacker > 0 && IsClientInGame(attacker) && g_hFFTimer[attacker] == timer)
	{
		g_hFFTimer[attacker] = INVALID_HANDLE;
		SetEntPropVector(attacker, Prop_Send, "m_aimPunchAngle", Float:{0.0, 0.0, 0.0});
		SetEntPropVector(attacker, Prop_Send, "m_aimPunchAngleVel", Float:{0.0, 0.0, 0.0});
	}
}

public Action:Timer_ResetKillNotice(Handle:timer)
	g_bKillNoticePlayed = false;

public Action:Timer_MoveToSurvivors(Handle:timer, any:client)
{
	if (IsClientInGame(client)) ChangeClientTeam(client, TEAM_SURVIVORS);
}

public Action:Timer_LostMedic(Handle:timer, any:client)
{
	if (IsClientInGame(client)) PrintToChatAll("\x01玩家 \x08%s%N \x01已丧失 \x08%s医疗资格", GetPlayerChatColor(client), client, COLOR_GOLD);
}

public Action:Event_PlayerDeath(Event event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:sWeaponName[64];
	GetEventString(event, "weapon", sWeaponName, sizeof(sWeaponName));
	new aTeam = -1;
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
	{
		aTeam = GetClientTeam(attacker);
/*		if (aTeam == TEAM_ZOMBIES && !g_bKillNoticePlayed && GetClientTeam(client) == TEAM_SURVIVORS)
		{
			if (StrContains(sWeaponName, "grenade", false) != -1 || StrContains(sWeaponName, "rocket", false) != -1 || StrContains(sWeaponName, "flame", false) != -1)
			{
	//			hq/coop/counterattackstart.ogg @ 6, 8, 13
				g_bKillNoticePlayed = true;
				switch(GetRandomInt(1, 5))
				{
					case 1:	EmitSoundToAll("hq/coop/counterattackstart6.ogg", _, _, _, _, 1.0);
					case 2:	EmitSoundToAll("hq/coop/counterattackstart8.ogg", _, _, _, _, 1.0);
					case 3:	EmitSoundToAll("hq/coop/counterattackstart13.ogg", _, _, _, _, 1.0);
					case 4:	EmitSoundToAll("hq/outpost/outpost_cachedestroyed10.ogg", _, _, _, _, 1.0);
					case 5:	EmitSoundToAll("hq/security/theycaptured10.ogg", _, _, _, _, 1.0);
				}
				CreateTimer(1.5, Timer_ResetKillNotice, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}	*/
	}

//	if (GetClientTeam(client) > TEAM_SPECTATOR)
	if (GetClientTeam(client) == TEAM_SURVIVORS)
	{
		ClientCommand(client, "playgamesound Lua_sounds/zombiehorde/survivors/death.ogg");
		if (g_bMedicForceToChange[client] && g_bMedicPlayer[client])
		{
			g_bMedicPlayer[client] = false;
			g_fMedicBannedTime[client] = GetGameTime()+300.0;
/*			g_bHasSquad[client] = false;
			new bool:bClassSlots[2][5];
			bClassSlots[1][0] = true;
			for (new i = 0;i < MAXPLAYER;i++)
			{
				if (g_iPlayersList[i] == -1 || !IsClientInGame(g_iPlayersList[i]) || g_iPlayersList[i] == client || !g_bHasSquad[g_iPlayersList[i]])
					continue;

				bClassSlots[GetPlayerSquad(g_iPlayersList[i], g_iPlayerManager, g_iOffsetSquad)][GetPlayerSquadSlot(g_iPlayersList[i], g_iPlayerManager, g_iOffsetSquadSlot)] = true;
			}
			for (new s = 0;s <= 1;s++)
			{
				for (new b = 0;b <= 4;b++)
				{
					if (!bClassSlots[s][b])
					{
						ClientCommand(client, "joinsquad %d %d", s, b);
						g_bHasSquad[client] = true;
						break;
					}
				}
				if (g_bHasSquad[client])
					break;
			}
			if (!g_bHasSquad[client])
			{
				ChangeClientTeam(client, TEAM_SPECTATOR);
				PrintToChatAll("\x08%s%N \x01has been moved to spectator due to not healing teammate as \x08%sMedic", GetPlayerChatColor(client), client, COLOR_GOLD);
			}
			else PrintToChatAll("\x08%s%N \x01has been changed class due to not healing teammate as \x08%sMedic", GetPlayerChatColor(client), client, COLOR_GOLD);	*/
			ChangeClientTeam(client, TEAM_SPECTATOR);
			CreateTimer(0.1, Timer_MoveToSurvivors, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.11, Timer_LostMedic, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		if (g_fPlayerHealthkitBandaging[client] != 0.0)
		{
			PrintCenterText(client, " ");
//			SetEntityMoveType(client, MOVETYPE_WALK);
			// StopSound(client, SNDCHAN_STATIC, "Lua_sounds/bandaging.wav");
			g_fPlayerHealthkitBandaging[client] = 0.0;
		}
		if (attacker == client || aTeam != TEAM_SURVIVORS)
		{
			if (!g_bKillNoticePlayed)
			{
				g_bKillNoticePlayed = true;
				PlayGameSoundToAll("Player.Security_Hunt_ManDown", client);
				CreateTimer(1.5, Timer_ResetKillNotice, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Handler_MedicMenu(Handle:menu, MenuAction:action, client, select)
{
	if (action == MenuAction_Select)
	{
		if (select != 3)
		{
			decl String:language[64];
			GetClientInfo(client, "cl_language", language, sizeof(language));
			new Handle:panel = CreatePanel();
			if (StrContains(language, "korea", false) == -1)
			{
				SetPanelTitle(panel, "你正在扮演 [医疗兵]");
				DrawPanelText(panel, " ");
				DrawPanelItem(panel, "使用[医疗包]来治疗你的队友 (3号槽位)");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "请注意[有光圈的队友]");
				DrawPanelItem(panel, "他们已受伤并需要你的治疗！");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "如果你在5分钟之内不治疗队友，你的职业将会被强制变更");
				DrawPanelItem(panel, "确认并关闭");
			}
			else
			{
				SetPanelTitle(panel, "당신은 지금  [메딕] 병과로 플레이 중입니다");
				DrawPanelText(panel, " ");
				DrawPanelItem(panel, "[First Aid] 를 사용해 아군을 치료하세요  (3번 슬롯)");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "[빛나는 플레이어] 들을 주시하세요");
				DrawPanelItem(panel, "그러한 플레이어들은 치료가 필요합니다 !");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, " ");
				DrawPanelText(panel, "5분 넘게 아군을 치료하지 않을 경우 강제로 병과가 변경됩니다.");
				DrawPanelItem(panel, "확인 및 닫기");
			}
			SendPanelToClient(panel, client, Handler_MedicMenu, 0);
			CloseHandle(panel);
		}
		else FakeClientCommand(client, "use weapon_healthkit");
	}
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}

stock Client_RemoveAllWeapons2(client, const String:exclude[]="")
{
	if (g_iOffsetMyWeapons == -1 || !IsClientInGame(client) || !IsPlayerAlive(client)) return -1;

	new numWeaponsRemoved = 0;
	for (new i = 0;i < 48;i++)
	{
		new weapon = GetEntDataEnt2(client, g_iOffsetMyWeapons+(4*i));
		if (weapon == -1) break;

		if (!IsValidEntity(weapon) || weapon <= MaxClients)
			continue;

		new String:classname[64];
		GetEntityClassname(weapon, classname, sizeof(classname));
		if (exclude[0] != '\0' && StrEqual(classname, exclude, false))
		{
			FakeClientCommand(client, "use %s", exclude);
			continue;
		}

		// PrintToServer("Removing #11");
		LogToGame("%d. Weapon \"%s\" has been removed from %N", weapon, classname, client);
//		AcceptEntityInput(weapon, "kill");
		RequestFrame(DeleteEntity, EntIndexToEntRef(weapon));

		numWeaponsRemoved++;
	}
	return numWeaponsRemoved;
}

public Action:Timer_InfectedSurvivorDied(Handle:timer, any:client)
{
	if (g_iGameState != 4 || g_fDeathOrigin[client][0] == 0.0) return;
	
	new iZombie = GetRandomPlayer(client, TEAM_ZOMBIES, true, true, false);
	if (iZombie > -1)
		TeleportEntity(iZombie, g_fDeathOrigin[client], NULL_VECTOR, Float:{0.0, 0.0, 0.0});
	g_fDeathOrigin[client][0] = 0.0;
}

public Action:Event_PlayerDeathPre(Event event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	LogToGame("%N is Dead", client);
	if (g_fPlayerDrugTime[client] != 0.0)
	{
		g_fPlayerDrugTime[client] = 0.0;
	}
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new iAttackerTeam = (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))?GetClientTeam(attacker):-1;
	g_fSuppressedTime[client] = 0.0;
//	SetEntProp(client, Prop_Data, "m_bDuckToggled", 0);
	g_bIsInCaptureZone[client] = false;
	new String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

/*	if (g_iEntityCount >= 1800)
	{
		LogToGame("Too many entities spawned therefore remove weapons when player died (%N)", client);
		Client_RemoveAllWeapons2(client, "weapon_kabar");
	}	*/
	new iTeam = GetClientTeam(client);
	if (iTeam == TEAM_SURVIVORS)
	{
//		RemoveCustomFlags(client);
/*		if (g_iPlayerHasHelmet[client] != INVALID_ENT_REFERENCE)
		{
			SetVariantString("OnUser1 !self:kill::10.0:1");
			AcceptEntityInput(g_iPlayerHasHelmet[client], "AddOutput");
			AcceptEntityInput(g_iPlayerHasHelmet[client], "FireUser1");
			SetVariantString("OnUser2 !self:ClearParent::2.0:1");
			AcceptEntityInput(g_iPlayerHasHelmet[client], "AddOutput");
			AcceptEntityInput(g_iPlayerHasHelmet[client], "FireUser2");
			g_iPlayerHasHelmet[client] = INVALID_ENT_REFERENCE;
		}		*/
		if (g_iPlayerInfected[client] != 0)
		{
			GetClientAbsOrigin(client, g_fDeathOrigin[client]);
			CreateTimer(4.0, Timer_InfectedSurvivorDied, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		if (Healthkit_CheckHealing(client) == 1)
		{
			g_fPlayerHealthkitBandaging[g_iPlayerHealthkitTarget[client]] = 0.0;
			g_iPlayerHealthkitHealingBy[g_iPlayerHealthkitTarget[client]] = -1;
			PrintCenterText(g_iPlayerHealthkitTarget[client], " ");
			g_iPlayerHealthkitTarget[client] = -1;
		}
		if (g_fPlayerTempPropTimestamp[client] != 0.0 && g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]))
		{
			// PrintToServer("Removing #1");
			decl String:targetname[64];
			GetEntPropString(g_iPlayerTempProp[client], Prop_Data, "m_iName", targetname, sizeof(targetname));
			if (StrEqual(targetname, "LuaCustomModel", true))
			{
				LogToGame("%N is installing gear id %d but killed before complete %d", client, g_iPlayerCustomGear[client], g_iPlayerTempProp[client]);
				RequestFrame(DeleteEntity, EntIndexToEntRef(g_iPlayerTempProp[client]));
				g_iPlayerTempProp[client] = -1;
				g_fPlayerTempPropTimestamp[client] = 0.0;
				g_bPlayerTempPropSetup[client] = false;
			}
		}
		PrintHintText(client, "已死亡");
		PrintCenterText(client, " ");
		if (iAttackerTeam == TEAM_ZOMBIES)
		{
			if (StrEqual(weapon, "kabar"))
			{
				SetEventInt(event, "weaponid", -1);
				SetEventString(event, "weapon", "Eaten");
			}
		}
	}
	else if (iTeam == TEAM_ZOMBIES)
	{
/*	if (g_iAttachedParticleRef[client] != INVALID_ENT_REFERENCE && IsValidEdict(g_iAttachedParticleRef[client]))
	{
		new iParticle = EntRefToEntIndex(g_iAttachedParticleRef[client]);
		if (iParticle > MaxClients && IsValidEntity(iParticle))
		{
			SetVariantString("OnUser1 !self:kill::0.1:1");
			AcceptEntityInput(g_iAttachedParticleRef[client], "AddOutput");
			AcceptEntityInput(g_iAttachedParticleRef[client], "FireUser1");
//			AcceptEntityInput(iParticle, "ClearParent");
			g_iAttachedParticleRef[client] = INVALID_ENT_REFERENCE;
		}
	}	*/
		if (g_iAttachedParticleRef[client] != INVALID_ENT_REFERENCE)
		{
			RequestFrame(DeleteEntity, g_iAttachedParticleRef[client]);
			g_iAttachedParticleRef[client] = INVALID_ENT_REFERENCE;
		}
		if (g_iZombieClass[client][CLASS] > -1)
			g_iZombieSpawnCount[g_iZombieClass[client][CLASS]]--;
		ZombieBurnSound(client, false);
		if (g_iZombieClass[client][CLASS] == ZOMBIE_IED_INDEX)
		{
			if (iAttackerTeam == TEAM_SURVIVORS)
			{
				if (g_iZombieClass[client][VAR] < -1)
				{
					FakeClientCommand(attacker, "say 已击杀IED！");
					g_iPlayerBonusScore[attacker] += 20;
				}
			}
			if (g_iZombieClass[client][VAR] < -1)
			{
				switch(g_iLastSpecTarget[client])
				{
					case 0: StopSound(client, SNDCHAN_VOICE, "Lua_sounds/zombiehorde/zombies/ied/zombine_charge1.wav");
					case 1: StopSound(client, SNDCHAN_VOICE, "Lua_sounds/zombiehorde/zombies/ied/zombine_charge2.wav");
					case 2: StopSound(client, SNDCHAN_VOICE, "Lua_sounds/zombiehorde/zombies/ied/zombine_readygrenade2.wav");
				}
			}
		}
		else if (g_iZombieClass[client][CLASS] == ZOMBIE_LEAPER_INDEX)
		{
			g_iZombieClass[client][VAR] = 0;
		}
		else if (g_iZombieClass[client][CLASS] == ZOMBIE_KNIGHT_INDEX)
		{
			if (iAttackerTeam == TEAM_SURVIVORS)
			{
				// FakeClientCommand(attacker, "say Knight Killed!");
			}
		}
/*		else if (g_iZombieClass[client][CLASS] == ZOMBIE_BURNER_INDEX)
		{
			if (iAttackerTeam == TEAM_SURVIVORS)
			{
				FakeClientCommand(attacker, "say Burner Killed!");
			}
		}	*/
		else if (g_iZombieClass[client][CLASS] == ZOMBIE_SMOKER_INDEX)
		{
			AttachParticle(client, "smokegrenade", true, true, 20.0, -1, 9.0);
			new Float:fOrigin[3], Float:fTargetOrigin[3];
			GetClientAbsOrigin(client, fOrigin);
			for (new i = 1;i <= MaxClients;i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					GetClientAbsOrigin(i, fTargetOrigin);
					if (GetVectorDistance(fOrigin, fTargetOrigin) < 1001.0)
						EmitSoundToClient(i, "weapons/m203/m203_detonate_smoke_near_01.wav");
					else EmitSoundToClient(i, "weapons/m203/m203_detonate_smoke_far_01.wav");
				}
			}
//				EmitSoundToAll("weapons/m18/smokeburn.wav", -1, _, _, _, 1.0, _, _, fOrigin);
			EmitAmbientSound("weapons/m18/smokeburn.wav", fOrigin);
			// if (iAttackerTeam == TEAM_SURVIVORS) FakeClientCommand(attacker, "say Smoker Killed!");
		}
		if (iAttackerTeam == TEAM_SURVIVORS)
		{
			g_fLastKillTime[attacker] = GetGameTime();
		}
	}

	if (dontBroadcast || GetEventInt(event, "weaponid") == -2) return Plugin_Continue;
	if (StrEqual(weapon, "entityflame", false))
	{
		attacker = g_iBurnedBy[client];
		if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker)) SetEventInt(event, "attacker", GetClientUserId(g_iBurnedBy[client]));
		iAttackerTeam = (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))?GetClientTeam(attacker):-1;
		event.BroadcastDisabled = false;
		if (attacker != client)
		{
			if (iAttackerTeam == TEAM_SURVIVORS && iTeam == TEAM_SURVIVORS)
			{
				PlayGameSoundToAll("Lua_sounds/teamkiller.wav");
				PrintToChatAll("\x08%s%N \x01已被 \x04%N 友军击杀", COLOR_SECURITY, client, attacker);
				LogToGame("%N has team killed by %N", client, attacker);
				LogMessage("%N has team killed by %N", client, attacker);
				if (g_fPlayerDrugTime[attacker] == 0.0)
					ServerCommand("sm_drug #%d 1", GetClientUserId(attacker));
				g_fPlayerDrugTime[attacker] = GetGameTime()+40.0;
			}
			else if (iAttackerTeam == TEAM_ZOMBIES && iTeam == TEAM_ZOMBIES)
				event.BroadcastDisabled = true;
		}
		weapon = "Flame";
		SetEventString(event, "weapon", weapon);
		return Plugin_Continue;
	}
	else if (StrContains(weapon, "trigger", false) != -1)
	{
		weapon = "World";
		SetEventString(event, "weapon", weapon);
	}
	if (iTeam == TEAM_SURVIVORS)
	{
		if (iAttackerTeam == TEAM_SURVIVORS && attacker != client)
		{
			if (StrContains(weapon, "cache", false) == -1)
			{
				PlayGameSoundToAll("Lua_sounds/teamkiller.wav");
				PrintToChatAll("\x08%s%N \x01已被 \x04%N 友军击杀", COLOR_SECURITY, client, attacker);
				LogToGame("%N has team killed by %N", client, attacker);
				LogMessage("%N has team killed by %N", client, attacker);
				if (g_fPlayerDrugTime[attacker] == 0.0)
					ServerCommand("sm_drug #%d 1", GetClientUserId(attacker));
				g_fPlayerDrugTime[attacker] = GetGameTime()+40.0;
			}
			else
			{
				SetEventInt(event, "attacker", -1);
			}
		}
		return Plugin_Continue;
	}
	if (StrContains(weapon, "grenade", false) != -1		||
		StrContains(weapon, "rocket", false) != -1		/*||
		StrContains(weapon, "cache", false) != -1		||
		StrEqual(weapon, "kabar", false)				||
		StrEqual(weapon, "gurkha", false)				*/
	)
	{
		if (iTeam == TEAM_ZOMBIES && iAttackerTeam == TEAM_ZOMBIES)
			event.BroadcastDisabled = true;		// Do not broadcast bot teamkills
		return Plugin_Continue;		// Let slowmo plugin handle rockets message for multi kill
	}

	if (iTeam == TEAM_ZOMBIES)
	{
		if (GetEventInt(event, "customkill") != 1) // Custom kill 1 must be selfkill by server
		{
			if (iAttackerTeam == TEAM_SURVIVORS)
			{
				// Kill Confrim
				if (StrContains("kabar;gurkha", weapon, false) == -1)
				{
					decl Float:fPlayerOrigin[3], Float:fTargetOrigin[3];
					GetClientHeadOrigin(attacker, fPlayerOrigin, 6.0);
					GetClientHeadOrigin(client, fTargetOrigin, 6.0);
					new Handle:hTrace = TR_TraceRayFilterEx(fPlayerOrigin, fTargetOrigin, MASK_SOLID, RayType_EndPoint, Filter_Not_Players);
					if (!TR_DidHit(hTrace))
					{
						if (g_iLastHitgroup[client] != 1)
							PlayerYell(attacker, 2, false, FCVAR_PLAYER_YELL_CHANCE_KILL, client);
						else
							PlayerYell(attacker, 2, false, FCVAR_PLAYER_YELL_CHANCE_HS_KILL, client, FCVAR_PLAYER_YELL_COOLDOWN_MIN);
					}
					else event.BroadcastDisabled = true;
					CloseHandle(hTrace);
				}
				else if (!StrEqual(weapon, "grenadedirect", false))
				{
//					PlayerYell(attacker, 5, false);
				}
				else
				{
					PlayerYell(attacker, 6, true);
				}
			}
			else if (iAttackerTeam == TEAM_ZOMBIES)
			{
				if (StrContains(weapon, "cache", false) == -1)
				{
					event.BroadcastDisabled = true;
					LogToGame("%N has teamkilled by %N, silence kill feed", client, attacker);
				}
				else
				{
					LogToGame("%N has teamkilled by %N but killed with cache, do not silence the killfeed", client, attacker);
				}
				return Plugin_Continue;
			}
		}
		else
		{
			event.BroadcastDisabled = true;
			LogToGame("%N has suicide by the game, silence kill feed", client);
			return Plugin_Continue;
		}
	}
	
//	Removed:	m40a3
	if (StrContains("m40a1;cheytac_m200;mosin;gol;kar98;enfield;remingtonmsr;m107;bleeding", weapon, false) != -1)
		return Plugin_Continue;		// Let !ins_slowmo plugin handle them

	if (StrContains("kabar;gurkha;grenadedirect", weapon, false) == -1)
	{
		if (g_iLastHitgroup[client] != 1)
			event.BroadcastDisabled = true;
	}
	else if (g_iLastHitgroup[client] == 1)	// Knife, DirectHit Only
	{
		if (!StrEqual(weapon, "grenadedirect", false))
		{
/*		//	String_ToUpper(weapon, weapon, sizeof(weapon));
			if (StrEqual("m40a1", weapon, false)) weapon = "M40A1";
//			else if (StrEqual("mosin", weapon, false)) weapon = "Mosin";
			else if (StrEqual("gol", weapon, false)) weapon = "GOL Magnum";
			else if (StrEqual("kar98", weapon, false)) weapon = "Karabiner 98k";
			else if (StrEqual("enfield", weapon, false)) weapon = "Lee-Enfield No. 4";
			else if (StrEqual("remingtonmsr", weapon, false)) weapon = "Remington MSR";
			else if (StrContains("kabar;gurkha", weapon, false) != -1) weapon = "Knife";
			else // Kabar, Gurkha, Mosin and anything else
			{
				if (weapon[0] != '\0')
					weapon[0] = CharToUpper(weapon[0]);
				else
					weapon[1] = CharToUpper(weapon[1]);
			}
			Format(weapon, sizeof(weapon), "%s  @  HEADSHOT", weapon);	*/
			weapon = "Knife  @  HEADSHOT";
		}
		else
		{
			weapon = "GRENADE IMPACT  @  HEADSHOT";
		}
		SetEventInt(event, "weaponid", 0);
		SetEventString(event, "weapon", weapon);
	}
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bUpdatedSpawnPoint)
		return;
	g_iGameState = 3;
	g_fUAVLastTime = 0.0;
	g_fReinforcementBotDeployTime = 0.0;
	g_fReinforcementPlayerDeployTime = 0.0;
	g_bDoNotPlayFlagPickUp = false;
	g_bNoTakingCache = false;
	g_iOnFireBy = -1;
	g_hWeaponCacheFireExplode = INVALID_HANDLE;
	g_hAmmoExplodeEffectTimer = INVALID_HANDLE;
	g_hCounterAttackRespawnTimer = INVALID_HANDLE;
	g_bCounterAttackReadyTime = false;
	g_bFinalCP = false;
	g_bFinalCPMusic = false;
	g_bCounterAttack = false;
	g_bReinforcementBotEnd = false;
	g_iReinforcementBotCount = 0;
	g_bReinforcementPlayerEnd = false;
	g_iReinforcementPlayerCount = 0;
	g_iPointFlag = INVALID_ENT_REFERENCE;
	g_iPointFlagSpawnGlow = INVALID_ENT_REFERENCE;
	g_iPointFlagOwner = -1;
	g_fFlagDropTime = 0.0;
	g_bKillNoticePlayed = false;
	g_bTochedControlPoint = false;
	g_iNextSpawnPointsIndex = -1;
	g_bUAVOnline = false;
	g_fSpawnUpdateLastFailedTime = 0.0;
	g_iHeliEvacPositionIndex = -1;
	g_iHelicopterRef = INVALID_ENT_REFERENCE;
	g_fHeliEvacTime = 0.0;
	g_bHeliEvacStarted = false;
	g_iHeliEvacParticle = INVALID_ENT_REFERENCE;
	g_iLastManStand = -1;
	for (new i = 1;i <= MaxClients;i++)
	{
		g_iPlayerBonusScore[i] = 0;
		g_fDeathOrigin[i][0] = 0.0;
		if (!RemoveCustomFlags(i))
		{
			if (!IsClientInGame(i)) continue;
			if (IsPlayerAlive(i))
				SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0);
			if (!IsFakeClient(i))
			{
				StopSound(i, SNDCHAN_AUTO, "Lua_sounds/warsaw.ogg");
//				StopSound(i, SNDCHAN_AUTO, "Lua_sounds/zombiehorde/zombies_won1.ogg");
//				StopSound(i, SNDCHAN_AUTO, "Lua_sounds/zombiehorde/zombies_won2.ogg");
//				StopSound(i, SNDCHAN_AUTO, "Lua_sounds/zombiehorde/zombies_won3.ogg");
				StopSound(i, SNDCHAN_AUTO, "Lua_sounds/zombiehorde/lasthuman.ogg");
			}
		}
	}
//	g_iBlockZoneIndex = -1;
	for (new i = 0;i < GetMaxEntities();i++)
	{
		g_bIsOnFire[i] = false;
		g_bIsMovingCache[i] = false;
	}
	new Float:fRoundTime = GetRoundTime();
	CreateTimer(0.1, Timer_RoundStartHeli, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(fRoundTime-2.0, Timer_UpdateBotsConfig, _, TIMER_FLAG_NO_MAPCHANGE);
//	SetTimerPause(false);
	LogToGame("Round Started");
}

public Action:Timer_RoundStartHeli(Handle:timer)
{
	decl Float:vWorldMaxs[3];
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vWorldMaxs);
	for (new b = 0;b < MAXPLAYER;b++)
	{
		if (g_iPlayersList[b] == -1) continue;
		new i = g_iPlayersList[b];
		if (IsPlayerAlive(i))
		{
			decl Float:vOrigin[3];
			GetClientHeadOrigin(i, vOrigin, 15.0);
	//		vOrigin[2] += 80.0;
			TR_TraceRay(vOrigin, Float:{-90.0, 0.0, 0.0}, MASK_SOLID_BRUSHONLY, RayType_Infinite);
			if (TR_DidHit())
			{
				decl Float:vEndOrigin[3];
				TR_GetEndPosition(vEndOrigin);
				if (vEndOrigin[2]-vOrigin[2] >= 600.0)
				{
					if (vEndOrigin[2] >= vWorldMaxs[2]) vEndOrigin[2] = GetRandomFloat(vWorldMaxs[2], vEndOrigin[2]);
					HelicopterSpawn(vEndOrigin, _, 9, false);
					break;
				}
			}
		}
	}
}

public Action:Timer_UpdateBotsConfig(Handle:timer)
{
//	if (g_bNightMap) HookUserMessage(GetUserMessageId("HQAudio"), HQAudioHookNight, true);
	UpdateBotsToken(0);
	UpdateBotsConfig(0, true, false);
}

public Action:Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bUpdatedSpawnPoint)
		return;
	g_iGameState = 4;
	ObjectUpdate_Do(1);
	g_iNextSpawnPointsIndex = -1;
	g_fThunderSound = GetGameTime()+GetRandomFloat(5.0, 60.0);
//	SetWeaponCacheModel(-1, false);
//	g_bSkipSpawnCheck = true;
	for (new j = 0;j < MAXPLAYER; j++)
	{
		if (g_iPlayersList[j] == -1 || !IsPlayerAlive(g_iPlayersList[j]))
			continue;
		new client = g_iPlayersList[j];
		g_fMedicLastHealTime[client] = GetGameTime();
		if (IsLeader(client))
			CreateCustomFlag(client);

		// #Resupply Check
		new iKnife = GetPlayerWeaponByName(client, "weapon_kabar");
		if (iKnife <= MaxClients || !IsValidEdict(iKnife))
			iKnife = GivePlayerItem(client, "weapon_kabar");
		if (iKnife > MaxClients && IsValidEdict(iKnife))
			g_iPlayerLastKnife[client] = EntIndexToEntRef(iKnife);
	}
	switch(GetRandomInt(1, 3))
	{
		case 1: EmitSoundToAll("Lua_sounds/zombiehorde/round_begin1.ogg", _, SNDCHAN_AUTO, _, _, 1.0);
		case 2: EmitSoundToAll("Lua_sounds/zombiehorde/round_begin2.ogg", _, SNDCHAN_AUTO, _, _, 1.0);
		case 3: EmitSoundToAll("Lua_sounds/zombiehorde/round_begin3.ogg", _, SNDCHAN_AUTO, _, _, 1.0);
	}
	PrintCenterTextAll(" ");
	LogToGame("Round Freeze Ended");
	return;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iGameState = GetGameState();
	g_hUAVTimer = INVALID_HANDLE;
	SetConVarInt(g_hCvarAlwaysCounterAttack, 0);
/*	if (!g_bSkipCacheCheck)
	{
		for (new i = 0;i < 16;i++)
		{
			if (g_iCPType[i] == 0 && g_iCPIndex[i] != INVALID_ENT_REFERENCE)
				SDKUnhook(g_iCPIndex[i], SDKHook_OnTakeDamage, ObjectOnTakeDamage);
		}
		LogToGame("Round End with unhooking weapon cache...");
	}	*/
	for (new i = MaxClients+1;i < GetMaxEntities();i++)
	{
		if (i != INVALID_ENT_REFERENCE && IsValidEntity(i))
		{
			decl String:sClassName[64];
			GetEntityClassname(i, sClassName, 64);
			if (StrEqual(sClassName, "CACHE (FLAME)", true))
			{
				LogToGame("%d. \"CACHE (FLAME)\" has been removed", i); 
				AcceptEntityInput(i, "Kill");
			}
			else if (StrEqual(sClassName, "CACHE (AMMO)", true))
			{
				LogToGame("%d. \"CACHE (AMMO)\" has been removed", i); 
				AcceptEntityInput(i, "Kill");
			}
			else if (StrEqual(sClassName, "LuaTempParticle", true))
			{
				LogToGame("%d. used \"info_particle_system (LuaTempParticle)\" has been removed", i);
				AcceptEntityInput(i, "Kill");
			}
			// else if (StrEqual(sClassName, "info_particle_system", false))
			// {
				// LogToGame("%d. used \"info_particle_system\" has been removed", i);
				// AcceptEntityInput(i, "Kill");
			// }
			else if (StrEqual(sClassName, "prop_dynamic_override", false))
			{
				GetEntPropString(i, Prop_Data, "m_iName", sClassName, sizeof(sClassName));
				if (StrEqual(sClassName, "LuaCustomFlag", true) || StrEqual(sClassName, "LuaCustomModel", true) || StrEqual(sClassName, "LuaCustomHeli", true))
				{
					LogToGame("%s has been killed for round end (Index: %d (%d))", sClassName, i, EntIndexToEntRef(i));
					AcceptEntityInput(i, "Kill");
				}
			}
		}
	}
	g_iOnFireBy = -1;
	g_bCounterAttack = false;
	g_hWeaponCacheFireExplode = INVALID_HANDLE;
	g_hAmmoExplodeEffectTimer = INVALID_HANDLE;
	g_hCounterAttackRespawnTimer = INVALID_HANDLE;
	g_iPointFlag = INVALID_ENT_REFERENCE;
	g_iPointFlagSpawnGlow = INVALID_ENT_REFERENCE;
	g_iPointFlagOwner = -1;
	g_fFlagDropTime = 0.0;
	g_iNextSpawnPointsIndex = -1;
	g_bUAVOnline = false;
	for (new i = 1; i <= MaxClients;i++)
	{
		g_fDeathOrigin[i][0] = 0.0;
		if (!IsClientInGame(i)) continue;

		if (g_bFinalCPMusic && !IsFakeClient(i))
			StopSound(i, SNDCHAN_AUTO, "Lua_sounds/Natural_Killers.ogg");

		StopSound(i, SNDCHAN_STATIC, "Lua_sounds/bandaging.wav");
		StopSound(i, SNDCHAN_STATIC, "Lua_sounds/helicopter/heli_loop1.wav");
		StopSound(i, SNDCHAN_AUTO, "Lua_sounds/zombiehorde/lasthuman.ogg");
		g_fPlayerHealthkitBandaging[i] = 0.0;
//		if (GetClientTeam(i) == TEAM_SURVIVORS)
//			RemoveCustomFlags(i);
		g_iCustomFlagIndex[i] = INVALID_ENT_REFERENCE;
	}
	new iWinner = GetEventInt(event, "winner");
	switch(iWinner)
	{
		case TEAM_ZOMBIES:
		{
			switch(GetRandomInt(1, 3))
			{
				case 1: EmitSoundToAll("Lua_sounds/zombiehorde/zombies_won1.ogg", _, SNDCHAN_AUTO, _, _, 1.0);
				case 2: EmitSoundToAll("Lua_sounds/zombiehorde/zombies_won2.ogg", _, SNDCHAN_AUTO, _, _, 1.0);
				case 3: EmitSoundToAll("Lua_sounds/zombiehorde/zombies_won3.ogg", _, SNDCHAN_AUTO, _, _, 1.0);
			}
		}

		case TEAM_SURVIVORS:
		{
			PlayGameSoundToAll("Music.LostRound_Security");
			EmitSoundToAll("Lua_sounds/warsaw.ogg", _, SNDCHAN_AUTO, _, _, 1.0);
			PrintToChatAll("\x05[ZH]   \x01幸存者已逃离！");
//			PlayGameSoundToAll("soundscape/emitters/oneshot/air_siren.ogg");
			switch(GetRandomInt(0, 1))
			{
				case 0: PlayGameSoundToAll("soundscape/emitters/oneshot/explosion_huge_distant_01.ogg");
				case 1: PlayGameSoundToAll("soundscape/emitters/oneshot/explosion_huge_distant_02.ogg");
			}
			TE_SetupParticleEffect("explosion_silo", PATTACH_WORLDORIGIN, _, Float:{0.0, 0.0, 0.0});
			TE_SendToAll();
		}
	}
	PrintCenterTextAll(" ");
	PrintHintTextToAll(" ");
//	SetTimerPause(false);
	LogToGame("Round Ended (Winner: %d)", iWinner);
}

public Action:Event_BroadcastAudio(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bUpdatedSpawnPoint)
		return Plugin_Handled;
	new String:sSoundName[128];
	GetEventString(event, "sound", sSoundName, sizeof(sSoundName));
	if (StrEqual(sSoundName, "Music.StartCounterAttack", true))
	{
		g_bReinforcementBotEnd = false;
		g_fReinforcementBotDeployTime = 0.0;
		g_bCounterAttack = true;
		g_bNoTakingCache = true;
		g_bCounterAttackReadyTime = true;
		g_bTochedControlPoint = true;
		if (g_iNumControlPoints-1 == g_iCurrentControlPoint)
		{
			PlayGameSoundToAll("soundscape/emitters/oneshot/air_siren.ogg");
			switch(GetRandomInt(0, 1))
			{
				case 0: PlayGameSoundToAll("soundscape/emitters/oneshot/explosion_huge_distant_01.ogg");
				case 1: PlayGameSoundToAll("soundscape/emitters/oneshot/explosion_huge_distant_02.ogg");
			}
			g_bFinalCP = true;
			SetRoundTime(FCVAR_FINAL_COUNTERATTACK_TIME);
			LogToGame("Final Counter-Attack is detected");
		}
		else
		{
			LogToGame("Counter-Attack is detected");
		}
		g_hCounterAttackRespawnTimer = CreateTimer(GetRandomFloat(1.0, 5.0), Timer_CounterAttackSetupRespawn, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	LogToGame("Broadcast Audio Played: \"%s\" (team %d)", sSoundName, GetEventInt(event, "team"));
	return Plugin_Continue;
}

public Action:Timer_CounterAttackSetupRespawn(Handle:timer)
{
	if (timer == g_hCounterAttackRespawnTimer && GetGameState() == 4 && GetCounterAttack())
	{
		if (g_iCPType[g_iCurrentControlPoint] == 0)
		{
			switch(GetRandomInt(0, 4))
			{
				case 0: PlayGameSoundToAll("hq/outpost/outpost_gamestart_cache1.ogg");
				case 1: PlayGameSoundToAll("hq/security/defendcache1.ogg");
				case 2: PlayGameSoundToAll("hq/security/defendcache2.ogg");
				case 3: PlayGameSoundToAll("hq/security/defendcache3.ogg");
				case 4: PlayGameSoundToAll("hq/security/defendcache4.ogg");
			}
			SetEntData(g_iCPIndex[g_iCurrentControlPoint], g_iOffsetWeaponCacheGlow, 1);
			g_fWeaponCacheHealth = FCVAR_GAME_COUNTERATTACK_WEAPON_CACHE_HEALTH;
			SetWeaponCacheModel(EntRefToEntIndex(g_iCPIndex[g_iCurrentControlPoint]), true);
//			SDKHook(g_iCPIndex[g_iCurrentControlPoint], SDKHook_OnTakeDamage, CounterAttackObjectOnTakeDamage);
		}

		// Teleport respawn players to player who nearest from object or weapon cache, for the capture point there should be a Prop info
//		new iCapPlayers[MAXPLAYERS_INS+1] = {-1, ...}, iCapPlayerCount = 0;
		new iDeadPlayers[MAXPLAYERS_INS+1] = {-1, ...}, iDeadPlayerCount = 0;
		for (new j = 0;j < MAXPLAYER; j++)
		{
			if (g_iPlayersList[j] == -1) continue;
			new client = g_iPlayersList[j];
			if (g_bHasSquad[client] && !IsPlayerAlive(client))
				iDeadPlayers[iDeadPlayerCount++] = client;
		}
		if (iDeadPlayerCount > 0 /*&& iCapPlayerCount > 0*/)
		{
			new Float:vTargetPos[3], Float:fDistance, Float:fNearestDistance = 2000.0, Float:vNearest[3] = {-9000.0, 0.0, 0.0}, iNearestPlayer = -1;
			for (new j = 0;j < MAXPLAYER; j++)
			{
				if (g_iPlayersList[j] == -1 || !IsPlayerAlive(g_iPlayersList[j]))
					continue;
				new i = g_iPlayersList[j];
				GetClientAbsOrigin(i, vTargetPos);
				fDistance = GetVectorDistance(vTargetPos, g_vCPPositions[g_iCurrentControlPoint]);
				if (fDistance <= fNearestDistance)
				{
					vNearest[0] = vTargetPos[0];
					vNearest[1] = vTargetPos[1];
					vNearest[2] = vTargetPos[2];
					fNearestDistance = fDistance;
					iNearestPlayer = i;
				}
			}
			if (iNearestPlayer != -1)
			{
				vNearest[2] += 2.0;
			}
			else
			{
				vNearest[0] = g_vCPPositions[g_iCurrentControlPoint][0];
				vNearest[1] = g_vCPPositions[g_iCurrentControlPoint][1];
				vNearest[2] = g_vCPPositions[g_iCurrentControlPoint][2];
				if (g_iCPType[g_iCurrentControlPoint] == 0) vNearest[2] += 12.0;
			}
/*			new iRandomCapPlayer = iCapPlayers[GetRandomInt(0, iCapPlayerCount-1)];
			decl Float:vPos[3];
			GetClientAbsOrigin(iRandomCapPlayer, vPos);
			vPos[2] += 6.0;	*/
			for (new i = 0;i < iDeadPlayerCount;i++)
			{
				RespawnPlayer(iDeadPlayers[i], 0);
				TeleportEntity(iDeadPlayers[i], vNearest, NULL_VECTOR, NULL_VECTOR);
				if (iNearestPlayer > 0 && IsClientInGame(iNearestPlayer))
				{
					PrintToChat(iNearestPlayer, "\x08%s%N \x01已在你身边部署！", GetPlayerChatColor(iDeadPlayers[i]), iDeadPlayers[i]);
				}
			}
			// Sounds
			PrintCenterTextAll("我们的支援已经到达了！\n \n \n \n \n \n \n \n \n \n \n \n ");
			if (g_iCPType[g_iCurrentControlPoint] != 0)
			{
				if (GetRandomInt(0, 2) != 0)
				{
					new String:sSoundFile[64];
					switch(GetRandomInt(1, 6))
					{
						case 1: sSoundFile = "Lua_sounds/defend01.ogg";
						case 2: sSoundFile = "hq/security/defendcache5.ogg";
						case 3: sSoundFile = "hq/security/vendetta1.ogg";
						case 4, 5, 6: Format(sSoundFile, sizeof(sSoundFile), "hq/security/wehave%d.ogg", GetRandomInt(1, 10));
					}
					EmitSoundToAll(sSoundFile, _, SNDCHAN_AUTO, _, _, 1.0);
				}
				else PlayGameSoundToAll("Player.Security_Outpost_NextLevel_OneThrough20");
			}
			g_fReinforcementBotDeployTime = 0.0;
			g_fReinforcementPlayerDeployTime = 0.0;
		}			
		g_hCounterAttackRespawnTimer = INVALID_HANDLE;
	}
}

public Action:CounterAttackObjectOnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (g_iGameState != 4 || victim <= MaxClients) return Plugin_Continue;
//	LogToGame("Counter Object Weapon Cache %d damaged by %d (inflictor %d) damage %0.2f (Type %d), weapon %d", victim, attacker, inflictor, damage, damagetype, weapon);
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == TEAM_ZOMBIES)
	{
		if (damagetype & DMG_BURN) damage = 1.0;
		else if (damagetype & DMG_BULLET) damage *= 0.08;
		else damage *= 0.5;
		g_fWeaponCacheHealth -= damage;
		if (g_fWeaponCacheHealth <= 0.1)
		{
			g_iGameState = 9;
			PrintToChatAll("\x08%sWeapon Cache \x01destroyed by \x08%sInsurgent Forces", COLOR_SECURITY, COLOR_INSURGENTS);
			CreateTimer(0.0, ExplosionEffect, victim, TIMER_FLAG_NO_MAPCHANGE);
			PlayGameSoundToAll("Player.Security_Outpost_CacheDestroyed");
			new ent = FindEntityByClassname(-1, "ins_rulesproxy");
			if (ent > MaxClients && IsValidEntity(ent))
			{
				SetVariantInt(TEAM_ZOMBIES);
				AcceptEntityInput(ent, "EndRound");
			}
			else
			{
				for (new j = 0;j < MAXPLAYER; j++)
				{
					if (g_iPlayersList[j] == -1 || !IsPlayerAlive(g_iPlayersList[j]))
						continue;
					ForcePlayerSuicide(g_iPlayersList[j]);
				}
			}
			decl Float:vObjPos[3], Float:vTargetPos[3], Float:fDistance;
			GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", vObjPos);
			for (new j = 0;j < MAXPLAYER; j++)
			{
				if (g_iPlayersList[j] == -1) continue;
				new i = g_iPlayersList[j];
				GetClientAbsOrigin(i, vTargetPos);
				fDistance = GetVectorDistance(vObjPos, vTargetPos);
				if (fDistance < 1500)
					EmitSoundToClient(i, "weapons/WeaponCache/Cache_Explode.wav", victim, SNDCHAN_STATIC, 140, _, 1.0);	// 140dB
				else if (fDistance < 5000)
					EmitSoundToClient(i, "weapons/WeaponCache/Cache_Explode_Distant.wav", victim, SNDCHAN_STATIC, 110, _, 1.0);		// 110dB
				else
					EmitSoundToClient(i, "weapons/WeaponCache/Cache_Explode_far_Distant.wav", victim, SNDCHAN_STATIC, 150, _, 1.0);	// 150dB
			}
			SDKUnhook(victim, SDKHook_OnTakeDamage, CounterAttackObjectOnTakeDamage);
		}
		else
		{
			if (g_fCacheLastHitTime <= g_fGameTime)
			{
				g_fCacheLastHitTime = g_fGameTime+5.0;
				PlayGameSoundToAll("Player.Security_Outpost_CacheTakesDamage");
			}
			PrintToChatAll("\x08%sWeapon Cache \x05%0.0f \x01/ \x05%0.0f", COLOR_SECURITY, g_fWeaponCacheHealth, FCVAR_GAME_COUNTERATTACK_WEAPON_CACHE_HEALTH);
		}
	}
	else
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:Event_RoundTimerChanged(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bUpdatedSpawnPoint)
		return;
	if (g_bCounterAttack)
	{
		if (g_iCPType[g_iCurrentControlPoint] == 0)
		{
			SetEntData(g_iCPIndex[g_iCurrentControlPoint], g_iOffsetWeaponCacheGlow, 0);
//			SDKUnhook(g_iCPIndex[g_iCurrentControlPoint], SDKHook_OnTakeDamage, CounterAttackObjectOnTakeDamage);
		}
//		g_fUAVLastTime = 0.0;
//		g_hUAVTimer = INVALID_HANDLE;
		g_iCurrentControlPoint++;
		CreateTimer(0.2, ObjectUpdate, 0);
		g_hCounterAttackRespawnTimer = INVALID_HANDLE;
		g_bCounterAttackReadyTime = false;
		g_bNoTakingCache = false;
		g_bCounterAttack = false;
		g_bReinforcementBotEnd = false;
		g_iReinforcementBotCount = 0;
		g_bReinforcementPlayerEnd = false;
		g_iReinforcementPlayerCount = 0;
		for (new client = 1;client <= MaxClients;client++)
		{
			g_iTeleportOnSpawn[client] = 0;
			if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TEAM_SURVIVORS)
				continue;

			new iFlags = GetEntProp(client, Prop_Send, "m_iPlayerFlags");
			if (iFlags & INS_PL_BLOCKZONE)
			{
				iFlags &= ~INS_PL_BLOCKZONE;
				iFlags &= ~INS_PL_LOWERZONE;
				SetEntProp(client, Prop_Send, "m_iPlayerFlags", iFlags);
			}
		}
		LogToGame("Counter-Attack Ended");
	}
	else
	{
		for (new client = 1;client <= MaxClients;client++)
			g_iTeleportOnSpawn[client] = 0;
		if (g_iCurrentControlPoint > 0) ZH_ZombieAlert();
	}
	g_bTochedControlPoint = false;
	g_fReinforcementBotDeployTime = 0.0;
	g_fReinforcementPlayerDeployTime = 0.0;
	if (g_iCurrentControlPoint > 0)
		CreateTimer(0.1, Timer_CheckBotDistanceForNextObject, _, TIMER_FLAG_NO_MAPCHANGE);
	return;
}

public Action:Event_ObjectReached(Handle:event, const String:name[], bool:dontBroadcast)
{
//	g_fUAVLastTime = 0.0;
//	g_hUAVTimer = INVALID_HANDLE;
	if (!g_bUpdatedSpawnPoint)
		return;
	if (DEBUGGING_ENABLED)
		LogToGame("Object Reached \"%s\" point: %d", name, g_iCurrentControlPoint);
	for (new client = 1;client <= MaxClients;client++)
		g_iTeleportOnSpawn[client] = 0;
	g_hWeaponCacheFireExplode = INVALID_HANDLE;
	g_bNoTakingCache = false;
	g_fReinforcementPlayerDeployTime = 0.0;
	g_fReinforcementBotDeployTime = 0.0;
	g_bReinforcementBotEnd = false;
	g_iReinforcementBotCount = 0;
	g_bReinforcementPlayerEnd = false;
	g_iReinforcementPlayerCount = 0;
	g_iPointFlag = INVALID_ENT_REFERENCE;
	g_iPointFlagSpawnGlow = INVALID_ENT_REFERENCE;
	g_iPointFlagOwner = -1;
	g_fFlagDropTime = 0.0;
	if (StrEqual(name, "object_destroyed", false))
	{
/*		"team" "byte"
		"attacker" "byte"
		"cp" "short"
		"index" "short"
		"type" "byte"
		"weapon" "string"
		"weaponid" "short"
		"assister" "byte"
		"attackerteam" "byte"	*/
		if (g_iCPIndex[g_iCurrentControlPoint] != INVALID_ENT_REFERENCE)
		{
			LogToGame("Object Weapon Cache %d destroyed on area %d", g_iCPIndex[g_iCurrentControlPoint], g_iCurrentControlPoint);
//			LogToGame("Object Weapon Cache %d destroyed on area %d, unhooking...", g_iCPIndex[g_iCurrentControlPoint], g_iCurrentControlPoint);
//			SDKUnhook(g_iCPIndex[g_iCurrentControlPoint], SDKHook_OnTakeDamage, ObjectOnTakeDamage);
			SetEntData(g_iCPIndex[g_iCurrentControlPoint], g_iOffsetWeaponCacheGlow, 0);
			GetEntPropString(g_iCPIndex[g_iCurrentControlPoint], Prop_Data, "m_ModelName", g_sMovingCacheModel, sizeof(g_sMovingCacheModel));
			g_iMovingCacheModelSkin = GetEntProp(g_iCPIndex[g_iCurrentControlPoint], Prop_Data, "m_nSkin");
			CreateTimer(0.02, ObjectModelUpdate, EntRefToEntIndex(g_iCPIndex[g_iCurrentControlPoint]), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.1, ExplosionEffect, EntRefToEntIndex(g_iCPIndex[g_iCurrentControlPoint]), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			g_sMovingCacheModel = "models/static_props/weapon_cache_01.mdl";
			g_iMovingCacheModelSkin = -1;
		}
	}
	else
	{
		g_sMovingCacheModel = "models/static_props/weapon_cache_01.mdl";
		g_iMovingCacheModelSkin = -1;
	}
	if (!GetCounterAttack())
	{
//		g_iCPIndex[g_iCurrentControlPoint] = -2;	// Set to -2 for skip until get a new active control point
		CreateTimer(0.2, ObjectUpdate, 0);
	}
//	CreateTimer(1.0, Timer_CheckBotDistanceForNextObject, _, TIMER_FLAG_NO_MAPCHANGE);
	return;
}

public Action:Timer_CheckBotDistanceForNextObject(Handle:timer)
{
	if (g_iGameState == 4 && !g_bCounterAttack)
	{
		g_fGameTime = GetGameTime();
		for (new client = 1;client <= MaxClients;client++)
		{
			if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TEAM_ZOMBIES || client == g_iPointFlagOwner || g_fGameTime-g_fSpawnTime[client] <= 3.0)
				continue;

			new Float:fOrigin[3], Float:fPlayerOrigin[3], bool:bPlayerNearby = false;
			GetClientHeadOrigin(client, fOrigin, 10.0);
/*			GetClientEyePosition(client, fOrigin);
			switch(GetEntProp(client, Prop_Send, "m_iCurrentStance"))
			{
				case 0: fOrigin[2] += 4.0;	// Standing
				case 1: fOrigin[2] += 20.0;	// Duck
				case 2: fOrigin[2] += 52.0;	// Prone
			}	*/
			for (new j = 0;j < MAXPLAYER;j++)
			{
				if (g_iPlayersList[j] == -1 || !IsPlayerAlive(g_iPlayersList[j]))
					continue;

				new i = g_iPlayersList[j];
				GetClientHeadOrigin(i, fPlayerOrigin, 10.0);
/*				GetClientEyePosition(i, fPlayerOrigin);
				switch(GetEntProp(i, Prop_Send, "m_iCurrentStance"))
				{
					case 0: fPlayerOrigin[2] += 4.0;	// Standing
					case 1: fPlayerOrigin[2] += 20.0;	// Duck
					case 2: fPlayerOrigin[2] += 52.0;	// Prone
				}	*/
				new Handle:hTrace = TR_TraceRayFilterEx(fOrigin, fPlayerOrigin, MASK_SOLID_BRUSHONLY, RayType_EndPoint, Base_TraceFilter);
				if (TR_DidHit(hTrace))
				{
					CloseHandle(hTrace);
				}
				else
				{
					CloseHandle(hTrace);
					bPlayerNearby = true;
					break;
				}
				if (GetVectorDistance(fOrigin, fPlayerOrigin) <= 1000.0)
				{
					bPlayerNearby = true;
					break;
				}
			}

			if (!bPlayerNearby)
			{
				RespawnPlayer(client, 0);
				LogToGame("%N has been respawned for new object (No players within 1000 ft and no visible)", client);
			}
			else g_fSpawnTime[client] = g_fGameTime;
		}
	}
}

public Action:ExplosionEffect(Handle:timer, any:iobject)
{
	if (iobject > MaxClients && IsValidEntity(iobject) && GetGameState() == 4)
	{
		LogToGame("Object Weapon Cache Explosion Effect has been activate on %d", iobject);
//		SetVariantFloat(0.0);
//		AcceptEntityInput(iobject, "IgniteLifetime");
		decl Float:pos[3];
		GetEntPropVector(iobject, Prop_Data, "m_vecAbsOrigin", pos);
		new Float:fHeightOffset = 20.0;
		if (StrContains(g_sMovingCacheModel, "models/static_props/wcache_sec_01", false) != -1)
			fHeightOffset = 40.0;
		else if (StrContains(g_sMovingCacheModel, "models/static_props/wcache_ins", false) != -1)
			fHeightOffset= 50.0;
		pos[2] += fHeightOffset;
		if (!GetCounterAttack() && GetGameState() == 4)
		{
			DoPointHurt(pos, 0, -1, 280, 12, 0.4, DMG_BULLET, "CACHE (AMMO)", 10.0);
			DoPointHurt(pos, 0, -1, 80, 3, 0.4, DMG_BURN, "CACHE (FLAME)", 20.0);
			g_hAmmoExplodeEffectTimer = CreateTimer(5.0, AmmoExplosionEffect, iobject, TIMER_FLAG_NO_MAPCHANGE);
		}
		else// if (GetGameState() == 4)
		{
			DoPointHurt(pos, 0, -1, 280, 12, 0.4, DMG_BULLET, "CACHE (AMMO)", 5.0);
			DoPointHurt(pos, 0, -1, 80, 3, 0.4, DMG_BURN, "CACHE (FLAME)", 6.0);
		}
		pos[2] -= fHeightOffset;
		new Float:distance, Float:amp, Float:fre, Float:targetpos[3];
		for (new j = 0;j < MAXPLAYER; j++)
		{
			if (g_iPlayersList[j] == -1) continue;
			new i = g_iPlayersList[j];
			GetClientAbsOrigin(i, targetpos);
			distance = GetVectorDistance(pos, targetpos)*0.01905; // meters
			if (distance <= 32.1)
			{
				if (distance <= 12.1)
				{
					amp = GetRandomFloat(25.0, 30.0);
					fre = GetRandomFloat(30.0, 35.0);
				}
				else
				{
					amp = GetRandomFloat(20.0, 25.0);
					fre = GetRandomFloat(30.0, 35.0);
				}
				ClientScreenShake(i, SHAKE_START, amp, fre, GetRandomFloat(2.22, 3.22));
			}
		}
		EmitAmbientSound("physics/dynamic/ammobox_cookoff.ogg", pos);
		pos[2] += 2.0;
//			TE_SetupParticleEffect("ins_car_explosion", PATTACH_CUSTOMORIGIN, _, pos);
//			TE_SendToAll();
		new particle = CreateEntityByName("info_particle_system");
		if (particle > MaxClients && IsValidEntity(particle))
		{
			DispatchKeyValue(particle, "classname", "LuaTempParticle");
			DispatchKeyValue(particle, "effect_name", "ins_car_explosion");
			DispatchSpawn(particle);
			AcceptEntityInput(particle, "start");
			ActivateEntity(particle);
			if (!GetCounterAttack()) SetVariantString("OnUser1 !self:kill::20.0:1");
			else SetVariantString("OnUser1 !self:kill::6.0:1");
//			if (!GetCounterAttack()) CreateTimer(20.0, DeleteParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
//			else CreateTimer(6.0, DeleteParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
			AcceptEntityInput(particle, "AddOutput");
			AcceptEntityInput(particle, "FireUser1");
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		}
		pos[2] += 7.0;
		TE_SetupParticleEffect("ins_ammo_explosion", PATTACH_CUSTOMORIGIN, _, pos);
		TE_SendToAll();
/*			TE_SetupParticleEffect("ins_c4_explosion_smoke_c", PATTACH_CUSTOMORIGIN, _, pos);
		TE_SendToAll();
//			TE_SetupParticleEffect("ins_ammo_explosion_sparks_e", PATTACH_CUSTOMORIGIN, _, pos);
//			TE_SendToAll();
		TE_SetupParticleEffect("ins_gas_explosion_flameburst", PATTACH_CUSTOMORIGIN, _, pos);
		TE_SendToAll();
		TE_SetupParticleEffect("ins_grenade_explosion_spikes", PATTACH_CUSTOMORIGIN, _, pos);
		TE_SendToAll();
		TE_SetupParticleEffect("ins_ammo_explosion_smoke", PATTACH_CUSTOMORIGIN, _, pos);
		TE_SendToAll();
		TE_SetupParticleEffect("ins_ammo_explosion_smoke_b", PATTACH_CUSTOMORIGIN, _, pos);
		TE_SendToAll();	*/
	}
}

public Action:AmmoExplosionEffect(Handle:timer, any:iobject)
{
	if (g_hAmmoExplodeEffectTimer == timer && iobject > MaxClients && IsValidEntity(iobject))
	{
		decl Float:pos[3];
		GetEntPropVector(iobject, Prop_Data, "m_vecAbsOrigin", pos);
		EmitAmbientSound("physics/dynamic/ammobox_cookoff.ogg", pos);
		pos[2] += 9.0;
		TE_SetupParticleEffect("ins_ammo_explosion", PATTACH_WORLDORIGIN, _, pos);
		TE_SendToAll();
	}
}

public Action:ObjectUpdate(Handle:timer, any:updatetype)
{
	ObjectUpdate_Do(updatetype);
}

ObjectUpdate_Do(updatetype = 0)
{
	g_iGameState = GetGameState();
	if (!GetCounterAttack() && g_iObjRes > MaxClients && IsValidEntity(g_iObjRes) && (g_iGameState == 4 || g_iGameState == 3))
	{
		g_iCurrentControlPoint = GetEntData(g_iObjRes, g_iOffsetCPIndex);
		g_iOnFireBy = -1;
		if (updatetype != 0) // These are only once on round started
		{
			g_iNumControlPoints = GetEntData(g_iObjRes, g_iOffsetCPNumbers);
			GetEntDataArray(g_iObjRes, g_iOffsetCPType, g_iCPType, g_iNumControlPoints, 4);
			for (new i = 0;i < g_iNumControlPoints;i++)
			{
				GetEntDataArray(g_iObjRes, g_iOffsetCPType, g_iCPType, g_iNumControlPoints, 4);
				GetEntDataVector(g_iObjRes, g_iOffsetCPPositions+(12*i), g_vCPPositions[i]);
			}
			CheckWeaponCache(true);
		}
		else CheckWeaponCache(false);
		LogToGame("Objectvie Update - Number of Points %d, Current Point %d", g_iNumControlPoints, g_iCurrentControlPoint);
		if (RoundToNearest(float(g_iNumControlPoints)/1.4) <= g_iCurrentControlPoint && GetConVarInt(FindConVar("mp_maxrounds")) != 1)
			ServerCommand("cvar mp_maxrounds 1");
		if (g_iNumControlPoints-1 == g_iCurrentControlPoint)
		{
			g_bFinalCP = true;
			LogToGame("Final Capture Point!");
			g_iHeliEvacPositionIndex = -1;
			if (GetRandomFloat(0.0, 100.0) <= FCVAR_HELICOPTER_EVAC_CHANCE)
			{
				LogToGame("Evac Helicopter Position Store Timer Started");
				CreateTimer(0.5, Timer_HeliEvacPositionStore, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			}
		}
		if (g_iCPType[g_iCurrentControlPoint] == 0)
		{
			if (g_bUpdatedSpawnPoint && FCVAR_BOT_WEAPONCACHE_INTEL_MODE_CHANCE >= GetRandomFloat(0.0, 100.0))
			{
				new iFlagPlayer = -1, Float:vTargetPos[3], Float:fDistance, Float:fNearestDistance = 800.0;
				for (new i = 1;i <= MaxClients;i++)
				{
					if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_ZOMBIES || !IsPlayerAlive(i)) continue;
					GetClientAbsOrigin(i, vTargetPos);
					fDistance = GetVectorDistance(vTargetPos, g_vCPPositions[g_iCurrentControlPoint]);
					if (fDistance <= fNearestDistance)
					{
						fNearestDistance = fDistance;
						iFlagPlayer = i;
					}
				}
				if (iFlagPlayer == -1) iFlagPlayer = GetRandomPlayer(-1, TEAM_ZOMBIES, false, true, false);
				if (iFlagPlayer > 0 && iFlagPlayer <= MaxClients && IsClientInGame(iFlagPlayer))
				{
					if (!IsPlayerAlive(iFlagPlayer)) SDKCall(g_hPlayerRespawn, iFlagPlayer);
					CreatePointFlag(iFlagPlayer, true);

					GetEntPropVector(g_iCPIndex[g_iCurrentControlPoint], Prop_Data, "m_vecAbsOrigin", vTargetPos);
					vTargetPos[2] -= 2000.0;
					TeleportEntity(g_iCPIndex[g_iCurrentControlPoint], vTargetPos, NULL_VECTOR, NULL_VECTOR);
					if (g_iGameState == 3)
					{
						g_iPointFlagOwner = -1;
						g_fFlagDropTime = 0.1;
					}
				}
				else LogError("Intel Gamemode has been failed to setting, Random player \"%d\" is not valid", iFlagPlayer);
			}
		}
//		else
//		{
//			LogToGame("Control Point %d found on area %d, hooking and setup", g_iCurrentControlPoint, g_iCurrentControlPoint);
//		}
	}
}

public Action:ObjectModelUpdate(Handle:timer, any:iobject)
{
	if (GetGameState() != 4) return;
	if (g_iMovingCacheModelSkin != -1)
	{
		if (StrContains(g_sMovingCacheModel, "_destr.mdl", false) == -1 && StrContains(g_sMovingCacheModel, "ins_radio", false) == -1)
			ReplaceString(g_sMovingCacheModel, sizeof(g_sMovingCacheModel), ".mdl", "_destr.mdl", false);
//		ReplaceString(g_sMovingCacheModel, sizeof(g_sMovingCacheModel), "_destr_destr.mdl", "_destr.mdl", false);
		SetEntityModel(iobject, g_sMovingCacheModel);
		SetEntProp(iobject, Prop_Data, "m_nSkin", g_iMovingCacheModelSkin);
		SetEntData(iobject, g_iOffsetWeaponCacheGlow, 0);
		if (!StrEqual(g_sMovingCacheModel, "models/static_props/wcache_sec_01_destr.mdl", false))
			SetEntProp(iobject, Prop_Send, "m_CollisionGroup", 26);
		else
			SetEntProp(iobject, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
		LogToGame("Weapon Cache %d model has been update to destroyed model \"%s\"", iobject, g_sMovingCacheModel);
	}
	return;
}

public Action:Event_Catpurezone_Enter(Handle:event, const String:name[], bool:dontBroadcast)
{
/*		"area" "byte"
		"object" "short"
		"player" "short"
		"team" "short"
		"owner" "short"
		"type" "short"	*/
		// type -1 (catpure zone), 0 = (weapon cache) for checkpoint
	if (g_bUpdatedSpawnPoint && GetGameState() == 4)
	{
		new area = GetEventInt(event, "area");
		if (area == g_iCurrentControlPoint)
		{
			if (g_iCPType[g_iCurrentControlPoint] == 0 || GetEventInt(event, "type") == 0)
			{
				new iobject = GetEventInt(event, "object");
				if (iobject != -1 && g_iCPIndex[g_iCurrentControlPoint] != EntIndexToEntRef(iobject))
				{
					if (g_iCPIndex[g_iCurrentControlPoint] != INVALID_ENT_REFERENCE && EntRefToEntIndex(g_iCPIndex[g_iCurrentControlPoint]) > MaxClients)
					{
						SetVariantBool(false);
						AcceptEntityInput(g_iCPIndex[g_iCurrentControlPoint], "TakeDamageBullets");
						SDKUnhook(g_iCPIndex[g_iCurrentControlPoint], SDKHook_OnTakeDamage, ObjectOnTakeDamage);
					}
					LogToGame("Object Weapon Cache %d (%d) was set wrong, set to %d (%d)", g_iCPIndex[g_iCurrentControlPoint], EntIndexToEntRef(iobject), EntIndexToEntRef(iobject), iobject);
					g_iCPIndex[g_iCurrentControlPoint] = EntIndexToEntRef(iobject);
					SetVariantBool(true);
					AcceptEntityInput(g_iCPIndex[g_iCurrentControlPoint], "TakeDamageBullets");
					SDKHook(g_iCPIndex[g_iCurrentControlPoint], SDKHook_OnTakeDamage, ObjectOnTakeDamage);
				}
			}
			new client = GetEventInt(event, "player");
			if (IsPlayerAlive(client))
			{
				g_bIsInCaptureZone[client] = true;
				if (IsFakeClient(client)) g_fSpawnTime[client] = GetGameTime();
				if (!g_bTochedControlPoint && GetClientTeam(client) == TEAM_SURVIVORS)
					g_bTochedControlPoint = true;
			}
		}
	}
}

stock CreatePointFlagSpawnGlow(client = -1, bool:enable = false)
{
	if (GetGameState() != 4) return false;
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		if ((client = GetRandomPlayer(client, TEAM_SURVIVORS, true, true, false)) == -1)
			return false;
	}
	g_iPointFlagSpawnGlow = CreateEntityByName("prop_dynamic_glow");
	if (g_iPointFlagSpawnGlow > MaxClients && IsValidEntity(g_iPointFlagSpawnGlow))
	{
		g_iPointFlagSpawnGlow = EntIndexToEntRef(g_iPointFlagSpawnGlow);
		new Float:vPos[3];
		GetClientAbsOrigin(client, vPos);
		new Float:vNearestSpawnZone[3], Float:vSpawnZonePos[3], Float:fDistance, Float:fNearestDistance = 90000.0;
		for (new i = 0;i <= g_iSpawnZoneIndex;i++)
		{
			if (GetEntProp(g_iSpawnZoneRef[i], Prop_Send, "m_iTeamNum") != TEAM_SURVIVORS || GetEntProp(g_iSpawnZoneRef[i], Prop_Data, "m_bDisabled") == 1)
				continue;
			GetEntPropVector(g_iSpawnZoneRef[i], Prop_Data, "m_vecOrigin", vSpawnZonePos);
			if (vSpawnZonePos[0] == 0.0 && vSpawnZonePos[1] == 0.0 && vSpawnZonePos[2] == 0.0) continue;
			fDistance = GetVectorDistance(vSpawnZonePos, vPos);
			if (fDistance <= fNearestDistance)
			{
				vNearestSpawnZone[0] = vSpawnZonePos[0];
				vNearestSpawnZone[1] = vSpawnZonePos[1];
				vNearestSpawnZone[2] = vSpawnZonePos[2];
				fNearestDistance = fDistance;
			}
		}
		if (fNearestDistance == 90000.0)
		{
			for (new i = 0;i <= g_iSpawnPointsIndex;i++)
			{
				if (g_iSpawnPointsRef[i] == INVALID_ENT_REFERENCE || GetEntProp(g_iSpawnPointsRef[i], Prop_Send, "m_iTeamNum") != TEAM_SURVIVORS || GetEntProp(g_iSpawnPointsRef[i], Prop_Data, "m_iDisabled") == 1)
					continue;
		
				GetEntPropVector(g_iSpawnPointsRef[i], Prop_Data, "m_vecOrigin", vSpawnZonePos);
				if (vSpawnZonePos[0] == 0.0 && vSpawnZonePos[1] == 0.0 && vSpawnZonePos[2] == 0.0) continue;
				fDistance = GetVectorDistance(vSpawnZonePos, vPos);
				if (fDistance <= fNearestDistance)
				{
					vNearestSpawnZone[0] = vSpawnZonePos[0];
					vNearestSpawnZone[1] = vSpawnZonePos[1];
					vNearestSpawnZone[2] = vSpawnZonePos[2];
					fNearestDistance = fDistance;
				}
			}
/*			new iMaxIndex;
			if (g_iCurrentControlPoint < g_iNumControlPoints-1)
				iMaxIndex = g_iSpawnPointsInfoIndex[g_iCurrentControlPoint+1]-1;
			else
				iMaxIndex = g_iSpawnPointsInfoMaxIndex;
			for (new i = g_iSpawnPointsInfoIndex[g_iCurrentControlPoint];i <= iMaxIndex;i++)
			{
				new iSpawnPointRef = g_iSpawnPointsInfo[i][0];
				if (iSpawnPointRef == INVALID_ENT_REFERENCE || g_iSpawnPointsInfo[i][1] == 1 || g_iSpawnPointsInfo[i][2] != g_iCurrentControlPoint || g_iSpawnPointsInfo[i][3] != TEAM_SURVIVORS)
					continue;

				PrintToChatAll("Spawn Index %d/%d (%d (%d), CA %d CP %d TEAM %d IsOff %d)", i, g_iSpawnPointsInfoMaxIndex, g_iSpawnPointsInfo[i][0], EntRefToEntIndex(g_iSpawnPointsInfo[i][0]), g_iSpawnPointsInfo[i][1], g_iSpawnPointsInfo[i][2], GetEntProp(iSpawnPointRef, Prop_Send, "m_iTeamNum"), GetEntProp(iSpawnPointRef, Prop_Data, "m_iDisabled"));
				GetEntPropVector(iSpawnPointRef, Prop_Data, "m_vecOrigin", vSpawnZonePos);
				PrintToChatAll("SpawnPoint Check %d (%d)  %0.2f, %0.2f, %0.2f", iSpawnPointRef, EntRefToEntIndex(iSpawnPointRef), vSpawnZonePos[0], vSpawnZonePos[1], vSpawnZonePos[2]);
				if (vSpawnZonePos[0] == 0.0 && vSpawnZonePos[1] == 0.0 && vSpawnZonePos[2] == 0.0) continue;
				fDistance = GetVectorDistance(vSpawnZonePos, vPos);
				if (fDistance <= fNearestDistance)
				{
					vNearestSpawnZone[0] = vSpawnZonePos[0];
					vNearestSpawnZone[1] = vSpawnZonePos[1];
					vNearestSpawnZone[2] = vSpawnZonePos[2];
					fNearestDistance = fDistance;
				}
			}	*/
		}
		if (fNearestDistance != 90000.0)
		{
			new Handle:hTrace = TR_TraceRayFilterEx(vNearestSpawnZone, Float:{90.0, 0.0, 0.0}, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, ExcludeSelfAndAlive);
			if (TR_DidHit(hTrace))
				TR_GetEndPosition(g_vIntelReturn, hTrace);
			else
			{
				g_vIntelReturn[0] = vNearestSpawnZone[0];
				g_vIntelReturn[1] = vNearestSpawnZone[1];
				g_vIntelReturn[2] = vNearestSpawnZone[2];
			}
			CloseHandle(hTrace);
			// Find the location of the weapon
			DispatchKeyValue(g_iPointFlagSpawnGlow, "model", "models/generic/flag_pole_animated.mdl");
			DispatchKeyValue(g_iPointFlagSpawnGlow, "modelscale", "0.5");
			DispatchKeyValue(g_iPointFlagSpawnGlow, "disablereceiveshadows", "0");
			DispatchKeyValue(g_iPointFlagSpawnGlow, "disableshadows", "0");
			DispatchKeyValue(g_iPointFlagSpawnGlow, "solid", "0");
			DispatchKeyValue(g_iPointFlagSpawnGlow, "spawnflags", "256");
			SetVariantString("idle");
			AcceptEntityInput(g_iPointFlagSpawnGlow, "SetAnimation");
			SetVariantString("idle");
			AcceptEntityInput(g_iPointFlagSpawnGlow, "SetDefaultAnimation");
			SetEntProp(g_iPointFlagSpawnGlow, Prop_Send, "m_CollisionGroup", 11);
			SetEntProp(g_iPointFlagSpawnGlow, Prop_Data, "m_nSkin", 2);
			
			// Spawn and teleport the entity
			DispatchSpawn(g_iPointFlagSpawnGlow);
			TeleportEntity(g_iPointFlagSpawnGlow, g_vIntelReturn, NULL_VECTOR, NULL_VECTOR);

			// Give glowing effect to the entity
			SetEntProp(g_iPointFlagSpawnGlow, Prop_Send, "m_bShouldGlow", enable);
			SetEntPropFloat(g_iPointFlagSpawnGlow, Prop_Send, "m_flGlowMaxDist", 1000000.0);

			SetVariantColor({30, 144, 255, 255});
			AcceptEntityInput(g_iPointFlagSpawnGlow, "SetGlowColor");
			AcceptEntityInput(g_iPointFlagSpawnGlow, "TurnOn");
			g_vIntelReturn[2] += 48.0;
			return true;
		}
		else LogError("Failed to setup flag capture point... (Point: %d)", g_iCurrentControlPoint);
	}
	g_iPointFlagSpawnGlow = INVALID_ENT_REFERENCE;
	return false;
}

stock CreatePointFlag(client = -1, bool:bNotice = true)
{
	new iPointFlag = CreateEntityByName("point_flag");
	if (iPointFlag > MaxClients && IsValidEntity(iPointFlag))
	{
		g_iPointFlag = EntIndexToEntRef(iPointFlag);
		g_bNoTakingCache = true;
		g_bDoNotPlayFlagPickUp = true;
		DispatchKeyValue(iPointFlag, "model", "models/generic/flag_pole_animated.mdl");
		DispatchKeyValueFloat(iPointFlag, "modelscale", 0.33);
		SetVariantInt(1);
		AcceptEntityInput(iPointFlag, "TeamNum");
		SetVariantString("idle");
		AcceptEntityInput(iPointFlag, "SetAnimation");
		SetVariantString("idle");
		AcceptEntityInput(iPointFlag, "SetDefaultAnimation");
		DispatchSpawn(iPointFlag);
		AcceptEntityInput(iPointFlag, "TurnOn");
		AcceptEntityInput(iPointFlag, "Enable");
		ActivateEntity(iPointFlag);

		decl Float:vPos[3];
		GetClientAbsOrigin(client, vPos);
		vPos[2] += 5.0;
		SetEntProp(iPointFlag, Prop_Data, "m_nSkin", GetRandomInt(0, 1) == 0?0:4);
		TeleportEntity(iPointFlag, vPos, NULL_VECTOR, NULL_VECTOR);
		new iOffset;
		if (!iOffset && (iOffset = GetEntSendPropOffs(iPointFlag, "m_clrGlow")) != -1)
		{
			SetEntProp(iPointFlag, Prop_Send, "m_bShouldGlow", true);
			SetEntProp(iPointFlag, Prop_Send, "m_nGlowStyle", 0);
			SetEntPropFloat(iPointFlag, Prop_Send, "m_flGlowMaxDist", 100000.0);
			SetEntData(iPointFlag, iOffset, 255, _, true);
			SetEntData(iPointFlag, iOffset + 1, 255, _, true);
			SetEntData(iPointFlag, iOffset + 2, 50, _, true);
			SetEntData(iPointFlag, iOffset + 3, 66, _, true);
		}
		if (bNotice)
		{
//			DisplayInstructorHint(0, 8.0, 0.0, 0.0, true, true, "icon_tip", "icon_tip", "", true, {255, 255, 255}, "Enemy has the intel, take it back to spawn!");
			DisplayInstructorHint(client, 8.0, 0.0, 0.0, true, true, "icon_interact", "icon_interact", "", true, {255, 255, 255}, "敌人拥有武器储备的情报！");
			CreatePointFlagSpawnGlow(-1, false);
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 0.1);
			CreateTimer(2.0, Timer_MoveAgain, client, TIMER_FLAG_NO_MAPCHANGE);
			PrintToChatAll("\x01敌人拥有武器储备的情报， \x08%s找到情报携带者 \x01并 \x08%s把情报归还至重生点", COLOR_INSURGENTS, COLOR_SECURITY);
			LogToGame("Intel gamemode activated and player choosed \"%N\"", client);
		}
		else LogToGame("Point Flag has been recreated to \"%N\"", client);
	}
	else
	{
		LogError("Intel Gamemode has been failed to setting, Point Flag entity \"%d\" is not valid", iPointFlag);
		g_iPointFlag = INVALID_ENT_REFERENCE;
		g_iPointFlagSpawnGlow = INVALID_ENT_REFERENCE;
	}
	return g_iPointFlag;
}

public Action:Timer_MoveAgain(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
}

public Action:Event_Catpurezone_Exit(Handle:event, const String:name[], bool:dontBroadcast)
{
/*		"owner" "short"
		"player" "short"
		"team" "short"
		"area" "byte"	*/
	new area = GetEventInt(event, "area");
//	PrintToChatAll("EXIT player %N area %d team %d owner %d", client, GetEventInt(event, "area"), GetEventInt(event, "team"), GetEventInt(event, "owner"));
	if (g_iCurrentControlPoint == area)
	{
		new client = GetEventInt(event, "player");
		g_bIsInCaptureZone[client] = false;
		if (IsFakeClient(client)) g_fSpawnTime[client] = GetGameTime();
//		LogToGame("%N exit capture zone", client);
	}
}

public Action:Event_PlayerActivate(Handle:event, const String:name[], bool:dontBroadcast)
	PlayerJoined(GetClientOfUserId(GetEventInt(event, "userid")));

stock PlayerJoined(client)
{
//	SDKHook(client, SDKHook_SetTransmit, SHook_OnTransmitForPlayers);
	SDKHook(client, SDKHook_TraceAttack, SHook_TraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, SHook_OnTakeDamage);
	g_iTeleportOnSpawn[client] = 0;
	g_bHasSquad[client] = false;
	WelcomeToTheCompany[client] = 0;
	g_iPlayerLastKnife[client] = -1;
	g_sPlayerClassTemplate[client] = "";
	g_iPlayerBonusScore[client] = 0;
	g_fPlayerLastChat[client] = 0.0;
	g_fMedicBannedTime[client] = 0.0;
	if (!IsFakeClient(client))
	{
		g_fPlayerAmbientTime[client] = 0.0;
		for (new i = 0;i < MAXPLAYER;i++)
		{
			if (g_iPlayersList[i] == -1 || !IsClientInGame(g_iPlayersList[i]))
			{
				g_iPlayersList[i] = client;
				break;
			}
		}
		SDKHook(client, SDKHook_PreThinkPost, SHook_OnPreThink);
		SDKHook(client, SDKHook_WeaponSwitch, SHook_WeaponSwitch);
		SDKHook(client, SDKHook_ShouldCollide, SHook_OnShouldCollide);
		SDKHook(client, SDKHook_Touch, SHook_OnPlayerTouch);
		// QueryClientConVar(client, "voice_inputfromfile", QueryConVar_HLSS);
	}
	else
	{
		decl String:name[64];
		Format(name, 64, "Zombie#%d", client);
		SetClientInfo(client, "name", name);
		CreateTimer(0.1, Timer_SetNetClassName, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_SetNetClassName(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		decl String:setname[MAX_NAME_LENGTH];
		GetClientInfo(client, "name", setname, sizeof(setname));
		SetEntPropString(client, Prop_Data, "m_szNetname", setname);
	}
}

public INS_OnPlayerResupplyed(client)
{
	PrintToChat(client, "\x05 >>> \x01已重新补给", COLOR_GOLD);
	if (IsPlayerAlive(client))
	{
		EmitSoundToAll("Lua_sounds/ammo_pickup.wav", client, SNDCHAN_STATIC, _, _, 1.0);
		if (g_iPLFBuyzone[client] == INVALID_ENT_REFERENCE)
		{
			LogToGame("[SPAWN ZONE] %N has been resupplyed", client);
			g_iPlayerBleeding[client] = 0;
			g_fPlayerBleedTime[client] = 0.0;
			g_iPlayerCustomGear[client] = -1;
			g_fLastMedicCall[client] = 0.0;
			g_iPlayerInfected[client] = 0;
			g_fNextInfection[client] = 0.0;
			SetEntityRenderColor(client, 255, 255, 255, 255);
	/*		if (g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]))
			{
				// PrintToServer("Removing #2");
				RequestFrame(DeleteEntity, EntIndexToEntRef(g_iPlayerTempProp[client]));
			}	*/
	//		g_iPlayerTempProp[client] = -1;
			g_fPlayerTempPropTimestamp[client] = 0.0;
			g_bPlayerTempPropSetup[client] = false;
			SetPlayerSkin(client, true);
		}
		else
		{
			LogToGame("[AMMO CRATE] %N has been resupplyed (%d / %d)", client, g_iPLFBuyzone[client], EntRefToEntIndex(g_iPLFBuyzone[client]));
			PrintToChatAll("\x01玩家 \x08%s%N  使用了\x04弹药箱\x01并重新补给了", GetPlayerChatColor(client), client);
			SetEntProp(client, Prop_Send, "m_iHealth", g_iPlayerLastHP[client]);
			SetEntPropFloat(g_iPLFBuyzone[client], Prop_Data, "m_flLocalTime", GetEntPropFloat(g_iPLFBuyzone[client], Prop_Data, "m_flLocalTime")-1.0);
			SetPlayerSkin(client, g_iPlayerCustomGear[client] > 0?true:false);
		}
	}
	else LogToGame("[DEAD] %N has been resupplyed", client);
}

stock SetPlayerSkin(client, bool:bGear = true)
{
/**
			Armor
		1 (Light) 3 (Heavy)

			Vest
		4~6

			Equip
		7 UAV
		8 Health kit
		9 Primary Sling
		10 Secondary Sling
		11 Portable Radar
		12 IED Jammer
		13 Barricade
		14 Ammo Crate
		28 NVG

			Characters
		15~17 (Sec) 18~20 (SCP) 21~22 (VIP) 23~24 (Umbrella)
**/
	new iChest = 0, iSling = 0, iCharacter = 0;
	if (g_iOffsetGears != -1)
	{
		for (new i = 0;i < 7;i++)
		{
			new gearId = GetEntData(client, g_iOffsetGears+(4*i));
			if (gearId == -1) continue;
			
			switch(gearId)
			{
				//case 4, 5, 6:	iChest = gearId;
				//case 9, 10:	iSling = gearId;
				//case 15, 16, 17, 18, 19, 20, 21, 22, 23, 24:	iCharacter = gearId;
			}

			if (gearId == 2)
			{
				new iWeapon = GivePlayerItem(client, "weapon_p2a1");
				if (iWeapon > MaxClients && IsValidEdict(iWeapon))
				{
//					SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, GetEntProp(iWeapon, Prop_Data, "m_iPrimaryAmmoType"));
//					FakeClientCommand(client, "use weapon_p2a1",);
//					PrintToChat(client, "\x08%sYou have a \x01UAV Flaregun\x08%s, fire weapon to use UAV  \x01(Slot 3)", COLOR_DARKORANGE, COLOR_DARKORANGE);
					LogToGame("%N has given p2a1 flaregun (%d)", client, iWeapon);
				}
			}

			if (gearId == 1)
			{
				new iWeapon = GivePlayerItem(client, "weapon_healthkit");
				if (iWeapon > MaxClients && IsValidEdict(iWeapon))
				{
//					new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo") + (GetEntProp(g_iPlayerHealthkitDeploy[client], Prop_Data, "m_iPrimaryAmmoType") * 4);
//					new iAmmo = GetEntData(client, iAmmoOffset);
//					FakeClientCommand(client, "use weapon_p2a1",);
					if (!g_bMedicPlayer[client])
					{
						SetEntProp(client, Prop_Data, "m_iAmmo", 2, _, GetEntProp(iWeapon, Prop_Data, "m_iPrimaryAmmoType"));
						PrintToChat(client, "\x08%s你拥有一个 \x01医疗包\x08%s, 对自己 (\x01鼠标左键\x08%s) 或者 对队友 (\x01鼠标右键\x08%s) 使用", COLOR_DARKORANGE, COLOR_DARKORANGE, COLOR_DARKORANGE, COLOR_DARKORANGE);
						PrintToChat(client, "(3号槽位)");
					}
					else
					{
						SetEntProp(client, Prop_Data, "m_iAmmo", 5, _, GetEntProp(iWeapon, Prop_Data, "m_iPrimaryAmmoType"));
						PrintToChat(client, "\x08%s你拥有一个 \x01医疗包 \x08%s[医疗兵]\x08%s, 对自己 (\x01鼠标左键\x08%s) 或者 对队友 (\x01鼠标右键\x08%s) 使用 \x01(3号槽位)", COLOR_DARKORANGE, COLOR_GOLD, COLOR_DARKORANGE, COLOR_DARKORANGE, COLOR_DARKORANGE);
					}
					LogToGame("%N has given first aid (%d)", client, iWeapon);
				}
			}

			if (bGear)
			{
				if (gearId == 5)
				{
					if (g_iPlayerLastKnife[client] != INVALID_ENT_REFERENCE && g_iPlayerLastKnife[client] != -1)
					{
						PrintToChat(client, "\x08%s你拥有一个 \x01便携雷达\x08%s, 可使用小刀布置 (\x01鼠标右键\x08%s)", COLOR_DARKORANGE, COLOR_DARKORANGE, COLOR_DARKORANGE);
						LogToGame("%N has set knife for portable radar (%d)", client, g_iPlayerLastKnife[client]);

	/*					if (g_iTomahawkModel[1] != -1)
							SetEntProp(g_iPlayerLastKnife[client], Prop_Send, "m_iWorldModelIndex", g_iTomahawkModel[1]);	*/
						g_iPlayerCustomGear[client] = 15;
					}
				}

				if (gearId == 4)
				{
					if (g_iPlayerLastKnife[client] != INVALID_ENT_REFERENCE && g_iPlayerLastKnife[client] != -1)
					{
						PrintToChat(client, "\x08%s你拥有一个 \x01IED干扰器\x08%s, 可使用小刀布置 (\x01鼠标右键\x08%s)", COLOR_DARKORANGE, COLOR_DARKORANGE, COLOR_DARKORANGE);
						LogToGame("%N has set knife for ied jammer (%d)", client, g_iPlayerLastKnife[client]);

	/*					if (g_iTomahawkModel[1] != -1)
							SetEntProp(g_iPlayerLastKnife[client], Prop_Send, "m_iWorldModelIndex", g_iTomahawkModel[1]);	*/
						g_iPlayerCustomGear[client] = 16;
					}
				}

				if (gearId == 6)
				{
					if (g_iPlayerLastKnife[client] != INVALID_ENT_REFERENCE && g_iPlayerLastKnife[client] != -1)
					{
						PrintToChat(client, "\x08%s你拥有一个 \x01路障\x08%s, 可使用小刀布置 (\x01鼠标右键\x08%s)", COLOR_DARKORANGE, COLOR_DARKORANGE, COLOR_DARKORANGE);
						LogToGame("%N has set knife for barricade (%d)", client, g_iPlayerLastKnife[client]);

	/*					if (g_iTomahawkModel[1] != -1)
							SetEntProp(g_iPlayerLastKnife[client], Prop_Send, "m_iWorldModelIndex", g_iTomahawkModel[1]);	*/
						g_iPlayerCustomGear[client] = 17;
					}
				}

				if (gearId == 3)
				{
					if (g_iPlayerLastKnife[client] != INVALID_ENT_REFERENCE && g_iPlayerLastKnife[client] != -1)
					{
						PrintToChat(client, "\x08%s你拥有一个 \x01弹药箱\x08%s, 可使用小刀布置 (\x01鼠标右键\x08%s)", COLOR_DARKORANGE, COLOR_DARKORANGE, COLOR_DARKORANGE);
						LogToGame("%N has set knife for ammo crate (%d)", client, g_iPlayerLastKnife[client]);

	/*					if (g_iTomahawkModel[1] != -1)
							SetEntProp(g_iPlayerLastKnife[client], Prop_Send, "m_iWorldModelIndex", g_iTomahawkModel[1]);	*/
						g_iPlayerCustomGear[client] = 18;
					}
				}
			}
		}
	}
	else
	{
		LogToGame("Failed to run \"m_iMyGear\" on \"CheckPlayerGears\"");
		LogError("Failed to run \"m_iMyGear\" on \"CheckPlayerGears\"");
	}

	new iBody = 1;
	if ((iCharacter >= 15 && iCharacter <= 20) || iCharacter == 23 || iCharacter == 24)
	{
		if (iSling > 0)
		{
			if (iChest == 4)
				iBody = 14;
			else if (iChest == 5)
				iBody = 17;
			else if (iChest == 6)
				iBody = 16;
			else
				iBody = 15;
		}
		else
		{
			if (iChest == 4)
				iBody = 3;
			else if (iChest == 5)
				iBody = 8;
			else if (iChest == 6)
				iBody = 7;
			else
				iBody = 3;
		}
	}
	else if (iCharacter == 21 || iCharacter == 22)
	{
		if (iSling > 0)
		{
			if (iChest == 4)
				iBody = 11;
			else if (iChest == 5)
				iBody = 17;
			else if (iChest == 6)
				iBody = 15;
			else
				iBody = 5;
		}
		else
		{
			if (iChest == 4)
				iBody = 7;
			else if (iChest == 5)
				iBody = 17;
			else if (iChest == 6)
				iBody = 15;
			else
				iBody = 1;
		}
	}
	SetEntProp(client, Prop_Send, "m_nBody", iBody);
//	CreateHelmet(client, 0);
}

public OnClientDisconnect(client)
{
//	SDKUnhook(client, SDKHook_TraceAttack, SHook_TraceAttack);
//	SDKUnhook(client, SDKHook_OnTakeDamage, SHook_OnTakeDamage);
//	WelcomeToTheCompany[client] = 0;
	g_fSuppressedTime[client] = 0.0;
	g_hFFTimer[client] = INVALID_HANDLE;
	g_hYellTimer[client] = INVALID_HANDLE;
	g_hSuppressTimer[client] = INVALID_HANDLE;
//	RemoveHelmet(client);
	RemoveCustomFlags(client);
	ZombieBurnSound(client, false);
	if (g_bMedicPlayer[client]) g_bMedicPlayer[client] = false;
	if (g_iZombieClass[client][CLASS] > -1)
		g_iZombieSpawnCount[g_iZombieClass[client][CLASS]]--;
	if (g_iPlayerHealthkitTarget[client] != -1)
	{
		g_iPlayerHealthkitHealingBy[g_iPlayerHealthkitTarget[client]] = -1;
		g_iPlayerHealthkitTarget[client] = -1;
	}
	if (g_iPlayerHealthkitHealingBy[client] != -1)
		g_iPlayerHealthkitTarget[g_iPlayerHealthkitHealingBy[client]] = -1;
	if (g_fPlayerHealthkitBandaging[client] != 0.0 || g_bPlayerBandageSound[client])
	{
		if (IsClientInGame(client)) StopSound(client, SNDCHAN_STATIC, "Lua_sounds/bandaging.wav");
		g_fPlayerHealthkitBandaging[client] = 0.0;
	}
	if (g_fPlayerTempPropTimestamp[client] != 0.0 && g_iPlayerTempProp[client] > MaxClients && IsValidEntity(g_iPlayerTempProp[client]))
	{
		// PrintToServer("Removing #3");
		decl String:targetname[64];
		GetEntPropString(g_iPlayerTempProp[client], Prop_Data, "m_iName", targetname, sizeof(targetname));
		if (StrEqual(targetname, "LuaCustomModel", true))
		{
			LogToGame("%N is installing gear id %d but disconnect before complete %d", client, g_iPlayerCustomGear[client], g_iPlayerTempProp[client]);
			RequestFrame(DeleteEntity, EntIndexToEntRef(g_iPlayerTempProp[client]));
		}
	}
	g_iPlayerTempProp[client] = -1;
	g_fPlayerTempPropTimestamp[client] = 0.0;
	for (new i = 0;i < MAXPLAYER;i++)
	{
		if (client == g_iPlayersList[i])
		{
			g_iPlayersList[i] = -1;
			break;
		}
	}
//	if (!IsFakeClient(client))
//		SDKUnhook(client, SHook_OnPreThink, SHook_OnPreThink);
}

public Action:Command_TeamSay(client, args)
{
	if (args <= 0) return Plugin_Continue;
	decl String:text[257];

	new startidx = 0;
	GetCmdArgString(text, sizeof(text));
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;	
	}
	
	FakeClientCommand(client, "say %s", text[startidx]);
	return Plugin_Handled;
}

public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[])
{
//		MAXLENGTH_MESSAGE
	new iTeam = GetClientTeam(author);
	if (iTeam != TEAM_ZOMBIES)
	{
		if (IsLeader(author))
		{
			if (g_bMedicPlayer[author])
				Format(name, 255, "\x08%s[医疗]  %s", COLOR_GOLD, name);
			else
				Format(name, 255, "\x08%s[队长]  %s", COLOR_GOLD, name);
		}
		else
		{
			if (StrEqual(g_sPlayerClassTemplate[author], "gnalvl_pointman_usmc", false))
				Format(name, 255, "\x08%s[步枪]  %s", COLOR_WHITE, name);
			else if (StrEqual(g_sPlayerClassTemplate[author], "Gnalvl_engineer_usmc_1", false))
				Format(name, 255, "\x08%s[霰弹]  %s", COLOR_WHITE, name);
			else if (StrEqual(g_sPlayerClassTemplate[author], "Gnalvl_support_usmc_1", false))
				Format(name, 255, "\x08%s[机枪]  %s", COLOR_WHITE, name);
			else if (StrEqual(g_sPlayerClassTemplate[author], "Gnalvl_marksman_usmc_1", false))
				Format(name, 255, "\x08%s[狙击]  %s", COLOR_WHITE, name);
			else if (StrEqual(g_sPlayerClassTemplate[author], "Gnalvl_marksman_usmc_2", false))
				Format(name, 255, "\x08%s[狙击]  %s", COLOR_WHITE, name);
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock String:GetPlayerChatColor(client)
{
	new String:sColor[9] = COLOR_SECURITY;
	if (GetClientTeam(client) == TEAM_ZOMBIES)
		sColor = COLOR_INSURGENTS;
	return sColor;
}

public Action:Event_GameLog(const String:message[])
{
	if (StrContains(message[15], "stuck (pos", true) != -1)
	{
/*
"BOT Charlie<4><BOT><3>" stuck (position "48.30 -555.03 -311.97") (duration "7.78")
"Mua<4><BOT><3>" stuck (position "48.30 -555.03 -311.97") (duration "7.78")
*/
		// Stuck duration checking
		// if (StrContains(message[55], "ation \"10.", true) != -1 || StrContains(message[55], "ation \"11.", true) != -1  || StrContains(message[55], "ation \"12.", true) != -1)
		if (StrContains(message[55], "ation \"6.", true) != -1 || StrContains(message[55], "ation \"7.", true) != -1  || StrContains(message[55], "ation \"8.", true) != -1)
		{
			new iCharFound = 0, client = 0, String:sChar[1];
			for (new i = 0;i < 64;i++)
			{
				sChar[0] = message[i];
				if (StrEqual(sChar, "<", false))
				{
					iCharFound = i;
					break;
				}
			}
//			PrintToChatAll("iCharFound %d", iCharFound);
			for (new i = 1;i < 5;i++)
			{
				sChar[0] = message[iCharFound+i];
//				PrintToChatAll("%d - %s", iCharFound+i, sChar);
				if (!StrEqual(sChar, ">", false))
				{
					if (client == 0)
						client = StringToInt(sChar);
					else
						client = (client*10)+StringToInt(sChar);
				}
				else break;
			}
			client = GetClientOfUserId(client);
			if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_ZOMBIES)
			{
				// LogToGame("%N has teleported due to stuck too long", client);
				// TeleportOnSpawn(client, 1);
				LogToGame("Zombie %N has killed due to stuck too long", client);
				ForcePlayerSuicide(client);
			}
		}
	}
	return Plugin_Continue;
}

public Action:WelcomeToTheCompany_rly(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientTimingOut(client))
	{
		switch(WelcomeToTheCompany[client])
		{
			case 1:
			{
				WelcomeToTheCompany[client] = 2;
				CreateTimer(6.0, WelcomeToTheCompany_rly, client, TIMER_FLAG_NO_MAPCHANGE);
				ClientCommand(client, "playgamesound vo/warehouse_training/vip_training1.2.wav");
			}
			case 2: 
			{
				WelcomeToTheCompany[client] = -1;
				ClientCommand(client, "playgamesound vo/warehouse_training/vip_training41.3.wav");
			}
			default:
			{
				WelcomeToTheCompany[client] = 1;
				CreateTimer(2.1, WelcomeToTheCompany_rly, client, TIMER_FLAG_NO_MAPCHANGE);
				ClientCommand(client, "playgamesound vo/warehouse_training/vip_training1.1.wav");
			}
		}
	}
}

stock DoPointHurt(const Float:origin[3], target = 0, attacker = -1, radius = 300, damage = 10, Float:delay, damagetype = DMG_GENERIC, String:damagename[] = "", Float:autokill = 0.0)
{
	new PointHurt = CreateEntityByName("point_hurt");
	if (PointHurt)
	{
		new String:delay_str[16];
		new String:radius_str[16];
		new String:dmg_str[8];
		new String:dmg_type_str[32];
		new String:originData[64];
		Format(originData, sizeof(originData), "%f %f %f", origin[0], origin[1], origin[2]);

		FloatToString(delay, delay_str, sizeof(delay_str));
		IntToString(radius, radius_str, sizeof(radius_str));
		IntToString(damage, dmg_str, sizeof(dmg_str));
		IntToString(damagetype, dmg_type_str, sizeof(dmg_type_str));
		if (target > 0 && target <= MaxClients && IsClientInGame(target))
		{
			decl String:targetname[64];
			Format(targetname, sizeof(targetname), "ins_point_hurt%d", PointHurt);
			DispatchKeyValue(target, "targetname", targetname);
			DispatchKeyValue(PointHurt, "DamageTarget", targetname);
		}
		if (damagename[0] == '\0')
			DispatchKeyValue(PointHurt, "classname", damagename);

		DispatchKeyValue(PointHurt, "Origin", originData);
		DispatchKeyValue(PointHurt, "DamageDelay", delay_str);
		DispatchKeyValue(PointHurt, "DamageRadius", radius_str);
		DispatchKeyValue(PointHurt, "Damage", dmg_str);
		DispatchKeyValue(PointHurt, "DamageType", dmg_type_str);
		DispatchSpawn(PointHurt);
		TeleportEntity(PointHurt, origin, NULL_VECTOR, NULL_VECTOR);
//		TeleportEntity(PointHurt, origin, NULL_VECTOR, NULL_VECTOR);
		if (autokill < 0.1)
		{
			AcceptEntityInput(PointHurt, "Hurt", (attacker>0)?attacker:-1);
//			AcceptEntityInput(PointHurt, "Kill");
			// PrintToServer("Removing #4");
			RequestFrame(DeleteEntity, EntIndexToEntRef(PointHurt));
		}
		else
		{
			AcceptEntityInput(PointHurt, "TurnOn");
			decl String:addoutput[64];
			Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1", autokill);
			SetVariantString(addoutput);
			AcceptEntityInput(PointHurt, "AddOutput");
			AcceptEntityInput(PointHurt, "FireUser1");
//			CreateTimer(autokill, DeletePointHurt, EntIndexToEntRef(PointHurt), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}
/*
public RoundTime(any:time)
{
	SetRoundTime(time);
}
*/
public DeleteEntity(any:refentity)
{
	new entity = EntRefToEntIndex(refentity);
	if (entity > MaxClients && IsValidEntity(refentity))
	{
		// PrintToServer("Removing...");
		LogToGame("Entity %d (%d) has been removed", entity, refentity);
		RemoveEdict(entity);
	}
}

stock PlayerYell(client, type = 0, bool:ignorecooltime = false, Float:chance = 100.00, target = 0, Float:forcedcooltime = 0.0)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return false;
	if (chance < 100.00 && GetRandomFloat(0.1, 100.00) > chance) return false;
	if (ignorecooltime || (forcedcooltime == 0.0 && g_fLastYellTime[client]+GetRandomFloat(FCVAR_PLAYER_YELL_COOLDOWN_MIN, FCVAR_PLAYER_YELL_COOLDOWN_MAX) <= g_fGameTime) || (forcedcooltime != 0.0 && g_fLastYellTime[client]+forcedcooltime <= g_fGameTime))
	{
/*		if (type != 2)
			LogToGame("Player \"%N\" Yelled type \"%d\" with %0.2f chances%s", client, type, chance, !ignorecooltime?"":" and bypass cooltimes");
		else if (target == -1)	//	Kill confirm and timer return as target = -1
			LogToGame("Player \"%N\" Yelled type \"2\" from timers", client);
		else					//	Kill confirm and timer started
			LogToGame("Player \"%N\" Yelled type \"2\" with %0.2f chances%s", client, chance, !ignorecooltime?"":" and bypass cooltimes");	*/
		LogToGame("Player \"%N\" Yelled type \"%d\" with %0.2f chances%s", client, type, chance, !ignorecooltime?"":" and bypass cooltimes");
		new String:sSoundFile[255];
		switch(type)
		{
			case 0:		// Weapon cache ignition
			{
				new iNum = GetRandomInt(0, 7);
				switch(iNum)
				{
					case 0: iNum = GetRandomInt(5, 8);
					case 1: iNum = GetRandomInt(11, 14);
					case 2: iNum = GetRandomInt(16, 22);
					case 3: iNum = 25;
					case 4: iNum = GetRandomInt(27, 28);
					case 5: iNum = 32;
					case 6: iNum = 36;
					case 7: iNum = GetRandomInt(6, 7);
				}
				if (iNum != 6 && iNum != 7) Format(sSoundFile, sizeof(sSoundFile), "player/voice/botsurvival/subordinate/incominggrenade%d.ogg", iNum);
				else Format(sSoundFile, sizeof(sSoundFile), "player/voice/responses/security/subordinate/damage/molotov_incendiary_detonated%d.ogg", iNum);
				PlaySoundOnPlayer(client, sSoundFile);
			}

			case 1:		// Hurts by teammate
			{
				if (g_fGameTime-g_fLastYellTime[client] >= FCVAR_PLAYER_YELL_COOLDOWN_FRIENDLYFIRE)
				{
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/responses/security/subordinate/unsuppressed/watchfire%d.ogg", GetRandomInt(1, 15));
					PlaySoundOnPlayer(client, sSoundFile);
				}
			}

			case 2:		// Kill confirm
			{
/*				if (target > 0 && target <= MaxClients && IsClientInGame(target))
				{
					decl Float:vTargetPos[3], Float:vPlayerPos[3];
					GetClientEyePosition(client, vPlayerPos);
					GetClientEyePosition(target, vTargetPos);
					g_hYellTimer[client] = CreateTimer((GetVectorDistance(vPlayerPos, vTargetPos)*0.01905)*GetRandomFloat(0.006, 0.014), Timer_KillConfirm, client, TIMER_FLAG_NO_MAPCHANGE);
					g_fLastYellTime[client] = g_fGameTime;
					return true;
				}	*/
				new iNum, iType = 0;
				if (g_fGameTime-g_fSuppressedTime[client] < 10.01)
					iType = GetRandomInt(7, 9);	// Should be Suppressed
				else
					iType = GetRandomInt(0, 6);
				switch(iType)
				{
					//Unsuppressed
					// player/voice/botsurvival/subordinate/target%d.ogg
					case 0: iNum = 2;
					case 1: iNum = GetRandomInt(4, 5);
					case 2: iNum = GetRandomInt(8, 9);
					case 3: iNum = 11;
					case 4: iNum = 13;
					//player/voice/responses/security/subordinate/unsuppressed/target%d.ogg
					case 5: iNum = 1;
					case 6: iNum = 3;
					//Suppressed
					//player/voice/responses/security/subordinate/suppressed/target%d.ogg
					case 7: iNum = GetRandomInt(2, 4);
					case 8: iNum = 7;
					case 9: iNum = GetRandomInt(10, 12);
				}
				if (iType >= 0 && iType <= 4)
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/botsurvival/subordinate/target%d.ogg", iNum);
				else if (iType >= 7 && iType <= 9)
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/responses/security/subordinate/suppressed/target%d.ogg", iNum);
				else
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/responses/security/subordinate/unsuppressed/target%d.ogg", iNum);
				PlaySoundOnPlayer(client, sSoundFile);
			}

			case 3:		//	Explosion nearby
			{
				new iNum = 5, iType = 0;
				if (!IsLightModel(client)) iType = GetRandomInt(0, 3);
				else iType = 3;
				switch(iType)
				{
					case 0: iNum = 3;
					case 1: iNum = 5;
					case 2: iNum = 23;
					case 3: iNum = GetRandomInt(4, 8);
				}
				if (iType != 3)
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/botsurvival/subordinate/flashbanged%d.ogg", iNum);
				else
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/botsurvival/leader/flashbanged%d.ogg", iNum);
				PlaySoundOnPlayer(client, sSoundFile);
			}

			case 4:		//	Rockets firing by player
			{
//				new iNum = 5, iType = GetRandomInt(0, 2); // Leader voice sux!
/*				new iNum = 5, iType = GetRandomInt(0, 1);
				switch(iType)
				{
					case 0: iNum = 1;
					case 1: iNum = 4;
					case 2: iNum = GetRandomInt(1, 4);
				}
				if (iType != 2)
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/responses/security/subordinate/coop/rpg%d.ogg", iNum);
				else
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/responses/security/leader/coop/rpg%d.ogg", iNum);	*/
				if (!IsLightModel(client))
					sSoundFile = "player/voice/responses/security/subordinate/coop/rpg4.ogg";
				else
					sSoundFile = "player/voice/responses/security/leader/coop/rpg2.ogg";
				PlaySoundOnPlayer(client, sSoundFile);
			}

			case 5:		//	Knives kill
			{
				new iNum = GetRandomInt(1, 3);
				if (!IsLightModel(client))
				{
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/radial/security/subordinate/unsuppressed/enemydown_knifekill%d.ogg", iNum);
					PlaySoundOnPlayer(client, sSoundFile);
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/radial/security/subordinate/unsuppressed/radio/enemydown_knifekill%d_radio.ogg", iNum);
				}
				else
				{
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/radial/security/leader/unsuppressed/enemydown_knifekill%d.ogg", iNum);
					PlaySoundOnPlayer(client, sSoundFile);
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/radial/security/leader/unsuppressed/radio/enemydown_knifekill%d_radio.ogg", iNum);
				}
				decl Float:vOrigin[3], Float:vTargetOrigin[3];
				GetClientEyePosition(client, vOrigin);
				for (new j = 0;j < MAXPLAYER; j++)
				{
					if (g_iPlayersList[j] == -1) continue;
					new i = g_iPlayersList[j];
					GetClientEyePosition(i, vTargetOrigin);
					if (GetVectorDistance(vOrigin, vTargetOrigin) > 650.0)
						ClientCommand(i, "playgamesound %s", sSoundFile);
				}
			}

			case 6:		//	Grenade Direct kill
			{
				if (!IsLightModel(client))
				{
					if (GetRandomInt(0, 1) == 0)
						sSoundFile = "player/voice/radial/security/subordinate/unsuppressed/enemydown_knifekill1.ogg";
					else
						sSoundFile = "player/voice/radial/security/subordinate/unsuppressed/enemydown_knifekill3.ogg";
				}
				else
				{
					if (GetRandomInt(0, 1) == 0)
						sSoundFile = "player/voice/radial/security/leader/unsuppressed/enemydown_knifekill1.ogg";
					else
						sSoundFile = "player/voice/radial/security/leader/unsuppressed/enemydown_knifekill3.ogg";
				}
				PlaySoundOnPlayer(client, sSoundFile);
			}

			case 7:		//	Suppressed target
			{
				if (!IsLightModel(client))
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/botsurvival/subordinate/suppress%d.ogg", GetRandomInt(1, 15));
				else
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/botsurvival/leader/suppress%d.ogg", GetRandomInt(1, 15));
				PlaySoundOnPlayer(client, sSoundFile);
			}

			case 8:		//	Incoming Grenade
			{
				if (!IsLightModel(client))
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/botsurvival/subordinate/incominggrenade%d.ogg", GetRandomInt(1, 36));
				else
					Format(sSoundFile, sizeof(sSoundFile), "player/voice/botsurvival/leader/incominggrenade%d.ogg", GetRandomInt(1, 33));
				PlaySoundOnPlayer(client, sSoundFile);
			}

			case 9:		//	Request Medic
			{
				if (target == 0)	// Death
					Format(sSoundFile, sizeof(sSoundFile), "lua_sounds/medic/medic_dying%d.ogg", GetRandomInt(1, 3));
				else if (target == 1)	// Critical
					Format(sSoundFile, sizeof(sSoundFile), "lua_sounds/medic/medic_critical%d.ogg", GetRandomInt(1, 16));
				else //if (target == 2)	// Injured	// 3 Healthy
					Format(sSoundFile, sizeof(sSoundFile), "lua_sounds/medic/medic_injured%d.ogg", GetRandomInt(1, 22));
				decl Float:vOrigin[3];
				GetClientEyePosition(client, vOrigin);
				for (new j = 0;j < MAXPLAYER; j++)
				{
					if (g_iPlayersList[j] == -1 || client == g_iPlayersList[j] || !IsPlayerAlive(g_iPlayersList[j]))
						continue;
					new i = g_iPlayersList[j];
					decl Float:vTargetOrigin[3];
					GetClientEyePosition(i, vTargetOrigin);
					new Float:fDistance = GetVectorDistance(vOrigin, vTargetOrigin);
					if (fDistance >= 650.0)
					{
						new Float:fVol = 0.1;
						if (fDistance <= 800.0) fVol = 0.4;
						else if (fDistance <= 1000.0) fVol = 0.3;
						else if (fDistance <= 1200.0) fVol = 0.2;
						EmitSoundToClient(i, sSoundFile, _, SNDCHAN_AUTO, _, _, fVol);
					}
				}
				PlaySoundOnPlayer(client, sSoundFile, SNDCHAN_STATIC);
			}

			case 10:		//	Damaged by fire
			{
				if (GetRandomInt(0, 2) != 2)
					Format(sSoundFile, sizeof(sSoundFile), "player/damage/pl_damage_major_0%d.wav", GetRandomInt(1, 9));
				else
					Format(sSoundFile, sizeof(sSoundFile), "player/damage/pl_damage_major_%d.wav", GetRandomInt(10, 14));
				PlaySoundOnPlayer(client, sSoundFile);
			}
		}
		g_fLastYellTime[client] = g_fGameTime;
		return true;
	}
	return false;
}

public Action:Timer_KillConfirm(Handle:timer, any:client)
{
	if (timer == g_hYellTimer[client] && IsClientInGame(client) && IsPlayerAlive(client))
	{
		g_hYellTimer[client] = INVALID_HANDLE;
		PlayerYell(client, 2, true, 100.0, -1);
	}
}

stock PlaySoundOnPlayer(client, const String:soundfile[], channel = SNDCHAN_VOICE)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return false;
	EmitSoundToAll(soundfile, client, channel, _, _, 1.0);
//	if (IsSoundPrecached(soundfile))
//	else return false;
	return true;
}

stock SetWeaponCacheModel(iobject = -1, bool:reset = false)
{
	g_iGameState = GetGameState();
	if (g_iGameState != 4)
	{
		LogToGame("SetWeaponCacheModel fuction skipped due to game is not yet started (%d)", GetGameState());
		return false;
	}
	new String:sClassName[128], String:sModelPath[128];
	if (iobject > MaxClients && IsValidEntity(iobject))
	{
		if (!IsValidEntity(iobject)) return false;

		GetEntityClassname(iobject, sClassName, sizeof(sClassName));
		if (StrEqual(sClassName, "obj_weapon_cache", false) || (g_iFixMapLocation == 2 && StrEqual(sClassName, "obj_destructible", false)))
		{
			GetEntPropString(iobject, Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
			if (reset || (GetEntProp(iobject, Prop_Data, "m_lifeState") == 2 && StrContains(sModelPath, "_destr", false) == -1 && StrContains(sModelPath, "ins_radio", false) == -1))
			{
				if (!reset)
				{
					if (StrContains(sModelPath, "_destr.mdl", false) == -1 && StrContains(sModelPath, "ins_radio", false) == -1)
						ReplaceString(sModelPath, sizeof(sModelPath), ".mdl", "_destr.mdl", false);
				}
				else
				{
					if (StrContains(sModelPath, "_destr.mdl", false) != -1)
						ReplaceString(sModelPath, sizeof(sModelPath), "_destr.mdl", ".mdl", false);
				}
//				ReplaceString(sModelPath, sizeof(sModelPath), "_destr_destr.mdl", "_destr.mdl", false);
				SetEntityModel(iobject, sModelPath);
				if (!reset) SetEntProp(iobject, Prop_Data, "m_nSkin", 0);
				if (StrContains(sModelPath, "wcache_sec_01", false) == -1)
					SetEntProp(iobject, Prop_Send, "m_CollisionGroup", 26);
				else
					SetEntProp(iobject, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
				LogToGame("Weapon Cache %d model has been update to %s model \"%s\"", iobject, !reset?"destroyed":"new", sModelPath);
			}
		}
		else
		{
			LogError("Entity %d is \"%s\" not obj_weapon_cache", iobject, sClassName);
			return false;
		}
	}
	else if (iobject == -1)	// Set all weapon caches to new model
	{
		for (new entity = MaxClients+1;entity < GetMaxEntities();entity++)
		{
			if (!IsValidEntity(entity)) continue;

			GetEntityClassname(entity, sClassName, sizeof(sClassName));
			if (StrEqual(sClassName, "obj_weapon_cache", false) /*|| StrEqual(sClassName, "obj_destructible", false)*/)
			{
				if (GetEntProp(entity, Prop_Data, "m_lifeState") != 2)
				{
					switch(GetRandomInt(1, 4))
					{
						case 1:
						{
							SetEntityModel(entity, "models/static_props/weapon_cache_01.mdl");
							if (FindDataMapInfo(entity, "m_nSkin") != -1)
								SetEntProp(entity, Prop_Data, "m_nSkin", 1);
							SetEntProp(entity, Prop_Send, "m_CollisionGroup", 26);
							LogToGame("Weapon Cache %d model has been set to new model \"models/static_props/weapon_cache_01.mdl\" skin: 1", entity);
						}
						case 2:
						{
							SetEntityModel(entity, "models/static_props/wcache_ins_01.mdl");
							if (FindDataMapInfo(entity, "m_nSkin") != -1)
								SetEntProp(entity, Prop_Data, "m_nSkin", 0);
							SetEntProp(entity, Prop_Send, "m_CollisionGroup", 26);
							LogToGame("Weapon Cache %d model has been set to new model \"models/static_props/wcache_ins_01.mdl\"", entity);
						}
						case 3:
						{
							SetEntityModel(entity, "models/static_props/weapon_cache_01.mdl");
							if (FindDataMapInfo(entity, "m_nSkin") != -1)
								SetEntProp(entity, Prop_Data, "m_nSkin", 0);
							SetEntProp(entity, Prop_Send, "m_CollisionGroup", 26);
							LogToGame("Weapon Cache %d model has been set to new model \"models/static_props/weapon_cache_01.mdl\" skin: 0", entity);
						}
						default:	// Problem with collision and destory model set back to default model
						{
							SetEntityModel(entity, "models/static_props/wcache_sec_01.mdl");
							if (FindDataMapInfo(entity, "m_nSkin") != -1)
								SetEntProp(entity, Prop_Data, "m_nSkin", 0);
							SetEntProp(entity, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
							LogToGame("Weapon Cache %d model has been set to new model \"models/static_props/wcache_sec_01.mdl\"", entity);
						}
					}
				}
				else
				{
					GetEntPropString(entity, Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
					if (StrContains(sModelPath, "_destr", false) == -1 && StrContains(sModelPath, "ins_radio", false) == -1)
					{
						ReplaceString(sModelPath, sizeof(sModelPath), ".mdl", "_destr.mdl", false);
//						ReplaceString(sModelPath, sizeof(sModelPath), "_destr_destr.mdl", "_destr.mdl", false);
						SetEntityModel(entity, sModelPath);
						if (FindDataMapInfo(entity, "m_nSkin") != -1)
								SetEntProp(entity, Prop_Data, "m_nSkin", 0);
						if (!StrEqual(sModelPath, "models/static_props/wcache_sec_01.mdl", false))
							SetEntProp(entity, Prop_Send, "m_CollisionGroup", 26);
						else
							SetEntProp(entity, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
						LogToGame("Weapon Cache %d model has been update to destroyed model \"%s\"", entity, sModelPath);
					}
				}
			}
		}
	}
	return true;
}

stock CheckWeaponCache(bool:bCheckObject = false)
{
	if (g_iGameState != 4 && g_iGameState != 3)
	{
		LogToGame("CheckWeaponCache fuction skipped due to game is not yet started (%d)", g_iGameState);
		return false;
	}
	if (!g_bSkipCacheCheck)
	{
		new iCacheCount = 0;
		for (new i = 0;i < 16;i++)
		{
			if (bCheckObject)
				g_iCPIndex[i] = INVALID_ENT_REFERENCE;
			if (g_iCPType[i] == 0)
				iCacheCount++;
		}
		if (iCacheCount == 0)
		{
			g_bSkipCacheCheck = true;
			LogToGame("There are zero Weapon Cache to check on this map...");
			return true;
		}
		else
		{
			new String:sClassName[128], iObject[MAX_OBJECTIVE], Float:vObjectOrigin[iCacheCount][3], iEntityCount = 0;
			for (new entity = MaxClients+1;entity < GetMaxEntities();entity++)
			{
				if (!IsValidEntity(entity)) continue;

				GetEntityClassname(entity, sClassName, sizeof(sClassName));
				if (StrEqual(sClassName, "obj_weapon_cache", false) || (g_iFixMapLocation == 2 && StrEqual(sClassName, "obj_destructible", false)))
				{
					SetWeaponCacheModel(entity);
					SetEntData(entity, g_iOffsetWeaponCacheGlow, 0);
					if (bCheckObject)
					{
						iObject[iEntityCount] = entity;
						GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vObjectOrigin[iEntityCount++]);
					}
					if (iEntityCount >= iCacheCount) break;
				}
			}
			if (bCheckObject)
			{
				for (new i = 0;i < 16;i++)
				{
					if (g_iCPType[i] != 0) continue;
					new Float:fNearestDistance = 9999.9, iNearest = -1;
					for (new j = 0;j < iCacheCount;j++)
					{
						new Float:fDistance = GetVectorDistance(g_vCPPositions[i], vObjectOrigin[j]);
						if (fDistance <= fNearestDistance)
						{
							iNearest = j;
							fNearestDistance = fDistance;
						}
					}
					if (iNearest != -1)
					{
						g_iCPIndex[i] = EntIndexToEntRef(iObject[iNearest]);
//						SetEntProp(g_iCPIndex[i], Prop_Data, "m_bTakeDamageBullets", 1);
						SetVariantBool(true);
						AcceptEntityInput(g_iCPIndex[i], "TakeDamageBullets");
						SDKHook(g_iCPIndex[i], SDKHook_OnTakeDamage, ObjectOnTakeDamage);
//						SetEntData(g_iCPIndex[i], g_iOffsetWeaponCacheGlow, 1);
						LogToGame("Point %d. Object Weapon Cache Found %d (%d) - %0.2f, %0.2f, %0.2f (Dist: %0.2f)", i, g_iCPIndex[i], iObject[iNearest], vObjectOrigin[iNearest][0], vObjectOrigin[iNearest][1], vObjectOrigin[iNearest][2], fNearestDistance);
						if (i >= g_iNumControlPoints-1) break;
					}
					else if (i < g_iNumControlPoints)
					{
						LogError("Couldn't find Object Weapon Cache for Point %d - %0.2f, %0.2f, %0.2f", i, g_vCPPositions[i][0], g_vCPPositions[i][1], g_vCPPositions[i][2]);
					}
				}
			}/*
			for (new i = 0;i < 16;i++)
			{
				if (g_iCPType[i] != 0 && g_iCPIndex[i] != -1) continue;
				LogError("Point %d couldn't find a Object Weapon Cache. Trying to find nearest object", i);
				new Float:fNearestDistance = 9999.0, iNearestObject = -1, iNearestPoint;
				for (new j = 0;j < iCacheCount;j++)
				{
					new Float:fDistance = GetVectorDistance(g_vCPPositions[i], vObjectOrigin[j]);
					if (fDistance <= fNearestDistance)
					{
						iNearestPoint = j;
						iNearestObject = iObject[j];
						fNearestDistance = fDistance;
					}
				}
				if (iNearestObject != -1)
				{
					g_iCPIndex[i] = iNearestObject;
					LogToGame("%d. (NEAREST) Object Weapon Cache Found %d - %0.2f, %0.2f, %0.2f (Dist: %0.2f)", i, g_iCPIndex[i], vObjectOrigin[iNearestPoint][0], vObjectOrigin[iNearestPoint][1], vObjectOrigin[iNearestPoint][2], fNearestDistance);
				}
				else
				{
					LogError("Couldn't find Object Weapon Cache for Point %d - %0.2f, %0.2f, %0.2f", i, g_vCPPositions[i][0], g_vCPPositions[i][1], g_vCPPositions[i][2]);
				}
			}	*/
		}
	}
	return true;
}

stock RespawnPlayer(client, teleport = 0)
{
	if (client < 1 || client > MaxClients) return;
	if (!IsClientInGame(client) || !g_bHasSquad[client] || GetClientTeam(client) <= 1) return;
	if (DEBUGGING_ENABLED) LogToGame("Player \"%N\" %s", client, !IsPlayerAlive(client)?"spawned":"respawned");
/*	if (g_iEntityCount >= 1800)
	{
		LogToGame("Too many entities spawned therefore remove weapons when player died (%N)", client);
		Client_RemoveAllWeapons2(client, "weapon_kabar");
	}	*/
	g_iTeleportOnSpawn[client] = teleport;
	SDKCall(g_hPlayerRespawn, client);
}

stock ResizePlayer(client, Float:size = 1.0)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return false;
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];
/*
Lua [MIN] -17.00, -17.00, 0.00 -- standing
Lua [MAX] 17.00, 17.00, 75.00
Lua [MIN] -17.00, -17.00, 0.00 -- ducking
Lua [MAX] 17.00, 17.00, 49.00
Lua [MIN] -17.00, -17.00, 0.00 -- prone
Lua [MAX] 17.00, 17.00, 24.00
*/
	vecScaledPlayerMin = Float:{-17.00, -17.00, 0.0};
	vecScaledPlayerMax = Float:{17.00, 17.00, 75.0};
/*	GetClientMins(client, vecScaledPlayerMin);
	GetClientMaxs(client, vecScaledPlayerMax);
	ScaleVector(vecScaledPlayerMin, size*1.15);
	ScaleVector(vecScaledPlayerMax, size*1.15);	*/
	ScaleVector(vecScaledPlayerMin, size);
	ScaleVector(vecScaledPlayerMax, size);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", size);
//	SetEntProp(client, Prop_Send, "m_ScaleType ", 3);
	return true;
}

stock PlayGameSoundToAll(const String:sample[], without = 0)
{
	for (new j = 0;j < MAXPLAYER; j++)
	{
		if (g_iPlayersList[j] == -1 || g_iPlayersList[j] == without) continue;
//		StopSound(g_iPlayersList[j], SNDCHAN_AUTO, sample);
		ClientCommand(g_iPlayersList[j], "playgamesound %s", sample);
	}
}

stock bool:IsLeader(client)
{
	if (!IsClientInGame(client)) return false;
	if (IsRecon(client) || IsMedic(client))
		return true;
	return false;
}

stock bool:IsRecon(client)
{
	if (!IsClientInGame(client)) return false;
	if (GetPlayerSquad(client, g_iPlayerManager, g_iOffsetSquad) == 1 && GetPlayerSquadSlot(client, g_iPlayerManager, g_iOffsetSquadSlot) == 2)
		return true;
	return false;
}

stock bool:IsMedic(client)
{
	if (!IsClientInGame(client)) return false;
	if (GetPlayerSquadSlot(client, g_iPlayerManager, g_iOffsetSquadSlot) == 5)
		return true;
	return false;
}

stock GetEffectIndex(const String:sEffectName[])
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	new iIndex = FindStringIndex(table, sEffectName);
	if(iIndex != INVALID_STRING_INDEX)
		return iIndex;
	
	// This is the invalid string index
	return 0;
}

stock PrecacheParticleEffect(const String:sEffectName[])
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	new bool:save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

stock GetParticleEffectIndex(const String:sEffectName[])
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	new iIndex = FindStringIndex(table, sEffectName);
	if(iIndex != INVALID_STRING_INDEX)
		return iIndex;
	
	// This is the invalid string index
	return 0;
}

stock TE_SetupParticleEffect(const String:sParticleName[], ParticleAttachment_t:iAttachType, entity = 0, const Float:fOrigin[3] = {9999.99, 0.0, 0.0})//, const Float:fOrigin[3] = NULL_VECTOR, const Float:fAngles[3] = NULL_VECTOR, const Float:fStart[3] = NULL_VECTOR, iAttachmentPoint = -1, bool:bResetAllParticlesOnEntity = false)
{
	TE_Start("EffectDispatch");
	
	TE_WriteNum("m_nHitBox", GetParticleEffectIndex(sParticleName));
	
	new fFlags;
	new Float:fEntityOrigin[3];
	if (fOrigin[0] != 9999.99){
		fEntityOrigin[0] = fOrigin[0];
		fEntityOrigin[1] = fOrigin[1];
		fEntityOrigin[2] = fOrigin[2];
	}
	else if (entity > 0 && IsValidEntity(entity)){
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", fEntityOrigin);
	}
	else return;
	TE_WriteFloatArray("m_vOrigin.x", fEntityOrigin, 3);
	if (entity > 0){
		if(iAttachType != PATTACH_WORLDORIGIN)
		{
			TE_WriteNum("entindex", entity);
			fFlags |= PARTICLE_DISPATCH_FROM_ENTITY;
		}
	}
	
	/*if(fOrigin != NULL_VECTOR)
		TE_WriteFloatArray("m_vOrigin.x", fOrigin, 3);
	if(fStart != NULL_VECTOR)
		TE_WriteFloatArray("m_vStart.x", fStart, 3);
	if(fAngles != NULL_VECTOR)
		TE_WriteVector("m_vAngles", fAngles);*/
	
	//if(bResetAllParticlesOnEntity)
	//	fFlags |= PARTICLE_DISPATCH_RESET_PARTICLES;
	
	TE_WriteNum("m_fFlags", fFlags);
	TE_WriteNum("m_nDamageType", _:iAttachType);
	TE_WriteNum("m_nAttachmentIndex", -1);
	
	TE_WriteNum("m_iEffectName", GetEffectIndex("ParticleEffect"));
}

public Action:DeletePointHurt(Handle:timer, any:refpointhurt)
{
	new pointhurt = EntRefToEntIndex(refpointhurt);
	if (refpointhurt != INVALID_ENT_REFERENCE && IsValidEntity(refpointhurt) && pointhurt > MaxClients)
	{
		decl String:sClassName[64];
		GetEntityClassname(refpointhurt, sClassName, 64);
		LogToGame("%d (%d). used point_hurt \"%s\" has been removed", pointhurt, sClassName, refpointhurt);
		AcceptEntityInput(refpointhurt, "Kill");
	}
}

public Action:DeleteParticle(Handle:timer, any:refparticle)
{
	new particle = EntRefToEntIndex(refparticle);
	if (refparticle != INVALID_ENT_REFERENCE && IsValidEntity(refparticle) && particle > MaxClients)
	{
		decl String:sClassName[64];
		GetEntityClassname(refparticle, sClassName, 64);
		if (StrEqual(sClassName, "LuaTempParticle", true))
		{
			LogToGame("%d (%d). used \"info_particle_system\" has been removed", particle, refparticle);
			AcceptEntityInput(refparticle, "Kill");
		}
	}
}

public Action:SetupZombiesEffect(Handle:timer, any:client)
{
	if (g_iGameState != 4 || !g_bUpdatedSpawnPoint) return;
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_ZOMBIES)
	{
		LogToGame("[ZH] Zombie \"%N\" setting up for effects", client);
		if (g_iZombieClass[client][CLASS] == ZOMBIE_BURNER_INDEX)
		{
			AttachParticle(client, "fire_small_03", false, false, _, 0, 38.0);
			return;
		}
		else if (g_iZombieClass[client][CLASS] == ZOMBIE_SMOKER_INDEX)
		{
			AttachParticle(client, "smokegrenade_spray_b", true, true, 0.1, client, 32.0);
			return;
		}
	}
	if (IsClientInGame(client))
	{
		LogToGame("[ZH] Zombie \"%N\" setting up for effects - FAILED", client);
		if (IsPlayerAlive(client))
		{
			SetEntityRenderColor(client, 255, 255, 255, 255);
			FakeClientCommand(client, "inventory_sell_all");
			g_iZombieClass[client][CLASS] = -1;
			g_iPlayerStatus[client] = 0;
			g_fZombieNextStats[client] = Float:{300.0, 1.0, 1.0};
			g_fZombieObjectDamaged[client] = 0.0;
			ZH_SetZombieClass(client, -1, 1.0);
			CreateTimer(0.1, Timer_BotSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
		LogToGame("[ZH] [NOT IN-GAME] Client \"%d\" setting up for effects - FAILED", client);
	return;
}

stock AttachParticle(client, String:particleType[], bool:tempeffect = false, bool:autoKill = false, Float:seconds = 1.0, attach = -1, Float:zCorrection)
{
	//PrintToChat(client, "AttachRTDParticle: %s", particleType);
	//find available particle slot
	if (IsClientInGame(client) && strlen(particleType) > 0)
	{
		new iParticle = CreateEntityByName("info_particle_system");
		if (iParticle > MaxClients && IsValidEdict(iParticle))
		{
			if (!tempeffect) g_iAttachedParticleRef[client] = EntIndexToEntRef(iParticle);
			decl Float:pos[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
			SetEntPropEnt(iParticle, Prop_Send, "m_hOwnerEntity", client);
			pos[2] += zCorrection;
			TeleportEntity(iParticle, pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(iParticle, "classname", "LuaTempParticle");
			DispatchKeyValue(iParticle, "effect_name", particleType);
			
			if (attach != -1)
			{
				decl String:tName[128];
				Format(tName, sizeof(tName), "target%i", client);
				DispatchKeyValue(client, "targetname", tName);
				DispatchKeyValue(iParticle, "parentname", tName);
				SetVariantString(tName);
				AcceptEntityInput(iParticle, "SetParent", iParticle, iParticle, 0);
			}
			DispatchSpawn(iParticle);
			AcceptEntityInput(iParticle, "start");
			if (attach == 100){
				SetVariantString("head");
				AcceptEntityInput(iParticle, "SetParentAttachment", iParticle, iParticle, 0);
			}
			else if (attach == 200){
				SetVariantString("flag");
				AcceptEntityInput(iParticle, "SetParentAttachment", iParticle, iParticle, 0);
				
				decl Float:angle[3]; 
				angle[2] = 70.0;
				TeleportEntity(iParticle, NULL_VECTOR, Float:{0.0, 0.0, 70.0}, NULL_VECTOR);
			}
			else if (attach == 300){
				SetVariantString("primary");
				AcceptEntityInput(iParticle, "SetParentAttachment", iParticle, iParticle, 0);
			}
			ActivateEntity(iParticle);
			
			if (autoKill)
			{
				decl String:addoutput[64];
				Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1",seconds);
				SetVariantString(addoutput);
				AcceptEntityInput(iParticle, "AddOutput");
				AcceptEntityInput(iParticle, "FireUser1");
			}
			return true;
		}
		else
		{
			LogToGame("[ZH] \"%N\" has failed attach particle \"%s\" (%d) and getting new zombie class", client, particleType, iParticle);
			ZH_SetZombieClass(client, -1);
		}
	}
	return false;
}

PrecacheThings()
{
	// Zombie Horde
	PrecacheSound("Lua_sounds/zombiehorde/zr_ambience.ogg");

	// SMOKER DETONATE
	PrecacheSound("weapons/m203/m203_detonate_smoke_near_01.wav");
	PrecacheSound("weapons/m203/m203_detonate_smoke_far_01.wav");
	PrecacheSound("weapons/m18/smokeburn.wav");
	
	PrecacheSound("Lua_sounds/zombiehorde/lasthuman.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/zr_ambience.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/zombies_won1.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/zombies_won2.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/zombies_won3.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/round_begin1.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/round_begin2.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/round_begin3.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/survivors/cough1.wav");
	PrecacheSound("Lua_sounds/zombiehorde/survivors/cough2.wav");
	PrecacheSound("Lua_sounds/zombiehorde/survivors/cough3.wav");
	PrecacheSound("Lua_sounds/zombiehorde/survivors/cough4.wav");
	PrecacheSound("Lua_sounds/zombiehorde/survivors/death.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/survivors/infection1.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/survivors/infection2.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/survivors/infection3.ogg");
	
	// Sounds @ Blinker
	// PrecacheSound("ui/sfx/ringing_01.wav");
	// PrecacheSound("ui/sfx/ringing_02.wav");

	// Common
	PrecacheSound("Lua_sounds/zombiehorde/zombies/common/attack1.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/zombies/common/alert1.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/zombies/common/alert2.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/zombies/common/die1.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/zombies/common/die2.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/zombies/common/pain1.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/zombies/common/pain2.ogg");
	PrecacheSound("Lua_sounds/zombiehorde/zombies/common/pain3.ogg");
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/common/scream", ".ogg", 1, 4, false);
	// Classic
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/classic/zombie_pain", ".wav", 1, 6, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/classic/zombie_die", ".wav", 1, 3, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/classic/zombie_alert", ".wav", 1, 3, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/classic/zombie_voice_idle", ".wav", 1, 14, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/classic/claw_strike", ".wav", 1, 3, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/classic/foot", ".wav", 1, 3, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/classic/moan_loop", ".wav", 1, 4, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/classic/zo_attack", ".wav", 1, 2, false);
	PrecacheSound("Lua_sounds/zombiehorde/zombies/classic/zombie_hit.wav");
	// Stalker
	PrecacheSound("Lua_sounds/zombiehorde/zombies/stalker/alert1.wav");
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/stalker/attack", ".wav", 1, 3, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/stalker/pain", ".wav", 1, 3, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/stalker/die", ".wav", 1, 2, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/stalker/idle", ".wav", 1, 3, false);
	// IED
	PrecacheParticleEffect("ins_flaregun_trail_glow_b");
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/ied/zombine_pain", ".wav", 1, 4, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/ied/zombine_charge", ".wav", 1, 2, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/ied/zombine_alert", ".wav", 1, 7, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/ied/zombine_idle", ".wav", 1, 4, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/ied/zombine_die", ".wav", 1, 2, false);
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/ied/zombine_readygrenade", ".wav", 1, 2, false);
	// SMOKER
	PrecacheParticleEffect("smokegrenade");
	PrecacheParticleEffect("smokegrenade_spray_b");
	PrecacheParticleEffect("molotov_trail");
	// BURNER
	PrecacheParticleEffect("fire_small_03");
	// BLINKER
	// PrecacheParticleEffect("bag_explode");
	// Fast
	PrecacheSound("Lua_sounds/zombiehorde/zombies/fast/fz_alert_far1.wav");
	PrecacheSound("Lua_sounds/zombiehorde/zombies/fast/fz_scream1.wav");
	PrecacheSound("Lua_sounds/zombiehorde/zombies/fast/fz_alert_close1.wav");
	PrecacheSound("Lua_sounds/zombiehorde/zombies/fast/fz_frenzy1.wav");
	PrecacheSoundNumbers("Lua_sounds/zombiehorde/zombies/fast/zombie_on_car_0", ".wav", 1, 4, false);
	
	// Won the map
	PrecacheParticleEffect("explosion_silo");
	//Evac Heli
	PrecacheModel("models/props_vehicles/helicopter_rescue.mdl");
	PrecacheSound("Lua_sounds/helicopter/heli_loop1.wav");
//	PrecacheSound("Lua_sounds/helicopter/heli_windy_loop1.wav");

	g_iZombieModels[0] = PrecacheModel("models/characters/zsmodel_heavy01.mdl");
	g_iZombieModels[1] = PrecacheModel("models/characters/zsmodel_inszomb002.mdl");
	g_iZombieModels[2] = PrecacheModel("models/characters/zsmodel_light01.mdl");
	g_iZombieModels[3] = PrecacheModel("models/characters/zsmodel_seczomb02.mdl");
	g_iZombieModels[4] = PrecacheModel("models/characters/zsmodel_vipinsurgent02.mdl");
//	g_iZombieModels[1] = PrecacheModel("models/characters/zsmodel_inszomb001.mdl");	// Too much bright
//	g_iZombieModels[2] = PrecacheModel("models/characters/zsmodel_vipinsurgent01.mdl");	// Too much bright
//	g_iZombieModels[3] = PrecacheModel("models/characters/zsmodel_seczomb01.mdl");	// Too much bright
//	g_iSuicideBombKnifeModel = PrecacheModel("models/weapons/w_marinebayonet.mdl");
	g_iSuicideBombWeaponModels[0] = PrecacheModel("models/weapons/w_f1.mdl");
	g_iSuicideBombWeaponModels[1] = PrecacheModel("models/weapons/w_m67.mdl");
	g_iSuicideBombWeaponModels[2] = PrecacheModel("models/weapons/w_nam_m26a2.mdl");
	g_iSuicideBombWeaponModels[3] = PrecacheModel("models/weapons/w_nam_geballteladung.mdl");
	g_iSuicideBombWeaponModels[4] = PrecacheModel("models/weapons/w_anm14.mdl");
	g_iSuicideBombWeaponModels[5] = PrecacheModel("models/weapons/w_molotov.mdl");
	g_iSuicideBombWeaponModels[6] = PrecacheModel("models/weapons/w_c4.mdl");
	g_iSuicideBombWeaponModels[7] = PrecacheModel("models/weapons/w_ied.mdl");
	g_iSuicideBombWeaponModels[8] = PrecacheModel("models/weapons/w_rpg7_projectile.mdl");
	g_iSuicideBombWeaponModels[9] = PrecacheModel("models/weapons/w_at4_projectile.mdl");

	g_iGearRadarModel[0] = PrecacheModel("models/static_props/sec_hub.mdl");
	g_iGearRadarModel[1] = PrecacheModel("models/static_props/sec_hub_burned.mdl");
	g_iGearIEDJammerModel[0] = PrecacheModel("models/static_props/ins_radio.mdl");
	g_iGearIEDJammerModel[1] = PrecacheModel("models/static_props/ins_radio_burned.mdl");
	g_iGearBarricade[0] = PrecacheModel("models/static_fortifications/sandbagwall01.mdl");
	g_iGearBarricade[1] = PrecacheModel("models/static_fortifications/sandbagwall02.mdl");
	g_iGearBarricade[2] = PrecacheModel("models/static_military/sandbag_wall_short_b.mdl");
	g_iGearBarricade[3] = PrecacheModel("models/static_afghan/prop_fortification_hesco_small.mdl");
	g_iGearBarricade[4] = PrecacheModel("models/generic/barrier_crete00a.mdl");
	g_iGearBarricade[5] = PrecacheModel("models/props/concrete_barrier_stw02.mdl");
	g_iGearBarricade[6] = PrecacheModel("models/static_fortifications/concrete_barrier_02.mdl");
//	g_iGearBarricade[7] = PrecacheModel("models/static_fortifications/concrete_barrier_01.mdl");
	g_iGearAmmoCrateModel[0] = PrecacheModel("models/generic/ammocrate3.mdl");
	g_iGearAmmoCrateModel[1] = PrecacheModel("models/generic/ammocrate1.mdl");

	//Effects
	PrecacheParticleEffect("ins_ammo_explosion");
	PrecacheParticleEffect("ins_car_explosion");
	PrecacheParticleEffect("ins_grenade_explosion");
	PrecacheParticleEffect("gore_blood_droplets_short");
	PrecacheParticleEffect("gore_blood_droplets_long");
	PrecacheParticleEffect("vol_dust_wide");
	PrecacheParticleEffect("ins_flaregun_trail");
	PrecacheSound("physics/dynamic/ammobox_cookoff.ogg");
	PrecacheSound("weapons/WeaponCache/Cache_Explode.wav");
	PrecacheSound("weapons/WeaponCache/Cache_Explode_Distant.wav");
	PrecacheSound("weapons/WeaponCache/Cache_Explode_far_Distant.wav");
	PrecacheSound("Lua_sounds/bandaging.wav");
	PrecacheSound("player/focus_exhale.wav");
	PrecacheSound("Lua_sounds/ammo_pickup.wav");
	PrecacheSound("ui/sfx/beep2.wav");
	PrecacheSoundNumbers("soundscape/emitters/oneshot/broken_tv_0", ".ogg", 1, 3, false);
/*
	PrecacheParticleEffect("ins_c4_explosion_smoke_c");
//	PrecacheParticleEffect("ins_ammo_explosion_sparks_e");
	PrecacheParticleEffect("ins_gas_explosion_flameburst");
	PrecacheParticleEffect("ins_grenade_explosion_spikes");
	PrecacheParticleEffect("ins_ammo_explosion_smoke");
	PrecacheParticleEffect("ins_ammo_explosion_smoke_b");
//	PrecacheParticleEffect("ins_ammo_explosion_smoke_c");
*/

	// UAV
//	g_iBeaconBeam = PrecacheModel("sprites/laserbeam.vmt");
	g_iBeaconHalo = PrecacheModel("sprites/glow01.vmt");
	g_iSpriteLaser = PrecacheModel("sprites/laserbeam.vmt");
	
	// Ignition on weapon cache
	PrecacheSoundNumbers("player/voice/botsurvival/subordinate/incominggrenade", ".ogg", 5, 8, false);
	PrecacheSoundNumbers("player/voice/botsurvival/subordinate/incominggrenade", ".ogg", 11, 4, false);
	PrecacheSoundNumbers("player/voice/botsurvival/subordinate/incominggrenade", ".ogg", 16, 22, false);
	PrecacheSound("player/voice/botsurvival/subordinate/incominggrenade24.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/incominggrenade25.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/incominggrenade27.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/incominggrenade28.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/incominggrenade32.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/incominggrenade36.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/damage/molotov_incendiary_detonated6.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/damage/molotov_incendiary_detonated7.ogg");

	// Kill Confirm
	// Security
	PrecacheSound("player/voice/botsurvival/subordinate/target2.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/target4.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/target5.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/target8.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/target9.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/target11.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/target13.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/unsuppressed/target1.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/unsuppressed/target3.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/suppressed/target2.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/suppressed/target3.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/suppressed/target4.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/suppressed/target7.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/suppressed/target10.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/suppressed/target11.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/suppressed/target12.ogg");
	PrecacheSoundNumbers("player/voice/radial/security/leader/unsuppressed/enemydown_knifekill", ".ogg", 1, 3, false);
	PrecacheSoundNumbers("player/voice/radial/security/subordinate/unsuppressed/enemydown_knifekill", ".ogg", 1, 3, false);

	// RPG & AT4 Killed by bots - HQ
	PrecacheSound("hq/coop/counterattackstart6.ogg");
	PrecacheSound("hq/coop/counterattackstart8.ogg");
	PrecacheSound("hq/coop/counterattackstart13.ogg");
	PrecacheSound("hq/outpost/outpost_cachedestroyed10.ogg");
	PrecacheSound("hq/security/theycaptured10.ogg");
	// Rockets firing by player
//	PrecacheSound("player/voice/responses/security/subordinate/coop/rpg1.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/coop/rpg4.ogg");
//	PrecacheSoundNumbers("player/voice/responses/security/leader/coop/rpg", ".ogg", 1, 4, false);
	PrecacheSound("player/voice/responses/security/leader/coop/rpg2.ogg");
	// Explosion nearby
	PrecacheSound("player/voice/botsurvival/subordinate/flashbanged3.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/flashbanged5.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/flashbanged23.ogg");
	PrecacheSoundNumbers("player/voice/botsurvival/leader/flashbanged", ".ogg", 4, 8, false);
	
	// Team Hit
	PrecacheSoundNumbers("player/voice/responses/security/subordinate/unsuppressed/watchfire", ".ogg", 1, 15, false);

	// Others
	PrecacheSound("Lua_sounds/Natural_Killers.ogg");
	PrecacheSound("Lua_sounds/humiliation.wav");
	PrecacheSound("Lua_sounds/teamkiller.wav");
	PrecacheSound("Lua_sounds/warsaw.ogg");
	PrecacheSound("Lua_sounds/uav_inbound.ogg");
	PrecacheSound("ui/sfx/ringing_04.wav");
//	PrecacheSound("Lua_sounds/heartbeat.ogg");

	PrecacheSound("player/voice/responses/security/subordinate/suppressed/suppressed11.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/suppressed/suppressed12.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/suppressed/suppressed16.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/suppressed/suppressed17.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/suppressed/suppressed23.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/suppressed/suppressed31.ogg");
	
	// Weapon caches
	PrecacheModel("models/static_props/weapon_cache_01.mdl");
	PrecacheModel("models/static_props/weapon_cache_01_destr.mdl");
	PrecacheModel("models/static_props/wcache_sec_01.mdl");
	PrecacheModel("models/static_props/wcache_sec_01_destr.mdl");
	PrecacheSoundNumbers("player/voice/security/command/subordinate/subordinateradio/located", "_radio.ogg", 2, 4, false);
	// It should be already precached by game
	PrecacheModel("models/static_props/wcache_ins_01.mdl");
	PrecacheModel("models/static_props/wcache_ins_01_destr.mdl");
	
	// Point Flag
	PrecacheModel("models/generic/flag_pole_animated.mdl");
	PrecacheSoundNumbers("hq/security/friendlycarrierdead", ".ogg", 1, 10, false);
	PrecacheSoundNumbers("hq/security/wekilled", ".ogg", 1, 10, false);
	PrecacheSoundNumbers("hq/security/wetook", ".ogg", 1, 10, false);
	PrecacheSoundNumbers("hq/security/theytook", ".ogg", 1, 10, false);
	
	// Suppress
	PrecacheSoundNumbers("player/voice/botsurvival/subordinate/suppress", ".ogg", 1, 15, false);
	PrecacheSoundNumbers("player/voice/botsurvival/leader/suppress", ".ogg", 1, 15, false);
	
	// Bleeding
	PrecacheSoundNumbers("player/voice/responses/security/leader/unsuppressed/wounded", ".ogg", 1, 18, false);
	PrecacheSoundNumbers("player/voice/responses/security/subordinate/unsuppressed/wounded", ".ogg", 1, 19, false);
	PrecacheSound("player/voice/responses/insurgent/subordinate/unsuppressed/wounded1.ogg");
//	PrecacheSoundNumbers("player/voice/responses/insurgent/leader/unsuppressed/wounded", ".ogg", 1, 20, false);
//	PrecacheSoundNumbers("player/voice/responses/insurgent/subordinate/unsuppressed/wounded", ".ogg", 1, 21, false);

	// Incoming Grenade
	PrecacheSoundNumbers("player/voice/botsurvival/leader/incominggrenade", ".ogg", 1, 33, false);
	PrecacheSoundNumbers("player/voice/botsurvival/subordinate/incominggrenade", ".ogg", 1, 36, false);
	
	// On Fire
	PrecacheSoundNumbers("player/damage/pl_damage_major_", ".wav", 1, 14, true);
	PrecacheSound("player/voice/responses/security/leader/damage/molotov_incendiary_detonated4.ogg");
	PrecacheSound("player/voice/responses/security/leader/damage/molotov_incendiary_detonated5.ogg");
/*	Dupliated Precache on Weapon Cache Fire
	PrecacheSound("player/voice/responses/security/subordinate/damage/molotov_incendiary_detonated6.ogg");
	PrecacheSound("player/voice/responses/security/subordinate/damage/molotov_incendiary_detonated7.ogg");	*/
	
	// Medic
	PrecacheSoundNumbers("lua_sounds/medic/medic_injured", ".ogg", 1, 22, false);
	PrecacheSoundNumbers("lua_sounds/medic/medic_critical", ".ogg", 1, 16, false);
	PrecacheSoundNumbers("lua_sounds/medic/medic_dying", ".ogg", 1, 3, false);
	PrecacheSoundNumbers("lua_sounds/medic/letme/medic_letme_bandage", ".ogg", 1, 18, false);
	PrecacheSoundNumbers("lua_sounds/medic/letme/medic_letme_heal", ".ogg", 1, 7, false);
	PrecacheSoundNumbers("lua_sounds/medic/healed/medic_healed", ".ogg", 1, 38, false);
	PrecacheSoundNumbers("lua_sounds/medic/thx/medic_thanks", ".ogg", 1, 20, false);
	
//	PrecacheSoundNumbers("hq/security/enemyout", ".ogg", 1, 10, false);
	PrecacheSoundNumbers("hq/security/wehave", ".ogg", 1, 10, false);
	PrecacheSoundNumbers("soundscape/emitters/oneshot/dist_crowd_warzone_0", ".ogg", 1, 7, false);
	PrecacheSound("soundscape/emitters/oneshot/mil_radio_03.ogg");
	PrecacheSound("soundscape/emitters/oneshot/mil_radio_04.ogg");
	PrecacheSound("Lua_sounds/defend01.ogg");
	PrecacheSound("hq/security/vendetta1.ogg");
	PrecacheSound("hq/security/defendcache5.ogg");
	PrecacheSound("hq/security/roundstart_flashpoint2.ogg");
	PrecacheSound("hq/security/roundstart_flashpoint8.ogg");
	PrecacheSound("hq/security/roundstart_infiltrate2.ogg");
	PrecacheSound("hq/security/roundstart_infiltrate9.ogg");
	PrecacheSound("hq/security/roundstart_occupy2.ogg");
	PrecacheSound("hq/security/roundstart_occupy3.ogg");
	PrecacheSound("hq/security/roundstart_occupy4.ogg");
	PrecacheSound("hq/security/roundstart_occupy6.ogg");
	PrecacheSound("hq/security/roundstart_occupy8.ogg");
	PrecacheSound("hq/security/roundstart_occupy9.ogg");
	PrecacheSound("hq/security/roundstart_strike5.ogg");
	PrecacheSound("hq/security/roundstart_strike9.ogg");
	PrecacheSound("hq/security/roundstart_strike10.ogg");
	PrecacheSound("hq/security/roundstart_vendetta2.ogg");
	PrecacheSound("hq/security/roundstart_vendetta4.ogg");
	PrecacheSound("hq/security/roundstart_vendetta5.ogg");
	PrecacheSound("hq/security/roundstart_vendetta9.ogg");
	PrecacheSound("hq/security/roundstart_vendetta10.ogg");
	PrecacheSound("hq/security/theyhave1.ogg");
	PrecacheSound("hq/security/theyhave2.ogg");
	PrecacheSound("hq/security/theyhave3.ogg");
	PrecacheSound("hq/security/theyhave5.ogg");
	PrecacheSound("hq/security/theyhave8.ogg");
	PrecacheSound("hq/security/theyhave9.ogg");
	PrecacheSound("hq/security/theyhave10.ogg");
	
	PrecacheSound("player/voice/botsurvival/subordinate/aggressiveinv2.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/aggressiveinv4.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/aggressiveinv15.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/aggressiveinv16.ogg");
	PrecacheSound("player/voice/botsurvival/leader/aggressiveinv14.ogg");
	PrecacheSound("player/voice/botsurvival/leader/aggressiveinv15.ogg");

	PrecacheSound("player/voice/botsurvival/subordinate/flashbanged14.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/flashbanged17.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/flashbanged20.ogg");
	PrecacheSound("player/voice/botsurvival/subordinate/flashbanged21.ogg");
	PrecacheSound("player/voice/botsurvival/leader/flashbanged17.ogg");
	PrecacheSound("player/voice/botsurvival/leader/flashbanged18.ogg");
	PrecacheSound("player/voice/botsurvival/leader/flashbanged20.ogg");
	return true;
}


stock PrecacheSoundNumbers(const String:soundprefix[], const String:soundpost[], number_begin, number_end, bool:zeroforlownumber = false)
{
	decl String:soundfileformat[512];
	for (new i = number_begin;i <= number_end;i++)
	{
		if (zeroforlownumber && i < 10 && i > -1)
			Format(soundfileformat, sizeof(soundfileformat), "%s0%d%s", soundprefix, i, soundpost);
		else
			Format(soundfileformat, sizeof(soundfileformat), "%s%d%s", soundprefix, i, soundpost);
		PrecacheSound(soundfileformat);
//		PrintToServer("Precached Sound: %s", soundfileformat);
	}
	return true;
}

stock String_ToUpper(const String:input[], String:output[], size)
{
	size--;

	new x=0;
	while (input[x] != '\0' && x < size) {
		
		output[x] = CharToUpper(input[x]);
		
		x++;
	}

	output[x] = '\0';
}

stock SwapWeaponToPrimary(client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || g_iOffsetMyWeapons == -1) return -2;
	ClientCommand(client, "toggleprimarysecondary");
	return 1;
/*	new iWeapon = GetPlayerWeaponSlot(client, 0);
	if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
		iWeapon = GetPlayerWeaponSlot(client, 1);
	if (iWeapon <= MaxClients || !IsValidEntity(iWeapon))
		ClientCommand(client, "lastinv");
	else
	{
		decl String:sClassName[32];
		GetEntityClassname(iWeapon, sClassName, sizeof(sClassName));
		FakeClientCommand(client, "use %s", sClassName);
		return iWeapon;
	}
	return -1;	*/
/*
	for (new i = 0;i < 48;i++)
	{
		new weapon = GetEntDataEnt2(client, g_iOffsetMyWeapons+(4*i));
		if (weapon == -1) break;

		if (!IsValidEntity(weapon) || weapon <= MaxClients)
			continue;

		new String:classname[64];
		GetEntityClassname(weapon, classname, sizeof(classname));
		FakeClientCommand(client, "use %s", classname);
		return weapon;
	}
	return -1;	*/
}

stock bool:IsVipModel(client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return false;
	new String:sModel[128];
	GetClientModel(client, sModel, sizeof(sModel));
	if (StrContains(sModel, "vip", false) != -1)
		return true;
	return false;
}

stock bool:IsLightModel(client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) return false;
	new String:sModel[128];
	GetClientModel(client, sModel, sizeof(sModel));
	if (StrContains(sModel, "_light.mdl", false) != -1 || StrContains(sModel, "civilian_vip_security.mdl", false) != -1)
		return true;
	return false;
}

stock ApplyFog()
{
	new iFogControllerIndex = FindEntityByClassname(-1, "env_fog_controller");
	if(iFogControllerIndex == -1)
	{
		iFogControllerIndex = CreateEntityByName("env_fog_controller");
		// Set density of the fog
		DispatchKeyValueFloat(iFogControllerIndex, "fogmaxdensity", 1.0);
		DispatchSpawn(iFogControllerIndex);
	}
	else DispatchKeyValueFloat(iFogControllerIndex, "fogmaxdensity", 1.0);

	// Set start distance of the fog
	SetVariantInt(360);
	AcceptEntityInput(iFogControllerIndex, "SetStartDist");

	// Set end distance of the fog
	SetVariantInt(GetRandomInt(2000, 3000));
	AcceptEntityInput(iFogControllerIndex, "SetEndDist");

	// Set plain distance of the fog
//	SetVariantInt(10000);
//	AcceptEntityInput(iFogControllerIndex, "SetFarZ");

	// Set main color
	SetVariantString("50 50 50");
	AcceptEntityInput(iFogControllerIndex, "SetColor");

	// Set secondary color
	SetVariantString("120 120 120");
	AcceptEntityInput(iFogControllerIndex, "SetColorSecondary");

	// Set secondary color
	SetVariantBool(true);
	AcceptEntityInput(iFogControllerIndex, "fogblend");
}

public ZH_ZombieLeapReady(client, target)
{
	if (g_iGameState != 4 || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsClientInGame(target) || !IsPlayerAlive(target) || g_iZombieClass[client][CLASS] == ZOMBIE_IED_INDEX)
		return;
		
	new Float:vZombieOrigin[3], Float:vTargetOrigin[3];
	GetClientEyePosition(client, vZombieOrigin);
	GetClientEyePosition(target, vTargetOrigin);
	new Float:fDistance = GetVectorDistance(vZombieOrigin, vTargetOrigin);
	if (vZombieOrigin[2]-75.0 <= vTargetOrigin[2] && fDistance >= FCVAR_ZOMBIE_LEAPER_LEAP_DISTANCE_MIN)
	{
		if (fDistance > FCVAR_ZOMBIE_LEAPER_LEAP_DISTANCE_MAX)
		{
			if (fDistance > FCVAR_ZOMBIE_LEAPER_LEAP_DISTANCE_MAX*2.0)
				return;
			else
			{
				new Float:fVel[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", fVel);
				if (GetVectorLength(fVel, false) > 50.0)
					return;
			}
		}
		g_iZombieClass[client][VAR] = 2;
		new Handle:hDataPack = CreateDataPack();
		decl Float:vAng[3], Float:fVel[3], Float:heightClient[3] = {0.0, ...}, Float:heightTarget[3] = {0.0, ...};
		// decl Float:vAng[3], Float:fVel[3];
		GetClientEyeAngles(client, vAng);
		fDistance *= GetRandomFloat(6.0, 10.0);
		if (fDistance < FCVAR_ZOMBIE_LEAPER_LEAP_DISTANCE_MAX/2.0) fDistance = FCVAR_ZOMBIE_LEAPER_LEAP_DISTANCE_MAX/2.0;
		// if (fDistance <= FCVAR_ZOMBIE_LEAPER_LEAP_DISTANCE_MAX/2.0) fDistance *= 4.0;
		// else fDistance *= 2.66;
		fVel[0] = (Cosine(vAng[1] * 0.01745329) * Cosine(vAng[0] * 0.01745329)) * fDistance;
		fVel[1] = (Sine(vAng[1] * 0.01745329) * Cosine(vAng[0] * 0.01745329)) * fDistance;
		// if (vZombieOrigin[2] < 0.0) NegateVector(vZombieOrigin);
		// if (vTargetOrigin[2] < 0.0) NegateVector(vTargetOrigin);
		heightClient[2] = vZombieOrigin[2];
		heightTarget[2] = vTargetOrigin[2];
		// if (vTargetOrigin[2]-vZombieOrigin[2] > 0.0 && vTargetOrigin[2]-vZombieOrigin[2] < 200.0)
			// fVel[2] = (vTargetOrigin[2]-vZombieOrigin[2])*4.0;
		// else
			// fVel[2] = (vTargetOrigin[2]-vZombieOrigin[2])*2.22;
//		fVel[2] = (vTargetOrigin[2]-vZombieOrigin[2])*3.0;
		new Float:fHeightDistance = GetVectorDistance(heightClient, heightTarget);
		if (fHeightDistance > 300.0)
			fVel[2] = (fHeightDistance*1.5);
		else
			fVel[2] = (fHeightDistance*2.0 + 150.0);
		// if (heightTarget[2] < 0.0) heightTarget[2] -= heightTarget[2];
		// else if (fVel[2] > heightTarget[2]*2.0) fVel[2] = heightTarget[2]*2.0;
		CreateDataTimer(Math_GetRandomFloat(FCVAR_ZOMBIE_LEAPER_LEAP_DELAY_MIN, FCVAR_ZOMBIE_LEAPER_LEAP_DELAY_MAX), Timer_ZH_ZombieLeap, hDataPack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(hDataPack, client);
		WritePackCell(hDataPack, target);
		WritePackFloat(hDataPack, vAng[0]);
		WritePackFloat(hDataPack, vAng[1]);
		WritePackFloat(hDataPack, vAng[2]);
		WritePackFloat(hDataPack, fVel[0]);
		WritePackFloat(hDataPack, fVel[1]);
		WritePackFloat(hDataPack, fVel[2]);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Float:{0.0, 0.0, 0.0});
		// LogToGame("Zombie \"%N\" has ready for leap to \"%N\", set speed to %0.2f", client, target, FCVAR_ZOMBIE_LEAP_READY_SPEED);
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", FCVAR_ZOMBIE_LEAP_READY_SPEED);
	}
	return;
}

public Action:Timer_ZH_ZombieLeap(Handle:timer, Handle:datapack)
{
	ResetPack(datapack);
	new client = ReadPackCell(datapack);
	if (g_iGameState != 4 || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		g_iZombieClass[client][VAR] = 0;
		return;
	}

	ZH_ResetZombieSpeed(client);
/*	new iButtons = GetClientButtons(client);
	if (iButtons & INS_BACKWARD || iButtons & INS_LEFT || iButtons & INS_RIGHT)
	{
		// LogToGame("Zombie \"%N\" is failed to leap (moving)", client);
		g_iZombieClass[client][VAR] = 0;
		return;
	}	*/

	new target = ReadPackCell(datapack);
	if ((g_iZombieClass[client][CLASS] != ZOMBIE_LEAPER_INDEX && g_fGameTime-g_fPlayerLastLeaped[target] < 5.0) || (g_iZombieClass[client][CLASS] == ZOMBIE_LEAPER_INDEX && g_fGameTime-g_fPlayerLastLeaped[client] < 3.0))
	{
		// LogToGame("Zombie \"%N\" is failed to leap (cooldown)", client);
		g_iZombieClass[client][VAR] = 0;
		return;
	}

	new iFlags = GetEntProp(client, Prop_Send, "m_iPlayerFlags");
	if (iFlags & ~INS_PL_SLIDE) SetEntProp(client, Prop_Send, "m_iPlayerFlags", iFlags & INS_PL_SLIDE);
	g_fPlayerLastLeaped[target] = g_fGameTime;
	g_fPlayerLastLeaped[client] = g_fGameTime;
	new Float:fVel[3], Float:fAng[3];
	fAng[0] = ReadPackFloat(datapack);
	fAng[1] = ReadPackFloat(datapack);
	fAng[2] = ReadPackFloat(datapack);
	fVel[0] = ReadPackFloat(datapack);
	fVel[1] = ReadPackFloat(datapack);
	fVel[2] = ReadPackFloat(datapack);
	TeleportEntity(client, NULL_VECTOR, fAng, fVel);
	if (IsClientInGame(target)) LogToGame("Zombie \"%N\" is leaping to \"%N\"", client, target);
	else LogToGame("Zombie \"%N\" is leaping to [NOT IN-GAME] \"#%d\"", client, target);
	g_iZombieClass[client][VAR] = 1;
	EmitSoundToAll("Lua_sounds/zombiehorde/zombies/fast/fz_scream1.wav", client, SNDCHAN_VOICE, _, _, 0.7);
	return;
}

public ZH_ResetZombieSpeed(client)
{
	if (g_iGameState != 4 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	new Float:fSpeed = g_fZombieNextStats[client][SPEED];
	if (g_iPlayerBleeding[client] != 0)
		fSpeed = fSpeed-GetRandomFloat(FCVAR_ZOMBIE_BLEED_REDUCE_SPEED_MIN, FCVAR_ZOMBIE_BLEED_REDUCE_SPEED_MAX);
	else if (g_iZombieBurnSound[client] != 0)
		fSpeed = fSpeed+GetRandomFloat(FCVAR_ZOMBIE_BURN_BONUS_SPEED_MIN, FCVAR_ZOMBIE_BURN_BONUS_SPEED_MAX);
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", fSpeed);
}
