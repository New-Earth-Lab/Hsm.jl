using Revise
# using JET
using BenchmarkTools
using Hsm
using Hsm: register_events!, add_state!, HierarchicalStateMachine1, StateMachineContext1, on_initialize!, on_event!, transition!, on_exit!, on_entry!, current, source, dispatch!
using Hsm: Handled, NotHandled


## DEFINITION ##########################################
# states = [
    # (; name = :Top, ancestor=:Root),
    # (; name = :S, ancestor=:Top),
    # (; name = :S1, ancestor=:S),
    # (; name = :S11, ancestor=:S1),
    # (; name = :S2, ancestor=:S),
    # (; name = :S21, ancestor=:S2),
    # (; name = :S211, ancestor=:S21),
# ]
hsm1 = HierarchicalStateMachine1(StateMachineContext1(:Root, :Root,0) )
register_events!(hsm1) do sm

    add_state!(sm, name = :Top, ancestor=:Root)
    add_state!(sm, name = :S, ancestor=:Top)
    add_state!(sm, name = :S1, ancestor=:S)
    add_state!(sm, name = :S11, ancestor=:S1)
    add_state!(sm, name = :S2, ancestor=:S)
    add_state!(sm, name = :S21, ancestor=:S2)
    add_state!(sm, name = :S211, ancestor=:S21)

    # on_entry!(()->print("Top-ENTRY;"), sm, :Top)
    # on_entry!(()->print("S-ENTRY;"), sm, :S)
    # on_entry!(()->print("S1-ENTRY;"), sm, :S1)
    # on_entry!(()->print("S11-ENTRY;"), sm, :S11)
    # on_entry!(()->print("S2-ENTRY;"), sm, :S2)
    # on_entry!(()->print("S21-ENTRY;"), sm, :S21)
    # on_entry!(()->print("S211-ENTRY;"), sm, :S211)

    # on_exit!(()->print("S-EXIT;"), sm, :S)
    # on_exit!(()->print("S1-EXIT;"), sm, :S1)
    # on_exit!(()->print("S11-EXIT;"), sm, :S11)
    # on_exit!(()->print("S2-EXIT;"), sm, :S2)
    # on_exit!(()->print("S21-EXIT;"), sm, :S21)
    # on_exit!(()->print("S211-EXIT;"), sm, :S211)

    on_initialize!(sm, :Top) do 
        transition!(sm, :S2) do 
            # print("Top-INIT;")
            sm.ctx.foo = 0
        end
    end

    ## S

    on_initialize!(sm, :S) do 
        transition!(sm, :S11) do 
            # print("S1-INIT")
        end
    end
    on_event!(sm, :S, :E) do payload
        transition!(sm, :S11) do 
            # print("S11-E")
        end
        return Handled
    end
    on_event!(sm, :S, :I) do payload
        if sm.ctx.foo == 1
            sm.ctx.foo = 0
            return Handled
        end
        return NotHandled 
    end

    ## S1
    on_initialize!(sm, :S1) do 
        transition!(sm, :S11) do
            # print("S1-INIT;")
        end
        return Handled
    end
    on_event!(sm, :S1, :A) do payload
        transition!(sm, :S1) do 
            # print("S1-A;")
        end
        return Handled
    end

    on_event!(sm, :S1, :B) do payload
        transition!(sm, :S11) do
            # print("S1-B;")
        end
        return Handled
    end

    on_event!(sm, :S1, :C) do payload
        transition!(sm, :S2) do
            # print("S2-C;")
        end
        return Handled
    end

    on_event!(sm, :S1, :D) do payload
        if sm.ctx.foo == 0
            transition!(sm, :S) do
                # print("S1;")
                sm.ctx.foo = 1
            end
            return Handled
        end
        return NotHandled
    end

    on_event!(sm, :S1, :F) do payload 
        transition!(sm, :S211) do
            # print("S211-F;")
        end
    end

    on_event!(sm, :S1, :I) do payload
        # print("S1-I;")
        return Handled
    end


    ## S11
    on_event!(sm, :S11, :D) do payload
        if sm.ctx.foo == 1
            transition!(sm, :S1) do 
                # print("S11-D;")
                sm.ctx.foo = 0
            end
            return Handled
        end
        return NotHandled
    end

    on_event!(sm, :S11, :G) do  payload
        transition!(sm, :S11) do 
            # print("S11-G;")
        end
        return Handled
    end
    
    on_event!(sm, :S11, :H) do  payload
        transition!(sm, :S) do 
            # print("S11-H;")
        end
        return Handled
    end
    



    ## S2
    on_initialize!(sm, :S2) do 
        transition!(sm, :S211) do
            # print("S2-INIT;")
        end
    end

    on_event!(sm, :S2, :C) do payload
        transition!(sm, :S1) do 
            # print("S2-C;")
        end
        return Handled
    end

    on_event!(sm, :S2, :F) do payload
        transition!(sm, :S11) do 
            # print("S2-F;")
        end
        return Handled
    end

    on_event!(sm, :S2, :I) do payload
        if sm.ctx.foo == 0
            sm.ctx.foo = 1
            return Handled
        end
        return NotHandled
    end


    ## S21

    on_initialize!(sm, :S21) do 
        transition!(sm, :S211) do
            # The previous S21 also transitions to S211? Is that right?
            # print("S21-INIT;")
        end
    end
    on_event!(sm, :S21, :A) do payload
        transition!(sm, :S21) do 
            # print("S21-A;")
        end
        return Handled
    end
    on_event!(sm, :S21, :B) do payload
        transition!(sm, :S211) do 
            # print("S21-B;")
        end
        return Handled
    end
    on_event!(sm, :S21, :G) do payload
        transition!(sm, :S11) do 
            # print("S21-G;")
        end
        return Handled
    end

    ## S211
    on_initialize!(sm, :S21) do
    end
    on_event!(sm, :S211, :D) do payload
        transition!(sm, :S21) do 
            # print("S211-D;")
        end
        return Handled
    end
    on_event!(sm, :S211, :H) do payload
        transition!(sm, :S) do 
            # print("S211-H;")
        end
        return Handled
    end
    
end;


# Start by transitioning to Top
function test(hsm)
    # Yuck, initial initialization is painful
    # call on_initialize callback of Top:
    for I in hsm.initializes
        if I.state == :Top
            I.callback()
        end
    end
    # transition!(hsm, :Top)
    dispatch!(hsm, :A)
    dispatch!(hsm, :B)
    dispatch!(hsm, :D)
    dispatch!(hsm, :E)
    dispatch!(hsm, :I)
    dispatch!(hsm, :F)
    dispatch!(hsm, :I)
    dispatch!(hsm, :I)
    dispatch!(hsm, :F)
    dispatch!(hsm, :A)
    dispatch!(hsm, :B)
    dispatch!(hsm, :D)
    dispatch!(hsm, :D)
    dispatch!(hsm, :E)
    dispatch!(hsm, :G)
    dispatch!(hsm, :H)
    dispatch!(hsm, :H)
    dispatch!(hsm, :C)
    dispatch!(hsm, :G)
    dispatch!(hsm, :C)
    dispatch!(hsm, :C)
    
    return
end
@btime test(hsm1)
# TODO: initial transition to Top is calling initialize but not leaving us in S1
# Bit confused about Top vs Root
# Game plan about the weird double init of the HSM: Don't pass in hsm just to push. Create two kinds of objects, one to hold everything, and a "real" one to put them when done.