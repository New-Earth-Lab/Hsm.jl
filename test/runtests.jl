using Test


mutable struct MyStateMachine <: Hsm.AbstractStateMachine
    ctx::Hsm.StateMachineContext
    foo::Int
end
mysm = MyStateMachine(
    Hsm.StateMachineContext(),
    1
)
Hsm.register_events!(mysm) do sm

    Hsm.add_state!(sm, name = :Top, ancestor=:Root)
    Hsm.add_state!(sm, name = :S, ancestor=:Top)
    Hsm.add_state!(sm, name = :S1, ancestor=:S)
    Hsm.add_state!(sm, name = :S11, ancestor=:S1)
    Hsm.add_state!(sm, name = :S2, ancestor=:S)
    Hsm.add_state!(sm, name = :S21, ancestor=:S2)
    Hsm.add_state!(sm, name = :S211, ancestor=:S21)


    Hsm.on_initialize!(sm, :Top) do 
        Hsm.transition!(sm, :S2) do 
            sm.foo = 0
        end
    end

    ## S

    Hsm.on_initialize!(sm, :S) do 
        Hsm.transition!(sm, :S11) do 
        end
    end
    Hsm.on_event!(sm, :S, :E) do payload
        Hsm.transition!(sm, :S11) do 
        end
        return Hsm.Handled
    end
    Hsm.on_event!(sm, :S, :I) do payload
        if sm.foo == 1
            sm.foo = 0
            return Hsm.Handled
        end
        return Hsm.NotHandled 
    end

    ## S1
    Hsm.on_initialize!(sm, :S1) do 
        Hsm.transition!(sm, :S11) do
        end
        return Hsm.Handled
    end
    Hsm.on_event!(sm, :S1, :A) do payload
        Hsm.transition!(sm, :S1) do 
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S1, :B) do payload
        Hsm.transition!(sm, :S11) do
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S1, :C) do payload
        Hsm.transition!(sm, :S2) do
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S1, :D) do payload
        if sm.foo == 0
            Hsm.transition!(sm, :S) do
                sm.foo = 1
            end
            return Hsm.Handled
        end
        return Hsm.NotHandled
    end

    Hsm.on_event!(sm, :S1, :F) do payload 
        Hsm.transition!(sm, :S211) do
        end
    end

    Hsm.on_event!(sm, :S1, :I) do payload
        return Hsm.Handled
    end


    ## S11
    Hsm.on_event!(sm, :S11, :D) do payload
        if sm.foo == 1
            Hsm.transition!(sm, :S1) do 
                sm.foo = 0
            end
            return Hsm.Handled
        end
        return Hsm.NotHandled
    end

    Hsm.on_event!(sm, :S11, :G) do  payload
        Hsm.transition!(sm, :S211) do
        end
        return Hsm.Handled
    end
    
    Hsm.on_event!(sm, :S11, :H) do  payload
        Hsm.transition!(sm, :S) do 
        end
        return Hsm.Handled
    end
    



    ## S2
    Hsm.on_initialize!(sm, :S2) do 
        Hsm.transition!(sm, :S211) do
        end
    end

    Hsm.on_event!(sm, :S2, :C) do payload
        Hsm.transition!(sm, :S1) do 
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S2, :F) do payload
        Hsm.transition!(sm, :S11) do 
        end
        return Hsm.Handled
    end

    Hsm.on_event!(sm, :S2, :I) do payload
        if sm.foo == 0
            sm.foo = 1
            return Hsm.Handled
        end
        return Hsm.NotHandled
    end


    ## S21

    Hsm.on_initialize!(sm, :S21) do 
        Hsm.transition!(sm, :S211) do
            # The previous S21 also transitions to S211? Is that right?
        end
    end
    Hsm.on_event!(sm, :S21, :A) do payload
        Hsm.transition!(sm, :S21) do 
        end
        return Hsm.Handled
    end
    Hsm.on_event!(sm, :S21, :B) do payload
        Hsm.transition!(sm, :S211) do 
        end
        return Hsm.Handled
    end
    Hsm.on_event!(sm, :S21, :G) do payload
        Hsm.transition!(sm, :S11) do 
        end
        return Hsm.Handled
    end

    ## S211
    Hsm.on_initialize!(sm, :S21) do
    end
    Hsm.on_event!(sm, :S211, :D) do payload
        Hsm.transition!(sm, :S21) do 
        end
        return Hsm.Handled
    end
    Hsm.on_event!(sm, :S211, :H) do payload
        Hsm.transition!(sm, :S) do 
        end
        return Hsm.Handled
    end
    
end;



