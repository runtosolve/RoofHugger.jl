using RoofHugger


design_code = "AISI S100-16 ASD"

# Define the properties of each purlin segment along the line.
                #length, section_properties, material_properties
segments = [(23.0*12, 1, 1),
                (2.0*12, 2, 1),
                (2.0*12, 2, 1),
                (23.0*12, 1, 1)]

# Define the purlin spacing.
spacing = 60.0;  #in.

# Define the roof slope.
roof_slope = 0.0;   #degrees

#Define the purlin cross-section type.
purlin_cross_section_dimensions = [("Z", 0.059, 0.91, 2.5, 8.0, 2.5, 0.91, -50.0, 0.0, 90.0, 0.0, -50.0, 3*0.059, 3*0.059, 3*0.059, 3*0.059),
                                        ("Z", 0.049, 0.91, 2.5, 8.0, 2.5, 0.91, -50.0, 0.0, 90.0, 0.0, -50.0, 3*0.059, 3*0.059, 3*0.059, 3*0.059)]

purlin_material_properties = [(29500.0, 0.30, 55.0, 70.0),
                              (29500.0, 0.30, 55.0, 70.0)]

#type="screw-fastened", thickness, fastener spacing, fastener diameter, fastener_shear_strength
#type="standing seam", thickness, clip spacing, clip stiffness

deck_details = ("screw-fastened", 0.0179, 12.0, 0.212, 2.50)

deck_material_properties = (29500.0, 0.30, 55.0, 70.0)

frame_flange_width = 24.0

support_locations = [0.0, 25.0*12, 50.0*12]

bridging_locations =[0.0, 10.0*12, 50.0*12]

#Every purlin cross-section has a complementary RoofHugger as listed below.


# roof_hugger_cross_section_dimensions = [(0.060, 0.50, 1.5, 3.5, 1.0, 3.5, 1.5, 0.5, 45.0, 0.0, -90.0, 0.0, +90.0, 0.0, -45.0, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25),
#                         (0.060, 0.50, 1.5, 3.5, 1.0, 3.5, 1.5, 0.5, 45.0, 0.0, -90.0, 0.0, +90.0, 0.0, -45.0, 0.25, 0.25, 0.25, 0.25, 0.25, 0.25)]


roof_hugger_cross_section_dimensions = [(0.074, 1.06, 4.5, 2.25, 0.25, 0.0, 90.0, 0.0, -35.0, 0.074*3, 0.074*3, 0.074*3),
                                        (0.074, 1.06, 4.5, 2.25, 0.25, 0.0, 90.0, 0.0, -35.0, 0.074*3, 0.074*3, 0.074*3)]

roof_hugger_material_properties = [(29500.0, 0.30, 55.0, 70.0),
(29500.0, 0.30, 55.0, 70.0)]

#Assume R-panel here.
                     #length, height
roof_hugger_punch_out_dimensions = (4.5, 1.625)

new_deck_details = ("screw-fastened", 0.0179, 12.0, 0.212, 2.50)

