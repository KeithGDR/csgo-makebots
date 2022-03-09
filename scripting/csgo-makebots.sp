/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[CSGO] MakeBots"
#define PLUGIN_DESCRIPTION "A simple plugin with API to make bots with proper think hooks without using an extension."
#define PLUGIN_VERSION "1.0.0"

/*****************************/
//Includes
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <csgo-makebots>

/*****************************/
//ConVars

/*****************************/
//Globals

bool g_MakeBot;
DataPack g_GlobalPack;

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("csgo-makebots");
	CreateNative("CSGO_MakeBot", Native_MakeBot);
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_GlobalPack = new DataPack();
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	RegAdminCmd("sm_makebot", Command_MakeBot, ADMFLAG_ROOT, "Creates a bot using the MakeBot functionality.");
}

public int Native_MakeBot(Handle plugin, int numParams)
{
	int size;
	GetNativeStringLength(1, size); size++;

	char[] name = new char[size];
	GetNativeString(1, name, size);

	int team = GetNativeCell(2);
	any data = GetNativeCell(3);

	Function oncreated = GetNativeFunction(4);
	Function onspawned = GetNativeFunction(5);

	if (strlen(name) == 0)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid name specified, you must give the bot a name.");

	if (team < 2 || team > 3)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid team index specified when making a bot, must be either 2 or 3.");
	//TODO: Make it so you can create multiple bots at once.
	if (g_MakeBot)
		return false;
	
	g_MakeBot = true;

	g_GlobalPack.Reset();
	g_GlobalPack.WriteCell(team);
	g_GlobalPack.WriteCell(data);
	g_GlobalPack.WriteCell(size);
	g_GlobalPack.WriteString(name);
	g_GlobalPack.WriteCell(plugin);
	g_GlobalPack.WriteFunction(oncreated);
	g_GlobalPack.WriteFunction(onspawned);

	ServerCommand((team == 2) ? "bot_add_t" : "bot_add_ct");

	return true;
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client) && g_MakeBot)
	{
		g_GlobalPack.Reset();

		int team = g_GlobalPack.ReadCell();
		int data = g_GlobalPack.ReadCell();
		int size = g_GlobalPack.ReadCell();
		
		char[] name = new char[size];
		g_GlobalPack.ReadString(name, size);

		CS_SwitchTeam(client, team);
		SetClientName(client, name);

		Handle plugin = g_GlobalPack.ReadCell();
		Function oncreated = g_GlobalPack.ReadFunction();

		Call_StartFunction(plugin, oncreated);
		Call_PushCell(client);
		Call_PushCell(data);
		Call_Finish();

		CS_RespawnPlayer(client);
	}
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsFakeClient(client) || !g_MakeBot)
		return;
	
	g_GlobalPack.Reset();
	g_GlobalPack.ReadCell();
	any data = g_GlobalPack.ReadCell();
	g_GlobalPack.ReadCell();
	char buffer[64];
	g_GlobalPack.ReadString(buffer, sizeof(buffer));

	Handle plugin = g_GlobalPack.ReadCell();
	g_GlobalPack.ReadFunction();
	Function onspawned = g_GlobalPack.ReadFunction();
	
	Call_StartFunction(plugin, onspawned);
	Call_PushCell(client);
	Call_PushCell(data);
	Call_Finish();

	g_MakeBot = false;
}

public Action Command_MakeBot(int client, int args)
{
	if (client < 1)
		return Plugin_Handled;
	
	if (args != 2)
	{
		char sCommand[32];
		GetCmdArg(0, sCommand, sizeof(sCommand));
		ReplyToCommand(client, "[SM] Usage: %s <name> <team>", sCommand);
		return Plugin_Handled;
	}

	char sName[MAX_NAME_LENGTH];
	GetCmdArg(1, sName, sizeof(sName));

	if (strlen(sName) == 0)
	{
		ReplyToCommand(client, "Name must be specified and not empty.");
		return Plugin_Handled;
	}

	char sTeam[16];
	GetCmdArg(2, sTeam, sizeof(sTeam));
	int team = StringToInt(sTeam);

	if (team < 2 || team > 3)
	{
		ReplyToCommand(client, "Team index must be specified between 2 and 3.");
		return Plugin_Handled;
	}

	bool passed = CSGO_MakeBot(sName, team, GetClientUserId(client), MakeBot_OnCreated, MakeBot_OnSpawned);
	ReplyToCommand(client, "[Makebot] Created bot '%s': %s", sName, passed ? "passed" : "failed");

	return Plugin_Handled;
}

public void MakeBot_OnCreated(int bot, any data)
{
	int client;
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	char sName[MAX_NAME_LENGTH];
	GetClientName(bot, sName, sizeof(sName));
	ReplyToCommand(client, "[MakeBot] '%s' has been created.", sName);
}

public void MakeBot_OnSpawned(int bot, any data)
{
	int client;
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	char sName[MAX_NAME_LENGTH];
	GetClientName(bot, sName, sizeof(sName));
	ReplyToCommand(client, "[MakeBot] '%s' has been spawned.", sName);
}