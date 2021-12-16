### A Pluto.jl notebook ###
# v0.17.2

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ e37326d5-d9c8-4512-960f-82d912c00273
begin
    import Pkg
    Pkg.activate()

    using PlutoUI, Images, Dates, CSV, DataFrames, PurlinLine, RoofHugger, StructuresKit

	local_path = "/Users/crismoen/.julia/dev/RoofHugger/UI/"

	purlin_data = CSV.read(local_path * "database/Purlins.csv",
                             DataFrame);

	roof_hugger_data = CSV.read(local_path * "database/Huggers.csv",
                             DataFrame);

	existing_deck_data = CSV.read(local_path * "database/Existing_Deck.csv",
                             DataFrame);

	new_deck_data = CSV.read(local_path * "database/New_Deck.csv",
                             DataFrame);
	
end;

# ╔═╡ 2a2939b5-b0de-4b51-9a14-3fdf5d439b93
load(local_path * "roof-hugger-logo-2.png")

# ╔═╡ c2353bb3-ee8c-4d55-9447-470427c22b06
@bind project_details TextField((30,5); default="Project details")

# ╔═╡ 96f90537-0b4d-4d48-927b-01492e3789ef
@bind report_date DateField(default=today())

# ╔═╡ 99299f0c-30ee-4807-a7a2-d4509b4680ab
md" ## Build existing roof system."

# ╔═╡ 5d180e53-27aa-4bb2-9ab1-81cc2737ab3b
purlin_spans = (25.0, 25.0, 25.0, 20.0)  #ft

# ╔═╡ 1d9b00aa-7f6b-4f7e-9da8-e1f0b1ace647
md"""
Purlin sizes $(@bind purlin_type_1 Select(["none"; purlin_data[:, 1]]))
$(@bind purlin_type_2 Select(["none"; purlin_data[:, 1]]))
"""

# ╔═╡ bafb4c6d-a36e-438d-be55-a29abcf1efc4
purlin_size_span_assignment = (1, 2, 2, 1)

# ╔═╡ 710a97bb-6cd1-457c-a352-23428408de55
purlin_laps = (2.5, 1.5, 2.5, 1.5, 3.2, 1.7)  #ft

# ╔═╡ dde7f4c2-2212-4244-a78b-8fe12b6c8d0e
purlin_spacing = 4.0  #ft

# ╔═╡ 1a1727db-c828-4317-8ccd-2be491ee48c0
frame_flange_width = 16.0  #in.

# ╔═╡ 37bb5287-53cf-4322-b3f6-e16de0ba16c9
md"""Purlin-frame connection $(@bind purlin_frame_connection Select(["Clip-mounted", "Direct"]))"""

# ╔═╡ 9eebfba0-7913-40fd-bda5-b1d1178c741a
roof_slope = 1/12

# ╔═╡ e20e6735-ae8a-4ae0-99bb-f563a602afbc
md" Existing roof deck type $(@bind existing_deck_type Select(existing_deck_data[:, 1]))"

# ╔═╡ dd6bbcfe-b781-4bf5-8485-1c4b25380ebc
md" ## Calculate existing roof system strength."

# ╔═╡ acee7188-5a10-4e5c-9b35-b46d8d3c59de
function define_span_segments(purlin_spans, purlin_laps)

	num_spans = length(purlin_spans)

	span_segments = Array{Tuple{Float64, Int64, Int64}, 1}(undef, num_spans)

	lap_index = 1

	for i = 1:num_spans

		if i == 1 #first spans
	
			segment_length = purlin_spans[i]*12 - purlin_laps[lap_index]*12
			span_segments[i] = (segment_length, purlin_size_span_assignment[i], 1)
	
			lap_index = lap_index + 1
	
		elseif (i > 1) & (i != num_spans) #interior span
	
			segment_length = purlin_spans[i]*12 - purlin_laps[lap_index]*12 - purlin_laps[lap_index+1]*12
			span_segments[i] = (segment_length, purlin_size_span_assignment[i], 1)
	
			lap_index = lap_index + 2
	
		elseif i==num_spans #end span
	
			segment_length = purlin_spans[i]*12 - purlin_laps[lap_index]*12
			span_segments[i] = (segment_length, purlin_size_span_assignment[i], 1)
	
		end

	end

	return span_segments

