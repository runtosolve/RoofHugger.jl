module RoofHugger_UI

function define_lap_section_types(purlin_size_span_assignment)

	#There are 3 possible combinations of purlin types at a lap: 1-1, 2-2, or 1-2.

	num_laps = length(purlin_size_span_assignment) - 1

	lap_section_types = Array{String}(undef, num_laps)

	for i=1:num_laps

		purlin_span_1 = purlin_size_span_assignment[i]
		purlin_span_2 = purlin_size_span_assignment[i+1]

		if (purlin_span_1 == purlin_span_2) & (purlin_span_1 == 1)

			lap_section_types[i] = "1-1"

		elseif (purlin_span_1 == purlin_span_2) & (purlin_span_1 == 2)

			lap_section_types[i] = "2-2"

		elseif purlin_span_1 != purlin_span_2

			lap_section_types[i] = "1-2"

		end

	end

	return lap_section_types

end

function define_lap_section_index(lap_section_types)

	num_lap_sections = length(lap_section_types)
	
	num_unique_lap_sections = length(unique(lap_section_types))

	unique_lap_sections = unique(lap_section_types)

	lap_section_index = Array{Int64}(undef, num_lap_sections)

	for i = 1:num_unique_lap_sections

		index = findall(x->x==unique_lap_sections[i], lap_section_types)

		lap_section_index[index] .= 2 + i

	end

	return lap_section_index

end

function define_lap_segments(purlin_laps, purlin_size_span_assignment)

	num_interior_supports = trunc(Int, length(purlin_laps)/2)

	lap_segments = Array{Tuple{Float64, Int64, Int64}, 1}(undef, num_interior_supports * 2)

	lap_section_types = define_lap_section_types(purlin_size_span_assignment)

	lap_section_index = define_lap_section_index(lap_section_types)

	for i = 1:num_interior_supports

		lap_segments[2*i - 1] = (purlin_laps[2*i - 1]*12.0, lap_section_index[i], 1)
		lap_segments[2*i] = (purlin_laps[2*i]*12.0, lap_section_index[i], 1)

	end

	return lap_segments

end

function define_purlin_line_segments(span_segments, lap_segments)

	num_spans = length(span_segments)
	
	num_purlin_line_segments = length(span_segments) + length(lap_segments)

	purlin_line_segments = Array{Tuple{Float64, Int64, Int64}, 1}(undef, num_purlin_line_segments)

	segment_index = 1

	lap_segment_index = 1	

	for i = 1:num_spans

		if i == 1 #first span
	
			purlin_line_segments[i] = span_segments[1]

			if num_spans > 1
				purlin_line_segments[i+1] = lap_segments[1]
	
				lap_segment_index = lap_segment_index + 1
				segment_index = segment_index + 2
			end
	
		elseif (i > 1) & (i != num_spans) #interior span
	
			purlin_line_segments[segment_index] = lap_segments[lap_segment_index]
			purlin_line_segments[segment_index+1] = span_segments[i]
			purlin_line_segments[segment_index+2] = lap_segments[lap_segment_index+1]
	
			lap_segment_index = lap_segment_index + 2
			segment_index = segment_index + 3
	
		elseif i == num_spans  #end span
	
			purlin_line_segments[segment_index] = lap_segments[lap_segment_index]
			purlin_line_segments[segment_index+1] = span_segments[i]
	
		end

	end

	return purlin_line_segments

end
	
