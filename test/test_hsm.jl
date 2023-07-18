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
# Hsm.ancestor(Type) = supertype(Type). Parent isn't necessary in that case
# abstract type State_S <: Hsm.AbstractHsmState end
# abstract type State_S1 <: State_S end
# abstract type State_S11 <: State_S1 end
# abstract type State_S2 <: State_S end
# abstract type State_S21 <: State_S2 end
# abstract type State_S211 <: State_S21 end 

# Define all events
struct Event_A end
struct Event_B end
struct Event_C end
struct Event_D end
struct Event_E end
struct Event_F end
struct Event_G end
struct Event_H end
struct Event_I end

function on_entry!(sm::Hsm.AbstractHsmStateMachine, state::Type{<:Hsm.AbstractHsmState})
    #print("$(state)-ENTRY;")
end

function on_exit!(sm::Hsm.AbstractHsmStateMachine, state::Type{<:Hsm.AbstractHsmState})
    #print("$(state)-EXIT;")
end

# Define the state machine
mutable struct HsmTest <: Hsm.AbstractHsmStateMachine
    context::Hsm.StateMachineContext
    foo::Int
    function HsmTest()
        sm = new(Hsm.StateMachineContext())
        Hsm.on_initialize!(sm, Hsm.Top)
        return sm
    end
end

############

function Hsm.on_initialize!(sm::HsmTest, state::Type{Hsm.Top})
    #print("$(state)-INIT;")
    Hsm.transition!(sm, State_S2, () -> sm.foo = 0)
end

##############


Hsm.ancestor(::Type{State_S}) = Hsm.Top

function Hsm.on_initialize!(sm::HsmTest, state::Type{State_S})
    #print("$(state)-INIT;")
    Hsm.transition!(sm, State_S11)
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S}, event::Event_E)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S11)
    return true
end

# This is how it should really be done
# function Hsm.on_event!(sm::HsmTest, state::Type{State_S}, event::Event_E)
#     Hsm.transition!(sm, State_S11, function ()
#         #print("$(state)-$(event);")
#     end)
#     return true
# end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S}, event::Event_I)
    if sm.foo == 1
        #print("$(state)-$(event);")
        sm.foo = 0
        return true
    else
        return false
    end
end

#########

Hsm.ancestor(::Type{State_S1}) = State_S

function Hsm.on_initialize!(sm::HsmTest, state::Type{State_S1})
    #print("$(state)-INIT;")
    Hsm.transition!(sm, State_S11)
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S1}, event::Event_A)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S1)
    return true
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S1}, event::Event_B)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S11)
    return true
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S1}, event::Event_C)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S2)
    return true
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S1}, event::Event_D)
    if sm.foo == 0
        #print("$(state)-$(event);")
        Hsm.transition!(sm, State_S1, () -> sm.foo = 1)
        return true
    else
        return false
    end
end

# This is how it should really be done
# function Hsm.on_event!(sm::HsmTest, state::Type{State_S1}, event::Event_D)
#     if sm.foo == 0
#         Hsm.transition!(sm, State_S1, function ()
#             #print("$(state)-$(event);")
#             sm.foo = 1
#         end)
#         return true
#     else
#         return false
#     end
# end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S1}, event::Event_F)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S211)
    return true
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S1}, event::Event_I)
    #print("$(state)-$(event);")
    return true
end

#############

Hsm.ancestor(::Type{State_S11}) = State_S1

function Hsm.on_event!(sm::HsmTest, state::Type{State_S11}, event::Event_D)
    if sm.foo == 1
        #print("$(state)-$(event);")
        Hsm.transition!(sm, State_S1, () -> sm.foo = 0)
        return true
    else
        return false
    end
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S11}, event::Event_G)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S211)
    return true
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S11}, event::Event_H)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S2)
    return true
end

######

Hsm.ancestor(::Type{State_S2}) = State_S

function Hsm.on_initialize!(sm::HsmTest, state::Type{State_S2})
    #print("$(state)-INIT;")
    Hsm.transition!(sm, State_S211)
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S2}, event::Event_C)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S1)
    return true
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S2}, event::Event_F)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S11)
    return true
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S2}, event::Event_I)
    if sm.foo == 0
        #print("$(state)-$(event);")
        sm.foo = 1
        return true
    else
        return false
    end
end

########

Hsm.ancestor(::Type{State_S21}) = State_S2

function Hsm.on_initialize!(sm::HsmTest, state::Type{State_S21})
    #print("$(state)-INIT;")
    Hsm.transition!(sm, State_S211)
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S21}, event::Event_A)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S21)
    return true
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S21}, event::Event_B)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S211)
    return true
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S21}, event::Event_G)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S11)
    return true
end

#############

Hsm.ancestor(::Type{State_S211}) = State_S21

function Hsm.on_event!(sm::HsmTest, state::Type{State_S211}, event::Event_D)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S21)
    return true
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S211}, event::Event_H)
    #print("$(state)-$(event);")
    Hsm.transition!(sm, State_S)
    return true
end

function dispatch!(sm, event)
    Hsm.dispatch!(sm, event)
    #print("\n")
end

function test()
    hsm = HsmTest()
    #print("\n")

    dispatch!(hsm, Event_A())
    dispatch!(hsm, Event_B())
    dispatch!(hsm, Event_D())
    dispatch!(hsm, Event_E())
    dispatch!(hsm, Event_I())
    dispatch!(hsm, Event_F())
    dispatch!(hsm, Event_I())
    dispatch!(hsm, Event_I())
    dispatch!(hsm, Event_F())
    dispatch!(hsm, Event_A())
    dispatch!(hsm, Event_B())
    dispatch!(hsm, Event_D())
    dispatch!(hsm, Event_D())
    dispatch!(hsm, Event_E())
    dispatch!(hsm, Event_G())
    dispatch!(hsm, Event_H())
    dispatch!(hsm, Event_H())
    dispatch!(hsm, Event_C())
    dispatch!(hsm, Event_G())
    dispatch!(hsm, Event_C())
    dispatch!(hsm, Event_C())

end

# ENV["JULIA_DEBUG"] = Hsm
test()