end
	

# ╔═╡ 72eb55da-e2ee-4d0f-a3fe-c8f9d8e40295
span_segments = define_span_segments(purlin_spans, purlin_laps)

# ╔═╡ d9e0981c-9065-43bd-a943-d28cdb8ea5f3
function define_lap_segments(purlin_spans, purlin_laps, purlin_type_2)

	num_lap_segments = length(purlin_laps)

	lap_segments = Array{Tuple{Float64, Int64, Int64}, 1}(undef, num_lap_segments)

	if purlin_type_2 == "none"

		lap_section_offset = 0
	
	else
	
		lap_section_offset = 1
	
	end

	for i = 1:num_lap_segments

		lap_segments[i] = (purlin_laps[i]*12.0, lap_section_offset + i + 1, 1)

	end

	return lap_segments

end
	

# ╔═╡ f200647f-7551-442a-84ab-89ed340173fe
lap_segments = define_lap_segments(purlin_spans, purlin_laps, purlin_type_2)

# ╔═╡ 7c185202-88fa-45b6-9258-5f0b1927d82f
function define_purlin_line_segments(span_segments, lap_segments)

	num_spans = length(span_segments)
	
	num_purlin_line_segments = length(span_segments) + length(lap_segments)

	purlin_line_segments = Array{Tuple{Float64, Int64, Int64}, 1}(undef, num_purlin_line_segments)

	segment_index = 1

	lap_segment_index = 1	

	for i = 1:num_spans

		if i == 1 #first span
	
			purlin_line_segments[i] = span_segments[1]
			purlin_line_segments[i+1] = lap_segments[1]
	
			lap_segment_index = lap_segment_index + 1
			segment_index = segment_index + 2
	
		elseif (i > 1) & (i != num_spans) #interior span
	
			purlin_line_segments[segment_index] = lap_segments[lap_segment_index]
			purlin_line_segments[segment_index+1] = span_segments[i]
			purlin_line_segments[segment_index+2] = lap_segments[lap_segment_index+1]
	
			lap_segment_index = lap_segment_index + 2
			segment_index = segment_index + 3
	
		elseif i == num_spans  #end spa
	
			purlin_line_segments[segment_index] = lap_segments[lap_segment_index]
			purlin_line_segments[segment_index+1] = span_segments[i]
	
		end

	end

	return purlin_line_segments

end
	

# ╔═╡ 1fe8972f-6925-4593-8f22-32ae5989808c
purlin_line_segments = define_purlin_line_segments(span_segments, lap_segments)

# ╔═╡ 73705e3c-5da6-44c6-80e8-c205b0a6ef19
# purlin_cross_section_dimensions = [tuple([purlin_data[1, :][i] for i=2:17]...)]

# ╔═╡ f7ba3fa1-6c5e-47fc-b4d3-a2e7d2c59ca6
purlin_line_segments[1][2]

# ╔═╡ b26de0ff-e9d5-43a0-b2f8-33d703c71247
purlin_cross_section_dimensions = Vector{Tuple{String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64}}(undef, 3)

# ╔═╡ f5b73a33-78f8-42f6-8516-ab0a9871f9b3
typeof(purlin_cross_section_dimensions)

# ╔═╡ cea7e59e-afdb-4e9b-939e-0bbcc85569a5
sections = [purlin_line_segments[i][2] for i=1:length(purlin_line_segments)]

# ╔═╡ 042afd7d-be49-47ba-89cf-33ca9cdecdd8
lap_segments

