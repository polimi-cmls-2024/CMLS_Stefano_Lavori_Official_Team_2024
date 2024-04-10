s.boot
//SinOsc.ar(2*pi*freq)* amp *EnvGen.kr(Env.perc(0.005, 4, 1, -4.5),doneAction: 2));
(
SynthDef(\Modal,{
	var freq = ~freq;
	var amp = ~amp;
	var out ;
	out = Klank.ar(`[freq,amp,nil],Impulse.ar(2,0,0.1));
	Out.ar(0,Pan2.ar(out,0));
}).add;
)

(
~params = {
	arg fundFreq, p_pose;
	var n_harmonics = (20000/fundFreq).floor;

	f = Array.fill(n_harmonics, {arg i; (i+1)*fundFreq});
	a = Array.fill(n_harmonics, {arg i;
		((2*p_pose.squared)/(squared(i+1)*pi.squared*(p_pose-1)))*sin((i+1)*pi/p_pose)});
    a = a.normalizeSum;
	[a,f]
};
)


(
p = ~params.value(440,2);
~freq = p[1];
~amp = p[0];
Synth(\Modal);

//play({ Klank.ar(`[p[1],p[0],nil],Impulse.ar(2,0,0.1));})
)

s.freqscope;
