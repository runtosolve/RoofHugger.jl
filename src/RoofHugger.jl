module RoofHugger

using PurlinLine
using StructuresKit

using NumericalIntegration

export define, analysis, capacity, define_roof_hugger_cross_sections, RoofHuggerObject, Inputs

struct Inputs

    design_code::String
    segments::Vector{Tuple{Float64, Int64, Int64}}
    spacing::Float64
    roof_slope::Float64
    purlin_cross_section_dimensions::Vector{Tuple{String, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64}}
    roof_hugger_cross_section_dimensions::Vector{NTuple{12, Float64}}
    roof_hugger_punch_out_dimensions::NTuple{2, Float64}
    purlin_material_properties::Vector{NTuple{4, Float64}}
    roof_hugger_material_properties::Vector{NTuple{4, Float64}}
    new_deck_details::Tuple{String, Float64, Float64, Float64, Float64}
    new_deck_material_properties::NTuple{4, Float64}
    frame_flange_width::Float64
    support_locations::Vector{Float64}
    bridging_locations::Vector{Float64}

end

mutable struct RoofHuggerObject

    inputs::RoofHugger.Inputs

    applied_pressure::Float64

    loading_direction::String

    purlin_cross_section_data::Array{PurlinLine.CrossSectionData}

    free_flange_cross_section_data::Array{PurlinLine.CrossSectionData}

    roof_hugger_cross_section_data::Array{PurlinLine.CrossSectionData}

    roof_hugger_purlin_cross_section_data::Array{PurlinLine.CrossSectionData}

    roof_hugger_purlin_net_cross_section_data::Array{PurlinLine.CrossSectionData}

    roof_hugger_purlin_distortional_net_cross_section_data::Array{PurlinLine.CrossSectionData}

    bracing_data::Array{PurlinLine.BracingData}

    new_deck_bracing_data::Array{PurlinLine.BracingData}

    free_flange_data::Array{PurlinLine.FreeFlangeData}

    local_buckling_xx_pos::Array{PurlinLine.ElasticBucklingData}
    local_buckling_xx_net_pos::Array{PurlinLine.ElasticBucklingData}
    local_buckling_xx_neg::Array{PurlinLine.ElasticBucklingData}
    local_buckling_yy_pos::Array{PurlinLine.ElasticBucklingData}
    local_buckling_yy_neg::Array{PurlinLine.ElasticBucklingData}
    distortional_buckling_xx_pos::Array{PurlinLine.ElasticBucklingData}
    distortional_buckling_xx_net_pos::Array{PurlinLine.ElasticBucklingData}
    distortional_buckling_xx_neg::Array{PurlinLine.ElasticBucklingData}

    yielding_flexural_strength_xx::Array{PurlinLine.YieldingFlexuralStrengthData}
    yielding_flexural_strength_xx_net::Array{PurlinLine.YieldingFlexuralStrengthData}
    yielding_flexural_strength_yy::Array{PurlinLine.YieldingFlexuralStrengthData}
    yielding_flexural_strength_free_flange_yy::Array{PurlinLine.YieldingFlexuralStrengthData}

    local_global_flexural_strength_xx::Array{PurlinLine.LocalGlobalFlexuralStrengthData}
    local_global_flexural_strength_yy::Array{PurlinLine.LocalGlobalFlexuralStrengthData}
    local_global_flexural_strength_free_flange_yy::Array{PurlinLine.LocalGlobalFlexuralStrengthData}

    distortional_flexural_strength_xx::Array{PurlinLine.DistortionalFlexuralStrengthData}

    torsion_strength::Array{PurlinLine.TorsionStrengthData}

    shear_strength_purlin::Array{PurlinLine.ShearStrengthData}
    shear_strength_roof_hugger::Array{PurlinLine.ShearStrengthData}
    shear_strength::Array{PurlinLine.ShearStrengthData}

    web_crippling::Array{PurlinLine.WebCripplingData}

    model::ThinWalledBeam.Model

    free_flange_model::BeamColumn.Model

    internal_forces::PurlinLine.InternalForceData

    free_flange_internal_forces::PurlinLine.InternalForceData

    support_reactions::PurlinLine.Reactions

    demand_to_capacity::PurlinLine.DemandToCapacity

    RoofHuggerObject() = new()

end


function define_roof_hugger_cross_sections(roof_hugger_purlin_line)

    num_roof_hugger_sections = size(roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions)[1]

    cross_section_data = Vector{PurlinLine.CrossSectionData}(undef, num_roof_hugger_sections)

    for i = 1:num_roof_hugger_sections

        #Map dimensions to cross-section nomenclature.
        t = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][1]
        b_bottom = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][2]
        h = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][3]
        b_top = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][4]
        d_top = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][5]
        α1 = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][6]
        α2 = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][7]
        α3 = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][8]
        α4 = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][9]
        r1 = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][10]
        r2 = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][11]
        r3 = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][12]

        #Define straight-line lengths on the top cross-section surface.   
        ΔL = [b_bottom - t, h - t, b_top, d_top]
        θ = [α1, α2, α3, α4]

        #Note that the outside radius is used at the top flanges, and the inside radius is used for the bottom flange.
        radius = [r1-t, r2, r3]

        closed_or_open = 1

        n = [4, 6, 4, 4]
        n_radius = [4, 4, 4]

        roof_hugger_section = CrossSection.Feature(ΔL, θ, n, radius, n_radius, closed_or_open)

        #Calculate the out-to-out surface coordinates.
        xcoords_out, ycoords_out = CrossSection.get_xy_coordinates(roof_hugger_section)

        #Calculate centerline coordinates.
        unitnormals = CrossSection.surface_normals(xcoords_out, ycoords_out, closed_or_open)
        nodenormals = CrossSection.avg_node_normals(unitnormals, closed_or_open)
        xcoords_center, ycoords_center = CrossSection.xycoords_along_normal(xcoords_out, ycoords_out, nodenormals, -t/2)

        #Shift y coordinates so that the bottom face is at y = 0.
        ycoords_center = ycoords_center .- minimum(ycoords_center) .+ t/2

        #Shift x coordinates so that the bottom flange centerline is at x = 0.
        index = floor(Int, n[1]/2)  + 1
        xcoords_center = xcoords_center .- xcoords_center[index]

        #Package nodal geometry.
        node_geometry = [xcoords_center ycoords_center]

        #Define cross-section element connectivity and thicknesses.
        num_cross_section_nodes = length(xcoords_center)
        element_info = [1:(num_cross_section_nodes - 1) 2:num_cross_section_nodes ones(num_cross_section_nodes - 1) * t]

        #Calculate section properties.
        section_properties = CUFSM.cutwp_prop2(node_geometry, element_info)

        #Add cross section information to data structure.
        cross_section_data[i] = PurlinLine.CrossSectionData(n, n_radius, node_geometry, element_info, section_properties)

    end

    return cross_section_data

end



function define_roof_hugger_purlin_cross_sections(roof_hugger_purlin_line)

    #Assume that for each purlin segment, there is a purlin cross-section and a RoofHugger cross-section defined.
    num_strengthened_sections = size(roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions)[1]

    roof_hugger_purlin_cross_section_data = Vector{PurlinLine.CrossSectionData}(undef, num_strengthened_sections)

    for i=1:num_strengthened_sections

        #Find purlin top flange centerline.
        purlin_top_flange_centerline_index = sum(roof_hugger_purlin_line.purlin_cross_section_data[i].n[1:3]) + floor(Int,roof_hugger_purlin_line.purlin_cross_section_data[i].n[4]/2) + sum(roof_hugger_purlin_line.purlin_cross_section_data[i].n_radius[1:3]) + 1
        purlin_top_flange_centerline_geometry = roof_hugger_purlin_line.purlin_cross_section_data[i].node_geometry[purlin_top_flange_centerline_index, :]

        #Shift RoofHugger geometry to sit on top of purlin top flange.
        roof_hugger_node_geometry = deepcopy(roof_hugger_purlin_line.roof_hugger_cross_section_data[i].node_geometry)
        purlin_t = roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions[i][2]

        roof_hugger_node_geometry[:, 1] = roof_hugger_node_geometry[:, 1] .+ purlin_top_flange_centerline_geometry[1]
        roof_hugger_node_geometry[:, 2] = roof_hugger_node_geometry[:, 2] .+ purlin_top_flange_centerline_geometry[2] .+ purlin_t/2 #check this

        # #Shift RoofHugger node numbers after purlin node numbers.

        num_purlin_nodes = size(roof_hugger_purlin_line.purlin_cross_section_data[i].node_geometry)[1]
        roof_hugger_element_definitions = deepcopy(roof_hugger_purlin_line.roof_hugger_cross_section_data[i].element_definitions)

        roof_hugger_element_definitions[:,1:2] = roof_hugger_element_definitions[:,1:2] .+ num_purlin_nodes

        #Combine node geometry and element definitions for RoofHugger and purlin.

        roof_hugger_purlin_node_geometry = [roof_hugger_purlin_line.purlin_cross_section_data[i].node_geometry; roof_hugger_node_geometry]

        roof_hugger_purlin_element_definitions = [roof_hugger_purlin_line.purlin_cross_section_data[i].element_definitions; roof_hugger_element_definitions]

        #Calculate section properties.
        roof_hugger_purlin_section_properties = CUFSM.cutwp_prop2(roof_hugger_purlin_node_geometry, roof_hugger_purlin_element_definitions)

        #Combine discretization info.
        n = [roof_hugger_purlin_line.purlin_cross_section_data[i].n; roof_hugger_purlin_line.roof_hugger_cross_section_data[i].n]
        n_radius = [roof_hugger_purlin_line.purlin_cross_section_data[i].n_radius; roof_hugger_purlin_line.roof_hugger_cross_section_data[i].n_radius]

        #Add cross section information to data structure.
        roof_hugger_purlin_cross_section_data[i] = PurlinLine.CrossSectionData(n, n_radius, roof_hugger_purlin_node_geometry, roof_hugger_purlin_element_definitions, roof_hugger_purlin_section_properties)

    end

    return roof_hugger_purlin_cross_section_data

end

