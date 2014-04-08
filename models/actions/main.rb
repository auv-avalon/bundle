require 'models/profiles/main'

class Main < Roby::Actions::Interface

    action_library
     PIPE_SPEED=0.5

     def name
         "Avalon's Action library"
     end
    



    describe("follow-pipe-a-turn-at-e-of-pipe").
	optional_arg('turn_dir', 'the turn direction').
	required_arg('initial_heading', 'the heading for the pipe to follow').
	required_arg('post_heading', 'the heading for the pipe to follow')
    state_machine "follow_pipe_a_turn_at_e_of_pipe" do
       follow = state pipeline_def(:heading => initial_heading, 	:speed_x => PIPE_SPEED, :turn_dir=> turn_dir)
       stop = state pipeline_def(:heading => initial_heading, 	:speed_x => -PIPE_SPEED/2.0, :turn_dir=> turn_dir, :timeout => 5)
       turn= state pipeline_def(:heading => post_heading, 	:speed_x => 0, 		 :turn_dir=> turn_dir, :timeout => 20)
       start(follow)
       transition(follow.weak_signal_event,stop)
       transition(stop.success_event,turn)
       forward turn.follow_pipe_event, success_event
       forward turn.success_event, success_event
    end

    describe("lawn_mover_over_pipe")
    state_machine "lawn_mover_over_pipe" do
        s1 = state target_move_def(:finish_when_reached => true, :heading => Math::PI/2.0, :depth => -4, :delta_timeout => 10, :x => -5, :y => 0)
        s2 = state target_move_def(:finish_when_reached => true, :heading => Math::PI/2.0, :depth => -4, :delta_timeout => 10, :x => -5, :y => 4)
        s3 = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => -4, :delta_timeout => 5)
        s4 = state target_move_def(:finish_when_reached => true, :heading => 0, :depth => -4, :delta_timeout => 10, :x => 0, :y => 4)
        s5 = state simple_move_def(:finish_when_reached => true, :heading => -Math::PI/2.0, :depth => -4, :delta_timeout => 5)
        s6 = state target_move_def(:finish_when_reached => true, :heading => Math::PI/2.0, :depth => -4, :delta_timeout => 10, :x => 0, :y => 0)
        s7 = state simple_move_def(:finish_when_reached => true, :heading => 0, :depth => -4, :delta_timeout => 5)
        s8 = state target_move_def(:finish_when_reached => true, :heading => 0, :depth => -4, :delta_timeout => 10, :x => 5, :y => 0)
        s9 = state simple_move_def(:finish_when_reached => true, :heading => Math::PI/2.0, :depth => -4, :delta_timeout => 5)
        s10 =state target_move_def(:finish_when_reached => true, :heading => Math::PI/2.0, :depth => -4, :delta_timeout => 10, :x => 5, :y => 4)

        start(s1)
        transition(s1.success_event,s2)
        transition(s2.success_event,s3)
        transition(s3.success_event,s4)
        transition(s4.success_event,s5)
        transition(s5.success_event,s6)
        transition(s6.success_event,s7)
        transition(s7.success_event,s8)
        transition(s8.success_event,s9)
        transition(s9.success_event,s10)
        forward s10.success_event,success_event
    end
    
   

    describe("Ping and Pong (once) on an pipeline")
    state_machine "pipe_ping_pong" do
        pipeline = state follow_pipe_a_turn_at_e_of_pipe(:initial_heading => 0,:post_heading => 3.13)
        pipeline2 = state follow_pipe_a_turn_at_e_of_pipe(:initial_heading => 3.13, :post_heading =>3.13)
        start(pipeline)
        transition(pipeline.success_event,pipeline2)
        forward pipeline2.success_event, success_event
    end
    
    describe("Ping and Pong inf on an pipeline")
    state_machine "loop_pipe_ping_pong" do
        s1 = state pipe_ping_pong
        s2 = state pipe_ping_pong
        start(s1)
        transition(s1.success_event,s2)
        transition(s2.success_event,s1)
    end

    
    describe("Find_pipe_with_localization")
    state_machine "find_pipe_with_localization" do
        find_pipe_back = state lawn_mover_over_pipe
        pipe_detector = state pipeline_detector_def
        pipe_detector.depends_on find_pipe_back, :role => "detector"
        start(pipe_detector)
        forward pipe_detector.align_auv_event, success_event
        forward pipe_detector,find_pipe_back.success_event,failed_event
    end
    
    describe("to_window")
    state_machine "to_window" do
        s1 = state target_move_def(:finish_when_reached => true, :heading => 0, :depth => -5.5, :delta_timeout => 10, :x => 7, :y => 6.5)
        s2 = state target_move_def(:finish_when_reached => true, :heading => 0, :depth => -5.5, :delta_timeout => 120, :x => 8, :y => 6.5)
        start(s1)

        transition s1.success_event, s2 
        forward s2.success_event, success_event
    end



    describe("ping-pong-pipe-wall-back-to-pipe")
    state_machine "ping_pong_pipe_wall_back_to_pipe" do
        ping_pong = state pipe_ping_pong
        wall = state wall_right_def(:max_corners => 2) 

        #now we are on the lower-left-corner (opposide from window)
         
        #parralel blindly drive and waiting for detection of pipe
        #align_to_pipe = state simple_move_def(:heading => 0.65, :speed_x => 0 ,:depth=>-4, :timeout=> 20)
        #find_pipe_back = state simple_move_def(:heading => 0.65, :speed_x => 0.3 ,:depth=>-4, :timeout=> 80)
        #pipe_detector = state pipeline_detector_def
        #pipe_detector.depends_on find_pipe_back, :role => "detector"
        find_pipe_back = state find_pipe_with_localization 
        start(ping_pong)
        transition(ping_pong.success_event, wall)
        transition(wall.success_event,find_pipe_back)
#        transition(wall.success_event,align_to_pipe)
#        transition(align_to_pipe.success_event,pipe_detector)

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

    describe("Ping and Pong (once) on an pipeline")
    state_machine "rocking" do
        s1 = state ping_pong_pipe_wall_back_to_pipe
        s2 = state ping_pong_pipe_wall_back_to_pipe
        start(s1)
        transition(s1.success_event,s2)
        transition(s2.success_event,s1)
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
