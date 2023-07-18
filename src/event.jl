
# Generic on_event! handler for unhandled events
on_event!(::AbstractHsmStateMachine, ::Type{<:AbstractHsmState}, ::Any) = false

# Event handler for Top state. Events are considered handled if they reach Top
on_event!(::AbstractHsmStateMachine, ::Type{Top}, ::Any) = true
