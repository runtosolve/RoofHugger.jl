### A Pluto.jl notebook ###
# v0.17.4

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

    OS = "Mac"

	 if OS == "Windows"

		purlin_data = CSV.read(raw"database\Purlins.csv",
                             DataFrame);

		roof_hugger_data = CSV.read(raw"database\Huggers.csv",
                             DataFrame);

		existing_deck_data = CSV.read(raw"database\Existing_Deck.csv",
                             DataFrame);

		new_deck_data = CSV.read(raw"database\New_Deck.csv",
                             DataFrame);

	elseif OS == "Mac"

		purlin_data = CSV.read("database/Purlins.csv",
                             DataFrame);

		roof_hugger_data = CSV.read("database/Huggers.csv",
                             DataFrame);

		existing_deck_data = CSV.read("database/Existing_Deck.csv",
                             DataFrame);

		new_deck_data = CSV.read("database/New_Deck.csv",
                             DataFrame);

	end



	# local_path = "/Users/crismoen/.julia/dev/RoofHugger/UI/"

	# purlin_data = CSV.read(local_path * "database/Purlins.csv",
    #                          DataFrame);

	# roof_hugger_data = CSV.read(local_path * "database/Huggers.csv",
    #                          DataFrame);

	# existing_deck_data = CSV.read(local_path * "database/Existing_Deck.csv",
    #                          DataFrame);

	# new_deck_data = CSV.read(local_path * "database/New_Deck.csv",
    #                          DataFrame);
	
end;

# ╔═╡ 0c83214c-02c5-4f7f-8f56-3bf5f46d51e0
using Plots

# ╔═╡ 2a2939b5-b0de-4b51-9a14-3fdf5d439b93
load("roof-hugger-logo-2.png")

# ╔═╡ c2353bb3-ee8c-4d55-9447-470427c22b06
@bind project_details TextField((30,5); default="Project details")

# ╔═╡ 96f90537-0b4d-4d48-927b-01492e3789ef
@bind report_date DateField(default=today())

# ╔═╡ 99299f0c-30ee-4807-a7a2-d4509b4680ab
md" ## Build existing roof system."

# ╔═╡ 5d180e53-27aa-4bb2-9ab1-81cc2737ab3b
purlin_spans = (25.0, 25.0, 25.0)  #ft

# ╔═╡ 1d9b00aa-7f6b-4f7e-9da8-e1f0b1ace647
md"""
Purlin sizes $(@bind purlin_type_1 Select(["Z8x2.5 060"; purlin_data[:, 1]]))
$(@bind purlin_type_2 Select(["none"; purlin_data[:, 1]]))
"""

# ╔═╡ bafb4c6d-a36e-438d-be55-a29abcf1efc4
purlin_size_span_assignment = (2, 1, 2)

# ╔═╡ 710a97bb-6cd1-457c-a352-23428408de55
purlin_laps = (2.0, 2.0, 2.0, 2.0)  #ft

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

# ╔═╡ de7c5c88-b286-4b0a-b09a-97140fe2a4b6
span_segments = UI.define_span_segments(purlin_spans, purlin_laps, purlin_size_span_assignment)

# ╔═╡ dd6bbcfe-b781-4bf5-8485-1c4b25380ebc
md" ## Calculate existing roof system strength."

# ╔═╡ 155b41ff-d261-40df-807d-37027d220187
purlin_line = UI.existing_roof_UI_mapper(purlin_spans, purlin_laps, purlin_spacing, roof_slope, purlin_data, existing_deck_type, existing_deck_data, frame_flange_width, purlin_frame_connection, purlin_type_1, purlin_type_2, purlin_size_span_assignment);

# ╔═╡ 40af7c07-ff81-4617-a220-9db2435247f2
begin

	xlims=(-9.0, 9.0);
	ylims = (0.0, 18.0);
	markershape = :none;
	StructuresKit.Visualize.show_multi_branch_cross_section(purlin_line.cross_section_data[1].node_geometry[:,1], purlin_line.cross_section_data[1].node_geometry[:,2], purlin_line.cross_section_data[1].element_definitions, markershape, xlims, ylims)

