s.boot;
Server.killAll;
s.options.numWireBufs = 450;
s.reboot;


(
~amp = {
	arg fundFreq, p_pose = 2, stiffness = 11;
	var i = 0;
	var n = 200;
	//var n_harmonics = (20000/fundFreq).floor;
	// here we just divide by 1000 to have more sensibility on the input number
	var stiffness_small = stiffness/(1000);
	// This is a constant detune that will be applied to each frequency mode except the fundamental
	var detune = stiffness_small + (stiffness_small.squared);
	// This is a part of the detuning that will depend on the frequency mode
	var variable_part = pi.squared * stiffness_small.squared/8;
	// Frequency array creation (here we apply the detuning to each frequency mode)
	//f = [fundFreq, Array.fill(249, {arg i; if( ((i+1)*fundFreq) < 20000,
	//	{(i+2)*fundFreq * (1 + detune + ((i+1).squared * variable_part))},
	//	{0}
	//)
	//})];
	// Amplitude array creation
	//a = Array.fill(250, {arg i; if( ((i+1)*fundFreq) < 20000,
	//	{((2*p_pose.squared)/(squared(i+1)*pi.squared*(p_pose-1)))*sin((i+1)*pi/p_pose)},
	//	{0}
	//)}
	//);
	a = Array.fill(n,{0});
    n.do({
		a[i] =((2*p_pose.squared)/(squared(i+1)*pi.squared*(p_pose-1)))*sin((i+1)*pi/p_pose);
		i = i+1;
	});
	// We normalize the array amplitude so that the sum of all the sinusoids is 1 (we apply a -3dB attenuation)
    a = a.normalizeSum * 0.5;
	// return as an array both arrays
	a;
};

~freq = {
	arg fundFreq, p_pose = 2, stiffness = 0;
	var i = 0;
	var n = 200;
	//var n_harmonics = (20000/fundFreq).floor;
	// here we just divide by 1000 to have more sensibility on the input number
	var stiffness_small = stiffness/(1000);
	// This is a constant detune that will be applied to each frequency mode except the fundamental
	var detune = stiffness_small + (stiffness_small.squared);
	// This is a part of the detuning that will depend on the frequency mode
	var variable_part = pi.squared * stiffness_small.squared/8;
	// Frequency array creation (here we apply the detuning to each frequency mode)
	//f = [fundFreq, Array.fill(249, {arg i; if( ((i+1)*fundFreq) < 20000,
	//	{(i+2)*fundFreq * (1 + detune + ((i+1).squared * variable_part))},
	//	{0}
	//)
	//})];
	// Amplitude array creation
	//a = Array.fill(250, {arg i; if( ((i+1)*fundFreq) < 20000,
	//	{((2*p_pose.squared)/(squared(i+1)*pi.squared*(p_pose-1)))*sin((i+1)*pi/p_pose)},
	//	{0}
	//)}
	//);
	f = Array.fill(n,{0});
    n.do({
		f[i] =(i+1)*fundFreq * (1 + detune + ((i+1).squared * variable_part));
		i = i+1;
	});
	f[0]=fundFreq;
	f;
};
)

// the SynthDef of the string
(
SynthDef(\modal,{ |trig = 1, midinote = 70, modulation = 40, vel = 1|
	var env, amp, freq, p, x;
	// Initialization of frequency and amplitude arrays (initially all zeros), and envelope
	//amp = NamedControl.ar(\amp, Array.fill(250,{0}));
	//freq = NamedControl.ar(\freq , Array.fill(250,{0}));
    amp = ~amp.value(midinote.midicps,5,11);
    freq = ~freq.value(midinote.midicps,5,11);
	env = EnvGen.kr(Env.perc(0.01, 1, 1, curve:-4), trig, doneAction: 2);
	// All sine waves summed together
	x = SinOsc.ar(freq, 0, amp).sum;
	Out.ar(0,Pan2.ar(x * env,0));
}).add;
)