function define_new_deck_bracing_properties(roof_hugger_purlin_line)

    num_purlin_segments = size(roof_hugger_purlin_line.inputs.segments)[1]

    bracing_data = Array{PurlinLine.BracingData, 1}(undef, num_purlin_segments)

    if roof_hugger_purlin_line.inputs.new_deck_details[1] == "screw-fastened"

        #Define the deck to RoofHugger screw-fastened connection spacing.
        deck_roof_hugger_fastener_spacing = roof_hugger_purlin_line.inputs.new_deck_details[3]

        #Define the deck to purlin screw diameter.
        deck_roof_hugger_fastener_diameter = roof_hugger_purlin_line.inputs.new_deck_details[4]

        #Define the nominal shear strength of the typical screw.
        Fss = roof_hugger_purlin_line.inputs.new_deck_details[5]

        #Define the roof deck base metal thickness.
        t_roof_deck = roof_hugger_purlin_line.inputs.new_deck_details[2]

        #Define roof deck steel elastic modulus.
        E_roof_deck = roof_hugger_purlin_line.inputs.new_deck_material_properties[1]

        #Define roof deck steel ultimate yield stress.
        Fu_roof_deck = roof_hugger_purlin_line.inputs.new_deck_material_properties[4]

        #Define the distance between fasteners as the distortional discrete bracing length.
        Lm = deck_roof_hugger_fastener_spacing

        #Loop over all the purlin segments in the line.  
        #Assume that there is a RoofHugger segment for every purlin segment.
        for i = 1:num_purlin_segments

            #Define the section property index associated with purlin segment i.
            section_index = roof_hugger_purlin_line.inputs.segments[i][2]

            #Define the material property index associated with purlin segment i.
            material_index = roof_hugger_purlin_line.inputs.segments[i][3]

            #Define RoofHugger steel elastic modulus.
            E_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_material_properties[material_index][1]

            #Define RoofHugger steel Poisson's ratio.
            μ_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_material_properties[material_index][2]

            #Define RoofHugger steel ultimate stress.
            Fu_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_material_properties[material_index][4]

            #Define the RoofHugger top flange width.
            b_top = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[section_index][4]

            #Define RoofHugger base metal thickness.
            t_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[section_index][1]

            #Define out-to-out RoofHugger web depth.
            ho = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[section_index][3]

            #Define RoofHugger top flange lip length.
            d_top = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[section_index][5]

            #Define RoofHugger top flange lip angle from the horizon, in degrees.
            θ_top = abs(roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[section_index][9])

            #Define the location from the RoofHugger top flange pivot point to the fastener.  Assume the fastener is centered in the flange.
            c = b_top/2

            #Define the deck fastener pull-through plate stiffness.  Assume the fastener is centered between two panel ribs.
            kp = PurlinLine.deck_pull_through_fastener_stiffness(roof_hugger_purlin_line.inputs.new_deck_material_properties, b_top, t_roof_deck)

            #Apply Cee or Zee binary.   Assume the RoofHugger behaves like a Z for this stiffness calculation.
            CorZ = 1
      
            #Calculate the rotational stiffness provided to each RoofHugger flange by the screw-fastened connection between the deck and the RoofHugger.  It is assumed that the deck flexural stiffness is much higher than the connection stiffness.
            kϕ = Connections.cfs_rot_screwfastened_k(b_top, c, deck_roof_hugger_fastener_spacing, t_roof_hugger, kp, E_roof_hugger, CorZ)

            #Calculate the RoofHugger distortional buckling half-wavelength.

            #Calculate top flange + lip section properties.
            Af, Jf, Ixf, Iyf, Ixyf, Cwf, xof,  hxf, hyf, yof = AISIS10016.table23131(CorZ, t_roof_hugger, b_top, d_top, θ_top)

            #Calculate the RoofHugger distortional buckling half-wavelength.
            Lcrd, L = AISIS10016.app23334(ho, μ_roof_hugger, t_roof_hugger, Ixf, xof, hxf, Cwf, Ixyf, Iyf, Lm)

            #If Lcrd is longer than the fastener spacing, then the distortional buckling will be restrained by the deck.
            if Lcrd >= Lm
                kϕ_dist = kϕ
            else
                kϕ_dist = 0.0
            end

            #Approximate the lateral stiffness provided to the top of each RoofHugger flange by the screw-fastened connection between the deck and the RoofHugger.

            #Calculate the stiffness of a single screw-fastened connection.
            Ka, ψ, α, β, Ke = Connections.cfs_trans_screwfastened_k(t_roof_deck, t_roof_hugger, E_roof_deck, E_roof_hugger, Fss, Fu_roof_deck, Fu_roof_hugger, deck_roof_hugger_fastener_diameter)

            #Convert the discrete stiffness to a distributed stiffness, divide by the fastener spacing.
            kx = Ke / deck_roof_hugger_fastener_spacing

            #Collect all the outputs.
            bracing_data[i] = PurlinLine.BracingData(kp, kϕ, kϕ_dist, kx, Lcrd, Lm)

        end

    end

    return bracing_data

end



function calculate_elastic_buckling_properties(roof_hugger_purlin_line)

    num_purlin_segments = size(roof_hugger_purlin_line.inputs.segments)[1]

    #Initialize vectors that will carry output.
    local_buckling_xx_pos = Array{PurlinLine.ElasticBucklingData, 1}(undef, num_purlin_segments)
    local_buckling_xx_neg = Array{PurlinLine.ElasticBucklingData, 1}(undef, num_purlin_segments)
    
    local_buckling_yy_pos = Array{PurlinLine.ElasticBucklingData, 1}(undef, num_purlin_segments)
    local_buckling_yy_neg = Array{PurlinLine.ElasticBucklingData, 1}(undef, num_purlin_segments)
    
    distortional_buckling_xx_pos = Array{PurlinLine.ElasticBucklingData, 1}(undef, num_purlin_segments)
    distortional_buckling_xx_neg = Array{PurlinLine.ElasticBucklingData, 1}(undef, num_purlin_segments)
 
    #Loop over all the purlin segments in the line.
    for i = 1:num_purlin_segments

        #Define the section property index associated with purlin segment i.
        section_index = roof_hugger_purlin_line.inputs.segments[i][2]

        #Define the material property index associated with purlin segment i.
        material_index = roof_hugger_purlin_line.inputs.segments[i][3]
        
        #Map section properties to CUFSM.
        A = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.A
        xcg = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.xc
        zcg = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.yc
        Ixx = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.Ixx
        Izz = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.Iyy
        Ixz = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.Ixy
        thetap = rad2deg(roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.θ)
        I11 = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.I1
        I22 = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.I2
        unsymm = 0  #Sets Ixz=0 if unsymm = 0

        #Define the number of cross-section nodes.
        num_cross_section_nodes = size(roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].node_geometry)[1]

        #Initialize CUFSM node matrix.
        node = zeros(Float64, (num_cross_section_nodes, 8))

        #Add node numbers to node matrix.
        node[:, 1] .= 1:num_cross_section_nodes

        #Add nodal coordinates to node matrix.
        node[:, 2:3] .= roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].node_geometry

        #Add nodal restraints to node matrix.
        node[:, 4:7] .= ones(num_cross_section_nodes,4)

        #Define number of cross-section elements.
        num_cross_section_elements = size(roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].element_definitions)[1]

        #Initialize CUFSM elem matrix.
        elem = zeros(Float64, (num_cross_section_elements, 5))

        #Add element numbers to elem matrix.
        elem[:, 1] = 1:num_cross_section_elements

        #Add element connectivity and thickness to elem matrix.
        elem[:, 2:4] .= roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].element_definitions

        #Add element material reference to elem matrix.
        elem[:, 5] .= ones(num_cross_section_elements) * 100
                                
        #Find the purlin top flange centerline node.
        #lip curve bottom_flange curve web curve top_flange
        center_top_flange_purlin_node = sum(roof_hugger_purlin_line.purlin_cross_section_data[section_index].n[1:3]) + sum(roof_hugger_purlin_line.purlin_cross_section_data[section_index].n_radius[1:3]) + floor(Int, roof_hugger_purlin_line.purlin_cross_section_data[section_index].n[4]/2) + 1  #This floor command is a little dangerous.

        #Find the RoofHugger top flange centerline node.
        num_purlin_nodes = size(roof_hugger_purlin_line.purlin_cross_section_data[section_index].node_geometry)[1]
        center_roof_hugger_flange_node = num_purlin_nodes + sum(roof_hugger_purlin_line.roof_hugger_cross_section_data[section_index].n[1:2]) + sum(roof_hugger_purlin_line.roof_hugger_cross_section_data[section_index].n_radius[1:2]) + floor(Int, roof_hugger_purlin_line.roof_hugger_cross_section_data[section_index].n[3]/2) + 1
       
        #Set up springs in CUFSM.  There can be translational and rotational springs at the purlin top flange, and at the RoofHugger top flange.
        springs = [1 center_top_flange_purlin_node 0 roof_hugger_purlin_line.bracing_data[i].kx 0 0 roof_hugger_purlin_line.bracing_data[i].kϕ_dist 0 0 0
                   2 center_roof_hugger_flange_node 0 roof_hugger_purlin_line.new_deck_bracing_data[i].kx 0 0 roof_hugger_purlin_line.new_deck_bracing_data[i].kϕ_dist 0 0 0]
        
        #Constrain the RoofHugger bottom flange to the purlin top flange in all dof (x, z, y, and q).
        roof_hugger_bottom_flange_centerline_node = num_purlin_nodes + floor(Int, roof_hugger_purlin_line.roof_hugger_cross_section_data[section_index].n[1] / 2) + 1
        
        #node#e DOFe coeff node#k DOFk
        constraints = [center_top_flange_purlin_node 1 1.0 roof_hugger_bottom_flange_centerline_node 1
                       center_top_flange_purlin_node 2 1.0 roof_hugger_bottom_flange_centerline_node 2
                       center_top_flange_purlin_node 3 1.0 roof_hugger_bottom_flange_centerline_node 3
                       center_top_flange_purlin_node 4 1.0 roof_hugger_bottom_flange_centerline_node 4]

        # constraints = 0

        #Assume here that purlin and RoofHugger have the same elastic modulus.
        E = roof_hugger_purlin_line.inputs.purlin_material_properties[material_index][1]
        ν = roof_hugger_purlin_line.inputs.purlin_material_properties[material_index][2]
        G = E / (2 *(1 + ν))
        prop = [100 E E ν ν G]

        neigs = 1  #just need the first mode 

        ###Local buckling - xx axis, positive 

        #Add reference stress to node matrix.

        #Define reference loads.  
        P = 0.0
        Mxx = 1.0  #assume centroidal moment always for now
        Mzz = 0.0
        M11 = 0.0
        M22 = 0.0

        #Define the RoofHugger flange width.
        b_top = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[section_index][4]  #this is a little dangerous
        length_inc = 5
        lengths = collect(0.25*b_top:0.75*b_top/length_inc:1.0*b_top)   #define to catch the local minimum

        CUFSM_local_xx_pos_data, Mcrℓ_xx_pos, Lcrℓ_xx_pos = PurlinLine.get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)   
        
        # mode_index = 4
        # shapes = CUFSM_local_xx_pos_data.shapes
        # scale_x = 1.0
        # scale_y = 1.0
        # # CUFSM.view_multi_branch_section_mode_shape(node, elem, shapes, mode_index, scale_x, scale_y)

        # half_wavelength = [curve[i,1][1] for i=1:length(lengths)]
        # load_factor = [curve[i,1][2] for i=1:length(lengths)]


        #Needed this deepcopy here to make struct work correctly.  Otherwise 'node' just kept changing.

        local_buckling_xx_pos[i] = PurlinLine.ElasticBucklingData(CUFSM_local_xx_pos_data, Lcrℓ_xx_pos, Mcrℓ_xx_pos)

        ###Local buckling - xx axis, negative 

        #Add reference stress to node matrix.

        #Define reference loads.  
        P = 0.0
        Mxx = -1.0  #assume centroidal moment always for now
        Mzz = 0.0
        M11 = 0.0
        M22 = 0.0

        #Use purlin web depth here.
        h = roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions[section_index][5]  #this is a little dangerous
        length_inc = 5
        lengths = collect(0.25*h:0.75*h/length_inc:1.0*h)   #define to catch the local minimum

        CUFSM_local_xx_neg_data, Mcrℓ_xx_neg, Lcrℓ_xx_neg = PurlinLine.get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)

        local_buckling_xx_neg[i] = PurlinLine.ElasticBucklingData(CUFSM_local_xx_neg_data, Lcrℓ_xx_neg, Mcrℓ_xx_neg)


        ###local buckling - yy axis, positive  (compression at tip of purlin bottom flange lip)
        
        #Define reference loads.  
        P = 0.0
        Mxx = 0.0  
        Mzz = 1.0  #assume centroidal moment always for now
        M11 = 0.0
        M22 = 0.0

        #Try Lcrd of the purlin as a guide for finding the half-wavelength of the flange and lip (unstiffened element).
        #It turns out that for the case I studied, the purlin web buckled, not the purlin bottom flange lip.  Makes sense I guess.
        length_inc = 5
        lengths = collect(0.25 * roof_hugger_purlin_line.bracing_data[i].Lcrd:(1.0 * roof_hugger_purlin_line.bracing_data[i].Lcrd)/length_inc:1.25 * roof_hugger_purlin_line.bracing_data[i].Lcrd)   #define to catch the local minimum

        CUFSM_local_yy_pos_data, Mcrℓ_yy_pos, Lcrℓ_yy_pos = PurlinLine.get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)

    #                 mode_index = 3
    # shapes = CUFSM_local_yy_pos_data.shapes
    # scale_x = 1.0
    # scale_y = 1.0
    # CUFSM.view_multi_branch_section_mode_shape(node, elem, shapes, mode_index, scale_x, scale_y)


        local_buckling_yy_pos[i] = PurlinLine.ElasticBucklingData(CUFSM_local_yy_pos_data, Lcrℓ_yy_pos, Mcrℓ_yy_pos)
  
        ###local buckling - yy axis, negative  (compression in RoofHugger top flange lip)
        
        #Define reference loads.  
        P = 0.0
        Mxx = 0.0  
        Mzz = -1.0  #assume centroidal moment always for now
        M11 = 0.0
        M22 = 0.0
    
        length_inc = 5
        #Try Lcrd of the RoofHugger as a guide for finding the half-wavelength of the flange and lip (unstiffened element).
        lengths = collect(0.25 * roof_hugger_purlin_line.new_deck_bracing_data[i].Lcrd:(1.0 * roof_hugger_purlin_line.new_deck_bracing_data[i].Lcrd)/length_inc:1.25 * roof_hugger_purlin_line.new_deck_bracing_data[i].Lcrd)   #define to catch the local minimum

        CUFSM_local_yy_neg_data, Mcrℓ_yy_neg, Lcrℓ_yy_neg = PurlinLine.get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)

        local_buckling_yy_neg[i] = PurlinLine.ElasticBucklingData(CUFSM_local_yy_neg_data, Lcrℓ_yy_neg, Mcrℓ_yy_neg)

        ###Distortional buckling - xx axis, positive

        #Define reference loads.  
        P = 0.0
        Mxx = 1.0  #assume centroidal moment always for now
        Mzz = 0.0
        M11 = 0.0
        M22 = 0.0

        length_inc = 5
        #Use RoofHugger Lcrd here.
        lengths = collect(0.75 * roof_hugger_purlin_line.new_deck_bracing_data[i].Lcrd:(0.50 * roof_hugger_purlin_line.new_deck_bracing_data[i].Lcrd)/length_inc:1.25 * roof_hugger_purlin_line.new_deck_bracing_data[i].Lcrd)  #define to catch distortional minimum

        CUFSM_dist_pos_data, Mcrd_pos, Lcrd_pos_CUFSM = PurlinLine.get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)

        distortional_buckling_xx_pos[i] = PurlinLine.ElasticBucklingData(CUFSM_dist_pos_data, Lcrd_pos_CUFSM, Mcrd_pos)


 

         ###Distortional buckling - xx axis, negative

        #Define reference loads.  
        P = 0.0
        Mxx = -1.0  #assume centroidal moment always for now
        Mzz = 0.0
        M11 = 0.0
        M22 = 0.0

        length_inc = 5
        #Use purlin Lcrd here.
        lengths = collect(0.75 * roof_hugger_purlin_line.bracing_data[i].Lcrd:(0.50 * roof_hugger_purlin_line.bracing_data[i].Lcrd)/length_inc:1.25 * roof_hugger_purlin_line.bracing_data[i].Lcrd)  #define to catch distortional minimum

        CUFSM_dist_neg_data, Mcrd_neg, Lcrd_neg_CUFSM = PurlinLine.get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)

        distortional_buckling_xx_neg[i] = PurlinLine.ElasticBucklingData(CUFSM_dist_neg_data, Lcrd_neg_CUFSM, Mcrd_neg)

    end

    return local_buckling_xx_pos, local_buckling_xx_neg, local_buckling_yy_pos, local_buckling_yy_neg, distortional_buckling_xx_pos, distortional_buckling_xx_neg


