package;

import Section.SwagSection;
import Song.SwagSong;

/**
 * ...
 * @author
 */
typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor
{
	public static var bpm:Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition:Float = 0;
	public static var lastSongPos:Float;
	public static var offset:Float = 0;

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];
	public static function judgeNote(note:Note, diff:Float = 0) // STOLEN FROM KADE ENGINE (bbpanzu) - I had to rewrite it later anyway after i added the custom hit windows lmao (Shadow Mario)
	{
		var data:Array<Rating> = PlayState.instance.ratingsData; //shortening cuz fuck u

		for (i in 0...data.length - 1) { if (diff <= data[i].hitWindow) return data[i]; } // skips last window (horse dog)
		return data[data.length - 1];
	}

	public static function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [];
		var curBPM:Float = song.bpm;

		var totalSteps:Int = 0;
		var totalPos:Float = 0;

		for (i in 0...song.notes.length)
		{
			var note:SwagSection = song.notes[i];
			var noteBPM:Float = note.bpm;

			if (note.changeBPM && noteBPM != curBPM)
			{
				curBPM = noteBPM;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: noteBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = note.lengthInSteps;

			totalSteps += deltaSteps;
			totalPos += (60 / curBPM) * 250 * deltaSteps;
		}
		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	public static function changeBPM(newBpm:Float)
	{
		bpm = newBpm;

		crochet = ((60 / bpm) * 1000);
		stepCrochet = crochet / 4;
	}
}
class Rating
{
	public var name:String = '';
	public var image:String = '';
	public var counter:String = '';
	public var hitWindow:Null<Int> = 0; //ms
	public var ratingMod:Float = 1;
	public var score:Int = 350;
	public var noteSplash:Bool = true;

	public function new(name:String)
	{
		this.name = name;
		this.image = name;
		this.counter = '${name}s';
		this.hitWindow = Reflect.field(ClientPrefs, name + 'Window');

		if (hitWindow == null) hitWindow = 0;
	}

	public function increase(blah:Int = 1)
	{
		Reflect.setField(PlayState.instance, counter, Reflect.field(PlayState.instance, counter) + blah);
	}
}