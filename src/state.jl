struct Top <: AbstractHsmState end
ancestor(::Type{<:AbstractHsmState}) = Top
on_initialize!(::AbstractHsmStateMachine, ::Type{<:AbstractHsmState}) = nothing
on_entry!(::AbstractHsmStateMachine, ::Type{<:AbstractHsmState}) = nothing
on_exit!(::AbstractHsmStateMachine, ::Type{<:AbstractHsmState}) = nothing

# This appears to be correct
function do_entry(sm::AbstractHsmStateMachine, @nospecialize(s), @nospecialize(t))
    if s != t
        do_entry(sm, s, ancestor(t))
    else
        return
    end
    current!(sm, t)  
    on_entry!(sm, t)
    return
end

function do_exit(sm::AbstractHsmStateMachine, @nospecialize(s), @nospecialize(t))
    if s != t
        on_exit!(sm, s)
        a = current!(sm, ancestor(s))
        do_exit(sm, a, t)
    end
    return
end

function transition!(sm::AbstractHsmStateMachine, target, action::Function=() -> nothing)
    # @debug "transition! $(typeof(sm))::$(target)"

    s = source(sm)
    c = current(sm)

    # In the case of source == target, exit the source state too
    if s == target
        s = ancestor(s)
    end

    # Perform exit transitions to the source state
    do_exit(sm, c, s)

    # Call action function
    action()

    lca = find_lca(s, target, Top)

    post(sm, s, target, lca)

    return
end

function post(sm::AbstractHsmStateMachine, source, target, lca)
    # exit from source state to lca
    do_exit(sm, source, lca)

    # Call entry functions from lca down to target
    do_entry(sm, lca, target)

    # Update the current position to the target
    current!(sm, target)

    # Set the source to current for initialize transitions
    source!(sm, target)

    on_initialize!(sm, target)
    return
end

function find_lca(source, target, root)
    # Optimization for simple cases
    if source == target
        return source
    elseif source == ancestor(target)
        return source
    elseif ancestor(source) == target
        return target
    elseif ancestor(source) == ancestor(target)
        return ancestor(source)
    else
        # Nested cases
        return find_lca_fast(source, target, root)
    end
end

function find_lca_fast(source, target, root)
    depth_source = 0
    depth_target = 0

    # Check if target is a substate of source
    t = target
    while t != root
        if t == source
            return t
        end
        t = ancestor(t)
        depth_target += 1
    end

    # Check if source is a substate of target
    s = source
    while s != root
        if s == target
            return s
        end
        s = ancestor(s)
        depth_source += 1
    end

    # If not found use the measured depth to calculate the common ancestor
    if depth_source > depth_target
        larger = source
        smaller = target
        delta = depth_source - depth_target
    else
        larger = target
        smaller = source
        delta = depth_target - depth_source
    end

    # Bring the states to an equal level
    while delta != 0
        larger = ancestor(larger)
        delta -= 1
    end

    while larger != smaller
        larger = ancestor(larger)
        smaller = ancestor(smaller)
    end
    return larger
end

function find_lca_loop(source, target, root)
    s = source
    while s != root
        t = target
        while t != root
            if t == s
                return t
            end
            t = ancestor(t)
        end
        s = ancestor(s)
    end
    return Top
end