function define_purlin_line_cross_section_dimensions(purlin_line_segments, lap_section_types, purlin_data, purlin_type_1, purlin_type_2)

	purlin_line_cross_section_indices = [purlin_line_segments[i][2] for i=1:length(purlin_line_segments)]

	unique_purlin_line_cross_section_indices = sort(unique(purlin_line_cross_section_indices))

	if !isempty(lap_section_types) #for multiple spans only
	
		if isempty(findall(x->x==2, unique_purlin_line_cross_section_indices)) #if there is no second purlin type defined, then add it, it won't be used though
	
			unique_purlin_line_cross_section_indices = [unique_purlin_line_cross_section_indices[1]; 2; unique_purlin_line_cross_section_indices[2:end]]
	
		end

	end

	num_purlin_line_cross_sections = length(unique_purlin_line_cross_section_indices)

	purlin_line_cross_section_dimensions = Vector{Tuple{String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64}}(undef, num_purlin_line_cross_sections)

	purlin_index_1 = findfirst(==(purlin_type_1), purlin_data.section_name)
	purlin_index_2 = findfirst(==(purlin_type_2), purlin_data.section_name)
	
	purlin_type_indices = [purlin_index_1; purlin_index_2]

	for i = 1:num_purlin_line_cross_sections

		cross_section_index = unique_purlin_line_cross_section_indices[i]

		if cross_section_index <= 2

			if purlin_type_2 == "none" #not used, set cross-section equal to purlin_type_1
	
		cross_section_index = unique_purlin_line_cross_section_indices[1]
	
			end
			
			purlin_line_cross_section_dimensions[i] = tuple([purlin_data[purlin_type_indices[cross_section_index], :][i] for i=2:17]...)

		elseif cross_section_index > 2 #these are the laps

			lap_type = lap_section_types[cross_section_index - 2]

			if lap_type == "1-1"

				cross_section_index = unique_purlin_line_cross_section_indices[1]

				baseline_cross_section_dimensions = deepcopy(purlin_data[purlin_type_indices[cross_section_index], :])

				#multiply base metal thickness by 2
				baseline_cross_section_dimensions[3] = baseline_cross_section_dimensions[3] * 2.0
				
				purlin_line_cross_section_dimensions[i] = tuple([baseline_cross_section_dimensions[i] for i=2:17]...)

			elseif lap_type == "2-2"

				cross_section_index = unique_purlin_line_cross_section_indices[2]

				baseline_cross_section_dimensions = deepcopy(purlin_data[purlin_type_indices[cross_section_index], :])

				#multiply base metal thickness by 2
				baseline_cross_section_dimensions[3] = baseline_cross_section_dimensions[3] * 2.0

				purlin_line_cross_section_dimensions[i] = tuple([baseline_cross_section_dimensions[i] for i=2:17]...)

			elseif lap_type == "1-2"

				cross_section_index = unique_purlin_line_cross_section_indices[1]

				baseline_cross_section_dimensions = deepcopy(purlin_data[purlin_type_indices[cross_section_index], :])

				#add the purlin 1 and purlin 2 thicknesses together
				baseline_cross_section_dimensions[3] = baseline_cross_section_dimensions[3] + purlin_line_cross_section_dimensions[2][2]

				
				purlin_line_cross_section_dimensions[i] = tuple([baseline_cross_section_dimensions[i] for i=2:17]...)

			end

		end

	end

	return purlin_line_cross_section_dimensions

end

function existing_roof_UI_mapper(purlin_spans, purlin_laps, purlin_spacing, roof_slope, purlin_data, existing_deck_type, existing_deck_data, frame_flange_width, purlin_frame_connection, purlin_type_1, purlin_type_2, purlin_size_span_assignment)

	design_code = "AISI S100-16 ASD"

	span_segments = define_span_segments(purlin_spans, purlin_laps)

	lap_section_types = define_lap_section_types(purlin_size_span_assignment)

	lap_segments = define_lap_segments(purlin_laps, purlin_size_span_assignment)

	purlin_segments = define_purlin_line_segments(span_segments, lap_segments)

	purlin_spacing = purlin_spacing * 12.0

	roof_slope = rad2deg(atan(roof_slope))

	purlin_cross_section_dimensions = define_purlin_line_cross_section_dimensions(purlin_segments, lap_section_types, purlin_data, purlin_type_1, purlin_type_2)

	purlin_material_properties = [(29500.0, 0.30, 50.0, 70.0)];  #E, ν, Fy, Fu

	deck_index = findfirst(==(existing_deck_type), existing_deck_data.deck_name)
	existing_roof_panel_details = ("screw-fastened", existing_deck_data[deck_index, 2], existing_deck_data[deck_index, 3], existing_deck_data[deck_index, 4], existing_deck_data[deck_index, 5])

	existing_roof_panel_material_properties = (29500.0, 0.30, 55.0, 70.0);  #E, ν, Fy, Fu

	support_locations = [0.0; collect(cumsum(purlin_spans .* 12.0))]

	if purlin_frame_connection == "Clip-mounted"
		
		purlin_frame_connections = "anti-roll clip"
		
	elseif purlin_frame_connection == "Direct"
		
		purlin_frame_connections = "bottom flange connection"
		
	end

	intermediate_bridging_locations = [ ]

		purlin_line = PurlinLine.build(design_code, purlin_segments, purlin_spacing, roof_slope, purlin_cross_section_dimensions, purlin_material_properties, existing_roof_panel_details, existing_roof_panel_material_properties, frame_flange_width, support_locations, purlin_frame_connections, intermediate_bridging_locations)

	#Run a gravity test.
	purlin_line.loading_direction = "gravity"
	purlin_line = PurlinLine.test(purlin_line)

	return purlin_line

