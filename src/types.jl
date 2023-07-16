struct HsmStateTransitionError <: Exception
    msg::String
end

abstract type AbstractHsmState end
abstract type AbstractHsmEvent end
abstract type AbstractHsmStateMachine end