ardour { ["type"] = "EditorAction", name = "[A] Chord progression",
         license = "MIT",
         author = "Frank Povazanj",
         description = [[Creates chord progression based on the chords defined in the location markers. v0.0.2]]
}

function icon (params)
    return function(ctx, width, height, fg)
        local txt = Cairo.PangoLayout(ctx, "ArdourMono " .. math.ceil(height / 3) .. "px")
        txt:set_text("CP")
        local tw, th = txt:get_pixel_size()
        ctx:set_source_rgba(ARDOUR.LuaAPI.color_to_rgba(fg))
        ctx:move_to(.5 * (width - tw), .5 * (height - th))
        txt:show_in_cairo_context(ctx)
    end
end

function factory ()
    return function()

        function getRelevantChords(region, chord_markers)
            -- Extract items from chord_markers where marker start >= region start and marker start < region start + length
            local region_position = region:position():beats()
            local region_end = region_position + region:length():beats()
            local relevant_chord_markers = {}

            print("Region '" .. region:name() .. "' start time", region:start():beats(), " position ", region_position)
            print("Region length", region:length():beats())

            for _, marker in ipairs(chord_markers) do
                local marker_start = marker:start():beats()
                if marker_start >= region_position and marker_start < region_end then
                    table.insert(relevant_chord_markers, marker)
                end
            end

            print("Relevant chord markers")
            for i, marker in ipairs(relevant_chord_markers) do
                print(i, marker:name(), marker:start():beats())
            end

            return relevant_chord_markers
        end

        function getAllChordMarkers()
            -- iterate over all location markers
            local loc = Session:locations() -- all marker locations
            local chordMarkers = {}
            for l in loc:list():iter() do
                -- Chord markers are prefixed with .
                if l:name():sub(0, 1) == "." then
                    print("Found a chord marker", l:name(), l:start():beats())
                    table.insert(chordMarkers, l)
                end
            end

            table.sort(chordMarkers, function(a, b)
                return a:start() < b:start()
            end)

            print("Chord markers")
            -- Iterate using ipairs
            for i, chord in ipairs(chordMarkers) do
                print(i, chord:name(), chord:start():beats())
            end

            return chordMarkers
        end

        -- Lua version of note_map for MIDI note numbers
        note_map = {
            ['C'] = 60, ['C#'] = 61, ['Db'] = 61, ['D'] = 62, ['D#'] = 63, ['Eb'] = 63, ['E'] = 64,
            ['F'] = 65, ['F#'] = 66, ['Gb'] = 66, ['G'] = 67, ['G#'] = 68, ['Ab'] = 68, ['A'] = 69,
            ['A#'] = 70, ['Bb'] = 70, ['B'] = 71
        }

        -- chord_type_map with intervals from root note
        chord_type_map = {
            -- Basic triads and seventh chords
            ['major'] = { 0, 4, 7 },
            ['maj'] = { 0, 4, 7 },
            ['minor'] = { 0, 3, 7 },
            ['min'] = { 0, 3, 7 },
            ['m'] = { 0, 3, 7 },
            ['7'] = { 0, 4, 7, 10 },
            ['maj7'] = { 0, 4, 7, 11 },
            ['min7'] = { 0, 3, 7, 10 },
            ['m7'] = { 0, 3, 7, 10 },
            ['dim'] = { 0, 3, 6 },
            ['aug'] = { 0, 4, 8 },

            -- Ninth, eleventh, and thirteenth chords
            ['7/9'] = { 0, 4, 7, 10, 14 },
            ['9'] = { 0, 4, 7, 10, 14 },
            ['min9'] = { 0, 3, 7, 10, 14 },
            ['m9'] = { 0, 3, 7, 10, 14 },
            ['maj9'] = { 0, 4, 7, 11, 14 },
            ['11'] = { 0, 4, 7, 10, 14, 17 },
            ['maj11'] = { 0, 4, 7, 11, 14, 17 },
            ['min11'] = { 0, 3, 7, 10, 14, 17 },
            ['m11'] = { 0, 3, 7, 10, 14, 17 },
            ['13'] = { 0, 4, 7, 10, 14, 17, 21 },
            ['maj13'] = { 0, 4, 7, 11, 14, 21 },
            ['min13'] = { 0, 3, 7, 10, 14, 21 },
            ['m13'] = { 0, 3, 7, 10, 14, 21 },

            -- Altered dominants
            ['7b5'] = { 0, 4, 6, 10 },
            ['7#5'] = { 0, 4, 8, 10 },
            ['7b9'] = { 0, 4, 7, 10, 13 },
            ['7#9'] = { 0, 4, 7, 10, 15 },
            ['7b13'] = { 0, 4, 7, 10, 20 },
            ['7#11'] = { 0, 4, 7, 10, 18 },

            -- Added tone chords
            ['add9'] = { 0, 4, 7, 14 },
            ['min(add9)'] = { 0, 3, 7, 14 },
            ['add11'] = { 0, 4, 7, 17 },
            ['add13'] = { 0, 4, 7, 21 },
            ['min(add11)'] = { 0, 3, 7, 17 },

            -- Suspended chords
            ['sus2'] = { 0, 2, 7 },
            ['sus4'] = { 0, 5, 7 },
            ['sus2/b7'] = { 0, 2, 7, 10 },
            ['sus4/b7'] = { 0, 5, 7, 10 },

            -- Complex chords
            ['maj7#11'] = { 0, 4, 7, 11, 18 },
            ['min(maj7)'] = { 0, 3, 7, 11 },
            ['dim(maj7)'] = { 0, 3, 6, 11 },
            ['7b13'] = { 0, 4, 7, 10, 20 },

            -- Diminished and augmented variations
            ['dim7'] = { 0, 3, 6, 9 },
            ['min7b5'] = { 0, 3, 6, 10 },
            ['aug7'] = { 0, 4, 8, 10 }
        }

        -- Function to print the contents of a table, with a prefix for each line
        function print_table(tbl)
            local result = {}

            -- Check if the table is a list by checking if numeric indices are consecutive
            local is_list = true
            local index = 1
            for k, _ in pairs(tbl) do
                if k ~= index then
                    is_list = false
                    break
                end
                index = index + 1
            end

            -- If it's a list, process the values
            if is_list then
                for _, v in ipairs(tbl) do
                    if type(v) == "table" then
                        table.insert(result, print_table(v))
                    else
                        table.insert(result, tostring(v))
                    end
                end
            else
                -- Otherwise, process key-value pairs
                for k, v in pairs(tbl) do
                    if type(v) == "table" then
                        table.insert(result, tostring(k) .. ": " .. print_table(v))
                    else
                        table.insert(result, tostring(k) .. ": " .. tostring(v))
                    end
                end
            end

            return "{" .. table.concat(result, ", ") .. "}"
        end

        -- Function to get chord notes based on key, chord type, and inversion
        function get_chord_notes(key, chord_type, octave, inversion)

            -- If we have an invalid key or chord_str return an empty list of notes
            if not note_map[string.upper(key)] then
                return {}
            end
            local root_note = note_map[string.upper(key)] + (octave - 4) * 12
            local chord_intervals = table.getIgnoreCase(chord_type_map, chord_type)
            if not chord_intervals then
                return {}
            end

            local chord_notes = {}

            -- Calculate chord notes with inversion
            for i, interval in ipairs(chord_intervals) do
                local note = root_note + interval
                table.insert(chord_notes, note)
            end

            -- Apply inversion (shift notes)
            for i = 1, inversion do
                chord_notes[i] = chord_notes[i] + 12
            end

            -- Sort the chord notes to maintain proper order
            table.sort(chord_notes)

            return chord_notes
        end

        -- Function to parse the chord string into key and chord type
        function parse_chord(chord_str)
            local key = chord_str:sub(1, 1)
            local chord_type = chord_str:sub(2)

            -- Check for sharp or flat in key
            if #chord_str > 1 and (chord_str:sub(2, 2) == "#" or chord_str:sub(2, 2) == "b") then
                key = chord_str:sub(1, 2)
                chord_type = chord_str:sub(3)
            end

            -- Default to major if no chord type is provided
            if chord_type == "" then
                chord_type = "major"
            end

            -- Validate the key and chord type
            if not note_map[string.upper(key)] then
                print("Invalid key: " .. key)
            end

            if not table.getIgnoreCase(chord_type_map, chord_type) then
                print("Invalid chord type: " .. chord_type)
            end

            return key, chord_type
        end

        -- Function to generate the run pattern based on time signature and octave drift
        function createUpArp(chordNotes, hand_config)
            local initialCycleNotes = math.abs(hand_config.pattern)   -- Total number of notes
            local initialOctaveDrift = hand_config.octave_drift       -- Initial octave drift
            local maxOctaveDrift = hand_config.max_octave_drift or 5  -- Maximum allowable octave drift
            local timeSignature = hand_config.time_signature          -- e.g., {4, 4} for 4/4 time
            local durationInMeasures = hand_config.measures or 1      -- Duration of the arpeggio in measures

            -- Step 1: Calculate total beats and notes per beat
            local beatsPerMeasure = timeSignature[1]
            local totalBeats = beatsPerMeasure * durationInMeasures
            local notesPerBeat = initialCycleNotes / totalBeats

            -- Ensure notesPerBeat is an integer
            if notesPerBeat ~= math.floor(notesPerBeat) then
                print("The total number of notes does not divide evenly into the total beats.")
                notesPerBeat = math.ceil(notesPerBeat)
            end

            -- Step 2: Calculate beats per run
            local beatsPerRun = initialOctaveDrift + 1

            -- Ensure beatsPerRun divides evenly into totalBeats
            if totalBeats % beatsPerRun ~= 0 then
                print("The total beats do not divide evenly into beats per run.")
            end

            -- Step 3: Calculate notes per run
            local notesPerRun = notesPerBeat * beatsPerRun

            -- Step 4: Extend chord notes across octaves dynamically
            local extendedNotes = {}
            local octaveDrift = initialOctaveDrift

            while true do
                -- Clear extendedNotes for each iteration
                extendedNotes = {}

                -- Extend chord notes up to the current octave drift
                for i = 0, octaveDrift do
                    for _, note in ipairs(chordNotes) do
                        table.insert(extendedNotes, note + i * 12)
                    end
                end

                -- Sort the extended notes
                table.sort(extendedNotes)

                -- Check if we have enough notes
                if #extendedNotes >= notesPerRun or octaveDrift >= maxOctaveDrift then
                    break
                end

                -- Increase octave drift
                octaveDrift = octaveDrift + 1
            end

            -- Ensure we have enough notes after extending
            if #extendedNotes < notesPerRun then
                print("Unable to extend notes sufficiently within the maximum octave drift.")
            end

            -- Generate the run pattern
            local runPattern = {}
            for i = 1, math.min(notesPerRun, #extendedNotes) do
                table.insert(runPattern, extendedNotes[i])
            end

            -- Return the run pattern
            return runPattern
        end

        function generate_downward_arpeggio(up_notes)
            -- Find the first note which, when transposed by one octave, is not already in the upward pattern
            local first_note = nil
            for i = 1, #up_notes do
                local transposed_note = up_notes[i] + 12  -- Transpose up by one octave
                if not table.contains(up_notes, transposed_note) then
                    first_note = transposed_note
                    break
                end
            end

            -- If all transposed notes are in the upward arpeggio, use the last note transposed up an octave
            if not first_note then
                first_note = up_notes[#up_notes] + 12
            end

            -- Generate the downward arpeggio starting from the first_note
            local down_notes = {first_note}
            -- Reverse the up_notes, excluding the first note to match the note count
            for i = #up_notes, 2, -1 do
                table.insert(down_notes, up_notes[i])
            end

            return down_notes
        end

        -- Function to add a chord at a given marker position
        function add_chord_to_midi(midiCommand, hand_config, position, duration, marker)

            print ("add_chord_to_midi", midiCommand, print_table(hand_config), position, duration, print_table(marker))

            local channel = hand_config.channel
            local velocity = hand_config.velocity
            local chord_notes = marker.chord_notes

            if not chord_notes or #chord_notes == 0 then
                -- Nothing to do
                return
            end
            -- Add MIDI notes to the region based on the play parameter for the hand

            -- Solid chord
            if hand_config.play == 0 then
                for _, note in ipairs(chord_notes) do
                    add_midi_note_to_region(midiCommand, note, position, duration, channel, velocity)
                end
            end

            -- Random note
            if hand_config.play == 9 then
                print("Play a random note from the chord")
                local note_x = math.random(#chord_notes)
                add_midi_note_to_region(midiCommand, chord_notes[note_x], position, duration, channel, velocity)
            end

            -- Arpeggio up
            if table.contains({1,2,3,4}, hand_config.play) and marker.arpeggio then
                chord_notes = marker.arpeggio
                -- Select note to play
                local note_x = marker.cnt % #chord_notes + 1
                local note = chord_notes[note_x]

                -- Add note
                add_midi_note_to_region(midiCommand, note, position, duration, channel, velocity)
            end
        end

        function add_midi_note_to_region(midiCommand, note_pitch, start_time, duration, channel, velocity)

            -- print ("add_midi_note_to_region", midiCommand, note_pitch, start_time, duration, channel, velocity)

            -- Create a new note and add it to the command
            local new_note = ARDOUR.LuaAPI.new_noteptr(
                    channel, -- Channel (0 for default)
                    start_time, -- Start time in beats
                    duration, -- Duration in beats
                    note_pitch, -- MIDI note number
                    velocity    -- Velocity
            )
            midiCommand:add(new_note)
        end

        function createArpeggios(chord_notes, hand_config)

            local arpeggioNotes = {}

            -- Arpeggio up
            if hand_config.play == 1 then
                arpeggioNotes = createUpArp(chord_notes, hand_config)
            end

            -- Arpeggio up/down
            if hand_config.play == 2 then
                arpeggioNotes = createUpArp(chord_notes, hand_config)
                table.append(arpeggioNotes, generate_downward_arpeggio(arpeggioNotes))
            end

            -- Arpeggio down
            if hand_config.play == 3 then
                arpeggioNotes = table.reverse(createUpArp(chord_notes, hand_config))
            end

            -- Arpeggio down/up
            if hand_config.play == 4 then
                local up_chord_notes = createUpArp(chord_notes, hand_config)
                local down_chord_notes = generate_downward_arpeggio(up_chord_notes)
                arpeggioNotes = table.reverse(up_chord_notes)
                table.append(arpeggioNotes, table.reverse(down_chord_notes))
            end

            return arpeggioNotes

        end

        function parse_chord_progression_config(str)
            -- Remove "#ChordProgression" part from the beginning
            local content = str:gsub("#ChordProgression", "")

            -- Define a table to hold the parsed result
            local result = {}

            -- Pattern to capture key-value pairs in the form `key(values)`
            for key, values in content:gmatch("([%w_]+)%(([^%)]*)%)") do
                -- Split the values by commas and store them in a table
                local value_table = {}
                for value in values:gmatch("([^,]+)") do
                    -- Convert numeric values to numbers, keep strings as is
                    local numeric_value = tonumber(value)
                    table.insert(value_table, numeric_value or value)
                end
                -- Assign the table to the corresponding key
                result[key] = value_table
                print("Config for " .. key, print_table(value_table))
            end

            return result
        end

        -- Global variable for the chord_progression_config. It is set for each of the regions being processed
        chord_progression_config = nil

        -- Function to get two configuration values from a table, with defaults if not present
        function get_config_values(key, default)
            -- Get value from chord_progression_config using case-insensitive key lookup
            local values = table.getIgnoreCase(chord_progression_config, key)

            -- Check if the value exists, is a table, and has exactly two elements
            if values ~= nil and type(values) == "table" and #values == 2 then
                -- Check if both elements in the list match the type of the default elements
                if type(values[1]) == type(default[1]) and type(values[2]) == type(default[2]) then
                    return values
                end
            end

            -- If any condition fails, return the default
            return default
        end

        -- Function to retrieve config values for both hands
        function get_hand_config(hand)
            return {
                hand = hand,
                octave = get_config_values("octave", _hand_octave)[hand],
                hand_span = get_config_values("hand_span", _max_hand_span)[hand],
                notes_per_hand = get_config_values("notes_per_hand", _max_notes_per_hand)[hand],
                inversions_per_bar = get_config_values("inversions_per_bar", _inversions_per_bar)[hand],
                channel = get_config_values("channel", _hand_channel)[hand],
                velocity = get_config_values("velocity", _velocity)[hand],
                note_gap = get_config_values("note_gap", _note_gap)[hand],
                pattern = get_config_values("pattern", _pattern)[hand],
                inversion_alg = get_config_values("inversion_alg", _inversion_algorithm)[hand],
                style = get_config_values("style", _style)[hand],
                octave_drift = get_config_values("octave_drift", _octave_drift)[hand],
                play = get_config_values("play", _play)[hand],
            }
        end

        function align_to_bar(position, num_beats_per_bar)
            -- Start with the beginning of the bar (markers before the first chord marker will be skipped later)
            local marker_start_at_beat = position:get_beats()
            local bar_start_at_beat = math.floor(marker_start_at_beat / num_beats_per_bar) * num_beats_per_bar
            return Temporal.Beats(bar_start_at_beat, 0)
        end

        -- Insert repeating chords
        function add_chord_repeats(inversion_change_markers, chord_str,
                                   chord_pattern_marker_time, first_marker_time, end_time, pattern,
                                   chord_pattern_interval_beats, chord_pattern_interval_ticks)
            local cnt = 0
            local chord_marker
            while chord_pattern_marker_time < end_time do
                -- Handle swing notes
                if pattern < 0 and (cnt % 3) == 1 then
                    -- this is break
                    chord_marker = "#"
                else
                    chord_marker = "*" .. chord_str
                end
                if chord_pattern_marker_time > first_marker_time then
                    -- Create a new marker for this beat
                    -- We need to mark this chord as a repeat, with the same inversion as the previous one
                    local marker_name = chord_marker
                    local new_marker = {
                        name = marker_name,
                        time = chord_pattern_marker_time,
                        cnt = cnt
                    }

                    -- Add the new marker to the inversion_change_markers table
                    print("Adding new chord repeating point for ", chord_str, " at ", chord_pattern_marker_time)
                    table.insert(inversion_change_markers, new_marker)
                end
                -- prepare for the next marker
                chord_pattern_marker_time = chord_pattern_marker_time + Temporal.Beats(chord_pattern_interval_beats, chord_pattern_interval_ticks)
                cnt = cnt + 1
            end
        end

        -- Process chord markers
        function process_chord_markers(chord_markers, midi_region, hand, midiCommand, hand_config)

            local region_position = midi_region:position():beats()
            local region_end = region_position + midi_region:length():beats()

            local previous_chord_str = nil
            local previous_inversion = nil
            local previous_octave_adjustment = nil
            local previous_chord_notes = {}
            local previous_arpeggio = {}

            for i, marker in ipairs(chord_markers) do

                local start_time = marker.time - region_position
                local end_time = nil
                if i < #chord_markers then
                    -- Use start of the next chord as the end time
                    print("Using next inversion point at ", chord_markers[i + 1].time, " for the duration")
                    end_time = chord_markers[i + 1].time
                else
                    -- Use end of the region as the end time
                    print("Using region end at ", region_end, " for the duration")
                    end_time = region_end
                end
                local duration = end_time - start_time - region_position - Temporal.Beats(0, hand_config.note_gap)
                local chord_str = marker.name:sub(2)
                local chord_prefix = marker.name:sub(1,1)

                -- Skip breaks
                if chord_prefix ~= "#" then
                    local inversion, octave_adjustment, octave, chord_notes
                    if chord_prefix == "*" then
                        -- This is a chord repeat, use the same inversion and octave adjustment as the previous chord
                        inversion, octave_adjustment, chord_notes = previous_inversion, previous_octave_adjustment, previous_chord_notes
                        -- Copy extra info from the previous chord
                        marker.arpeggio = previous_arpeggio
                    else
                        print("Calling inversion algorithm ", hand_config.inversion_alg, " with parameters ", chord_str, previous_inversion, previous_chord_str, previous_octave_adjustment, print_table(previous_chord_notes), print_table(hand_config))
                        local choose_inversion = inversion_algorithms[hand_config.inversion_alg]
                        inversion, octave_adjustment, chord_notes =
                        choose_inversion(chord_str, previous_inversion, previous_chord_str, previous_octave_adjustment, previous_chord_notes, hand_config)
                        print("Inversion algorithm returned ", inversion, octave_adjustment, print_table(chord_notes))
                        -- Create arpeggio if needed
                        if table.contains({1,2,3,4}, hand_config.play) and hand_config.pattern ~= 0 then
                            marker.arpeggio = createArpeggios(chord_notes, hand_config)
                        end
                    end

                    -- Add generated chord notes to the marker object
                    marker.chord_notes = chord_notes

                    -- Add notes for the chord based on play configuration
                    add_chord_to_midi(midiCommand, hand_config,
                            start_time + midi_region:start():beats(), duration, marker)

                    print("Adding chord ", chord_str, " at ", start_time, " with duration ", duration,
                            " for hand ", hand, " inversion ", inversion, " hand octave ", hand_config.octave,
                            " octave adjustment ", octave_adjustment,
                            " chord_notes ", print_table(chord_notes))

                    -- Update previous settings based on hand
                    previous_inversion = inversion
                    previous_octave_adjustment = octave_adjustment
                    -- Save current chord string and notes for the next iteration
                    previous_chord_str = chord_str
                    previous_chord_notes = chord_notes
                    previous_arpeggio = marker.arpeggio

                end

            end

        end

        -- New inversion algorithm, ideas from Claude
        -- Function to choose the best inversion with voice leading
        function choose_inversion_2(chord_str, previous_inversion, previous_chord_str, previous_octave_adjustment, previous_chord_notes, hand_config)

            local octave = hand_config.octave

            if not chord_str or not octave then
                print("Error: Missing required parameters chord_str or octave")
                return nil, nil, {}
            end

            local key, chord_type = parse_chord(chord_str)
            if not key or not chord_type then
                print("Error: Invalid chord string: " .. chord_str)
                return nil, nil, {}
            end

            -- Generate all possible inversions
            local possible_inversions = {}
            local base_notes = get_chord_notes(key, chord_type, octave, 0)

            if not base_notes or #base_notes == 0 then
                print("Error: No notes generated for chord: " .. chord_str)
                return nil, nil, {}
            end

            local num_inversions = #base_notes

            for inv = 0, num_inversions - 1 do
                for adj = -1, 1 do
                    local notes = get_chord_notes(key, chord_type, octave + adj, inv)
                    if notes and #notes > 0 then
                        table.insert(possible_inversions, {inversion = inv, octave_adjustment = adj, notes = notes})
                        -- print("Adding inversion ", print_table(possible_inversions[#possible_inversions]))
                    end
                end
            end

            if #possible_inversions == 0 then
                print("Error: No valid inversions generated for chord: " .. chord_str)
                return nil, nil, {}
            end

            -- If there's no previous chord, choose a random inversion
            if not previous_chord_notes or #previous_chord_notes == 0 then
                -- We want to start with the inversion that has root note in the selected octave
                local start_inversions = {}
                for _, inv in ipairs(possible_inversions) do
                    if (inv.inv == 0 and inv.octave_adjustment == 0) or (inv.inv ~= 0 and inv.octave_adjustment == -1) then
                        table.insert(start_inversions, inv)
                    end
                end
                math.randomseed(os.time()) -- Seed the random number generator
                local random_index = math.random(#start_inversions)
                start_inversions[random_index].notes = trim_chord(start_inversions[random_index].notes, previous_chord_notes, hand_config, chord_type, key)
                print("trim_chord returned ", print_table(start_inversions[random_index].notes))
                return start_inversions[random_index].inversion,
                start_inversions[random_index].octave_adjustment,
                start_inversions[random_index].notes
            end

            -- Calculate voice leading scores for all inversions
            for _, inv in ipairs(possible_inversions) do
                inv.score, inv.notes = evaluate_single_hand(previous_chord_notes, inv.notes, hand_config, chord_type, key)
                --print("current_notes ", print_table(inv))
            end

            -- Inversions are now optimized for the hand and we might have duplicates
            -- Remove duplicates
            local unique_inversions = {}
            local seen_note_sets = {}

            for _, inv in ipairs(possible_inversions) do
                -- Convert the notes table to a string for easy comparison
                --inv.notes = table.sort(inv.notes)
                local note_set = table.concat(inv.notes, ",")

                if not seen_note_sets[note_set] then
                    seen_note_sets[note_set] = true
                    table.insert(unique_inversions, inv)
                end
            end

            -- Replace possible_inversions with the unique inversions
            possible_inversions = unique_inversions

            -- Sort inversions by voice leading score
            table.sort(possible_inversions, function(a, b) return a.score > b.score end)

            print("Unique inversions ", print_table(possible_inversions))

            -- If the chord hasn't changed, we need to choose a different inversion
            if chord_str == previous_chord_str then
                -- Find the best inversion that's different from the previous one
                local different_inv = {}
                for _, inv in ipairs(possible_inversions) do
                    local inv_note_set = table.concat(inv.notes, ",")
                    local prev_note_set = table.concat(previous_chord_notes, ",")
                    if prev_note_set ~= inv_note_set then
                        table.insert(different_inv, inv)
                        --return inv.inversion, inv.octave_adjustment, inv.notes
                    end
                end
                -- If we couldn't find a different inversion, use one of the best ones
                local random_index = math.random(math.min(2, #different_inv))
                print("Selecting inversion ", random_index, " from ", print_table(different_inv))
                return different_inv[random_index].inversion,
                different_inv[random_index].octave_adjustment,
                different_inv[random_index].notes
            end

            -- Return one of the best inversions to give it some randomness
            local random_index = math.random(math.min(2, #possible_inversions))
            return possible_inversions[random_index].inversion,
            possible_inversions[random_index].octave_adjustment,
            possible_inversions[random_index].notes
        end

        -- Evaluate new inversions based on previous chord notes and hand parameters
        function evaluate_single_hand(prev_notes, current_notes, hand_config, chord_type, key)

            --print("evaluate_single_hand ", print_table(prev_notes), print_table(current_notes), print_table(hand_config), chord_type, key)

            table.sort(prev_notes)
            table.sort(current_notes)

            local hand = hand_config.hand
            local style = hand_config.style
            local total_score = 0
            local max_movement = 12

            -- Intelligent note removal
            current_notes = trim_chord(current_notes, prev_notes, hand_config, chord_type, key)
            --print("trim_chord returned ", print_table(current_notes))

            -- Calculate common notes
            local common_notes = 0
            for _, note in ipairs(prev_notes) do
                if table.contains(current_notes, note) then
                    common_notes = common_notes + 1
                end
            end

            -- Evaluate note movements
            local total_movement = 0
            local largest_movement = 0
            for i = 1, math.min(#prev_notes, #current_notes) do
                local difference = math.abs(current_notes[i] - prev_notes[i])
                total_movement = total_movement + difference
                largest_movement = math.max(largest_movement, difference)

                -- Reward smaller movements
                total_score = total_score + (max_movement - difference)
            end

            -- Reward common notes
            total_score = total_score + (common_notes * 10)

            -- Evaluate range
            local prev_range = prev_notes[#prev_notes] - prev_notes[1]
            local current_range = current_notes[#current_notes] - current_notes[1]
            local range_difference = math.abs(current_range - prev_range)

            -- Style-specific scoring
            if style == "classical" then
                total_score = total_score + (12 - range_difference) * 3
                total_score = total_score - largest_movement * 2
            elseif style == "jazz" then
                total_score = total_score + (24 - range_difference)
                if current_range > 12 then
                    total_score = total_score + 10
                end
            elseif style == "pop" then
                total_score = total_score + (12 - range_difference) * 2
                total_score = total_score + (common_notes * 5)
            end

            -- Penalize very large total movements (adjusted for style and hand)
            local movement_threshold = max_movement * #prev_notes
            if style == "jazz" then movement_threshold = movement_threshold * 1.5 end
            if hand == 1 then movement_threshold = movement_threshold * 0.8 end
            if total_movement > movement_threshold then
                total_score = total_score - (total_movement - movement_threshold)
            end

            -- Bonus for ergonomic hand positions
            if is_ergonomic_position(current_notes, hand_config) then
                total_score = total_score + 15
            end

            --print("Returning ", total_score, print_table(current_notes))
            table.sort(current_notes)

            -- Add penalty for lowest note outside of allowed range
            local base_octave = hand_config.octave * 12  -- Convert octave to MIDI note number
            local lower_bound = base_octave - (hand_config.octave_drift * 12)  -- Lower bound in MIDI note numbers
            local upper_bound = base_octave + (hand_config.octave_drift * 12)  -- Upper bound in MIDI note numbers

            local lowest_note = current_notes[1]  -- Assuming current_notes is sorted

            if lowest_note < lower_bound or lowest_note > upper_bound then
                local distance_from_range = math.min(math.abs(lowest_note - lower_bound), math.abs(lowest_note - upper_bound))
                local octaves_out_of_range = math.floor(distance_from_range / 12)
                total_score = total_score - (octaves_out_of_range * 20)  -- Penalty per octave out of range
            end

            return total_score, current_notes
        end

        function trim_chord(notes, prev_notes, hand_config, chord_type, key)

            --print("trim_chord ", print_table(notes), print_table(prev_notes), print_table(hand_config), chord_type, key)

            if #notes <= hand_config.notes_per_hand then
                return notes
            end

            local root = note_map[key]
            local note_weights = {}
            local priority_notes = get_priority_notes(chord_type, root, hand_config)

            -- Assign weights to notes
            for _, note in ipairs(notes) do
                local weight = 0
                -- Priority notes from chord quality
                for i, priority_note in ipairs(priority_notes) do
                    if note % 12 == priority_note then
                        weight = weight + (5 - i) * 10  -- Higher weight for more important chord tones
                    end
                end
                -- Common notes with previous chord
                if table.contains(prev_notes, note) then
                    weight = weight + 15
                end
                -- Prefer lower notes for left hand, higher notes for right hand
                if hand_config.hand == 1 then
                    weight = weight + (127 - note)
                else
                    weight = weight + note
                end
                note_weights[note] = weight
            end

            -- Sort notes by weight
            table.sort(notes, function(a, b) return note_weights[a] > note_weights[b] end)

            -- Keep the top max_notes
            notes = {table.unpack(notes, 1, hand_config.notes_per_hand)}

            -- Now sort notes back in the ascending order
            table.sort(notes)

            return notes
        end

        function get_priority_notes(chord_quality, root, hand_config)
            local intervals = chord_type_map[chord_quality]
            if not intervals then
                print("Error: Unknown chord quality: " .. chord_quality)
                return {}
            end

            local notes = {}
            for _, interval in ipairs(intervals) do
                table.insert(notes, (root + interval) % 12)
            end

            -- Remove duplicates
            local unique_notes = {}
            for _, v in ipairs(notes) do
                if not table.contains(unique_notes, v) then
                    table.insert(unique_notes, v)
                end
            end

            -- Sort notes
            --table.sort(unique_notes)

            -- Select notes based on hand
            local priority_notes = {}
            if hand_config.hand == 1 then  -- Left hand
                for i = 1, math.min(#unique_notes, hand_config.notes_per_hand) do
                    table.insert(priority_notes, unique_notes[i])
                end
            else  -- Right hand
                for i = math.max(1, #unique_notes - hand_config.notes_per_hand + 1), #unique_notes do
                    table.insert(priority_notes, unique_notes[i])
                end
            end

            -- Sort priority notes before returning them
            table.sort(priority_notes)
            return priority_notes
        end

        function is_ergonomic_position(notes, hand_config)
            local range = notes[#notes] - notes[1]
            return range <= hand_config.hand_span
        end

        function table.contains(table, element)
            for _, value in pairs(table) do
                if value == element then
                    return true
                end
            end
            return false
        end

        -- Append t2 to t1
        function table.append(t1, t2)
            for i = 1, #t2 do
                t1[#t1 + 1] = t2[i]
            end
            return t1
        end

        -- Define the table.reverse function
        function table.reverse(tbl)
            local reversed = {}
            for i = #tbl, 1, -1 do
                reversed[#reversed + 1] = tbl[i]
            end
            return reversed
        end

        function table.getIgnoreCase(tbl, key)
            local lower_key = string.lower(key)
            for k, v in pairs(tbl) do
                if string.lower(k) == lower_key then
                    return v
                end
            end
            return nil
        end

        function get_all_cp_regions()
            local cp_regions = {}
            -- Get the selected regions
            local sel = Editor:get_selection()
            -- Loop through all selected MIDI regions
            for r in sel.regions:regionlist():iter() do
                -- Skip non-MIDI region
                local midi_region = r:to_midiregion()
                if midi_region and midi_region:name():sub(0, string.len("#ChordProgression")) == "#ChordProgression" then
                    table.insert(cp_regions, midi_region)
                end
            end

            print("Found ", #cp_regions, " selected chord progression regions ")

            return cp_regions

        end

        function split_key_index(str)
            local key = str:match("(%D+)")  -- Match one or more non-digit characters
            local index = tonumber(str:match("(%d+)$"))  -- Match one or more digits at the end of the string
            return key, index
        end

        function format_key_values(key_values)
            local result = {}
            for key, values in pairs(key_values) do
                local formattedValues = {}
                for i, value in ipairs(values) do
                    if type(value) == "number" then
                        formattedValues[i] = tostring(math.floor(value))
                    else
                        formattedValues[i] = tostring(value)
                    end
                end
                local valueStr = table.concat(formattedValues, ",")
                table.insert(result, key .. "(" .. valueStr .. ")")
            end
            return table.concat(result, " ")
        end

        function config_cp_region(cp_region)

            -- Parse configuration options
            chord_progression_config = parse_chord_progression_config(cp_region:name())

            local play_values = {
                ["Solid chords"] = 0,
                ["Arp up"] = 1,
                ["Arp up/down"] = 2,
                ["Arp down"] = 3,
                ["Arp down/up"] = 4,
                ["Random"] = 9
            }

            local play_values_x = {
                [0] = "Solid chords",
                "Arp up",
                "Arp up/down",
                "Arp down",
                "Arp down/up",
                [9] = "Random"
            }

            local style_values = {
                ["jazz"] = "jazz",
                ["pop"] = "pop",
                ["classical"] = "classical"
            }

            local hands = {"Left", "Right"}

            local dialog_options = {}

            for _, hand in ipairs({ 1, 2 }) do

                local hand_config = get_hand_config(hand)

                if hand == 2 then
                    table.insert(dialog_options, {type = "label", title = " "})
                    table.insert(dialog_options, {type = "label", title = "__________________________________________________" .. hands[hand] .. " hand"})
                else
                    table.insert(dialog_options, {type = "label", title = hands[hand] .. " hand__________________________________________________"})
                end

                table.insert(dialog_options, {type = "number", key = "octave"..tostring(hand), title = "Octave", min = 0, max = 8, default = hand_config.octave, step = 1})
                table.insert(dialog_options, {type = "number", key = "hand_span"..tostring(hand), title = "Hand span", min = 0, max = 12, default = hand_config.hand_span, step = 1})
                table.insert(dialog_options, {type = "number", key = "notes_per_hand"..tostring(hand), title = "Notes per hand", min = 0, max = 12, default = hand_config.notes_per_hand, step = 1})
                table.insert(dialog_options, {type = "number", key = "inversions_per_bar"..tostring(hand), title = "Inversions per bar", min = 0, max = 16, default = hand_config.inversions_per_bar, step = 1})
                table.insert(dialog_options, {type = "number", key = "channel"..tostring(hand), title = "Channel", min = 0, max = 15, default = hand_config.channel, step = 1})
                table.insert(dialog_options, {type = "slider", key = "velocity"..tostring(hand), title = "Velocity", min = 0, max = 127, default = hand_config.velocity, step = 1})
                table.insert(dialog_options, {type = "slider", key = "note_gap"..tostring(hand), title = "Note gap", min = 0, max = 120, default = hand_config.note_gap, step = 1})
                table.insert(dialog_options, {type = "number", key = "pattern"..tostring(hand), title = "Pattern", min = 0, max = 64, default = math.abs(hand_config.pattern), step = 1})
                table.insert(dialog_options, {type = "checkbox", key = "swing"..tostring(hand), title = "Swing", default = (hand_config.pattern < 0)})
                table.insert(dialog_options, {type = "number", key = "octave_drift"..tostring(hand), title = "Octave drift", min = 0, max = 4, default = hand_config.octave_drift, step = 1})
                table.insert(dialog_options, {type = "dropdown", key = "play"..tostring(hand), title = "Play", values = play_values, default = play_values_x[hand_config.play]})
                table.insert(dialog_options, {type = "dropdown", key = "style"..tostring(hand), title = "Style", values = style_values, default = style_values[hand_config.style]})

            end
            -- Open config dialog for the selected region
            local dialog = LuaDialog.Dialog("Chord progression settings", dialog_options)
            local response = dialog:run()
            dialog = nil

            if response then

                -- Adjustments
                if response.swing1 then
                    response.pattern1 = -1 * response.pattern1
                end
                if response.swing2 then
                    response.pattern2 = -1 * response.pattern2
                end

                -- Generate setup string

                local key_values = {}
                print("Dialog response ", print_table(response))
                for dialog_key, value in pairs(response) do
                    local key, index = split_key_index(dialog_key)
                    if not key_values[key] then
                        key_values[key] = {}
                    end
                    key_values[key][index] = value
                end

                --print("Found these settings ", print_table(key_values))
                local setup_str = "#ChordProgression " .. format_key_values(key_values)
                --print("Setup string ", setup_str)

                -- Update region's name with the new setup string
                cp_region:set_name(setup_str)

                return true

            else
                return false
            end
        end

        -- Globals

        _hand_octave = { 3, 5 }
        _max_hand_span = { 13, 13 }
        _max_notes_per_hand = { 3, 4 }
        _inversions_per_bar = { 0, 0 } -- One inversion per chord change
        _hand_channel = {0,0} -- Both hands go to the same channel
        _velocity = {64, 64}
        _note_gap = {0, 0}
        _pattern = {0, 0} --chord repeat pattern. Negative value for swing notes
        _inversion_algorithm = {1, 1}
        _style = {"jazz", "jazz"}
        _octave_drift = {1, 1}
        _play = {0, 0}

        ticks_per_beat = 1920.0

        inversion_algorithms = {
            choose_inversion_2
        }

        -- Main code block

        math.randomseed(os.time()) -- Seed the random number generator

        -- Get the selected cp regions
        local cp_regions = get_all_cp_regions()

        -- Get all chord markers in the session
        local chordMarkers = getAllChordMarkers()

        if #cp_regions == 0 then
            LuaDialog.Message ("Chord progression",
                    "Please select at least one #ChordProgression MIDI region",
                    LuaDialog.MessageType.Error,
                    LuaDialog.ButtonType.Close):run ()
            return
        end

        if #cp_regions == 1 then
            -- Only one CP region selected, open config dialog
            if not config_cp_region(cp_regions[1]) then
                return
            end
        end

        -- Loop through all selected MIDI regions
        for _, midi_region in ipairs(cp_regions) do

            -- Parse configuration options
            chord_progression_config = parse_chord_progression_config(midi_region:name())

            local region_position = midi_region:position():beats()
            local region_end = region_position + midi_region:length():beats()

            -- Get signature at the start of the region
            local tempoMap = Temporal.TempoMap:read()
            local signature = tempoMap:meter_at(midi_region:position())
            print("Signature ", signature:divisions_per_bar(), " / ", signature:note_value())

            -- number of beats  per bar is defined as signature:divisions_per_bar(
            local num_beats_per_bar = signature:divisions_per_bar()

            -- Get chord markers within the current region
            local relevantChordMarkers = getRelevantChords(midi_region, chordMarkers)

            -- Setup midi command for the region
            local midiModel = midi_region:midi_source(0):model()
            local midi_command = midiModel:new_note_diff_command("Add MIDI Note")

            -- Delete existing notes first
            for note in ARDOUR.LuaAPI.note_list(midiModel):iter() do
                midi_command:remove(note)
            end

            -- Process left and right hands separately
            for _, hand in ipairs({ 1, 2 }) do

                local hand_config = get_hand_config(hand)
                -- Add signature to the hand_config
                hand_config.time_signature = {signature:divisions_per_bar(), signature:note_value()}

                -- Add all inversion change points as chords in the timeline
                local inversion_change_markers = {}
                for i, marker in ipairs(relevantChordMarkers) do
                    -- Add chord marker first

                    local end_time = nil
                    if i < #relevantChordMarkers then
                        -- Use start of the next chord as the end time
                        end_time = relevantChordMarkers[i + 1]:start():beats()
                    else
                        -- Use end of the region as the end time
                        end_time = region_end
                    end
                    local chord_str = marker:name():sub(2)

                    print("Adding first inversion change point for ", chord_str, " at ", marker:start():beats())
                    local first_marker_name = marker:name()
                    local first_marker_time = marker:start():beats()
                    local first_marker = {
                        name = first_marker_name,
                        time = first_marker_time,
                        cnt = 0
                    }
                    table.insert(inversion_change_markers, first_marker)

                    local chord_pattern_interval
                    local chord_pattern_interval_beats
                    local chord_pattern_interval_ticks
                    local chord_pattern_marker_time

                    -- First insert repeating chords per settings
                    if hand_config.pattern ~= 0 then
                        -- Interval calculation for the chord repeats
                        chord_pattern_interval = num_beats_per_bar / math.abs(hand_config.pattern)
                        chord_pattern_interval_beats = math.floor(chord_pattern_interval)
                        chord_pattern_interval_ticks = math.tointeger(math.floor((chord_pattern_interval - chord_pattern_interval_beats) * ticks_per_beat))
                        print("Chord pattern interval ",  chord_pattern_interval, " = ",  chord_pattern_interval_beats, ":",  chord_pattern_interval_ticks, " beats")

                        local marker_time
                        if hand_config.inversions_per_bar > 0 then
                            -- Calculate where the next inversion change will be
                            local interval = num_beats_per_bar / hand_config.inversions_per_bar
                            local interval_beats = math.floor(interval)
                            local interval_ticks = math.tointeger((interval - interval_beats) * ticks_per_beat)
                            print("Inversion interval ", interval, " = ", interval_beats, ":", interval_ticks, " beats")

                            -- Start with the beginning of the bar (markers before the first chord marker will be skipped later)
                            local marker_start_at_beat = marker:start():beats():get_beats()
                            local bar_start_at_beat = math.floor(marker_start_at_beat / num_beats_per_bar) * num_beats_per_bar
                            marker_time = Temporal.Beats(bar_start_at_beat, 0)
                            -- Make sure next marker is after the first markerUnsupported type
                            while marker_time <= first_marker_time do
                                marker_time = marker_time + Temporal.Beats(interval_beats, interval_ticks)
                            end

                        else
                            local next_marker = relevantChordMarkers[i+1]
                            if next_marker then
                                marker_time = next_marker:start():beats()
                            else
                                marker_time = end_time
                            end
                        end

                        chord_pattern_marker_time = align_to_bar(first_marker_time, num_beats_per_bar)

                        add_chord_repeats(inversion_change_markers, chord_str,
                                chord_pattern_marker_time, first_marker_time, math.min(marker_time, end_time), hand_config.pattern,
                                chord_pattern_interval_beats, chord_pattern_interval_ticks)
                    end

                    if hand_config.inversions_per_bar > 0 then

                        -- Create new marker for each inversion change within the duration of the chord.
                        -- Intervals between the inversions based on the signature
                        local interval = num_beats_per_bar / hand_config.inversions_per_bar
                        local interval_beats = math.floor(interval)
                        local interval_ticks = math.tointeger((interval - interval_beats) * ticks_per_beat)
                        print("Inversion interval ", interval, " = ", interval_beats, ":", interval_ticks, " beats")

                        -- Start with the beginning of the bar (markers before the first chord marker will be skipped later)
                        local marker_start_at_beat = marker:start():beats():get_beats()
                        local bar_start_at_beat = math.floor(marker_start_at_beat / num_beats_per_bar) * num_beats_per_bar
                        local marker_time = Temporal.Beats(bar_start_at_beat, 0)
                        -- Make sure next marker is after the first marker
                        while marker_time <= first_marker_time do
                            marker_time = marker_time + Temporal.Beats(interval_beats, interval_ticks)
                        end
                        print("Bar starts at ", bar_start_at_beat, " next marker at (", marker_time, ")")

                        while marker_time < end_time do

                            -- Create a new marker for this beat
                            local marker_name = marker:name()
                            local new_marker = {
                                name = marker_name,
                                time = marker_time,
                                cnt = 0
                            }

                            -- Add the new marker to the inversion_change_markers table
                            print("Adding new inversion change point for ", chord_str, " at ", marker_time)
                            table.insert(inversion_change_markers, new_marker)

                            -- prepare for the next marker
                            local prev_marker_time = marker_time
                            marker_time = marker_time + Temporal.Beats(interval_beats, interval_ticks)

                            -- Insert repeating chords till the next inversion change or end of region

                            if hand_config.pattern ~= 0 then
                                chord_pattern_marker_time = chord_pattern_marker_time + Temporal.Beats(chord_pattern_interval_beats, chord_pattern_interval_ticks)

                                add_chord_repeats(inversion_change_markers, chord_str,
                                        prev_marker_time, prev_marker_time, math.min(marker_time, end_time), hand_config.pattern,
                                        chord_pattern_interval_beats, chord_pattern_interval_ticks)

                            end

                        end

                        print("Inversion change markers:", print_table(inversion_change_markers))

                    end

                end

                -- Process chord markers in range
                process_chord_markers(inversion_change_markers, midi_region, hand, midi_command, hand_config)

            end

            -- Apply the command to the MIDI model (changes to the current region)
            midiModel:apply_command(Session, midi_command)

        end

    end

end



