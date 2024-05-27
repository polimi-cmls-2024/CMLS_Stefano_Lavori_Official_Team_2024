#include <Bela.h>
#include <cmath>
#include <libraries/OscReceiver/OscReceiver.h>
#include <libraries/OscSender/OscSender.h>
#include <libraries/Pipe/Pipe.h>

Pipe oscPipe;
OscSender oscSender;

float gPhase;
float gInverseSampleRate;
int gAudioFramesPerAnalogFrame = 0;

// Set the analog channels to read from
int gSensorInputz = 2;
int gSensorInputy = 1;
int gSensorInputx = 0;

int gSensorDigitalInput = 0;

float x;
float y;
float z;

float digit;

bool setup(BelaContext *context, void *userData)
{

	// Check if analog channels are enabled
	if(context->analogFrames == 0 || context->analogFrames > context->audioFrames) {
		rt_printf("Error: this example needs analog enabled, with 4 or 8 channels\n");
		return false;
	}

	// Useful calculations
	if(context->analogFrames)
		gAudioFramesPerAnalogFrame = context->audioFrames / context->analogFrames;
	gInverseSampleRate = 1.0 / context->audioSampleRate;
	gPhase = 0.0;
	
	pinMode(context, 0, gSensorDigitalInput, INPUT); //set input
	
	oscSender.setup(24, std::string("192.168.6.1"));
	//oscSender.newMessage("/trig").add(3.f).send();
	x = 0;
	y = 0;
	z = 1;
	digit = 0;
	return true;
}

void render(BelaContext *context, void *userData)
{
	//for(unsigned int n = 0; n < context->audioFrames; n++) {
	//	if(gAudioFramesPerAnalogFrame && !(n % gAudioFramesPerAnalogFrame)) {
			// we normalize the x and y because the maximum value is not 1 but 0.84
			x = analogRead(context, 0, gSensorInputx)/0.84;
			y = analogRead(context, 0, gSensorInputy)/0.84;
			z = analogRead(context, 0, gSensorInputz);
	//	}
	//}
	//for(unsigned int n=0; n<context->digitalFrames; n++){
	digit = digitalRead(context, 0, gSensorDigitalInput);
	//}
	//rt_printf("x: %f y: %f z: %f Digital value: %f\n", x, y, z, digit);

	oscSender.newMessage("/trig").add(x).add(y).add(z).add(digit).send();
	//rt_printf("Sent: %f\n", x);
}

void cleanup(BelaContext *context, void *userData)
{

}
