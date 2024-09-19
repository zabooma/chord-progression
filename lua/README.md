
# Ardour Chord Progression Script

## Introduction

This Lua script for Ardour DAW automatically generates a chord progression within selected MIDI regions. It uses location markers to define the chords in the progression, allowing you to easily create complex harmonic structures.

<img src="src/images/img.png" alt="Example 1" style="max-width:500px; border-radius: 10px;">

## Usage

1. **Create Location Markers:** Define your chord progression by creating location markers in the editor. Each marker name should start with a dot (`.`) followed by the chord symbol (e.g., `.Cmaj7`, `.Fmin`, `.G7`).
2. **Create or Select MIDI Regions:** Create empty MIDI regions or select existing ones where you want the chord progression to be generated.
3. **Name the MIDI Regions:** Rename each MIDI region to start with `#ChordProgression`. You can also add configuration parameters to the region name, as described below.
4. **Run the Script:** Select the MIDI regions containing the `#ChordProgression` prefix and run the script. It will analyze the location markers and generate MIDI notes for the specified chords within the regions.

## Configuration Parameters

You can customize the chord generation process by adding configuration parameters to the MIDI region names. These parameters are added after the `#ChordProgression` prefix and separated by whitespace. Each parameter has its values enclosed in parentheses. Here's a breakdown of the parameters:

### octave(left hand, right hand)

* **Description:** Sets the base octave for each hand.
* **Default:** `octave(3, 5)` (Left hand starts at octave 3, right hand starts at octave 5)
* **Example:** `#ChordProgression octave(4, 6)` (Left hand starts at octave 4, right hand starts at octave 6)

### hand_span(left hand, right hand)

* **Description:** Limits the maximum interval between the highest and lowest notes played by each hand. This helps to ensure playability.
* **Default:** `hand_span(13, 13)` (13 semitones for both hands)
* **Example:** `#ChordProgression hand_span(10, 12)` (Left hand has a maximum span of 10 semitones, right hand has a maximum span of 12 semitones)

### notes_per_hand(left hand, right hand)

* **Description:** Controls the maximum number of notes played simultaneously by each hand.
* **Default:** `notes_per_hand(3, 4)` (Left hand plays up to 3 notes, right hand plays up to 4 notes)
* **Example:** `#ChordProgression notes_per_hand(2, 3)` (Left hand plays up to 2 notes, right hand plays up to 3 notes)

### inversions_per_bar(left hand, right hand)

* **Description:** Defines how many times the chord inversion should change within each bar. A value of **0 means one inversion change per chord change**. A value of 1 means one inversion change at the beginning of each bar, and higher values represent multiple inversion changes per bar.
* **Default:** `inversions_per_bar(0, 0)` (One inversion change per chord change for both hands)
* **Example:** `#ChordProgression inversions_per_bar(1, 2)` (Left hand changes inversion once per bar, right hand changes inversion twice per bar)

### channel(left hand, right hand)

* **Description:** Specifies the MIDI channel for each hand.
* **Default:** `channel(0, 0)` (Both hands on MIDI channel 1)
* **Example:** `#ChordProgression channel(0, 1)` (Left hand on MIDI channel 1, right hand on MIDI channel 2)

### velocity(left hand, right hand)

* **Description:** Determines the MIDI velocity (volume) for each hand.
* **Default:** `velocity(64, 64)` (Velocity 64 for both hands)
* **Example:** `#ChordProgression velocity(80, 100)` (Left hand velocity 80, right hand velocity 100)

### note_gap(left hand, right hand)

* **Description:** Creates gaps between notes by shortening note duration by specified number of ticks. 
* **Default:** `note_gap(0, 0)` (There are no note gaps)
* **Example:** `#ChordProgression note_gap(30, 30)` (Creates note gap of 30 ticks for both hands)

## Examples

To create a chord progression with Cmaj7, Fmin, and G7 chords, starting at octave 4 for both hands, with a maximum hand span of 12 semitones, and 3 notes per hand, you would:

1. Create location markers named `.Cmaj7`, `.Fmin`, `.G7`.
2. Create a MIDI region and name it `#ChordProgression octave(4, 5) hand_span(12, 12) notes_per_hand(3, 4)`.
3. Run the script.

<img src="src/images/img_1.png" alt="Example 2" style="max-width:500px; border-radius: 10px;">

This is an example of generating a walking bass line. This is done by playing only left hand and reducing number of notes per chord to one.

Chord progression settings: `#ChordProgression octave(2,5) notes_per_hand(1, 0)  hand_span(13,13) channel(0,0) inversions_per_bar(8,2) velocity(100,0)`

<img src="src/images/img_2.png" alt="Example 3" style="max-width:500px; border-radius: 10px;">

This is an example of triplets on the right hand and walking bass on the left hand. Note gap is added for the left hand to emphasize the rhythm pattern

Chord progression settings:`#ChordProgression channel(0,1) octave(3, 5) pattern(4,12) inversions_per_bar(0,2) note_gap(40,120) notes_per_hand(1,4)`

<img src="src/images/img_3.png" alt="Example 3" style="max-width:500px; border-radius: 10px;">


## Note

The script currently supports a wide variety of chord types, including major, minor, seventh, ninth, eleventh, thirteenth, suspended, and altered chords. It also includes logic to optimize chord voicings for playability.


