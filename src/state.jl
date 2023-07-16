parent(::Type{<:AbstractHsmState}) = AbstractHsmState

function on_initialize!(sm::AbstractHsmStateMachine, ::Type{<:AbstractHsmState})
end

function on_entry!(sm::AbstractHsmStateMachine, state::Type{<:AbstractHsmState})
    # @debug "on_entry $(typeof(sm))::$(state)"
    return
end

function on_exit!(sm::AbstractHsmStateMachine, state::Type{<:AbstractHsmState})
    # @debug "on_exit $(typeof(sm))::$(state)"
end

function enter(sm::AbstractHsmStateMachine, @nospecialize(source), @nospecialize(target))
    if source != target
        enter(sm, source, parent(target))
    else
        return
    end
    on_entry!(sm, target)
    return
end

function exit(sm::AbstractHsmStateMachine, @nospecialize(source::Type{<:AbstractHsmState}), @nospecialize(target::Type{<:AbstractHsmState}))
    if source != target
        on_exit!(sm, source)
        exit(sm, parent(source), target)
    end
end

function transition!(sm::AbstractHsmStateMachine, target::Type{<:AbstractHsmState}, action::Function=() -> nothing)
    # @debug "transition! $(typeof(sm))::$(target)"

    # exit from current state to source state
    # s = source(sm)
    # iter = current(sm)
    # while iter != s
    #     on_exit!(sm, iter)
    #     iter = parent(iter)
    # end
    exit(sm, current(sm), source(sm))

    # Call action function
    action()

    # exit from source state to lca
    # lca = find_lca(iter, target)
    lca = find_lca(source(sm), target)

    # while iter != lca
    #     on_exit!(sm, iter)
    #     iter = parent(iter)
    # end
    exit(sm, source(sm), lca)

    # Call entry functions from lca down to target
    enter(sm, lca, target)

    #=
    Iterative version.

    path = Type{<:AbstractHsmState}[]
    iter = target
    while iter != lca
        push!(path, iter)
        iter = parent(iter)
    end

    # Call the state entry functions on the path in reverse
    for i in length(path):-1:1
        on_entry!(sm, path[i])
    end
    =#

    # Update the current position to the target
    current!(sm, target)

    # Set the source to current for initialize transitions
    source!(sm, target)

    on_initialize!(sm, target)

    return
end

function find_lca(@nospecialize(source), @nospecialize(target))::Type{<:AbstractHsmState}
    # Optimization for simple cases
    if source == target
        return parent(source)
    elseif source == parent(target)
        return source
    elseif parent(source) == target
        return target
    elseif parent(source) == parent(target)
        return parent(source)
    else
        # Nested cases
        return find_lca_loop(source, target)
    end
end

function find_lca_loop(@nospecialize(source), @nospecialize(target))::Type{<:AbstractHsmState}
    depth_source = 0
    depth_target = 0

    # Check if target is a substate of source
    t = target
    while t != AbstractHsmState
        if t == source
            return t
        end
        t = parent(t)
        depth_target += 1
    end

    # Check if source is a substate of target
    s = source
    while s != AbstractHsmState
        if s == target
            return s
        end
        s = parent(s)
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
        larger = parent(larger)
        delta -= 1
    end

    while larger != smaller
        larger = parent(larger)
        smaller = parent(smaller)
    end
    return larger
end


