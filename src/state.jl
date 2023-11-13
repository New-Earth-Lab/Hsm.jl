struct Root <: AbstractHsmState end
ancestor(::Type{<:AbstractHsmState}) = Root
on_initialize!(::AbstractHsmStateMachine, ::Type{<:AbstractHsmState}) = nothing
on_entry!(::AbstractHsmStateMachine, ::Type{<:AbstractHsmState}) = nothing
on_exit!(::AbstractHsmStateMachine, ::Type{<:AbstractHsmState}) = nothing

function do_entry!(sm::AbstractHsmStateMachine, s::Type{<:AbstractHsmState}, t::Type{<:AbstractHsmState})
    if s === t
        return
    end
    do_entry!(sm, s, ancestor(t))
    current!(sm, t)
    on_entry!(sm, t)
    return
end

function do_exit!(sm::AbstractHsmStateMachine, s::Type{<:AbstractHsmState}, t::Type{<:AbstractHsmState})
    if s === t
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

    return EventHandled
end

function find_lca(source::Type{<:AbstractHsmState}, target::Type{<:AbstractHsmState})
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
function isancestorof(@nospecialize(a), @nospecialize(b))
    if a === Root || b === Root
        return false
    elseif a === b
        return true
    end
    isancestorof(ancestor(a), b)
end

function find_lca_recursive(@nospecialize(source), @nospecialize(target))
    if source === Root || target === Root
        return Root
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

function find_lca_loop(@nospecialize(source), @nospecialize(target))
    while source !== Root
        t = target
        while t !== Root
            if t === source
                return t
            end
            t = ancestor(t)
        end
        source = ancestor(source)
    end
    return Root
end

function find_lca_loop2(@nospecialize(source), @nospecialize(target))
    while source !== Root
        if isancestorof(target, source)
            while target !== source
                target = ancestor(target)
            end
            return target
        end
        source = ancestor(source)
    end
    return Root
end
