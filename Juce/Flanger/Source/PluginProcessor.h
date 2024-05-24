/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin processor.

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>

#define MAX_DELAY_TIME 2



//==============================================================================
/**
*/
class FlangerAudioProcessor  : public juce::AudioProcessor,
                               public juce::OSCReceiver, 
                               public juce::OSCReceiver::ListenerWithOSCAddress<juce::OSCReceiver::RealtimeCallback>
{
public:
    //==============================================================================
    FlangerAudioProcessor();
    ~FlangerAudioProcessor() override;

    //==============================================================================
    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;

   #ifndef JucePlugin_PreferredChannelConfigurations
    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;
   #endif

    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    //==============================================================================
    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;

    //==============================================================================
    const juce::String getName() const override;

    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;

    //==============================================================================
    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram (int index) override;
    const juce::String getProgramName (int index) override;
    void changeProgramName (int index, const juce::String& newName) override;

    //==============================================================================
    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;

    /*static juce::AudioProcessorValueTreeState::ParameterLayout createParameterLayout();
    juce::AudioProcessorValueTreeState apvts{ *this, nullptr, "Parameters", createParameterLayout() };*/

    juce::dsp::WaveShaper<float> waveshaper;

    float squareWave(float x) {

        x = juce::jmap(x, (float)(-2.0f * PI), (float)(2.0f * PI), -1.0f, 1.0f);

        if (x >= -1 && x < 0) {
            x = -1;
        }
        else if (x >= 0 && x <= 1) {
            x = 1;
        }

        return x;
    }

    float triangleWave(float x) {
        x = juce::jmap(x, (float)(-2.0f * PI), (float)(2.0f * PI), -2.0f, 2.0f);
        if (x <= 0) {
            x = (x + 1) / 2;
        }
        else {    
            x = (1 - x)/ 2;
        }
        return x;
    }

    float linear_interp(float sample_x, float sample_x1, float inPhase) {
        return (1 - inPhase) * sample_x + inPhase * sample_x1;
    }

    void oscMessageReceived(const juce::OSCMessage& message) override;

private:
    //==============================================================================
    float PI = juce::MathConstants<float>::pi;

    float LFO_phase;
    float delayTimeSmooth_l;
    float delayTimeSmooth_r;
    float delayTimeSamples_l;
    float delayTimeSamples_r;
    float feedback_l = 0;
    float feedback_r = 0;
    float delayReadHead_l;
    float delayReadHead_r;
    float LFO_out = 0;
    float drive_l = 0;
    float drive_r = 0;
    float lfoOutMapped;

    int circularBufferLength;
    int circularBufferWriteHead;
    std::unique_ptr<float> circularBufferLeft = nullptr;
    std::unique_ptr<float> circularBufferRight = nullptr;

    juce::dsp::ProcessSpec spec;

    juce::dsp::Limiter<float> limiter;

    juce::Array<float> params;
    

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (FlangerAudioProcessor)
};
