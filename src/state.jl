function do_entry!(sm::AbstractStateMachine, source::Symbol, target::Symbol)
    if source === target
        return
    end

    do_entry!(sm, source, ancestor(sm, target))
    current!(sm, target)

    # Call on_entry callback
    for cb in sm.context.entry_callbacks
        if cb.state == target
            cb.callback()
            break
        end
    end
    return
end

function do_exit!(sm::AbstractStateMachine, source::Symbol, target::Symbol)
    if source === target
        return
    end

    # Call on_exit callback
    for cb in sm.context.exit_callbacks
        if cb.state === source
            cb.callback()
            break
        end
    end

    a = current!(sm, ancestor(sm, source))
    do_exit!(sm, a, target)
    return
end

function transition!(sm::AbstractStateMachine, target::Symbol)
    transition!(Returns(nothing), sm, target)
end

# TODO: work in progress
function transition!(action, sm::AbstractStateMachine, target::Symbol)
    c = current(sm)
    s = source(sm)
    lca = find_lca(sm, s, target)

    # Perform exit transitions from the current state
    do_exit!(sm, c, lca)

    # Call action function
    action()

    # Perform entry transitions to the target state
    do_entry!(sm, lca, target)

    # Set the source to current for initial transitions
    source!(sm, target)

    # Call on_initial callback
    for cb in sm.context.initial_callbacks
        if cb.state === target
            cb.callback()
            break
        end
    end
    return Handled
end

function ancestor(sm::AbstractStateMachine, state::Symbol)
    for s in sm.context.states
        if s.name === state
            return s.ancestor
        end
    end
    return ::Top
end

function find_lca(sm::AbstractStateMachine, source::Symbol, target::Symbol)
    # Special case for transition to self
    if source === target
        return ancestor(sm, source)
    elseif source === ancestor(sm, target)
        return source
    elseif ancestor(sm, source) === target
        return target
    end
    return find_lca_loop(sm, source, target)
end

# Could put Base.@assume_effects :terminates_locally
function find_lca_loop(sm::AbstractStateMachine, source::Symbol, target::Symbol)
    while source !== ::Top
        t = target
        while t !== ::Top
            if t === source
                return t
            end
            t = ancestor(sm, t)
        end
        source = ancestor(sm, source)
    end
    return ::Top
end

# Is 'a' a child of 'b'
function ischildof(sm::AbstractStateMachine, a::Symbol, b::Symbol)
    if a === ::Top || b === ::Top
        return false
    elseif a === b
        return true
    end
    return ischildof(sm, ancestor(sm, a), b)
end
