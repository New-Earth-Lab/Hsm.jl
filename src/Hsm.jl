module Hsm
using FunctionWrappers
using Setfield

include("types.jl")
include("machine.jl")
include("state.jl")
include("build-sm.jl")

# export AbstractHsmState, AbstractHsmMachine
# export on_initialize!, on_entry!, on_exit!, on_event!
# export transition!, dispatch!
# export StateMachineContext

end # module Hsm
