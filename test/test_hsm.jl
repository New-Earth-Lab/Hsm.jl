using Revise
using JET

using Hsm
using Logging

# Define all states
struct State_S <: Hsm.AbstractHsmState end
struct State_S1 <: Hsm.AbstractHsmState end
struct State_S11 <: Hsm.AbstractHsmState end
struct State_S2 <: Hsm.AbstractHsmState end
struct State_S21 <: Hsm.AbstractHsmState end
struct State_S211 <: Hsm.AbstractHsmState end

# Could also use the type system to define the hierarchy of states
# Hsm.parent(Type) = supertype(Type). Parent isn't necessary in that case
# abstract type State_S <: Hsm.AbstractHsmState end
# abstract type State_S1 <: State_S end
# abstract type State_S11 <: State_S1 end
# abstract type State_S2 <: State_S end
# abstract type State_S21 <: State_S2 end
# abstract type State_S211 <: State_S21 end 

# Define all events
struct Event_A <: Hsm.AbstractHsmEvent end
struct Event_B <: Hsm.AbstractHsmEvent end
struct Event_C <: Hsm.AbstractHsmEvent end
struct Event_D <: Hsm.AbstractHsmEvent end
struct Event_E <: Hsm.AbstractHsmEvent end
struct Event_F <: Hsm.AbstractHsmEvent end
struct Event_G <: Hsm.AbstractHsmEvent end
struct Event_H <: Hsm.AbstractHsmEvent end
struct Event_I <: Hsm.AbstractHsmEvent end

# Define the state machine
mutable struct HsmTest <: Hsm.AbstractHsmStateMachine
    context::Hsm.StateMachineContext
    foo::Int
    function HsmTest(initial, foo)
        sm = new(Hsm.StateMachineContext(Hsm.AbstractHsmState))
        Hsm.transition!(sm, State_S2, () -> sm.foo = 0)
        return sm
    end
end

############

Hsm.parent(::Type{State_S}) = Hsm.AbstractHsmState

function Hsm.on_initialize!(sm::HsmTest, state::Type{State_S})
    # @debug "on_initialize! $(typeof(sm))::$(state)"
    Hsm.transition!(sm, State_S11)
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S}, event::Event_E)
    Hsm.transition!(sm, State_S11)
    return true
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S}, event::Event_I)
    if sm.foo == 1
        sm.foo = 0
    end
    return true
end


#########

Hsm.parent(::Type{State_S1}) = State_S

function Hsm.on_initialize!(sm::HsmTest, state::Type{State_S1})
    # @debug "on_initialize! $(typeof(sm))::$(state)"
    Hsm.transition!(sm, State_S11)
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S1}, event::Event_A)
    Hsm.transition!(sm, State_S1)
    return true
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S1}, event::Event_A)
    Hsm.transition!(sm, State_S1)
    return true
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S1}, event::Event_B)
    Hsm.transition!(sm, State_S11)
    return true
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S1}, event::Event_C)
    Hsm.transition!(sm, State_S2)
    return true
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S1}, event::Event_D)
    if sm.foo == 0
        Hsm.transition!(sm, State_S1, () -> sm.foo = 1)
        return true
    else
        return false
    end
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S1}, event::Event_F)
    Hsm.transition!(sm, State_S211)
    return true
end

#############

Hsm.parent(::Type{State_S11}) = State_S1

function Hsm.on_event!(sm::HsmTest, ::Type{State_S11}, event::Event_D)
    if sm.foo == 1
        Hsm.transition!(sm, State_S1, () -> sm.foo = 0)
        return true
    else
        return false
    end
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S11}, event::Event_G)
    Hsm.transition!(sm, State_S211)
    return true
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S11}, event::Event_H)
    Hsm.transition!(sm, State_S2)
    return true
end

######

Hsm.parent(::Type{State_S2}) = State_S

function Hsm.on_initialize!(sm::HsmTest, state::Type{State_S2})
    # @debug "on_initialize! $(typeof(sm))::$(state)"
    Hsm.transition!(sm, State_S211)
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S2}, event::Event_C)
    Hsm.transition!(sm, State_S1)
    return true
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S2}, event::Event_F)
    Hsm.transition!(sm, State_S11)
    return true
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S2}, event::Event_I)
    if sm.foo == 0
        sm.foo = 1
    end
    return true
end

########

Hsm.parent(::Type{State_S21}) = State_S2

function Hsm.on_initialize!(sm::HsmTest, state::Type{State_S21})
    # @debug "on_initialize! $(typeof(sm))::$(state)"
    Hsm.transition!(sm, State_S211)
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S21}, event::Event_A)
    Hsm.transition!(sm, State_S21)
    return true
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S21}, event::Event_B)
    Hsm.transition!(sm, State_S211)
    return true
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S21}, event::Event_G)
    Hsm.transition!(sm, State_S11)
    return true
end

#############

Hsm.parent(::Type{State_S211}) = State_S21

function Hsm.on_event!(sm::HsmTest, ::Type{State_S211}, event::Event_D)
    Hsm.transition!(sm, State_S21)
    return true
end

function Hsm.on_event!(sm::HsmTest, ::Type{State_S211}, event::Event_H)
    Hsm.transition!(sm, State_S)
    return true
end

function test()
    hsm = HsmTest(State_S2, 0)

    Hsm.dispatch!(hsm, Event_A())
    Hsm.dispatch!(hsm, Event_B())
    Hsm.dispatch!(hsm, Event_D())
    Hsm.dispatch!(hsm, Event_E())
    Hsm.dispatch!(hsm, Event_I())
    Hsm.dispatch!(hsm, Event_I())
    Hsm.dispatch!(hsm, Event_F())
    Hsm.dispatch!(hsm, Event_I())
    Hsm.dispatch!(hsm, Event_F())
    Hsm.dispatch!(hsm, Event_A())
    Hsm.dispatch!(hsm, Event_B())
    Hsm.dispatch!(hsm, Event_D())
    Hsm.dispatch!(hsm, Event_D())
    Hsm.dispatch!(hsm, Event_E())
    Hsm.dispatch!(hsm, Event_G())
    Hsm.dispatch!(hsm, Event_H())
    Hsm.dispatch!(hsm, Event_H())
    Hsm.dispatch!(hsm, Event_C())
    Hsm.dispatch!(hsm, Event_G())
    Hsm.dispatch!(hsm, Event_C())
    Hsm.dispatch!(hsm, Event_C())

end

# ENV["JULIA_DEBUG"] = Hsm
test()