from mido import Message, MidiFile, MidiTrack, MetaMessage
from mido import bpm2tempo
import random

# MIDI note number mapping
note_map = {
    'C': 60, 'C#': 61, 'Db': 61, 'D': 62, 'D#': 63, 'Eb': 63, 'E': 64,
    'F': 65, 'F#': 66, 'Gb': 66, 'G': 67, 'G#': 68, 'Ab': 68, 'A': 69,
    'A#': 70, 'Bb': 70, 'B': 71
}

# Chord types map with intervals from the root note
chord_type_map = {
    'major': [0, 4, 7],        # Major
    'minor': [0, 3, 7],        # Minor
    '7': [0, 4, 7, 10],        # Dominant 7th
    'maj7': [0, 4, 7, 11],     # Major 7th
    'min7': [0, 3, 7, 10],     # Minor 7th
    'dim': [0, 3, 6],          # Diminished
    'aug': [0, 4, 8],          # Augmented
    '7/9': [0, 4, 7, 10, 14]   # Dominant 7/9
}

class ChordProgression:
    def __init__(self):
        self.previous_chord = None
        self.previous_left_inversion = None
        self.previous_right_inversion = None
        self.previous_left_octave_adjustment = 0
        self.previous_right_octave_adjustment = 0

    def get_chord_notes(self, key, chord_type, octave=4, inversion=0):
        root_note = note_map[key] + (octave - 4) * 12
        chord_intervals = chord_type_map[chord_type]
        chord_notes = [root_note + interval for interval in chord_intervals]

        for i in range(inversion):
            chord_notes[i] += 12

        chord_notes.sort()

        #print (f"Notes for {key}{chord_type}({octave}) inversion {inversion}: {chord_notes}")

        return chord_notes

    def evaluate_inversion_blending(self, prev_notes, current_notes):
        """
        Evaluate how well the current inversion blends with the previous chord notes
        by calculating the sum of absolute differences between the notes of the two chords.
        The longer list of notes is trimmed to match the length of the shorter list.
        """
        # Sort the notes to align them properly for comparison
        prev_notes.sort()
        current_notes.sort()

        # Trim the longer list to match the length of the shorter list
        min_length = min(len(prev_notes), len(current_notes))
        _prev_notes = prev_notes[:min_length]
        _current_notes = current_notes[:min_length]

        # Calculate the sum of absolute differences between the two lists of notes
        total_difference = 0
        for prev_note, current_note in zip(_prev_notes, _current_notes):
            total_difference += abs(prev_note - current_note)

        print(f"Difference {total_difference} for prev {prev_notes} and current {current_notes}")

        return total_difference

    def choose_inversion(self, chord_str, previous_inversion=None, previous_chord=None, previous_octave_adjustment=0):
        key, chord_type = self.parse_chord(chord_str)

        print(f"Choosing inversion for {chord_str}, previous chord {previous_chord} inversion {previous_inversion} octave_adjustment {previous_octave_adjustment}")

        if previous_chord:
            prev_key, prev_chord_type = self.parse_chord(previous_chord)
            prev_notes = self.get_chord_notes(prev_key, prev_chord_type, octave=4 + previous_octave_adjustment, inversion=previous_inversion)

            best_inversion = 0
            best_octave_adjustment = 0
            min_blending = float('inf')  # Initialize with a large number

            for octave_adjustment in [-1, 0, 1]:
                for inversion in range(len(chord_type_map[chord_type])):
                    candidate_notes = self.get_chord_notes(key, chord_type, octave=4 + octave_adjustment, inversion=inversion)
                    blending = self.evaluate_inversion_blending(prev_notes, candidate_notes)

                    if (blending < min_blending) and (blending != 0):  # Ignore the same inversion of the same chord
                        best_inversion = inversion
                        best_octave_adjustment = octave_adjustment
                        best_inversion_notes = candidate_notes
                        min_blending = blending

            print(f"Best inversion {best_inversion} {best_inversion_notes} blending {min_blending} octave_adjustment {best_octave_adjustment}")

            return best_inversion, best_octave_adjustment

        else:
            # Default inversion if no previous information
            best_inversion = random.randint(0, len(chord_type_map[chord_type]))

            print(f"No previous chord, using inversion {best_inversion}")

            return best_inversion, 0

    def add_chord(self, track, chord_str, duration,
                  left_hand_octave=4, left_hand_inversion=None,
                  right_hand_octave=5, right_hand_inversion=None):

        print(f"\nAdding chord {chord_str} left_hand_octave={left_hand_octave}, left_hand_inversion={left_hand_inversion}, right_hand_octave={right_hand_octave}, right_hand_inversion={right_hand_inversion}")

        key, chord_type = self.parse_chord(chord_str)

        # Default inversions and octave adjustments if not provided
        if left_hand_inversion is None:
            left_hand_inversion, left_octave_adjustment = self.choose_inversion(
                chord_str=chord_str,
                previous_inversion=self.previous_left_inversion,
                previous_chord=self.previous_chord,
                previous_octave_adjustment=self.previous_left_octave_adjustment
            )
        else:
            left_octave_adjustment = 0

        if right_hand_inversion is None:
            right_hand_inversion, right_octave_adjustment = self.choose_inversion(
                chord_str=chord_str,
                previous_inversion=self.previous_right_inversion,
                previous_chord=self.previous_chord,
                previous_octave_adjustment=self.previous_right_octave_adjustment
            )
        else:
            right_octave_adjustment = 0

        left_hand_notes = self.get_chord_notes(key, chord_type, octave=left_hand_octave + left_octave_adjustment, inversion=left_hand_inversion)
        right_hand_notes = self.get_chord_notes(key, chord_type, octave=right_hand_octave + right_octave_adjustment, inversion=right_hand_inversion)

        # Optimize chords for playability
        left_hand_notes = self.optimize_chord(left_hand_notes, root_note=note_map[key], max_notes_per_hand=3)
        right_hand_notes = self.optimize_chord(right_hand_notes, root_note=note_map[key], max_notes_per_hand=4)

        # Ensure no overlap between left and right hand notes in the same octave
        if left_hand_notes and right_hand_notes:
            left_hand_notes = [note for note in left_hand_notes if note < min(right_hand_notes)]

        print(f"Adding chords: left {left_hand_notes}({left_hand_inversion}, octave_adjustment={left_octave_adjustment}) right {right_hand_notes}({right_hand_inversion}, octave_adjustment={right_octave_adjustment})")

        # Add note_on messages for both hands
        for note in left_hand_notes + right_hand_notes:
            track.append(Message('note_on', note=note, velocity=64, time=0))

        # Add note_off messages for both hands
        for i, note in enumerate(left_hand_notes + right_hand_notes):
            track.append(Message('note_off', note=note, velocity=64, time=int(duration) if i == 0 else 0))

        # Update the previous chord and inversions for the next chord
        self.previous_chord = chord_str
        self.previous_left_inversion = left_hand_inversion
        self.previous_right_inversion = right_hand_inversion

        # Remember octave adjustments
        self.previous_left_octave_adjustment = left_octave_adjustment
        self.previous_right_octave_adjustment = right_octave_adjustment

    # Function to parse a chord string into key and chord type
    def parse_chord(self, chord_str):
        key = chord_str[0]
        chord_type = chord_str[1:]

        # Check for sharp or flat
        if len(chord_str) > 1 and chord_str[1] in ['#', 'b']:
            key += chord_str[1]
            chord_type = chord_str[2:]

        # Default to major if chord type is not provided
        if chord_type == '':
            chord_type = 'major'

        # Validate the key and chord type
        if key not in note_map:
            raise ValueError(f"Invalid key: {key}")

        if chord_type not in chord_type_map:
            raise ValueError(f"Invalid chord type: {chord_type}")

        return key, chord_type

    def optimize_chord(self, notes, root_note, max_notes_per_hand=3, max_hand_span=13):
        notes.sort()

        while max(notes) - min(notes) > max_hand_span:
            notes.pop()

        priority_intervals = [0, 3, 4, 10]
        while len(notes) > max_notes_per_hand:
            for i, note in enumerate(notes):
                if (note - root_note) % 12 not in priority_intervals:
                    notes.pop(i)
                    break
            else:
                notes.pop()

        return notes

