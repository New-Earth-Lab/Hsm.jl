struct HsmStateTransitionError <: Exception
    msg::String
end

abstract type AbstractHsmState end
abstract type AbstractHsmStateMachine end