#=


This file sketches out some ideas for a different HSM implementation
that is properly unrolled and doesn't need to allocate anything
when changing states and dispatching events.

Philosophy:
We need to build a graph of states in a tuple-style structure?
The current state and source states should be represented by simple integers.


# =#

# TestHsm = @state_machine begin

#     @state S begin
#         @state S1 begin
#             @state S11 begin
#             end
#         end
#         @state S2 begin
#             @state S21 begin
#                 @state S211 begin
#                 end
#             end
#         end
#     end

#     @event E function(hsm)
#     end

# end


## ############



# Create the stucture of states step by step
# Create the event handling, on entry/exit step by step
# Call a function to "seal it off" and turn this flexible representation
#     into some kind of integer / tuple -based fixed transition code.
# Would be nice if this could also be graphed using a Package Extension.
# Don't use code generation. Instead, build up a tuple structure with the necessary
#     structure so that the transition functions work appropriately.

# Start with how we want to transition between states

# Do we want to use FunctionWrappers??
# This lets us type-stabily call a bunch of different functions.
# Yes, I think we need this? Unless we can represent all the transitions
# in code. Maybe we can.
# But we'll normally have a loop dispatching events right.
# Unless we have a bunch of e.g. gotos and at each location in the code
# we are somehow waiting for events and responding to them.

# while 


## Okay so we don't want to use GOTOs (as fun as that would be) for HSMs
# But we do want to use function wrappers. 


# Potential game plane
# Store state names as symbols
# callbacks are stored as FunctionWrappers.

# ##
# states = (
#     name = :S,
#     children = (
#         (
#             name = :S1,
#             children = (
#                 (
#                     name=:S11,
#                     children = (),
#                 )
#             )
#         ),
#         (
#             name = :S2,
#             children = (
#                 (
#                     name=:S21,
#                     children = (
#                         (
#                             name=:S21,
#                             children = (
#                             ),
#                         )
#                     ),
#                 )
#             )
#         )
#     )
# )
# states′ = (;
#     name=:Root,
#     children=(states,
#     )
# )

# ##
# # In future we can have a mutable struct to hold all of these 
# # and to build it up step by step. 
# # Then call `prepare()` or something and get the above tuple structure.
# # Then we can `dispatch!(hsm, :Event_A)`

# # Problem is we really want to be able to dispatch to functions with 
# # julia typed objects. Passing byte-buffers only is one possibility.
# # But yuck.

# onevent!(hsm, :Event_A) do bytes
#     transition!(hsm, :State_S2)
# end
# dispatch!(hsm, :State_S2)

##
# We perhaps want events to still be julia objects.
# How can we square that with the above runtime implementation?
# We don't rely on runtime dispatch. We have individual functions that
# we pick based on the states and transitions. But then we want to hand
# this object off to it.
# If we want to do that, we can't really use FunctionWrappers.
# But do we need to? We could write out a function that branches
# to all possible transitions. e.g
# function calleventhandler(dispatched_event_type::ArrayMessage)
# 
# end

# Nope, best strategy is sending byte buffers around and instanciating
# them inside the right function. Not terrible. 
# We can add some kind of wrapper where we "assert" the input type
# and this cast is handled for us and calls our callback.
# on_event!(hsm, :Event_A) do bytes
#     transition!(hsm, :State_S2)
# end

# on_event!(hsm, :Event_A) do bytes
#     process_array(hsm, ArrayMessage(bytes))
#     transition!(hsm, :State_S2)
# end

# ## ####################
# # But could be any function, not just argument type
# using FunctionWrappers: FunctionWrapper
# HSM = Nothing # TODO of course
# function on_event!(callback::Base.Callable, hsm, event_name::Symbol, typer::Base.Callable)
#     our_callback(hsm, bytes)::Bool = callback(hsm, typer(bytes))
#     # In reality, a SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}
#     fw = FunctionWrapper{Bool,Tuple{StateMachineContext,Vector{UInt8}}}(our_callback)
#     @show fw
# end
# hsm = nothing
# # on_event!(hsm, :Event_A, ArrayMessage{Int16,2}) do msg
# fw = on_event!(hsm, :Event_A, sum) do hsm, msg
#     # @show msg
#     # transition!(hsm, :State_S2)
#     return true
# end

