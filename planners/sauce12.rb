class MainPlanner < Roby::Planning::Planner

    PIPELINE_SEARCH_SPEED = 0.50
    PIPELINE_SEARCH_Z = -2.7
    PIPELINE_SEARCH_YAW = Math::PI / 2.0
    PIPELINE_PREFERED_YAW = Math::PI ### MATH::PI ==> turn left;    0 ==> turn right
#    PIPELINE_STABILIZE_YAW = Math::PI / 2.0
    PIPELINE_SEARCH_TIMEOUT = 90
    PIPELINE_TURN_TIMEOUT = 50
    PIPELINE_MISSION_TIMEOUT = 360
    PIPELINE_TURNS = 1

    WALL_SERVOING_Z = -1.1
    WALL_SERVOING_TIMEOUT = 5 * 60
    WALL_ALIGNMENT_ANGLE = Math::PI/2.0
    
    GOTO_WALL_ALIGNMENT_ANGLE = 0.0
    GOTO_WALL_TIMEOUT = 30

    BUOY_SEARCH_TIMEOUT = 60
    BUOY_MISSION_TIMEOUT = 10 * 60
    BUOY_SEARCH_Z = -2.5
    BUOY_SEARCH_YAW = deg_to_rad(10)
    BUOY_SEARCH_SPEED = 0.3
    BUOY_MODE = :serve_360

    MODEM_WAIT_POS_ANGLE = Math::PI / 2.0
    MODEM_GOTO_SPEED = -0.4
    MODEM_GOTO_DURATION = 2
    MODEM_WAIT_FOR_COMMAND_TIME = 10


    method(:sauce12_pipeline) do
    
        find_follow_turn_pipeline(:yaw => PIPELINE_SEARCH_YAW, 
                                  :z => PIPELINE_SEARCH_Z,
                                  :speed => PIPELINE_SEARCH_SPEED,
                                  :prefered_yaw => PIPELINE_PREFERED_YAW,
                                  :turns => PIPELINE_TURNS,
                                  :search_timeout => PIPELINE_SEARCH_TIMEOUT,
                                  :turn_timeout => PIPELINE_TURN_TIMEOUT,
                                  :mission_timeout => PIPELINE_MISSION_TIMEOUT)
    end
    
   
    method(:sauce12_buoy) do
        sequence = []

        goto_depth = simple_move(:z => BUOY_SEARCH_Z)

        s = survey_buoy(:yaw => BUOY_SEARCH_YAW,
                    :z => BUOY_SEARCH_Z,
                    :speed => BUOY_SEARCH_SPEED,
                    :mode => BUOY_MODE,
                    :search_timeout => BUOY_SEARCH_TIMEOUT,
                    :mission_timeout => BUOY_MISSION_TIMEOUT
                   )   

        task = Planning::BaseTask.new
        sequence << goto_depth << s
        task.add_task_sequence(sequence)
        task
    end

    method(:sauce12_wall) do
        # Z VALUE FOR WALL SERVOING IS CURRENTLY ONLY CONTROLLED BY YAML CONFIGURATION
        survey_wall(:timeout => WALL_SERVOING_TIMEOUT,
                   :corners => 2)
    end

    # For debugging of pipeline turn (ALIGN_AUV with inverted preferred heading). Assumes that we are on the pipe.
    method(:sauce12_align_on_pipe) do
        find_and_follow_pipeline(:yaw => 0, ## we are already on pipe, so yaw is not important
                                 :z => PIPELINE_SEARCH_Z, 
                                 :speed => PIPELINE_SEARCH_SPEED,
                                 :prefered_yaw => 0,
                                 :search_timeout => 10,  # TODO set correct timeout
                                 :mission_timeout => 60,
                                 :do_safe_turn => false)
    end
 
    method(:sauce12_pipeline_and_wall) do
    
        follow_pipe = sauce12_pipeline

        align_for_goto_wall = align_and_move(:z => WALL_SERVOING_Z,
                                             :yaw => GOTO_WALL_ALIGNMENT_ANGLE)

        drive_to_wall = goto_wall(:mission_timeout => GOTO_WALL_TIMEOUT)

        align_to_wall = align_and_move(:z => WALL_SERVOING_Z,
                                       :yaw => WALL_ALIGNMENT_ANGLE)

        wall = sauce12_wall

        surface = simple_move(:z => 0)
        
        run = Planning::MissionRun.new(:timeout => 10.0 * 60.0)
        run.design do
            # Define start and end states
            start(follow_pipe)
            finish(surface)

            # Set up state machine 
	    transition(follow_pipe, :success => align_for_goto_wall, :failed => surface)
            transition(align_for_goto_wall, :success => drive_to_wall, :failed => drive_to_wall)
            transition(drive_to_wall, :success => align_to_wall, :failed => align_to_wall)
            transition(align_to_wall, :success => wall, :failed => surface)
            transition(wall, :success => surface, :failed => surface)         
        end    
    end

    method(:sauce12_pipeline_and_buoy) do
    
        follow_pipe = sauce12_pipeline

        align_for_goto_buoy = align_and_move(:z => BUOY_SEARCH_Z,
                                             :yaw => BUOY_SEARCH_YAW)

        buoy = sauce12_buoy

        surface = simple_move(:z => 0)
        
        run = Planning::MissionRun.new
        run.design do
            # Define start and end states
            start(follow_pipe)
            finish(surface)

            # Set up state machine 
	        transition(follow_pipe, :success => align_for_goto_buoy, :failed => surface)
            transition(align_for_goto_buoy, :success => buoy, :failed => buoy)
            transition(buoy, :success => surface, :failed => surface)         
        end    

    end

    method(:sauce12_buoy_and_wall) do

        buoy = sauce12_buoy

        goto_modem_pos = align_and_move(:speed => MODEM_GOTO_SPEED,
                                        :z => WALL_SERVOING_Z,
                                        :yaw => MODEM_WAIT_POS_ANGLE,
                                        :duration => MODEM_GOTO_DURATION)

        wait_for_modem_command = simple_move(:z => WALL_SERVOING_Z,
                                             :duration => MODEM_WAIT_FOR_COMMAND_TIME)

        align_to_wall = align_and_move(:z => WALL_SERVOING_Z,
                                       :yaw => WALL_ALIGNMENT_ANGLE)

        wall = sauce12_wall

        surface = simple_move(:z => 0)
        
        run = Planning::MissionRun.new
        run.design do
            # Define start and end states
            start(buoy)
            finish(surface)

            # Set up state machine 
	        transition(buoy, :success => goto_modem_pos, :failed => goto_modem_pos)
            transition(goto_modem_pos, :success => wait_for_modem_command, :failed => wait_for_modem_command)
            transition(wait_for_modem_command, :success => align_to_wall, :failed => align_to_wall)  
            transition(align_to_wall, :success => wall, :failed => surface)  
            transition(wall, :success => surface, :failed => surface)       
        end    

    end
    

    method(:sauce12_pipeline_reverse) do
        pos_align = align_and_move(:z => -1.0, :yaw => PIPELINE_SEARCH_YAW)
        surface = simple_move(:z => 0)

        pipeline_reverse = find_and_follow_pipeline(
            :yaw => PIPELINE_SEARCH_YAW,
            :z => PIPELINE_SEARCH_Z,
            :speed => PIPELINE_SEARCH_SPEED,
            :follow_speed => -0.4,
            :prefered_yaw => 0.01,
            :search_timeout => 120,
            :mission_timeout => 6000,
            :do_safe_turn => false,
            :controlled_turn_on_pipe => false)

        pipeline_follow = find_and_follow_pipeline(
            :yaw => proc { State.pipeline_heading },
            :z => PIPELINE_SEARCH_Z,
            :speed => PIPELINE_SEARCH_SPEED - 0.1,
            :follow_speed => 0.4,
            :prefered_yaw => proc { normalize_angle(State.pipeline_heading + 0.1) },
            :search_timeout => 120,
            :mission_timeout => 6000,
            :do_safe_turn => false,
            :controlled_turn_on_pipe => false)

        run = Planning::MissionRun.new(:timeout => 1.0 * 60.0)
        run.design do
            # Define start and end states
            start(pos_align)
            finish(surface)
            
            # Set up state machine
            transition(pos_align, :success => pipeline_reverse, :failed => surface)
            transition(pipeline_reverse, :success => pipeline_follow, :failed => surface)
            transition(pipeline_follow, :success => surface, :failed => surface)
        end        
    end

    describe("Autonomous mission SAUC-E'12")
    method(:sauce12_complete) do

        follow_pipe = sauce12_pipeline

        align_for_goto_buoy = align_and_move(:z => BUOY_SEARCH_Z,
                                             :yaw => BUOY_SEARCH_YAW)

        buoy = sauce12_buoy

        goto_modem_pos = align_and_move(:speed => MODEM_GOTO_SPEED,
                                        :z => WALL_SERVOING_Z,
                                        :yaw => MODEM_WAIT_POS_ANGLE,
                                        :duration => MODEM_GOTO_DURATION)

        wait_for_modem_command = simple_move(:z => WALL_SERVOING_Z,
                                             :duration => MODEM_WAIT_FOR_COMMAND_TIME)

        align_to_wall = align_and_move(:z => WALL_SERVOING_Z,
                                       :yaw => WALL_ALIGNMENT_ANGLE)

        wall = sauce12_wall

        surface = simple_move(:z => 0)

        #nav = navigate(:waypoint => Eigen::Vector3.new(0.0, 0.0, -2.2))

        run = Planning::MissionRun.new(:timeout => 20.0 * 60.0)
        run.design do
            # Define start and end states
            start(follow_pipe)
            finish(surface)
            
	        transition(follow_pipe, :success => align_for_goto_buoy, :failed => surface)
            transition(align_for_goto_buoy, :success => buoy, :failed => buoy)
	        transition(buoy, :success => goto_modem_pos, :failed => goto_modem_pos)
            transition(goto_modem_pos, :success => wait_for_modem_command, :failed => wait_for_modem_command)
            transition(wait_for_modem_command, :success => align_to_wall, :failed => align_to_wall)  
            transition(align_to_wall, :success => wall, :failed => surface)  
            transition(wall, :success => surface, :failed => surface)               
        end        
        
    end


    ########################################################################
    # Practice Area Missions                                               #
    ########################################################################

    PRACTICE_BUOY_SEARCH_YAW = deg_to_rad(180)
    PRACTICE_PIPELINE_PREFERED_YAW = 0

    method(:sauce12_practice_pipeline) do
    
        find_follow_turn_pipeline(:yaw => PIPELINE_SEARCH_YAW, 
                                  :z => PIPELINE_SEARCH_Z,
                                  :speed => PIPELINE_SEARCH_SPEED,
                                  :prefered_yaw => PRACTICE_PIPELINE_PREFERED_YAW,
                                  :turns => PIPELINE_TURNS,
                                  :search_timeout => PIPELINE_SEARCH_TIMEOUT,
                                  :turn_timeout => PIPELINE_TURN_TIMEOUT,
                                  :mission_timeout => PIPELINE_MISSION_TIMEOUT)
    end

    method(:sauce12_practice_buoy) do
        sequence = []

        goto_depth = simple_and_move(:z => BUOY_SEARCH_Z)

        s = survey_buoy(:yaw => PRACTICE_BUOY_SEARCH_YAW,
                    :z => BUOY_SEARCH_Z,
                    :speed => BUOY_SEARCH_SPEED,
                    :mode => BUOY_MODE,
                    :search_timeout => BUOY_SEARCH_TIMEOUT,
                    :mission_timeout => BUOY_MISSION_TIMEOUT
                   )   

        task = Planning::BaseTask.new
        sequence << goto_depth << s
        task.add_task_sequence(sequence)
        task
    end

    method(:sauce12_practice_wall) do
        survey_wall(:z => WALL_SERVOING_Z,
           #        :speed => WALL_SERVOING_SPEED, 
                   #:initial_wall_yaw => 0.0, # Math::PI / 2.0,
                   #:servoing_wall_yaw => 0.0, # Math::PI / 2.0,
                   #:ref_distance => 4.5,
                   :timeout => WALL_SERVOING_TIMEOUT,
                   :corners => 0)
    end

end
