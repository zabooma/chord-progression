ardour { ["type"] = "EditorAction", name = "[A] Create chord markers",
         license = "MIT",
         author = "Frank Povazanj",
         description = [[Creates markers based on the progression string. v0.0.1]]
}

function icon (params)
    return function(ctx, width, height, fg)
        local txt = Cairo.PangoLayout(ctx, "ArdourMono " .. math.ceil(height / 3) .. "px")
        txt:set_text("CM")
        local tw, th = txt:get_pixel_size()
        ctx:set_source_rgba(ARDOUR.LuaAPI.color_to_rgba(fg))
        ctx:move_to(.5 * (width - tw), .5 * (height - th))
        txt:show_in_cairo_context(ctx)
    end
end

function factory ()
    return function()

        function parse_markers(markerString, repeatCount)
            -- Default repeat count is 1 if not specified
            repeatCount = repeatCount or 1
            local markers = {}

            -- Helper function to parse a single pattern
            local function parsePattern(pattern, startBar)
                local currentBar = startBar or 1
                local currentBeat = 1
                local patternMarkers = {}

                -- Remove optional first and last bar characters
                pattern = pattern:gsub("^|", ""):gsub("|$", "")

                -- Split into bars
                for barContent in (pattern .. "|"):gmatch("(.-)|") do
                    -- Trim spaces at the start and end of the bar
                    barContent = barContent:match("^%s*(.-)%s*$")
                    currentBeat = 1  -- Reset beat at start of bar

                    -- Handle empty bar
                    if barContent == "" then
                        currentBar = currentBar + 1
                        goto continue
                    end

                    -- Split the bar content into elements by spaces
                    local elements = {}
                    for element in barContent:gmatch("%S+") do
                        table.insert(elements, element)
                    end

                    -- Process the elements
                    for _, element in ipairs(elements) do
                        if element ~= "/" then
                            table.insert(patternMarkers, {
                                name = element,
                                bar = currentBar,
                                beat = currentBeat
                            })
                        end
                        currentBeat = currentBeat + 1
                    end

                    currentBar = currentBar + 1

                    ::continue::
                end

                return patternMarkers, currentBar - startBar
            end

            -- Generate markers for all repetitions
            local patternMarkers, barCount = parsePattern(markerString, 1)
            for i = 0, repeatCount - 1 do
                local startBar = 1 + (i * barCount)
                for _, marker in ipairs(patternMarkers) do
                    table.insert(markers, {
                        name = marker.name,
                        bar = marker.bar + (i * barCount),
                        beat = marker.beat
                    })
                end
            end

            return markers
        end

        function pad_right(str, length, char)
            char = char or " "  -- Default padding character is a space
            return str .. string.rep(char, length - #str)
        end

        function get_inputs()

            local dialog_options = {
                {type = "label", title =  pad_right("", 120, ".")},
                {type = "number", key = "repeats", title = "Repeat", min = 1, max = 64, default = 1, step = 1},
                {type = "checkbox", key = "chords", title = "Chord markers", default = true},
                {type = "entry", key = "progression", title = "Progression"}
            }


            -- Open config dialog for the selected region
            local dialog = LuaDialog.Dialog("Create markers starting at head position", dialog_options)
            local response = dialog:run()
            dialog = nil

            if response then
                print("Response: ", print_table(response))
                return response.progression, response.chords, math.floor(response.repeats)
            else
                return nil
            end
        end

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

        function get_last_marker()
            -- iterate over all location markers
            local loc = Session:locations() -- all marker locations
            local last_marker
            for l in loc:list():iter() do
                last_marker = l
            end
            return last_marker
        end

        -- Main code

        -- Get the current playhead position in samples
        local playhead_position_samples = Session:transport_sample()
        local playhead_position = Temporal.timepos_t(playhead_position_samples)
        print("playhead_position: ", playhead_position, " in beats ", playhead_position:beats())

        -- Get signature at the head position
        local tempoMap = Temporal.TempoMap:read()
        local signature = tempoMap:meter_at(playhead_position)
        print("Signature ", signature:divisions_per_bar(), " / ", signature:note_value())

        -- number of beats  per bar is defined as signature:divisions_per_bar(
        local num_beats_per_bar = signature:divisions_per_bar()

        local progression, chords, repeats = get_inputs()
        print("progression, chords, repeats ", progression, chords, repeats)

        if progression then
            local markers = parse_markers(progression, repeats)
            print("Markers: ", print_table(markers))

            for _, marker in ipairs(markers) do

                -- Create marker
                local marker_position_in_beats = (playhead_position:beats() + Temporal.Beats((marker.bar - 1) * num_beats_per_bar + marker.beat - 1, 0))
                local marker_position_timepos_t = Temporal.timepos_t.from_ticks(marker_position_in_beats:to_ticks())
                local m = Editor:mouse_add_new_marker (marker_position_timepos_t, ARDOUR.LocationFlags.IsMark, 0)

                -- Change marker name
                local last_marker =  get_last_marker()
                if last_marker then
                    local marker_name = marker.name
                    if chords then
                        marker_name = "." .. marker_name
                    end
                    last_marker:set_name(marker_name)
                end
            end


        end

    end
end