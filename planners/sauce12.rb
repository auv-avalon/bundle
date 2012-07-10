class MainPlanner < Roby::Planning::Planner

    PIPELINE_SEARCH_SPEED = 0.40
    PIPELINE_SEARCH_Z = -2.7
    PIPELINE_SEARCH_YAW = Math::PI / 2.0
    PIPELINE_PREFERED_YAW = Math::PI ### MATH::PI ==> turn left;    0 ==> turn right
#    PIPELINE_STABILIZE_YAW = Math::PI / 2.0
    PIPELINE_SEARCH_TIMEOUT = 120
    PIPELINE_TURN_TIMEOUT = 50
    PIPELINE_MISSION_TIMEOUT = 360
    PIPELINE_TURNS = 1

    WALL_SERVOING_Z = -1.1
    WALL_SERVOING_TIMEOUT = 180
    WALL_ALIGNMENT_ANGLE = Math::PI/2.0
    
    GOTO_WALL_ALIGNMENT_ANGLE = 0.0
    GOTO_WALL_TIMEOUT = 30

    BUOY_SEARCH_TIMEOUT = 60
    BUOY_MISSION_TIMEOUT = 10
    BUOY_SEARCH_Z = -2.5
    BUOY_SEARCH_YAW = deg_to_rad(0)
    BUOY_SEARCH_SPEED = 0.0
    BUOY_MODE = :serve_360


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
    
    method(:sauce12_align_on_pipe) do
        find_and_follow_pipeline(:yaw => 0, ## we are already on pipe, so yaw is not important
                                 :z => PIPELINE_SEARCH_Z, 
                                 :speed => PIPELINE_SEARCH_SPEED,
                                 :prefered_yaw => 0,
                                 :search_timeout => 10,  # TODO set correct timeout
                                 :mission_timeout => 60,
                                 :do_safe_turn => false)
    end
    
    method(:sauce12_buoy) do
        pos_align = align_and_move(:z => -2.7,:yaw => BUOY_SEARCH_YAW)

        s = survey_buoy(:yaw => BUOY_SEARCH_YAW,
                    :z => BUOY_SEARCH_Z,
                    :speed => BUOY_SEARCH_SPEED,
                    :mode => BUOY_MODE,
                    :search_timeout => BUOY_SEARCH_TIMEOUT,
                    :mission_timeout => BUOY_MISSION_TIMEOUT
                   )   


        run = Planning::MissionRun.new
        run.design do
            start(pos_align)
            finish(s)

            transition(pos_align, :success => s)
        end        
    end

    method(:sauce12_wall) do
        survey_wall(:z => WALL_SERVOING_Z,
           #        :speed => WALL_SERVOING_SPEED, 
                   #:initial_wall_yaw => 0.0, # Math::PI / 2.0,
                   #:servoing_wall_yaw => 0.0, # Math::PI / 2.0,
                   #:ref_distance => 4.5,
                   :timeout => WALL_SERVOING_TIMEOUT,
                   :corners => 2)
    end
    

    method(:sauce12_simple) do
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

        run = Planning::MissionRun.new
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

        # Submerge and align to start heading
        #dive_and_align = align_and_move(:z => PIPELINE_SEARCH_Z, :yaw => PIPELINE_SEARCH_YAW)
        
        surface = simple_move(:z => 0)

        follow_pipe = find_follow_turn_pipeline(:yaw => PIPELINE_SEARCH_YAW, 
                                  :z => PIPELINE_SEARCH_Z,
                                  :speed => PIPELINE_SEARCH_SPEED,
                                  :prefered_yaw => PIPELINE_PREFERED_YAW,
                                  :turns => PIPELINE_TURNS,
                                  :search_timeout => PIPELINE_SEARCH_TIMEOUT,
                                  :turn_timeout => PIPELINE_TURN_TIMEOUT,
                                  :mission_timeout => PIPELINE_MISSION_TIMEOUT)

        #buoy_and_cut = survey_and_cut_buoy(:yaw => BUOY_SEARCH_YAW,
        #                                   :z => BUOY_SEARCH_Z,
        #                                   :speed => BUOY_SEARCH_SPEED,
        #                                   :mode => BUOY_MODE#,
        #                                   #:search_timeout => BUOY_SEARCH_TIMEOUT
        #                                   )
        
#       buoy_and_cut = dummy(:msg => "BuoyDetector")

        #drive_to_wall = goto_wall(:mission_timeout => GOTO_WALL_TIMEOUT = 90) # TODO mission timeout

        #wall = survey_wall(:z => WALL_SERVOING_Z,
        #           #        :speed => WALL_SERVOING_SPEED, 
        #                   #:initial_wall_yaw => 0.0, # Math::PI / 2.0,
        #                   #:servoing_wall_yaw => 0.0, # Math::PI / 2.0,
        #                   #:ref_distance => 4.5,
        #                   :timeout => WALL_SERVOING_TIMEOUT,
        #                   :corners => 2)

        #nav = navigate(:waypoint => Eigen::Vector3.new(0.0, 0.0, -2.2))
        
        #align_for_goto_wall = align_and_move(:z => WALL_SERVOING_Z,
        #                                     :yaw => GOTO_WALL_ALIGNMENT_ANGLE)
        
        #align_to_wall = align_and_move(:z => WALL_SERVOING_Z,
        #                               :yaw => WALL_ALIGNMENT_ANGLE)
        
	#left_area_move_back = simple_move(:forward_speed => -PIPELINE_SEARCH_SPEED,
	#                                  :z => WALL_SERVOING_Z,
#					  :yaw => proc {State.pipeline_heading},
#					  :duration => 5)

        run = Planning::MissionRun.new
        run.design do
            # Define start and end states
            #start(dive_and_align)
            start(follow_pipe)
            #start(align_for_goto_wall)
            finish(surface)
            #finish(wall)
            
            
            
            # Set up state machine
            
            # TODO Do not surface all the time in case of an error! Do other missions!
            
            #transition(dive_and_align, :success => follow_pipe)
            
	    ### right area
            
	    transition(follow_pipe, :success => surface, :failed => surface)
	    #transition(follow_pipe, :success => align_for_goto_wall, :failed => surface)
            #transition(align_for_goto_wall, :success => drive_to_wall, :failed => surface)
            
	    ### left area
	    #transition(follow_pipe, :success => left_area_move_back, :failed => surface)
            #transition(left_area_move_back, :success => align_for_goto_wall, :failed => surface)
            #transition(align_for_goto_wall, :success => drive_to_wall, :failed => surface)
            

            #transition(drive_to_wall, :success => align_to_wall, :failed => surface)
            #transition(align_to_wall, :success => wall, :failed => surface)
            #transition(wall, :success => surface, :failed => surface)            
        end        
        
    end

end