end

# ╔═╡ d2246077-5cf8-4f00-81af-9e5922bec619
md"**Existing roof system downward (gravity) strength = $(round(purlin_line.applied_pressure*1000*144, digits=1)) psf**"

# ╔═╡ 9760a25d-cf0e-4fe5-b812-c16e7fb16f9f
purlin_line

# ╔═╡ e1318eb7-751d-4de9-a0f8-407b0a06a55e
plot(purlin_line.model.z, purlin_line.internal_forces.T)

# ╔═╡ 0b7e949d-d39a-45e6-820b-d2866a57cb7c
plot(purlin_line.model.z, purlin_line.model.ϕ, markershape = :o)

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

# ╔═╡ 33f14b20-ecce-43e9-884b-629ef5a9ac40
roof_hugger_purlin_line = UI.retrofit_UI_mapper(purlin_line, roof_hugger_data, roof_hugger_type, new_deck_type, new_deck_data, hugger_window_dimensions);

# ╔═╡ 828e6235-3b5f-47f0-a004-62b00bf14ff9
begin
	StructuresKit.Visualize.show_multi_branch_cross_section(roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].node_geometry[:,1], roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].node_geometry[:,2], roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].element_definitions, markershape, xlims, ylims)

end

# ╔═╡ 19a966f6-5f6f-4ddd-8ecf-91e7a0326839
begin
	StructuresKit.Visualize.show_multi_branch_cross_section(roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[1].node_geometry[:,1], roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[1].node_geometry[:,2], roof_hugger_purlin_line.roof_hugger_purlin_net_cross_section_data[1].element_definitions, markershape, xlims, ylims)

end

# ╔═╡ 8fe61b54-e9e1-4aa6-be50-b0812d86a1cf
md"**Retrofitted roof system downward (gravity) strength = $(round(roof_hugger_purlin_line.applied_pressure*1000*144, digits=1)) psf**"

# ╔═╡ 0a982b48-b517-4b3f-b794-18a8d8426232
9.83-5.38

# ╔═╡ 76c601bb-0c64-425e-a5e3-bdf036389b69
roof_hugger_purlin_line

# ╔═╡ 2a6017a3-0be0-405b-bb19-4518488aee9f
25*12

# ╔═╡ bcbae4a4-1d7b-4e5e-81f4-365b6fc9208b
begin
	plot(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.internal_forces.Mxx, label="hugger+purlin")
	plot!(purlin_line.model.z, purlin_line.internal_forces.Mxx, label="purlin")
end

# ╔═╡ cc666f40-7c2d-4168-aa08-c93104839b79
sum(roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].n) + sum(roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].n_radius) + 2 - roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].n[end] - roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].n_radius[end] - floor(Int,roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].n[end-1]/2)

# ╔═╡ 44708b2b-aac4-4874-9260-01730a17e761
roof_hugger_purlin_line.roof_hugger_purlin_cross_section_data[1].node_geometry[42,:]

# ╔═╡ 8d32773b-8457-4a30-a427-e7d2228c25af
begin
	plot(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.internal_forces.Vyy, label="hugger+purlin")
	plot!(purlin_line.model.z, purlin_line.internal_forces.Vyy, label="purlin")
end

# ╔═╡ 52dd1cd6-4249-4bee-9a58-0243b88577fb
begin
	plot(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.internal_forces.Myy, label="hugger+purlin")
	plot!(purlin_line.model.z, purlin_line.internal_forces.Myy, label="purlin")
end

# ╔═╡ 8b0eea21-0a6d-43b0-8a20-22112beb1481
begin
	plot(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.model.u, label="hugger+purlin")
	plot!(purlin_line.model.z, purlin_line.model.u, label="purlin")
end

# ╔═╡ b0a41923-1889-4484-8829-be8e81b08e15
begin
	plot(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.internal_forces.T, label="hugger+purlin")
	plot!(purlin_line.model.z, purlin_line.internal_forces.T, label="purlin")
end

