package;

import flixel.FlxG;
import openfl.utils.Assets;

using StringTools;
#if sys
import sys.FileSystem;
import sys.io.File;
#else
import openfl.utils.Assets;
#end

class CoolUtil
{
	inline public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	inline public static function repeat(value:Int, delta:Int, loop:Int):Int
	{
		var newValue:Int = (value + delta) % loop;
		return newValue < 0 ? loop - 1 : newValue;
	}

	inline public static function boolToInt(value:Bool):Int
	{
		return value ? 1 : 0;
	}

	inline public static function getDelta(a:Bool, b:Bool):Int
	{
		return boolToInt(a) - boolToInt(b);
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if sys
		if (FileSystem.exists(path))
			daList = File.getContent(path).trim().split('\n');
		#else
		if (Assets.exists(path))
			daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();
		return daList;
	}

	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();
		return daList;
	}

	public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel != 0)
				{
					if (countByColor.exists(colorOfThisPixel)) { countByColor[colorOfThisPixel]++; }
					else if (countByColor[colorOfThisPixel] != -13520687) { countByColor[colorOfThisPixel] = 1; }
				}
			}
		}

		var maxCount:Int = 0;
		var maxKey:Int = 0; // after the loop this will store the max color

		countByColor[flixel.util.FlxColor.BLACK] = 0;
		for (key in countByColor.keys())
		{
			var curCount:Int = countByColor[key];
			if (curCount >= maxCount)
			{
				maxCount = curCount;
				maxKey = key;
			}
		}
		return maxKey;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	// uhhhh does this even work at all? i'm starting to doubt
	public static function precacheSound(sound:String, ?library:String = null):Void
	{
		Paths.sound(sound, library);
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void
	{
		Paths.music(sound, library);
	}

	public static function precacheSong(song:String):Void
	{
		Paths.inst(song);
		Paths.voices(song);
	}

	public static function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}
}