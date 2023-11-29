using Hsm

# Using a inner constructor is much slower, I wonder why?
mutable struct MyStateMachine <: Hsm.AbstractStateMachine
    context::Hsm.StateMachineContext
    foo::Int
end
mysm = MyStateMachine(Hsm.StateMachineContext(), 1)

Hsm.register_events!(mysm) do sm
    Hsm.add_state!(sm, name = :Top, ancestor = :Root)
    Hsm.add_state!(sm, name = :S, ancestor = :Top)
    Hsm.add_state!(sm, name = :S1, ancestor = :S)
    Hsm.add_state!(sm, name = :S11, ancestor = :S1)
    Hsm.add_state!(sm, name = :S2, ancestor = :S)
    Hsm.add_state!(sm, name = :S21, ancestor = :S2)
    Hsm.add_state!(sm, name = :S211, ancestor = :S21)

    # Hsm.on_entry!(() -> # print("Top-ENTRY;"), sm, :Top)
    # Hsm.on_entry!(() -> # print("S-ENTRY;"), sm, :S)
    # Hsm.on_entry!(() -> # print("S1-ENTRY;"), sm, :S1)
    # Hsm.on_entry!(() -> # print("S11-ENTRY;"), sm, :S11)
    # Hsm.on_entry!(() -> # print("S2-ENTRY;"), sm, :S2)
    # Hsm.on_entry!(() -> # print("S21-ENTRY;"), sm, :S21)
    # Hsm.on_entry!(() -> # print("S211-ENTRY;"), sm, :S211)

    # Hsm.on_exit!(() -> # print("S-EXIT;"), sm, :S)
    # Hsm.on_exit!(() -> # print("S1-EXIT;"), sm, :S1)
    # Hsm.on_exit!(() -> # print("S11-EXIT;"), sm, :S11)
    # Hsm.on_exit!(() -> # print("S2-EXIT;"), sm, :S2)
    # Hsm.on_exit!(() -> # print("S21-EXIT;"), sm, :S21)
    # Hsm.on_exit!(() -> # print("S211-EXIT;"), sm, :S211)

    Hsm.on_initial!(sm, :Top) do
        Hsm.transition!(sm, :S2) do
            # print("Top-INIT;")
            sm.foo = 0
        end
    end

    ## S

    Hsm.on_initial!(sm, :S) do
        Hsm.transition!(sm, :S11) do
            # print("S-INIT;")
        end
    end

    Hsm.on_event!(sm, :S, :E) do payload
        Hsm.transition!(sm, :S11) do
            # print("S-E;")
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S, :I) do payload
        if sm.foo == 1
            # print("S-I;")
            sm.foo = 0
            return Hsm.Handled
        end
        return Hsm.NotHandled
    end

    ## S1
    Hsm.on_initial!(sm, :S1) do
        Hsm.transition!(sm, :S11) do
            # print("S1-INIT;")
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S1, :A) do payload
        Hsm.transition!(sm, :S1) do
            # print("S1-A;")
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S1, :B) do payload
        Hsm.transition!(sm, :S11) do
            # print("S1-B;")
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S1, :C) do payload
        Hsm.transition!(sm, :S2) do
            # print("S1-C;")
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S1, :D) do payload
        if sm.foo == 0
            Hsm.transition!(sm, :S) do
                # print("S1-D;")
                sm.foo = 1
            end
            return Hsm.Handled
        end
        return Hsm.NotHandled
    end

    Hsm.on_event!(sm, :S1, :F) do payload
        Hsm.transition!(sm, :S211) do
            # print("S1-F;")
        end
    end

    Hsm.on_event!(sm, :S1, :I) do payload
        # print("S1-I;")
        return Hsm.Handled
    end

    ## S11
    Hsm.on_event!(sm, :S11, :D) do payload
        if sm.foo == 1
            Hsm.transition!(sm, :S1) do
                # print("S11-D;")
                sm.foo = 0
            end
            return Hsm.Handled
        end
        return Hsm.NotHandled
    end

    Hsm.on_event!(sm, :S11, :G) do payload
        Hsm.transition!(sm, :S211) do
            # print("S11-G;")
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S11, :H) do payload
        Hsm.transition!(sm, :S) do
            # print("S11-H;")
        end
        return Hsm.Handled
    end

    ## S2
    Hsm.on_initial!(sm, :S2) do
        Hsm.transition!(sm, :S211) do
            # print("S2-INIT;")
        end
    end

    Hsm.on_event!(sm, :S2, :C) do payload
        Hsm.transition!(sm, :S1) do
            # print("S2-C;")
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S2, :F) do payload
        Hsm.transition!(sm, :S11) do
            # print("S2-F;")
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S2, :I) do payload
        if sm.foo == 0
            # print("S2-I;")
            sm.foo = 1
            return Hsm.Handled
        end
        return Hsm.NotHandled
    end

    ## S21

    Hsm.on_initial!(sm, :S21) do
        Hsm.transition!(sm, :S211) do
            # The previous S21 also transitions to S211? Is that right?
            # print("S21-INIT;")
        end
    end

    Hsm.on_event!(sm, :S21, :A) do payload
        Hsm.transition!(sm, :S21) do
            # print("S21-A;")
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S21, :B) do payload
        Hsm.transition!(sm, :S211) do
            # print("S21-B;")
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S21, :G) do payload
        Hsm.transition!(sm, :S11) do
            # print("S21-G;")
        end
        return Hsm.Handled
    end

    ## S211

    Hsm.on_event!(sm, :S211, :D) do payload
        Hsm.transition!(sm, :S21) do
            # print("S211-D;")
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S211, :H) do payload
        Hsm.transition!(sm, :S) do
            # print("S211-H;")
        end
        return Hsm.Handled
    end
end;

# Start by transitioning to Top
function test(hsm)

    function dispatch!(hsm, event)
        # print("$event:")
        Hsm.dispatch!(hsm, event)
        println()
    end

    Hsm.transition!(hsm, :Top)
    Hsm.dispatch!(hsm, :A)
    Hsm.dispatch!(hsm, :B)
    Hsm.dispatch!(hsm, :D)
    Hsm.dispatch!(hsm, :E)
    Hsm.dispatch!(hsm, :I)
    Hsm.dispatch!(hsm, :F)
    Hsm.dispatch!(hsm, :I)
    Hsm.dispatch!(hsm, :I)
    Hsm.dispatch!(hsm, :F)
    Hsm.dispatch!(hsm, :A)
    Hsm.dispatch!(hsm, :B)
    Hsm.dispatch!(hsm, :D)
    Hsm.dispatch!(hsm, :D)
    Hsm.dispatch!(hsm, :E)
    Hsm.dispatch!(hsm, :G)
    Hsm.dispatch!(hsm, :H)
    Hsm.dispatch!(hsm, :H)
    Hsm.dispatch!(hsm, :C)
    Hsm.dispatch!(hsm, :G)
    Hsm.dispatch!(hsm, :C)
    Hsm.dispatch!(hsm, :C)

    return
end
precompile(test, (typeof(mysm),))
@time test(mysm)
