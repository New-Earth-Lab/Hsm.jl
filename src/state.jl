struct Root <: AbstractHsmState end
ancestor(::Type{<:AbstractHsmState}) = Root
on_initialize!(::AbstractHsmStateMachine, ::Type{<:AbstractHsmState}) = nothing
on_entry!(::AbstractHsmStateMachine, ::Type{<:AbstractHsmState}) = nothing
on_exit!(::AbstractHsmStateMachine, ::Type{<:AbstractHsmState}) = nothing

function do_entry!(sm::AbstractHsmStateMachine, s::Type{<:AbstractHsmState}, t::Type{<:AbstractHsmState})
    if s == t
        return
    end
    do_entry!(sm, s, ancestor(t))
    current!(sm, t)
    on_entry!(sm, t)
    return
end

function do_exit!(sm::AbstractHsmStateMachine, s::Type{<:AbstractHsmState}, t::Type{<:AbstractHsmState})
    if s == t
        return
    end
    on_exit!(sm, s)
    a = current!(sm, ancestor(s))
    do_exit!(sm, a, t)
end

function transition!(sm::AbstractHsmStateMachine, target::Type{<:AbstractHsmState})
    transition!(Returns(nothing), sm, target)
end

function transition!(action::Function, sm::AbstractHsmStateMachine, target::Type{<:AbstractHsmState})
    c = current(sm)
    s = source(sm)
    lca = find_lca(s, target)

    # Perform exit transitions from the current state
    do_exit!(sm, c, lca)

    # Call action function
    action()

    # Perform entry transitions to the target state
    do_entry!(sm, lca, target)

    # Set the source to current for initialize transitions
    source!(sm, target)

    on_initialize!(sm, target)

    return true
end

function find_lca(source::Type{<:AbstractHsmState}, target::Type{<:AbstractHsmState})
    # Special case for transition to self
    if source == target
        return ancestor(source)
        # Optimization for simple cases
    elseif source == ancestor(target)
        return source
    elseif ancestor(source) == target
        return target
    elseif ancestor(source) == ancestor(target)
        return ancestor(source)
    else
        # Nested cases
        return find_lca_fast(source, target)
    end
end

function find_lca_loop(source::Type{<:AbstractHsmState}, target::Type{<:AbstractHsmState})
    s = source
    while s != Root
        t = target
        while t != Root
            if t == s
                return t
            end
            t = ancestor(t)
        end
        s = ancestor(s)
    end
    return Root
end

function find_lca_fast(source::Type{<:AbstractHsmState}, target::Type{<:AbstractHsmState})
    depth_source = 0
    depth_target = 0

    # Check if target is a substate of source
    t = target
    while t != Root
        if t == source
            return t
        end
        t = ancestor(t)
        depth_target += 1
    end

    # Check if source is a substate of target
    s = source
    while s != Root
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
