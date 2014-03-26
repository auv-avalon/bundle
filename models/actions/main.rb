require 'models/profiles/main'

class Main < Roby::Actions::Interface

    action_library
     PIPE_SPEED=0.6

     def name
         "Avalon's Action library"
     end
    


    describe("follow-pipe-and-turn-at-end-of-pipe").
	oprional_arg('turn_dir', 'the turn direction').
	required_arg('initial-heading', 'the heading for the pipe to follow').
	required_arg('post-heading', 'the heading for the pipe to follow')
    state_machine "follow-pipe-and-turn-at-end-of-pipe" do
       follow = state pipeline_def(:heading => initial-heading, 	:speed_x => -PIPE_SPEED, :turn_dir=> turn_dir)
       break = state pipeline_def(:heading => initial-heading, 	:speed_x => -PIPE_SPEED, :turn_dir=> turn_dir, :timeout => 10)
       turn= state pipeline_def(:heading => post-heading, 	:speed_x => 0, 		 :turn_dir=> turn_dir)
       start(follow)
       transition(follow.weak_signal_event,break)
       transition(break.success_event,turn)
       forward turn.follow_pipe_event, success_event
    end

    
    
    
    describe("Ping and Pong (once) on an pipeline")
    state_machine "pipe_ping_pong" do
        pipeline = state follow-pipe-and-turn-at-end-of-pipe(:initial_heading => 0,:post_heading => 3.13)
        pipeline2 = state follow-pipe-and-turn-at-end-of-pipe(:initial_heading => 3.13, :post_heading =>0)
        start(pipeline)
        transition(pipeline.success_event,pipeline2)
        forward pipeline2.success_event, success_event
    end

    describe("ping-pong-pipe-wall-back-to-pipe")
    state_machine "ping-pong-pipe-wall-back-to-pipe" do
        ping_pong = state pipe_ping_pong
        wall = state wall_right_def(:max_corners => 2) 

        #now we are on the lower-left-corner (opposide from window)
         
        #parralel blindly drive and waiting for detection of pipe
        find_pipe_back = state simple_move_def(:heading => Math::PI*-0.2, :speed_x => 2 ,:depth=>-5, :timeout=> 80)
        pipe_detector = state pipeline_detector_def
        pipe_detector.depends_on find_pipe_back, :role => "detector"

        start(ping_pong)
        transition(ping_pong.success_event, wall)
        transition(wall.success_event,pipe_detector)

	#timeout occured
        forward pipe_detector.failed_event, failed_event
        #we found back the pipeline
        forward pipe_detector.check_candidate_event, success_event ##todo maybe use align_auv insted?

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
