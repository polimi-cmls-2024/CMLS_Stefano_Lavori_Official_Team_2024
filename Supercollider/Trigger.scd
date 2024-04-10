s.boot;

(
//Funzione per creare il ritmo euclideo
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

//Funzione per ruotare il ritmo
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
//Creazione di un clock personalizzato, guiderà il nostro pattern
t = TempoClock(132 * 4/60);

/*f = {
	inf.do({0.coin.binaryValue.postln;
		1.yield;})
};

r = Routine(f);

r.play(t, 1)*/

//Il pattern che suonerà
p = Pbind(
	//Stessa durata per tutti gli eventi
	\dur, Pseq([1], inf, 0),
	//Si genera il ritmo e si mette in operazione logica con un random trigger
	\amp, Pdefn(\currentPtt, (Pseq(~euclid.value(8, 5, 1), inf, 0).collect({|x| (x.asBoolean.or(0.coin)).binaryValue}))).trace
);

~seq1 = p.play(t);

)

~seq1.stop;
~seq1.resume;
~seq1.reset;


//Cambia il pattern in tempo reale. Follia...

(
~randomSeq = Array.newClear(16);
16.do({|i|
	~randomSeq[i] = 0.5.coin.binaryValue;
});

~randomSeq.postln;

)



(
~step = 16;
~trig = 11;
~rot = 0;
~prob = 0.1;
~op = 1;
~loop = 0;
~loopArray = ~randomSeq.copyRange(0, ~step -1);


//Pdefn(\currentPtt, (Pseq(~euclid.value(~step, ~trig, ~rot), inf, 0).collect({|x| (x.asBoolean.or(~prob.coin)).binaryValue})));

Pdefn(\currentPtt, (Pseq(~euclid.value(~step, ~trig, ~rot), inf, 0).collect({|x|
	case(
		{~op == 1}, {if(~loop == 1, {~loopArray = ~loopArray.rotate(-1);
			x.asBoolean.or(~loopArray[~step - 2].asBoolean).binaryValue;},
		{~randomSeq = ~randomSeq.rotate(-1);
			~randomSeq.put(15, ~prob.coin.binaryValue);
			x.asBoolean.or(~randomSeq[14].asBoolean).binaryValue;
		})},
		{~op == 2}, {if(~loop == 1, {~loopArray = ~loopArray.rotate(-1);
			x.asBoolean.and(~loopArray[~step - 2].asBoolean).binaryValue;},
		{~randomSeq = ~randomSeq.rotate(-1);
			~randomSeq.put(15, ~prob.coin.binaryValue);
			x.asBoolean.and(~randomSeq[14].asBoolean).binaryValue;
		})},
		{~op == 3}, {if(~loop == 1, {~loopArray = ~loopArray.rotate(-1);
			x.asBoolean.xor(~loopArray[~step - 2].asBoolean).binaryValue;},
		{~randomSeq = ~randomSeq.rotate(-1);
			~randomSeq.put(15, ~prob.coin.binaryValue);
			x.asBoolean.xor(~randomSeq[14].asBoolean).binaryValue;
		})},
		{~op == 4}, {if(~loop == 1, {~loopArray = ~loopArray.rotate(-1);
			x.asBoolean.nand(~loopArray[~step - 2].asBoolean).binaryValue;},
		{~randomSeq = ~randomSeq.rotate(-1);
			~randomSeq.put(15, ~prob.coin.binaryValue);
			x.asBoolean.nand(~randomSeq[14].asBoolean).binaryValue;
		})},

);
})));

)