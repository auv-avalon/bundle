require "models/profiles/avalon_simulation/main"

class Main < Roby::Actions::Interface
    use_profile Avalon::Profiles::Simulation

    

    describe("test")
    state_machine "test" do
        pipeline = state pipeline_def(:heading => 0)
        pipeline2 = state pipeline_def(:heading => 3.13)
        start(pipeline)
        transition(pipeline.end_of_pipe_event,pipeline2)
        forward pipeline2.end_of_pipe_event, success_event
    end
end
