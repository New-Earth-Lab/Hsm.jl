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
    const events::Vector{@NamedTuple{name::Symbol, state::Symbol, callback::FunctionWrappers.FunctionWrapper{Hsm.EventHandled, Tuple{Vector{UInt8}}}}}
    const exits::Vector{@NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}}
    const enters::Vector{@NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}}
    const initializes::Vector{@NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}}
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

function do_event!(sm::AbstractStateMachine, s::Symbol, event::Symbol, payload) # TODO: payload typed

    # TODO: Darryl does this seem appropriate? We want a way 
    # to be notified if the user dispatches an event that is not accounted for
    # at all or handled all the way up the state machine.
    if s == :Root
        error(lazy"Event $event not handled by any states up to Root")
    end

    # Find the main source state by calling on_event! until the event is handled
    source!(sm, s)
    # on_event!(sm, s , event)
    # find relevant event

    handled = NotHandled
    for event′ in sm.ctx.events
        if event′.name == event && event′.state == s
            handled = event′.callback(payload)
            break
        end
    end

    if handled != Handled
        do_event!(sm, ancestor(sm, s), event, payload)
    end
    return
end