# ╔═╡ d9df5f3d-8d45-4af4-b0ee-a9daab8a75ca
function define_lap_cross_section_properties(sections, section_index_1, section_index_2, lap_segments, purlin_segments, purlin_data)

	num_lap_segments = length(lap_segments)

	num_spans = length(purlin_segments)

	lap_cross_section_dimensions = Vector{Tuple{String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64}}(undef, 3)

	for i = 1:num_spans

		if i == 1 #first span
	
	lap_group = sections[1:4]

	
	

# ╔═╡ 1548882a-528e-4a7a-897e-616f3350bc42
function define_purlin_cross_section_dimensions(purlin_type_1, purlin_type_2, purlin_line_segments, purlin_data)

	section_index_1 = findfirst(==(purlin_type_1), purlin_data.section_name)

	if purlin_type_2 != "none"

		section_index_2 = findfirst(==(purlin_type_2), purlin_data.section_name)

	end

	sections = [purlin_line_segments[i][2] for i=1:length(purlin_line_segments)]

	num_sections = maximum(sections)
	
	purlin_cross_section_dimensions = Vector{Tuple{String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64}}(undef, 3)

	
	
	purlin_cross_section_dimensions = [tuple([purlin_data[section_index, :][i] for i=2:17]...)]
	
	

# ╔═╡ bc141195-cc2e-437d-907c-92ba11e4d55f
function existing_roof_UI_mapper(purlin_spans, purlin_laps, purlin_spacing, roof_slope, purlin_type, purlin_data, existing_deck_type, existing_deck_data, frame_flange_width, purlin_frame_connection, purlin_type_1, purlin_type_2, purlin_sizes_each_span)

	design_code = "AISI S100-16 ASD";

	num_purlin_segments = length(purlin_spans) + length(purlin_laps)	

	purlin_segments = Array{Tuple{Float64, Int64, Int64}, 1}(undef, num_purlin_segments)

	for i=1:num_purlin_segments

		if i == 1
		
			purlin_segments[i] = (purlin_spans[i]*12, purlin_sizes_each_span[i], 1)

	end

	purlin_spacing = purlin_spacing * 12.0

	roof_slope = rad2deg(atan(roof_slope))

	section_index = findfirst(==(purlin_type), purlin_data.section_name)
	
	purlin_cross_section_dimensions = [tuple([purlin_data[section_index, :][i] for i=2:17]...)]

	purlin_material_properties = [(29500.0, 0.30, 50.0, 70.0)];  #E, ν, Fy, Fu

	deck_index = findfirst(==(existing_deck_type), existing_deck_data.deck_name)
	existing_roof_panel_details = ("screw-fastened", existing_deck_data[deck_index, 2], existing_deck_data[deck_index, 3], existing_deck_data[deck_index, 4], existing_deck_data[deck_index, 5])

	existing_roof_panel_material_properties = (29500.0, 0.30, 55.0, 70.0);  #E, ν, Fy, Fu

	support_locations = [0.0, purlin_spans[end]*12.0]

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

end;

# ╔═╡ 155b41ff-d261-40df-807d-37027d220187
purlin_line = existing_roof_UI_mapper(purlin_spans, purlin_laps, purlin_spacing, roof_slope, purlin_type, purlin_data, existing_deck_type, existing_deck_data, frame_flange_width, purlin_frame_connection, purlin_type_1, purlin_type_2, purlin_sizes_each_span);

# ╔═╡ 40af7c07-ff81-4617-a220-9db2435247f2
begin

	xlims=(-9.0, 9.0);
	ylims = (0.0, 18.0);
	markershape = :none;
	StructuresKit.Visualize.show_multi_branch_cross_section(purlin_line.cross_section_data[1].node_geometry[:,1], purlin_line.cross_section_data[1].node_geometry[:,2], purlin_line.cross_section_data[1].element_definitions, markershape, xlims, ylims)

end