end

function define_roof_hugger_purlin_net_section(roof_hugger_purlin_line)

    num_purlin_sections = size(roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions)[1]

    cross_section_data = Vector{CrossSectionData}(undef, num_purlin_sections)

    for i=1:num_purlin_sections

        num_purlin_nodes = size(roof_hugger_purlin_line.purlin_cross_section_data[i].node_geometry)[1]

        #Find all cross-section nodes that are in the RoofHugger punchout region.
        roof_hugger_node_geometry = roof_hugger_purlin_line.roof_hugger_cross_section_data[i].node_geometry[:,1:2]
        hole_index = findall(x->x<roof_hugger_purlin_line.inputs.roof_hugger_punch_out_dimensions[2], roof_hugger_node_geometry[:,2])
    
        #Shift the cross-section node to match up with the punch out dimensions.
        h_purlin = roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions[i][5]
        roof_hugger_purlin_node_geometry = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[i].node_geometry[:,1:2]
        roof_hugger_purlin_node_geometry[hole_index[end] + num_purlin_nodes, 2] =  h_purlin + roof_hugger_purlin_line.inputs.roof_hugger_punch_out_dimensions[2]
    
        #Delete the nodes within the punchout region.
        remove_hole_nodes_index = hole_index[1:(end-1)] .+ num_purlin_nodes
        roof_hugger_purlin_node_geometry = roof_hugger_purlin_node_geometry[setdiff(1:end, remove_hole_nodes_index), :]
    
        #Remove elements at punchouts.
        roof_hugger_purlin_element_definitions = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[i].element_definitions
        remove_hole_elements_index = hole_index[1:end] .+ num_purlin_nodes .- 1
        roof_hugger_purlin_element_definitions = roof_hugger_purlin_element_definitions[setdiff(1:end, remove_hole_elements_index), :]
    
        #Update nodal connectivity.
        update_index = remove_hole_elements_index[1]
        num_removed_elements = length(remove_hole_elements_index)
    
        roof_hugger_purlin_element_definitions[update_index:end, 1:2] = roof_hugger_purlin_element_definitions[update_index:end, 1:2] .- num_removed_elements
    
        #Calculate section properties of net section at a RoofHugger punchout.
        section_properties = CUFSM.cutwp_prop2(roof_hugger_purlin_node_geometry, roof_hugger_purlin_element_definitions)
    
        #Add cross section information to data structure.
        cross_section_data[i] = PurlinLine.CrossSectionData(roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[i].n, roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[i].n_radius, roof_hugger_purlin_node_geometry, roof_hugger_purlin_element_definitions, section_properties)

    end

    return cross_section_data

end



function calculate_net_section_local_buckling_properties(roof_hugger_purlin_line)
        
    num_purlin_segments = size(roof_hugger_purlin_line.inputs.segments)[1]

    #Initialize vectors that will carry output.
    local_buckling_xx_net_pos = Array{PurlinLine.ElasticBucklingData, 1}(undef, num_purlin_segments)
    
    #Loop over all the purlin segments in the line.
    for i = 1:num_purlin_segments

        #Define the section property index associated with purlin segment i.
        section_index = roof_hugger_purlin_line.inputs.segments[i][2]

        #Define the material property index associated with purlin segment i.
        material_index = roof_hugger_purlin_line.inputs.segments[i][3]
        
        #Map section properties to CUFSM.
        A = roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].section_properties.A
        xcg = roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].section_properties.xc
        zcg = roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].section_properties.yc
        Ixx = roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].section_properties.Ixx
        Izz = roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].section_properties.Iyy
        Ixz = roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].section_properties.Ixy
        thetap = rad2deg(roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].section_properties.θ)
        I11 = roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].section_properties.I1
        I22 = roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].section_properties.I2
        unsymm = 0  #Sets Ixz=0 if unsymm = 0

        #Define the number of cross-section nodes.
        num_cross_section_nodes = size(roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].node_geometry)[1]

        #Initialize CUFSM node matrix.
        node = zeros(Float64, (num_cross_section_nodes, 8))

        #Add node numbers to node matrix.
        node[:, 1] .= 1:num_cross_section_nodes

        #Add nodal coordinates to node matrix.
        node[:, 2:3] .= roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].node_geometry

        #Add nodal restraints to node matrix.
        node[:, 4:7] .= ones(num_cross_section_nodes,4)

        #Define number of cross-section elements.
        num_cross_section_elements = size(roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].element_definitions)[1]

        #Initialize CUFSM elem matrix.
        elem = zeros(Float64, (num_cross_section_elements, 5))

        #Add element numbers to elem matrix.
        elem[:, 1] = 1:num_cross_section_elements

        #Add element connectivity and thickness to elem matrix.
        elem[:, 2:4] .= roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].element_definitions

        #Add element material reference to elem matrix.
        elem[:, 5] .= ones(num_cross_section_elements) * 100
                                
        #Find the purlin top flange centerline node.
        #lip curve bottom_flange curve web curve top_flange
        center_top_flange_purlin_node =  sum(roof_hugger_purlin_line.purlin_cross_section_data[section_index].n[1:3]) + sum(roof_hugger_purlin_line.purlin_cross_section_data[section_index].n_radius[1:3]) + floor(Int, roof_hugger_purlin_line.purlin_cross_section_data[section_index].n[4]/2) + 1  #This floor command is a little dangerous.

        #Find the RoofHugger top flange centerline nodes.
        num_roof_hugger_purlin_nodes = size(roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].node_geometry)[1]
        center_roof_hugger_flange_node = num_roof_hugger_purlin_nodes -  roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].n[end] - roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].n_radius[end] - floor(Int, roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].n[end-1]/2)

        #Set up springs in CUFSM.  There can be translational and rotational springs at the purlin top flange, and at each of the RoofHugger top flanges.
        springs = [1 center_top_flange_purlin_node 0 roof_hugger_purlin_line.bracing_data[i].kx 0 0 roof_hugger_purlin_line.bracing_data[i].kϕ_dist 0 0 0
                2 center_roof_hugger_flange_node 0 roof_hugger_purlin_line.new_deck_bracing_data[i].kx 0 0 roof_hugger_purlin_line.new_deck_bracing_data[i].kϕ_dist 0 0 0]

        constraints = 0

        #Assume here that purlin and RoofHugger have the same elastic modulus.
        E = roof_hugger_purlin_line.inputs.purlin_material_properties[material_index][1]
        ν = roof_hugger_purlin_line.inputs.purlin_material_properties[material_index][2]
        G = E / (2 *(1 + ν))
        prop = [100 E E ν ν G]

        neigs = 1  #just need the first mode 

        ###Local buckling - xx axis, positive 

        #Add reference stress to node matrix.

        #Define reference loads.  
        P = 0.0
        Mxx = 1.0  #assume centroidal moment always for now
        Mzz = 0.0
        M11 = 0.0
        M22 = 0.0

        #Define the length of the punchout.
        L_hole = roof_hugger_purlin_line.inputs.roof_hugger_punch_out_dimensions[1]  

        #Assume the buckling half-wavelength is longer than RoofHugger punchout.  This seems reasonable based on wavelength studies where the mininum was around 15 in. for the net section RoofHugger + purlin model.  
        lengths = [L_hole]

        CUFSM_local_xx_net_pos_data, Mcrℓ_xx_net_pos, Lcrℓ_xx_net_pos = PurlinLine.get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)   

        #Needed this deepcopy here to make struct work correctly.  Otherwise 'node' just kept changing.

        local_buckling_xx_net_pos[i] = PurlinLine.ElasticBucklingData(CUFSM_local_xx_net_pos_data, Lcrℓ_xx_net_pos, Mcrℓ_xx_net_pos)

    end

    return local_buckling_xx_net_pos

