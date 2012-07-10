class MainPlanner < Roby::Planning::Planner

    PIPELINE_SEARCH_SPEED = 0.50
    PIPELINE_SEARCH_Z = -2.7
    PIPELINE_SEARCH_YAW = Math::PI / 2.0
    PIPELINE_PREFERED_YAW = Math::PI ### MATH::PI ==> turn left;    0 ==> turn right
#    PIPELINE_STABILIZE_YAW = Math::PI / 2.0
    PIPELINE_SEARCH_TIMEOUT = 160
    PIPELINE_TURN_TIMEOUT = 50
    PIPELINE_MISSION_TIMEOUT = 500
    PIPELINE_TURNS = 1

    WALL_SERVOING_Z = -2.2
    WALL_SERVOING_SPEED = -0.25
    WALL_SERVOING_TIMEOUT = 240

    BUOY_SEARCH_Z = -2.5
    BUOY_SEARCH_YAW = deg_to_rad(40)
    BUOY_SEARCH_SPEED = 0.5
#    BUOY_CUT_TIMEOUT = 240
    BUOY_MODE = :serve_180
#    BUOY_SEARCH_TIMEOUT =


    method(:sauce12_pipeline) do
    
        find_follow_turn_pipeline(:yaw => PIPELINE_SEARCH_YAW, 
                                  :z => PIPELINE_SEARCH_Z,
                                  :speed => PIPELINE_SEARCH_SPEED,
                                  :prefered_yaw => PIPELINE_PREFERED_YAW,
                                  :turns => PIPELINE_TURNS,
                                  :search_timeout => PIPELINE_SEARCH_TIMEOUT,
                                  :turn_timeout => PIPELINE_TURN_TIMEOUT,
                                  :mission_timeout => PIPELINE_MISSION_TIMEOUT)
        
        #find_and_follow_pipeline(:yaw => PIPELINE_SEARCH_YAW, 
        #                         :z => PIPELINE_SEARCH_Z, 
        #                         :prefered_yaw => PIPELINE_PREFERED_YAW, 
        #                         :speed => PIPELINE_SEARCH_SPEED,
        #                         :search_timeout => PIPELINE_SEARCH_TIMEOUT,
        #                         :mission_timeout => PIPELINE_MISSION_TIMEOUT,
        #                         :do_safe_turn => true)
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
        survey_buoy(:yaw => BUOY_SEARCH_YAW,
                   :z => BUOY_SEARCH_Z,
                   :speed => BUOY_SEARCH_SPEED,
                   :mode => BUOY_MODE#,
                   #:search_timeout => BUOY_SEARCH_TIMEOUT
                   )    
    end
    
    method(:sauce12_wall) do
        survey_wall(:z => WALL_SERVOING_Z,
                             :speed => WALL_SERVOING_SPEED, 
                             #:initial_wall_yaw => 0.0, # Math::PI / 2.0,
                             #:servoing_wall_yaw => 0.0, # Math::PI / 2.0,
                             :ref_distance => 4.5,
                             :timeout => WALL_SERVOING_TIMEOUT,
                             :corners => 1)
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
        dive_and_align = align_and_move(:z => PIPELINE_SEARCH_Z, :yaw => PIPELINE_SEARCH_YAW)
        
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

        drive_to_wall = goto_wall() # TODO mission timeout

        wall = survey_wall(:z => WALL_SERVOING_Z,
                   #        :speed => WALL_SERVOING_SPEED, 
                           #:initial_wall_yaw => 0.0, # Math::PI / 2.0,
                           #:servoing_wall_yaw => 0.0, # Math::PI / 2.0,
                           #:ref_distance => 4.5,
                           :timeout => WALL_SERVOING_TIMEOUT,
                           :corners => 2)

        #nav = navigate(:waypoint => Eigen::Vector3.new(0.0, 0.0, -2.2))


        run = Planning::MissionRun.new
        run.design do
            # Define start and end states
            #start(dive_and_align)
            start(follow_pipe)
            finish(surface)
            finish(wall)
            
            # Set up state machine
            #transition(dive_and_align, :success => follow_pipe)
            transition(follow_pipe, :success => drive_to_wall, :failed => surface)
            transition(drive_to_wall, :success => wall, :failed => surface)
            
        end        
        
    end

end