# ##


# ##
#     @state S begin
#         @state S1 begin
#             @state S11 begin
#             end
#         end
#         @state S2 begin
#             @state S21 begin
#                 @state S211 begin
#                 end
#             end
#         end
#     end

#     @event E function(hsm)
#     end

# end

# :S1 => function(a,b)

# end




######################## BEGIN #############
using AllocCheck
## 
# @enum EventHandled Handled NotHandled
# struct StateMachineContext{S,T,X,E,I,CTX}
#     states::S
#     events::T
#     exits::X
#     enters::E
#     initializes::I
#     ctx::CTX
# end

# # Defined by user #
# mutable struct StateMachineContext1
#     current::Symbol
#     source::Symbol
#     # history::Symbol
#     foo::Int
# end

# function add_state!(sm::StateMachineContext; name::Symbol, ancestor::Symbol)
#     push!(sm.states, (;name, ancestor))
# end

# using FunctionWrappers: FunctionWrapper
# function on_event!(callback::Base.Callable, sm::StateMachineContext, state_name::Symbol, event_name::Symbol)
#     @info "Registering callback" state_name event_name
#     precompile(callback, (Vector{UInt8},))
#     # allocations = check_allocs(callback, (Vector{UInt8},))
#     # if !isempty(allocations)
#     #     @warn "Provided on_event! callback will allocate. This is bad for real-time performance!" allocations
#     # end

#     # TODO: In reality, a SubArray{UInt8, 1, Vector{UInt8}, Tuple{UnitRange{Int64}}, true}
#     fw = FunctionWrapper{EventHandled,Tuple{Vector{UInt8}}}(callback) # Works!
#     # fw = FunctionWrapper{EventHandled,Tuple{Vector{UInt8},typeof(typer)}}(our_callback)
#     # fw = @cfunction($our_callback, Cvoid, (Vector{UInt8},))
#     push!(sm.event_callbacks, (; name=event_name, state=state_name, callback=fw))
#     return nothing
# end
# function on_entry!(callback::Base.Callable, sm::StateMachineContext, state_name::Symbol,)
#     @info "Registering enter callback" state_name
#     precompile(callback, ())
#     # allocations = check_allocs(callback, ())
#     # if !isempty(allocations)
#     #     @warn "Provided on_entry! callback will allocate. This is bad for real-time performance!" allocations
#     # end
#     fw = FunctionWrapper{Nothing,Tuple{}}(callback) 
#     push!(sm.enter_callbacks, (; state=state_name, callback=fw))
#     return nothing
# end
# function on_exit!(callback::Base.Callable, sm::StateMachineContext, state_name::Symbol,)
#     @info "Registering exit callback" state_name
#     precompile(callback, ())
#     # allocations = check_allocs(callback, ())
#     # if !isempty(allocations)
#     #     @warn "Provided on_exit! callback will allocate. This is bad for real-time performance!" allocations
#     # end
#     fw = FunctionWrapper{Nothing,Tuple{}}(callback) 
#     push!(sm.exit_callbacks, (; state=state_name, callback=fw))
#     return nothing
# end
# function on_initialize!(callback::Base.Callable, sm::StateMachineContext, state_name::Symbol,)
#     @info "Registering initialize callback" state_name
#     precompile(callback, ())
#     # allocations = check_allocs(callback, ())
#     # if !isempty(allocations)
#     #     @warn "Provided on_initialize! callback will allocate. This is bad for real-time performance!" allocations
#     # end
#     fw = FunctionWrapper{Nothing,Tuple{}}(callback) 
#     push!(sm.initialize_callbacks, (; state=state_name, callback=fw))
#     return nothing
# end

# Problem: we have a recursive relationship between the function wrapper type (since it receives
# hsm as an argument) and the HSM itself. 
# Can we relax the types on the HSM?
# Perhaps a better strategy:
# states and events are owned by something that contains the current and source values.
# Those are what need to change. 
# BTW, this can be the user's type.

