
function do_entry!(sm::HierarchicalStateMachine1, s::Symbol, t::Symbol)
    if s === t
        return
    end
    do_entry!(sm, s, ancestor(sm, t))
    current!(sm, t)
    # Call on_entry callback
    for enter′ in sm.enters
        if enter′.state == t
            enter′.callback()
            break
        end
    end
    return
end



function do_exit!(sm::HierarchicalStateMachine1, s::Symbol, t::Symbol)
    if s === t
        return
    end
    # Call on_exit callback
    for exit′ in sm.exits
        if exit′.state == s
            exit′.callback()
            break
        end
    end
    a = current!(sm, ancestor(sm,s))
    do_exit!(sm, a, t)
    return
end

function transition!(sm::HierarchicalStateMachine1, target::Symbol)
    transition!(Returns(nothing), sm, target)
end

# TODO: work in progress
function transition!(action::Function, sm::HierarchicalStateMachine1, target::Symbol)
    c = current(sm)
    s = source(sm)
    lca = find_lca(sm, s, target)

    # Perform exit transitions from the current state
    do_exit!(sm, c, lca)

    # Call action function
    action()

    
    # Perform entry transitions to the target state
    do_entry!(sm, lca, target)

    # Set the source to current for initialize transitions
    source!(sm, target)

    # Call on_initialize callback
    for initialize′ in sm.initializes
        if initialize′.state == target
            initialize′.callback()
            break
        end
    end

    return Handled
end

function ancestor(hsm1::HierarchicalStateMachine1, state::Symbol)
    for state′ in hsm1.states
        if state′.name == state
            return state′.ancestor
        end
    end
    return :Root
end

function find_lca(hsm1::HierarchicalStateMachine1, source::Symbol, target::Symbol)
    # Special case for transition to self
    if source === target
        return ancestor(hsm1, source)
    elseif source === ancestor(hsm1, target)
        return source
    elseif ancestor(hsm1, source) === target
        return target
    end
    find_lca_loop(hsm1, source, target)
end
# Could put Base.@assume_effects :terminates_locally
function find_lca_loop(sm::HierarchicalStateMachine1, source, target)
    while source !== :Root
        t = target
        while t !== :Root
            if t === source
                return t
            end
            t = ancestor(sm, t)
        end
        source = ancestor(sm, source)
    end
    return :Root
end

# Is 'a' a child of 'b'
function isancestorof(hsm, a::Symbol, b::Symbol)
    if a === :Root || b === :Root
        return false
    elseif a === b
        return true
    end
    isancestorof(hsm, ancestor(hsm, a), b)
end # TODO: this naming is bad! Should be ischildof!