new_deck_material_properties = (29500.0, 0.30, 55.0, 70.0)




    # #Create the RoofHugger data structure.
    # roof_hugger_purlin_line = RoofHuggerObject()

    # #Add RoofHugger user inputs to data structure.
    # roof_hugger_purlin_line.inputs = RoofHugger.Inputs(design_code, segments, spacing, roof_slope, purlin_cross_section_dimensions, roof_hugger_cross_section_dimensions, roof_hugger_punch_out_dimensions, purlin_material_properties, roof_hugger_material_properties, new_deck_details, new_deck_material_properties, frame_flange_width, support_locations, bridging_locations)

    # #Define RoofHugger cross-section data including nodal geometry, cross-section discretization and section properties.
    # roof_hugger_purlin_line.roof_hugger_cross_section_data = define_roof_hugger_cross_sections(roof_hugger_purlin_line)

    # using PurlinLine
    # #Create the PurlinLine data structure.
    # purlin_line = PurlinLineObject()

    # #Capture PurlinLine inputs.
    # purlin_line.inputs = PurlinLine.Inputs(design_code, segments, spacing, roof_slope, purlin_cross_section_dimensions, purlin_material_properties, deck_details, deck_material_properties, frame_flange_width, support_locations, bridging_locations)

    # #Calculate purlin and purlin free flange section properties.
    # roof_hugger_purlin_line.purlin_cross_section_data, roof_hugger_purlin_line.free_flange_cross_section_data = PurlinLine.calculate_purlin_section_properties(purlin_line)
    # purlin_line.cross_section_data = roof_hugger_purlin_line.purlin_cross_section_data
    # purlin_line.free_flange_cross_section_data = roof_hugger_purlin_line.free_flange_cross_section_data

    # #Define RoofHugger + purlin properties.
    # roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data = RoofHugger.define_roof_hugger_purlin_cross_sections(roof_hugger_purlin_line)

    # #Calculate deck bracing properties.  This is for the purlin to deck.   
    # #Assume for now that adding big screws and the RoofHugger does not change the stiffness properties. 
    # roof_hugger_purlin_line.bracing_data = PurlinLine.define_deck_bracing_properties(purlin_line)
    # purlin_line.bracing_data = PurlinLine.define_deck_bracing_properties(purlin_line)

    # #Calculate free flange shear flow properties, including bracing stiffness from web and conversion factor from purlin line load to shear flow.
    # #Assume shear flow is unchanged with addition of the RoofHugger.
    # roof_hugger_purlin_line.free_flange_data = PurlinLine.calculate_free_flange_shear_flow_properties(purlin_line)

    # #Calculate bracing properties for new roof deck to RoofHugger.
    # roof_hugger_purlin_line.new_deck_bracing_data = RoofHugger.define_new_deck_bracing_properties(roof_hugger_purlin_line)

    # #Calculate elastic buckling properties for RoofHugger and purlin as a cross-section together.
    # roof_hugger_purlin_line.local_buckling_xx_pos, roof_hugger_purlin_line.local_buckling_xx_neg, roof_hugger_purlin_line.local_buckling_yy_pos, roof_hugger_purlin_line.local_buckling_yy_neg, roof_hugger_purlin_line.distortional_buckling_xx_pos, roof_hugger_purlin_line.distortional_buckling_xx_neg = RoofHugger.calculate_elastic_buckling_properties(roof_hugger_purlin_line)

    # #Calculate net section properties and add to RoofHugger data structure.
    # roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data = RoofHugger.define_roof_hugger_purlin_net_section(roof_hugger_purlin_line)

    # #Calculate local buckling at the RoofHugger punchout.
    # roof_hugger_purlin_line.local_buckling_xx_net_pos = RoofHugger.calculate_net_section_local_buckling_properties(roof_hugger_purlin_line)


    # using StructuresKit
    # mode_index = 1
    # curve = roof_hugger_purlin_line.local_buckling_xx_net_pos[1].CUFSM_data.curve
    # shapes = roof_hugger_purlin_line.local_buckling_xx_net_pos[1].CUFSM_data.shapes
    # node = roof_hugger_purlin_line.local_buckling_xx_net_pos[1].CUFSM_data.node
    # elem = roof_hugger_purlin_line.local_buckling_xx_net_pos[1].CUFSM_data.elem
    # scale_x = 100000000.0
    # scale_y = 100000000.0
    # CUFSM.view_multi_branch_section_mode_shape(node, elem, shapes, mode_index, scale_x, scale_y)


    # #Calculate distortional buckling including the influence of the RoofHugger punchout.
    # roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data = RoofHugger.define_roof_hugger_purlin_distortional_net_section(roof_hugger_purlin_line)

    # roof_hugger_purlin_line.distortional_buckling_xx_net_pos = RoofHugger.calculate_net_section_distortional_buckling_properties(roof_hugger_purlin_line)








    # using Plots
    # plot(roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[1].node_geometry[:,1], roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[1].node_geometry[:,2], seriestype = :scatter)

    # #Calculate local buckling at the RoofHugger punchout.
    # roof_hugger_purlin_line.local_buckling_xx_net_pos = calculate_net_section_local_buckling_properties(roof_hugger_purlin_line)











roof_hugger_purlin_line = RoofHugger.define(design_code, segments, spacing, roof_slope, purlin_cross_section_dimensions, roof_hugger_cross_section_dimensions, roof_hugger_punch_out_dimensions, purlin_material_properties, roof_hugger_material_properties, deck_details, deck_material_properties, new_deck_details, new_deck_material_properties, frame_flange_width, support_locations, bridging_locations)


roof_hugger_purlin_line.applied_pressure = 0.00000001
roof_hugger_purlin_line = RoofHugger.analysis(roof_hugger_purlin_line)


roof_hugger_purlin_line.loading_direction = "gravity"
roof_hugger_purlin_line = RoofHugger.capacity(roof_hugger_purlin_line)






















