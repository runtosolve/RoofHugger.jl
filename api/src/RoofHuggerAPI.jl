module RoofHuggerAPI

using CSV, DataFrames, Dates, RoofHugger, JSON3, PurlinLine, StructTypes, UUIDs

export RunRoofHugger, RoofHuggerResult, calculate, export_report

const DEFAULT_EXISTING_PURLIN = "Z8x2.5 060"
const ROOF_HUGGER_MATERIAL = [(29500.0, 0.30, 55.0, 70.0)]

mutable struct RunRoofHugger
  purlin_types::Vector{String}
  purlin_spans::Vector{Float64}
  purlin_size_span_assignment::Vector{Int}
  purlin_laps::Vector{Float64}
  purlin_spacing::Float64
  frame_flange_width::Float64
  roof_slope::Float64   # rise in 12 (1 = 1:12); the analysis takes rise over run, roof_slope / 12
  deck_type::String
  loading_direction::String
  generate_report::Bool
  roof_hugger_type::String
  analysis_type::String
  purlin_frame_connection::String

  RunRoofHugger() = new()
end

mutable struct RoofHuggerResult
  applied_pressure::Float64
  failure_limit_state::String
  failure_location::Float64
  input_z::Vector{Float64}
  output_v::Vector{Float64}
  report_id::String

  RoofHuggerResult() = new()
end

StructTypes.StructType(::Type{RunRoofHugger}) = StructTypes.Mutable()
StructTypes.StructType(::Type{RoofHuggerResult}) = StructTypes.Mutable()

function with_purlin_decks(deck_data)
  purlin_deck = CSV.read(joinpath(pkgdir(PurlinLine), "database", "Existing_Deck.csv"), DataFrame)
  known = Set(String.(deck_data.deck_name))
  extra = filter(row -> !(String(row.deck_name) in known), purlin_deck)
  return vcat(deck_data, extra)
end

function load_section_databases()
  databases = RoofHugger.UI.load_databases()
  return (
    purlin_data = databases.purlin_data,
    roof_hugger_data = databases.roof_hugger_data,
    existing_deck_data = with_purlin_decks(databases.existing_deck_data),
    new_deck_data = with_purlin_decks(databases.new_deck_data),
  )
end

const DATABASES = load_section_databases()

function existing_purlin_types(types, roof_hugger_data)
  section_names = String.(roof_hugger_data.section_name)
  if all(type -> type in section_names, types)
    return [DEFAULT_EXISTING_PURLIN]
  end
  return types
end

# The report pipeline (RoofHugger_cFSM and RoofHugger_Capacity); the retrofit analysis below uses it too.
include("report.jl")

# Finished analyses are kept per set of inputs, so running the same roof again answers at once.
const ANALYSIS_CACHE = Dict{String, RoofHuggerResult}()
const ANALYSIS_CACHE_LOCK = ReentrantLock()
const ANALYSIS_CACHE_SIZE = 200

analysis_key(data::RunRoofHugger) = JSON3.write([isdefined(data, f) ? getfield(data, f) : nothing
                                                   for f in fieldnames(RunRoofHugger) if f != :generate_report])

function calculate(data::RunRoofHugger)::RoofHuggerResult
  key = analysis_key(data)
  result = lock(() -> get(ANALYSIS_CACHE, key, nothing), ANALYSIS_CACHE_LOCK)
  if result === nothing
    result = analyze(data)
    lock(ANALYSIS_CACHE_LOCK) do
      length(ANALYSIS_CACHE) >= ANALYSIS_CACHE_SIZE && empty!(ANALYSIS_CACHE)
      ANALYSIS_CACHE[key] = result
    end
  end

  output = RoofHuggerResult()
  output.applied_pressure = result.applied_pressure
  output.failure_limit_state = result.failure_limit_state
  output.failure_location = result.failure_location
  output.input_z = copy(result.input_z)
  output.output_v = copy(result.output_v)
  output.report_id = data.generate_report ? string(uuid4()) : ""
  return output
