struct StateMachineContext{TCurrentState<:AbstractHsmState,TSourceState<:AbstractHsmState}
    current::TCurrentState
    source::TSourceState
    handled::Bool
end
StateMachineContext() = StateMachineContext(Root(), Root(), false)

current(sm::AbstractHsmStateMachine)::AbstractHsmState = sm.context.current
current!(sm::AbstractHsmStateMachine, state::AbstractHsmState) = @set sm.context.current = state
source(sm::AbstractHsmStateMachine)::AbstractHsmState = sm.context.source
source!(sm::AbstractHsmStateMachine, state::AbstractHsmState) = @set sm.context.source = state

function dispatch!(sm::AbstractHsmStateMachine, event)
    sm = @set sm.context.handled = false
    do_event!(sm, current(sm), event)
end

function do_event!(sm::AbstractHsmStateMachine, s::AbstractHsmState, event)
    # Find the main source state by calling on_event! until the event is handled
    sm = source!(sm, s)
    sm = on_event!(sm, s, event)
    if !sm.context.handled
        sm = do_event!(sm, ancestor(s), event)
    end
    return sm
end
