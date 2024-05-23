/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin processor.

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>

#define MAX_DELAY_TIME 2

const float PI = juce::MathConstants<float>::pi;


//==============================================================================
/**
*/
struct ChainSettings
{
    int waveType;
    float rate, depth;
    float feedback, width, drywet, color, stereo;
};

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
        x = (1 - x) / 2;
    }
    return x;
}

ChainSettings getChainSettings(juce::AudioProcessorValueTreeState& apvts);

template <typename Type>
class LFO
{
public:
    LFO(){}

    /*void changeWaveform(int newValue)
    {

        switch (newValue) {
        case 0:
            osc.initialise([](Type x) {return std::sin(x); }, 128);
            break;
        case 1:
            osc.initialise([](Type x) {return squareWave(2 * PI * x);});
            break;
        case 2:
            osc.initialise([](Type x) {return triangleWave(2 * PI * x);});
            break;
        case 3:
            osc.initialise([](Type x) {return juce::jmap((2.0f * PI * x), (-2.0f * PI), (2.0f * PI), -1.0f, 1.0f);}, 2);
            break;
        default:
            jassertfalse;
            break;
        }
    }

    void setRate(Type newValue)
    {
        osc.setFrequency(newValue);
    }*/

    void updateParams(ChainSettings settings)
    {
        /*changeWaveform(settings.waveType);
        setRate(settings.rate);*/
        rate = settings.rate;
        waveType = settings.waveType;
    }

    /*void reset()
    {
        osc.reset();
    }*/

    float getLFOOut()
    {
        float LFO_out;
        //LFO waveform selection
        if (waveType == 0)
            //LFO_out = std::sin(2 * juce::MathConstants<float>::pi * LFO_phase);
            LFO_out = std::sin(2 * PI * LFO_phase);
        else if (waveType == 1)
            LFO_out = squareWave(2 * PI * LFO_phase);
        else if (waveType == 2)
            LFO_out = triangleWave(2 * PI * LFO_phase);
        else if (waveType == 3)
            LFO_out = juce::jmap((2.0f * PI * LFO_phase), ( - 2.0f * PI), (2.0f * PI), -1.0f, 1.0f);


        //LFO_out = std::sin(2 * PI * LFO_phase);

        LFO_phase += rate / specs.sampleRate; //update LFO phase

        if (LFO_phase > 1)
        {
            LFO_phase = -1;
        }
        return LFO_out;
    }

    //template <typename ProcessContext>
    //void process(const ProcessContext& context) noexcept
    //{
    //    //osc.process(context)
    //    auto& inputBlock = context.getInputBlock();
    //    auto& outputBlock = context.getOutputBlock();
    //    auto numSamples = outputBlock.getNumSamples();
    //    auto numChannels = outputBlock.getNumChannels();

    //    jassert(inputBlock.getNumSamples() == numSamples);
    //    jassert(inputBlock.getNumChannels() == numChannels);

    //    for (int ch = 0; ch < numChannels; ch++)
    //    {
    //        auto* input = inputBlock.getChannelPointer(ch);
    //        auto* output = outputBlock.getChannelPointer(ch);

    //        for (int sample = 0; sample < numSamples; sample++)
    //        {
    //            auto drySample = input[sample];
    //            auto inSample = drySample;

    //            //LFO waveform selection
    //            if (waveType == 0)
    //                //LFO_out = std::sin(2 * juce::MathConstants<float>::pi * LFO_phase);
    //                LFO_out = std::sin(2 * PI * LFO_phase);
    //            else if (waveType == 1)
    //                LFO_out = squareWave(2 * PI * LFO_phase);
    //            else if (waveType == 2)
    //                LFO_out = triangleWave(2 * PI * LFO_phase);
    //            else if (waveType == 3)
    //                LFO_out = juce::jmap((2.0f * PI * LFO_phase), ( - 2.0f * PI), (2.0f * PI), -1.0f, 1.0f);
    //        }
    //    }
    //}

    void prepare(const juce::dsp::ProcessSpec& spec)
    {
        specs = spec
    }

private:
    //=======================================================
    //juce::dsp::Oscillator<float> osc;
    float LFO_phase = 0;
    float waveType, rate;
    float phase;
    juce::dsp::ProcessSpec specs;
};

template <typename Type>
class DelayLine
{
public:
    void clear() noexcept
    {
        std::fill(rawData.begin(), rawData.end(), Type(0));
    }

    size_t size() const noexcept
    {
        return rawData.size();
    }

    void resize(size_t newValue)
    {
        rawData.resize(newValue);
        leastRecentIndex = 0;
    }

    Type back() const noexcept
    {
        return rawData[leastRecentIndex];
    }

    Type get(size_t delayInSamples) const noexcept
    {
        jassert(delayInSamples >= 0 && delayInSamples < size());

        return rawData[(leastRecentIndex + 1 + delayInSamples) % size()];   // [3]
    }

    /** Set the specified sample in the delay line */
    void set(size_t delayInSamples, Type newValue) noexcept
    {
        jassert(delayInSamples >= 0 && delayInSamples < size());

        rawData[(leastRecentIndex + 1 + delayInSamples) % size()] = newValue; // [4]
    }

    /** Adds a new value to the delay line, overwriting the least recently added sample */
    void push(Type valueToAdd) noexcept
    {
        rawData[leastRecentIndex] = valueToAdd;                                         // [1]
        leastRecentIndex = leastRecentIndex == 0 ? size() - 1 : leastRecentIndex - 1;   // [2]
    }


