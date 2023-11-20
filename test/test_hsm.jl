using Revise
# using JET
using BenchmarkTools
using Setfield
using Hsm

# Define all states
struct Top <: Hsm.AbstractHsmState end
struct State_S <: Hsm.AbstractHsmState end
struct State_S1 <: Hsm.AbstractHsmState end
struct State_S11 <: Hsm.AbstractHsmState end
struct State_S2 <: Hsm.AbstractHsmState end
struct State_S21 <: Hsm.AbstractHsmState end
struct State_S211 <: Hsm.AbstractHsmState end

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

function Hsm.on_entry!(sm::Hsm.AbstractHsmStateMachine, state::Type{<:Hsm.AbstractHsmState})
    print("$(state)-ENTRY;")
    return sm
end

function Hsm.on_exit!(sm::Hsm.AbstractHsmStateMachine, state::Type{<:Hsm.AbstractHsmState})
    print("$(state)-EXIT;")
    return sm
end

# Define the state machine
struct HsmTest{TContext<:Hsm.StateMachineContext} <: Hsm.AbstractHsmStateMachine
    context::TContext
    # Define state machine variables
    foo::Int
end
function HsmTest()
    ctx = Hsm.StateMachineContext()
    sm = HsmTest(ctx,0)
    sm = Hsm.on_initialize!(sm, Top)
    return sm
end

############

# Hsm.on_initialize!(sm::HsmTest, state::Type{Top}) =
#     Hsm.transition!(sm, State_S2) do
#         print("$(state)-INIT;")
#         @set sm.foo = 0
#     end
function Hsm.on_initialize!(sm::HsmTest, state::Type{Top})
    res = Hsm.transition!(sm, State_S2) do
        @show sm
        print("$(state)-INIT;")
        sm = @set sm.foo = 0
        @show sm
        return sm
    end

    @show res
    return res
end
##############


Hsm.ancestor(::Type{State_S}) = Top

Hsm.on_initialize!(sm::HsmTest, state::Type{State_S}) =
    Hsm.transition!(sm, State_S11) do
        print("$(state)-INIT;")
        sm
    end

Hsm.on_event!(sm::HsmTest, state::Type{State_S}, event::Event_E) =
    Hsm.transition!(sm, State_S11) do
        print("$(state)-$(event);")
        sm
    end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S}, event::Event_I)
    if sm.foo == 1
        print("$(state)-$(event);")
        sm = @set sm.foo = 0
        sm = @set sm.context.handled = true
    end
end

#########

Hsm.ancestor(::Type{State_S1}) = State_S

Hsm.on_initialize!(sm::HsmTest, state::Type{State_S1}) =
    Hsm.transition!(sm, State_S11) do
        print("$(state)-INIT;")
        sm
    end

Hsm.on_event!(sm::HsmTest, state::Type{State_S1}, event::Event_A) =
    Hsm.transition!(sm, State_S1) do
        print("$(state)-$(event);")
        return sm
    end

Hsm.on_event!(sm::HsmTest, state::Type{State_S1}, event::Event_B) =
    Hsm.transition!(sm, State_S11) do
        print("$(state)-$(event);")
        return sm
    end

Hsm.on_event!(sm::HsmTest, state::Type{State_S1}, event::Event_C) =
    Hsm.transition!(sm, State_S2) do
        print("$(state)-$(event);")
        return sm
    end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S1}, event::Event_D)
    if sm.foo == 0
        return Hsm.transition!(sm, State_S) do
            print("$(state)-$(event);")
            sm = @set sm.foo = 1
        end
    end
end

Hsm.on_event!(sm::HsmTest, state::Type{State_S1}, event::Event_F) = 
    Hsm.transition!(sm, State_S211) do
        print("$(state)-$(event);")
        return sm
    end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S1}, event::Event_I)
    print("$(state)-$(event);")
    sm = @set sm.context.handled = true
end

#############

