package;

import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.app.Application;
import openfl.Assets;

using StringTools;
import Discord.DiscordClient;

typedef TitleData =
{
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	backgroundSprite:String,
	bpm:Int
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;
	private static var titleJSON:TitleData;

	private var sickBeats:Int = -1; // Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;

	var canYouFuckingWait:Bool = false;
	var skippedIntro:Bool = false;

	var dumbassLogo:FlxSprite;

	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;

	var logoScale:Float = .8;

	var camTransition:FlxCamera;
	var camOther:FlxCamera;
	var camGame:FlxCamera;

	var titleText:FlxSprite;
	var logoBl:FlxSprite;

	var transitioning:Bool = false;
	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		var path = Paths.getPreloadPath("images/titleJSON.json");
		titleJSON = Json.parse(Assets.getText(path));

		camTransition = new FlxCamera();
		camOther = new FlxCamera();
		camGame = new FlxCamera();

		camTransition.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);

		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camTransition, false);

		CustomFadeTransition.nextCamera = camTransition;

		FlxG.game.focusLostFramerate = 30;
		FlxG.sound.muteKeys = muteKeys;

		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;

		FlxG.keys.preventDefaultKeys = [ TAB ];
		PlayerSettings.init();

		super.create();

		FlxG.save.bind('top10', 'top10birthdays');
		ClientPrefs.loadPrefs();

		var data:Dynamic = FlxG.save.data;
		if (data != null && !initialized && data.fullscreen) FlxG.fullscreen = data.fullscreen;

		FlxG.mouse.visible = false;
		if (FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;

			MusicBeatState.switchState(new FlashingState());
		}
		else
		{
			if (!DiscordClient.isInitialized)
			{
				DiscordClient.initialize();
				Application.current.onExit.add(function(exitCode)
				{
					DiscordClient.shutdown();
				});
			}

			canYouFuckingWait = true;
			new FlxTimer().start(1, function(tmr:FlxTimer) { startIntro(); });
		}
	}

	public static function playTitleMusic(volume:Float = 1)
	{
		FlxG.sound.playMusic(Paths.music('freakyMenu'), volume);
		if (titleJSON != null)
			Conductor.changeBPM(titleJSON.bpm);
	}

	function startIntro()
	{
		persistentUpdate = true;
		var bg:FlxSprite = new FlxSprite();

		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none") { bg.loadGraphic(Paths.image(titleJSON.backgroundSprite)); }
		else { bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK); }

		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.screenCenter();

		add(bg);

		logoBl = new FlxSprite();
		logoBl.frames = Paths.getSparrowAtlas('Start_Screen_Assets');

		logoBl.antialiasing = ClientPrefs.globalAntialiasing;

		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');

		logoBl.setGraphicSize(Std.int(logoBl.width * logoScale));

		logoBl.updateHitbox();
		logoBl.screenCenter();

		logoBl.x += titleJSON.titlex;
		logoBl.y += titleJSON.titley;

		titleText = new FlxSprite().loadGraphic(Paths.image('enter'));
		titleText.antialiasing = ClientPrefs.globalAntialiasing;

		titleText.setGraphicSize(Std.int(titleText.width * .8));

		titleText.updateHitbox();
		titleText.screenCenter();

		titleText.x += titleJSON.startx;
		titleText.y += titleJSON.starty;

		dumbassLogo = new FlxSprite().loadGraphic(Paths.image('gobbledegook'));

		dumbassLogo.setGraphicSize(Std.int(dumbassLogo.width * 1.2));
		dumbassLogo.updateHitbox();

		dumbassLogo.screenCenter(X);
		dumbassLogo.y = FlxG.height - dumbassLogo.height - 40;

		dumbassLogo.visible = false;

		credGroup = new FlxGroup();
		textGroup = new FlxGroup();

		add(logoBl);
		add(titleText);
		add(credGroup);

		credGroup.add(bg);
		credGroup.add(dumbassLogo);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();

		credTextShit.visible = false;
		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 3, {ease: FlxEase.quadInOut, type: PINGPONG});

		switch (initialized)
		{
			case true: skipIntro();
			default:
			{
				initialized = true;
				playTitleMusic(0);

				FlxG.sound.music.fadeIn(4, 0, .7);
				FlxG.sound.music.play(true);

				Conductor.songPosition = 0;
				beatHit();
			}
		}
		canYouFuckingWait = false;
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time + elapsed;
		// sometimes it jsut dont go....
		FlxG.mouse.visible = false;
		super.update(elapsed);

		if (canYouFuckingWait) return;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;
		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
				pressedEnter = true;
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		if (gamepad != null)
		{
			if (gamepad.justPressed.START #if switch || gamepad.justPressed.B #end)
				pressedEnter = true;
		}
		if (!transitioning && skippedIntro)
		{
			if (FlxG.keys.justPressed.F) FlxG.fullscreen = !FlxG.fullscreen;
			if (pressedEnter)
			{
				transitioning = true;
				switch (ClientPrefs.flashing)
				{
					case true:
					{
						FlxG.camera.flash(FlxColor.WHITE, 1, null, true);
						FlxFlicker.flicker(titleText);
					}
					default:
					{
						FlxG.camera.fade(FlxColor.BLACK, 1, false, null, true);
						FlxTween.tween(titleText, {alpha: 0}, 1);
					}
				}
				FlxG.sound.play(Paths.sound('confirmMenu'), .7);
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}
		}

		if (initialized && pressedEnter && !skippedIntro)
			skipIntro();
		if (ClientPrefs.camZooms)
		{
			var lerpSpeed:Float = CoolUtil.boundTo(1 - (elapsed * Math.PI), 0, 1);
			FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.initialZoom, FlxG.camera.zoom, lerpSpeed);
		}
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var text:String = textArray[i];
			var money:Alphabet = new Alphabet(0, 0, text, true, false);

			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;

			if (credGroup != null && textGroup != null)
			{
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if (textGroup != null && credGroup != null)
		{
			var coolText:Alphabet = new Alphabet(0, 0, text, true, false);

			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;

			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function canZoomCamera():Bool
	{
		return skippedIntro && ClientPrefs.camZooms;
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			var member = textGroup.members[0];
			if (member != null)
			{
				credGroup.remove(member, true);
				textGroup.remove(member, true);

				member.destroy();
			}
			else
			{
				break;
			}
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if (logoBl != null) logoBl.animation.play('bump', true);

		if (canZoomCamera()) FlxG.camera.zoom += .045;
		if (!closedState)
		{
			// sickBeats++;
			for (i in sickBeats...curBeat)
			{
				trace(i + 1);
				switch (i + 1)
				{
					case 0:
						createCoolText(['Pandemonium', 'the j', 'and CRASH'], -40);
					case 2:
						addMoreText('present', -40);

					case 3:
						deleteCoolText();

					case 4:
						createCoolText(['A mod for'], -40);
					case 7:
					{
						if (dumbassLogo != null) dumbassLogo.visible = true;
						addMoreText('Top 10 Awesome', -40);
					}

					case 8:
					{
						if (dumbassLogo != null)
						{
							dumbassLogo.visible = false;
							dumbassLogo.kill();

							credGroup.remove(dumbassLogo);

							dumbassLogo.destroy();
							dumbassLogo = null;
						}
						deleteCoolText();
					}

					case 9:
						createCoolText(['Happy birthday']);
					case 11:
						addMoreText('Top 10 Awesome!');

					case 12:
						deleteCoolText();

					case 13:
						createCoolText(['Top']);
					case 14:
						addMoreText('10');
					case 15:
						addMoreText('Birthdays');

					case 16:
						skipIntro();
				}
			}
			sickBeats = curBeat;
		}
	}
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(credGroup);

			camGame.flash(FlxColor.WHITE, 4);
			skippedIntro = true;
		}
	}
}