end


function calculate_yielding_flexural_strength(roof_hugger_purlin_line)

    num_purlin_segments = size(roof_hugger_purlin_line.inputs.segments)[1]

    #Initialize a vectors that will hold all the outputs.
    yielding_flexural_strength_xx = Array{YieldingFlexuralStrengthData, 1}(undef, num_purlin_segments)
    yielding_flexural_strength_xx_net = Array{YieldingFlexuralStrengthData, 1}(undef, num_purlin_segments)
    yielding_flexural_strength_yy = Array{YieldingFlexuralStrengthData, 1}(undef, num_purlin_segments)
    yielding_flexural_strength_free_flange_yy = Array{YieldingFlexuralStrengthData, 1}(undef, num_purlin_segments)


    for i = 1:num_purlin_segments

        #Define the section property index associated with purlin segment i.
        section_index = roof_hugger_purlin_line.inputs.segments[i][2]

        #Define the material property index associated with purlin segment i.
        material_index = roof_hugger_purlin_line.inputs.segments[i][3]

        ###strong axis flexure, local-global interaction
        Fy_purlin = roof_hugger_purlin_line.inputs.purlin_material_properties[material_index][3]
        Fy_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_material_properties[material_index][3]
        Ixx = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.Ixx
        cy_bottom = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.yc  #distance from neutral axis to bottom outer fiber

        roof_hugger_purlin_depth = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[section_index][3] + roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions[section_index][5]
        cy_top = roof_hugger_purlin_depth - cy_bottom #distance from neutral axis to top outer fiber
        Sxx_pos = Ixx/cy_top
        Sxx_neg = Ixx/cy_bottom
        My_xx_pos = Fy_roof_hugger * Sxx_pos #RoofHugger at top fiber
        My_xx_neg = Fy_purlin * Sxx_neg  #purlin is at bottom fiber
        My_xx = minimum([My_xx_pos My_xx_neg])  #first yield criterion for AISI 

        yielding_flexural_strength_xx[i] = PurlinLine.YieldingFlexuralStrengthData(Sxx_pos, Sxx_neg, My_xx_pos, My_xx_neg, My_xx, 0.0)   #make eMy zero here since it is not used

        ###strong axis flexure, local-global interaction, net section at a punchout
        Ixx_net = roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].section_properties.Ixx
        cy_bottom_net = roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[section_index].section_properties.yc  #distance from neutral axis to bottom outer fiber

        cy_top_net = roof_hugger_purlin_depth - cy_bottom_net #distance from neutral axis to top outer fiber
        Sxx_pos_net = Ixx_net/cy_top_net
        Sxx_neg_net = Ixx_net/cy_bottom_net
        My_xx_pos_net = Fy_roof_hugger * Sxx_pos_net #RoofHugger at top fiber
        My_xx_neg_net = Fy_purlin * Sxx_neg_net  #purlin is at bottom fiber
        My_xx_net = minimum([My_xx_pos_net My_xx_neg_net])  #first yield criterion for AISI 

        yielding_flexural_strength_xx_net[i] = PurlinLine.YieldingFlexuralStrengthData(Sxx_pos_net, Sxx_neg_net, My_xx_pos_net, My_xx_neg_net, My_xx_net, 0.0)   #make eMy zero here since it is not used


        ###weak axis flexure, local-global interaction
        Iyy = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.Iyy

        #distance from neutral axis to (-x or left) outer fiber
        #Positive moment is applied when this outer fiber is compressed.
        cx_minusx = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.xc - minimum(roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].node_geometry[:,1])
        #distance from neutral axis to (+x or right) outer fiber
        #Negative moment is applied when this outer fiber is compressed.
        cx_plusx = maximum(roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].node_geometry[:,1]) - roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.xc 
 
        Syy_pos = Iyy / cx_minusx
        Syy_neg = Iyy / cx_plusx
 
        My_yy_pos = Fy_purlin * Syy_pos  #outer fiber is the purlin
        My_yy_neg = Fy_roof_hugger *Syy_neg  #outer fiber is the RoofHugger.  This could be incorrect if RoofHugger yield stress is much higher than purlin yield stress!!!
        My_yy = minimum([My_yy_pos My_yy_neg])  #first yield criterion for AISI 
 
        yielding_flexural_strength_yy[i] = PurlinLine.YieldingFlexuralStrengthData(Syy_pos, Syy_neg, My_yy_pos, My_yy_neg, My_yy, 0.0)  #set eMy=0.0 for now

        ###free flange yy-axis, local-global interaction

        #define free flange properties
        Iyyf = roof_hugger_purlin_line.free_flange_cross_section_data[section_index].section_properties.Iyy

        #distance from neutral axis to (-x or left) outer fiber
        #Positive moment is applied when this outer fiber is compressed.
        cxf_minusx = roof_hugger_purlin_line.free_flange_cross_section_data[section_index].section_properties.xc - minimum(roof_hugger_purlin_line.free_flange_cross_section_data[section_index].node_geometry[:,1])
        #distance from neutral axis to (+x or right) outer fiber
        #Negative moment is applied when this outer fiber is compressed.
        cxf_plusx = maximum(roof_hugger_purlin_line.free_flange_cross_section_data[section_index].node_geometry[:,1]) - roof_hugger_purlin_line.free_flange_cross_section_data[section_index].section_properties.xc 

        Syy_pos_free_flange = Iyyf / cxf_minusx
        Syy_neg_free_flange = Iyyf / cxf_plusx

        My_yy_pos_free_flange = Fy_purlin * Syy_pos_free_flange
        My_yy_neg_free_flange = Fy_purlin * Syy_neg_free_flange
        My_yy_free_flange = minimum([My_yy_pos_free_flange My_yy_neg_free_flange])  #first yield criterion for AISI 

        #Factored yield moment is needed for the free flange to perform AISI interaction checks.

        if roof_hugger_purlin_line.inputs.design_code == "AISI S100-16 ASD"
            ASDorLRFD = 0
        elseif roof_hugger_purlin_line.inputs.design_code == "AISI S100-16 LRFD"
            ASDorLRFD = 1
        end

        Mcrℓ_yy_free_flange = 10.0^10 #Make this a big number so we just get back eMy
        My_yy_free_flange, eMy_yy_free_flange = AISIS10016.f321(My_yy_free_flange, Mcrℓ_yy_free_flange, ASDorLRFD)

        yielding_flexural_strength_free_flange_yy[i] = YieldingFlexuralStrengthData(Syy_pos_free_flange, Syy_neg_free_flange, My_yy_pos_free_flange, My_yy_neg_free_flange, My_yy_free_flange, eMy_yy_free_flange)

    end

    return yielding_flexural_strength_xx, yielding_flexural_strength_xx_net, yielding_flexural_strength_yy, yielding_flexural_strength_free_flange_yy

end

function calculate_local_global_flexural_strength(roof_hugger_purlin_line)

    num_purlin_segments = size(roof_hugger_purlin_line.inputs.segments)[1]

    #Initialize a vectors that will hold all the outputs.
    local_global_flexural_strength_xx = Array{LocalGlobalFlexuralStrengthData, 1}(undef, num_purlin_segments)
    local_global_flexural_strength_yy = Array{LocalGlobalFlexuralStrengthData, 1}(undef, num_purlin_segments)
    local_global_flexural_strength_free_flange_yy = Array{LocalGlobalFlexuralStrengthData, 1}(undef, num_purlin_segments)


    if roof_hugger_purlin_line.inputs.design_code == "AISI S100-16 ASD"
        ASDorLRFD = 0
    elseif roof_hugger_purlin_line.inputs.design_code == "AISI S100-16 LRFD"
        ASDorLRFD = 1
    end

    for i = 1:num_purlin_segments

        Mne_xx = roof_hugger_purlin_line.yielding_flexural_strength_xx[i].My  #handle global buckling in the ThinWalledBeam second order analysis

        #Define Mcrℓ as the mininum of [Mcrℓ, Mcrℓ_hole] as suggested in AISI S100-16.

        Mcrℓ = minimum([roof_hugger_purlin_line.local_buckling_xx_pos[i].Mcr, roof_hugger_purlin_line.local_buckling_xx_net_pos[i].Mcr])

        buckling_index = findfirst(x->x≈Mcrℓ, [roof_hugger_purlin_line.local_buckling_xx_pos[i].Mcr, roof_hugger_purlin_line.local_buckling_xx_net_pos[i].Mcr])

        #This is not tracking punchout location along the purlin line.  Consider in the future.

        if buckling_index == 1  #local buckling occurs away from the punchouts

            Mnℓ_xx_pos, eMnℓ_xx_pos =  AISIS10016.f321(Mne_xx, Mcrℓ, ASDorLRFD)
        

        elseif buckling_index == 2  #local buckling occurs at the hole

            My_net = roof_hugger_purlin_line.yielding_flexural_strength_xx_net[i].My
            Mnℓ_xx_pos, eMnℓ_xx_pos =  AISIS10016.f322(Mne_xx, Mcrℓ, My_net, ASDorLRFD)

        end

        Mnℓ_xx_neg, eMnℓ_xx_neg =  AISIS10016.f321(Mne_xx, roof_hugger_purlin_line.local_buckling_xx_neg[i].Mcr, ASDorLRFD)

        local_global_flexural_strength_xx[i] = PurlinLine.LocalGlobalFlexuralStrengthData(Mne_xx, Mnℓ_xx_pos, Mnℓ_xx_neg, eMnℓ_xx_pos, eMnℓ_xx_neg)

       
        ###weak axis flexure, local-global interaction
        Mne_yy = roof_hugger_purlin_line.yielding_flexural_strength_yy[i].My

        Mnℓ_yy_pos, eMnℓ_yy_pos = AISIS10016.f321(Mne_yy, roof_hugger_purlin_line.local_buckling_yy_pos[i].Mcr, ASDorLRFD)

        Mnℓ_yy_neg, eMnℓ_yy_neg = AISIS10016.f321(Mne_yy, roof_hugger_purlin_line.local_buckling_yy_neg[i].Mcr, ASDorLRFD)

        local_global_flexural_strength_yy[i] = PurlinLine.LocalGlobalFlexuralStrengthData(Mne_yy, Mnℓ_yy_pos, Mnℓ_yy_neg, eMnℓ_yy_pos, eMnℓ_yy_neg)


        ###free flange yy-axis, local-global interaction
        Mne_yy_free_flange = roof_hugger_purlin_line.yielding_flexural_strength_free_flange_yy[i].My 

        #Assume no local buckling for now in the free flange strength calculation.  Set Mcrℓ to Mne times a big number. 

        Mnℓ_yy_pos_free_flange, eMnℓ_yy_pos_free_flange = AISIS10016.f321(Mne_yy_free_flange, Mne_yy_free_flange * 1000, ASDorLRFD)

        Mnℓ_yy_neg_free_flange, eMnℓ_yy_neg_free_flange = AISIS10016.f321(Mne_yy_free_flange, Mne_yy_free_flange * 1000, ASDorLRFD)

        local_global_flexural_strength_free_flange_yy[i] = LocalGlobalFlexuralStrengthData(Mne_yy_free_flange, Mnℓ_yy_pos_free_flange, Mnℓ_yy_neg_free_flange, eMnℓ_yy_pos_free_flange, eMnℓ_yy_neg_free_flange)

    end

    return local_global_flexural_strength_xx, local_global_flexural_strength_yy, local_global_flexural_strength_free_flange_yy