    void updateParams(ChainSettings settings)
    {
        depth = settings.depth;
        width = settings.width;
        feedback = settings.feedback;
        color = settings.color;
        stereo = settings.stereo;
        drywet = settings.drywet;

        if (feedback == 1.0f)
        {
            feedback = 0.95f;
        }
        lfo.updateParams(settings);
    }

    /*void reset()
    {
        delayTimeSmooth = 1;


        clear()
    }*/

    
    template <typename ProcessContext>
    void process(const ProcessContext& context) noexcept
    {
        auto& inputBlock = context.getInputBlock();
        auto& outputBlock = context.getOutputBlock();
        auto numSamples = outputBlock.getNumSamples();
        auto numChannels = outputBlock.getNumChannels();

        jassert(inputBlock.getNumSamples() == numSamples);
        jassert(inputBlock.getNumChannels() == numChannels);





        for (int ch = 0; ch < numChannels; ch++)
        {
            auto* input = inputBlock.getChannelPointer(ch);
            auto* output = outputBlock.getChannelPointer(ch);

            float st = 0;
            
            if (ch == 1)
            {
                st = 0.005 * stereo;
            }

            for (int sample = 0; sample < numSamples; sample++)
            {
                LFOout = lfo.getLFOOut();

                auto drySample = input[sample];
                auto inSample = drySample;
                inSample *= depth;
                inSample = juce::jmap(inSample, -1.f, 1.f, 0.0001f, width);

                delayTimeSmooth = delayTimeSmooth - 0.001 * (delayTimeSmooth - inSample - st);
                delayTimeSamples = delayTimeSmooth * specs.sampleRate;

                drive = std::pow(2, fbck) - 1;

                fbck = std::tanh((1 - color) * fbck + color * drive);

                inSample += fbck;

                push(inSample);

                delay_sample = get(delayTimeSamples) + inSample;

                fbck = delay_sample * feedback;

                output[sample] = drySample * (1-drywet) + delay_sample * drywet;
            }
        }
    }

    void prepare(const juce::dsp::ProcessSpec& spec)
    {
        specs = spec;
        resize(MAX_DELAY_TIME * specs.sampleRate);
    }

private:
    std::vector<Type> rawData;
    size_t leastRecentIndex = 0;
    
    float depth, width, feedback, color, stereo, drywet;

    float fbck;
    float drive;
    float delay_sample;
    float LFOout;

    float delayTimeSmooth = 1.f;
    float delayTimeSamples = 0.f;

    LFO<float> lfo;
    juce::dsp::Limiter<float> limiter;
    juce::dsp::ProcessSpec specs;
};

template <typename Type>
class Flanger
{
public:
    Flanger()
    {

    }
    void prepare(const juce::dsp::ProcessSpec& spec)
    {
        processorChain.prepare(spec);
    }

    //==============================================================================
    template <typename ProcessContext>
    void process(const ProcessContext& context) noexcept
    {
        processorChain.process(context);
    }

    //==============================================================================
    void reset() noexcept
    {
        processorChain.reset();
    }

    void setParameters(ChainSettings settings)
    {
        //processorChain.template get<lfoIndex>().updateParams(settings);
        processorChain.template get<dlIndex>().updateParams(settings);
    }

private:
    juce::dsp::ProcessorChain<DelayLine<Type>> processorChain;

    enum
    {
        //lfoIndex,
        dlIndex,
    };
};

class FlangerAudioProcessor : public juce::AudioProcessor
{
public:
    //==============================================================================
    FlangerAudioProcessor();
    ~FlangerAudioProcessor() override;

    //==============================================================================
    void prepareToPlay(double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;

#ifndef JucePlugin_PreferredChannelConfigurations
    bool isBusesLayoutSupported(const BusesLayout& layouts) const override;
#endif

    void processBlock(juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

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
    void setCurrentProgram(int index) override;
    const juce::String getProgramName(int index) override;
    void changeProgramName(int index, const juce::String& newName) override;

    //==============================================================================
    void getStateInformation(juce::MemoryBlock& destData) override;
    void setStateInformation(const void* data, int sizeInBytes) override;

    static juce::AudioProcessorValueTreeState::ParameterLayout createParameterLayout();
    juce::AudioProcessorValueTreeState apvts{ *this, nullptr, "Parameters", createParameterLayout() };

    juce::dsp::WaveShaper<float> waveshaper;

    /*float linear_interp(float sample_x, float sample_x1, float inPhase) {
        return (1 - inPhase) * sample_x + inPhase * sample_x1;
    }*/



private:
    //==============================================================================


    //float LFO_phase;
    //float delayTimeSmooth_l;
    //float delayTimeSmooth_r;
    //float delayTimeSamples_l;
    //float delayTimeSamples_r;
    //float feedback_l = 0;
    //float feedback_r = 0;
    //float delayReadHead_l;
    //float delayReadHead_r;
    //float LFO_out = 0;
    //float drive_l = 0;
    //float drive_r = 0;
    //float lfoOutMapped;

    //int circularBufferLength;
    //int circularBufferWriteHead;
    //std::unique_ptr<float> circularBufferLeft = nullptr;
    //std::unique_ptr<float> circularBufferRight = nullptr;

    juce::dsp::ProcessSpec spec;

    Flanger<float> flanger;

    //LFO<float> lfo;
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(FlangerAudioProcessor)
};