# ╔═╡ be540db1-8334-48cb-bad5-527c2fb31f42
begin
	plot(purlin_line.model.z, purlin_line.model.Ix, label="purlin")
	plot!(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.model.Ix, label="hugger+purlin")
	
end

# ╔═╡ 29aabd3a-3aa1-4b07-9232-785d904d9377
begin
	plot(purlin_line.model.z, purlin_line.model.Cw, label="purlin")
	plot!(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.model.Cw, label="hugger+purlin")
	
end

# ╔═╡ 7284523b-5123-4e02-9015-5b903f87d01a
begin
	plot(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.free_flange_internal_forces.P)
	plot!(purlin_line.model.z, purlin_line.free_flange_internal_forces.P)
end

# ╔═╡ 1e5f9868-9520-4330-9c64-98b38c0dee39
begin
	plot(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.flexure_torsion_demand_to_capacity.action_Mxx)
	plot!(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.flexure_torsion_demand_to_capacity.action_Myy)
	plot!(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.flexure_torsion_demand_to_capacity.action_B)
		plot!(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.flexure_torsion_demand_to_capacity.action_Myy_freeflange)
	plot!(roof_hugger_purlin_line.model.z, roof_hugger_purlin_line.flexure_torsion_demand_to_capacity.interaction)
end

# ╔═╡ 85504a55-3745-457f-88bc-b67153d617cb
begin
	plot(purlin_line.model.z, purlin_line.flexure_torsion_demand_to_capacity.action_Mxx, label="Mxx")
	plot!(purlin_line.model.z, purlin_line.flexure_torsion_demand_to_capacity.action_Myy, label="Myy")
	plot!(roof_hugger_purlin_line.model.z, purlin_line.flexure_torsion_demand_to_capacity.action_B, label="T")
		plot!(roof_hugger_purlin_line.model.z, purlin_line.flexure_torsion_demand_to_capacity.action_Myy_freeflange, label="free flange")
		plot!(roof_hugger_purlin_line.model.z, purlin_line.flexure_torsion_demand_to_capacity.interaction, label="interaction")
end

# ╔═╡ 2e54230e-5510-4efe-aa20-f3527b4fca3b
begin
	plot(purlin_line.model.z, purlin_line.free_flange_model.qx)
	plot!(purlin_line.model.z, roof_hugger_purlin_line.free_flange_model.qx)
end

# ╔═╡ a49ecfc5-4e12-40c6-ae5f-7064db85a3df
begin
	plot(purlin_line.model.z, purlin_line.expected_strengths.eMnℓ_xx)
	plot!(purlin_line.model.z, roof_hugger_purlin_line.expected_strengths.eMnℓ_xx)
end

# ╔═╡ ae9f9b93-a9bd-496f-9a3e-72d23edf3873
begin
	plot(purlin_line.model.z, purlin_line.expected_strengths.eMnd_xx)
	plot!(purlin_line.model.z, roof_hugger_purlin_line.expected_strengths.eMnd_xx)
end

# ╔═╡ 95ce2b11-9e5f-49b4-9b97-8b07dec220e0
begin
	plot(purlin_line.model.z, roof_hugger_purlin_line.model.v, label="hugger+purlin")
	plot!(purlin_line.model.z, purlin_line.model.v, label="purlin")
end

# ╔═╡ 5ff16089-47e4-42d4-8cba-d235b32324e0
begin
	plot(purlin_line.model.z, roof_hugger_purlin_line.model.ϕ, label="hugger+purlin")
	plot!(purlin_line.model.z, purlin_line.model.ϕ, label="purlin")
end

# ╔═╡ 2a4616a6-703b-4296-8a48-adcba5e4eaaf
begin
	plot(purlin_line.model.z, roof_hugger_purlin_line.model.u, label="hugger+purlin")
	plot!(purlin_line.model.z, purlin_line.model.u, label="purlin")
end

