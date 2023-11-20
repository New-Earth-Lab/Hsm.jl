struct Root <: AbstractHsmState end
ancestor(::AbstractHsmState) = Root()
on_initialize!(sm::AbstractHsmStateMachine, ::AbstractHsmState) = sm
on_entry!(sm::AbstractHsmStateMachine, ::AbstractHsmState) = sm
on_exit!(sm::AbstractHsmStateMachine, ::AbstractHsmState) = sm

function do_entry!(sm::AbstractHsmStateMachine, s::AbstractHsmState, t::AbstractHsmState)
    if s === t
        return sm
    end
    sm = do_entry!(sm, s, ancestor(t))
    if isnothing(sm)
        error("Error in state machine definition. `nothing` returned instead of an updated state machine.")
    end
    sm = current!(sm, t)
    if isnothing(sm)
        error("Error in state machine definition. `nothing` returned instead of an updated state machine.")
    end
    sm = on_entry!(sm, t)
    if isnothing(sm)
        error("Error in state machine definition. `nothing` returned instead of an updated state machine.")
    end
    return sm
end

function do_exit!(sm::AbstractHsmStateMachine, s::AbstractHsmState, t::AbstractHsmState)
    if s === t
        return sm
    end
    sm = on_exit!(sm, s)
    if isnothing(sm)
        error("Error in state machine definition. `nothing` returned instead of an updated state machine.")
    end
    a = ancestor(s)
    sm = current!(sm, a)
    if isnothing(sm)
        error("Error in state machine definition. `nothing` returned instead of an updated state machine.")
    end
    sm = do_exit!(sm, a, t)
    if isnothing(sm)
        error("Error in state machine definition. `nothing` returned instead of an updated state machine.")
    end
    return sm
end

function transition!(sm::AbstractHsmStateMachine, target::AbstractHsmState)
    transition!(Returns(nothing), sm, target)
end

function transition!(action::Function, sm::AbstractHsmStateMachine, target::AbstractHsmState)
    c = current(sm)
    s = source(sm)
    lca = find_lca(s, target)

    # Perform exit transitions from the current state
    sm = do_exit!(sm, c, lca)
    if isnothing(sm)
        error("Error in state machine definition. `nothing` returned instead of an updated state machine.")
    end

    # Call action function
    action()

    # Perform entry transitions to the target state
    sm = do_entry!(sm, lca, target)
    if isnothing(sm)
        error("Error in state machine definition. `nothing` returned instead of an updated state machine.")
    end

    # Set the source to current for initialize transitions
    sm = source!(sm, target)
    if isnothing(sm)
        error("Error in state machine definition. `nothing` returned instead of an updated state machine.")
    end

    sm = on_initialize!(sm, target)
    if isnothing(sm)
        error("Error in state machine definition. `nothing` returned instead of an updated state machine.")
    end

    sm = @set sm.context.handled = true

    return sm
end

function find_lca(source::AbstractHsmState, target::AbstractHsmState)
    # Special case for transition to self
    if source === target
        return ancestor(source)
    elseif source === ancestor(target)
        return source
    elseif ancestor(source) === target
        return target
    end
    find_lca_recursive(source, target)
end

# Is 'a' a child of 'b'
function isancestorof(a, b)
    if a === Root() || b === Root()
        return false
    elseif a === b
        return true
    end
    isancestorof(ancestor(a), b)
end

function find_lca_recursive(source, target)
    if source === Root() || target === Root()
        return Root()
    end

    if source === target
        return source
    end

    if isancestorof(source, target)
        return find_lca_recursive(ancestor(source), target)
    else
        return find_lca_recursive(source, ancestor(target))
    end
end

function find_lca_loop(source, target)
    while source !== Root()
        t = target
        while t !== Root()
            if t === source
                return t
            end
            t = ancestor(t)
        end
        source = ancestor(source)
    end
    return Root()
end