##
# hsm1 = StateMachineContext()
# HSM11.

##

##



##

# current(hsm1::StateMachineContext) = hsm1.ctx.current
# current!(hsm1::StateMachineContext, state::Symbol) = hsm1.ctx.current = state
# source(hsm1::StateMachineContext) = hsm1.ctx.source
# source!(hsm1::StateMachineContext, state::Symbol) = hsm1.ctx.source = state

# function ancestor(hsm1::StateMachineContext, state::Symbol)
#     for state′ in hsm1.states
#         if state′.name == state
#             return state′.ancestor
#         end
#     end
#     return :Root
# end

# function find_lca(hsm1::StateMachineContext, source::Symbol, target::Symbol)
#     # Special case for transition to self
#     if source === target
#         return ancestor(hsm1, source)
#     elseif source === ancestor(hsm1, target)
#         return source
#     elseif ancestor(hsm1, source) === target
#         return target
#     end
#     find_lca_loop(hsm1, source, target)
# end
# # Could put Base.@assume_effects :terminates_locally
# function find_lca_loop(sm::StateMachineContext, source, target)
#     while source !== :Root
#         t = target
#         while t !== :Root
#             if t === source
#                 return t
#             end
#             t = ancestor(sm, t)
#         end
#         source = ancestor(sm, source)
#     end
#     return :Root
# end

# # Is 'a' a child of 'b'
# function ischildof(hsm, a::Symbol, b::Symbol)
#     if a === :Root || b === :Root
#         return false
#     elseif a === b
#         return true
#     end
#     ischildof(hsm, ancestor(hsm, a), b)
# end # TODO: this naming is bad! Should be ischildof!

##

# function transition!(sm::StateMachineContext, target::Symbol)
#     transition!(Returns(nothing), sm, target)
# end




# # TODO: work in progress
# function transition!(action::Function, sm::StateMachineContext, target::Symbol)
#     c = current(sm)
#     s = source(sm)
#     lca = find_lca(sm, s, target)

#     # Perform exit transitions from the current state
#     do_exit!(sm, c, lca)

#     # Call action function
#     action()

    
#     # Perform entry transitions to the target state
#     do_entry!(sm, lca, target)

#     # Set the source to current for initialize transitions
#     source!(sm, target)

#     for initialize′ in sm.initialize_callbacks
#         if initialize′.state == target
#             initialize′.callback()
#             break
#         end
#     end

#     return Handled
# end

# function do_entry!(sm::StateMachineContext, s::Symbol, t::Symbol)
#     if s === t
#         return
#     end
#     do_entry!(sm, s, ancestor(sm, t))
#     current!(sm, t)
#     for enter′ in sm.enter_callbacks
#         if enter′.state == t
#             enter′.callback()
#             break
#         end
#     end
#     return
# end



# function do_exit!(sm::StateMachineContext, s::Symbol, t::Symbol)
#     if s === t
#         return
#     end
#     for exit′ in sm.exit_callbacks
#         if exit′.state == s
#             exit′.callback()
#             break
#         end
#     end
#     a = current!(sm, ancestor(sm,s))
#     do_exit!(sm, a, t)
#     return
# end

# const empty_payload = UInt8[]
# function dispatch!(sm::StateMachineContext, event, payload=empty_payload)
#     do_event!(sm, current(sm), event, payload)
# end

# function do_event!(sm::StateMachineContext, s::Symbol, event::Symbol, payload) # TODO: payload typed

#     # TODO: Darryl does this seem appropriate? We want a way 
#     # to be notified if the user dispatches an event that is not accounted for
#     # at all or handled all the way up the state machine.
#     if s == :Root
#         error(lazy"Event $event not handled by any states up to Root")
#     end

#     # Find the main source state by calling on_event! until the event is handled
#     source!(sm, s)
#     # on_event!(sm, s , event)
#     # find relevant event

#     handled = NotHandled
#     for event′ in sm.event_callbacks
#         if event′.name == event && event′.state == s
#             handled = event′.callback(payload)
#             break
#         end
#     end

