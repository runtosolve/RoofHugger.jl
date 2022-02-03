using CSV, DataFrames, PurlinLine, RoofHugger, StructuresKit, Plots




purlin_data = CSV.read("database/Purlins.csv",
DataFrame);

roof_hugger_data = CSV.read("database/Huggers.csv",
DataFrame);

existing_deck_data = CSV.read("database/Existing_Deck.csv",
DataFrame);

new_deck_data = CSV.read("database/New_Deck.csv",
DataFrame);




purlin_spans = (25.0, 25.0, 25.0, 25.0)

purlin_type_1 = "Z8x2.5 060"
purlin_type_2 = "Z8x2.5 075"

purlin_size_span_assignment = (1, 1, 1, 1)

purlin_laps = (2.0, 2.0, 2.0, 2.0, 2.0, 2.0)

purlin_spacing = 4.0

frame_flange_width = 16.0 

purlin_frame_connection = "Clip-mounted"

roof_slope = 1/12

existing_deck_type = "PBR 22 gauge"

span_segments = UI.define_span_segments(purlin_spans, purlin_laps, purlin_size_span_assignment)

span_segments = [(276.0, 1, 1),(252.0, 1, 1),(252.0, 1, 1),(276.0, 1, 1)]



purlin_line = UI.existing_roof_UI_mapper(purlin_spans, purlin_laps, purlin_spacing, roof_slope, purlin_data, existing_deck_type, existing_deck_data, frame_flange_width, purlin_frame_connection, purlin_type_1, purlin_type_2, purlin_size_span_assignment);

# Lcrd = purlin_line.distortional_buckling_xx_pos[1].Lcr 

# M_start = purlin_line.internal_forces.Mxx

# using Dierckx
# spl = Spline1D(purlin_line.model.z, purlin_line.internal_forces.Mxx)

# M_end = [spl(purlin_line.model.z[i] + purlin_line.distortional_buckling_xx_pos[1].Lcr) for i in eachindex(purlin_line.model.z)]

# M1 = [minimum([abs(M_start[i]), abs(M_end[i])]) for i in eachindex(M_start)]
# M2 = -[maximum([abs(M_start[i]), abs(M_end[i])]) for i in eachindex(M_start)]

# Lm = Lcrd  .* ones(Float64, length(M1))
# L = Lcrd  .* ones(Float64, length(M1))


# Β = AISIS10016.app23333.(L, Lm, M1, M2)

# L=Lcrd
# Lm = Lcrd * 2
# M1 = 75.0
# M2 = 75.0
# Β_test = AISIS10016.app23333.(L, Lm, M1, M2)


# plot(purlin_line.model.z, M1./M2)

# plot(purlin_line.model.z, Β)

# plot(purlin_line.model.z, M1)
# plot!(purlin_line.model.z, M2)
# M2[end-1]
# M1[end-1]

roof_hugger_type = "Model C 1.83 16g"

hugger_window_dimensions = (2.5, 1.625)  #(width, height) in inches

new_deck_type = "PBR 22 gauge"



roof_hugger_purlin_line = UI.retrofit_UI_mapper(purlin_line, roof_hugger_data, roof_hugger_type, new_deck_type, new_deck_data, hugger_window_dimensions);



# Lcrd = roof_hugger_purlin_line.distortional_buckling_xx_pos[1].Lcr




# plot(purlin_line.model.z, M2)

# # M1 = -0
# # M2 = -75.0
# Lm = Lcrd .* ones(Float64, length(M1))
# L = minimum([Lcrd, Lm])
# Β = AISIS10016.app23333(L, Lm, M1, M2)



# roof_hugger_purlin_line.internal_forces.Mxx[1]

# L = 25*12.0
# Lcrd = roof_hugger_purlin_line.distortional_buckling_xx_pos[1].Lcr
# AISIS10016.app23333(L, Lm, M1, M2)


plot(purlin_line.model.z, purlin_line.model.u, markershape = :o)
plot(purlin_line.model.z, purlin_line.model.v, markershape = :o)
plot(purlin_line.model.z, purlin_line.model.ϕ, markershape = :o)

plot(purlin_line.model.z, purlin_line.internal_forces.Mxx, markershape = :o)
plot(purlin_line.model.z, purlin_line.internal_forces.Myy, markershape = :o)
plot(purlin_line.model.z, purlin_line.internal_forces.T, markershape = :o)
plot(purlin_line.model.z, purlin_line.internal_forces.Vyy, markershape = :o)

purlin_line.failure_location
purlin_line.failure_limit_state
purlin_line.applied_pressure*1000*144


PurlinLine.calculate_support_reactions(purlin_line.inputs.support_locations, purlin_line.model.z, purlin_line.internal_forces.Vyy)


findfirst(x->x≈324.0, purlin_line.model.z)
findfirst(x->x≈876.0, purlin_line.model.z)

purlin_line.internal_forces.Mxx[23]

purlin_line.distortional_flexural_strength_xx[1]

purlin_line.expected_strengths.eMnd_xx[24]

plot(purlin_line.model.z, purlin_line.expected_strengths.eMnd_xx, markershape = :o)

purlin_line.expected_strengths.eMnd_xx[12]

roof_hugger_purlin_line.failure_location
roof_hugger_purlin_line.failure_limit_state
roof_hugger_purlin_line.applied_pressure*1000*144

roof_hugger_purlin_line.expected_strengths

show(roof_hugger_purlin_line.yielding_flexural_strength_xx)


plot(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.expected_strengths.eMnℓ_xx)

plot(purlin_line.model.z, purlin_line.expected_strengths.eMnℓ_xx)


plot(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.flexure_torsion_demand_to_capacity.action_Mxx)
plot!(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.flexure_torsion_demand_to_capacity.action_Myy)
plot!(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.flexure_torsion_demand_to_capacity.action_B)
plot!(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.flexure_torsion_demand_to_capacity.action_Myy_freeflange)
plot!(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.flexure_torsion_demand_to_capacity.interaction)