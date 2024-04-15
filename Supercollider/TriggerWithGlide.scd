s.boot;
Server.killAll;

(
// Defining FM synthesis module
SynthDef(\fm, {
	arg midinote = 70, freq_mod = 250, vel = 1, amp_mod = 40, trig = 1;
	var out, mod, sig, env;
	// Modulation signal
	mod = SinOsc.ar(freq_mod, mul:amp_mod);
	// Envelope
	env = EnvGen.kr(Env.perc(0.01, 0.4, 1, curve:-7), trig, doneAction: 2);
	// Output signal
	sig = LFTri.ar(midinote.midicps + mod, mul:vel);

	out = Out.ar(0, Pan2.ar(sig * env));
}).add;
)



(
// Euclidean rhythm function implementation (got it from a Javascript code on Github)
~euclid = {
	arg steps, pulses, rotate;
	var rhythm = Array.newClear(steps), bucket = 0;
	rotate = rotate + 1;
	rotate = rotate % steps;

	steps.do({arg i;
		bucket = bucket + pulses;
		if(bucket >= steps, {
			bucket = bucket - steps;
			rhythm[i] = 1;
		},{rhythm[i] = 0;});
	});

	if(rotate > 0, {
		rhythm = ~rotateSeq.value(rhythm, steps, rotate);
	},{});

	rhythm;

};

// Function to rotate the Euclidean rhythm
~rotateSeq = {
	arg seq2, steps, rotate;
	var output = Array.newClear(steps), val = steps - rotate;
	seq2.size.do({arg i;
		output[i] = seq2[abs((i+val) % seq2.size)];
	});
	output;
};

)

(
// BPM of the clock
t = TempoClock(120 * 4 /60);
// Ndef to contain the sequence implemented after and setting the clock
Ndef(\a).fadeTime_(0).clock_(t).quant_(4).play;
// Random sequence declaration and initialization
~randomSeq = Array.newClear(16);
16.do({|i|
	~randomSeq[i] = 0.5.coin.binaryValue;
});
// Array buffer that contains all the previous played notes
~noteArray = Array.rand(32, 60, 72);
// The actual played note is the last element of the array
~actualNote = ~noteArray[31];

)


(

// The played pattern
Ndef(\a, Pbind(
	\instrument, \fm,
	// The trigger will be a combination of a Euclidean rhythm with a random sequence
	\trig, Pdefn(\currentPtt, (Pseq(~euclid.value(8, 5, 1), inf, 0).collect({|x| (~trigg = x.asBoolean.or(0.coin).binaryValue)}))),
	\dur, Pseq([1, 1], inf).collect({|x|
		if(~trigg == 1, {x}, {Rest(1)});
	}),
	\vel, 0.9,
	// The note when triggered (now is random)
	\midinote, (Pdefn(\newNote, Pwhite(60, 70, inf)))
));

)

