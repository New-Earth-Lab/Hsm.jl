mutable struct StateMachineContext
    current::Type{<:AbstractHsmState}
    source::Type{<:AbstractHsmState}
    StateMachineContext() = new(Root, Root)
end
current(sm::AbstractHsmStateMachine)::Type{<:AbstractHsmState} = sm.context.current
current!(sm::AbstractHsmStateMachine, state::Type{<:AbstractHsmState}) = sm.context.current = state
source(sm::AbstractHsmStateMachine)::Type{<:AbstractHsmState} = sm.context.source
source!(sm::AbstractHsmStateMachine, state::Type{<:AbstractHsmState}) = sm.context.source = state

function dispatch!(sm::AbstractHsmStateMachine, event::Any)
    s = source!(sm, current(sm))
    do_event!(sm, s, event)
end

function do_event!(sm::AbstractHsmStateMachine, s::Type{<:AbstractHsmState}, event::Any)
    # Find the main source state by calling on_event! until the event is handled
    ret = on_event!(sm, s, event)
    if ret == EventHandled
        return
    elseif ret == EventNotHandled
        s = source!(sm, ancestor(s))
        do_event!(sm, s, event)
    else
        error("Invalid return value from on_event!")
    end
end
