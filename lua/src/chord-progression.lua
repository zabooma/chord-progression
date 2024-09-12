ardour { ["type"] = "EditorAction", name = "[A] Chord progression",
         license = "MIT",
         author = "Frank Povazanj",
         description = [[Creates chord progression based on the chords defined in the location markers.]]
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

    function getRelevantChords(region, chord_markers)
        -- Extract items from chord_markers where marker start >= region start and marker start < region start + length
        local region_start = region:position():beats()
        local region_end = region_start + region:length():beats()
        local relevant_chord_markers = {}

        print("Region '" .. region:name() .. "' start time", region_start)
        print("Region length", region:length():beats())

        for _, marker in ipairs(chord_markers) do
            local marker_start = marker:start():beats()
            if marker_start >= region_start and marker_start < region_end then
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

    -- Converted code

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
        ['minor'] = { 0, 3, 7 },
        ['7'] = { 0, 4, 7, 10 },
        ['maj7'] = { 0, 4, 7, 11 },
        ['min7'] = { 0, 3, 7, 10 },
        ['dim'] = { 0, 3, 6 },
        ['aug'] = { 0, 4, 8 },

        -- Ninth, eleventh, and thirteenth chords
        ['7/9'] = { 0, 4, 7, 10, 14 },
        ['9'] = { 0, 4, 7, 10, 14 },
        ['min9'] = { 0, 3, 7, 10, 14 },
        ['maj9'] = { 0, 4, 7, 11, 14 },
        ['11'] = { 0, 4, 7, 10, 14, 17 },
        ['maj11'] = { 0, 4, 7, 11, 14, 17 },
        ['min11'] = { 0, 3, 7, 10, 14, 17 },
        ['13'] = { 0, 4, 7, 10, 14, 17, 21 },
        ['maj13'] = { 0, 4, 7, 11, 14, 21 },
        ['min13'] = { 0, 3, 7, 10, 14, 21 },

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
        local root_note = note_map[key] + (octave - 4) * 12
        local chord_intervals = chord_type_map[chord_type]
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

    -- Function to evaluate how well two chords blend by comparing notes
    function evaluate_inversion_blending(prev_notes, current_notes)
        table.sort(prev_notes)
        table.sort(current_notes)

        -- Calculate total difference between corresponding notes
        local total_difference = 0
        for i = 1, math.min(#prev_notes, #current_notes) do
            total_difference = total_difference + math.abs(prev_notes[i] - current_notes[i])
        end

        return total_difference
    end

    -- Function to choose the best inversion based on the previous chord
    function choose_inversion(chord_str, previous_inversion, previous_chord, previous_octave_adjustment)
        local key, chord_type = parse_chord(chord_str)

        print("Choosing inversion for ", chord_str, " previous chord ", previous_chord, " inversion ", previous_inversion, " octave adjustment ", previous_octave_adjustment)

        if previous_chord then
            local prev_key, prev_chord_type = parse_chord(previous_chord)
            local prev_notes = get_chord_notes(prev_key, prev_chord_type, 4 + previous_octave_adjustment, previous_inversion)

            print("Previous chord notes", print_table(prev_notes))

            local best_inversion = 0
            local best_octave_adjustment = 0
            local min_blending = math.huge  -- Set to a very large number

            -- Loop through inversions and octave adjustments to find the best match
            for octave_adjustment = -1, 1 do
                for inversion = 0, #chord_type_map[chord_type] - 1 do
                    local candidate_notes = get_chord_notes(key, chord_type, 4 + octave_adjustment, inversion)
                    local blending = evaluate_inversion_blending(prev_notes, candidate_notes)
                    print("Candidate notes, inversion " .. tostring(inversion) .. " octave adjustment " .. tostring(octave_adjustment), print_table(candidate_notes))
                    if blending <= min_blending and blending ~= 0 then
                        best_inversion = inversion
                        best_octave_adjustment = octave_adjustment
                        min_blending = blending
                    end
                end
            end
            print("Choosing inversion " .. tostring(best_inversion) .. " with blending ", min_blending, " and octave adjustment " .. tostring(best_octave_adjustment))
            return best_inversion, best_octave_adjustment
        else
            -- Default inversion if no previous chord
            return math.random(0, #chord_type_map[chord_type] - 1), 0
        end
    end

    -- Function to optimize chord for playability by limiting notes and hand span
    function optimize_chord(notes, root_note, max_notes_per_hand, max_hand_span)
        -- Ensure the notes are sorted
        table.sort(notes)

        -- Limit the span of notes
        while notes[#notes] - notes[1] > max_hand_span do
            table.remove(notes)
        end

        -- Define priority intervals
        local priority_intervals = { 0, 3, 4, 10 }

        -- Keep track of whether any note was removed in the last pass
        local note_removed = true

        -- Remove notes based on priority intervals until the number of notes is acceptable
        while #notes > max_notes_per_hand do
            note_removed = false  -- Reset the flag to check if any note is removed

            for i, note in ipairs(notes) do
                if not contains(priority_intervals, (note - root_note) % 12) then
                    table.remove(notes, i)
                    note_removed = true  -- Mark that a note was removed
                    break
                end
            end

            -- If no notes were removed, remove the last note (the highest note) to prevent infinite loop
            if not note_removed then
                table.remove(notes)
            end
        end

        return notes
    end

    -- Helper function to check if a table contains a value
    function contains(table, value)
        for _, v in ipairs(table) do
            if v == value then
                return true
            end
        end
        return false
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
        if not note_map[key] then
            error("Invalid key: " .. key)
        end

        if not chord_type_map[chord_type] then
            error("Invalid chord type: " .. chord_type)
        end

        return key, chord_type
    end

    -- Function to add a chord at a given marker position
    function add_chord_to_midi(midiCommand, chord_str, hand_inversion, hand_octave, position, duration, max_notes_per_hand, max_hand_span)
        local key, chord_type = parse_chord(chord_str)

        -- Get chord notes for both hands
        local hand_notes = get_chord_notes(key, chord_type, hand_octave, hand_inversion)

        -- Optimize the chord notes for playability
        hand_notes = optimize_chord(hand_notes, note_map[key], max_notes_per_hand, max_hand_span)

        -- Add MIDI notes to the region
        for _, note in ipairs(hand_notes) do
            add_midi_note_to_region(midiCommand, note, 64, position, duration)
        end

        return hand_notes
    end

    function add_midi_note_to_region(midiCommand, note_pitch, note_velocity, start_time, duration)

        -- Create a new note and add it to the command
        local new_note = ARDOUR.LuaAPI.new_noteptr(
                0, -- Channel (0 for default)
                start_time, -- Start time in beats
                duration, -- Duration in beats
                note_pitch, -- MIDI note number
                note_velocity    -- Velocity
        )
        midiCommand:add(new_note)
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
        local values = chord_progression_config[key] or default
        return values
    end

    return function()

        -- Globals
        local _hand_octave = { 3, 5 }
        local _max_hand_span = { 13, 13 }
        local _max_notes_per_hand = { 3, 4 }
        local _inversions_per_bar = { 0, 0 } -- One inversion per chord change

        local ticks_per_beat = 1920.0

        -- Get the selected region
        local sel = Editor:get_selection()

        -- Get all chord markers in the session
        local chordMarkers = getAllChordMarkers()

        -- Loop through all selected MIDI regions
        for r in sel.regions:regionlist():iter() do
            -- Skip non-MIDI region
            local midi_region = r:to_midiregion()
            if midi_region and midi_region:name():sub(0, string.len("#ChordProgression")) == "#ChordProgression" then

                -- Parse configuration options
                chord_progression_config = parse_chord_progression_config(midi_region:name())

                local hand_octave = get_config_values("octave", _hand_octave)
                local max_hand_span = get_config_values("hand_span", _max_hand_span)
                local max_notes_per_hand = get_config_values("notes_per_hand", _max_notes_per_hand)
                local inversions_per_bar = get_config_values("inversions_per_bar", _inversions_per_bar)

                local regionStart = midi_region:position():beats()
                local regionEnd = regionStart + midi_region:length():beats()

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
                local midiCommand = midiModel:new_note_diff_command("Add MIDI Note")

                -- Delete existing notes first
                for note in ARDOUR.LuaAPI.note_list(midiModel):iter() do
                    midiCommand:remove(note)
                end

                -- Process left and right hands separately
                for _, hand in ipairs({ 1, 2 }) do

                    local previous_chord_str = nil
                    local previous_inversion = nil
                    local previous_octave_adjustment = nil
                    local previous_chord_notes = {}

                    -- Add all inversion change points as chords in the timeline
                    local inversion_change_markers = {}
                    for i, marker in ipairs(relevantChordMarkers) do
                        -- Add chord marker first

                        local start_time = marker:start():beats() - regionStart
                        local end_time = nil
                        if i < #relevantChordMarkers then
                            -- Use start of the next chord as the end time
                            end_time = relevantChordMarkers[i + 1]:start():beats()
                        else
                            -- Use end of the region as the end time
                            end_time = regionEnd
                        end
                        local duration = end_time - start_time - regionStart
                        local chordStr = marker:name():sub(2)

                        print("Adding first inversion change point for ", chordStr, " at ", marker:start():beats())
                        local first_marker_name = marker:name()
                        local first_marker_time = marker:start():beats()
                        local first_marker = {
                            name = first_marker_name,
                            time = first_marker_time
                        }
                        table.insert(inversion_change_markers, first_marker)

                        if inversions_per_bar[hand] > 0 then

                            -- TODO create new marker for each inversion change within the duration of the chord.

                            -- Intervals between the inversions based on the signature
                            local interval = num_beats_per_bar / inversions_per_bar[hand]
                            local interval_beats = math.floor(interval)
                            local interval_ticks = math.tointeger((interval - interval_beats) * ticks_per_beat)
                            print("inversion interval ", interval, " = ", interval_beats, ":", interval_ticks, " beats")

                            -- Loop through each beat and create a new marker
                            -- Start with the beginning of the bar (markers before the first chord marker will be skipped later)
                            local marker_start_at_beat = marker:start():beats():get_beats()
                            local bar_start_at_beat = math.floor(marker_start_at_beat / num_beats_per_bar) * num_beats_per_bar
                            local marker_time = Temporal.Beats(bar_start_at_beat, 0)
                            print("Bar starts at ", bar_start_at_beat, " (", marker_time, ")")
                            while marker_time < end_time do

                                if marker_time > first_marker_time then
                                    -- Create a new marker for this beat
                                    local marker_name = marker:name()
                                    local new_marker = {
                                        name = marker_name,
                                        time = marker_time
                                    }

                                    -- Add the new marker to the inversion_change_markers table
                                    print("Adding new inversion change point for ", chordStr, " at ", marker_time)
                                    table.insert(inversion_change_markers, new_marker)
                                end
                                -- prepare for the next marker
                                marker_time = marker_time + Temporal.Beats(interval_beats, interval_ticks)
                            end

                            print("Inversion change markers:", print_table(inversion_change_markers))

                            table.sort(inversion_change_markers, function(a, b)
                                return a.time < b.time
                            end)

                            print("Inversion change markers after sorting:", print_table(inversion_change_markers))

                            -- endTODO
                        end

                    end

                    -- Process chord markers in range
                    for i, marker in ipairs(inversion_change_markers) do

                        local start_time = marker.time - regionStart
                        local end_time = nil
                        if i < #inversion_change_markers then
                            -- Use start of the next chord as the end time
                            print("Using next inversion point at ", inversion_change_markers[i + 1].time, " for the duration")
                            end_time = inversion_change_markers[i + 1].time
                        else
                            -- Use end of the region as the end time
                            print("Using region end at ", regionEnd, " for the duration")
                            end_time = regionEnd
                        end
                        local duration = end_time - start_time - regionStart
                        local chordStr = marker.name:sub(2)

                        local inversion, octave_adjustment, octave

                        inversion, octave_adjustment = choose_inversion(chordStr, previous_inversion, previous_chord_str, previous_octave_adjustment)
                        octave = hand_octave[hand] + octave_adjustment

                        -- Add chord to MIDI for the current hand
                        local chord_notes = add_chord_to_midi(midiCommand, chordStr, inversion, octave,
                                start_time, duration,
                                max_notes_per_hand[hand],
                                max_hand_span[hand])

                        print("Adding chord ", chordStr, " at ", start_time, " with duration ", duration,
                                " for hand ", hand, " inversion ", inversion, " hand octave ", hand_octave[hand],
                                " octave adjustment ", octave_adjustment,
                                " chord_notes ", print_table(chord_notes))

                        -- Update previous settings based on hand
                        previous_inversion = inversion
                        previous_octave_adjustment = octave_adjustment
                        -- Save current chord string and notes for the next iteration
                        previous_chord_str = chordStr
                        previous_chord_notes = chord_notes

                    end

                end

                -- Apply the command to the MIDI model
                midiModel:apply_command(Session, midiCommand)
            end
        end

    end

end