//Here we can chaneg in real time the elements of the pattern
(
// Total number of steps of Euclidean rhythm
~step = 16;
// Number of triggers inside of the Euclidean rhythm
~trig = 7;
// Initial rotation
~rot = 2;
// Probability bias of the random coin flip
~prob = 0.5;
// Operator between Or, And, Xor, Nand
~op = 3;
// On/Off loop
~loop = 0;
~noteLoopOn = 0;
~looplength = 8;
~noteLoopLength = 8;
~glide = ((60/(120*4)) - 0.030)*0;
~standardDev = 5;
~expVal = 60;
~selectScale = 5;
~scale = case(
	{~selectScale == 1}, {Scale.chromatic},
	{~selectScale == 2}, {Scale.major},
	{~selectScale == 3}, {Scale.minor},
	{~selectScale == 4}, {Scale.majorPentatonic},
	{~selectScale == 5}, {Scale.minorPentatonic},
	{~selectScale == 6}, {Scale.dorian},
	{~selectScale == 7}, {Scale.lydian},
	{~selectScale == 8}, {Scale.phrygian},
	{~selectScale == 9}, {Scale.mixolidian},
	{~selectScale == 10}, {Scale.iwato},
);


//Prima si crea una copia della sequenza randomica, poi si estrae una sezione lunga quanto la lunghezza del loop desiderato
~loopArray = ~randomSeq.copyRange(0, ~step -1);
~loopArray = ~loopArray.copyRange(0, ~looplength - 1);

// This is for the triggers, we can loop triggers but still have variable notes
Pdefn(\currentPtt, (Pseq(~euclid.value(~step, ~trig, ~rot), inf, 0).collect({|x|
	case(
		{~op == 1}, {
			if(~loop == 1, //Or
				{
					// We are inside the loop mode
					// Get next note from the loop array
					~loopArray = ~loopArray.rotate(-1);
					// Calculate trigger
					~trigg = x.asBoolean.or(~loopArray[~looplength - 2].asBoolean).binaryValue;
				},
				{
					// Get next note from the random array
					~randomSeq = ~randomSeq.rotate(-1);
					// add new element to the last position of array (length of array is 16, from 0 to 15)
					~randomSeq.put(15, ~prob.coin.binaryValue);
					// get the current note to play, which is the one that was previously at position 15, but because of the rotation, now is in position 14
					~trigg = x.asBoolean.or(~randomSeq[14].asBoolean).binaryValue;
				}
			)
		},
		{~op == 2}, {
			if(~loop == 1, // And
				{
					~loopArray = ~loopArray.rotate(-1);
					~trigg = x.asBoolean.and(~loopArray[~looplength - 2].asBoolean).binaryValue;},
				{
					~randomSeq = ~randomSeq.rotate(-1);
					~randomSeq.put(15, ~prob.coin.binaryValue);
					~trigg = x.asBoolean.and(~randomSeq[14].asBoolean).binaryValue;
				}
			)
		},
		{~op == 3}, {
			if(~loop == 1, //Xor
				{
					~loopArray = ~loopArray.rotate(-1);
					~trigg = x.asBoolean.xor(~loopArray[~looplength - 2].asBoolean).binaryValue;},
				{
					~randomSeq = ~randomSeq.rotate(-1);
					~randomSeq.put(15, ~prob.coin.binaryValue);
					~trigg = x.asBoolean.xor(~randomSeq[14].asBoolean).binaryValue;
				}
			)
		},
		{~op == 4}, {
			if(~loop == 1, //Nand
				{
					~loopArray = ~loopArray.rotate(-1);
					~trigg = x.asBoolean.nand(~loopArray[~looplength - 2].asBoolean).binaryValue;
				},
				{
					~randomSeq = ~randomSeq.rotate(-1);
					~randomSeq.put(15, ~prob.coin.binaryValue);
					~trigg = x.asBoolean.nand(~randomSeq[14].asBoolean).binaryValue;
				}
			)
		},

);
})));

~noteLoopArray = ~noteArray.copyRange(0, ~noteLoopLength - 1);

Pdefn(\newNote, (Pfuncn({
	if(~noteLoopOn == 1,
		{
			// note loop is one
			~noteLoopArray = ~noteLoopArray.rotate(-1);
			// We quintize the notes to a scale
			~actualNote = ~noteLoopArray[~noteLoopLength - 2].nearestInScale(~scale, 12);
			if(~glide == 0,
				//there were some glitches if we put 0 seconds to the glide time so we just skip the Line.kr if we have 0 glide
				{
					~actualNote
				},
				{
					// Here we do the glide from the previous note to the current one
					Ndef(\glide, {
						Line.kr(~noteLoopArray[~noteLoopLength- 3], ~actualNote, ~glide, doneAction:2)
					})
				}
			)
		},
		{
			// Here We just update and rotate the note array with new notes
			~noteArray = ~noteArray.rotate(-1);
			~noteArray[31] = if(~standardDev < 50, {~expVal.gauss(~standardDev).abs}, {if(0.5.coin, {30.gauss(55 - ~standardDev).abs}, {90.gauss(55 - ~standardDev).abs})});
			~actualNote = ~noteArray[30].nearestInScale(~scale, 12);
			if(~glide == 0,
				//there were some glitches if we put 0 seconds to the glide time so we just skip the Line.kr if we have 0 glide
				{
					~actualNote
				},
				{
					// Here we do the glide from the previous note to the current one
					Ndef(\glide, {
						Line.kr(~noteArray[29], ~actualNote, ~glide, doneAction:2)
					})
				}
			)
		}
	)
}, inf)));

)














s.scope;