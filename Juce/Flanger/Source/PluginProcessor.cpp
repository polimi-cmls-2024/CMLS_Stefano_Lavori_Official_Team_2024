/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin processor.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
FlangerAudioProcessor::FlangerAudioProcessor()
#ifndef JucePlugin_PreferredChannelConfigurations
    : AudioProcessor(BusesProperties()
#if ! JucePlugin_IsMidiEffect
#if ! JucePlugin_IsSynth
        .withInput("Input", juce::AudioChannelSet::stereo(), true)
#endif
        .withOutput("Output", juce::AudioChannelSet::stereo(), true)
#endif
    )
#endif
{
    params.resize(8);

    //OSC functions
    connect(9001);
    juce::OSCReceiver::addListener(this, "/flangerParams");
}

FlangerAudioProcessor::~FlangerAudioProcessor()
{
}

//==============================================================================
const juce::String FlangerAudioProcessor::getName() const
{
    return JucePlugin_Name;
}

bool FlangerAudioProcessor::acceptsMidi() const
{
#if JucePlugin_WantsMidiInput
    return true;
#else
    return false;
#endif
}

bool FlangerAudioProcessor::producesMidi() const
{
#if JucePlugin_ProducesMidiOutput
    return true;
#else
    return false;
#endif
}

bool FlangerAudioProcessor::isMidiEffect() const
{
#if JucePlugin_IsMidiEffect
    return true;
#else
    return false;
#endif
}

double FlangerAudioProcessor::getTailLengthSeconds() const
{
    return 0.0;
}

int FlangerAudioProcessor::getNumPrograms()
{
    return 1;   // NB: some hosts don't cope very well if you tell them there are 0 programs,
    // so this should be at least 1, even if you're not really implementing programs.
}

int FlangerAudioProcessor::getCurrentProgram()
{
    return 0;
}

void FlangerAudioProcessor::setCurrentProgram(int index)
{
}

const juce::String FlangerAudioProcessor::getProgramName(int index)
{
    return {};
}

void FlangerAudioProcessor::changeProgramName(int index, const juce::String& newName)
{
}

//==============================================================================
void FlangerAudioProcessor::prepareToPlay(double sampleRate, int samplesPerBlock)
{
    // Use this method as the place to do any pre-playback
    // initialisation that you need

    spec.sampleRate = sampleRate;
    spec.maximumBlockSize = samplesPerBlock;
    spec.numChannels = getNumInputChannels();

    LFO_phase = 0;

    circularBufferLength = sampleRate * MAX_DELAY_TIME;

    circularBufferLeft.reset(new float[circularBufferLength]);
    juce::zeromem(circularBufferLeft.get(), circularBufferLength * sizeof(float));
    circularBufferRight.reset(new float[circularBufferLength]);
    juce::zeromem(circularBufferRight.get(), circularBufferLength * sizeof(float));

    circularBufferWriteHead = 0;

    delayTimeSmooth_l = 1;
    delayTimeSmooth_r = 1;

    l_smoother.reset(1);
    r_smoother.reset(1);
}

void FlangerAudioProcessor::releaseResources()
{
    // When playback stops, you can use this as an opportunity to free up any
    // spare memory, etc.
}

#ifndef JucePlugin_PreferredChannelConfigurations
bool FlangerAudioProcessor::isBusesLayoutSupported(const BusesLayout& layouts) const
{
#if JucePlugin_IsMidiEffect
    juce::ignoreUnused(layouts);
    return true;
#else
    // This is the place where you check if the layout is supported.
    // In this template code we only support mono or stereo.
    // Some plugin hosts, such as certain GarageBand versions, will only
    // load plugins that support stereo bus layouts.
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
        && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

    // This checks if the input layout matches the output layout
#if ! JucePlugin_IsSynth
    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;
#endif

    return true;
#endif
}
#endif

void FlangerAudioProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;
    auto totalNumInputChannels = getTotalNumInputChannels();
    auto totalNumOutputChannels = getTotalNumOutputChannels();

    // In case we have more outputs than inputs, this code clears any output
    // channels that didn't contain input data, (because these aren't
    // guaranteed to be empty - they may contain garbage).
    // This is here to avoid people getting screaming feedback
    // when they first compile a plugin, but obviously you don't need to keep
    // this code if your algorithm always overwrites all the output channels.
    for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
        buffer.clear(i, 0, buffer.getNumSamples());

    // This is the place where you'd normally do the guts of your plugin's
    // audio processing...
    // Make sure to reset the state if your inner loop is processing
    // the samples and the outer loop is handling the channels.
    // Alternatively, you can process the samples with the channels
    // interleaved by keeping the same state.

    juce::dsp::AudioBlock<float> block(buffer);
    
    auto leftChannel = block.getSingleChannelBlock(0);
    auto rightChannel = block.getSingleChannelBlock(1);


    //juce::dsp::ProcessContextReplacing<float> leftContext(leftChannel);

    int waveType = apvts.getRawParameterValue("Wave Type")->load();
    float rate = apvts.getRawParameterValue("Rate")->load();
    float depth = apvts.getRawParameterValue("Depth")->load();
    float feedback = apvts.getRawParameterValue("Feedback")->load();
    float width = apvts.getRawParameterValue("Width")->load();
    float drywet = apvts.getRawParameterValue("Dry/Wet")->load();
    float color = apvts.getRawParameterValue("Color")->load();
    float stereo = apvts.getRawParameterValue("Stereo")->load();

    if(oscNew)
    {
        waveType = (int)params[0];
        rate = params[1];
        depth = params[2];
        feedback = params[3];
        width = params[4];
        drywet = params[5];
        color = params[6];
        stereo = params[7];
    
        rate = juce::mapToLog10(rate / 100, 0.1f, 20000.0f);
        width = juce::jmap(width, 0.0f, 100.0f, 0.001f, 0.015f);
    }


    if (feedback == 1)
        feedback = 0.95;

    if (waveType != 0)
        rate *= 2;
    

    for (int sample = 0; sample < buffer.getNumSamples(); ++sample)
    {

        //LFO waveform selection
        if (waveType == 0)
            LFO_out = std::sin(2 * PI * LFO_phase);
        else if (waveType == 1)
            LFO_out = squareWave(LFO_phase);
        else if (waveType == 2)
            LFO_out = triangleWave(LFO_phase);
        else if (waveType == 3)
            LFO_out = LFO_phase;

        LFO_phase += rate / getSampleRate(); //update LFO phase

        if (LFO_phase > 1.0f)
        {
            LFO_phase = -1.0f;
        }

        LFO_out *= depth; //scale on depth

        lfoOutMapped = juce::jmap(LFO_out, -1.0f, 1.0f, 0.000f, width); //map in ms

        //calculate delay time
        delayTimeSmooth_l = delayTimeSmooth_l - 0.001 * (delayTimeSmooth_l - lfoOutMapped);
        delayTimeSmooth_r = delayTimeSmooth_r - 0.001 * (delayTimeSmooth_r - lfoOutMapped - (0.005 * stereo));
        delayTimeSamples_l = delayTimeSmooth_l * getSampleRate();
        delayTimeSamples_r = delayTimeSmooth_r * getSampleRate();

        //add sample plus feedback to each circular buffer
        circularBufferLeft.get()[circularBufferWriteHead] = leftChannel.getSample(0,sample) + feedback_l;
        circularBufferRight.get()[circularBufferWriteHead] = rightChannel.getSample(0,sample) + feedback_r;

        //indexes to navigate circular buffer for delayed samples
        delayReadHead_l = circularBufferWriteHead - delayTimeSamples_l;
        delayReadHead_r = circularBufferWriteHead - delayTimeSamples_r;

        //wrapping
        if (delayReadHead_l < 0) {
            delayReadHead_l = circularBufferLength + delayReadHead_l;
        }
        if (delayReadHead_r < 0) {
            delayReadHead_r = circularBufferLength + delayReadHead_r;
        }

        //get the actual flanged samples
        float delay_sample_left = std::tanh(circularBufferLeft.get()[(int)delayReadHead_l] + buffer.getSample(0, sample));
        float delay_sample_right = std::tanh(circularBufferRight.get()[(int)delayReadHead_r] + buffer.getSample(1, sample));      

        //calculate feedbacks for next sample
        feedback_l = delay_sample_left * feedback;
        feedback_r = delay_sample_right * feedback;
        
        //overdrive feedback
        drive_l = std::pow(2, feedback_l) - 1;
        drive_r = std::pow(2, feedback_r) - 1;

        feedback_l = (1 - color) * feedback_l + color * drive_l;
        feedback_r = (1 - color) * feedback_r + color * drive_r;
        
        //smoothing on the outputs
        l_smoother.setTargetValue(buffer.getSample(0, sample) * (1 - (drywet)) + delay_sample_left * (drywet));
        r_smoother.setTargetValue(buffer.getSample(1, sample) * (1 - (drywet)) + delay_sample_right * (drywet));

        //set outputs
        leftChannel.setSample(0, sample, l_smoother.getNextValue());
        rightChannel.setSample(0, sample, r_smoother.getNextValue());

        //increment on buffer head for next cycle
        circularBufferWriteHead++;
        if (circularBufferWriteHead >= circularBufferLength) {
            circularBufferWriteHead = 0;
        }  
    }
}

