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
roof_hugger_cross_section_dimensions = [(0.074, 1.06, 4.5, 2.25, 0.25, 0.0, 90.0, 0.0, -35.0, 0.074*3, 0.074*3, 0.074*3),
                                        (0.074, 1.06, 4.5, 2.25, 0.25, 0.0, 90.0, 0.0, -35.0, 0.074*3, 0.074*3, 0.074*3)]

roof_hugger_material_properties = [(29500.0, 0.30, 55.0, 70.0),
(29500.0, 0.30, 55.0, 70.0)]


                     #length, height
roof_hugger_punch_out_dimensions = (4.5, 1.625)

#Assume R-panel here.
new_deck_details = ("screw-fastened", 0.0179, 12.0, 0.212, 2.50)

new_deck_material_properties = (29500.0, 0.30, 55.0, 70.0)


roof_hugger_purlin_line = RoofHugger.define(design_code, segments, spacing, roof_slope, purlin_cross_section_dimensions, roof_hugger_cross_section_dimensions, roof_hugger_punch_out_dimensions, purlin_material_properties, roof_hugger_material_properties, deck_details, deck_material_properties, new_deck_details, new_deck_material_properties, frame_flange_width, support_locations, bridging_locations)


roof_hugger_purlin_line.applied_pressure = 0.00000001   #kips/in^2
roof_hugger_purlin_line = RoofHugger.analysis(roof_hugger_purlin_line)


roof_hugger_purlin_line.loading_direction = "gravity"
roof_hugger_purlin_line = RoofHugger.capacity(roof_hugger_purlin_line)






















