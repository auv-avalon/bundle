require 'models/profiles/main'

class Main < Roby::Actions::Interface
    
    
    describe("Ping and Pong (once) on an pipeline")
    state_machine "pipe_ping_pong" do
        pipeline = state pipeline_def(:heading => 0)
        #pipeline = state pipeline_def(:heading => 0).use(PipelineDetector(:heading
        pipeline2 = state pipeline_def(:heading => 3.13)
        start(pipeline)
        transition(pipeline.end_of_pipe_event,pipeline2)
        forward pipeline2.end_of_pipe_event, success_event
    end

end
