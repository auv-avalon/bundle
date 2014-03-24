require 'models/profiles/main'

class Main < Roby::Actions::Interface

    action_library
     PIPE_SPEED=0.6

     def name
         "Avalon's Action library"
     end
    
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


#    #TODO noch nciht möglich da remove_dependency nicht implementiert ist
#    describe("Test action")
#    action_script 'test_method' do
#        detector = task pipeline_detector_def(Hash.new)
#        drive    = task drive_simple_def
#        pipe     = task pipeline_def(:heading => 3.13, :speed_x => PIPE_SPEED, :turn_dir=>2)
#
#        binding.pry
#        start detector
#        start drive
#        wait detector.end_of_pipe_event
#        remove_dependency pipeline
#        start pipe
#
#    end


#    #todo z.Z. nicht möglich da zugriff auf children nicht möglich ist
#    describe("Test action").
#        returns(::Pipeline::Detector)
#    def test_method(*arguments)
#        pd = pipeline_detector_def(Hash.new)
#        ds = pd.depends_on(drive_simple_def, :role => 'ds') 
#        
#        pipe = pd.depends_on(pipeline_def(:heading => 3.13, :speed_x => PIPE_SPEED, :turn_dir=>2), :role => 'follower')
#    
#        pipe.should_start_after ds.stop_event
#
#        pd.script do
#           wait_any end_of_pipe_event
#
#           execute do
#               remove_dependency(ds_child)
#               #depends_on(pipeline_def(:heading => 3.13, :speed_x => PIPE_SPEED, :turn_dir=>2), :role => 'follower')
#           end
#           wait_any follower_child.end_of_pipe_event
#           success_event.emit
#        end
#        pd 
#    end

    describe("testbed demo")
    state_machine "testbed" do
            pipeline = state pipeline_def(:heading => 0, :speed_x => PIPE_SPEED, :turn_dir=> 1) #Pipe left
            pipeline2 = state pipeline_def(:heading => 0, :speed_x => PIPE_SPEED, :timeout => 3) #Hover on pipe-end
            pipeline3 = state pipeline_def(:heading => 0, :speed_x => -PIPE_SPEED, :timeout => 5) #reverse
            pipeline4 = state pipeline_def(:heading => 3.13, :speed_x => PIPE_SPEED, :turn_dir=>2) #turn and until end
            pipeline5 = state pipeline_def(:heading => 3.13, :speed_x => PIPE_SPEED, :timeout => 3) #hover on other end
            pipeline6 = state pipeline_def(:heading => 3.13, :speed_x => -PIPE_SPEED, :timeout => 5) #short reverse
                
            start(pipeline) 
            transition(pipeline.end_of_pipe_event,pipeline2)
            transition(pipeline2.success_event,pipeline3)
            transition(pipeline3.success_event,pipeline4)
            transition(pipeline4.end_of_pipe_event,pipeline5)
            transition(pipeline5.success_event,pipeline6)
            transition(pipeline6.success_event,pipeline)
    end
    
    describe("Matthias-testing")
    state_machine "test2" do
        pipeline = state pipeline_def(:heading => 0, :speed_x => 0, :timeout => 10)
        away_from_pipe = state simple_move_def(:heading => Math::PI*0.5, :speed_x => 3 ,:depth=>-5, :timeout=> 15)
        align_to_pipe = state simple_move_def(:heading => Math::PI*-0.5, :speed_x => 0 ,:depth=>-5, :timeout=> 5)
        pipe_detector = state pipeline_detector_def
        pure_pipe_detector = state pipeline_detector_def
        find_pipe_mover = state simple_move_def(:heading => Math::PI*-0.5, :speed_x => 3 ,:depth=>-5, :timeout=> 30)
        pipe_detector.depends_on find_pipe_mover, :role => "detector"
        follow_pipe = state pipeline_def(:heading => 0, :speed_x => 2)

        start(pipeline)
        transition(pipeline.success_event,away_from_pipe)
        transition(away_from_pipe.success_event,align_to_pipe)
        transition(align_to_pipe.success_event,pipe_detector)
        transition(pipe_detector.align_auv_event,follow_pipe)
        
        #forward pipe_detector.success_event, failed_event
        #transition(pipe_detector.align_auv_event,follow_pipe)
        #forward follow_pipe.end_of_pipe_event, success_event
    end



    describe("Matthias-testing")
    state_machine "pipe_and_wall" do
            pipeline = state pipeline_def(:heading => 0, :speed_x => PIPE_SPEED, :turn_dir=> 1) #Pipe left
            #move1 = state simple_move_def(:heading=>3.13, :speed_x=>0.0 ,:depth=>-5, :timeout=> 20)
            pipeline1 = state pipeline_def(:heading => 3.13, :speed_x => PIPE_SPEED, :turn_dir=>2) #turn and until end
            away_from_pipe = state simple_move_def(:heading => 0, :speed_x => 1 ,:depth=>-5, :timeout=> 25)
            align_to_wall = state simple_move_def(:heading => 0.5 * Math::PI, :speed_x => 0 ,:depth=>-5, :timeout=> 5)
            find_pipe_back = state simple_move_def(:heading => Math::PI*-0.2, :speed_x => 2 ,:depth=>-5, :timeout=> 80)
            pipe_detector = state pipeline_detector_def
            pipe_detector.depends_on find_pipe_back, :role => "detector"
            pipe_follower = state pipeline_def
            wall = state wall_right_def(:max_corners => 1) 

                
            start(pipeline) 

            transition(pipeline.end_of_pipe_event,pipeline1)
            #transition(pipeline.end_of_pipe_event,move1)
            #transition(move1.success_event,pipeline1)
            
            transition(pipeline1.end_of_pipe_event,away_from_pipe)
            transition(away_from_pipe.success_event,align_to_wall)
            transition(align_to_wall.success_event,wall)
            transition(wall.success_event,pipe_detector)
            forward pipe_detector.failed_event, failed_event
            forward pipe_detector.check_candidate_event, success_event

    end
    
    describe("looping-pipe-wall")
    state_machine "loop_pipe_wall" do
        state1 = state pipe_and_wall
        state2 = state pipe_and_wall
        start(state1)
        transition(state1.success_event, state2)
        transition(state2.success_event,state1)
    end
    
    
    describe("Ping and Pong (once) on an pipeline")
    state_machine "pipe_ping_pong" do
        pipeline = state pipeline_def(:heading => 0)
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
