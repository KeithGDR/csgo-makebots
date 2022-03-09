#if defined _csgo_makebots_included
  #endinput
#endif
#define _csgo_makebots_included

typedef MakeBot_OnCreated = function void (int bot, any data);
typedef MakeBot_OnSpawned = function void (int bot, any data);

/**
 * Creates a bot using the traditional bot_add_t and bot_add_ct commands in order for the bot to have proper think functionality.
 * If you don't need the think functionality then you're better off just using CreateFakeClient instead.
 * 
 * Only allowed to create 1 bot at a time.
 * 
 * @param name			The name of the bot to use.
 * @param team			The team for the bot to be on.
 * @param data			Pass data through to the callbacks.
 * @param oncreated		Called once the bot is created and in-game after being made.
 * @param onspawned		Called once the bot is spawned on the map after being made.
 *
 * @return True if created and functions are being passed, false otherwise.
 */
native bool CSGO_MakeBot(const char[] name, int team, any data = 0, MakeBot_OnCreated oncreated = INVALID_FUNCTION, MakeBot_OnSpawned onspawned = INVALID_FUNCTION);

#if !defined REQUIRE_PLUGIN
public void __pl_csgo_makebots_SetNTVOptional()
{
	MarkNativeAsOptional("CSGO_MakeBot");
}
#endif

public SharedPlugin __pl_csgo_makebots =
{
	name = "csgo-makebots",
	file = "csgo-makebots.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};