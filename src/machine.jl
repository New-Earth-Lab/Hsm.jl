@enum EventHandled Handled NotHandled

abstract type AbstractStateMachine end

const T_state = @NamedTuple{name::Symbol, ancestor::Symbol}
const T_event = @NamedTuple{
    name::Symbol,
    state::Symbol,
    callback::FunctionWrappers.FunctionWrapper{EventHandled,Tuple{Vector{UInt8}}},
}
const T_exit =
    @NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing,Tuple{}}}
const T_entry =
    @NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing,Tuple{}}}
const T_initial =
    @NamedTuple{state::Symbol, callback::FunctionWrappers.FunctionWrapper{Nothing,Tuple{}}}

mutable struct StateMachineContext
    # These vectors are constant bindings but can be modified
    const states::Vector{@NamedTuple{name::Symbol, ancestor::Symbol}}
    const event_callbacks::Vector{
        @NamedTuple{
            name::Symbol,
            state::Symbol,
            callback::FunctionWrappers.FunctionWrapper{EventHandled,Tuple{Vector{UInt8}}},
        }
    }
    const exit_callbacks::Vector{
        @NamedTuple{
            state::Symbol,
            callback::FunctionWrappers.FunctionWrapper{Nothing,Tuple{}},
        }
    }
    const entry_callbacks::Vector{
        @NamedTuple{
            state::Symbol,
            callback::FunctionWrappers.FunctionWrapper{Nothing,Tuple{}},
        }
    }
    const initial_callbacks::Vector{
        @NamedTuple{
            state::Symbol,
            callback::FunctionWrappers.FunctionWrapper{Nothing,Tuple{}},
        }
    }
    current::Symbol
    source::Symbol
    # history::Symbol
end

# TODO Use inner constructor?
StateMachineContext() = StateMachineContext(
    T_state[],
    T_event[],
    T_exit[],
    T_entry[],
    T_initial[],
    :Top,
    :Top,
)

current(sm::AbstractStateMachine) = sm.context.current
current!(sm::AbstractStateMachine, state::Symbol) = sm.context.current = state
source(sm::AbstractStateMachine) = sm.context.source
source!(sm::AbstractStateMachine, state::Symbol) = sm.context.source = state

const empty_payload = UInt8[]
function dispatch!(sm::AbstractStateMachine, event, payload = empty_payload)
    do_event!(sm, current(sm), event, payload)
end

function do_event!(
    sm::AbstractStateMachine,
    source::Union{Symbol,AbstractString},
    event::Symbol,
    payload,
) # TODO: payload typed
    while source !== :Top
        source!(sm, source)

        handled = NotHandled
        for cb in sm.context.event_callbacks
            if cb.name === event && cb.state === source
                handled = cb.callback(payload)
                break
            end
        end

        if handled === Handled
            return
        end

        source = ancestor(sm, source)
    end
    
    @warn "Event not handled by any states up to Root" event maxlog = 1
    return

end