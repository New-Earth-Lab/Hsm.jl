
function add_state!(sm::HierarchicalStateMachine1; name::Symbol, ancestor::Symbol)
    push!(sm.states, (;name, ancestor))
end

using FunctionWrappers: FunctionWrapper
function on_event!(callback::Base.Callable, sm::HierarchicalStateMachine1, state_name::Symbol, event_name::Symbol)
    @info "Registering callback" state_name event_name
    precompile(callback, (Vector{UInt8},))
    # allocations = check_allocs(callback, (Vector{UInt8},))
    # if !isempty(allocations)
    #     @warn "Provided on_event! callback will allocate. This is bad for real-time performance!" allocations
    # end

    # TODO: In reality, a SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}
    fw = FunctionWrapper{EventHandled,Tuple{Vector{UInt8}}}(callback) # Works!
    # fw = FunctionWrapper{EventHandled,Tuple{Vector{UInt8},typeof(typer)}}(our_callback)
    # fw = @cfunction($our_callback, Cvoid, (Vector{UInt8},))
    push!(sm.events, (; name=event_name, state=state_name, callback=fw))
    return nothing
end
function on_entry!(callback::Base.Callable, sm::HierarchicalStateMachine1, state_name::Symbol,)
    @info "Registering enter callback" state_name
    precompile(callback, ())
    # allocations = check_allocs(callback, ())
    # if !isempty(allocations)
    #     @warn "Provided on_entry! callback will allocate. This is bad for real-time performance!" allocations
    # end
    fw = FunctionWrapper{Nothing,Tuple{}}(callback) 
    push!(sm.enters, (; state=state_name, callback=fw))
    return nothing
end
function on_exit!(callback::Base.Callable, sm::HierarchicalStateMachine1, state_name::Symbol,)
    @info "Registering exit callback" state_name
    precompile(callback, ())
    # allocations = check_allocs(callback, ())
    # if !isempty(allocations)
    #     @warn "Provided on_exit! callback will allocate. This is bad for real-time performance!" allocations
    # end
    fw = FunctionWrapper{Nothing,Tuple{}}(callback) 
    push!(sm.exits, (; state=state_name, callback=fw))
    return nothing
end
function on_initialize!(callback::Base.Callable, sm::HierarchicalStateMachine1, state_name::Symbol,)
    @info "Registering initialize callback" state_name
    precompile(callback, ())
    # allocations = check_allocs(callback, ())
    # if !isempty(allocations)
    #     @warn "Provided on_initialize! callback will allocate. This is bad for real-time performance!" allocations
    # end
    fw = FunctionWrapper{Nothing,Tuple{}}(callback) 
    push!(sm.initializes, (; state=state_name, callback=fw))
    return nothing
end

function register_events!(callback, hsm1)
    callback(hsm1)
end