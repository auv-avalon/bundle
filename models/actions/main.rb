require 'models/profiles/main'

class Main < Roby::Actions::Interface
     PIPE_SPEED=0.4
    
#    describe("Executes the given task and wait for he given signal, is the signal occurs wait for an period and emif success afterwards").
#        required_arg("task", "the task to be executed").
#        required_arg("signal", "the signal to wait for").
#        optional_arg("duration", "duration to wait after the event")#.
#        #returns(task)
#    method(:delayed_success) do
#
#       t = self.task
#       script do
#         wait_any t.start_event
#         wait t.call(self.signal)
#         timeout_start(self.duration)
#         emit :success
#       end
#  
#       
#    end
#    
#    describe("Ping and Pong (once) on an pipeline")
#    state_machine "testi" do
#        pipeline = state delayed_success(:task => pipeline_def(:heading => 0), :signal=>"end_of_pipe_event", :duration => 5)
#        #pipeline = state pipeline_def(:heading => 0).use(PipelineDetector(:heading
#        start(pipeline)
#        forward pipeline.end_of_pipe_event, success_event
#    end
#    
    describe("testbed demo")
    state_machine "testbed" do
        last = nil
        (0..50).each do |i|
            pipeline = state pipeline_def(:heading => 0, :speed_x => PIPE_SPEED, :turn_dir=> 1) #Pipe left
            pipeline2 = state pipeline_def(:heading => 0, :speed_x => PIPE_SPEED, :timeout => 3) #Hover on pipe-end
            pipeline3 = state pipeline_def(:heading => 0, :speed_x => -PIPE_SPEED, :timeout => 5) #reverse
            pipeline4 = state pipeline_def(:heading => 3.13, :speed_x => PIPE_SPEED, :turn_dir=>1) #turn and until end
            pipeline5 = state pipeline_def(:heading => 3.13, :speed_x => PIPE_SPEED, :timeout => 3) #hover on other end
            pipeline6 = state pipeline_def(:heading => 3.13, :speed_x => -PIPE_SPEED, :timeout => 5) #short reverse
            
            if(i==0)
                start(pipeline) 
            else
                transition(last.success_event,pipeline)
            end
            last = pipeline6
            
            transition(pipeline.end_of_pipe_event,pipeline2)
            transition(pipeline2.success_event,pipeline3)
            transition(pipeline3.success_event,pipeline4)
            transition(pipeline4.end_of_pipe_event,pipeline5)
            transition(pipeline5.success_event,pipeline6)
            #transition(pipeline6.success_event,pipeline)
            if(i==49)
                forward pipeline6.success_event, success_event
            end
        end
    end
    
    
    
    describe("Ping and Pong (once) on an pipeline")
    state_machine "pipe_ping_pong" do
        pipeline = state pipeline_def(:heading => 0)
        #pipeline = state pipeline_def(:heading => 0).use(PipelineDetector(:heading
        pipeline2 = state pipeline_def(:heading => 3.13)
        start(pipeline)
        transition(pipeline.end_of_pipe_event,pipeline2)
        forward pipeline2.end_of_pipe_event, success_event
    end
    
    describe("simple_move_tests")
    state_machine "simple" do
        s1 = state simple_move_def(:heading=>0, :depth=>-5,:timeout =>15)
        s2 = state simple_move_def(:heading=>0, :speed_x=>3 ,:depth=>-5, :timeout=> 15)
        s3 = state simple_move_def(:heading => Math::PI*0.5, :speed_x => 3 ,:depth=>-5, :timeout=> 15)
        s4 = state simple_move_def(:heading => Math::PI*1.0, :speed_x => 3 ,:depth=>-5, :timeout=> 15)
        s5 = state simple_move_def(:heading => Math::PI*1.5, :speed_x => 3 ,:depth=>-5, :timeout=> 15)
        s6 = state simple_move_def(:heading => 0, :speed_x => 0 ,:depth=>-5, :timeout=> 15)
        start(s1)
        transition(s1.success_event,s2)
        transition(s2.success_event,s3)
        transition(s3.success_event,s4)
        transition(s4.success_event,s5)
        transition(s5.success_event,s6)
        forward s6.success_event, success_event
    end

end
