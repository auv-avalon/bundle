require 'models/actions/core'

class Main




    describe("ping-pong-pipe-wall-back-to-pipe")
    state_machine "ping_pong_pipe_wall_back_to_pipe" do
        ping_pong = state pipe_ping_pong
        wall = state wall_right_def(:max_corners => 2) 

        
        find_pipe_back = state find_pipe_with_localization 
        find_pipe_back = state find_pipe_with_localization 
        start(ping_pong)
        transition(ping_pong.success_event, wall)
        transition(wall.success_event,find_pipe_back)

	#timeout occured
        forward find_pipe_back.failed_event, failed_event
        #we found back the pipeline
        forward find_pipe_back.success_event, success_event ##todo maybe use align_auv insted?

     end
    
    describe("ping-pong-pipe-wall-back-to-pipe")
    state_machine "ping_pong_pipe_wall_back_to_pipe_with_window" do
        ping_pong = state pipe_ping_pong
        wall = state wall_right_def(:max_corners => 2) 
        window = state to_window

        find_pipe_back = state find_pipe_with_localization 
        start(ping_pong)
        transition(ping_pong.success_event, wall)
        transition(wall.success_event,window)
        transition(window.success_event,find_pipe_back)

	#timeout occured
        forward find_pipe_back.failed_event, failed_event
        #we found back the pipeline
        forward find_pipe_back.success_event, success_event ##todo maybe use align_auv insted?

     end

    describe("Do a pipeline ping-pong, pass two corners with wall servoing and goind back to pipe")
    state_machine "rocking" do
        s1 = state ping_pong_pipe_wall_back_to_pipe
        s2 = state ping_pong_pipe_wall_back_to_pipe
        start(s1)
        transition(s1.success_event,s2)
        transition(s2.success_event,s1)
    end

    describe("Do the minimal demo for the halleneroeffnung, means pipeline, then do wall-following and back to pipe-origin")
    state_machine "minimal_demo" do
        use_fault_response_table HBridgeFailure::Retry 
        init = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => -4, :delta_timeout => 60, :timeout => 60)
        s1 = state find_pipe_with_localization 
#        detector = state pipeline_detector_def
#        detector.depends_on s1
    
        #Follow pipeline to right end
        pipeline1 = state pipeline_def(:depth=> -5.5, :heading => 0, :speed_x => 0.5, :turn_dir=> 1)
        align_to_wall = state simple_move_def(:finish_when_reached => true, :heading => 3.14, :depth => -5, :delta_timeout => 5, :timeout => 30)
        #Doing wall-servoing 
        wall1 = state wall_right_def(:max_corners => 1) 
        wall2 = state wall_right_def(:timeout => 10) 

        transition(init.success_event, s1)
        transition(s1.success_event, pipeline1)
        #transition(pipeline1.success_event, align_to_wall)
        transition(pipeline1.end_of_pipe_event, align_to_wall)
        transition(align_to_wall.success_event, wall1)
        
        transition(wall1.success_event, wall2)
        transition(wall2.success_event, s1)
    end
    
    describe("Do the minimal demo for the halleneroeffnung, menas pipeline, then do wall-following and back to pipe-origin")
    state_machine "minimal_demo_blind" do
        init = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => -4, :delta_timeout => 60, :timeout => 60)
        s1 = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => -4, :delta_timeout => 60, :timeout => 60) 
        detector = state pipeline_detector_def
        detector.depends_on s1
    
        start(init)
        #Follow pipeline to right end
        pipeline1 = state follow_pipe_a_turn_at_e_of_pipe(:initial_heading => 0, :post_heading => 3.14, :turn_dir => 1)
        #Doing wall-servoing 
        wall1 = state wall_right_def(:max_corners => 1) 
        wall2 = state wall_right_def(:timeout => 10) 

        transition(init.success_event, detector)
        transition(detector.align_auv_event, pipeline1)
        transition(pipeline1.success_event, wall1)
        transition(wall1.success_event, wall2)
        transition(wall2.success_event, detector)
    end
    
   
    #TODO This could be extended by adding additional mocups
    describe("do a full Demo, with visiting the window after wall-servoing")
    state_machine "full_demo" do
        s1 = state target_move_def(:finish_when_reached => true, :heading => 1, :depth => -5.5, :delta_timeout => 10, :x => -6.5, :y => -1) #trajectory_move_def(:target => "pipeline") 
        detector = state pipeline_detector_def
        detector.depends_on s1
    
        #Follow pipeline to right end
        pipeline1 = state follow_pipe_a_turn_at_e_of_pipe(:initial_heading => 0, :post_heading => 3.14, :turn_dir => 1)
        #Doing wall-servoing 
        wall1 = state wall_right_def(:max_corners => 1) 
        wall2 = state wall_right_def(:timeout => 10) 
        #window
        window = state to_window 
        
        start(detector)
        transition(detector.align_auv_event, pipeline1)
        transition(pipeline1.success_event, wall1)
        transition(wall1.success_event, wall2)
        transition(wall2.success_event, window)
        transition(window.success_event, detector)
    end
    
#    describe("Workaround1")
#    state_machine "wa1" do 
#        s1 = state drive_to_pipeline
#        detector = state pipeline_detector_def
#        detector.depends_on s1
#        start detector
#        forward detector.align_auv_event, success_event 
#    end

    describe("Find pipeline localization based, and to a infinite pipe-ping-pong on it")
    state_machine "start_pipe_loopings" do 
        
        detector = state trajectory_move_def(:target => "pipeline") 
        #turn = state simple_move_def(:heading => -Math::PI, :timeout => 5) 

        pipeline1 = state pipe_ping_pong(:post_heading => 0)
        pipeline2 = state pipe_ping_pong(:post_heading => 0)
        
        start detector

        transition(detector.success_event, pipeline1)
#        transition(turn.success_event, pipeline1)
        transition(pipeline1.success_event, pipeline2)
        transition(pipeline2.success_event, pipeline1)
    end
    
end

module FailureHandling
    class Operator < Roby::Coordination::FaultResponseTable
        describe("waits for the operator to do something").
            returns(WaitForOperator)
        def wait_for_operator
            WaitForOperator.new
        end
        # This is a catch-all that makes the system stop doing anything until an
        # operator comes
        on_fault Roby::LocalizedError do
            wait_for_operator!
        end
    end
end

module HBridgeFailure
    class Retry
        on_fault with_origin(HBrigde.timeout_event) do
            retry
        end


    end
end
