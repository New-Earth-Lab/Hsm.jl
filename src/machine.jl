mutable struct StateMachineContext
    current::Type{<:AbstractHsmState}
    source::Type{<:AbstractHsmState}
    StateMachineContext() = new(Root, Root)
end
current(sm::AbstractHsmStateMachine)::Type{<:AbstractHsmState} = sm.context.current
current!(sm::AbstractHsmStateMachine, state::Type{<:AbstractHsmState}) = sm.context.current = state
source(sm::AbstractHsmStateMachine)::Type{<:AbstractHsmState} = sm.context.source
source!(sm::AbstractHsmStateMachine, state::Type{<:AbstractHsmState}) = sm.context.source = state

function dispatch!(sm::AbstractHsmStateMachine, event)
    do_event!(sm, current(sm), event)
end

function do_event!(sm::AbstractHsmStateMachine, s::Type{<:AbstractHsmState}, event)
    # Find the main source state by calling on_event! until the event is handled
    source!(sm, s)
    ret = on_event!(sm, s, event)
    if ret === EventHandled
        return
    elseif ret === EventNotHandled
        do_event!(sm, ancestor(s), event)
        return
    else
        error("Invalid return value from on_event!")
    end
end