Hsm.ancestor(::Type{State_S11}) = State_S1

function Hsm.on_event!(sm::HsmTest, state::Type{State_S11}, event::Event_D)
    if sm.foo == 1
        return Hsm.transition!(function ()
                print("$(state)-$(event);")
                sm = @set sm.foo = 0
            end, sm, State_S1)
    end
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S11}, event::Event_G)
    Hsm.transition!(function ()
            print("$(state)-$(event);")
            return sm
        end, sm, State_S211)
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S11}, event::Event_H)
    Hsm.transition!(function ()
            print("$(state)-$(event);")
            return sm
        end, sm, State_S)
end

######

Hsm.ancestor(::Type{State_S2}) = State_S

function Hsm.on_initialize!(sm::HsmTest, state::Type{State_S2})
    Hsm.transition!(function ()
            print("$(state)-INIT;")
            return sm
        end, sm, State_S211)
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S2}, event::Event_C)
    Hsm.transition!(function ()
            print("$(state)-$(event);")
            return sm
        end, sm, State_S1)
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S2}, event::Event_F)
    Hsm.transition!(function ()
            print("$(state)-$(event);")
            return sm
        end, sm, State_S11)
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S2}, event::Event_I)
    if sm.foo == 0
        print("$(state)-$(event);")
        sm = @set sm.foo = 1
        sm = @set sm.context.handled = true
    end
end

########

Hsm.ancestor(::Type{State_S21}) = State_S2

function Hsm.on_initialize!(sm::HsmTest, state::Type{State_S21})
    Hsm.transition!(function ()
            print("$(state)-INIT;")
            return sm
        end, sm, State_S211)
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S21}, event::Event_A)
    Hsm.transition!(function ()
            print("$(state)-$(event);")
            return sm
        end, sm, State_S21)
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S21}, event::Event_B)
    Hsm.transition!(function ()
            print("$(state)-$(event);")
            return sm
        end, sm, State_S211)
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S21}, event::Event_G)
    Hsm.transition!(function ()
            print("$(state)-$(event);")
            return sm
        end, sm, State_S11)
end

#############

Hsm.ancestor(::Type{State_S211}) = State_S21

function Hsm.on_event!(sm::HsmTest, state::Type{State_S211}, event::Event_D)
    Hsm.transition!(function ()
            print("$(state)-$(event);")
            return sm
        end, sm, State_S21)
end

function Hsm.on_event!(sm::HsmTest, state::Type{State_S211}, event::Event_H)
    Hsm.transition!(function ()
            print("$(state)-$(event);")
            return sm
        end, sm, State_S)
end

function dispatch!(sm, event)
    print("$(event) - ")
    Hsm.dispatch!(sm, event)
    print("\n")
    return sm
end

function test(hsm)
    hsm = dispatch!(hsm, Event_A())
    hsm = dispatch!(hsm, Event_B())
    hsm = dispatch!(hsm, Event_D())
    hsm = dispatch!(hsm, Event_E())
    hsm = dispatch!(hsm, Event_I())
    hsm = dispatch!(hsm, Event_F())
    hsm = dispatch!(hsm, Event_I())
    hsm = dispatch!(hsm, Event_I())
    hsm = dispatch!(hsm, Event_F())
    hsm = dispatch!(hsm, Event_A())
    hsm = dispatch!(hsm, Event_B())
    hsm = dispatch!(hsm, Event_D())
    hsm = dispatch!(hsm, Event_D())
    hsm = dispatch!(hsm, Event_E())
    hsm = dispatch!(hsm, Event_G())
    hsm = dispatch!(hsm, Event_H())
    hsm = dispatch!(hsm, Event_H())
    hsm = dispatch!(hsm, Event_C())
    hsm = dispatch!(hsm, Event_G())
    hsm = dispatch!(hsm, Event_C())
    hsm = dispatch!(hsm, Event_C())
end

hsm = HsmTest()
test(hsm)