@testset "Basics" begin

    @test Hsm.ancestor(sm, :Top) == :Root
    @test Hsm.ancestor(sm, :S) == :Top
    @test Hsm.ancestor(sm, :S1) == :S
    @test Hsm.ancestor(sm, :S11) == :S1
    @test Hsm.ancestor(sm, :S2) == :S
    @test Hsm.ancestor(sm, :S21) == :S2
    @test Hsm.ancestor(sm, :S211) == :S21


    @test Hsm.ischildof(sm, :S, :Top)
    
    @test Hsm.ischildof(sm, :S1, :S)
    @test Hsm.ischildof(sm, :S1, :Top)

    @test Hsm.ischildof(sm, :S11, :S1)
    @test Hsm.ischildof(sm, :S11, :S)
    @test Hsm.ischildof(sm, :S11, :Top)

    @test Hsm.ischildof(sm, :S2, :S)
    @test Hsm.ischildof(sm, :S2, :Top)

    @test Hsm.ischildof(sm, :S21, :S2)
    @test Hsm.ischildof(sm, :S21, :S)
    @test Hsm.ischildof(sm, :S21, :Top)

    @test Hsm.ischildof(sm, :S211, :S21)
    @test Hsm.ischildof(sm, :S211, :S2)
    @test Hsm.ischildof(sm, :S211, :S)
    @test Hsm.ischildof(sm, :S211, :Top)


    @test Hsm.find_lca(sm, :S211, :S11) == :S

end


@testset "All 4 Level HSM transitions" begin
    
    Hsm.transition!(mysm, :Top)
    @test Hsm.current(mysm) == :S211

    Hsm.dispatch!(mysm, :A)
    @test Hsm.current(mysm) == :S211

    Hsm.dispatch!(mysm, :B)
    @test Hsm.current(mysm) == :S211

    Hsm.dispatch!(mysm, :D)
    @test Hsm.current(mysm) == :S211

    Hsm.dispatch!(mysm, :E)
    @test Hsm.current(mysm) == :S11

    Hsm.dispatch!(mysm, :I)
    @test Hsm.current(mysm) == :S11

    Hsm.dispatch!(mysm, :F)
    @test Hsm.current(mysm) == :S211

    Hsm.dispatch!(mysm, :I)
    @test Hsm.current(mysm) == :S211

    Hsm.dispatch!(mysm, :I)
    @test Hsm.current(mysm) == :S211

    Hsm.dispatch!(mysm, :F)
    @test Hsm.current(mysm) == :S11

    Hsm.dispatch!(mysm, :A)
    @test Hsm.current(mysm) == :S11

    Hsm.dispatch!(mysm, :B)
    @test mysm.foo == 0
    @test Hsm.current(mysm) == :S11

    Hsm.dispatch!(mysm, :D)
    @test mysm.foo == 1
    @test Hsm.current(mysm) == :S11

    Hsm.dispatch!(mysm, :D)
    @test mysm.foo == 0
    @test Hsm.current(mysm) == :S11

    Hsm.dispatch!(mysm, :E)
    @test Hsm.current(mysm) == :S11

    Hsm.dispatch!(mysm, :G)
    @test Hsm.current(mysm) == :S211

    Hsm.dispatch!(mysm, :H)
    @test Hsm.current(mysm) == :S11

    Hsm.dispatch!(mysm, :H)
    @test Hsm.current(mysm) == :S11

    Hsm.dispatch!(mysm, :C)
    @test Hsm.current(mysm) == :S211

    Hsm.dispatch!(mysm, :G)
    @test Hsm.current(mysm) == :S11

    Hsm.dispatch!(mysm, :C)
    @test Hsm.current(mysm) == :S211

    Hsm.dispatch!(mysm, :C)
    @test Hsm.current(mysm) == :S11

    
end



@testset "Allocation Free" begin
    
    function test(mysm)
        Hsm.transition!(mysm, :Top)
        Hsm.dispatch!(mysm, :A)
        Hsm.dispatch!(mysm, :B)
        Hsm.dispatch!(mysm, :D)
        Hsm.dispatch!(mysm, :E)
        Hsm.dispatch!(mysm, :I)
        Hsm.dispatch!(mysm, :F)
        Hsm.dispatch!(mysm, :I)
        Hsm.dispatch!(mysm, :I)
        Hsm.dispatch!(mysm, :F)
        Hsm.dispatch!(mysm, :A)
        Hsm.dispatch!(mysm, :B)
        Hsm.dispatch!(mysm, :D)
        Hsm.dispatch!(mysm, :D)
        Hsm.dispatch!(mysm, :E)
        Hsm.dispatch!(mysm, :G)
        Hsm.dispatch!(mysm, :H)
        Hsm.dispatch!(mysm, :H)
        Hsm.dispatch!(mysm, :C)
        Hsm.dispatch!(mysm, :G)
        Hsm.dispatch!(mysm, :C)
        Hsm.dispatch!(mysm, :C)
        return
    end
    precompile(test, (typeof(mysm),))
    @test 0 == @allocated test(mysm)

    
end

