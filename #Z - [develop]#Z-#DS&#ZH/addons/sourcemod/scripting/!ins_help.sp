#include <sourcemod>
#include <sdktools>
#include <smlib/clients>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_DESCRIPTION "Need help?"

new g_iCurrentPage[49] = {-1, ...};

public Plugin:myinfo =
{
	name = "#Lua Zombie Horde Help [China]",
	author = "D.Freddo, Modified by:Kud",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://group.lua.kr"
}

public OnPluginStart()
{
	HookEvent("player_say", Event_PlayerSay, EventHookMode_Post);
}

public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && !IsFakeClient(client))
	{
		decl String:text[192];
		GetEventString(event, "text", text, sizeof(text));
		if (strcmp(text, "!help", false) == 0 || strcmp(text, "!info", false) == 0 || strcmp(text, "/help", false) == 0 || strcmp(text, "/info", false) == 0)
		{
			ShowHelpMenu(client, 0);
		}
	}
}

stock ShowHelpMenu(client, page = 0)
{
	if (!IsClientInGame(client)) return;
	new Handle:PopupPanel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
	new String:textformat[255];
	decl String:language[64];
	GetClientInfo(client, "cl_language", language, sizeof(language));
	if (page == 0)
	{
		if (StrContains(language, "korea", false) == -1)
		{
			Format(textformat, sizeof(textformat), "#Lua Zombie Horde  -  Game Info\n ");
			SetPanelTitle(PopupPanel,textformat);
			Format(textformat, sizeof(textformat), "[Steam]  Group.Lua.kr\n[Discord]  Discord.Lua.kr\n ");
			DrawPanelText(PopupPanel, textformat);

			DrawPanelItem(PopupPanel, "Gamemode");				// 1
			DrawPanelItem(PopupPanel, "Player Equipments");		// 2
//			DrawPanelItem(PopupPanel, "Zombie Classes");		// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);			// 3
			DrawPanelText(PopupPanel, "3. Zombie Classes (WIP)");	// 3 TEXT
			DrawPanelItem(PopupPanel, "Chat Commands");			// 4
			DrawPanelItem(PopupPanel, "TIPS\n ");				// 5
		}
		else
		{
			Format(textformat, sizeof(textformat), "#Lua Zombie Horde  -  게임 정보\n ");
			SetPanelTitle(PopupPanel,textformat);
			Format(textformat, sizeof(textformat), "[스팀]  Group.Lua.kr\n[디스코드]  Discord.Lua.kr\n ");
			DrawPanelText(PopupPanel, textformat);

			DrawPanelItem(PopupPanel, "게임모드");			// 1
			DrawPanelItem(PopupPanel, "플레이어 장비");		// 2
//			DrawPanelItem(PopupPanel, "좀비 종류");		// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);			// 3
			DrawPanelText(PopupPanel, "3. 좀비 종류 (제작중)");	// 3 TEXT
			DrawPanelItem(PopupPanel, "채팅 명령어");		// 4
			DrawPanelItem(PopupPanel, "TIPS\n ");		// 5
		}
	}
	else if (page == 1 || page >= 10 && page <= 19)		// Gamemode
	{
		if (page == 1)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Gamemode]\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "Intel Capture");			// 11
				DrawPanelItem(PopupPanel, "Hidden Weapon Cache");	// 12
				DrawPanelItem(PopupPanel, "Evac Helicopter\n ");		// 13
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[게임모드]\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "고가치 정보 회수");	// 11
				DrawPanelItem(PopupPanel, "숨겨진 무기 은닉처");	// 12
				DrawPanelItem(PopupPanel, "탈출용 헬리콥터\n ");	// 13
			}
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 14
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 15
		}
		else if (page == 11)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Gamemode]  Intel capture\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "Object:  Weapon Cache");
				DrawPanelText(PopupPanel, "Weapon cache is gone until capture the intel\n ");
				DrawPanelText(PopupPanel, "Flag will be appear to the enemy and glowing");
				DrawPanelText(PopupPanel, "Kill the flag carrier and pick up the flag");
				DrawPanelText(PopupPanel, "Return it to the base by following the blue line\n ");
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[게임모드]  고가치 정보 회수\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "목표:  무기 은닉처");
				DrawPanelText(PopupPanel, "고가치 정보를 회수하기 전까지 무기 은닉처는 사라짐\n ");
				DrawPanelText(PopupPanel, "특정 적에게 깃발이 생성되며 빛나게 됩니다");
				DrawPanelText(PopupPanel, "깃발을 가지고 있는 적을 사살하고 깃발을 획득하세요");
				DrawPanelText(PopupPanel, "획득 후 파란 선을 따라 기지에 고가치 정보를 회수하세요\n ");
			}
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 2
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 4
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 5
		}
		else if (page == 12)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Gamemode]  Hidden Weapon Cache\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "Object:  Weapon Cache");
				DrawPanelText(PopupPanel, "Weapon cache is gone until find the carrier\n ");
				DrawPanelText(PopupPanel, "Enemy can take the weapon cache and moving around");
				DrawPanelText(PopupPanel, "Kill enemies to find weapon cache carrier");
				DrawPanelText(PopupPanel, "Also have a chance to suicide bomb with weapon cache\n ");
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[게임모드]  숨겨진 무기 은닉처\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "목표:  무기 은닉처");
				DrawPanelText(PopupPanel, "운반자를 찾기 전까지 무기 은닉처는 사라짐\n ");
				DrawPanelText(PopupPanel, "적군은 무기 은닉처를 가지고 주변을 돌아다닐 수도 있습니다");
				DrawPanelText(PopupPanel, "적군을 사살하며 운반자를 찾아내세요");
				DrawPanelText(PopupPanel, "또한 운반자는 무기 은닉처와 함께 자폭할 수도 있습니다\n ");
			}
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 2
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 4
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 5
		}
		else if (page == 13)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Gamemode]  Evac Helicopter\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "Object:  Final Counter-Attack");
				DrawPanelText(PopupPanel, "When Final Counter-Attack is almost over\n ");
				DrawPanelText(PopupPanel, "Evac Helicopter is worth to go for when arriving");
				DrawPanelText(PopupPanel, "To Evac, All players need to join the evac area");
				DrawPanelText(PopupPanel, "Once evac complete, security will be win the game in short time\n ");
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[게임모드]  탈출용 헬리콥터\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "목표:  마지막 카운터-어택");
				DrawPanelText(PopupPanel, "마지막 카운터-어택이 끝나갈 때쯤 시작\n ");
				DrawPanelText(PopupPanel, "탈출용 헬리콥터는 도착할 때쯤 가는 것이 좋습니다");
				DrawPanelText(PopupPanel, "탈출하기 위해서는 모든 플레이어가 탈출 지역 안에 있어야합니다");
				DrawPanelText(PopupPanel, "탈출이 완료되면 짧은 시간 내에 게임을 승리하게 됩니다\n ");
			}
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 2
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 4
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 5
		}
	}
	else if (page == 2 || page >= 20 && page <= 29)		// Player Equipments
	{
		if (page == 2)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Player Equipments]\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "UAV");				// 21
				DrawPanelItem(PopupPanel, "First Aid");			// 22
				DrawPanelItem(PopupPanel, "Barricade");			// 23
				DrawPanelItem(PopupPanel, "Portable Radar");	// 24
				DrawPanelItem(PopupPanel, "IED Jammer\n ");		// 25
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[플레이어 장비]\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "UAV");		// 21
				DrawPanelItem(PopupPanel, "응급 치료킷");	// 22
				DrawPanelItem(PopupPanel, "바리케이드");	// 23
				DrawPanelItem(PopupPanel, "포터블 레이더");	// 24
				DrawPanelItem(PopupPanel, "IED 재머\n ");	// 25
			}
		}
		else if (page == 21)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Player Equipments]  UAV\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "Range:  Global");
				DrawPanelText(PopupPanel, "Enable by Firing P2A1 Flaregun\n ");
				DrawPanelText(PopupPanel, "Amount of time, all enemies will be glowing");
				DrawPanelText(PopupPanel, "UAV has long cooldown time\n ");
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[플레이어 장비]  UAV\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "사거리:  맵 전체");
				DrawPanelText(PopupPanel, "P2A1 플레어건을 사용하여 작동\n ");
				DrawPanelText(PopupPanel, "일정 시간동안 모든 적군이 빛나게 됩니다");
				DrawPanelText(PopupPanel, "UAV 는 긴 쿨타임을 가집니다\n ");
			}
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 2
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 4
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 5
		}
		else if (page == 22)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Player Equipments]  First Aid\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "Target:  Self or Teammate");
				DrawPanelText(PopupPanel, "Healing woundes for yourself or teammate\n ");
				DrawPanelText(PopupPanel, "Equip First Aid and [Left Click] to self heal");
				DrawPanelText(PopupPanel, "[Right Click] to heal teammate");
				DrawPanelText(PopupPanel, "Medic class has more effective and faster healing\n ");
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[플레이어 장비]  응급 치료킷\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "대상:  자신 또는 타 플레이어");
				DrawPanelText(PopupPanel, "자신 또는 타 플레이어의 상처를 치료\n ");
				DrawPanelText(PopupPanel, "응급 치료킷 장비 후 [왼쪽 클릭] 으로 자가 치료");
				DrawPanelText(PopupPanel, "[오른쪽 클릭] 으로 타 플레이어를 치료합니다");
				DrawPanelText(PopupPanel, "메딕 병과는 더 효과적이고 빠르게 치료할 수 있습니다\n ");
			}
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 2
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 4
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 5
		}
		else if (page == 23)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Player Equipments]  Barricade\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "Target:  Ground");
				DrawPanelText(PopupPanel, "Install barricade to take cover\n ");
				DrawPanelText(PopupPanel, "Equip Knfie, [Right Click] to install");
				DrawPanelText(PopupPanel, "Engineer Class can repair the damaged barricades\n ");
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[플레이어 장비]  바리케이드\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "대상:  지상");
				DrawPanelText(PopupPanel, "엄폐할 수 있는 바리케이드를 설치\n ");
				DrawPanelText(PopupPanel, "나이프를 장비 후 [오른쪽 클릭] 으로 설치합니다");
				DrawPanelText(PopupPanel, "엔지니어 병과는 데미지를 받은 바리케이드를 수리할 수 있습니다\n ");
			}
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 2
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 4
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 5
		}
		else if (page == 24)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Player Equipments]  Portable Radar\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "Range:  900 ft");
				DrawPanelText(PopupPanel, "Placeable Portable Radar, spotting enemy in range\n ");
				DrawPanelText(PopupPanel, "Equip Knfie, [Right Click] to install");
				DrawPanelText(PopupPanel, "It has chance to broke\n ");
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[플레이어 장비]  포터블 레이더\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "사거리:  900 걸음");
				DrawPanelText(PopupPanel, "사거리 내의 적을 알려주는 설치용 포터블 레이더\n ");
				DrawPanelText(PopupPanel, "나이프를 장비후 [오른쪽 클릭] 으로 설치합니다");
				DrawPanelText(PopupPanel, "고장날 수 있는 확률이 있습니다\n ");
			}
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 2
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 4
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 5
		}
		else if (page == 25)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Player Equipments]  IED Jammer\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "Range:  1200 ft");
				DrawPanelText(PopupPanel, "Placeable IED Jammer, delays suicide bomber detonate time in range\n ");
				DrawPanelText(PopupPanel, "Equip Knfie, [Right Click] to install");
				DrawPanelText(PopupPanel, "It has chance to broke\n ");
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[플레이어 장비]  IED 재머\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "사거리:  1200 걸음");
				DrawPanelText(PopupPanel, "사거리 내의 자폭병의 폭발 시간을 늘려주는 설치용 IED 재머\n ");
				DrawPanelText(PopupPanel, "나이프를 장비후 [오른쪽 클릭] 으로 설치합니다");
				DrawPanelText(PopupPanel, "고장날 수 있는 확률이 있습니다\n ");
			}
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 2
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 4
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 5
		}
	}
	else if (page == 3 || page >= 30 && page <= 39)		// Enemy Special Classes
	{
		if (page == 3)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Enemy Special Classes]\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "LMG");				// 31
				DrawPanelItem(PopupPanel, "Traitor");			// 32
				DrawPanelItem(PopupPanel, "Suicide Bomber\n ");	// 33
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[적군 특수 병과]\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "LMG");		// 31
				DrawPanelItem(PopupPanel, "반역자");		// 32
				DrawPanelItem(PopupPanel, "자폭병\n ");	// 33
			}
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 34
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 35
		}
		else if (page == 31)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Enemy Special Classes]  LMG\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "Class:  LMG");
				DrawPanelText(PopupPanel, "Has huge body with high health\n ");
				DrawPanelText(PopupPanel, "Armor, Explosive, LMG with ROF Mod");
				DrawPanelText(PopupPanel, "Aim for the head to take him down!\n ");
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[적군 특수 병과]  LMG\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "병과:  LMG");
				DrawPanelText(PopupPanel, "타 병과에 비해 큰 몸집과 높은 체력을 보유\n ");
				DrawPanelText(PopupPanel, "방어구, 폭발류, ROF 모드가 장착된 머신건을 사용");
				DrawPanelText(PopupPanel, "머리를 노리면 쉽게 제압할 수 있습니다!\n ");
			}
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 2
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 4
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 5
		}
		else if (page == 32)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Enemy Special Classes]  Traitor\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "Class:  Security");
				DrawPanelText(PopupPanel, "Has security character models\n ");
				DrawPanelText(PopupPanel, "UAV and Portable Radar has no effect on this class");
				DrawPanelText(PopupPanel, "Armor, Explosive, Heavy Weapons\n ");
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[적군 특수 병과]  반역자\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "병과:  안보지원군");
				DrawPanelText(PopupPanel, "안보지원군과 같은 생김새를 한 병과\n ");
				DrawPanelText(PopupPanel, "UAV와 포터블 레이더의 효과를 받지 않는 병과입니다");
				DrawPanelText(PopupPanel, "방어구, 폭발류, 고화력 무기를 사용\n ");
			}
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 2
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 4
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 5
		}
		else if (page == 33)
		{
			if (StrContains(language, "korea", false) == -1)
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Enemy Special Classes]  Suicide Bomber\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "Class:  Suicide Bomber");
				DrawPanelText(PopupPanel, "Has high speed with suicide bomb\n ");
				DrawPanelText(PopupPanel, "Carrying suicide bomb on hands and detonate when player spotted");
				DrawPanelText(PopupPanel, "Also if not death by headshot have a chance to detonate\n ");
			}
			else
			{
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[적군 특수 병과]  자폭병\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "병과:  자폭병");
				DrawPanelText(PopupPanel, "빠른 속도와 자폭용 폭발물을 사용하는 병과\n ");
				DrawPanelText(PopupPanel, "자폭용 폭발물을 손에 들고 플레이어를 발견하면 터트립니다");
				DrawPanelText(PopupPanel, "또한 헤드샷이 아닐 경우 사망시 폭발할 수도 있습니다\n ");
			}
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 2
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 4
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 5
		}
	}
	else if (page == 4)		// Chat Commands
	{
		if (StrContains(language, "korea", false) == -1)
		{
			Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[Chat Commands]\n ");
			SetPanelTitle(PopupPanel,textformat);

			DrawPanelItem(PopupPanel, "Rank System");							// 41
			DrawPanelText(PopupPanel, "        rank");
			DrawPanelText(PopupPanel, "        stats  (stats nickname)");
			DrawPanelText(PopupPanel, "        top10  (top0 - 1000)\n ");
			DrawPanelItem(PopupPanel, "Call Map Vote");							// 42
			DrawPanelText(PopupPanel, "        rtv, rockthevote");
			DrawPanelText(PopupPanel, "        (60% players required)\n ");
		}
		else
		{
			Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[채팅 명령어]\n ");
			SetPanelTitle(PopupPanel,textformat);

			DrawPanelItem(PopupPanel, "랭크 시스템");							// 41
			DrawPanelText(PopupPanel, "        rank");
			DrawPanelText(PopupPanel, "        stats  (stats 닉네임)");
			DrawPanelText(PopupPanel, "        top10  (top0 - 1000)\n ");
			DrawPanelItem(PopupPanel, "맵 투표 및 바꾸기");						// 42
			DrawPanelText(PopupPanel, "        rtv, rockthevote");
			DrawPanelText(PopupPanel, "        (플레이어 중 60%가 사용해야합니다)\n ");
		}
		DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 43
		DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 44
		DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 45
	}
	else if (page == 5)		// TIPS
	{
		if (StrContains(language, "korea", false) == -1)
		{
			Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[TIPS]\n ");
			SetPanelTitle(PopupPanel,textformat);

			DrawPanelItem(PopupPanel, "Glowing Players");							// 51
			DrawPanelText(PopupPanel, "        Medic or Wounded player\n ");
			DrawPanelItem(PopupPanel, "Bleeding or Low HP");						// 52
			DrawPanelText(PopupPanel, "        Use First Aid or Find a Medic and Call (F Key)");
			DrawPanelText(PopupPanel, "        'Death' status has black-out\n ");
			DrawPanelItem(PopupPanel, "On Fire");									// 53
			DrawPanelText(PopupPanel, "        Extinguish fire by Prone\n ");
			DrawPanelItem(PopupPanel, "Headshots and knife has more damage\n ");					// 54
			DrawPanelItem(PopupPanel, "Enemy Back Spawn");							// 55
			DrawPanelText(PopupPanel, "        Enemies can reinforcement from Behind\n ");
		}
		else
		{
			Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[TIPS]\n ");
			SetPanelTitle(PopupPanel,textformat);

			DrawPanelItem(PopupPanel, "빛나는 플레이어");								// 51
			DrawPanelText(PopupPanel, "        메딕 또는 치명상을 입은 플레이어\n ");
			DrawPanelItem(PopupPanel, "출혈 또는 낮은 체력");					// 52
			DrawPanelText(PopupPanel, "        First Aid 사용 또는 메딕을 찾아가서 요청 (F 키)");
			DrawPanelText(PopupPanel, "        'Death' 상태시 시야가 어두워짐\n ");
			DrawPanelItem(PopupPanel, "불이 붙을 경우");									// 53
			DrawPanelText(PopupPanel, "        엎드려서 불을 끔\n ");
			DrawPanelItem(PopupPanel, "헤드샷과 나이프는 높은 데미지를 보유\n ");					// 54
			DrawPanelItem(PopupPanel, "적군 후방 스폰");							// 55
			DrawPanelText(PopupPanel, "        적군은 후방에서도 스폰합니다\n ");
		}
	}
	else return;

	if (page > 0)
	{
		if (StrContains(language, "korea", false) == -1)
			DrawPanelItem(PopupPanel, "[Q]  Back");	// 6
		else
			DrawPanelItem(PopupPanel, "[Q]  뒤로가기");	// 6
	}
	else
		DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 6
	DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 7
	DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 8
	if (StrContains(language, "korea", false) == -1)
		DrawPanelItem(PopupPanel, "[TAB]  Close");	// 9
	else
		DrawPanelItem(PopupPanel, "[TAB]  닫기");	// 9

	if (!IsPlayerAlive(client))
		SetEntProp(client, Prop_Send, "m_iHideHUD", HIDEHUD_HEALTH);
	SendPanelToClient(PopupPanel, client, HelpMenuHandler, 60);
	g_iCurrentPage[client] = page;
	CloseHandle(PopupPanel);
}