end



function define_roof_hugger_purlin_distortional_net_section(roof_hugger_purlin_line)

    num_purlin_segments = size(roof_hugger_purlin_line.inputs.segments)[1]

    cross_section_data = Vector{CrossSectionData}(undef, num_purlin_segments)

    #Define length of RoofHugger punchout.
    L_hole = roof_hugger_purlin_line.inputs.roof_hugger_punch_out_dimensions[1]

    for i=1:num_purlin_segments

        #Define the section property index associated with purlin segment i.
        section_index = roof_hugger_purlin_line.inputs.segments[i][2]

        ##Find all cross-section nodes that are in the RoofHugger web.
        roof_hugger_purlin_node_geometry = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].node_geometry[:,1:2]

        #Define the x range for the RoofHugger webs.

        #Work from the purlin top flange centerline.
        center_top_flange_purlin_node =  sum(roof_hugger_purlin_line.purlin_cross_section_data[section_index].n[1:3]) + sum(roof_hugger_purlin_line.purlin_cross_section_data[section_index].n_radius[1:3]) + floor(Int, roof_hugger_purlin_line.purlin_cross_section_data[section_index].n[4]/2) + 1  

        #Define the RoofHugger bottom flange width.
        roof_hugger_bottom_flange_width = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[section_index][2]

        #Define the RoofHugger base metal thickness.
        t_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[section_index][1]

        #Define the RoofHugger x web coordinate.
        roof_hugger_web_x = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].node_geometry[center_top_flange_purlin_node, 1] + roof_hugger_bottom_flange_width/2 + t_roof_hugger   #check this

        web_index = findall(x->x≈roof_hugger_web_x, roof_hugger_purlin_node_geometry[:,1])

        #Approximate the Lcrd for each cross-section.   
        Lcrd = roof_hugger_purlin_line.distortional_buckling_xx_pos[section_index].Lcr
        tr = AISIS10016.app2C2262(t_roof_hugger, L_hole, Lcrd)

        #Define element definitions.
        roof_hugger_purlin_element_definitions = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].element_definitions

        #Define the element ranges where t becomes tr.
        web_element_index = [web_index[1] - 2; web_index[1] - 1; web_index[1:(end-1)]]

        #Update the element thicknesses in the RoofHugger.
        roof_hugger_purlin_element_definitions[web_element_index, 3] .= tr

        #Calculate section properties of section with reduced web thickness.
        section_properties = CUFSM.cutwp_prop2(roof_hugger_purlin_node_geometry, roof_hugger_purlin_element_definitions)

        #Add cross section information to data structure.
        cross_section_data[i] = PurlinLine.CrossSectionData(roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].n, roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].n_radius, roof_hugger_purlin_node_geometry, roof_hugger_purlin_element_definitions, section_properties)

    end

    return cross_section_data

end




function calculate_net_section_distortional_buckling_properties(roof_hugger_purlin_line)
        
    num_purlin_segments = size(roof_hugger_purlin_line.inputs.segments)[1]

    #Initialize vectors that will carry output.
    distortional_buckling_xx_net_pos = Array{PurlinLine.ElasticBucklingData, 1}(undef, num_purlin_segments)
    
    #Loop over all the purlin segments in the line.
    for i = 1:num_purlin_segments

        #Define the section property index associated with purlin segment i.
        section_index = roof_hugger_purlin_line.inputs.segments[i][2]

        #Define the material property index associated with purlin segment i.
        material_index = roof_hugger_purlin_line.inputs.segments[i][3]
        
        #Map section properties to CUFSM.
        A = roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data[section_index].section_properties.A
        xcg = roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data[section_index].section_properties.xc
        zcg = roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data[section_index].section_properties.yc
        Ixx = roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data[section_index].section_properties.Ixx
        Izz = roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data[section_index].section_properties.Iyy
        Ixz = roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data[section_index].section_properties.Ixy
        thetap = rad2deg(roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data[section_index].section_properties.θ)
        I11 = roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data[section_index].section_properties.I1
        I22 = roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data[section_index].section_properties.I2
        unsymm = 0  #Sets Ixz=0 if unsymm = 0

        #Define the number of cross-section nodes.
        num_cross_section_nodes = size(roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data[section_index].node_geometry)[1]

        #Initialize CUFSM node matrix.
        node = zeros(Float64, (num_cross_section_nodes, 8))

        #Add node numbers to node matrix.
        node[:, 1] .= 1:num_cross_section_nodes

        #Add nodal coordinates to node matrix.
        node[:, 2:3] .= roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data[section_index].node_geometry

        #Add nodal restraints to node matrix.
        node[:, 4:7] .= ones(num_cross_section_nodes,4)

        #Define number of cross-section elements.
        num_cross_section_elements = size(roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data[section_index].element_definitions)[1]

        #Initialize CUFSM elem matrix.
        elem = zeros(Float64, (num_cross_section_elements, 5))

        #Add element numbers to elem matrix.
        elem[:, 1] = 1:num_cross_section_elements

        #Add element connectivity and thickness to elem matrix.
        elem[:, 2:4] .= roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data[section_index].element_definitions

        #Add element material reference to elem matrix.
        elem[:, 5] .= ones(num_cross_section_elements) * 100
                                
        #Find the purlin top flange centerline node.
        #lip curve bottom_flange curve web curve top_flange
        center_top_flange_purlin_node =  sum(roof_hugger_purlin_line.purlin_cross_section_data[section_index].n[1:3]) + sum(roof_hugger_purlin_line.purlin_cross_section_data[section_index].n_radius[1:3]) + floor(Int, roof_hugger_purlin_line.purlin_cross_section_data[section_index].n[4]/2) + 1  #This floor command is a little dangerous.
        
        #Find the RoofHugger top flange centerline nodes.
        num_purlin_nodes = size(roof_hugger_purlin_line.purlin_cross_section_data[section_index].node_geometry)[1]
        center_roof_hugger_flange_node = num_purlin_nodes + sum(roof_hugger_purlin_line.roof_hugger_cross_section_data[section_index].n[1:2]) + sum(roof_hugger_purlin_line.roof_hugger_cross_section_data[section_index].n_radius[1:2]) + floor(Int, roof_hugger_purlin_line.roof_hugger_cross_section_data[section_index].n[3]/2) + 1
       
        #Set up springs in CUFSM.  There can be translational and rotational springs at the purlin top flange, and at each of the RoofHugger top flanges.
        springs = [1 center_top_flange_purlin_node 0 roof_hugger_purlin_line.bracing_data[i].kx 0 0 roof_hugger_purlin_line.bracing_data[i].kϕ_dist 0 0 0
                   2 center_roof_hugger_flange_node 0 roof_hugger_purlin_line.new_deck_bracing_data[i].kx 0 0 roof_hugger_purlin_line.new_deck_bracing_data[i].kϕ_dist 0 0 0]
        
        #Constrain the RoofHugger bottom flange to the purlin top flange in all dof (x, z, y, and q).
        roof_hugger_bottom_flange_centerline_node = num_purlin_nodes + floor(Int, roof_hugger_purlin_line.roof_hugger_cross_section_data[section_index].n[2] / 2) + 1
        
        #node#e DOFe coeff node#k DOFk
        constraints = [center_top_flange_purlin_node 1 1.0 roof_hugger_bottom_flange_centerline_node 1
                       center_top_flange_purlin_node 2 1.0 roof_hugger_bottom_flange_centerline_node 2
                       center_top_flange_purlin_node 3 1.0 roof_hugger_bottom_flange_centerline_node 3
                       center_top_flange_purlin_node 4 1.0 roof_hugger_bottom_flange_centerline_node 4]

        #Assume here that purlin and RoofHugger have the same elastic modulus.
        E = roof_hugger_purlin_line.inputs.purlin_material_properties[material_index][1]
        ν = roof_hugger_purlin_line.inputs.purlin_material_properties[material_index][2]
        G = E / (2 *(1 + ν))
        prop = [100 E E ν ν G]

        neigs = 1  #just need the first mode 

        ###Local buckling - xx axis, positive 

        #Add reference stress to node matrix.

        #Define reference loads.  
        P = 0.0
        Mxx = 1.0  #assume centroidal moment always for now
        Mzz = 0.0
        M11 = 0.0
        M22 = 0.0

        #Define the distortional buckling half-wavelength.
        Lcrd = roof_hugger_purlin_line.distortional_buckling_xx_pos[i].Lcr 

        #Calculate the buckling load just at Lcrd.
        lengths = [Lcrd]

        CUFSM_distortional_xx_net_pos_data, Mcrd_xx_net_pos, Lcrd_xx_net_pos = PurlinLine.get_elastic_buckling(prop, deepcopy(node), elem, lengths, springs, constraints, neigs, P,Mxx,Mzz,M11,M22,A,xcg,zcg,Ixx,Izz,Ixz,thetap,I11,I22,unsymm)   

        #Needed this deepcopy here to make struct work correctly.  Otherwise 'node' just kept changing.

        distortional_buckling_xx_net_pos[i] = PurlinLine.ElasticBucklingData(CUFSM_distortional_xx_net_pos_data, Lcrd_xx_net_pos, Mcrd_xx_net_pos)

    end

    return distortional_buckling_xx_net_pos

end


