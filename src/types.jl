abstract type AbstractHsmState end
abstract type AbstractHsmStateMachine end
abstract type AbstractEventReturn end
struct EventHandled <: AbstractEventReturn end
struct EventNotHandled <: AbstractEventReturn end