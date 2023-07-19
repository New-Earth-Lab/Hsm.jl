mutable struct StateMachineContext
    current::Type{<:AbstractHsmState}
    source::Type{<:AbstractHsmState}
    StateMachineContext() = new(Top, Top)
end
current(sm::AbstractHsmStateMachine)::Type{<:AbstractHsmState} = sm.context.current
current!(sm::AbstractHsmStateMachine, state::Type{<:AbstractHsmState}) = sm.context.current = state
source(sm::AbstractHsmStateMachine)::Type{<:AbstractHsmState} = sm.context.source
source!(sm::AbstractHsmStateMachine, state::Type{<:AbstractHsmState}) = sm.context.source = state

function dispatch!(sm::AbstractHsmStateMachine, event::Any)
    # Find the main source state by calling on_event! until the event is handled
    s = source!(sm, current(sm))
    do_event!(sm, s, event)
end

function do_event!(sm::AbstractHsmStateMachine, s::Type{<:AbstractHsmState}, event::Any)
    if on_event!(sm, s, event)
        return
    else
        s = source!(sm, ancestor(s))
        do_event!(sm, s, event)
    end
end
