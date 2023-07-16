
on_event!(::AbstractHsmStateMachine, ::Type{<:AbstractHsmState}, ::AbstractHsmEvent) = false
on_event!(::AbstractHsmStateMachine, ::Type{AbstractHsmState}, ::AbstractHsmEvent) = true
