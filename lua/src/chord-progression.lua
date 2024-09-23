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
        ['maj'] = { 0, 4, 7 },
        ['minor'] = { 0, 3, 7 },
        ['min'] = { 0, 3, 7 },
        ['m'] = { 0, 3, 7 },
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
    function choose_inversion_1(chord_str, previous_inversion, previous_chord, previous_octave_adjustment, previous_chord_notes, hand_config)

        local key, chord_type = parse_chord(chord_str)
        local octave = hand_config.octave

        print("Choosing inversion for ", chord_str, " previous chord ", previous_chord, " inversion ", previous_inversion, " octave adjustment ", previous_octave_adjustment)

        if previous_chord then
            local prev_key, prev_chord_type = parse_chord(previous_chord)
            if not previous_chord_notes then
                previous_chord_notes = get_chord_notes(prev_key, prev_chord_type, octave + previous_octave_adjustment, previous_inversion)
            end

            print("Previous chord notes", print_table(previous_chord_notes))

            local best_inversion = 0
            local best_octave_adjustment = 0
            local min_blending = math.huge  -- Set to a very large number

            -- Loop through inversions and octave adjustments to find the best match
            local all_inversions = {}
            for octave_adjustment = -1, 1 do
                for inversion = 0, #chord_type_map[chord_type] - 1 do
                    local candidate_notes = get_chord_notes(key, chord_type, octave + octave_adjustment, inversion)
                    local blending = evaluate_inversion_blending(previous_chord_notes, candidate_notes)
                    if blending > 0 then
                        print("Candidate notes, inversion " .. tostring(inversion) .. " blending " .. blending .. " octave adjustment " .. tostring(octave_adjustment), print_table(candidate_notes))
                        -- Save this inversion
                        local inversion_obj = {
                            inversion = inversion,
                            blending = blending,
                            octave_adjustment = octave_adjustment,
                            chord_notes = candidate_notes
                        }
                        table.insert(all_inversions, inversion_obj)
                    end
                end
            end
            table.sort(all_inversions,function(a, b)
                return a.blending < b.blending
            end )
            -- Chose one of the first two inversions
            local inversion_index = math.random(1, 2)
            best_inversion = all_inversions[inversion_index].inversion
            best_octave_adjustment = all_inversions[inversion_index].octave_adjustment
            min_blending = all_inversions[inversion_index].blending

            print("Chosen is inversion with index " .. inversion_index .. " inversion " .. tostring(best_inversion) .. " with blending ", min_blending, " and octave adjustment " .. tostring(best_octave_adjustment))
            return best_inversion, best_octave_adjustment, all_inversions[inversion_index].chord_notes
        else
            -- Random inversion if no previous chord
            local inversion = math.random(0, #chord_type_map[chord_type] - 1)
            return inversion, 0,
                get_chord_notes(key, chord_type, octave, inversion)
        end
    end

    -- Function to optimize chord for playability by limiting notes and hand span
    function optimize_chord(chord_notes, root_note, max_notes_per_hand, max_hand_span, priority_intervals)

        -- Create a copy of the chord notes
        local notes = {}
        for i, note in ipairs(chord_notes) do
            table.insert(notes, note)
        end
        -- Ensure the notes are sorted
        table.sort(notes)

        print("Optimizing chord ", print_table(notes), " for notes per hand ", max_notes_per_hand,
                " max hand span ", max_hand_span, " priority intervals ", print_table(priority_intervals), " root note ", root_note)

        -- Limit the span of notes
        while notes[#notes] - notes[1] > max_hand_span do
            table.remove(notes)
        end

        -- Keep track of whether any note was removed in the last pass
        local note_removed = true
        -- Convert root note to the base octave
        root_note = root_note % 12
        -- Remove notes based on priority intervals until the number of notes is acceptable
        while #notes > max_notes_per_hand do
            note_removed = false  -- Reset the flag to check if any note is removed

            local interval =  nil
            for i, note in ipairs(notes) do
                -- Convert current note to the base octave
                note = note % 12
                if note < root_note then
                    interval = (note + 12 - root_note)
                else
                    interval = (note - root_note)
                end
                print(string.format("Root note %d note %d interval %d", root_note, note, interval))
                if not contains(priority_intervals, interval) then
                    print("Removing non_priority note ", note)
                    table.remove(notes, i)
                    note_removed = true  -- Mark that a note was removed
                    break
                end
            end

            -- If no notes were removed we only have the priority notes left, remove a random note to prevent infinite loop
            if not note_removed then
                local note =  math.random(1, #notes)
                print("Removing priority note ", notes[note])
                table.remove(notes, note)
            end
        end

        print("Optimized chord ", print_table(notes))

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
    function add_chord_to_midi(midiCommand, channel, position, duration, velocity, hand_notes)

        -- Add MIDI notes to the region
        for _, note in ipairs(hand_notes) do
            add_midi_note_to_region(midiCommand, channel, note, velocity, position, duration)
        end

    end

    function add_midi_note_to_region(midiCommand, channel, note_pitch, note_velocity, start_time, duration)

        -- Create a new note and add it to the command
        local new_note = ARDOUR.LuaAPI.new_noteptr(
                channel, -- Channel (0 for default)
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
                    time = chord_pattern_marker_time
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
                else
                    print("Calling inversion algorithm ", hand_config.inversion_alg, " with parameters ", chord_str, previous_inversion, previous_chord_str, previous_octave_adjustment, print_table(previous_chord_notes), print_table(hand_config))
                    local choose_inversion = inversion_algorithms[hand_config.inversion_alg]
                    inversion, octave_adjustment, chord_notes =
                        choose_inversion(chord_str, previous_inversion, previous_chord_str, previous_octave_adjustment, previous_chord_notes, hand_config)
                    print("Inversion algorithm returned ", inversion, octave_adjustment, print_table(chord_notes))
                end

                -- Optimize the chord notes for playability
                local key = parse_chord(chord_str)
                -- optimize_chord(notes, root_note, max_notes_per_hand, max_hand_span, priority_intervals)
                local optimized_chord_notes = optimize_chord(chord_notes, note_map[key], hand_config.notes_per_hand, hand_config.hand_span, hand_config.priority_intervals)

                add_chord_to_midi(midiCommand, hand_config.channel,
                        start_time + midi_region:start():beats(), duration,
                        hand_config.velocity, optimized_chord_notes)

                print("Adding chord ", chord_str, " at ", start_time, " with duration ", duration,
                        " for hand ", hand, " inversion ", inversion, " hand octave ", hand_config.octave,
                        " octave adjustment ", octave_adjustment,
                        " chord_notes ", print_table(chord_notes))

                -- Add generated chord notes to the marker object
                marker.chord_notes = optimized_chord_notes

                -- Update previous settings based on hand
                previous_inversion = inversion
                previous_octave_adjustment = octave_adjustment
                -- Save current chord string and notes for the next iteration
                previous_chord_str = chord_str
                -- Remember chord notes before they were optimized
                previous_chord_notes = chord_notes

            end

        end

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
            priority_intervals = get_config_values("priority_intervals", _priority_intervals)[hand],
            inversion_alg = get_config_values("inversion_alg", _inversion_algorithm)[hand],
            style = get_config_values("style", _style)[hand]
        }
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
    _inversion_algorithm = {1,1}
    _style = {"jazz", "jazz"}
    -- Define priority intervals per hand
    _priority_intervals = {{0,7,3,4},{0, 3, 4, 10, 11}}

    ticks_per_beat = 1920.0

    inversion_algorithms = {
        choose_inversion_1,
        choose_inversion_2
    }

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
                end
            end
        end

        if #possible_inversions == 0 then
            print("Error: No valid inversions generated for chord: " .. chord_str)
            return nil, nil, {}
        end

        -- If there's no previous chord, choose a random inversion
        if not previous_chord_notes or #previous_chord_notes == 0 then
            math.randomseed(os.time()) -- Seed the random number generator
            local random_index = math.random(#possible_inversions)
            return possible_inversions[random_index].inversion,
                possible_inversions[random_index].octave_adjustment,
                possible_inversions[random_index].notes
        end

        -- Calculate voice leading scores for all inversions
        for _, inv in ipairs(possible_inversions) do
            inv.score, inv.notes = evaluate_single_hand(previous_chord_notes, inv.notes, hand_config, chord_type, key)
            print("current_notes ", print_table(inv.notes))
        end

        -- Sort inversions by voice leading score
        table.sort(possible_inversions, function(a, b) return a.score > b.score end)

        -- If the chord hasn't changed, we need to choose a different inversion
        if chord_str == previous_chord_str then
            -- Find the best inversion that's different from the previous one
            for _, inv in ipairs(possible_inversions) do
                if inv.inversion ~= previous_inversion or inv.octave_adjustment ~= previous_octave_adjustment then
                    return inv.inversion, inv.octave_adjustment, inv.notes
                end
            end
            -- If we couldn't find a different inversion, use one of the best ones
            local random_index = math.random(math.min(2, #possible_inversions))
            return possible_inversions[random_index].inversion,
                possible_inversions[random_index].octave_adjustment,
                possible_inversions[random_index].notes
        end

        -- Return the best inversion
        return possible_inversions[1].inversion,
            possible_inversions[1].octave_adjustment,
            possible_inversions[1].notes
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
        if hand == "left" then movement_threshold = movement_threshold * 0.8 end
        if total_movement > movement_threshold then
            total_score = total_score - (total_movement - movement_threshold)
        end

        -- Bonus for ergonomic hand positions
        if is_ergonomic_position(current_notes, hand_config) then
            total_score = total_score + 15
        end

        --print("Returning ", total_score, print_table(current_notes))
        return total_score, current_notes
    end

    function trim_chord(notes, prev_notes, hand_config, chord_type, key)

        --print("trim_chord ", print_table(notes), print_table(prev_notes), print_table(hand_config), chord_type, key)

        if #notes <= hand_config.notes_per_hand then
            return notes
        end

        local root = note_map[key]
        local note_weights = {}
        local priority_notes = get_priority_notes(chord_type, root, hand_config.hand)

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
        return {table.unpack(notes, 1, hand_config.notes_per_hand)}
    end

    function get_priority_notes(chord_quality, root, hand)
        local priorities = {}

        if hand == 1 then
            -- Left hand priorities focus on bass notes
            table.insert(priorities, root)
            table.insert(priorities, (root + 7) % 12)  -- Perfect fifth
            if chord_quality == "7" or chord_quality == "maj7" or chord_quality == "m7" then
                table.insert(priorities, (root + 10) % 12) -- Seventh
            end
            table.insert(priorities, (root + 3) % 12)  -- Third (major or minor)
            table.insert(priorities, (root + 4) % 12)  -- Major third (in case of major chord)
        else
            -- Right hand priorities focus on chord character
            if chord_quality == "major" then
                table.insert(priorities, (root + 4) % 12)  -- Major third
                table.insert(priorities, root)
                table.insert(priorities, (root + 7) % 12)  -- Perfect fifth
            elseif chord_quality == "m" then
                table.insert(priorities, (root + 3) % 12)  -- Minor third
                table.insert(priorities, root)
                table.insert(priorities, (root + 7) % 12)  -- Perfect fifth
            elseif chord_quality == "7" then
                table.insert(priorities, (root + 10) % 12) -- Minor seventh
                table.insert(priorities, (root + 4) % 12)  -- Major third
                table.insert(priorities, (root + 7) % 12)  -- Perfect fifth
                table.insert(priorities, root)
            elseif chord_quality == "dim" then
                table.insert(priorities, (root + 3) % 12)  -- Minor third
                table.insert(priorities, (root + 6) % 12)  -- Diminished fifth
                table.insert(priorities, (root + 9) % 12)  -- Diminished seventh
                table.insert(priorities, root)
            elseif chord_quality == "aug" then
                table.insert(priorities, (root + 4) % 12)  -- Major third
                table.insert(priorities, (root + 8) % 12)  -- Augmented fifth
                table.insert(priorities, root)
            elseif chord_quality == "sus4" then
                table.insert(priorities, (root + 5) % 12)  -- Perfect fourth
                table.insert(priorities, (root + 7) % 12)  -- Perfect fifth
                table.insert(priorities, root)
                -- Add more chord qualities as needed
            end
        end

        return priorities
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

    -- end new inversion algorithm 2

    return function()

        math.randomseed(os.time()) -- Seed the random number generator

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
                            time = first_marker_time
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
                            chord_pattern_interval_ticks = math.tointeger((chord_pattern_interval - chord_pattern_interval_beats) * ticks_per_beat)
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
                                -- Make sure next marker is after the first marker
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
                                    time = marker_time
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

end



