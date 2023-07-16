using Logging

mutable struct StateMachineContext
    current::Type{<:AbstractHsmState}
    source::Type{<:AbstractHsmState}
    StateMachineContext(initial) = new(initial, initial)
end
current(sm::AbstractHsmStateMachine) = sm.context.current
current!(sm::AbstractHsmStateMachine, state::Type{<:AbstractHsmState}) = sm.context.current = state
source(sm::AbstractHsmStateMachine) = sm.context.source
source!(sm::AbstractHsmStateMachine, state::Type{<:AbstractHsmState}) = sm.context.source = state

function dispatch2!(sm::AbstractHsmStateMachine, event::AbstractHsmEvent)
    source!(sm, current(sm))
    s = source(sm)
    while !on_event!(sm, s, event)
        source!(sm, parent(s))
        s = source(sm)
    end
end


function dispatch!(sm::AbstractHsmStateMachine, event::AbstractHsmEvent)
    source!(sm, current(sm))
    
    # Keep calling on_event! to find the source state of the event
    while !on_event!(sm, source(sm), event)
        source!(sm, parent(source(sm)))
    end
end