end

"""
The line inputs of the report (`RoofHugger_Capacity.line_inputs`, which takes `roof_slope / 12`) for `data`,
so an analysis and a later report on the same roof share the cached models.
"""
function line_inputs(data::RunRoofHugger)
  body = (purlin_types = existing_purlin_types(data.purlin_types, DATABASES.roof_hugger_data),
          purlin_spans = data.purlin_spans, purlin_laps = data.purlin_laps,
          purlin_size_span_assignment = data.purlin_size_span_assignment, purlin_spacing = data.purlin_spacing,
          roof_slope = data.roof_slope, deck_type = data.deck_type, frame_flange_width = data.frame_flange_width,
          purlin_frame_connection = data.purlin_frame_connection, roof_hugger_type = data.roof_hugger_type,
          roof_hugger_material = (E_ksi = ROOF_HUGGER_MATERIAL[1][1], nu = ROOF_HUGGER_MATERIAL[1][2],
                                    Fy_ksi = ROOF_HUGGER_MATERIAL[1][3], Fu_ksi = ROOF_HUGGER_MATERIAL[1][4]))
  return RoofHugger_cFSM.RoofHugger_Capacity.line_inputs(body)
end

function analyze(data::RunRoofHugger)::RoofHuggerResult
  li = line_inputs(data)
  model = if data.analysis_type == "retrofit"
    retrofit_analysis(data, li)
  else
    RoofHugger_cFSM.RoofHugger_Capacity.existing_case(li, DATABASES, data.loading_direction)
  end

  output = RoofHuggerResult()
  output.applied_pressure = model.applied_pressure
  # Same display labels the Typst report uses (LIMIT_STATE_LABELS).
  labels = RoofHugger_cFSM.RoofHugger_Capacity.LIMIT_STATE_LABELS
  output.failure_limit_state = get(labels, model.failure_limit_state, model.failure_limit_state)
  output.failure_location = model.failure_location
  output.input_z = model.model.inputs.z
  output.output_v = model.model.outputs.v
  output.report_id = ""
  return output
end

"""
The RoofHugger retrofit as the report computes it (`RoofHugger_Capacity.retrofit_case`):
`RoofHugger.UI.retrofit_UI_mapper` plus the governing (minimum) positive local buckling moment of the
combined section and the bare RoofHugger cFSM study, so the analysis and the report give the same
allowable pressure. The cFSM study is memoized per profile and material, the models per line.
"""
function retrofit_analysis(data::RunRoofHugger, li)
  profile = findfirst(==(data.roof_hugger_type), DATABASES.roof_hugger_data.section_name)
  profile === nothing && throw(ArgumentError("Roof Hugger section not in the database: $(data.roof_hugger_type)"))
  E, ν, Fy = li.if_mat[1][1:3]
  cfsm = RoofHugger_cFSM.governing_local_buckling_inputs(DATABASES.roof_hugger_data[profile, :], E, ν, Fy)
  return RoofHugger_cFSM.RoofHugger_Capacity.retrofit_case(li, DATABASES, cfsm, data.loading_direction)
end

"""
    warmup_calculate()

Runs the default existing and retrofit analyses (the report warm-up's inputs) so the first
/roofhugger/base request after a start does not pay Julia's compilation time. Failures are
logged, never thrown.
"""
function warmup_calculate()
  try
    t = @elapsed for analysis_type in ("existing", "retrofit")
      body = merge(WARMUP_BODY, Dict{String,Any}("loading_direction" => "gravity", "generate_report" => false,
                                                 "analysis_type" => analysis_type))
      calculate(JSON3.read(JSON3.write(body), RunRoofHugger))
    end
    @info "RoofHugger analysis warmed up" seconds = round(t, digits = 1)
  catch error
    @error "RoofHugger analysis warm-up failed" exception = (error, catch_backtrace())
  end
  return nothing
end

end