end

function retrofit_UI_mapper(purlin_line, roof_hugger_data, roof_hugger_type, existing_deck_type, existing_deck_data, new_deck_type, new_deck_data, hugger_window_dimensions)


	roof_hugger_section_index = findfirst(==(roof_hugger_type), roof_hugger_data.section_name)
	
	roof_hugger_cross_section_dimensions = [tuple([roof_hugger_data[roof_hugger_section_index, :][i] for i=2:13]...)]

	# Define the Roof Hugger material properties.
	roof_hugger_material_properties = [(29500.0, 0.30, 55.0, 70.0)]; #E, ν, Fy, Fu
	
	# Define the Roof Hugger punchout dimensions.  
	roof_hugger_punch_out_dimensions = [hugger_window_dimensions]; #length, height

  	#Define the new deck details.

	new_deck_index = findfirst(==(new_deck_type), new_deck_data.deck_name)


	if !ismissing(new_deck_data[new_deck_index, 3]) #screw_fastened

		new_roof_panel_details = ("screw-fastened", new_deck_data[new_deck_index, 2], new_deck_data[new_deck_index, 3], new_deck_data[new_deck_index, 4], new_deck_data[new_deck_index, 5])

	elseif ismissing(new_deck_data[new_deck_index, 3]) #SSR
	
		new_roof_panel_details = ("MR-24", new_deck_data[new_deck_index, 7], new_deck_data[new_deck_index, 6], 0.0, 0.0)

	end

	new_roof_panel_material_properties = (29500.0, 0.30, 55.0, 70.0)

	#length, purlin section_properties, Hugger section properties, purlin material_properties, Hugger material properties, Hugger punchout dimensions

	num_segments = length(purlin_line.inputs.segments)
	segment_lengths = [purlin_line.inputs.segments[i][1] for i=1:num_segments]
	# segment_length = purlin_line.inputs.segments[1][1]

	hugger_purlin_segments = Vector{Tuple{Float64, Int64, Int64, Int64, Int64, Int64}}(undef, num_segments)

	for i =1:num_segments

		hugger_purlin_segments[i] = (segment_lengths[i], 1, 1, 1, 1, 1)

	end

	# Assemble the purlin line model, now with the addition of Hugger Framing.

	roof_hugger_purlin_line = RoofHugger.define(purlin_line.inputs.design_code, hugger_purlin_segments, purlin_line.inputs.spacing, purlin_line.inputs.roof_slope, purlin_line.inputs.cross_section_dimensions, roof_hugger_cross_section_dimensions, roof_hugger_punch_out_dimensions, purlin_line.inputs.material_properties, roof_hugger_material_properties, purlin_line.inputs.deck_details, purlin_line.inputs.deck_material_properties, new_roof_panel_details, new_roof_panel_material_properties, purlin_line.inputs.frame_flange_width, purlin_line.inputs.support_locations, purlin_line.inputs.purlin_frame_connections, purlin_line.inputs.bridging_locations)


	# Run a test to calculate the expected roof system failure pressure including the Roof Hugger.
	roof_hugger_purlin_line.loading_direction = "gravity";
	roof_hugger_purlin_line = RoofHugger.capacity(roof_hugger_purlin_line)

	return roof_hugger_purlin_line

end

end
