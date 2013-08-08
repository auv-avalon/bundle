require "models/profiles/avalon_simulation/main"

class Main < Roby::Actions::Interface
    use_profile Avalon::Profiles::Simulation

    describe("foo").
        required_arg(...)
    def pipeline_follower(arguments)
        pipeline_def.use(
        PipelineDetector.use(:heading => heading)
    end

    describe("test")
    state_machine "test" do
        pipeline = state pipeline_def(:heading => 0)
        #pipeline = state pipeline_def(:heading => 0).use(PipelineDetector(:heading
        pipeline2 = state pipeline_def(:heading => 3.13)
        start(pipeline)
        transition(pipeline.controller_child.end_of_pipe_event,pipeline2)
        forward pipeline2.end_of_pipe_event, success_event
    end
end
