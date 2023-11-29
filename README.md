# Hsm.jl

This package provides tools for implementing hierarchical state machines in Julia, in an efficient and zero-allocation way.

This library started as a fork of [HSM.jl](https://github.com/AndrewWasHere/HSM.jl) by Andrew Lin. See their [accompanying blog post](https://andrewwashere.github.io/2022/05/21/state-machines.html) for more information.

## Usage

To use this package, define a state machine type. This can contain any state fields you might want to use in your application.
It must inherit from `Hsm.AbstractStateMachine` and contain a field called `context` of type `Hsm.StateMachineContext`:

```julia
using Hsm

mutable struct MyStateMachine <: Hsm.AbstractStateMachine
    context::Hsm.StateMachineContext
    # Your state variables here
    foo::Int
end

# Create an instances
mysm = MyStateMachine(
    Hsm.StateMachineContext(),
    1
)
```

Next, describe the possible states and their nesting:
```julia
Hsm.add_state!(mysm, name = :State1, ancestor=:Top)
Hsm.add_state!(mysm, name = :State1_substate1, ancestor=:State1)
Hsm.add_state!(mysm, name = :State1_substate2, ancestor=:State1)
```

An ancestor of `:Top` should be included for your outermost state.

Now, define the ways in which your state machine enters and exits those
(potentially nested) states.
```julia

Hsm.register_events!(mysm) do sm

    Hsm.on_initial!(sm, :State1) do
        # When initializing the outer State1, let's
        # immediately transition into this sub-state.
        Hsm.transition!(sm, :State1_substate1)
    end

    Hsm.on_entry!(sm, :State1) do 
        println("entered state 1")
    end
    Hsm.on_entry!(sm, :State1_substate1) do 
        println("entered substate 1")
    end
    Hsm.on_entry!(sm, :State1_substate2) do 
        println("entered substate 2")
    end

    Hsm.on_exit!(sm, :State1_substate2) do 
        println("exitted substate 2")
    end
end
```

Next, define what events your state machine can response to:
```julia
Hsm.register_events!(mysm) do sm
    # If we receive an `Event_A`, we go to the other substate
    Hsm.on_event!(sm, :State1_substate1, :Event_A) do payload
        Hsm.transition!(sm, :State1_substate2)
        # Indicate that we handled this event, so the event won't
        # bubble up to the ancestor state.
        return Hsm.Handled
    end
    # If we receive an `Event_A`, we go to the other substate
    Hsm.on_event!(sm, :State1_substate2, :Event_B) do payload
        Hsm.transition!(sm, :State1_substate1)
        # Indicate that we handled this event, so the event won't
        # bubble up to the ancestor state.
        return Hsm.Handled
    end
end
```

Finally, we are done! We can use our state machine by dispatching events to it.
```julia
# Start by transitioning into the outer state
Hsm.transition!(mysm, :State1)
# After this point, we only interact with the state machine
# by sending events

Hsm.dispatch!(mysm, :Event_A)
Hsm.dispatch!(mysm, :Event_B)

# Calling dispatch! will not allocate except for any allocations
# that occur in the user's callback (printing in this example).
```