# ╔═╡ d2246077-5cf8-4f00-81af-9e5922bec619
md"**Existing roof system strength = $(round(purlin_line.applied_pressure*1000*144, digits=1)) psf**"

# ╔═╡ f67cf06d-2fe6-401f-ab71-1ecea9aa373f
md" ## Add Roof Hugger framing and the new roof."

# ╔═╡ 6cebdfda-7d1c-4df6-9e64-b6afad1c7f6d
md" Hugger size $(@bind roof_hugger_type Select(roof_hugger_data[:, 1]))"
		

# ╔═╡ 9a6b80f0-db1c-465a-8c59-b3c6ac181a1e
hugger_window_dimensions = (2.5, 1.625)  #(width, height) in inches

# ╔═╡ bfac357a-4b13-471e-84e8-edf4272065ba
md" New roof deck type $(@bind new_deck_type Select(new_deck_data[:, 1]))"

# ╔═╡ 4d47c72c-52a9-4caa-9516-446296e73443
md" ## Calculate retrofitted roof system strength."

# ╔═╡ 2df480a5-d4c2-4d8a-a78e-4952b23939f1
function retrofit_UI_mapper(purlin_line, roof_hugger_data, roof_hugger_type, existing_deck_type, existing_deck_data, new_deck_type, new_deck_data, hugger_window_dimensions)


	roof_hugger_section_index = findfirst(==(roof_hugger_type), roof_hugger_data.section_name)
	
	roof_hugger_cross_section_dimensions = [tuple([roof_hugger_data[roof_hugger_section_index, :][i] for i=2:13]...)]

	# Define the Roof Hugger material properties.
	roof_hugger_material_properties = [(29500.0, 0.30, 55.0, 70.0)]; #E, ν, Fy, Fu


	deck_index = findfirst(==(existing_deck_type), existing_deck_data.deck_name)
	
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

	#make this work for just one span for now
	segment_length = purlin_line.inputs.segments[1][1]
	hugger_purlin_segments = [(segment_length, 1, 1, 1, 1, 1)]

	# Assemble the purlin line model, now with the addition of Hugger Framing.

	roof_hugger_purlin_line = RoofHugger.define(purlin_line.inputs.design_code, hugger_purlin_segments, purlin_line.inputs.spacing, purlin_line.inputs.roof_slope, purlin_line.inputs.cross_section_dimensions, roof_hugger_cross_section_dimensions, roof_hugger_punch_out_dimensions, purlin_line.inputs.material_properties, roof_hugger_material_properties, purlin_line.inputs.deck_details, purlin_line.inputs.deck_material_properties, new_roof_panel_details, new_roof_panel_material_properties, purlin_line.inputs.frame_flange_width, purlin_line.inputs.support_locations, purlin_line.inputs.purlin_frame_connections, purlin_line.inputs.bridging_locations)


	# Run a test to calculate the expected roof system failure pressure including the Roof Hugger.
	roof_hugger_purlin_line.loading_direction = "gravity";
	roof_hugger_purlin_line = RoofHugger.capacity(roof_hugger_purlin_line)

	return roof_hugger_purlin_line

end;

# ╔═╡ 33f14b20-ecce-43e9-884b-629ef5a9ac40
roof_hugger_purlin_line = retrofit_UI_mapper(purlin_line, roof_hugger_data, roof_hugger_type, existing_deck_type, existing_deck_data, new_deck_type, new_deck_data, hugger_window_dimensions);

# ╔═╡ 828e6235-3b5f-47f0-a004-62b00bf14ff9
begin
	StructuresKit.Visualize.show_multi_branch_cross_section(roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].node_geometry[:,1], roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].node_geometry[:,2], roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].element_definitions, markershape, xlims, ylims)

end

# ╔═╡ 19a966f6-5f6f-4ddd-8ecf-91e7a0326839
begin
	StructuresKit.Visualize.show_multi_branch_cross_section(roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[1].node_geometry[:,1], roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[1].node_geometry[:,2], roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[1].element_definitions, markershape, xlims, ylims)