# ╔═╡ Cell order:
# ╟─e37326d5-d9c8-4512-960f-82d912c00273
# ╟─2a2939b5-b0de-4b51-9a14-3fdf5d439b93
# ╟─c2353bb3-ee8c-4d55-9447-470427c22b06
# ╟─96f90537-0b4d-4d48-927b-01492e3789ef
# ╟─99299f0c-30ee-4807-a7a2-d4509b4680ab
# ╠═5d180e53-27aa-4bb2-9ab1-81cc2737ab3b
# ╠═1d9b00aa-7f6b-4f7e-9da8-e1f0b1ace647
# ╠═bafb4c6d-a36e-438d-be55-a29abcf1efc4
# ╠═710a97bb-6cd1-457c-a352-23428408de55
# ╠═dde7f4c2-2212-4244-a78b-8fe12b6c8d0e
# ╠═1a1727db-c828-4317-8ccd-2be491ee48c0
# ╟─37bb5287-53cf-4322-b3f6-e16de0ba16c9
# ╠═9eebfba0-7913-40fd-bda5-b1d1178c741a
# ╟─e20e6735-ae8a-4ae0-99bb-f563a602afbc
# ╠═de7c5c88-b286-4b0a-b09a-97140fe2a4b6
# ╟─dd6bbcfe-b781-4bf5-8485-1c4b25380ebc
# ╟─155b41ff-d261-40df-807d-37027d220187
# ╟─40af7c07-ff81-4617-a220-9db2435247f2
# ╟─d2246077-5cf8-4f00-81af-9e5922bec619
# ╠═9760a25d-cf0e-4fe5-b812-c16e7fb16f9f
# ╠═0c83214c-02c5-4f7f-8f56-3bf5f46d51e0
# ╠═e1318eb7-751d-4de9-a0f8-407b0a06a55e
# ╠═0b7e949d-d39a-45e6-820b-d2866a57cb7c
# ╟─f67cf06d-2fe6-401f-ab71-1ecea9aa373f
# ╟─6cebdfda-7d1c-4df6-9e64-b6afad1c7f6d
# ╠═9a6b80f0-db1c-465a-8c59-b3c6ac181a1e
# ╟─bfac357a-4b13-471e-84e8-edf4272065ba
# ╟─4d47c72c-52a9-4caa-9516-446296e73443
# ╟─33f14b20-ecce-43e9-884b-629ef5a9ac40
# ╟─828e6235-3b5f-47f0-a004-62b00bf14ff9
# ╟─19a966f6-5f6f-4ddd-8ecf-91e7a0326839
# ╟─8fe61b54-e9e1-4aa6-be50-b0812d86a1cf
# ╠═0a982b48-b517-4b3f-b794-18a8d8426232
# ╠═76c601bb-0c64-425e-a5e3-bdf036389b69
# ╠═2a6017a3-0be0-405b-bb19-4518488aee9f
# ╠═bcbae4a4-1d7b-4e5e-81f4-365b6fc9208b
# ╠═cc666f40-7c2d-4168-aa08-c93104839b79
# ╠═44708b2b-aac4-4874-9260-01730a17e761
# ╠═8d32773b-8457-4a30-a427-e7d2228c25af
# ╠═52dd1cd6-4249-4bee-9a58-0243b88577fb
# ╠═8b0eea21-0a6d-43b0-8a20-22112beb1481
# ╠═b0a41923-1889-4484-8829-be8e81b08e15
# ╠═be540db1-8334-48cb-bad5-527c2fb31f42
# ╠═29aabd3a-3aa1-4b07-9232-785d904d9377
# ╠═7284523b-5123-4e02-9015-5b903f87d01a
# ╠═1e5f9868-9520-4330-9c64-98b38c0dee39
# ╠═85504a55-3745-457f-88bc-b67153d617cb
# ╠═2e54230e-5510-4efe-aa20-f3527b4fca3b
# ╠═a49ecfc5-4e12-40c6-ae5f-7064db85a3df
# ╠═ae9f9b93-a9bd-496f-9a3e-72d23edf3873
# ╠═95ce2b11-9e5f-49b4-9b97-8b07dec220e0
# ╠═5ff16089-47e4-42d4-8cba-d235b32324e0
# ╠═2a4616a6-703b-4296-8a48-adcba5e4eaaf
