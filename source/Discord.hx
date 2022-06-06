package;

using StringTools;

#if (desktop && !neko && !debug)
import Sys.sleep;
import sys.thread.Thread;
import discord_rpc.DiscordRpc;
#end

class DiscordClient
{
	private static var largeText:String = "HAPPY BIRTHDAY TOP 10 AWESOME!!!";
	public static var isInitialized:Bool = false;
	#if (desktop && !neko && !debug)
	private static var curPresence:DiscordPresenceOptions;
	#end

	public function new()
	{
		#if (desktop && !neko && !debug)
		trace("Discord Client starting...");
		DiscordRpc.start({
			clientID: "983194614263603272",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		trace("Discord Client started.");
		while (true)
		{
			if (curPresence != null)
			{
				DiscordRpc.presence(curPresence);
				curPresence = null;
			}
			DiscordRpc.process();
			sleep(1);
			// trace("Discord Client Update");
		}
		DiscordRpc.shutdown();
		#end
	}

	public static function shutdown()
	{
		#if (desktop && !neko && !debug)
		DiscordRpc.shutdown();
		#end
	}

	static function onReady()
	{
		#if (desktop && !neko && !debug)
		DiscordRpc.presence({
			details: "In the Menus",
			state: null,
			largeImageKey: 'top10awesomelogo',
			largeImageText: largeText
		});
		#end
	}

	static function onError(_code:Int, _message:String)
	{
		trace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String)
	{
		trace('Disconnected! $_code : $_message');
	}

	public static function initialize()
	{
		#if (desktop && !neko && !debug)
		var daemon:Thread = sys.thread.Thread.create(() -> { new DiscordClient(); });
		isInitialized = true;

		trace("Discord Client initialized");
		trace(daemon);
		#end
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float)
	{
		#if (desktop && !neko && !debug)
		var startTimestamp:Float = hasStartTimestamp ? Date.now().getTime() : 0;
		if (endTimestamp > 0 && hasStartTimestamp)
			endTimestamp = startTimestamp + endTimestamp;

		curPresence = { // DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: 'top10awesomelogo',
			largeImageText: largeText,
			smallImageKey: smallImageKey,
			// Obtained times are in milliseconds so they are divided so Discord can use it
			startTimestamp: hasStartTimestamp ? Std.int(startTimestamp / 1000) : null,
			endTimestamp: hasStartTimestamp ? Std.int(endTimestamp / 1000) : null
		}; // );
		#end
		// trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}
}