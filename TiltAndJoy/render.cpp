#include <Bela.h>
#include <cmath>
#include <libraries/OscReceiver/OscReceiver.h>
#include <libraries/OscSender/OscSender.h>
#include <libraries/Pipe/Pipe.h>

Pipe oscPipe;
OscSender oscSender;

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
	
	pinMode(context, 0, gSensorDigitalInput, INPUT); //set input
	
	oscSender.setup(24, std::string("192.168.6.1"));

	x = 0;
	y = 0;
	z = 1;
	digit = 0;
	return true;
}

void render(BelaContext *context, void *userData)
{
	// we normalize the x and y because the maximum value at 3.3 volts of the joystick is not 1 but 0.84
	x = analogRead(context, 0, gSensorInputx)/0.84;
	y = analogRead(context, 0, gSensorInputy)/0.84;
	z = analogRead(context, 0, gSensorInputz);
	
	digit = digitalRead(context, 0, gSensorDigitalInput);

	oscSender.newMessage("/trig").add(x).add(y).add(z).add(digit).send();
}

void cleanup(BelaContext *context, void *userData)
{

}
