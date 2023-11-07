
# Generic on_event! handler for unhandled events
on_event!(::AbstractHsmStateMachine, ::Type{<:AbstractHsmState}, ::Any) = false

# Event handler for Root state. Events are considered handled if they reach Root
on_event!(::AbstractHsmStateMachine, ::Type{Root}, ::Any) = true