end

# ╔═╡ 8fe61b54-e9e1-4aa6-be50-b0812d86a1cf
md"**Retrofitted roof system strength = $(round(roof_hugger_purlin_line.applied_pressure*1000*144, digits=1)) psf**"

# ╔═╡ Cell order:
# ╠═e37326d5-d9c8-4512-960f-82d912c00273
# ╠═2a2939b5-b0de-4b51-9a14-3fdf5d439b93
# ╟─c2353bb3-ee8c-4d55-9447-470427c22b06
# ╟─96f90537-0b4d-4d48-927b-01492e3789ef
# ╟─99299f0c-30ee-4807-a7a2-d4509b4680ab
# ╠═5d180e53-27aa-4bb2-9ab1-81cc2737ab3b
# ╠═1d9b00aa-7f6b-4f7e-9da8-e1f0b1ace647
# ╠═bafb4c6d-a36e-438d-be55-a29abcf1efc4
# ╠═710a97bb-6cd1-457c-a352-23428408de55
# ╠═dde7f4c2-2212-4244-a78b-8fe12b6c8d0e
# ╠═1a1727db-c828-4317-8ccd-2be491ee48c0
# ╠═37bb5287-53cf-4322-b3f6-e16de0ba16c9
# ╠═9eebfba0-7913-40fd-bda5-b1d1178c741a
# ╟─e20e6735-ae8a-4ae0-99bb-f563a602afbc
# ╟─dd6bbcfe-b781-4bf5-8485-1c4b25380ebc
# ╠═acee7188-5a10-4e5c-9b35-b46d8d3c59de
# ╠═72eb55da-e2ee-4d0f-a3fe-c8f9d8e40295
# ╠═d9e0981c-9065-43bd-a943-d28cdb8ea5f3
# ╠═f200647f-7551-442a-84ab-89ed340173fe
# ╠═7c185202-88fa-45b6-9258-5f0b1927d82f
# ╠═1fe8972f-6925-4593-8f22-32ae5989808c
# ╠═73705e3c-5da6-44c6-80e8-c205b0a6ef19
# ╠═f7ba3fa1-6c5e-47fc-b4d3-a2e7d2c59ca6
# ╠═f5b73a33-78f8-42f6-8516-ab0a9871f9b3
# ╠═b26de0ff-e9d5-43a0-b2f8-33d703c71247
# ╠═cea7e59e-afdb-4e9b-939e-0bbcc85569a5
# ╠═042afd7d-be49-47ba-89cf-33ca9cdecdd8
# ╠═d9df5f3d-8d45-4af4-b0ee-a9daab8a75ca
# ╠═1548882a-528e-4a7a-897e-616f3350bc42
# ╠═bc141195-cc2e-437d-907c-92ba11e4d55f
# ╠═155b41ff-d261-40df-807d-37027d220187
# ╟─40af7c07-ff81-4617-a220-9db2435247f2
# ╟─d2246077-5cf8-4f00-81af-9e5922bec619
# ╟─f67cf06d-2fe6-401f-ab71-1ecea9aa373f
# ╟─6cebdfda-7d1c-4df6-9e64-b6afad1c7f6d
# ╠═9a6b80f0-db1c-465a-8c59-b3c6ac181a1e
# ╠═bfac357a-4b13-471e-84e8-edf4272065ba
# ╟─4d47c72c-52a9-4caa-9516-446296e73443
# ╠═2df480a5-d4c2-4d8a-a78e-4952b23939f1
# ╠═33f14b20-ecce-43e9-884b-629ef5a9ac40
# ╠═828e6235-3b5f-47f0-a004-62b00bf14ff9
# ╠═19a966f6-5f6f-4ddd-8ecf-91e7a0326839
# ╟─8fe61b54-e9e1-4aa6-be50-b0812d86a1cf
