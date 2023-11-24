@enum EventHandled Handled NotHandled

abstract type AbstractStateMachine end

const T_state = @NamedTuple{name::Symbol, ancestor::Symbol}
const T_event = @NamedTuple{name::Symbol, state::Symbol, callback::FunctionWrappers.FunctionWrapper{Hsm.EventHandled, Tuple{Vector{UInt8}}}}
const T_exit = @NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}
const T_enter = @NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}
const T_initialize = @NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}

mutable struct StateMachineContext
    # These vectors are constant bindings but can be modified
    const states::Vector{@NamedTuple{name::Symbol, ancestor::Symbol}}
    const event_callbacks::Vector{@NamedTuple{name::Symbol, state::Symbol, callback::FunctionWrappers.FunctionWrapper{Hsm.EventHandled, Tuple{Vector{UInt8}}}}}
    const exit_callbacks::Vector{@NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}}
    const enter_callbacks::Vector{@NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}}
    const initialize_callbacks::Vector{@NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}}
    current::Symbol
    source::Symbol
    # history::Symbol
end
StateMachineContext() = StateMachineContext(
    T_state[],
    T_event[],
    T_exit[],
    T_enter[],
    T_initialize[],
    :Root,
    :Root,
)

current(sm::AbstractStateMachine) = sm.ctx.current
current!(sm::AbstractStateMachine, state::Symbol) = sm.ctx.current = state
source(sm::AbstractStateMachine) = sm.ctx.source
source!(sm::AbstractStateMachine, state::Symbol) = sm.ctx.source = state

const empty_payload = UInt8[]
function dispatch!(sm::AbstractStateMachine, event, payload=empty_payload)
    do_event!(sm, current(sm), event, payload)
end

function do_event!(sm::AbstractStateMachine, s::Union{Symbol, AbstractString}, event::Symbol, payload) # TODO: payload typed

    # TODO: Darryl does this seem appropriate? We want a way 
    # to be notified if the user dispatches an event that is not accounted for
    # at all or handled all the way up the state machine.
    if s == :Root
        @warn "Event not handled by any states up to Root" event maxlog=1
        return
    end

    source!(sm, s)

    # Find the main source state by calling on_event! until the event is handled
    # on_event!
    handled = NotHandled
    for event_prime in sm.ctx.event_callbacks
        if event_prime.name == event && event_prime.state == s
            handled = event_prime.callback(payload)
            break
        end
    end

    if handled != Handled
        do_event!(sm, ancestor(sm, s), event, payload)
    end
    return
end
