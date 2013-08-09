require "models/profiles/avalon_simulation/main"

class Main < Roby::Actions::Interface
    use_profile Avalon::Profiles::Simulation

#    describe("pipeline_follower_action").
#        required_arg("heading").
#        returns(PipelineDetector)
#    def pipeline_follower(arguments)
##        pipeline_def.use(
#        #PipelineDetector.with_arguments(:heading => heading)
#        PipelineDetector.with_arguments(:heading => arguments[:heading])
#    end

    describe("test")
    state_machine "test" do
        pipeline = state pipeline_def(:heading => 0)
        #pipeline = state pipeline_def(:heading => 0).use(PipelineDetector(:heading
        pipeline2 = state pipeline_def(:heading => 3.13)
        start(pipeline)
        transition(pipeline.end_of_pipe_event,pipeline2)
        forward pipeline2.end_of_pipe_event, success_event
    end
end
