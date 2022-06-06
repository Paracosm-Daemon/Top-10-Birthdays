package;

import openfl.media.Sound;
import flixel.system.FlxAssets.FlxShader;
import vlc.VlcBitmap;
import haxe.io.Bytes;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import Controls.Control;
import Note.EventNote;
import Section.SwagSection;
import Song.SwagSong;
import StageData;
import Conductor.Rating;
import editors.CharacterEditorState;
import editors.ChartingState;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.animation.FlxAnimation;
import flixel.graphics.FlxGraphic;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.events.KeyboardEvent;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

import Discord.DiscordClient;
#if sys
import sys.FileSystem;
#end

class PlayState extends MusicBeatState
{
	public static var SONG_NAME:String = 'Bash';

	public static var STRUM_X:Float = 42;
	public static var STRUM_X_MIDDLESCROLL:Float = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['Shit', .4],
		['Bad', .5],
		['OK', .7],
		['Good', .8],
		['Great', .9],
		['Sick!', 1],
		['Perfect!', 1]
	];
	public static var introAlts:Array<String> = ['ready', 'set', 'go'];
	// lol
	// event variables
	public var modchartTweens:Array<FlxTween> = new Array<FlxTween>();
	public var modchartTimers:Array<FlxTimer> = new Array<FlxTimer>();

	private var isCameraOnForcedPos:Bool = false;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = Note.noteWidth * 2;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var SONG:SwagSong = null;

	public var spawnTime:Float = 3000;
	public var vocals:FlxSound;

	public var lastDad:Character = null;
	public var dad:Character = null;

	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	// Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;

	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;

	public var stageGroup:FlxTypedGroup<BGSprite>;
	public var foregroundGroup:FlxSpriteGroup;

	public var windowGroup:FlxSpriteGroup;
	public var doorGroup:FlxSpriteGroup;

	public var presentOverlayGroup:FlxSpriteGroup;
	public var presentGroup:FlxSpriteGroup;

	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;

	private var curSong:String = "";

	public var gfSpeed:Int = 1;

	public var health:Float = 1;
	public var maxHealth:Float = 2;

	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;

	public var healthBar:FlxBar;

	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;

	public var timeBar:FlxBar;

	public var ratingsData:Array<Rating> = [];

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;

	public var endingSong:Bool = false;
	public var startingSong:Bool = false;

	private var updateTime:Bool = true;
	public static var chartingMode:Bool = false;

	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;

	// public var practiceMode:Bool = false;
	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var camZoomTypeBeatOffset:Int = 0;
	public var camZoomType:Int = 0;
	public var camZoomTypes:Array<Array<Dynamic>>;

	var cameraOffset:Float = 25;

	var opponentDelta:FlxPoint;
	var playerDelta:FlxPoint;

	private var losingPercent:Float = 20;
	private var vocalResyncTime:Int = 20;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;

	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;

	public var isDead:Bool = false;

	var gameZoomAdd:Float = 0;
	var hudZoomAdd:Float = 0;

	var gameZoom:Float = 1;
	var hudZoom:Float = 1;

	var gameShakeAmount:Float = 0;
	var hudShakeAmount:Float = 0;

	var songLength:Float = 0;
	var startDelay:Float = 0;

	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	public var paused:Bool = false;
	public var canReset:Bool = true;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;

	var detailsText:String = "";
	var detailsPausedText:String = "";

	public static var instance:PlayState;
	public static var focused:Bool = true;

	public var stageData:StageFile;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	public var evilAwesome:Character;
	public var spiderman:Character;
	public var thanos:Character;
	public var mBest:Character;
	public var santa:Character;
	public var nft:Character;

	var present_outside:BGSprite;
	var present_inside:BGSprite;
	var present_cover:BGSprite;

	var window_closed:BGSprite;
	var window_open:BGSprite;

	var window_crash:BGSprite;

	var totalChars:FlxSpriteGroup;
	var cake:BGSprite;

	var flipRatingOffset:Bool = false;
	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	override public function create()
	{
		Paths.clearStoredMemory();
		instance = this;

		opponentDelta = new FlxPoint();
		playerDelta = new FlxPoint();

		camZoomType = 0;
		// [ On Beat (bool), Function ]
		camZoomTypes = [
			[
				true,
				function()
				{
					if ((curBeat + camZoomTypeBeatOffset) % 4 == 0)
					{
						gameZoomAdd += .015;
						hudZoomAdd += .03;
					}
				}
			],
			[
				true,
				function()
				{
					if ((curBeat + camZoomTypeBeatOffset) % 2 == 0)
					{
						gameZoomAdd += .015;
						hudZoomAdd += .03;
					}
				}
			],
			[
				true,
				function()
				{
					gameZoomAdd += .015;
					hudZoomAdd += .03;
				}
			]
		];

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];
		//Ratings
		var rating:Rating = new Rating('sick');
		rating.hitWindow = ClientPrefs.sickWindow;

		rating.counter = 'sicks';
		ratingsData.push(rating); //default rating

		var rating:Rating = new Rating('good');
		rating.hitWindow = ClientPrefs.goodWindow;

		rating.noteSplash = false;
		rating.counter = 'goods';

		rating.ratingMod = .7;
		rating.score = 200;

		ratingsData.push(rating);
		var rating:Rating = new Rating('bad');
		rating.hitWindow = ClientPrefs.badWindow;

		rating.noteSplash = false;
		rating.counter = 'bads';

		rating.ratingMod = .4;
		rating.score = 100;

		ratingsData.push(rating);
		var rating:Rating = new Rating('shit');

		rating.counter = 'shits';
		rating.noteSplash = false;

		rating.ratingMod = 0;
		rating.score = 50;

		ratingsData.push(rating);
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		// practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();

		camHUD = new FlxCamera();
		camOther = new FlxCamera();

		camOther.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>(12);

		// FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		// FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
		{
			var formatted:String = Paths.formatToSongPath(SONG_NAME);
			SONG = Song.loadFromJson(formatted, formatted); // lolzoolzolzlzolzozololzolzolz
		}

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		detailsText = "Birthday";
		// String for when the game is paused
		detailsPausedText = 'Paused - $detailsText';

		curSong = Paths.formatToSongPath(SONG.song);
		curStage = StageData.getStage(SONG);

		stageData = StageData.getStageFile(curStage);
		startDelay = Conductor.crochet / 1000;

		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: .9,

				boyfriend: [770, 100],
				opponent: [100, 100],

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],

				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		gameZoom = defaultCamZoom;

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];

		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		opponentCameraOffset = stageData.camera_opponent;

		if (boyfriendCameraOffset == null)
			boyfriendCameraOffset = [0, 0]; // Fucks sake should have done it since the start :rolling_eyes:
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);

		stageGroup = new FlxTypedGroup<BGSprite>();

		foregroundGroup = new FlxSpriteGroup();
		totalChars = new FlxSpriteGroup();

		switch (curStage)
		{
			case 'stage': // Tutorial
			{
				var bg:BGSprite = new BGSprite('stageback', -600, -200);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600);

				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();

				add(stageFront);
				if (!ClientPrefs.lowQuality)
				{
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, .9, .9);

					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();

					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, .9, .9);

					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();

					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);

					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * .9));
					stageCurtains.updateHitbox();

					add(stageCurtains);
				}
			}
			case 'birthday':
			{
				var bg:BGSprite = new BGSprite('background', -200, -300, .5, .5);

				var house:BGSprite = new BGSprite('house');
				var hallway:BGSprite = new BGSprite('hallway');

				var door_inside:BGSprite = new BGSprite('door/inside');
				var door_outside:BGSprite = new BGSprite('door/outside');

				var table:BGSprite = new BGSprite('table');

				present_outside = new BGSprite('present/outside');
				present_inside = new BGSprite('present/inside');
				present_cover = new BGSprite('present/cover');

				windowGroup = new FlxSpriteGroup();
				doorGroup = new FlxSpriteGroup();

				window_crash = new BGSprite('window/crash', 500, 420, 1, 1, true, ['Symbol 1']);

				window_closed = new BGSprite('window/closed');
				window_open = new BGSprite('window/open');
				// temp hide
				window_crash.visible = false;
				window_open.visible = false;

				presentOverlayGroup = new FlxSpriteGroup();
				presentGroup = new FlxSpriteGroup();

				cake = new BGSprite('cake');
				add(bg);

				add(house);
				add(hallway);

				add(windowGroup);

				windowGroup.add(window_closed);
				windowGroup.add(window_crash);
				windowGroup.add(window_open);

				doorGroup.add(door_inside);
				foregroundGroup.add(door_outside);

				foregroundGroup.add(table);
				foregroundGroup.add(cake);

				presentGroup.add(present_inside);

				presentOverlayGroup.add(present_outside);
				presentOverlayGroup.add(present_cover);
			}
		}

		add(dadGroup);
		add(boyfriendGroup);

		if (doorGroup != null) add(doorGroup);
		add(foregroundGroup);

		if (presentGroup != null) add(presentGroup);
		if (presentOverlayGroup != null) add(presentOverlayGroup);

		boyfriend = new Character(0, 0, SONG.player1, true);

		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if (ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;

		strumLine.scrollFactor.set();
		var showTime:Bool = ClientPrefs.timeBarType != 'Disabled';

		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		timeTxt.antialiasing = ClientPrefs.globalAntialiasing;

		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;

		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;

		if (ClientPrefs.downScroll)
			timeTxt.y = FlxG.height - 44;
		if (ClientPrefs.timeBarType == 'Song Name')
			timeTxt.text = SONG.song;

		updateTime = showTime;
		timeBarBG = new AttachedSprite('timeBar');

		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);

		timeBarBG.antialiasing = ClientPrefs.globalAntialiasing;

		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;

		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;

		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;

		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();

		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 400; // How much lag this causes?? Should i tone it down to idk, 400 or 200?

		timeBar.alpha = 0;
		timeBar.visible = showTime;

		timeBar.antialiasing = ClientPrefs.globalAntialiasing;

		add(timeBar);
		add(timeTxt);

		timeBarBG.sprTracker = timeBar;
		strumLineNotes = new FlxTypedGroup<StrumNote>();

		add(strumLineNotes);
		add(grpNoteSplashes);

		if (ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);

		grpNoteSplashes.add(splash);
		splash.alpha = 0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

		noteTypeMap.clear();
		noteTypeMap = null;

		eventPushedMap.clear();
		eventPushedMap = null;

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		var camPos:FlxPoint = new FlxPoint();
		camPos.set(boyfriendCameraOffset[0]
			+ boyfriend.getMidpoint().x
			- 100
			+ boyfriend.cameraPosition[0],
			boyfriendCameraOffset[1]
			+ boyfriend.getMidpoint().y
			- 100
			+ boyfriend.cameraPosition[1]);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		camGame.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		camGame.focusOn(camFollow);
		camGame.zoom = gameZoom + gameZoomAdd;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.fixedTimestep = false;

		isCameraOnForcedPos = true;
		moveCameraSection();

		healthBarBG = new AttachedSprite('healthBar');

		healthBarBG.y = FlxG.height * .89;
		healthBarBG.screenCenter(X);

		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;

		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;

		add(healthBarBG);
		if (ClientPrefs.downScroll) healthBarBG.y = .11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this, 'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;

		add(healthBar);

		healthBarBG.sprTracker = healthBar;
		iconP1 = new HealthIcon(boyfriend.healthIcon, true);

		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;

		add(iconP1);
		iconP2 = new HealthIcon(dad != null ? dad.healthIcon : boyfriend.healthIcon, false);

		iconP1.y = healthBar.y - 75;
		iconP2.y = iconP1.y;

		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;

		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "");

		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.borderSize = 1.25;

		scoreTxt.scrollFactor.set();

		scoreTxt.visible = !ClientPrefs.hideHud;
		scoreTxt.antialiasing = ClientPrefs.globalAntialiasing;

		add(scoreTxt);
		botplayTxt = new FlxText(0, timeBarBG.y + 30, FlxG.width - 800, "BOTPLAY", 32);

		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();

		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;

		botplayTxt.antialiasing = ClientPrefs.globalAntialiasing;

		botplayTxt.updateHitbox();
		botplayTxt.screenCenter(X);

		add(botplayTxt);
		if (ClientPrefs.downScroll)
			botplayTxt.y = timeBarBG.y - 118;

		grpNoteSplashes.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		notes.cameras = [camHUD];

		GameOverSubstate.resetVariables();

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = .7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
		switch (seenCutscene)
		{
			case true:
			{
				// play some video please!! then remove the line beloooww!!!
				startCountdown();
			}
			default: startCountdown();
		}

		seenCutscene = true;
		RecalculateRating();
		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		CoolUtil.precacheSong(curSong);
		Hitsound.play(true);

		CoolUtil.precacheMusic(PauseSubState.songName);
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, getFormattedSong(), iconP2.getCharacter());

		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.create();

		Paths.clearUnusedMemory();
		CustomFadeTransition.nextCamera = camOther;
	}

	public function getFormattedSong(?getRating:Bool = true)
	{
		var start = SONG.song;
		if (getRating)
		{
			var floored:String = ratingName == '?' ? '?' : '$ratingName (${Highscore.floorDecimal(ratingPercent * 100, 2)}%)';
			start += '\nScore: $songScore | Misses: $songMisses | Rating: $floored';
		}
		return start;
	}

	private function quickUpdatePresence(?startString:String = "", ?hasLength:Bool = true)
	{
		if (health > 0 && !paused && DiscordClient.isInitialized)
			DiscordClient.changePresence(detailsText, '$startString${getFormattedSong()}', iconP2.getCharacter(), hasLength && Conductor.songPosition > 0,
				songLength - Conductor.songPosition - ClientPrefs.noteOffset);
	}

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh

			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}

		songSpeed = value;
		noteKillOffset = (Note.noteWidth * 2) / songSpeed;

		return value;
	}

	function cancelCameraDelta(char:Null<Character>)
	{
		if (char != null && !char.animation.name.startsWith('sing'))
		{
			var deltaCancel:FlxPoint = switch (char.isPlayer)
			{
				default: opponentDelta;
				case true: playerDelta;
			};
			deltaCancel.set();
		}
	}

	function getCameraDelta(leData:Int):FlxPoint
	{
		return new FlxPoint(switch (leData)
		{
			case 0: -1;
			case 3: 1;

			default: 0;
		}, switch (leData)
			{
				case 2: -1;
				case 1: 1;

				default: 0;
			});
	}

	public function reloadHealthBarColors()
	{
		var p1Colors:Array<Int> = boyfriend.healthColorArray;
		var p2Colors:Array<Int> = (dad != null ? dad : boyfriend).healthColorArray;

		healthBar.createFilledBar(FlxColor.fromRGB(p2Colors[0], p2Colors[1], p2Colors[2]), FlxColor.fromRGB(p1Colors[0], p1Colors[1], p1Colors[2]));
		healthBar.updateBar();
	}

	function startCharacterPos(char:Character)
	{
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String, skipTransIn:Bool = false):Void
	{
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = '';
		#if sys
		if (FileSystem.exists(fileName)) foundFile = true;
		#end
		if (!foundFile)
		{
			fileName = Paths.video(name);
			if (#if sys FileSystem #else OpenFlAssets #end.exists(fileName)) foundFile = true;
		}
		if (foundFile)
		{
			inCutscene = true;
			var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

			bg.scrollFactor.set();
			bg.cameras = [camOther];

			add(bg);
			new FlxVideo(fileName).finishCallback = function()
			{
				remove(bg);
				bg.destroy();
				startAndEnd(skipTransIn);
			};
			return;
		}
		else
		{
			FlxG.log.warn('Couldn\'t find video file: $fileName');
			// startAndEnd(skipTransIn);
		}
		#end
		startAndEnd(skipTransIn);
	}

	function startAndEnd(skipTransIn:Bool = false)
	{
		switch (endingSong)
		{
			case true:
				cleanupEndSong(skipTransIn);
			default:
				startCountdown();
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer;

	public var countdownImage:FlxSprite;
	public static var startOnTime:Float = 0;

	private function charDance(char:Character, beat:Int)
	{
		var curAnim:FlxAnimation = char.animation.curAnim;
		if (curAnim != null && (beat % char.danceEveryNumBeats) == 0)
		{
			if (!char.stunned && (curAnim.finished || !curAnim.name.startsWith("sing"))) char.dance();
		}
	}

	private function stageDance(beat:Int) { if (beat % gfSpeed == 0) { for (sprite in stageGroup.members) { if (Std.isOfType(sprite, BGSprite)) cast(sprite, BGSprite).dance(true); } } }
	private function groupDance(chars:FlxSpriteGroup, beat:Int) { for (char in chars.members) { if (Std.isOfType(char, Character)) charDance(cast(char, Character), beat); } }

	private function bfDance()
	{
		var curAnim:FlxAnimation = boyfriend.animation.curAnim;
		if (curAnim != null)
		{
			var animName = curAnim.name;
			if (boyfriend.holdTimer > ((Conductor.stepCrochet / 1000) * boyfriend.singDuration)
				&& (animName.startsWith("sing") && !animName.endsWith("miss")))
				boyfriend.dance();
		}
	}

	public function startCountdown():Void
	{
		inCutscene = false;
		isCameraOnForcedPos = false;

		skipCountdown = false;
		if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		startedCountdown = true;
		var lastTween:FlxTween = null;

		Conductor.songPosition = -startDelay * 5000;
		if (startOnTime > 0)
		{
			if (FlxG.sound.music != null) { FlxG.sound.music.volume = 0; }

			clearNotesBefore(startOnTime);
			setSongTime(startOnTime - 350);

			return;
		}
		else if (skipCountdown)
		{
			setSongTime(0);
			return;
		}
		countdownImage = new FlxSprite();

		countdownImage.antialiasing = ClientPrefs.globalAntialiasing;
		countdownImage.scrollFactor.set();

		countdownImage.alpha = 0;
		add(countdownImage);
		// So it doesn't lag
		for (alt in introAlts) Paths.image(alt);
		for (i in 1...4) { CoolUtil.precacheSound('intro$i'); }

		CoolUtil.precacheSound('introGo');
		startTimer = new FlxTimer().start(startDelay, function(tmr:FlxTimer)
		{
			if (ClientPrefs.opponentStrums)
			{
				notes.forEachAlive(function(note:Note)
				{
					note.copyAlpha = false;
					note.alpha = note.multAlpha;

					if (ClientPrefs.middleScroll && !note.mustPress)
						note.alpha *= .5;
				});
			}

			var loopsLeft:Int = tmr.loopsLeft;
			var beat:Int = loopsLeft + 1;

			var count = tmr.elapsedLoops - 2;

			groupDance(boyfriendGroup, beat);
			// groupDance(dadGroup, beat);
			groupDance(totalChars, beat);

			stageDance(beat);
			iconBop(beat);

			if ((count >= 0 && count < introAlts.length) && countdownImage != null)
			{
				countdownImage.loadGraphic(Paths.image(introAlts[count]));
				// FUCK HAXEFLIXEL
				if (lastTween != null && !lastTween.finished)
				{
					lastTween.cancel();
					cleanupTween(lastTween);
					lastTween = null;
				}

				countdownImage.updateHitbox();
				countdownImage.screenCenter();

				countdownImage.alpha = 1;
				var tween:FlxTween = FlxTween.tween(countdownImage, { alpha: 0 }, Conductor.crochet / 1000, {
					ease: FlxEase.quartInOut,
					onComplete: function(twn:FlxTween)
					{
						if (loopsLeft <= 0)
						{
							countdownImage.alpha = 0;
							remove(countdownImage);
							countdownImage.destroy();
						}
						lastTween = null;
						cleanupTween(twn);
					}
				});

				modchartTweens.push(tween);
				lastTween = tween;
			}
			FlxG.sound.play(Paths.sound('intro${loopsLeft <= 0 ? 'Go' : Std.string(loopsLeft)}'), .6);
		}, 4);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if (time >= 0 && time < FlxG.sound.music.length)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = time;

			FlxG.sound.music.play();
		}
		if (time >= 0 && time < vocals.length)
		{
			vocals.pause();

			vocals.time = time;
			vocals.play();
		}

		Conductor.songPosition = time;
		songTime = time;
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(SONG.song), 0, false);
		FlxG.sound.music.onComplete = onSongComplete;

		vocals.volume = 0;
		var curTime:Float = FlxG.sound.music.time;

		FlxG.sound.music.play(true, curTime);
		vocals.play(true, curTime);

		Conductor.songPosition = curTime;

		resyncVocals(true);
		Conductor.songPosition = FlxG.sound.music.time;

		FlxG.sound.music.volume = 1;
		vocals.volume = 1;

		if (startOnTime > 0)
			setSongTime(startOnTime - 500);
		startOnTime = 0;

		if (paused)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}

		camZooming = true;//curSong != 'tutorial';
		super.update(FlxG.elapsed);

		stepHit();
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, .5, {ease: FlxEase.circOut, onComplete: cleanupTween});
		FlxTween.tween(timeTxt, {alpha: 1}, .5, {ease: FlxEase.circOut, onComplete: cleanupTween});
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, getFormattedSong(), iconP2.getCharacter(), true, songLength);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');

		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		Conductor.changeBPM(SONG.bpm);
		vocals = new FlxSound();

		if (SONG.needsVoices) vocals.loadEmbedded(Paths.voices(dataPath));

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(dataPath)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection> = SONG.notes;
		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var file:String = Paths.json('$curSong/events');
		#if sys
		if (FileSystem.exists(file))
		{
		#else
		if (OpenFlAssets.exists(file))
		{
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', curSong).events;
			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;
				var noteType:String = songNotes[3];

				if (songNotes[1] > 3) gottaHitNote = !section.mustHitSection;

				var oldNote:Note = unspawnNotes.length > 0 ? unspawnNotes[Std.int(unspawnNotes.length - 1)] : null;
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false);

				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];

				swagNote.noteType = noteType;
				if (!Std.isOfType(songNotes[3], String))
					swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				if (susLength > 0)
				{
					var floorSus:Int = Math.round(susLength);
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime
							+ (Conductor.stepCrochet * susNote)
							+ (Conductor.stepCrochet / songSpeed), daNoteData, oldNote,
						true, false);

						sustainNote.mustPress = gottaHitNote;

						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();

						unspawnNotes.push(sustainNote);
						if (sustainNote.mustPress) { sustainNote.x += FlxG.width / 2; } // general offset
						else
						{
							if (ClientPrefs.middleScroll)
							{
								sustainNote.x += 310;
								if (daNoteData > 1) sustainNote.x += FlxG.width / 2 + 25; // Up and Right
							}
						}
					}
				}
				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2;
				} // general offset
				else
				{
					if (ClientPrefs.middleScroll)
					{
						swagNote.x += 310;
						if (daNoteData > 1) swagNote.x += FlxG.width / 2 + 25; // Up and Right
					}
				}
				if (!noteTypeMap.exists(swagNote.noteType)) noteTypeMap.set(swagNote.noteType, true);
			}
			daBeats += 1;
		}
		for (event in SONG.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};

				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);

				eventPushed(subEvent);
			}
		}
		// trace(unspawnNotes.length);
		// playerCounter += 1;
		unspawnNotes.sort(sortByShit);
		if (eventNotes.length > 1)
			eventNotes.sort(sortByTime); // No need to sort if there's a single one or none at all
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote)
	{
		switch (event.event)
		{
			case 'Change Character':
				{
					var newCharacter:String = event.value1.trim();
					var path:String = Paths.getPreloadPath('characters/$newCharacter.json');

					if (Assets.exists(path))
					{
						var json:Dynamic = Json.parse(Assets.getText(path));
						var asset:FlxGraphic = Paths.image(json.image); // Cache

						trace(asset);
					}
				}
		}

		if (!eventPushedMap.exists(event.event))
			eventPushedMap.set(event.event, true);
	}

	function eventNoteEarlyTrigger(event:EventNote):Float
	{
		switch (event.event)
		{
			// case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
			//	return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false;
	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = (player < 1 && !ClientPrefs.opponentStrums) ? 0 : ((ClientPrefs.middleScroll && player < 1) ? .35 : 1);
			var babyArrow:StrumNote = new StrumNote(STRUM_X_MIDDLESCROLL, strumLine.y, i, (player * 2) - 1);// new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);

			babyArrow.downScroll = ClientPrefs.downScroll;

			babyArrow.y -= 10;
			babyArrow.alpha = 0;

			modchartTweens.push(FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1,
				{ease: FlxEase.circOut, startDelay: .5 + (.2 * i), onComplete: cleanupTween}));

			switch (player)
			{
				case 1:
					playerStrums.add(babyArrow);
				default:
					{
						if (ClientPrefs.middleScroll)
						{
							babyArrow.x += 310;
							if (i > 1)
								babyArrow.x += FlxG.width / 2 + 25; // Up and Right
						}
						opponentStrums.add(babyArrow);
					}
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;

			if (songSpeedTween != null)
				songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, dad, nft, spiderman, thanos, santa, evilAwesome, mBest];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
					char.colorTween.active = false;
			}

			for (tween in modchartTweens)
				tween.active = false;
			for (timer in modchartTimers)
				timer.active = false;
		}
		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals(true);

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;

			if (songSpeedTween != null)
				songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, dad, nft, spiderman, thanos, santa, evilAwesome, mBest];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
					char.colorTween.active = true;
			}

			for (tween in modchartTweens)
				tween.active = true;
			for (timer in modchartTimers)
				timer.active = true;

			paused = false;
			DiscordClient.changePresence(detailsText, getFormattedSong(), iconP2.getCharacter(), startTimer == null ? true : startTimer.finished,
				songLength - Conductor.songPosition - ClientPrefs.noteOffset);
		}
		super.closeSubState();
	}

	override public function onFocus():Void
	{
		if (health > 0 && !paused)
			quickUpdatePresence();

		focused = true;
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		if (health > 0 && !paused)
			quickUpdatePresence("PAUSED - ", false);

		focused = false;
		super.onFocusLost();
	}

	function resyncVocals(?forceMusic:Bool = false):Void
	{
		if (finishTimer != null)
			return;

		var curTime:Float = FlxG.sound.music.time;
		var curVocals:Float = vocals.time;

		if ((forceMusic || curVocals > curTime + vocalResyncTime || curVocals < curTime - vocalResyncTime) && curTime < vocals.length && curTime < FlxG.sound.music.length)
		{
			// im like 90% sure this yields so i'm force restarting it and caching the current music time, then restarting it
			FlxG.sound.music.play(true);
			vocals.play(true);

			FlxG.sound.music.time = curTime;
			vocals.time = curTime;
		}
		Conductor.songPosition = curTime;
	}

	function getFrame(percent:Float) : Int
	{
		return CoolUtil.boolToInt(percent <= losingPercent);
	}
	override public function update(elapsed:Float)
	{
		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
	}*/

		if (!inCutscene)
		{
			var curBar:Int = Std.int(curStep / 16);
			var curNote:SwagSection = SONG.notes[curBar];

			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			if (generatedMusic && curNote != null && !endingSong && !isCameraOnForcedPos)
				moveCameraSection(curBar);

			cancelCameraDelta(boyfriend);
			cancelCameraDelta(dad);

			var usePlayerDelta:Bool = curNote != null && curNote.mustHitSection;

			var point:FlxPoint = usePlayerDelta ? playerDelta : opponentDelta;
			var multiplier:Float = ClientPrefs.reducedMotion ? 0 : cameraOffset;

			var followX:Float = camFollow.x + (point.x * multiplier);
			var followY:Float = camFollow.y + (point.y * multiplier);

			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, followX, lerpVal), FlxMath.lerp(camFollowPos.y, followY, lerpVal));
		}

		var format:String = 'Score: $songScore | Misses: $songMisses | Rating: $ratingName';
		scoreTxt.text = (ratingName == '?') ? format : '$format (${Highscore.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC';

		if (botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}
		if (controls.PAUSE && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;

			paused = true;
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			DiscordClient.changePresence(detailsPausedText, getFormattedSong(), iconP2.getCharacter());
		}
		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			#if debug
			openChartEditor();
			#end
		}

		health = Math.min(health, maxHealth);

		iconP2.alpha = (dad != null ? dad.alpha : 0) * dadGroup.alpha;
		iconP1.alpha = boyfriend.alpha * boyfriendGroup.alpha;

		iconP2.visible = !ClientPrefs.hideHud && dadGroup.visible && dad != null && dad.visible && iconP2.alpha > 0;
		iconP1.visible = !ClientPrefs.hideHud && boyfriendGroup.visible && boyfriend.visible && iconP1.alpha > 0;

		var healthPercent:Float = healthBar.percent;
		var curHealth:Float = healthPercent;

		var visibleMult:Int = CoolUtil.boolToInt(iconP1.visible && iconP2.visible);
		var iconOffset:Float = 26 * visibleMult;

		iconP1.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(curHealth, 0, 100, 100, 0) / 100))
			+ (150 * visibleMult * iconP1.scale.x - 150) / 2
			- iconOffset;
		iconP2.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(curHealth, 0, 100, 100, 0) / 100))
			- (150 * visibleMult * iconP2.scale.x) / 2
			- iconOffset * 2;

		iconP2.setFrame(getFrame(100 - curHealth));
		iconP1.setFrame(getFrame(curHealth));

		#if debug
		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused = true;

			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}
		#end

		var elapsedMult:Float = elapsed * 1000;
		var elapsedTicks:Int = FlxG.game.ticks;

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += elapsedMult;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += elapsedMult;
			if (!paused)
			{
				songTime += elapsedTicks - previousFrameTime;
				previousFrameTime = elapsedTicks;
				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}
				if (updateTime)
				{
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;

					curTime = Math.max(curTime, 0);
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if (ClientPrefs.timeBarType == 'Time Elapsed')
						songCalc = curTime;

					var secondsTotal:Int = Math.floor(Math.max(songCalc / 1000, 0));
					if (ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}
		}

		var lerpSpeed:Float = CoolUtil.boundTo(1 - (elapsed * Math.PI), 0, 1);

		camGame.zoom = gameZoom + gameZoomAdd; // FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, lerpSpeed);
		camHUD.zoom = hudZoom + hudZoomAdd; // FlxMath.lerp(1, camHUD.zoom, lerpSpeed);

		if (camZooming)
		{
			gameZoom = FlxMath.lerp(defaultCamZoom, gameZoom, lerpSpeed);
			// commented out because i could maybe keep it constant
			// hudZoom = FlxMath.lerp(1, hudZoom, lerpSpeed);
			gameZoomAdd = FlxMath.lerp(0, gameZoomAdd, lerpSpeed);
			hudZoomAdd = FlxMath.lerp(0, hudZoomAdd, lerpSpeed);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = -1;
			trace("RESET = True");
		}
		doDeathCheck();
		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime; // shit be werid on 4:3

			if (songSpeed < 1)
				time /= songSpeed;
			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene)
			{
				if (!cpuControlled)
				{
					keyShit();
				}
				else
				{
					bfDance();
				}
			}

			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if (!daNote.mustPress)
					strumGroup = opponentStrums;

				var strumX:Float = strumGroup.members[daNote.noteData].x;
				var strumY:Float = strumGroup.members[daNote.noteData].y;

				var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
				var strumAngle:Float = strumGroup.members[daNote.noteData].angle;

				var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;
				var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;

				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				daNote.distance = .45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed * (strumScroll ? 1 /* Downscroll */ : -1 /* Upscroll */);
				var angleDir = strumDirection * Math.PI / 180;

				if (daNote.copyAngle) daNote.angle = strumDirection - 90 + strumAngle;
				if (daNote.copyAlpha) daNote.alpha = strumAlpha;

				if (daNote.copyX) daNote.x = strumX + Math.cos(angleDir) * daNote.distance;
				if (daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;
					// Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					if (strumScroll && daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith('end'))
						{
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;

							daNote.y -= 19;
						}

						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) opponentNoteHit(daNote);
				if (daNote.mustPress && cpuControlled)
				{
					if (daNote.isSustainNote) { if (daNote.canBeHit) goodNoteHit(daNote); }
					else { if (daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) goodNoteHit(daNote); }
				}

				var center:Float = strumY + Note.swagWidth / 2;
				if (strumGroup.members[daNote.noteData].sustainReduce
					&& daNote.isSustainNote
					&& (daNote.mustPress || !daNote.ignoreNote)
					&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);

							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);

							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}
				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.getSafeZone(daNote.earlyHitWindow) + daNote.strumTime)
				{
					if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) noteMiss(daNote);

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}
		checkEventNote();
		super.update(elapsed);
		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO)
			{ // Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;

		cancelMusicFadeTween();

		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		DiscordClient.changePresence("Chart Editor", null, null, true);
	}
	function doDeathCheck(?skipHealthCheck:Bool = false):Bool
	{
		if ((skipHealthCheck || health <= 0) && !isDead)
		{
			boyfriend.stunned = true;
			if (!chartingMode) deathCounter++;

			paused = true;
			vocals.stop();

			FlxG.sound.music.stop();

			persistentUpdate = false;
			persistentDraw = false;

			for (tween in modchartTweens)
				tween.active = true;
			for (timer in modchartTimers)
				timer.active = true;

			DiscordClient.changePresence('Game Over - $detailsText', getFormattedSong(false), iconP2.getCharacter());
			GameOverSubstate.characterName = boyfriend.curCharacter;

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));
			isDead = true;

			return true;
		}
		return false;
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
				break;

			var value1:String = '';
			if (eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if (eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String)
	{
		var pressed:Bool = Reflect.getProperty(controls, key);
		// trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String)
	{
		switch (eventName)
		{
			case 'Set GF Speed':
			{
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value))
					value = 1;
				gfSpeed = value;
			}
			case 'Add Camera Zoom':
			{
				if (canZoomCamera())
				{
					var camZoomAdding:Float = Std.parseFloat(value1);
					var hudZoomAdding:Float = Std.parseFloat(value2);

					if (Math.isNaN(camZoomAdding)) camZoomAdding = .015;
					if (Math.isNaN(hudZoomAdding)) hudZoomAdding = .03;

					gameZoomAdd += camZoomAdding;
					hudZoomAdd += hudZoomAdding;
				}
			}
			case 'Set Zoom Type':
			{
				var beats:Int = Std.parseInt(value2.trim());
				var type:Int = Std.parseInt(value1.trim());

				camZoomType = Math.isNaN(type) ? 0 : Std.int(CoolUtil.boundTo(type, 0, camZoomTypes.length - 1));
				camZoomTypeBeatOffset = Math.isNaN(beats) ? 0 : beats;
			}
			case 'Change Default Zoom':
			{
				var value:Float = Std.parseFloat(value1.trim());
				defaultCamZoom = stageData.defaultZoom + (Math.isNaN(value) ? 0 : value);
			}
			case 'Flash Camera':
			{
				var duration:Float = Std.parseFloat(value1.trim());
				var color:String = value2.trim();

				if (color.length > 1)
				{
					if (!color.startsWith('0x'))
						color = '0xFF$color';
				}
				else
				{
					color = "0xFFFFFFFF";
				}

				if (ClientPrefs.flashing)
					camOther.flash(Std.parseInt(color), Math.isNaN(duration) ? 1 : duration, null, true);
			}
			case 'Change Character Visibility':
			{
				var visibility:String = value2.toLowerCase();
				var char:Character = switch (value1.toLowerCase().trim())
				{
					case 'dad' | 'opponent': dad;
					default: boyfriend;
				};
				char.visible = visibility.length <= 1 || visibility.startsWith('true');
			}
			case 'Play Sound':
			{
				try
				{
					var sound:Dynamic = Reflect.getProperty(this, value1);
					if (sound != null && Std.isOfType(sound, FlxSound))
						sound.play(true);
				}
				catch (e:Dynamic)
				{
					trace('Unknown sound tried to be played - $e');
				}
			}
			case 'Play Animation':
			{
				// trace('Anim to play: ' + value1);
				var char:Character = switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend': boyfriend;
					default:
						{
							var val2:Int = Std.parseInt(value2);

							if (Math.isNaN(val2))
								val2 = 0;
							switch (val2)
							{
								case 1: boyfriend;
								default: dad;
							}
						}
				}

				char.playAnim(value1, true);
				char.specialAnim = true;
			}
			case 'Camera Follow Pos':
			{
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);

				if (Math.isNaN(val1))
					val1 = 0;
				if (Math.isNaN(val2))
					val2 = 0;

				isCameraOnForcedPos = false;
				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
				{
					camFollow.x = val1;
					camFollow.y = val2;

					isCameraOnForcedPos = true;
				}
			}
			case 'Alt Idle Animation':
			{
				var char:Character = switch (value1.toLowerCase())
				{
					case 'boyfriend' | 'bf': boyfriend;
					default:
						{
							var val:Int = Std.parseInt(value1);

							if (Math.isNaN(val))
								val = 0;
							switch (val)
							{
								case 1: boyfriend;
								default: dad;
							}
						}
				}

				char.idleSuffix = value2;
				char.recalculateDanceIdle();
			}
			case 'Sustain Shake':
			{
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);

				if (Math.isNaN(val1))
					val1 = 0;
				if (Math.isNaN(val2))
					val2 = 0;

				gameShakeAmount = val1;
				hudShakeAmount = val2;

				doSustainShake();
			}
			case 'Screen Shake':
			{
				if (!ClientPrefs.reducedMotion)
				{
					var valuesArray:Array<String> = [value1, value2];
					var targetsArray:Array<FlxCamera> = [camGame, camHUD];

					for (i in 0...targetsArray.length)
					{
						var split:Array<String> = valuesArray[i].split(',');

						var intensity:Float = 0;
						var duration:Float = 0;

						if (split[1] != null)
							intensity = Std.parseFloat(split[1].trim());
						if (split[0] != null)
							duration = Std.parseFloat(split[0].trim());

						if (Math.isNaN(intensity))
							intensity = 0;
						if (Math.isNaN(duration))
							duration = 0;

						if (duration > 0 && intensity != 0)
							targetsArray[i].shake(intensity, duration);
					}
				}
			}
			case 'Change Character':
			{
				// check if we're trying to append the character
				var trimmed:String = value1.trim().toLowerCase();
				var property:String = switch (trimmed)
				{
					case 'eviltop10': 'evilAwesome';
					case 'spiderman': 'spiderman';
					case 'thanos': 'thanos';
					case 'santa': 'santa';
					case 'mbest': 'mBest';
					case 'nft': 'nft';

					default: null;
				};

				var strumX:Float = STRUM_X_MIDDLESCROLL;
				var isMiddleScroll:Bool = true;

				var flipped:Bool = false;
				if (property == null)
				{
					dad = null;
					iconP2.changeIcon(boyfriend.healthIcon);

					reloadHealthBarColors();
				}
				else
				{
					strumX = STRUM_X;
					isMiddleScroll = false;

					var lowerProperty:String = property.toLowerCase();
					flipped = switch (lowerProperty)
					{
						case 'evilawesome' | 'thanos': true;
						default: false;
					}

					var thisChar:Character = Reflect.getProperty(this, property);
					if (thisChar == null)
					{
						lastDad = dad;
						thisChar = new Character(DAD_X, DAD_Y, value1, false);

						startCharacterPos(thisChar);

						Reflect.setProperty(this, property, thisChar);
						totalChars.add(thisChar);
						// do an intro
						switch (lowerProperty)
						{
							default: { dadGroup.add(thisChar); lastDad = null; } // so i can see the characters !!!!!
							case 'evilawesome':
							{
								trace('evil awesome intro!!!!');
								flipped = true;

								thisChar.x += 1075;
								thisChar.y += 300;

								thisChar.playAnim('crash', true);
								thisChar.specialAnim = true;

								thisChar.animation.callback = function(anim:String, frameNumber:Int, frameIndex:Int)
								{
									if (anim == 'crash' && frameIndex > 2)
									{
										trace('splatter');

										cake.visible = false;
										cake.kill();

										foregroundGroup.remove(cake);

										cake.destroy();
										cake = null;

										boyfriend.playAnim('clean', true);
										boyfriend.specialAnim = true;

										thisChar.animation.callback = null;
									}
								}

								lastDad = null;
								foregroundGroup.add(thisChar);
							}
							case 'spiderman':
							{
								trace('shatter the windows');

								var originalHeight:Float = thisChar.height;
								var originalWidth:Float = thisChar.width;

								thisChar.x -= 900;
								thisChar.y -= 500;

								thisChar.setGraphicSize(20, 1);
								modchartTweens.push(FlxTween.tween(thisChar, { y: thisChar.y + 600 }, Conductor.crochet / 1000, { ease: FlxEase.quartOut, onUpdate: function(twn:FlxTween) {
									thisChar.setGraphicSize(Std.int(FlxMath.lerp(20, originalWidth, twn.scale)), Std.int(FlxMath.lerp(1, originalHeight, twn.scale)));
								}, onComplete: function(twn:FlxTween) {
									lastDad = null;
									cleanupTween(twn);
								} }));

								window_closed.kill();
								window_crash.visible = true;

								windowGroup.remove(window_closed);

								window_closed.destroy();
								window_closed = null;

								window_crash.dance(true);
								window_crash.animation.finishCallback = function(name:String) {
									trace('finished');
									// open window
									window_open.visible = true;
									window_crash.kill();

									windowGroup.remove(window_crash);
									window_crash.animation.finishCallback = null;

									window_crash.destroy();
									window_crash = null;
								}
								doorGroup.add(thisChar);
							}
							case 'nft':
							{
								var originalHeight:Float = thisChar.height;
								var originalWidth:Float = thisChar.width;

								var originalY:Float = thisChar.y;

								thisChar.x -= 480;
								thisChar.setGraphicSize(1, 1);

								modchartTweens.push(FlxTween.tween(thisChar, { y: originalY - 200 }, Conductor.crochet / 1000, { ease: FlxEase.quartOut, onUpdate: function(twn:FlxTween) {
									thisChar.setGraphicSize(Std.int(FlxMath.lerp(1, originalWidth, twn.scale)), Std.int(FlxMath.lerp(1, originalHeight, twn.scale)));
								}, onComplete: function(twn:FlxTween) {
									lastDad = null;
									cleanupTween(twn);
								} }));
								// PRESENT TWEEN
								modchartTweens.push(FlxTween.tween(present_cover, { y: present_cover.y - 400 }, Conductor.crochet / 500, { ease: FlxEase.quartOut, onComplete: function(twn:FlxTween) {
									modchartTimers.push(new FlxTimer().start(Conductor.crochet / 250, function(tmr:FlxTimer) {
										// i know.
										var tweenTime:Float = Conductor.crochet / 1000;
										for (member in presentOverlayGroup.members)
										{
											if (member != thisChar)
											{
												modchartTweens.push(FlxTween.tween(member, { alpha: 0 }, tweenTime, { onComplete: function(twn:FlxTween) {
													member.kill();
													presentOverlayGroup.remove(member);

													member.destroy();
													member = null;

													cleanupTween(twn);
												} }));
											}
										}
										for (member in presentGroup.members)
										{
											if (member != thisChar)
											{
												modchartTweens.push(FlxTween.tween(member, { alpha: 0 }, tweenTime, { onComplete: function(twn:FlxTween) {
													member.kill();
													presentGroup.remove(member);

													member.destroy();
													member = null;

													cleanupTween(twn);
												} }));
											}
										}
										modchartTweens.push(FlxTween.tween(thisChar, { y: originalY }, tweenTime, { ease: FlxEase.bounceOut, startDelay: tweenTime, onComplete: cleanupTween }));
										cleanupTimer(tmr);
									}));
									cleanupTween(twn);
								} }));
								presentGroup.add(thisChar);
							}

							case 'mbest':
							{
								thisChar.x -= 1800;
								thisChar.y += 100;

								modchartTweens.push(FlxTween.tween(thisChar, { x: thisChar.x + 600 }, Conductor.crochet / 500, { ease: FlxEase.sineOut, onComplete: function(twn:FlxTween) {
									lastDad = null;
									cleanupTween(twn);
								} }));
								doorGroup.add(thisChar);
							}

							case 'santa':
							{
								trace('santa');

								thisChar.y -= 1000;
								modchartTweens.push(FlxTween.tween(thisChar, { y: thisChar.y + 1400 }, Conductor.crochet / 500, { ease: FlxEase.quartOut, onComplete: function(twn:FlxTween) {
									lastDad = null;
									cleanupTween(twn);
								} }));
								foregroundGroup.add(thisChar);
							}
							case 'thanos':
							{
								thisChar.x -= 1200;
								thisChar.y -= 500;

								thisChar.alpha = 0;
								modchartTweens.push(FlxTween.tween(thisChar, { alpha: 1 }, Conductor.crochet / 1000, { ease: FlxEase.quartIn, onComplete: function(twn:FlxTween) {
									lastDad = null;
									cleanupTween(twn);
								} }));
								dadGroup.add(thisChar);
							}
						}
					}
					// set the dad
					dad = thisChar;
					iconP2.changeIcon(dad.healthIcon);

					reloadHealthBarColors();
				}
				if (!ClientPrefs.middleScroll)
				{
					flipRatingOffset = flipped;

					var flipInt:Int = CoolUtil.boolToInt(flipped);
					for (note in playerStrums.members)
					{
						modchartTweens.push(FlxTween.tween(note, {
							x:
							strumX + (Note.swagWidth * note.ID)
							+ (Note.swagWidth / 2)
							+ ((FlxG.width / 2) * (1 - flipInt))
						}, Conductor.crochet / 500, { ease: FlxEase.backInOut, onComplete: cleanupTween, startDelay: (Conductor.crochet / 2000) * (note.ID + 1) / 2 }));
					}
					for (note in opponentStrums.members)
					{
						modchartTweens.push(FlxTween.tween(note, {
							x:
							strumX + (Note.swagWidth * note.ID)
							+ (Note.swagWidth / 2)
							+ ((FlxG.width / 2) * (isMiddleScroll ? ((flipInt * 2) - 1) : flipInt))
						}, Conductor.crochet / 500, { ease: FlxEase.backInOut, onComplete: cleanupTween, startDelay: (Conductor.crochet / 2000) * ((note.ID % 4) + 1) / 2 }));
					}
				}
			}
			case 'Change Scroll Speed':
			{
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);

				if (Math.isNaN(val1))
					val1 = 1;
				if (Math.isNaN(val2))
					val2 = 0;

				var newValue:Float = switch (songSpeedType)
				{
					default: SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;
					case "constant": ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;
				}

				if (val2 <= 0) { songSpeed = newValue; }
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							cleanupTween(twn);
							songSpeedTween = null;
						}
					});
				}
			}
		}
	}

	function moveCameraSection(?id:Int = 0):Void
	{
		var section:SwagSection = SONG.notes[id];

		if (section == null) return;
		moveCamera(!section.mustHitSection);
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if (isDad && dad != null)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);

			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];

			tweenCamZoom(true);
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			tweenCamZoom();
		}
	}

	function tweenCamZoom(opponent:Bool = false)
	{
		// var start:Float = defaultCamZoom;
		// switch (curSong)
		// {
		// 	case 'tutorial':
		// 	{
		// 		var target:Float = opponent ? 1.3 : 1;
		// 		if (start != target)
		// 		{
		// 			if (cameraTwn != null)
		// 			{
		// 				cameraTwn.cancel();
		// 				cleanupTween(cameraTwn);
		// 				cameraTwn = null;
		// 			}

		// 			defaultCamZoom = target;
		// 			cameraTwn = FlxTween.num(start, target, Conductor.crochet / 1000, {
		// 				ease: FlxEase.elasticInOut,

		// 				onUpdate: function(twn:FlxTween) { gameZoom = FlxMath.lerp(start, target, twn.scale); },
		// 				onComplete: function(twn:FlxTween)
		// 				{
		// 					cleanupTween(twn);
		// 					cameraTwn = null;
		// 				}
		// 			});
		// 		}
		// 	}
		// }
	}

	function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	// Any way to do this without using a different function? kinda dumb
	private function onSongComplete()
	{
		finishSong(false);
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		trace('finish song please!');
		var finishCallback:Void->Void = endSong; // In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;

		vocals.volume = 0;
		vocals.pause();

		if (ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) { finishCallback(); }
		else { finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) { finishCallback(); }); }
	}

	public var transitioning = false;

	private function cleanupEndSong(skipTransIn:Bool = false, useValidScore:Bool = true)
	{
		if (!transitioning)
		{
			var isValid:Bool = SONG.validScore && useValidScore;
			#if !switch
			if (isValid)
			{
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent))
					percent = 0;
			}
			#end

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			TitleState.playTitleMusic();
			cancelMusicFadeTween();

			FlxG.save.flush();
			FlxTransitionableState.skipNextTransIn = skipTransIn;

			CustomFadeTransition.nextCamera = FlxTransitionableState.skipNextTransIn ? camOther : null;
			MusicBeatState.switchState(new MainMenuState());

			transitioning = true;
		}
	}

	private function doShitAtTheEnd():Void
	{
		switch (curSong)
		{
			default: cleanupEndSong();
		}
	}
	public function endSong():Void
	{
		// Should kill you if you tried to cheat
		if (!(startingSong || cpuControlled))
		{
			notes.forEach(function(daNote:Note)
			{
				if (daNote.strumTime < (songLength - daNote.getSafeZone(daNote.earlyHitWindow)))
					health -= daNote.missHealth * healthLoss;
			});

			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < (songLength - daNote.getSafeZone(daNote.earlyHitWindow)))
					health -= daNote.missHealth * healthLoss;
			}
			if (doDeathCheck())
				return;
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		doShitAtTheEnd();
	}

	public function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];

			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}

		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0;
	public var showCombo:Bool = true;
	public var showRating:Bool = true;

	private function popUpScore(note:Note = null):Void
	{
		vocals.volume = 1;
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);

		var placement:String = Std.string(combo);
		var score:Int = 350;
		// tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;

		if (!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;
		if (!cpuControlled)
		{
			songScore += score;
			if (!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating();
			}

			if (ClientPrefs.scoreZoom)
			{
				if (scoreTxtTween != null)
				{
					scoreTxtTween.cancel();
					cleanupTween(scoreTxtTween);
					scoreTxtTween = null;
				}

				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = scoreTxt.scale.x;

				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, .2, {
					onComplete: function(twn:FlxTween)
					{
						cleanupTween(twn);
						scoreTxtTween = null;
					}
				});
			}
		}
		if (daRating.noteSplash && !note.noteSplashDisabled) spawnNoteSplashOnNote(note);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.antialiasing = ClientPrefs.globalAntialiasing;

		coolText.screenCenter(Y);
		coolText.x = FlxG.width * .35;

		if (flipRatingOffset) coolText.x = FlxG.width - coolText.x;
		//
		var rating:FlxSprite = new FlxSprite();
		rating.loadGraphic(Paths.image(daRating.image));

		rating.cameras = [camHUD];
		rating.screenCenter(Y);

		rating.x = coolText.x - 40;
		rating.y -= 60;

		rating.acceleration.y = 550;

		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		rating.visible = (!ClientPrefs.hideHud && showRating);

		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('combo'));

		comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		rating.antialiasing = ClientPrefs.globalAntialiasing;

		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();

		comboSpr.x = coolText.x;

		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		comboSpr.visible = (!ClientPrefs.hideHud && showCombo);

		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(strumLineNotes), rating);

		rating.setGraphicSize(Std.int(rating.width * .7));
		rating.antialiasing = ClientPrefs.globalAntialiasing;

		comboSpr.setGraphicSize(Std.int(comboSpr.width * .7));
		comboSpr.antialiasing = ClientPrefs.globalAntialiasing;

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];
		if (combo >= 1000)
			seperatedScore.push(Math.floor(combo / 1000) % 10);

		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);

		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('num${Std.int(i)}'));

			numScore.antialiasing = ClientPrefs.globalAntialiasing;
			numScore.cameras = [camHUD];

			numScore.setGraphicSize(Std.int(numScore.width * .5));
			numScore.updateHitbox();

			numScore.screenCenter();

			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			numScore.antialiasing = ClientPrefs.globalAntialiasing;

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.visible = !ClientPrefs.hideHud;

			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			// if (combo >= 10 || combo == 0)
			insert(members.indexOf(strumLineNotes), numScore);
			modchartTweens.push(FlxTween.tween(numScore, {alpha: 0}, .2, {
				onComplete: function(tween:FlxTween)
				{
					remove(numScore);
					numScore.destroy();
					cleanupTween(tween);
				},
				startDelay: Conductor.crochet / 500
			}));

			daLoop++;
		}

		modchartTweens.push(FlxTween.tween(rating, {alpha: 0}, .2, {startDelay: Conductor.crochet / 1000, onComplete: cleanupTween}));
		modchartTweens.push(FlxTween.tween(comboSpr, {alpha: 0}, .2, {
			onComplete: function(tween:FlxTween)
			{
				remove(rating);
				remove(coolText);
				remove(comboSpr);

				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
				cleanupTween(tween);
			},
			startDelay: Conductor.crochet / 1000
		}));
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		// trace('Pressed: ' + eventKey);

		if (!cpuControlled && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if (!boyfriend.stunned && generatedMusic && !endingSong)
			{
				// more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				// var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if (daNote.noteData == key) sortedNotesList.push(daNote);
						canMiss = true;
					}
				});

				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
				if (sortedNotesList.length > 0)
				{
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes)
						{
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
							{
								doubleNote.kill();
								notes.remove(doubleNote, true);

								doubleNote.destroy();
							}
							else { notesStopped = true; }
						}
						// eee jack detection before was not super good
						if (!notesStopped)
						{
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				}
				else { if (canMiss) noteMissPress(key); }
				// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if (spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
		}
		// trace('pressed: ' + controlArray);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		}
		// trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_P,
				controls.NOTE_DOWN_P,
				controls.NOTE_UP_P,
				controls.NOTE_RIGHT_P
			];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					goodNoteHit(daNote);
				}
			});
			if (!endingSong)
				bfDance();
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_R,
				controls.NOTE_DOWN_R,
				controls.NOTE_UP_R,
				controls.NOTE_RIGHT_R
			];
			if (controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if (controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void
	{
		// You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.mustPress
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		combo = 0;
		health -= daNote.missHealth * healthLoss;

		if (instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		// For testing purposes
		// trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;

		songScore -= 10;
		totalPlayed++;

		RecalculateRating();
		if (boyfriend != null && !daNote.noMissAnimation && boyfriend.hasMissAnimations)
		{
			var daAlt = daNote.noteType == 'Alt Animation' ? '-alt' : '';
			var animToPlay:String = '${singAnimations[Std.int(Math.abs(daNote.noteData))]}miss$daAlt';

			boyfriend.playAnim(animToPlay, true);
		}
		quickUpdatePresence();
	}

	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (ClientPrefs.ghostTapping)
			return;
		if (!boyfriend.stunned)
		{
			health -= .05 * healthLoss;
			if (instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			combo = 0;
			songScore -= 10;

			if (!endingSong)
				songMisses++;
			totalPlayed++;

			RecalculateRating();

			vocals.volume = 0;
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(.1, .2));

			if (boyfriend.hasMissAnimations) boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			quickUpdatePresence();
		}
	}
	function playCharacterAnim(?char:Character = null, animToPlay:String, note:Note):Bool
	{
		if (char != null && !char.specialAnim)
		{
			var curAnim:FlxAnimation = char.animation.curAnim;
			var isSingAnimation:Bool = false;

			if (curAnim != null && !curAnim.name.endsWith('miss')) { for (anim in singAnimations) { if (curAnim.name.startsWith(anim)) { isSingAnimation = true; break; } } }

			var canOverride:Bool = curAnim == null || char.lastNoteHit == null || curAnim.finished || !isSingAnimation;
			if (canOverride || char.lastNoteHit.noteData == note.noteData || (!note.isSustainNote && ((char.lastNoteHit.strumTime < note.strumTime) || (char.lastNoteHit.strumTime == note.strumTime && note.sustainLength > char.lastNoteHit.sustainLength))))
			{
				if (!note.isSustainNote || canOverride) char.lastNoteHit = note;

				char.playAnim(animToPlay, true);
				char.holdTimer = 0;

				return true;
			}
		}
		return false;
	}

	function opponentNoteHit(note:Note):Void
	{
		var isAlternative:Bool = false;
		if (!note.noAnimation)
		{
			var noteType:String = Paths.formatToSongPath(note.noteType);

			var char:Character = lastDad != null ? lastDad : dad;
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			var section:SwagSection = SONG.notes[curSection];

			if (section != null && (section.altAnim || noteType == 'alt-animation')) altAnim = '-alt';

			var leData:Int = Math.round(Math.abs(note.noteData));
			var singAnim:String = singAnimations[leData] + altAnim;

			switch (noteType)
			{
				case 'mbest-note': char = mBest;
				case 'nft-note': char = nft;

				case 'mbest-and-nft-note':
				{
					var otherChar:Character = char == nft ? mBest : nft;
					playCharacterAnim(otherChar, singAnim, note);
				}
			}

			var didPlay:Bool = playCharacterAnim(char, singAnim + altAnim, note);
			if (didPlay)
			{
				var camDelta:FlxPoint = getCameraDelta(leData);
				opponentDelta = camDelta;
			}
		}

		if (SONG.needsVoices) vocals.volume = 1;
		var time:Float = .15;

		if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) time *= 2;

		StrumPlayAnim(isAlternative ? 2 : 1, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;

		if (!note.isSustainNote)
		{
			note.kill();

			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;
			if (!note.hitsoundDisabled) Hitsound.play();

			if (note.hitCausesMiss)
			{
				noteMiss(note);
				if (!note.noteSplashDisabled && !note.isSustainNote) spawnNoteSplashOnNote(note);

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo = Std.int(Math.min(combo + 1, 9999));
				popUpScore(note);
			}
			health += note.hitHealth * healthGain;
			if (!note.noAnimation)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + switch (note.noteType)
				{
					case 'Alt Animation': '-alt';
					default: '';
				};

				var didPlay:Bool = playCharacterAnim(boyfriend, animToPlay, note);
				if (didPlay)
				{
					var leData:Int = Math.round(Math.abs(note.noteData));
					playerDelta = getCameraDelta(leData);
				}
				if (note.noteType == 'Hey!')
				{
					if (boyfriend.animOffsets.exists('hey'))
					{
						boyfriend.playAnim('hey', true);

						boyfriend.specialAnim = true;
						boyfriend.heyTimer = .6;
					}
				}
			}

			if (cpuControlled)
			{
				var time:Float = .15;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
					time += .15;

				StrumPlayAnim(0, Std.int(Math.abs(note.noteData)) % 4, time);
			}
			else
			{
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
						spr.playAnim('confirm', true);
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
		quickUpdatePresence();
	}

	function spawnNoteSplashOnNote(note:Note)
	{
		if (ClientPrefs.noteSplashes && note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null) spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var skin:String = 'noteSplashes';
		if (SONG.splashSkin != null && SONG.splashSkin.length > 0)
			skin = SONG.splashSkin;

		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;

		if (note != null)
		{
			skin = note.noteSplashTexture;

			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);

		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	override function destroy()
	{
		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}

	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null)
		{
			FlxG.sound.music.fadeTween.cancel();
			FlxG.sound.music.fadeTween.destroy();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;

	function canZoomCamera():Bool
	{
		return camZooming && ClientPrefs.camZooms; // && FlxG.camera.zoom < 1.35;
	}

	function getStretchValue(value:Bool):Float
	{
		return value ? -1 : .5;
	}

	function doSustainShake()
	{
		if (!ClientPrefs.reducedMotion)
		{
			var stepCrochet:Float = Conductor.stepCrochet / 1000;
			if (gameShakeAmount > 0)
				camGame.shake(gameShakeAmount, stepCrochet);
			if (hudShakeAmount > 0)
				camHUD.shake(hudShakeAmount, stepCrochet);
		}
	}

	function cleanupTween(?twn:FlxTween)
	{
		if (modchartTweens.contains(twn))
			modchartTweens.remove(twn);
		if (twn != null)
		{
			twn.active = false;
			twn.destroy();
		}
	}

	function cleanupTimer(?tmr:FlxTimer)
	{
		if (modchartTimers.contains(tmr))
			modchartTimers.remove(tmr);
		if (tmr != null)
		{
			tmr.active = false;
			tmr.destroy();
		}
	}

	override function stepHit()
	{
		super.stepHit();

		var songPosition:Float = Conductor.songPosition - Conductor.offset;
		if (songPosition >= 0 && Conductor.songPosition <= FlxG.sound.music.length && (Math.abs(FlxG.sound.music.time - songPosition) > vocalResyncTime && FlxG.sound.music.length > songPosition && FlxG.sound.music.time < FlxG.sound.music.length && FlxG.sound.music.playing) || (SONG.needsVoices && Math.abs(vocals.time - songPosition) > vocalResyncTime && vocals.length > songPosition && vocals.time < vocals.length && vocals.time < FlxG.sound.music.length && vocals.playing))
			resyncVocals();
		if (curStep == lastStepHit)
			return;

		var zoomFunction:Array<Dynamic> = camZoomTypes[camZoomType];
		if (zoomFunction != null && canZoomCamera() && !zoomFunction[0])
			zoomFunction[1]();

		doSustainShake();
		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;
	function iconBop(beat:Int = 0)
	{
		var crochetDiv:Float = 1300;
		if (beat % gfSpeed == 0)
		{
			var stretchBool:Bool = (beat % (gfSpeed * 2)) == 0;

			var stretchValueOpponent:Float = getStretchValue(!stretchBool);
			var stretchValuePlayer:Float = getStretchValue(stretchBool);

			var angleValue:Float = 15 * FlxMath.signOf(stretchValuePlayer);
			var scaleValue:Float = .4;

			var scaleDefault:Float = 1.1;

			iconP1.scale.set(scaleDefault, scaleDefault + (scaleValue * stretchValuePlayer));
			iconP2.scale.set(scaleDefault, scaleDefault + (scaleValue * stretchValueOpponent));

			modchartTweens.push(FlxTween.angle(iconP1, -angleValue, 0, Conductor.crochet / (crochetDiv * gfSpeed),
				{ease: FlxEase.quadOut, onComplete: cleanupTween}));
			modchartTweens.push(FlxTween.angle(iconP2, angleValue, 0, Conductor.crochet / (crochetDiv * gfSpeed),
				{ease: FlxEase.quadOut, onComplete: cleanupTween}));

			modchartTweens.push(FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / (crochetDiv * gfSpeed),
				{ease: FlxEase.quadOut, onComplete: cleanupTween}));
			modchartTweens.push(FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / (crochetDiv * gfSpeed),
				{ease: FlxEase.quadOut, onComplete: cleanupTween}));

			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat) return;
		if (generatedMusic) notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		var section:SwagSection = SONG.notes[Math.floor(curStep / 16)];
		if (section != null && section.changeBPM) Conductor.changeBPM(section.bpm);

		var zoomFunction:Array<Dynamic> = camZoomTypes[camZoomType];
		if (zoomFunction != null && canZoomCamera() && zoomFunction[0])
			zoomFunction[1]();

		iconBop(curBeat);

		groupDance(boyfriendGroup, curBeat);
		// groupDance(dadGroup, curBeat);
		groupDance(totalChars, curBeat);

		stageDance(curBeat);
		lastBeatHit = curBeat;
	}

	function StrumPlayAnim(player:Int, id:Int, time:Float)
	{
		var strumLine:FlxTypedGroup<StrumNote> = switch (player)
		{
			case 1: strumLineNotes;
			default: playerStrums;
		};

		var spr:StrumNote = strumLine.members[id];
		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;

	public function RecalculateRating()
	{
		if (totalPlayed <= 0) { ratingName = '?'; } // Prevent divide by 0
		else
		{
			// Rating Percent
			ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
			// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

			// Rating Name
			if (ratingPercent >= 1)
			{
				ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
			}
			else
			{
				for (i in 0...ratingStuff.length - 1)
				{
					if (ratingPercent < ratingStuff[i][1])
					{
						ratingName = ratingStuff[i][0];
						break;
					}
				}
			}
		}

		// Rating FC
		ratingFC = "";
		if (songMisses > 0)
		{
			if (songMisses >= 10) { ratingFC = "Clear"; }
			else { ratingFC = "SDCB"; }

			return;
		}

		if (bads > 0 || shits > 0) { ratingFC = "FC"; return; }
		if (goods > 0) { ratingFC = "GFC"; return; }
		if (sicks > 0) { ratingFC = "SFC"; return; }
	}
}