public HelpMenuHandler(Handle:menu, MenuAction:action, client, select)
{
	if (action == MenuAction_Select)
	{
		if (select >= 1 && select <= 5)
		{
			if (g_iCurrentPage[client] <= 3)
				ShowHelpMenu(client, select+(g_iCurrentPage[client]*10));
			else
				ShowHelpMenu(client, g_iCurrentPage[client]);
		}
		else if (select == 6)		// Back
		{
			if (g_iCurrentPage[client] >= 1 && g_iCurrentPage[client] <= 5)
			{
				ShowHelpMenu(client, 0);
			}
			else if (g_iCurrentPage[client] >= 10 && g_iCurrentPage[client] <= 19)
			{
				ShowHelpMenu(client, 1);
			}
			else if (g_iCurrentPage[client] >= 20 && g_iCurrentPage[client] <= 29)
			{
				ShowHelpMenu(client, 2);
			}
			else if (g_iCurrentPage[client] >= 30 && g_iCurrentPage[client] <= 39)
			{
				ShowHelpMenu(client, 3);
			}
			else if (g_iCurrentPage[client] >= 40 && g_iCurrentPage[client] <= 49)
			{
				ShowHelpMenu(client, 4)
			}
			else if (g_iCurrentPage[client] >= 50 && g_iCurrentPage[client] <= 59)
			{
				ShowHelpMenu(client, 5);
			}
			else
			{
				g_iCurrentPage[client] = -1;
			}
		}
	}
	else if (action == MenuAction_End)
	{
		g_iCurrentPage[client] = -1;
	}
}