#     if handled != Handled
#         do_event!(sm, ancestor(sm, s), event, payload)
#     end
#     return
# end


## DEFINITION ##########################################
states = [
    (; name = :S, ancestor=:Root),
    (; name = :S1, ancestor=:S),
    (; name = :S11, ancestor=:S1),
    (; name = :S2, ancestor=:S),
    (; name = :S21, ancestor=:S2),
    (; name = :S211, ancestor=:S21),
]


hsm1 = StateMachineContext(states, [], [],[], [], StateMachineContext1(:S, :S,0) )

function register_events!(callback, hsm1)
    callback(hsm1)

    # We could now look at all events I suppose if we needed to inspect them

    hsm1 = StateMachineContext(
        tuple(hsm1.states...), 
        tuple(hsm1.event_callbacks...), 
        tuple(hsm1.exit_callbacks...), 
        tuple(hsm1.enter_callbacks...), 
        tuple(hsm1.initialize_callbacks...), 
        StateMachineContext1(:S, :S,0) 
    )
end
hsm1 = register_events!(hsm1) do hsm1

    on_event!(hsm1, :S, :A) do payload
        buf = identity(payload)
        transition!(hsm1, :S2)
        return Handled
    end;

    on_exit!(hsm1, :S) do 
    end

    on_event!(hsm1, :S21, :B) do payload
        transition!(hsm1, :S2)
        return Handled
    end;

    on_entry!(hsm1, :S2) do 
        println("hello from enter")
    end
    on_exit!(hsm1, :S2) do 
        println("hello from exit")
    end
    # on_event!(hsm1, :Processing, :ArrayMessage) do msg
    #     transition!(hsm1, :S2)
    #     return Handled
    # end;

end
##

payload = zeros(UInt8, 10)
@time ancestor(hsm1, :S211)
@time find_lca(hsm1, :S21, :S11)
@time ischildof(hsm1, :S2, :S21)
hsm1.ctx.current = :S2
transition!(hsm1, :S211)
transition!(hsm1, :S11)
# @btime transition!(hsm1, :S1) # It's only allocating a return value on the REPL
function testtransition(hsm1)
    @time transition!(hsm1, :S1)
    return nothing
end
testtransition(hsm1)

@time dispatch!(hsm1, :A, payload)
##
@btime dispatch!(hsm1, :A, payload)


##






##


