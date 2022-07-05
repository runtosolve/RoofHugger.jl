using CSV, DataFrames, RoofHugger, Plots




purlin_data = CSV.read("database/Purlins.csv",
DataFrame);

roof_hugger_data = CSV.read("database/Huggers.csv",
DataFrame);

existing_deck_data = CSV.read("database/Existing_Deck.csv",
DataFrame);

new_deck_data = CSV.read("database/New_Deck.csv",
DataFrame);





purlin_spans = (25.0)

purlin_type_1 = "C8x2.5 060"
purlin_type_2 = "none"

purlin_size_span_assignment = (1)

purlin_laps = ()

purlin_spacing = 4.0

frame_flange_width = 10.0 

purlin_frame_connection = "Clip-mounted"

roof_slope = 1/12

existing_deck_type = "PBR 22 gauge"

span_segments = UI.define_span_segments(purlin_spans, purlin_laps, purlin_size_span_assignment)

purlin_line = UI.existing_roof_UI_mapper(purlin_spans, purlin_laps, purlin_spacing, roof_slope, purlin_data, existing_deck_type, existing_deck_data, frame_flange_width, purlin_frame_connection, purlin_type_1, purlin_type_2, purlin_size_span_assignment);
	
plot(purlin_line.model.inputs.z, purlin_line.model.outputs.u)
# plot(purlin_line.model.z, purlin_line.model.v)
# plot(purlin_line.model.z, purlin_line.model.ϕ)

# plot(purlin_line.model.z, purlin_line.internal_forces.Mxx, markershape = :o)
# plot(purlin_line.model.z, purlin_line.internal_forces.Myy, markershape = :o)
# plot(purlin_line.model.z, purlin_line.internal_forces.T, markershape = :o)
# plot(purlin_line.model.z, purlin_line.internal_forces.Vyy, markershape = :o)

purlin_line.failure_location
purlin_line.failure_limit_state
purlin_line.applied_pressure*1000*144



roof_hugger_type = "Model C 1.83 16g"

hugger_window_dimensions = (2.5, 1.625)  #(width, height) in inches

new_deck_type = "PBR 22 gauge"



roof_hugger_purlin_line = UI.retrofit_UI_mapper(purlin_line, roof_hugger_data, roof_hugger_type, new_deck_type, new_deck_data, hugger_window_dimensions);


roof_hugger_purlin_line.applied_pressure*1000*144




UI.plot_purlin_geometry(purlin_line.inputs.cross_section_dimensions[1][2], purlin_line.cross_section_data[1].node_geometry[:,1], purlin_line.cross_section_data[1].node_geometry[:,2], roof_slope)


UI.plot_roof_hugger_purlin_geometry(roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[1][1], roof_hugger_purlin_line.purlin_cross_section_data[1].node_geometry[:,1], roof_hugger_purlin_line.purlin_cross_section_data[1].node_geometry[:,2], roof_slope, roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].node_geometry[:,1], roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].node_geometry[:,2], roof_hugger_purlin_line.roof_hugger_cross_section_data[1].node_geometry[:,1], roof_hugger_purlin_line.roof_hugger_cross_section_data[1].node_geometry[:,2])

UI.plot_net_section_roof_hugger_purlin_geometry(purlin_line.inputs.cross_section_dimensions[1][2], roof_hugger_purlin_line.purlin_cross_section_data[1].node_geometry[:,1], roof_hugger_purlin_line.purlin_cross_section_data[1].node_geometry[:,2], roof_hugger_purlin_line.roof_hugger_cross_section_data[1].node_geometry[:,1], roof_hugger_purlin_line.roof_hugger_cross_section_data[1].node_geometry[:,2], roof_slope, roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].node_geometry[:,1],  roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].node_geometry[:,2], roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[1].node_geometry)




roof_hugger_purlin_line.purlin_cross_section_data[1].node_geometry[:,1]

roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].node_geometry[:,1]




