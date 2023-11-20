
# Generic on_event! handler for unhandled events
function on_event!(sm::AbstractHsmStateMachine, ::AbstractHsmState, ::Any)
    sm
end

# Event handler for Root state. Events are considered handled if they reach Root
function on_event!(sm::AbstractHsmStateMachine, ::Root, ::Any)
    sm = @set sm.context.handled = true
    sm
end