# Setup variables
bpm = 100
time_signature_numerator = 12
time_signature_denominator = 8
clocks_per_click = 24
notated_32nd_notes_per_beat = 8

# Calculate derived values
tempo = bpm2tempo(bpm)
standard_ticks_per_beat = 480
ticks_per_beat = int(standard_ticks_per_beat * (4 / time_signature_denominator))
ticks_per_measure = ticks_per_beat * time_signature_numerator

# Create MIDI file
mid = MidiFile()
track = MidiTrack()
mid.tracks.append(track)

# Set tempo and time signature
track.append(MetaMessage('set_tempo', tempo=tempo))
track.append(MetaMessage('time_signature',
                         numerator=time_signature_numerator,
                         denominator=time_signature_denominator,
                         clocks_per_click=clocks_per_click,
                         notated_32nd_notes_per_beat=notated_32nd_notes_per_beat))

# Create ChordProgression instance
progression = ChordProgression()

# Example chord progression
chords = [
    #("A7", 0, 1), ('D7', None, None), ("A7", 2, 3), ('D7', None, None)
    ('A7', None, None), ('D7', None, None), ('A7', None, None), ('A7', None, None),
    ('D7', None, None), ('D7', None, None), ('A7', None, None), ('A7', None, None),
    ('E7', None, None), ('D7', None, None), ('A7', None, None), ('E7', None, None)
]

# Add chords to the track
for chord, left_inversion, right_inversion in chords:
    progression.add_chord(track, chord, ticks_per_measure, left_hand_octave=3, left_hand_inversion=left_inversion, right_hand_octave=5, right_hand_inversion=right_inversion)

# Save the MIDI file
mid.save('midi_progression_v0.1.7.mid')
