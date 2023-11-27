using FunctionWrappers: FunctionWrapper

function add_state!(sm::AbstractStateMachine; name::Symbol, ancestor::Symbol)
    push!(sm.context.states, (; name, ancestor))
    return
end

function on_event!(
    callback,
    sm::AbstractStateMachine,
    state_name::Symbol,
    event_name::Symbol,
)
    # TODO: In reality, a SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}
    fw = FunctionWrapper{EventHandled,Tuple{Vector{UInt8}}}(callback) # Works!
    # fw = FunctionWrapper{EventHandled,Tuple{Vector{UInt8},typeof(typer)}}(our_callback)
    # fw = @cfunction($our_callback, Cvoid, (Vector{UInt8},))
    push!(
        sm.context.event_callbacks,
        (; name = event_name, state = state_name, callback = fw),
    )
    return
end

function on_entry!(callback, sm::AbstractStateMachine, state_name::Symbol)
    fw = FunctionWrapper{Nothing,Tuple{}}(callback)
    push!(sm.context.entry_callbacks, (; state = state_name, callback = fw))
    return
end

function on_exit!(callback, sm::AbstractStateMachine, state_name::Symbol)
    fw = FunctionWrapper{Nothing,Tuple{}}(callback)
    push!(sm.context.exit_callbacks, (; state = state_name, callback = fw))
    return
end

function on_initial!(callback, sm::AbstractStateMachine, state_name::Symbol)
    fw = FunctionWrapper{Nothing,Tuple{}}(callback)
    push!(sm.context.initial_callbacks, (; state = state_name, callback = fw))
    return
end

function register_events!(callback, sm)
    callback(sm)
end