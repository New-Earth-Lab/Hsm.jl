@enum EventHandled Handled NotHandled


const T_state = @NamedTuple{name::Symbol, ancestor::Symbol}
const T_event = @NamedTuple{name::Symbol, state::Symbol, callback::FunctionWrappers.FunctionWrapper{Hsm.EventHandled, Tuple{Vector{UInt8}}}}
const T_exit = @NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}
const T_enter = @NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}
const T_initialize = @NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}

struct HierarchicalStateMachine1{CTX}
    states::Vector{@NamedTuple{name::Symbol, ancestor::Symbol}}
    events::Vector{@NamedTuple{name::Symbol, state::Symbol, callback::FunctionWrappers.FunctionWrapper{Hsm.EventHandled, Tuple{Vector{UInt8}}}}}
    exits::Vector{@NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}}
    enters::Vector{@NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}}
    initializes::Vector{@NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing, Tuple{}}}}
    ctx::CTX
end
HierarchicalStateMachine1(ctx) = HierarchicalStateMachine1(
    T_state[],
    T_event[],
    T_exit[],
    T_enter[],
    T_initialize[],
    ctx
)

# Defined by user? #
mutable struct StateMachineContext1
    current::Symbol
    source::Symbol
    # history::Symbol
    foo::Int
end
current(hsm1::HierarchicalStateMachine1) = hsm1.ctx.current
current!(hsm1::HierarchicalStateMachine1, state::Symbol) = hsm1.ctx.current = state
source(hsm1::HierarchicalStateMachine1) = hsm1.ctx.source
source!(hsm1::HierarchicalStateMachine1, state::Symbol) = hsm1.ctx.source = state

const empty_payload = UInt8[]
function dispatch!(sm::HierarchicalStateMachine1, event, payload=empty_payload)
    do_event!(sm, current(sm), event, payload)
end

function do_event!(sm::HierarchicalStateMachine1, s::Symbol, event::Symbol, payload) # TODO: payload typed

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
    for event′ in sm.events
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
