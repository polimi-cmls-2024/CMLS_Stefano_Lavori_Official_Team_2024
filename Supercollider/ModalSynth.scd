s.boot
// This is essential for the synth to play
s.options.numWireBufs = 512;

(
~amp = {
	arg fundFreq, p_pose = 2, stiffness = 0;
	var i = 0;
	var n_harmonics = (20000/fundFreq).floor;
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
	a = Array.fill(250,{0});
    n_harmonics.do({
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
	var n_harmonics = (20000/fundFreq).floor;
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
	f = Array.fill(250,{0});
    n_harmonics.do({
		f[i] =(i+1)*fundFreq * (1 + detune + ((i+1).squared * variable_part));
		i = i+1;
	});
	f[0]=fundFreq;
	f;
};
)


// the SynthDef of the string
(
SynthDef(\Modal_2,{ |trig = 1, midinote = 70, modulation = 40|
	var env, amp, freq, p, x;
	// Initialization of frequency and amplitude arrays (initially all zeros), and envelope
	//amp = NamedControl.ar(\amp, Array.fill(250,{0}));
	//freq = NamedControl.ar(\freq , Array.fill(250,{0}));
    amp = ~amp.value(midinote.midicps,2,11);
    freq = ~freq.value(midinote.midicps,2,11);
	env = EnvGen.kr(Env.perc(0.01, 2, 1, curve:-4), trig, doneAction: Done.freeSelf);
	// All sine waves summed together
	x = SinOsc.ar(freq, 0, amp).sum;
	Out.ar(0,Pan2.ar(x * env,0));
}).add;
)

(
// play mode
y = Synth(\Modal_2);
//p = ~params.value(180, 2, 11);
//y.setn(\freq, p[1]);
//y.setn(\amp, p[0]);
)

s.freqscope;