//==============================================================================
bool FlangerAudioProcessor::hasEditor() const
{
    return true; // (change this to false if you choose to not supply an editor)
}

juce::AudioProcessorEditor* FlangerAudioProcessor::createEditor()
{
    //return new FlangerAudioProcessorEditor (*this);
    return new juce::GenericAudioProcessorEditor(*this); //testing editor
}

//==============================================================================
void FlangerAudioProcessor::getStateInformation(juce::MemoryBlock& destData)
{
    // You should use this method to store your parameters in the memory block.
    // You could do that either as raw data, or use the XML or ValueTree classes
    // as intermediaries to make it easy to save and load complex data.
}

void FlangerAudioProcessor::setStateInformation(const void* data, int sizeInBytes)
{
    // You should use this method to restore your parameters from this memory block,
    // whose contents will have been created by the getStateInformation() call.
}

//function to handle OSC messages
void FlangerAudioProcessor::oscMessageReceived(const juce::OSCMessage& message)
{
    if (message.size() == 8)
    {
        params.set(0, message[0].getFloat32());
        params.set(1, message[1].getFloat32());
        params.set(2, message[2].getFloat32());
        params.set(3, message[3].getFloat32());
        params.set(4, message[4].getFloat32());
        params.set(5, message[5].getFloat32());
        params.set(6, message[6].getFloat32());
        params.set(7, message[7].getFloat32());

        oscNew = true;
    }   
}

juce::AudioProcessorValueTreeState::ParameterLayout
FlangerAudioProcessor::createParameterLayout()
{
    juce::AudioProcessorValueTreeState::ParameterLayout layout;

    juce::StringArray waveType(
        "Sine",
        "Square",
        "Triangle",
        "Sawtooth"
    );

    layout.add(std::make_unique<juce::AudioParameterChoice>(
        "Wave Type", //ID
        "Wave Type", //Name
        waveType,
        0)); //default value

    layout.add(std::make_unique<juce::AudioParameterFloat>(
        "Rate", //ID
        "Rate", //Name
        juce::NormalisableRange<float>(0.1f, 20000.f, 0.1f, 0.15f), //min, max, increment, skew factor
        0.5f)); //default value

    layout.add(std::make_unique<juce::AudioParameterFloat>(
        "Depth", //ID
        "Depth", //Name
        juce::NormalisableRange<float>(0.1f, 1.f, 0.1f, 1.f), //min, max, increment, skew factor
        0.7f)); //default value

    layout.add(std::make_unique<juce::AudioParameterFloat>(
        "Feedback", //ID
        "Feedback", //Name
        juce::NormalisableRange<float>(0.f, 1.f, 0.1f, 1.f), //min, max, increment, skew factor
        0.5f)); //default value

    layout.add(std::make_unique<juce::AudioParameterFloat>(
        "Width", //ID
        "Width", //Name
        juce::NormalisableRange<float>(0.001f, 0.015f, 0.001f, 1.f), //min, max, increment, skew factor
        0.005f)); //default value

    layout.add(std::make_unique<juce::AudioParameterFloat>(
        "Dry/Wet", //ID
        "Dry/Wet", //Name
        juce::NormalisableRange<float>(0.f, 1.f, 0.1f, 1.f), //min, max, increment, skew factor
        0.f)); //default value

    layout.add(std::make_unique<juce::AudioParameterFloat>(
        "Color", //ID
        "Color", //Name
        juce::NormalisableRange<float>(0.f, 1.f, 0.1f, 1.f), //min, max, increment, skew factor
        0.f)); //default value

    layout.add(std::make_unique<juce::AudioParameterFloat>(
        "Stereo", //ID
        "Stereo", //Name
        juce::NormalisableRange<float>(0.f, 1.f, 0.1f, 1.f), //min, max, increment, skew factor
        1.0f)); //default value

    return layout;
}

//==============================================================================
// This creates new instances of the plugin..
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new FlangerAudioProcessor();
}