function calculate_distortional_flexural_strength(roof_hugger_purlin_line)

    num_purlin_segments = size(roof_hugger_purlin_line.inputs.segments)[1]

    #Initialize a vectors that will hold all the outputs.
    distortional_flexural_strength_xx = Array{PurlinLine.DistortionalFlexuralStrengthData, 1}(undef, num_purlin_segments)

    if roof_hugger_purlin_line.inputs.design_code == "AISI S100-16 ASD"
        ASDorLRFD = 0
    elseif roof_hugger_purlin_line.inputs.design_code == "AISI S100-16 LRFD"
        ASDorLRFD = 1
    end

    for i = 1:num_purlin_segments

        Mnd_xx_pos, eMnd_xx_pos = AISIS10016.f411(roof_hugger_purlin_line.yielding_flexural_strength_xx[i].My, roof_hugger_purlin_line.distortional_buckling_xx_net_pos[i].Mcr, ASDorLRFD)  #use Mcrd_hole always here

        Mnd_xx_neg, eMnd_xx_neg = AISIS10016.f411(roof_hugger_purlin_line.yielding_flexural_strength_xx[i].My, roof_hugger_purlin_line.distortional_buckling_xx_neg[i].Mcr, ASDorLRFD)  #assume holes do not affect negative bending distortional buckling for RoofHugger + purlin

        distortional_flexural_strength_xx[i] = PurlinLine.DistortionalFlexuralStrengthData(Mnd_xx_pos, Mnd_xx_neg, eMnd_xx_pos, eMnd_xx_neg)

    end

    return distortional_flexural_strength_xx

end


function calculate_torsion_strength(roof_hugger_purlin_line)

    num_purlin_segments = size(roof_hugger_purlin_line.inputs.segments)[1]

    #Initialize a vector that will hold all the outputs.
    torsion_strength = Array{PurlinLine.TorsionStrengthData, 1}(undef, num_purlin_segments)
    
    if roof_hugger_purlin_line.inputs.design_code == "AISI S100-16 ASD"
        ASDorLRFD = 0
    elseif roof_hugger_purlin_line.inputs.design_code == "AISI S100-16 LRFD"
        ASDorLRFD = 1
    end

    for i = 1:num_purlin_segments

        #Define the section property index associated with purlin segment i.
        section_index = roof_hugger_purlin_line.inputs.segments[i][2]

        #Define the material property index associated with purlin segment i.
        material_index = roof_hugger_purlin_line.inputs.segments[i][3]
        
        Cw = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.Cw

        #This is the maximum magnitude of the warping stress function.  
        Wn = maximum(abs.(roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[section_index].section_properties.wn))

        Fy_purlin = roof_hugger_purlin_line.inputs.purlin_material_properties[material_index][3]
        Fy_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_material_properties[material_index][3]
        Fy = minimum([Fy_purlin, Fy_roof_hugger])  #Maximum warping stress will be in the top right RoofHugger flange or the bottom purlin flange lip, so use the minimum yield stress here.

        Bn, eBn = AISIS10024.h411(Cw, Fy, Wn, ASDorLRFD)

        torsion_strength[i] = TorsionStrengthData(Wn, Bn, eBn)

    end

    return torsion_strength

end


function calculate_shear_strength(roof_hugger_purlin_line)

    num_purlin_segments = size(roof_hugger_purlin_line.inputs.segments)[1]

    #Initialize a vector that will hold all the outputs.
    shear_strength_purlin = Array{PurlinLine.ShearStrengthData, 1}(undef, num_purlin_segments)
    shear_strength_roof_hugger = Array{PurlinLine.ShearStrengthData, 1}(undef, num_purlin_segments)
    shear_strength = Array{PurlinLine.ShearStrengthData, 1}(undef, num_purlin_segments)

    if roof_hugger_purlin_line.inputs.design_code == "AISI S100-16 ASD"
        ASDorLRFD = 0
    elseif roof_hugger_purlin_line.inputs.design_code == "AISI S100-16 LRFD"
        ASDorLRFD = 1
    end

    for i = 1:num_purlin_segments
    
        #Define the section property index associated with purlin segment i.
        section_index = roof_hugger_purlin_line.inputs.segments[i][2]

        #Define the material property index associated with purlin segment i.
        material_index = roof_hugger_purlin_line.inputs.segments[i][3]

        #Set a, the shear stiffener spacing, to the sum of the purlin segment lengths.  This assumes that shear stiffeners are not provided.
        sum_purlin_segments = sum([roof_hugger_purlin_line.inputs.segments[i][1] for i=1:size(roof_hugger_purlin_line.inputs.segments)[1]])
        a = sum_purlin_segments

        #Assume shear strength is Vn,purlin + Vn,roof_hugger.

        #Vn, purlin

        #Define base metal thickness.
        t_purlin = roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions[section_index][2]

        #Define material properties.
        E_purlin = roof_hugger_purlin_line.inputs.purlin_material_properties[material_index][1]
        μ_purlin = roof_hugger_purlin_line.inputs.purlin_material_properties[material_index][2]
        Fy_purlin = roof_hugger_purlin_line.inputs.purlin_material_properties[material_index][3]

        #Depth of flat portion of web.
        full_web_depth_purlin = roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions[section_index][5]
        bottom_flange_web_outside_radius_purlin = roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions[section_index][14]
        top_flange_web_outside_radius_purlin = roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions[section_index][15]
        h_flat_purlin = full_web_depth_purlin - bottom_flange_web_outside_radius_purlin - top_flange_web_outside_radius_purlin

        #Calculate plate buckling coefficient.
        kv_purlin  = AISIS10016.g233(a, h_flat_purlin)

        #Calculate shear buckling stress.
        Fcrv_purlin = AISIS10016.g232(E_purlin, μ_purlin, kv_purlin, h_flat_purlin, t_purlin)
        Vcr_purlin = AISIS10016.g231(h_flat_purlin, t_purlin, Fcrv_purlin)

        #Calculate shear buckling strength.
        Vn_purlin, eVn_purlin = AISIS10016.g21(E_purlin, h_flat_purlin, t_purlin, Fy_purlin, Vcr_purlin, ASDorLRFD)

        #Vn, RoofHugger

        #Define base metal thickness.
        t_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[section_index][1]

        #Define material properties.
        E_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_material_properties[material_index][1]
        μ_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_material_properties[material_index][2]
        Fy_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_material_properties[material_index][3]

        #Depth of flat portion of web.
        full_web_depth_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[section_index][3]
        bottom_flange_web_outside_radius_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[section_index][10]
        top_flange_web_outside_radius_roof_hugger = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[section_index][11]
        h_flat_roof_hugger = full_web_depth_roof_hugger - bottom_flange_web_outside_radius_roof_hugger - top_flange_web_outside_radius_roof_hugger

        #Calculate plate buckling coefficient.
        kv_roof_hugger  = AISIS10016.g233(a, h_flat_roof_hugger)

        #Calculate shear buckling stress.
        Fcrv_roof_hugger = AISIS10016.g232(E_roof_hugger, μ_roof_hugger, kv_roof_hugger, h_flat_roof_hugger, t_roof_hugger)
        Vcr_roof_hugger = AISIS10016.g231(h_flat_roof_hugger, t_roof_hugger, Fcrv_roof_hugger)

        #Calculate shear buckling strength for one web of RoofHugger.
        Vn_roof_hugger, eVn_roof_hugger = AISIS10016.g21(E_roof_hugger, h_flat_roof_hugger, t_roof_hugger, Fy_roof_hugger, Vcr_roof_hugger, ASDorLRFD)

        Vn = Vn_purlin + Vn_roof_hugger
        eVn = eVn_purlin + eVn_roof_hugger

        shear_strength_purlin[i] = PurlinLine.ShearStrengthData(h_flat_purlin, kv_purlin, Fcrv_purlin, Vcr_purlin, Vn_purlin, eVn_purlin)
        shear_strength_roof_hugger[i] = PurlinLine.ShearStrengthData(h_flat_roof_hugger, kv_roof_hugger, Fcrv_roof_hugger, Vcr_roof_hugger, Vn_roof_hugger, eVn_roof_hugger)
        shear_strength[i] = PurlinLine.ShearStrengthData(0.0, 0.0, 0.0, 0.0, Vn, eVn)
    

    end

    return shear_strength_purlin, shear_strength_roof_hugger, shear_strength

end


function define(design_code, segments, spacing, roof_slope, purlin_cross_section_dimensions, roof_hugger_cross_section_dimensions, roof_hugger_punch_out_dimensions, purlin_material_properties, roof_hugger_material_properties, deck_details, deck_material_properties, new_deck_details, new_deck_material_properties, frame_flange_width, support_locations, bridging_locations)

    #Create the RoofHugger data structure.
    roof_hugger_purlin_line = RoofHuggerObject()

    #Add RoofHugger user inputs to data structure.
    roof_hugger_purlin_line.inputs = RoofHugger.Inputs(design_code, segments, spacing, roof_slope, purlin_cross_section_dimensions, roof_hugger_cross_section_dimensions, roof_hugger_punch_out_dimensions, purlin_material_properties, roof_hugger_material_properties, new_deck_details, new_deck_material_properties, frame_flange_width, support_locations, bridging_locations)

    #Define RoofHugger cross-section data including nodal geometry, cross-section discretization and section properties.
    roof_hugger_purlin_line.roof_hugger_cross_section_data = define_roof_hugger_cross_sections(roof_hugger_purlin_line)

    #Create the PurlinLine data structure.
    purlin_line = PurlinLineObject()

    #Capture PurlinLine inputs.
    purlin_line.inputs = PurlinLine.Inputs(design_code, segments, spacing, roof_slope, purlin_cross_section_dimensions, purlin_material_properties, deck_details, deck_material_properties, frame_flange_width, support_locations, bridging_locations)

    #Calculate purlin and purlin free flange section properties.
    roof_hugger_purlin_line.purlin_cross_section_data, roof_hugger_purlin_line.free_flange_cross_section_data = PurlinLine.calculate_purlin_section_properties(purlin_line)
    purlin_line.cross_section_data = roof_hugger_purlin_line.purlin_cross_section_data
    purlin_line.free_flange_cross_section_data = roof_hugger_purlin_line.free_flange_cross_section_data

    #Define RoofHugger + purlin properties.
    roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data = define_roof_hugger_purlin_cross_sections(roof_hugger_purlin_line)

    #Calculate deck bracing properties.  This is for the purlin to deck.   
    #Assume for now that adding big screws and the RoofHugger does not change the stiffness properties. 
    roof_hugger_purlin_line.bracing_data = PurlinLine.define_deck_bracing_properties(purlin_line)
    purlin_line.bracing_data = PurlinLine.define_deck_bracing_properties(purlin_line)

    #Calculate free flange shear flow properties, including bracing stiffness from web and conversion factor from purlin line load to shear flow.
    #Assume shear flow is unchanged with addition of the RoofHugger.
    roof_hugger_purlin_line.free_flange_data = PurlinLine.calculate_free_flange_shear_flow_properties(purlin_line)

    #Calculate bracing properties for new roof deck to RoofHugger.
    roof_hugger_purlin_line.new_deck_bracing_data = define_new_deck_bracing_properties(roof_hugger_purlin_line)

    #Calculate elastic buckling properties for RoofHugger and purlin as a cross-section together.
    roof_hugger_purlin_line.local_buckling_xx_pos, roof_hugger_purlin_line.local_buckling_xx_neg, roof_hugger_purlin_line.local_buckling_yy_pos, roof_hugger_purlin_line.local_buckling_yy_neg, roof_hugger_purlin_line.distortional_buckling_xx_pos, roof_hugger_purlin_line.distortional_buckling_xx_neg = RoofHugger.calculate_elastic_buckling_properties(roof_hugger_purlin_line)

    #Calculate net section properties and add to RoofHugger data structure.
    roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data = define_roof_hugger_purlin_net_section(roof_hugger_purlin_line)

    #Calculate local buckling at the RoofHugger punchout.
    roof_hugger_purlin_line.local_buckling_xx_net_pos = calculate_net_section_local_buckling_properties(roof_hugger_purlin_line)

    #Calculate distortional buckling including the influence of the RoofHugger punchout.
    roof_hugger_purlin_line.roof_hugger_purlin_distortional_net_cross_section_data = define_roof_hugger_purlin_distortional_net_section(roof_hugger_purlin_line)

    roof_hugger_purlin_line.distortional_buckling_xx_net_pos = calculate_net_section_distortional_buckling_properties(roof_hugger_purlin_line)

    #Calculate the first yield flexural strengths for each purlin line segment.  
    roof_hugger_purlin_line.yielding_flexural_strength_xx, roof_hugger_purlin_line.yielding_flexural_strength_xx_net, roof_hugger_purlin_line.yielding_flexural_strength_yy, roof_hugger_purlin_line.yielding_flexural_strength_free_flange_yy = calculate_yielding_flexural_strength(roof_hugger_purlin_line)

    #Calculate the local-global flexural strengths for each purlin line segment.   
    roof_hugger_purlin_line.local_global_flexural_strength_xx, roof_hugger_purlin_line.local_global_flexural_strength_yy, roof_hugger_purlin_line.local_global_flexural_strength_free_flange_yy = calculate_local_global_flexural_strength(roof_hugger_purlin_line)

    #Calculate distortional buckling strengths for each purlin line segment.
    roof_hugger_purlin_line.distortional_flexural_strength_xx = calculate_distortional_flexural_strength(roof_hugger_purlin_line)

    #Calculate torsion strength for each purlin line segment.
    roof_hugger_purlin_line.torsion_strength = calculate_torsion_strength(roof_hugger_purlin_line)

    #Calculate shear strength for each purlin line segment.
    roof_hugger_purlin_line.shear_strength_purlin, roof_hugger_purlin_line.shear_strength_roof_hugger, roof_hugger_purlin_line.shear_strength = calculate_shear_strength(roof_hugger_purlin_line)

    #Calculate web crippling strength at each support.
    #Assume purlin is limiting member here.  Don't consider RoofHugger.
    roof_hugger_purlin_line.web_crippling = PurlinLine.calculate_web_crippling_strength(purlin_line)


    return roof_hugger_purlin_line