(
// Defining FM synthesis module
SynthDef(\fm, {
	arg midinote = 70, freq_mod = 220, vel = 1, modulation = 40, trig = 1;
	var out, mod, sig, env;
	// Modulation signal
	mod = SinOsc.ar(midinote + freq_mod, mul:modulation);
	// Envelope
	env = EnvGen.kr(Env.perc(0.01, 0.3 + (vel / 2), 1, curve:-7), trig, doneAction: 2);
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
~bpm = 100;
t = TempoClock(~bpm * 4 /60);
// Ndef to contain the sequence implemented after and setting the clock
Ndef(\a).fadeTime_(0).clock_(t).quant_(4).play;
// Random sequence declaration and initialization
~randomSeq = Array.newClear(32);
32.do({|i|
	~randomSeq[i] = 0.5.coin.binaryValue;
});
// Array buffer that contains all the previous played notes
~noteArray = Array.rand(32, 60, 72);
~velocityArray = Array.rand (32, 0.5, 0.9);
// The actual played note is not the last element of the array
~actualNote = ~noteArray[30];
// Total number of steps of Euclidean rhythm


~modArray = Array.rand(32, 0, 200);
~actualMod = ~modArray[30];





)


(

~step = 16;
// Number of triggers inside of the Euclidean rhythm
~trig = 10;
// Initial rotation
~rot = 0;
~pattern = ~euclid.value(~step, ~trig, ~rot);
// Probability bias of the random coin flip
~prob = 0.2;
// Operator between Or, And, Xor, Nand
~op = 1;
// On/Off loop
~loop = 0;
~looplength = 3;


~standardDev = 10;
~expVal = 60;
~glide = 0;
~noteLoopOn = 0;
~noteLoopLength = 16;
~selectScale = 10;

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

~velStandardDev = 0.2;
~velExpVal = 0.4;
~velocityLoop = 1;
~velocityLoopLength = 16;


~modStandardDev = 20;
~modExpVal = 30;
~interpol = 1;
~modulationLoopOn = 0;
~modLoopLength = 16;



~loopArray = ~randomSeq;
~loopArray = ~loopArray.copyRange(0, ~looplength - 1);
~noteLoopArray = ~noteArray;
~noteLoopArray = ~noteArray.copyRange(0, ~noteLoopLength - 1);
~velocityLoopArray = ~velocityArray;
~velocityLoopArray = ~velocityArray.copyRange(0, ~velocityLoopLength - 1);
~modLoopArray = ~modArray;
~modLoopArray = ~modArray.copyRange(0, ~modLoopLength - 1);

)

(

// The played pattern
Ndef(\a, Pbind(
	\instrument, \modal,
	// The trigger will be a combination of a Euclidean rhythm with a random sequence
	\trig, Pseq(~pattern, inf, 0).collect({|x|
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
}),
	\dur, Pseq([1, 1], inf).collect({|x|
		if(~trigg == 1, {x}, {Rest(1)});
	}),
	\vel, Pfunc({if(~velocityLoop == 1,
		{
			~velocityLoopArray = ~velocityLoopArray.rotate(-1);
			~velocityLoopArray[~velocityLoopLength - 2];
	},
		{
			~velocityArray = ~velocityArray.rotate(-1);
			~velocityArray[31] =  if(~velStandardDev < 0.5, {clip(~velExpVal.gauss(~velStandardDev), 0.1, 1)}, {if(0.5.coin, {clip(0.3.gauss(0.55 - ~velStandardDev), 0.1, 1)}, {clip(0.9.gauss(0.55 - ~velStandardDev), 0.1, 1)})});
			~velocityArray[30];
	})}),

	// The note when triggered (now is random)
	\midinote, Pfuncn({
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
					if(~glide < 0, {Ndef(\glide, {
						Line.kr(~noteLoopArray[~noteLoopLength- 3], ~actualNote, ((60/(~bpm * 4)) - 0.030) * ~glide.abs, doneAction:2)
					})},
						{Ndef(\glide, {
						XLine.kr(~noteLoopArray[~noteLoopLength- 3], ~actualNote, ((60/(~bpm * 4)) - 0.030) * ~glide, doneAction:2)
					})})
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
					if(~glide < 0, {Ndef(\glide, {
						Line.kr(~noteArray[29], ~actualNote, ((60/(~bpm * 4)) - 0.030) * ~glide.abs, doneAction:2)
					})},
							{Ndef(\glide, {
						XLine.kr(~noteArray[29], ~actualNote, ((60/(~bpm * 4)) - 0.030) * ~glide, doneAction:2)
					})});
				}
			)
		}
	)
}, inf),

	\modulation, Pfuncn({
	if(~modulationLoopOn == 1,
		{
			// note loop is one
			~modLoopArray = ~modLoopArray.rotate(-1);
			// We quintize the notes to a scale
			~actualMod = ~modLoopArray[~modLoopLength - 2];
			if(~interpol == 0,
				//there were some glitches if we put 0 seconds to the glide time so we just skip the Line.kr if we have 0 glide
				{
					~actualMod
				},
				{
					// Here we do the glide from the previous note to the current one
					if(~interpol < 0, {Ndef(\interpol, {
						Line.kr(~modLoopArray[~modLoopLength- 3], ~actualMod, ((60/(~bpm * 4)) - 0.030) * ~interpol.abs, doneAction:2)
					})},
						{Ndef(\interpol, {
						XLine.kr(~modLoopArray[~modLoopLength- 3], ~actualMod, ((60/(~bpm * 4)) - 0.030) * ~interpol, doneAction:2)
					})})
				}
			)
		},
		{
			// Here We just update and rotate the note array with new notes
			~modArray = ~modArray.rotate(-1);
				~modArray[31] = if(~modStandardDev < 50, {~modExpVal.gauss(~modStandardDev).abs}, {if(0.5.coin, {clip(50.gauss(55 - ~standardDev), 0, 200)}, {clip(150.gauss(55 - ~standardDev), 150, 200)})});
			~actualMod = ~modArray[30];
			if(~interpol == 0,
				//there were some glitches if we put 0 seconds to the glide time so we just skip the Line.kr if we have 0 glide
				{
					~actualMod
				},
				{
					// Here we do the glide from the previous note to the current one
					if(~interpol < 0, {Ndef(\interpol, {
						Line.kr(~modArray[29], ~actualMod, ((60/(~bpm * 4)) - 0.030) * ~interpol.abs, doneAction:2)
					})},
							{Ndef(\interpol, {
						XLine.kr(~modArray[29], ~actualMod, ((60/(~bpm * 4)) - 0.030) * ~interpol, doneAction:2)
					})});
				}
			)
		}
	)
}, inf)
)
);

)















s.scope;