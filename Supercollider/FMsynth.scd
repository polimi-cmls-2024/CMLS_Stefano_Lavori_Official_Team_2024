s.boot;

(
SynthDef(\fm, {
	arg freq = 440, freq_mod = 110, vel = 1, amp_mod = 300, gate = 1;
	var out, mod, sig, env;
	mod = SinOsc.ar(freq_mod, mul:amp_mod);
	env = EnvGen.kr(Env.perc(0.01, 0.5, 1, curve:-4), gate);
	sig = SinOsc.ar(freq + mod, mul:vel);

	out = Out.ar(0, sig * env);
}).add;
)

~fm = Synth(\fm);
~fm.set(\gate, 1);
~fm.set(\freq, 50);