end


function thin_walled_beam_interface(roof_hugger_purlin_line)

    #Discretize purlin line.
    member_definitions, dz, z, m = PurlinLine.discretize_purlin_line(roof_hugger_purlin_line)


    #Define ThinWalledBeam section property inputs.
    #Ix Iy Ixy J Cw

    num_purlin_sections = size(roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions)[1]
    section_properties = Vector{Tuple{Float64, Float64, Float64, Float64, Float64}}(undef, num_purlin_sections)

    for i = 1:num_purlin_sections

        #Note -Ixy here since +y in ThinWalledBeam formulation is pointing down.
        section_properties[i] = (roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[i].section_properties.Ixx, roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[i].section_properties.Iyy, -roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[i].section_properties.Ixy, roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[i].section_properties.J, roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[i].section_properties.Cw)

    end


    #Define ThinWalledBeam material property inputs.
    num_purlin_materials = size(roof_hugger_purlin_line.inputs.purlin_material_properties)[1]

    material_properties = Vector{Tuple{Float64, Float64}}(undef, num_purlin_materials)

    for i = 1:num_purlin_materials

        material_properties[i] = (roof_hugger_purlin_line.inputs.purlin_material_properties[i][1], roof_hugger_purlin_line.inputs.purlin_material_properties[i][2])

    end

    #Define the lateral and rotational stiffness magnitudes for ThinWalledBeam.


    #There will be two sets of springs, one for the existing deck and one for the new deck.

    kx = Array{Array{Float64}}(undef, 2)
    kϕ = Array{Array{Float64}}(undef, 2)

    #First, the existing deck.

    num_purlin_segments = size(roof_hugger_purlin_line.bracing_data)[1]

    kx_segments = Vector{Float64}(undef, num_purlin_segments)
    kϕ_segments = Vector{Float64}(undef, num_purlin_segments)

    for i=1:num_purlin_segments

        kx_segments[i] = roof_hugger_purlin_line.bracing_data[i].kx 
        kϕ_segments[i]  = roof_hugger_purlin_line.bracing_data[i].kϕ
 
    end

    num_nodes = length(z)
    kx[1] = zeros(Float64, num_nodes)
    kϕ[1] = zeros(Float64, num_nodes)
    kx[1] .= kx_segments[m]
    kϕ[1] .= kϕ_segments[m]

    #Define the lateral spring location for ThinWalledBeam.    

    #Calculate the y-distance from the RoofHugger + purlin shear center to the existing deck lateral translational spring.
    spring_location_segment = Vector{Float64}(undef, num_purlin_sections)

    for i = 1:num_purlin_sections

        ys = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[i].section_properties.ys  #distance from bottom fiber of purlin to shear center
        h = roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions[i][5] 

        spring_location_segment[i] = h - ys  

    end


    ay_kx = Array{Array{Float64}}(undef, 2)

    #Define location of translational spring at each node.
    ay_kx[1] = Mesh.create_line_element_property_array(member_definitions, m, dz, spring_location_segment, 3, 1)


    #Now work on the new deck springs and spring locations.


    kx_segments = Vector{Float64}(undef, num_purlin_segments)
    kϕ_segments = Vector{Float64}(undef, num_purlin_segments)

    for i=1:num_purlin_segments

        kx_segments[i] = roof_hugger_purlin_line.new_deck_bracing_data[i].kx 
        kϕ_segments[i]  = roof_hugger_purlin_line.new_deck_bracing_data[i].kϕ
 
    end

    num_nodes = length(z)
    kx[2] = zeros(Float64, num_nodes)
    kϕ[2] = zeros(Float64, num_nodes)
    kx[2] .= kx_segments[m]
    kϕ[2] .= kϕ_segments[m]

    #Define the lateral spring location for ThinWalledBeam.    

    #Calculate the y-distance from the RoofHugger + purlin shear center to the new deck lateral translational spring.
    spring_location_segment = Vector{Float64}(undef, num_purlin_sections)

    for i = 1:num_purlin_sections

        ys = roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[i].section_properties.ys  #distance from bottom fiber of purlin to shear center
        roof_hugger_purlin_depth = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][4] + roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions[i][5]
        #out to out RoofHugger + purlin height

        spring_location_segment[i] = roof_hugger_purlin_depth - ys  

    end

    #Define location of translational spring at each node.
    ay_kx[2] = Mesh.create_line_element_property_array(member_definitions, m, dz, spring_location_segment, 3, 1)


    #Define purlin line support locations for ThinWalledBeam.
    #location where u=v=ϕ=0
    supports = roof_hugger_purlin_line.inputs.support_locations

    #Define purlin line end boundary conditions for ThinWalledBeam.

    end_boundary_conditions = Array{Int64}(undef, 2)

    purlin_line_length = sum([roof_hugger_purlin_line.inputs.segments[i][1] for i=1:size(roof_hugger_purlin_line.inputs.segments)[1]])

    #type=1 u''=v''=ϕ''=0 (simply supported), type=2 u'=v'=ϕ'=0  (fixed), type=3 u''=v''=ϕ''=u'''=v'''=ϕ'''=0 (free end, e.g., a cantilever)

    #z=0 (left) end
    if supports[1] == 0.0
        end_boundary_conditions[1] = 1 #pin
    else
        end_boundary_conditions[1] = 3  #cantilever
    end

    #z=purlin_line_length (right) end
    if supports[end] == purlin_line_length
        end_boundary_conditions[2] = 1
    else
        end_boundary_conditions[2] = 3  #cantilever
    end

    #Calculate load magnitudes from user-defined pressure for ThinWalledBeam.
    q = roof_hugger_purlin_line.applied_pressure * roof_hugger_purlin_line.inputs.spacing #go from pressure to line load

    num_nodes = length(z)

    if q<0   #uplift wind pressure
        qx = zeros(num_nodes)
        qy = q .* ones(Float64, num_nodes)
    elseif q>= 0 #gravity pressure
        qx = -q .* sin(deg2rad(roof_hugger_purlin_line.inputs.roof_slope)) .* ones(Float64, num_nodes)
        qy = q .* cos(deg2rad(roof_hugger_purlin_line.inputs.roof_slope)) .* ones(Float64, num_nodes)
    end

    #Calculate the load locations for ThinWalledBeam, from the RoofHugger + purlin shear center.  
    ax_purlin_section = Vector{Float64}(undef, num_purlin_sections)
    ay_purlin_section = Vector{Float64}(undef, num_purlin_sections)

    for i = 1:num_purlin_sections

        center_top_flange_node_index = sum(roof_hugger_purlin_line.purlin_cross_section_data[i].n[1:3]) + sum(roof_hugger_purlin_line.purlin_cross_section_data[i].n_radius[1:3]) + floor(Int,roof_hugger_purlin_line.purlin_cross_section_data[i].n[4]/2) + 1

        ax_purlin_section[i] = roof_hugger_purlin_line.purlin_cross_section_data[i].node_geometry[center_top_flange_node_index, 1] - roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[i].section_properties.xs

        roof_hugger_purlin_depth = roof_hugger_purlin_line.inputs.roof_hugger_cross_section_dimensions[i][4] + roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions[i][5]

        #This is different since the load is now applied at the top of the RoofHugger.
        ay_purlin_section[i] = roof_hugger_purlin_depth - roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[i].section_properties.ys
        
    end

    #Define the load location at each node.
    ax = Mesh.create_line_element_property_array(member_definitions, m, dz, ax_purlin_section, 3, 1)
    ay = Mesh.create_line_element_property_array(member_definitions, m, dz, ay_purlin_section, 3, 1)

    return z, m, member_definitions, section_properties, material_properties, kx, kϕ, ay_kx, qx, qy, ax, ay, end_boundary_conditions, supports

end



