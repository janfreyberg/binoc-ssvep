# binoc-ssvep
Experiment for binocular rivalry with SSVEP
copyright (c) 2015 Jan Freyberg

This code will produce several trials of binocular rivalry on a single display, to be used with a mirror stereoscope. It will flicker the stimuli (gratings) at two distinct frequencies, designed to elicit distinct SSVEPs.

You may need scripts from the autism-research-centre repository `matlabGeneral`

# Experiment

Run the experiment by running `binoc_ssvep`.

The code will run:
* 1 practice block with static gratings
* 1 practice block with flickering gratings
* 16 experimental blocks with pseudorandom counterbalancing

### Variables

Change the following variables to adjust your experiment:

* `freq1/freq2`: the frequencies you want (they have to be multiples of the Screen Refresh rate, in my case 144Hz)
* `trialdur`: the duration of a trial
* `contr`, `stimsize`, `cycperdegree`: stimulus properties (Contrast, Size and Spatial Frequency)

Additionally, the following need to be accurate:

* `scr_diagonal` gives real display diagonal, in inches
* `scr_distance` is the subject's distance from the screen

Of course, you'll have to change all filepaths to suit your machine and OS.

### Triggers

The script sends a trigger to a parallel port whenever:

* The response of the participant changes (they change what button they press)
* A trial starts

The value of button-press related triggers is the decimal equivalent of a 3-digit binary vector where each digit represents one of the three buttons you use for response (left, up, right in my case)

Change the variable `address` to your port address, and adjust triggering to your liking by finding all lines that contain `outp(...)`.


# Analysis

`analyse_binoc` will analyse the data for you.

It calculates:
* The power of a frequency during perceptual phases
* The pure behavioural result of the experiment
* The signal-to-noise ratio at various electrodes
* The amplitude of the two frequencies