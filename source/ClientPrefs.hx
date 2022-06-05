package;

import Controls;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;

class ClientPrefs
{
	public static var reducedMotion:Bool = false;
	public static var scrollUnderlay:Float = 0; // WHY IS THIS NOT IN NATIVE PSYCH

	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var opponentStrums:Bool = true;
	public static var showFPS:Bool = false;
	public static var flashing:Bool = true;
	public static var globalAntialiasing:Bool = true;
	public static var noteSplashes:Bool = true;
	public static var lowQuality:Bool = false;
	public static var framerate:Int = 60;
	public static var camZooms:Bool = true;
	public static var hideHud:Bool = false;
	public static var noteOffset:Int = 0;
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public static var ghostTapping:Bool = true;
	public static var timeBarType:String = 'Time Left';
	public static var scoreZoom:Bool = true;
	public static var noReset:Bool = false;
	public static var healthBarAlpha:Float = 1;
	public static var controllerMode:Bool = false;
	public static var hitsoundVolume:Float = 0;
	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		// 'healthgain' => 1.0,
		// 'healthloss' => 1.0,
		// 'instakill' => false,
		// 'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];

	public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	public static var ratingOffset:Int = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var safeFrames:Float = 10;

	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		// Key Bind, Name for ControlsSubState
		'note_left' => [A, LEFT],
		'note_down' => [S, DOWN],
		'note_up' => [W, UP],
		'note_right' => [D, RIGHT],
		'ui_left' => [A, LEFT],
		'ui_down' => [S, DOWN],
		'ui_up' => [W, UP],
		'ui_right' => [D, RIGHT],
		'accept' => [SPACE, ENTER],
		'back' => [BACKSPACE, ESCAPE],
		'pause' => [ENTER, ESCAPE],
		'hit' => [SPACE, NONE],
		'reset' => [R, NONE],
		'volume_mute' => [ZERO, NONE],
		'volume_up' => [NUMPADPLUS, PLUS],
		'volume_down' => [NUMPADMINUS, MINUS],
		'debug_1' => [SEVEN, NONE],
		'debug_2' => [EIGHT, NONE]
	];
	public static var persistentData:Array<String> = [
		'reducedMotion', 'downScroll', 'middleScroll', 'opponentStrums', 'flashing', 'globalAntialiasing', 'noteSplashes', 'lowQuality', 'camZooms', 'noteOffset',
		'hideHud', 'ghostTapping', 'timeBarType', 'scoreZoom', 'noReset', 'healthBarAlpha', 'comboOffset', 'ratingOffset', 'controllerMode', 'hitsoundVolume', 'scrollUnderlay'
	];
	public static var persistentFunctions:Map<String, Dynamic> = [
		'framerate' => function(data):Bool
		{
			if (data > FlxG.drawFramerate)
			{
				FlxG.updateFramerate = data;
				FlxG.drawFramerate = data;
			}
			else
			{
				FlxG.drawFramerate = data;
				FlxG.updateFramerate = data;
			}

			return true;
		},
		'showFPS' => function(data):Bool
		{
			if (Main.fpsVar != null)
				Main.fpsVar.visible = data;
			return true;
		}
	];
	public static var persistentMapData:Array<String> = ['gameplaySettings'];
	public static var flixelPersistentData:Map<String, String> = ['volume' => 'volume', 'mute' => 'muted'];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		// trace(defaultKeys);
	}

	public static function saveSettings()
	{
		for (persistent in persistentData)
		{
			var savedData = Reflect.getProperty(ClientPrefs, persistent);
			if (savedData != null)
				Reflect.setProperty(FlxG.save.data, persistent, savedData);
		}
		for (persistent in persistentFunctions.keys())
		{
			var savedData = Reflect.getProperty(ClientPrefs, persistent);
			if (savedData != null)
				Reflect.setProperty(FlxG.save.data, persistent, savedData);
		}
		for (persistent in persistentMapData)
		{
			var savedMap:Map<Any, Any> = Reflect.getProperty(ClientPrefs, persistent);
			if (savedMap != null)
			{
				var reflectMap:Map<Any, Any> = Reflect.getProperty(FlxG.save.data, persistent);
				if (reflectMap != null)
				{
					for (name => value in savedMap)
						reflectMap.set(name, value);
				}
			}
		}

		FlxG.save.flush();
		var save:FlxSave = new FlxSave();

		save.bind('top10controls', 'top10birthdays'); // Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		save.data.customControls = keyBinds;

		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs()
	{
		for (persistent in persistentData)
		{
			var savedData = Reflect.getProperty(FlxG.save.data, persistent);
			if (savedData != null)
				Reflect.setProperty(ClientPrefs, persistent, savedData);
		}
		for (persistent => func in persistentFunctions)
		{
			var savedData = Reflect.getProperty(FlxG.save.data, persistent);
			if (savedData != null && func(savedData))
				Reflect.setProperty(ClientPrefs, persistent, savedData);
		}
		for (persistent in persistentMapData)
		{
			var savedMap:Map<String, Dynamic> = Reflect.getProperty(FlxG.save.data, persistent);
			if (savedMap != null)
			{
				var reflectMap:Map<String, Dynamic> = Reflect.getProperty(ClientPrefs, persistent);
				for (name => value in savedMap)
					reflectMap.set(name, value);
			}
		}
		// flixel automatically saves your volume!
		for (persistent => key in flixelPersistentData)
		{
			var savedData = Reflect.getProperty(FlxG.save.data, persistent);
			if (savedData != null)
				Reflect.setProperty(FlxG.sound, key, savedData);
		}

		var save:FlxSave = new FlxSave();
		save.bind('top10controls', 'top10birthdays');
		if (save != null && save.data.customControls != null)
		{
			var loadedControls:Map<String, Array<FlxKey>> = save.data.customControls;
			for (control => keys in loadedControls)
				keyBinds.set(control, keys);
			reloadControls();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic
	{
		return gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue;
	}

	public static function reloadControls()
	{
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);
		TitleState.muteKeys = copyKey(keyBinds.get('volume_mute'));

		TitleState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		TitleState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));

		FlxG.sound.muteKeys = TitleState.muteKeys;

		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}
}