## DEFINITION ##########################################
states = [
    (; name = :S, ancestor=:Root),
    (; name = :S1, ancestor=:S),
    (; name = :S11, ancestor=:S1),
    (; name = :S2, ancestor=:S),
    (; name = :S21, ancestor=:S2),
    (; name = :S211, ancestor=:S21),
]
hsm1 = StateMachineContext(states, [], [],[], [], StateMachineContext1(:Top, :Top,0) )
hsm1 = register_events!(hsm1) do sm

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
            print("Top-INIT;")
            sm.foo = 0
        end
    end

    ## S

    on_initialize!(sm, :S) do 
        transition!(sm, :S11) do 
            print("S1-INIT")
        end
    end
    on_event!(sm, :S, :E) do payload
        transition!(sm, :S11) do 
            print("S11-E")
        end
        return Handled
    end
    on_event!(sm, :S, :I) do payload
        if sm.foo == 1
            sm.foo = 0
            return Handled
        end
        return NotHandled 
    end

    ## S1
    on_initialize!(sm, :S1) do 
        transition!(sm, :S11) do
            print("S1-INIT;")
        end
        return Handled
    end
    on_event!(sm, :S1, :A) do payload
        transition!(sm, :S1) do 
            print("S1-A;")
        end
        return Handled
    end

    on_event!(sm, :S1, :B) do payload
        transition!(sm, :S11) do sm
            print("S1-B;")
        end
        return Handled
    end

    on_event!(sm, :S1, :C) do payload
        transition!(sm, :S2) do sm
            print("S2-C;")
        end
        return Handled
    end

    on_event!(sm, :S1, :D) do payload
        if sm.foo == 0
            transition!(sm, :S) do
                print("S1;")
                sm.foo = 1
            end
            return Handled
        end
        return NotHandled
    end

    on_event!(sm, :S1, :F) do payload 
        transition!(sm, State_S211()) do sm
            print("S211-F;")
        end
    end

    on_event!(sm, :S1, :I) do payload
        print("S1-I;")
        return Handled
    end


    ## S11
    on_event!(sm, :S11, :D) do payload
        if sm.foo == 1
            transition!(sm, :S1) do 
                print("S11-D;")
                sm.foo = 0
            end
            return Handled
        end
        return NotHandled
    end

    on_event!(sm, :S11, :G) do  payload
        transition!(sm, :S11) do 
            print("S11-G;")
        end
        return Handled
    end
    
    on_event!(sm, :S11, :H) do  payload
        transition!(sm, :S) do 
            print("S11-H;")
        end
        return Handled
    end
    



    ## S2
    on_initialize!(sm, :S2) do 
        transition!(sm, :S211) do
            print("S2-INIT;")
        end
    end

    on_event!(sm, :S2, :C) do payload
        transition!(sm, :S1) do 
            print("S2-C;")
        end
        return Handled
    end

    on_event!(sm, :S2, :F) do payload
        transition!(sm, :S11) do 
            print("S2-F;")
        end
        return Handled
    end

    on_event!(sm, :S2, :I) do payload
        if sm.foo == 0
            sm.foo = 1
            return Handled
        end
        return NotHandled
    end


    ## S21

    on_initialize!(sm, :S21) do 
        transition!(sm, :S211) do sm
            # The previous S21 also transitions to S211? Is that right?
            print("S21-INIT;")
        end
    end
    on_event!(sm, :S21, :A) do payload
        transition!(sm, :S211) do 
            print("S21-A;")
        end
        return Handled
    end
    on_event!(sm, :S21, :B) do payload
        transition!(sm, :S211) do 
            print("S21-B;")
        end
        return Handled
    end
    on_event!(sm, :S21, :G) do payload
        transition!(sm, :S11) do 
            print("S21-G;")
        end
        return Handled
    end

    ## S211
    on_initialize!(sm, :S21) do 
        # NOTE: I added this one not present in the original one
        print("S211-INIT;")
    end
    on_event!(sm, :S211, :D) do payload
        transition!(sm, :S21) do 
            print("S211-D;")
        end
        return Handled
    end
    on_event!(sm, :S211, :H) do payload
        transition!(sm, :S) do 
            print("S211-H;")
        end
        return Handled
    end
    
end;
##

# Start by transitioning to Top
function test(hsm)
    # Yuck, initial initialization is painful
    # for I in hsm1.initialize_callbacks
    #     if I.state == :Top
    #         I.callback()
    #     end
    # end
    transition!(hsm, :Top)
    println()
    @show current(hsm)
    return
    hsm = dispatch!(hsm, :A)
    hsm = dispatch!(hsm, :B)
    hsm = dispatch!(hsm, :D)
    hsm = dispatch!(hsm, :E)
    hsm = dispatch!(hsm, :I)
    hsm = dispatch!(hsm, :F)
    hsm = dispatch!(hsm, :I)
    hsm = dispatch!(hsm, :I)
    hsm = dispatch!(hsm, :F)
    hsm = dispatch!(hsm, :A)
    hsm = dispatch!(hsm, :B)
    hsm = dispatch!(hsm, :D)
    hsm = dispatch!(hsm, :D)
    hsm = dispatch!(hsm, :E)
    hsm = dispatch!(hsm, :G)
    hsm = dispatch!(hsm, :H)
    hsm = dispatch!(hsm, :H)
    hsm = dispatch!(hsm, :C)
    hsm = dispatch!(hsm, :G)
    hsm = dispatch!(hsm, :C)
    hsm = dispatch!(hsm, :C)
    
    return
end
test(hsm1)
# TODO: need to copy over example
# TODO: initial transition to Top is calling initialize but not leaving us in S1
# Bit confused about Top vs Root
# Game plan about the weird double init of the HSM: Don't pass in hsm just to push. Create two kinds of objects, one to hold everything, and a "real" one to put them when done.