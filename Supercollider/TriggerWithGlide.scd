//Runna prima l'opzione, poi lancia il server
s.options.numWireBufs = 450;
s.boot;


Server.killAll;
s.reboot;


//Runna questo dopo il server
(
~step = 1;
// Number of triggers inside of the Euclidean rhythm
~trig = 1;
// Initial rotation
~rot = 0;
~pattern = ~euclid.value(~step, ~trig, ~rot);
// Probability bias of the random coin flip
~prob = 0;
// Operator between Or, And, Xor, Nand
~op = 1;
// On/Off loop
~loop = 0;
~loopLength = 1;
~trigPerm = 0;


~standardDev = 0.1;
~expVal = 1;
~glide = 0;
~noteLoopOn = 0;
~noteLoopLength = 1;
~notePerm = 0;
~selectScale = 1;


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

~velStandardDev = 0.1;
~velExpVal = 0.1;
~velocityLoop = 0;
~velocityLoopLength = 1;


~modStandardDev = 0.1;
~modExpVal = 1;
~interpol = 0;
~modulationLoopOn = 0;
~modLoopLength = 1;





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

SynthDef(\modal,{ |trig = 1, midinote = 70, modulation , vel = 1, buf = 0, rate = 2, ptrdelay = 0.3, dryWet|
	var env, amp, freq, p, x, sig, ptr, gran, maxgraindur;
	// Initialization of frequency and amplitude arrays (initially all zeros), and envelope
	//amp = NamedControl.ar(\amp, Array.fill(250,{0}));
	//freq = NamedControl.ar(\freq , Array.fill(250,{0}));
    amp = ~amp.value(midinote.midicps, modulation, 11) * vel;
    freq = ~freq.value(midinote.midicps,5, 11);
	env = EnvGen.kr(Env.perc(0.01, 0.2 + vel, 1, curve:-4), trig, doneAction: 2);
	// All sine waves summed together
	x = SinOsc.ar(freq, 0, amp).sum;

	ptr = Phasor.ar(0, BufRateScale.ir(0), 0, BufFrames.ir(0));
	maxgraindur = ptrdelay / rate;
	BufWr.ar(x * env, buf, ptr);
	sig = GrainBuf.ar(
		numChannels: 2,
		trigger: Dust.kr(16),
		dur: min(0.3, maxgraindur),
		sndbuf: buf,
		rate: rate,
		pos: (ptr - (ptrdelay  * SampleRate.ir))  / BufFrames.ir(buf),
		envbufnum: -1,
		interp: 4,
		maxGrains: 64
	);
	Out.ar(0, XFade2.ar(x * env, sig, dryWet));
}).add;



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
b = Buffer.alloc(s, s.sampleRate * 3, bufnum: 0);

~loopArray = ~randomSeq;
~loopArray = ~loopArray.copyRange(0, ~loopLength - 1).permute(~trigPerm);

~noteLoopArray = ~noteArray;
~noteLoopArray = ~noteArray.copyRange(0, ~noteLoopLength - 1).permute(~notePerm);
~velocityLoopArray = ~velocityArray;
~velocityLoopArray = ~velocityArray.copyRange(0, ~velocityLoopLength - 1);
~modLoopArray = ~modArray;
~modLoopArray = ~modArray.copyRange(0, ~modLoopLength - 1);


~ritmo = {Pdefn(\rhythm, Pseq(~pattern, inf, 0).collect({|x|
	case(
		{~op == 1}, {
			if(~loop == 1, //Or
				{
					// We are inside the loop mode
					// Get next note from the loop array
					~loopArray = ~loopArray.rotate(-1);
					// Calculate trigger
					~scport.sendMsg('/trig', ~trigg);
					~trigg = x.asBoolean.or(~loopArray[(~loopLength - 2).clip(0, 31)].asBoolean).binaryValue;
				},
				{
					// Get next note from the random array
					~randomSeq = ~randomSeq.rotate(-1);
					// add new element to the last position of array (length of array is 16, from 0 to 15)
					~randomSeq.put(15, ~prob.coin.binaryValue);
					// get the current note to play, which is the one that was previously at position 15, but because of the rotation, now is in position 14
					~scport.sendMsg('/trig', ~trigg);
					~trigg = x.asBoolean.or(~randomSeq[14].asBoolean).binaryValue;
				}
			)
		},
		{~op == 2}, {
			if(~loop == 1, // And
				{
					~loopArray = ~loopArray.rotate(-1);
					~scport.sendMsg('/trig', ~trigg);
					~trigg = x.asBoolean.and(~loopArray[(~loopLength - 2).clip(0, 31)].asBoolean).binaryValue;},
				{
					~randomSeq = ~randomSeq.rotate(-1);
					~randomSeq.put(15, ~prob.coin.binaryValue);
					~scport.sendMsg('/trig', ~trigg);
					~trigg = x.asBoolean.and(~randomSeq[14].asBoolean).binaryValue;
				}
			)
		},
		{~op == 3}, {
			if(~loop == 1, //Xor
				{
					~loopArray = ~loopArray.rotate(-1);
					~scport.sendMsg('/trig', ~trigg);
					~trigg = x.asBoolean.xor(~loopArray[(~loopLength - 2).clip(0, 31)].asBoolean).binaryValue;},
				{
					~randomSeq = ~randomSeq.rotate(-1);
					~randomSeq.put(15, ~prob.coin.binaryValue);
					~scport.sendMsg('/trig', ~trigg);
					~trigg = x.asBoolean.xor(~randomSeq[14].asBoolean).binaryValue;
				}
			)
		},
		{~op == 4}, {
			if(~loop == 1, //Nand
				{
					~loopArray = ~loopArray.rotate(-1);
					~scport.sendMsg('/trig', ~trigg);
					~trigg = x.asBoolean.nand(~loopArray[(~loopLength - 2).clip(0, 31)].asBoolean).binaryValue;
				},
				{
					~randomSeq = ~randomSeq.rotate(-1);
					~randomSeq.put(15, ~prob.coin.binaryValue);
					~scport.sendMsg('/trig', ~trigg);
					~trigg = x.asBoolean.nand(~randomSeq[14].asBoolean).binaryValue;
				}
			)
		},

);
}))};
~dinamica = {Pdefn(\dynamics, Pfunc({if(~velocityLoop == 1,
		{
			~velocityLoopArray = ~velocityLoopArray.rotate(-1);
		~velocityLoopArray[(~velocityLoopLength - 2).clip(0, 30)];
	},
		{
			~velocityArray = ~velocityArray.rotate(-1);
		~velocityArray[31] =  if(~velStandardDev < 0.5,
			{clip(~velExpVal.gauss(~velStandardDev), 0.1, 1)},
			{if(0.5.coin,
				{clip((0.2 - (~velStandardDev/10)).gauss(0.2 - (~velStandardDev/10)), 0.1, 1)},
				{clip((0.9 + (~velStandardDev/10)).gauss(0.9 - (~velStandardDev/10)), 0.1, 1)}
		)}
		);
			~velocityArray[30];
})}))};

	// The note when triggered (now is random)
~melodia = {Pdefn(\melody, Pfuncn({
	if(~noteLoopOn == 1,
		{
			// note loop is one
			~noteLoopArray = ~noteLoopArray.rotate(-1);
			// We quintize the notes to a scale
			~actualNote = ~noteLoopArray[clip(~noteLoopLength - 2, 0, 30)].nearestInScale(~scale, 12);
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
			~noteArray[31] = if(~standardDev < 20, {~expVal.gauss(~standardDev).abs}, {if(0.5.coin, {(41-~standardDev).gauss(40.1 - ~standardDev).clip(1, 60)}, {(87 + ~standardDev).gauss(40.1 - ~standardDev).clip(60, 127)})});
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
}, inf))};

~modulazione = {Pdefn(\variations, Pfuncn({
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
			~modArray[31] = if(~modStandardDev < 10, {~modExpVal.gauss(~modStandardDev).clip(2, 20)}, {if(0.5.coin, {clip((12 - ~modStandardDev/2).gauss(10.1 - ~modStandardDev/2), 2, 20)}, {clip((10 + ~modStandardDev/2).gauss(10.1 - ~modStandardDev/2), 2, 20)})});
			~actualMod = ~modArray[30].fold(2, 20);
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
}, inf))};



Ndef(\a, Pbind(
	\instrument, \modal,
	// The trigger will be a combination of a Euclidean rhythm with a random sequence
	\trig, Pdefn(\rhythm, ~ritmo),
	\dur, Pseq([1, 1], inf).collect({|x|
		if(~trigg == 1, {x}, {Rest(1)});
	}),
	\vel, Pdefn(\dynamics,~dinamica),

	// The note when triggered (now is random)
	\midinote, Pdefn(\melody, ~melodia).collect({|x|
		if(~trigg == 1, {x}, {Rest(1)});
	}),

	\modulation, Pdefn(\variations, ~modulazione),
	\dryWet, Pdefn(\effect, -1)
)
);


)




//Ora runna questo per aprire la GUI. Divertiti :)
(
Window("Layout Management", Rect(100, 100, 500, 600)).front
.layout_(
	VLayout(
		HLayout(
			VLayout(
				Button().states_([
					["Trig Loop Off", Color.gray(0.2), Color.gray(0.8)],
					["Trig Loop On", Color.gray(0.8), Color.green(0.7)]
				])
				.action_({ |btn| ~loop = btn.value;
					~loopArray = ~randomSeq;
					~loopArray = ~loopArray.copyRange(0, ~loopLength - 1).permute(~trigPerm);
					~ritmo.value;
				}),
				    a = StaticText().string = "Euclid Steps: " ++ ~step.asString,
				Knob().action_({ |knb| ~step = (knb.value * 31) + 1;
					~step = ~step.asInteger;
					a.string = "Euclid Steps: " ++ ~step.asString;
					~pattern = ~euclid.value(~step, ~trig, ~rot);
					~ritmo.value;

				}),
				b = StaticText().string = "Euclid Trig: " ++ ~trig.asString,
				Knob().action_({ |knb| ~trig = (knb.value * (~step- 1)) + 1;
					~trig = ~trig.asInteger;
					b.string = "Euclid Triggers: " ++ ~trig.asString;
					~pattern = ~euclid.value(~step, ~trig, ~rot);
					~ritmo.value;
				}),
				g = StaticText().string = "Euclid Rotation: " ++ ~rot.asString,
				Knob().action_({ |knb| ~rot = (knb.value * ~step);
					~rot = ~rot.asInteger;
					g.string = "Euclid Rotation: " ++ ~rot.asString;
					~pattern = ~euclid.value(~step, ~trig, ~rot);
					~ritmo.value;
				}),
				),
			VLayout(
				Button().states_([
				["Vel Loop Off", Color.gray(0.2), Color.gray(0.8)],
				["Vel Loop On", Color.gray(0.8), Color.green(0.7)]
				])
				.action_({ |btn| ~velocityLoop = btn.value;
					~velocityLoopArray = ~velocityArray;
					~velocityLoopArray = ~velocityArray.copyRange(0, ~velocityLoopLength - 1);
					~dinamica.value;
				}),
				c = StaticText().string = "Trig Probability",
				Knob().action_({ |knb| ~prob = knb.value;
					~pattern = ~euclid.value(~step, ~trig, ~rot);
					~ritmo.value;
				}),
				d = StaticText().string = "Logic (or and xor nand): " ++ ~op.asString,
				Knob().action_({ |knb| ~op = (knb.value * 3) + 1;
					~op = ~op.ceil.asInteger;
					d.string = "Logic (or and xor nand): " ++ ~op.asString;
					~pattern = ~euclid.value(~step, ~trig, ~rot);
					~ritmo.value;
				}),
				e = StaticText().string = "Trig Loop Length: " ++ ~loopLength.asString,
				Knob().action_({ |knb| ~loopLength = (knb.value * 31) + 1;
					~loopLength = ~loopLength.asInteger;
					e.string = "Trig Loop Length: " ++ ~loopLength.asString;
					~loopArray = ~randomSeq;
					~loopArray = ~loopArray.copyRange(0, ~loopLength - 1).permute(~trigPerm);
					~pattern = ~euclid.value(~step, ~trig, ~rot);
					~ritmo.value;
				}),
				f = StaticText().string = "Rhythm Permutations",
				Knob().action_({ |knb| ~trigPerm = (knb.value * (~loopLength.asInteger.clip(1, 12).factorial)).asInteger;
					~loopArray = ~randomSeq;
					~loopArray = ~loopArray.copyRange(0, ~loopLength - 1).permute(~trigPerm);
					~pattern = ~euclid.value(~step, ~trig, ~rot);
					~ritmo.value;
			})
			),
			VLayout(
				Button().states_([
				["Notes Loop Off", Color.gray(0.2), Color.gray(0.8)],
				["Notes Loop On", Color.gray(0.8), Color.green(0.7)]
			])
			.action_({ |btn| ~noteLoopOn = btn.value;
					~noteLoopArray = ~noteArray;
					~noteLoopArray = ~noteArray.copyRange(0, ~noteLoopLength - 1).permute(~notePerm);
					~melodia.value;
				}),
				h = StaticText().string = "Glide (lin|exp)",
				Knob().action_({ |knb| ~glide = (knb.value * 2) - 1;
					~melodia.value;
				}),
				i = StaticText().string = "Notes Loop Length: " ++ ~noteLoopLength.asString,
				Knob().action_({ |knb| ~noteLoopLength = (knb.value * 31).asInteger + 1;
					~noteLoopArray = ~noteArray;
					~noteLoopArray = ~noteArray.copyRange(0, ~noteLoopLength - 1).permute(~notePerm);
					i.string = "Notes Loop Length: " ++ ~noteLoopLength.asString;
					~melodia.value;
				}),
				j = StaticText().string = "Notes Permutations",
				Knob().action_({ |knb| ~notePerm = (knb.value * (~noteLoopLength.asInteger.clip(1, 12).factorial)).asInteger;
					~noteLoopArray = ~noteArray;
					~noteLoopArray = ~noteArray.copyRange(0, ~noteLoopLength - 1).permute(~notePerm);
					~melodia.value;
				}),
				k = StaticText().string = "Scale",
				Knob().action_({ |knb| ~selectScale = (knb.value * 9).asInteger + 1;
					~scale = case(
						{~selectScale == 1}, {Scale.chromatic},
						{~selectScale == 2}, {Scale.major},
						{~selectScale == 3}, {Scale.minor},
						{~selectScale == 4}, {Scale.majorPentatonic},
						{~selectScale == 5}, {Scale.minorPentatonic},
						{~selectScale == 6}, {Scale.dorian},
						{~selectScale == 7}, {Scale.lydian},
						{~selectScale == 8}, {Scale.phrygian},
						{~selectScale == 9}, {Scale.mixolydian},
						{~selectScale == 10}, {Scale.iwato},
					);
					~melodia.value;
				}),
				),
			VLayout(
				Button().states_([
				["Mod Loop Off", Color.gray(0.2), Color.gray(0.8)],
				["Mod Loop On", Color.gray(0.8), Color.green(0.7)]
				])
				.action_({ |btn| ~modulationLoopOn = btn.value;
					~modLoopArray = ~modArray;
					~modLoopArray = ~modArray.copyRange(0, ~modLoopLength - 1);
					~modulazione.value;
				}),
				l = StaticText().string = "Velocity Loop Length: " ++ ~velocityLoopLength.asString,
				Knob().action_({ |knb| ~velocityLoopLength = (knb.value * 31).asInteger + 1;
					l.string = "Velocity Loop Length: " ++ ~velocityLoopLength.asString;
					~velocityLoopArray = ~velocityArray;
					~velocityLoopArray = ~velocityArray.copyRange(0, ~velocityLoopLength - 1);
					~dinamica.value;
				}),
				p = StaticText().string = "Modulation Loop Length: " ++ ~modLoopLength.asString,
				Knob().action_({ |knb| ~modLoopLength = (knb.value * 31).asInteger + 1;
					p.string = "Modulation Loop Length: " ++ ~modLoopLength.asString;
					~modulazione.value;
				}),
				q = StaticText().string = "Modulation interpolation (lin|exp)",
				Knob().action_({ |knb| ~modLoopLength = (knb.value * 2) - 1;
					~modulazione.value;
				}),
				r = StaticText().string = "Dry/wet",
				Knob().action_({ |knb| ~dryWet = (knb.value * 2) - 1;
				Pdefn(\effect, ~dryWet);
				}),
			),
),
		HLayout(
			VLayout(
			m = StaticText().string = "Pitch Foundamental and Spread ",
			Slider2D().action_({ |sld| ~standardDev = (sld.y * 39.9) + 0.1;
			~expVal = sld.x * 126 + 1;
			~melodia.value;
			})),
			VLayout(
			n = StaticText().string = "Velocity Bias and Spread",
			Slider2D().action_({ |sld| ~velStandardDev = (sld.y * 0.9) + 0.1;
			~velExpVal = (sld.x * 0.9) + 0.1;
			~dinamica.value;
			})),
			VLayout(
			o = StaticText().string = "Modulation Bias and Spread",
			Slider2D().action_({ |sld| ~modStandardDev = (sld.y * 19.9) + 0.1;
			~modExpVal = sld.x * 18 + 2;
			~modulazione.value;
			})),
			),
));
 )



//Parte di OSC... Ci stiamo lavorando

//Funzione che aggiorna in tempo reale i parametri che prende da una stringa
(
OSCdef(\fromProcessing, { |msg|
	~step = msg[1];
	~trig = msg[2];
	~rot = msg[3];
	~prob = msg[4];
	~op = msg[5];
	~loop = msg[6];
	~loopLength = msg[7];
	~trigPerm = msg[8];


	~standardDev = msg[9];
	~expVal = msg[10];
	~glide = msg[11];
	~noteLoopOn = msg[12];
	~noteLoopLength = msg[13];
	~notePerm = msg[14];
	~selectScale = msg[15];

	~velStandardDev = msg[16];
	~velExpVal = msg[17];
	~velocityLoop = msg[18];
	~velocityLoopLength = msg[19];


	~modStandardDev = msg[20];
	~modExpVal = msg[21];
	~interpol = msg[22];
	~modulationLoopOn = msg[23];
	~modLoopLength = msg[24];
	msg[1].postln;
}, '/vars');
)

//Mando nuovi parametri da sc a sc. L'OSCdef attiverà la funzione ogni volta che arriva un nuovo parmetro.
~scport.sendMsg('/vars', 120, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
//Verifichiamo che il valore si sia aggiornato
~step;


//Non so se questa linea di codice servirà (ora sì perchè mando osc da sc).
//Potrebbe essere una cosa da implementare in processing quando si mandano i dati.
//Crea un net address (ora stiamo usando ip locale e la porta che sc sta ascoltando)
~scport = NetAddr("127.0.0.1", NetAddr.langPort);




//Isco il ricevitore dei trigger in processing deve avere questa forma. In particolare l'ID deve essere trig.
(

OSCdef(\prova, {|msc|
	msc[1].postln;
}, '/trig');

)