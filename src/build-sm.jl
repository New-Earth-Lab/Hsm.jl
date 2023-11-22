
function add_state!(sm::AbstractStateMachine; name::Symbol, ancestor::Symbol)
    push!(sm.ctx.states, (;name, ancestor))
end

using FunctionWrappers: FunctionWrapper
function on_event!(callback::Base.Callable, sm::AbstractStateMachine, state_name::Symbol, event_name::Symbol)
    # TODO: In reality, a SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}
    fw = FunctionWrapper{EventHandled,Tuple{Vector{UInt8}}}(callback) # Works!
    # fw = FunctionWrapper{EventHandled,Tuple{Vector{UInt8},typeof(typer)}}(our_callback)
    # fw = @cfunction($our_callback, Cvoid, (Vector{UInt8},))
    push!(sm.ctx.events, (; name=event_name, state=state_name, callback=fw))
    return nothing
end
function on_entry!(callback::Base.Callable, sm::AbstractStateMachine, state_name::Symbol,)
    fw = FunctionWrapper{Nothing,Tuple{}}(callback) 
    push!(sm.ctx.enters, (; state=state_name, callback=fw))
    return nothing
end
function on_exit!(callback::Base.Callable, sm::AbstractStateMachine, state_name::Symbol,)
    fw = FunctionWrapper{Nothing,Tuple{}}(callback) 
    push!(sm.ctx.exits, (; state=state_name, callback=fw))
    return nothing
end
function on_initialize!(callback::Base.Callable, sm::AbstractStateMachine, state_name::Symbol,)
    fw = FunctionWrapper{Nothing,Tuple{}}(callback) 
    push!(sm.ctx.initializes, (; state=state_name, callback=fw))
    return nothing
end

function register_events!(callback, hsm1)
    callback(hsm1)
end