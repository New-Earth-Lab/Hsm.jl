
# Generic on_event! handler for unhandled events
function on_event!(sm::AbstractHsmStateMachine, ::Type{<:AbstractHsmState}, ::Any)
    sm
end

# Event handler for Root state. Events are considered handled if they reach Root
function on_event!(sm::AbstractHsmStateMachine, ::Type{Root}, ::Any)
    sm = @set sm.context.handled = true
    sm
end
