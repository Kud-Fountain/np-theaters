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
			Format(textformat, sizeof(textformat), "#Lua Zombie Horde  -  ���� ����\n ");
			SetPanelTitle(PopupPanel,textformat);
			Format(textformat, sizeof(textformat), "[����]  Group.Lua.kr\n[���ڵ�]  Discord.Lua.kr\n ");
			DrawPanelText(PopupPanel, textformat);

			DrawPanelItem(PopupPanel, "���Ӹ��");			// 1
			DrawPanelItem(PopupPanel, "�÷��̾� ���");		// 2
//			DrawPanelItem(PopupPanel, "���� ����");		// 3
			DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);			// 3
			DrawPanelText(PopupPanel, "3. ���� ���� (������)");	// 3 TEXT
			DrawPanelItem(PopupPanel, "ä�� ��ɾ�");		// 4
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[���Ӹ��]\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "��ġ ���� ȸ��");	// 11
				DrawPanelItem(PopupPanel, "������ ���� ����ó");	// 12
				DrawPanelItem(PopupPanel, "Ż��� �︮����\n ");	// 13
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[���Ӹ��]  ��ġ ���� ȸ��\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "��ǥ:  ���� ����ó");
				DrawPanelText(PopupPanel, "��ġ ������ ȸ���ϱ� ������ ���� ����ó�� �����\n ");
				DrawPanelText(PopupPanel, "Ư�� ������ ����� �����Ǹ� ������ �˴ϴ�");
				DrawPanelText(PopupPanel, "����� ������ �ִ� ���� ����ϰ� ����� ȹ���ϼ���");
				DrawPanelText(PopupPanel, "ȹ�� �� �Ķ� ���� ���� ������ ��ġ ������ ȸ���ϼ���\n ");
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[���Ӹ��]  ������ ���� ����ó\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "��ǥ:  ���� ����ó");
				DrawPanelText(PopupPanel, "����ڸ� ã�� ������ ���� ����ó�� �����\n ");
				DrawPanelText(PopupPanel, "������ ���� ����ó�� ������ �ֺ��� ���ƴٴ� ���� �ֽ��ϴ�");
				DrawPanelText(PopupPanel, "������ ����ϸ� ����ڸ� ã�Ƴ�����");
				DrawPanelText(PopupPanel, "���� ����ڴ� ���� ����ó�� �Բ� ������ ���� �ֽ��ϴ�\n ");
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[���Ӹ��]  Ż��� �︮����\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "��ǥ:  ������ ī����-����");
				DrawPanelText(PopupPanel, "������ ī����-������ ������ ���� ����\n ");
				DrawPanelText(PopupPanel, "Ż��� �︮���ʹ� ������ ���� ���� ���� �����ϴ�");
				DrawPanelText(PopupPanel, "Ż���ϱ� ���ؼ��� ��� �÷��̾ Ż�� ���� �ȿ� �־���մϴ�");
				DrawPanelText(PopupPanel, "Ż���� �Ϸ�Ǹ� ª�� �ð� ���� ������ �¸��ϰ� �˴ϴ�\n ");
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[�÷��̾� ���]\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "UAV");		// 21
				DrawPanelItem(PopupPanel, "���� ġ��Ŷ");	// 22
				DrawPanelItem(PopupPanel, "�ٸ����̵�");	// 23
				DrawPanelItem(PopupPanel, "���ͺ� ���̴�");	// 24
				DrawPanelItem(PopupPanel, "IED ���\n ");	// 25
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[�÷��̾� ���]  UAV\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "��Ÿ�:  �� ��ü");
				DrawPanelText(PopupPanel, "P2A1 �÷������ ����Ͽ� �۵�\n ");
				DrawPanelText(PopupPanel, "���� �ð����� ��� ������ ������ �˴ϴ�");
				DrawPanelText(PopupPanel, "UAV �� �� ��Ÿ���� �����ϴ�\n ");
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[�÷��̾� ���]  ���� ġ��Ŷ\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "���:  �ڽ� �Ǵ� Ÿ �÷��̾�");
				DrawPanelText(PopupPanel, "�ڽ� �Ǵ� Ÿ �÷��̾��� ��ó�� ġ��\n ");
				DrawPanelText(PopupPanel, "���� ġ��Ŷ ��� �� [���� Ŭ��] ���� �ڰ� ġ��");
				DrawPanelText(PopupPanel, "[������ Ŭ��] ���� Ÿ �÷��̾ ġ���մϴ�");
				DrawPanelText(PopupPanel, "�޵� ������ �� ȿ�����̰� ������ ġ���� �� �ֽ��ϴ�\n ");
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[�÷��̾� ���]  �ٸ����̵�\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "���:  ����");
				DrawPanelText(PopupPanel, "������ �� �ִ� �ٸ����̵带 ��ġ\n ");
				DrawPanelText(PopupPanel, "�������� ��� �� [������ Ŭ��] ���� ��ġ�մϴ�");
				DrawPanelText(PopupPanel, "�����Ͼ� ������ �������� ���� �ٸ����̵带 ������ �� �ֽ��ϴ�\n ");
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[�÷��̾� ���]  ���ͺ� ���̴�\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "��Ÿ�:  900 ����");
				DrawPanelText(PopupPanel, "��Ÿ� ���� ���� �˷��ִ� ��ġ�� ���ͺ� ���̴�\n ");
				DrawPanelText(PopupPanel, "�������� ����� [������ Ŭ��] ���� ��ġ�մϴ�");
				DrawPanelText(PopupPanel, "���峯 �� �ִ� Ȯ���� �ֽ��ϴ�\n ");
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[�÷��̾� ���]  IED ���\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "��Ÿ�:  1200 ����");
				DrawPanelText(PopupPanel, "��Ÿ� ���� �������� ���� �ð��� �÷��ִ� ��ġ�� IED ���\n ");
				DrawPanelText(PopupPanel, "�������� ����� [������ Ŭ��] ���� ��ġ�մϴ�");
				DrawPanelText(PopupPanel, "���峯 �� �ִ� Ȯ���� �ֽ��ϴ�\n ");
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[���� Ư�� ����]\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "LMG");		// 31
				DrawPanelItem(PopupPanel, "�ݿ���");		// 32
				DrawPanelItem(PopupPanel, "������\n ");	// 33
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[���� Ư�� ����]  LMG\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "����:  LMG");
				DrawPanelText(PopupPanel, "Ÿ ������ ���� ū ������ ���� ü���� ����\n ");
				DrawPanelText(PopupPanel, "��, ���߷�, ROF ��尡 ������ �ӽŰ��� ���");
				DrawPanelText(PopupPanel, "�Ӹ��� �븮�� ���� ������ �� �ֽ��ϴ�!\n ");
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[���� Ư�� ����]  �ݿ���\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "����:  �Ⱥ�������");
				DrawPanelText(PopupPanel, "�Ⱥ��������� ���� ������� �� ����\n ");
				DrawPanelText(PopupPanel, "UAV�� ���ͺ� ���̴��� ȿ���� ���� �ʴ� �����Դϴ�");
				DrawPanelText(PopupPanel, "��, ���߷�, ��ȭ�� ���⸦ ���\n ");
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
				Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[���� Ư�� ����]  ������\n ");
				SetPanelTitle(PopupPanel,textformat);

				DrawPanelItem(PopupPanel, "����:  ������");
				DrawPanelText(PopupPanel, "���� �ӵ��� ������ ���߹��� ����ϴ� ����\n ");
				DrawPanelText(PopupPanel, "������ ���߹��� �տ� ��� �÷��̾ �߰��ϸ� ��Ʈ���ϴ�");
				DrawPanelText(PopupPanel, "���� ��弦�� �ƴ� ��� ����� ������ ���� �ֽ��ϴ�\n ");
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
			Format(textformat, sizeof(textformat), "#Lua Zombie Horde\n[ä�� ��ɾ�]\n ");
			SetPanelTitle(PopupPanel,textformat);

			DrawPanelItem(PopupPanel, "��ũ �ý���");							// 41
			DrawPanelText(PopupPanel, "        rank");
			DrawPanelText(PopupPanel, "        stats  (stats �г���)");
			DrawPanelText(PopupPanel, "        top10  (top0 - 1000)\n ");
			DrawPanelItem(PopupPanel, "�� ��ǥ �� �ٲٱ�");						// 42
			DrawPanelText(PopupPanel, "        rtv, rockthevote");
			DrawPanelText(PopupPanel, "        (�÷��̾� �� 60%�� ����ؾ��մϴ�)\n ");
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

			DrawPanelItem(PopupPanel, "������ �÷��̾�");								// 51
			DrawPanelText(PopupPanel, "        �޵� �Ǵ� ġ����� ���� �÷��̾�\n ");
			DrawPanelItem(PopupPanel, "���� �Ǵ� ���� ü��");					// 52
			DrawPanelText(PopupPanel, "        First Aid ��� �Ǵ� �޵��� ã�ư��� ��û (F Ű)");
			DrawPanelText(PopupPanel, "        'Death' ���½� �þ߰� ��ο���\n ");
			DrawPanelItem(PopupPanel, "���� ���� ���");									// 53
			DrawPanelText(PopupPanel, "        ������� ���� ��\n ");
			DrawPanelItem(PopupPanel, "��弦�� �������� ���� �������� ����\n ");					// 54
			DrawPanelItem(PopupPanel, "���� �Ĺ� ����");							// 55
			DrawPanelText(PopupPanel, "        ������ �Ĺ濡���� �����մϴ�\n ");
		}
	}
	else return;

	if (page > 0)
	{
		if (StrContains(language, "korea", false) == -1)
			DrawPanelItem(PopupPanel, "[Q]  Back");	// 6
		else
			DrawPanelItem(PopupPanel, "[Q]  �ڷΰ���");	// 6
	}
	else
		DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 6
	DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 7
	DrawPanelItem(PopupPanel, "", ITEMDRAW_NOTEXT);	// 8
	if (StrContains(language, "korea", false) == -1)
		DrawPanelItem(PopupPanel, "[TAB]  Close");	// 9
	else
		DrawPanelItem(PopupPanel, "[TAB]  �ݱ�");	// 9

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

