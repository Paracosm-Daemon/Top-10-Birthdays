package;

import flixel.system.FlxSound;
import openfl.utils.Assets;
import flixel.FlxG;
import flixel.system.FlxAssets.FlxSoundAsset;

using StringTools;
#if sys
import sys.FileSystem;
#end

class Hitsound
{
	private static var hitsound:String = 'hitsound';

	public static function canPlayHitsound():Bool { return ClientPrefs.hitsoundVolume > 0; }
	public static function play(cache:Bool = false):Null<FlxSound>
	{
		if (!canPlayHitsound()) return null;
		switch (cache)
		{
			default: return FlxG.sound.play(Paths.sound(hitsound), ClientPrefs.hitsoundVolume);
			case true: CoolUtil.precacheSound(hitsound);
		}
		return null;
	}
}