function beam_column_interface(roof_hugger_purlin_line)

    #Discretize purlin line.
    member_definitions, dz, z, m = discretize_purlin_line(roof_hugger_purlin_line)

    #Define the number of purlin cross-sections.
    num_purlin_sections = size(roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions)[1]

    #Initialize an array of tuples to hold the free flange section properties.
    section_properties = Vector{Tuple{Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64, Float64,}}(undef, num_purlin_sections)

    for i = 1:num_purlin_sections

        Af = roof_hugger_purlin_line.free_flange_cross_section_data[i].section_properties.A
        Ixf = roof_hugger_purlin_line.free_flange_cross_section_data[i].section_properties.Ixx
        Iyf = roof_hugger_purlin_line.free_flange_cross_section_data[i].section_properties.Iyy
        Jf = roof_hugger_purlin_line.free_flange_cross_section_data[i].section_properties.J
        Cwf = roof_hugger_purlin_line.free_flange_cross_section_data[i].section_properties.Cw
        xcf = roof_hugger_purlin_line.free_flange_cross_section_data[i].section_properties.xc
        ycf = roof_hugger_purlin_line.free_flange_cross_section_data[i].section_properties.yc
        xsf = roof_hugger_purlin_line.free_flange_cross_section_data[i].section_properties.xs
        ysf = roof_hugger_purlin_line.free_flange_cross_section_data[i].section_properties.ys

        section_properties[i] = (Af, Ixf, Iyf, Jf, Cwf, xcf, ycf, xsf, ysf)

    end


    #Define BeamColumn material property inputs.
    num_purlin_materials = size(roof_hugger_purlin_line.inputs.purlin_material_properties)[1]

    material_properties = Vector{Tuple{Float64, Float64}}(undef, num_purlin_materials)

    for i = 1:num_purlin_materials

        material_properties[i] = (roof_hugger_purlin_line.inputs.purlin_material_properties[i][1], roof_hugger_purlin_line.inputs.purlin_material_properties[i][2])

    end

   
    num_purlin_segments = size(roof_hugger_purlin_line.bracing_data)[1]

    #Define kxf along the purlin line.
    kxf_segments = [roof_hugger_purlin_line.free_flange_data[i].kxf for i=1:num_purlin_segments]

    num_nodes = length(z)
    kxf = zeros(Float64, num_nodes)
    kxf .= kxf_segments[m]

    #There is no kyf assumed.
    kyf = zeros(Float64, num_nodes)

    #Define kϕf along the purlin line.
    kϕf_segments = [roof_hugger_purlin_line.free_flange_data[i].kϕf for i=1:num_purlin_segments]
    kϕf = zeros(Float64, num_nodes)
    kϕf .= kϕf_segments[m]    

    #Assume the lateral spring acts at the free flange centroid.  This means hx =hy = 0.
    hxf = zeros(Float64, num_nodes)
    hyf = zeros(Float64, num_nodes)

    #Define shear flow force in free flange.

    #Define the purlin segment properties.
    kH_segments = [roof_hugger_purlin_line.free_flange_data[i].kH for i=1:num_purlin_segments]
    kH = zeros(Float64, num_nodes)
    kH .= kH_segments[m]

    #The shear flow is applied at the free flange centerline.  The distance ay in StructuresKit.BeamColumn is the distance from the shear center to the load along the centroidal y-axis.   Since the shear center for just the free flange is close to the free flange centerline, assume ay= 0.  

    ayf = zeros(Float64, num_nodes)

    #There is no qyf so this can be set to zero.
    axf = zeros(Float64, num_nodes)

    #Define supports.   Combine frame supports and intermediate bridging here.
    supports = sort(unique([roof_hugger_purlin_line.inputs.support_locations; roof_hugger_purlin_line.inputs.bridging_locations]))

    #Define purlin line end boundary conditions for BeamColumn.

    end_boundary_conditions = Array{Int64}(undef, 2)

    purlin_line_length = sum([roof_hugger_purlin_line.inputs.segments[i][1] for i=1:size(roof_hugger_purlin_line.inputs.segments)[1]])

    #type=1 u''=v''=ϕ''=0 (simply supported), type=2 u'=v'=ϕ'=0  (fixed), type=3 u''=v''=ϕ''=u'''=v'''=ϕ'''=0 (free end, e.g., a cantilever)

    #z=0 (left) end
    if supports[1] == 0.0
        end_boundary_conditions[1] = 1 #pin
    else
        end_boundary_conditions[1] = 3  #cantilever
    end

    #z=purlin_line_length (right) end
    if supports[end] == purlin_line_length
        end_boundary_conditions[2] = 1
    else
        end_boundary_conditions[2] = 3  #cantilever
    end


    return z, m, member_definitions, section_properties, material_properties, kxf, kyf, kϕf, kH, hxf, hyf, axf, ayf, end_boundary_conditions, supports

end


function calculate_free_flange_axial_force(Mxx, member_definitions, roof_hugger_purlin_line)
    #this may not need to be updated, could use PurlinLine version
    num_purlin_sections = size(roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions)[1]

    P_unit = zeros(Float64, num_purlin_sections)

    #Loop over the purlin cross-sections in the line.
    for i = 1:num_purlin_sections

        #Find web node at H/5.
        web_index = roof_hugger_purlin_line.purlin_cross_section_data[i].n[1] + roof_hugger_purlin_line.purlin_cross_section_data[i].n_radius[1] + roof_hugger_purlin_line.purlin_cross_section_data[i].n[2] + roof_hugger_purlin_line.purlin_cross_section_data[i].n_radius[2] + 1 + 1

        #Use the local_buckling_xx_pos node geometry and reference stress from CUFSM (Mxx = 1).
        dx = diff(roof_hugger_purlin_line.local_buckling_xx_pos[i].CUFSM_data.node[1:web_index,2])
        dy = diff(roof_hugger_purlin_line.local_buckling_xx_pos[i].CUFSM_data.node[1:web_index,3])
        ds = sqrt.(dx.^2 .+ dy.^2)
        s = [0; cumsum(ds)]   #line coordinates around free flange

        #Integrate the reference stress (Mxx = 1.0) in the free flange to find the reference axial force.   
        stress = roof_hugger_purlin_line.local_buckling_xx_pos[i].CUFSM_data.node[1:web_index,8] 
        t = roof_hugger_purlin_line.inputs.purlin_cross_section_dimensions[i][2]
        P_unit[i] = integrate(s, stress) * t

    end

    #Scale the reference axial force along the purlin line to define the axial force in the free flange.
    #The sign convention for P is + (compression), - (tension) to match StructuresKit.BeamColumn.
    dz = diff(roof_hugger_purlin_line.model.z)
    P = Mesh.create_line_element_property_array(member_definitions, roof_hugger_purlin_line.model.m, dz, P_unit, 3, 1) .* Mxx

    return P

end


function analysis(roof_hugger_purlin_line)

    z, m, member_definitions, section_properties, material_properties, kx, kϕ, ay_kx, qx, qy, ax, ay, end_boundary_conditions, supports = RoofHugger.thin_walled_beam_interface(roof_hugger_purlin_line)

    #Set up ThinWalledBeam model.
    model = ThinWalledBeam.define(z, m, member_definitions, section_properties, material_properties, kx, kϕ, ay_kx, qx, qy, ax, ay, end_boundary_conditions, supports)

    #Solve ThinWalledBeam model.
    roof_hugger_purlin_line.model = ThinWalledBeam.solve(model)

    #Calculate purlin line internal forces and moments from deformations, add them to data structure.
    Mxx, Myy, Vxx, Vyy, T, B = PurlinLine.calculate_internal_forces(roof_hugger_purlin_line.model)

    num_nodes = length(roof_hugger_purlin_line.model.z)
    P = zeros(Float64, num_nodes)  #No axial force in purlin for now.  Could be added later.

    #Add internal forces to data structure.
    roof_hugger_purlin_line.internal_forces = PurlinLine.InternalForceData(P, Mxx, Myy, Vxx, Vyy, T, B)

    #Translate purlin_line design variables to BeamColumn design variables.
    z, m, member_definitions, section_properties, material_properties, kxf, kyf, kϕf, kH, hxf, hyf, axf, ayf, end_boundary_conditions, supports = beam_column_interface(roof_hugger_purlin_line)

    #Calculate axial force in free flange.
    Pf = calculate_free_flange_axial_force(Mxx, member_definitions, roof_hugger_purlin_line)

    #Apply the shear flow based on the y-direction load along the purlin line free flange model.
    qxf = qy .* kH

    #The y-direction load is assumed to be zero in the free flange model.
    num_nodes = length(z)
    qyf = zeros(Float64, num_nodes)

    #Set up the free flange model.
    roof_hugger_purlin_line.free_flange_model = BeamColumn.define(z, m, member_definitions, section_properties, material_properties, kxf, kyf, kϕf, hxf, hyf, qxf, qyf, Pf, axf, ayf, end_boundary_conditions, supports)

    #Run the free flange model.
    roof_hugger_purlin_line.free_flange_model = BeamColumn.solve(roof_hugger_purlin_line.free_flange_model)

    #Calculate internal forces in the free flange.
    Mxx, Myy, Vxx, Vyy, T, B = PurlinLine.calculate_internal_forces(roof_hugger_purlin_line.free_flange_model)

    #Add free flange internal forces to data structure.
    roof_hugger_purlin_line.free_flange_internal_forces = PurlinLine.InternalForceData(Pf, Mxx, Myy, Vxx, Vyy, T, B)

    #Calculate demand-to-capacity ratios for each of the purlin line limit states.
    DC_flexure_torsion = PurlinLine.calculate_bending_torsion_DC(roof_hugger_purlin_line)
    DC_distortional = PurlinLine.calculate_distortional_buckling_DC(roof_hugger_purlin_line)
    DC_flexure_shear = PurlinLine.calculate_flexure_shear_DC(roof_hugger_purlin_line)        
    DC_biaxial_bending = PurlinLine.calculate_biaxial_bending_DC(roof_hugger_purlin_line)
    DC_web_crippling = PurlinLine.calculate_web_crippling_DC(roof_hugger_purlin_line)

    #Add demand-to-capacity ratios to data structure.
    roof_hugger_purlin_line.demand_to_capacity = PurlinLine.DemandToCapacity(DC_flexure_torsion, DC_distortional, DC_flexure_shear, DC_biaxial_bending, DC_web_crippling)

    return roof_hugger_purlin_line

end

function capacity(roof_hugger_purlin_line)

    DC_tolerance = 0.01  
    
    if roof_hugger_purlin_line.loading_direction == "gravity"

        load_sign = 1.0
    
    elseif roof_hugger_purlin_line.loading_direction =="uplift"
    
        load_sign = -1.0
    
    end

    #Run a very small pressure to get the test going.
    roof_hugger_purlin_line.applied_pressure = load_sign * 10^-6
    roof_hugger_purlin_line = RoofHugger.analysis(roof_hugger_purlin_line)
    max_DC = PurlinLine.find_max_DC(roof_hugger_purlin_line)

    #Define initial residual.
    residual = 1.0 - abs(max_DC)

    while residual > DC_tolerance

        new_pressure = roof_hugger_purlin_line.applied_pressure / max_DC
        roof_hugger_purlin_line.applied_pressure = roof_hugger_purlin_line.applied_pressure + (new_pressure - roof_hugger_purlin_line.applied_pressure) / 2

        roof_hugger_purlin_line = RoofHugger.analysis(roof_hugger_purlin_line)
        max_DC = PurlinLine.find_max_DC(roof_hugger_purlin_line)

        residual = 1.0 - abs(max_DC)

    end

    return roof_hugger_purlin_line

end

end # module
