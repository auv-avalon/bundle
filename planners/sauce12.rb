class MainPlanner < Roby::Planning::Planner

    PIPELINE_SEARCH_SPEED = 0.50
    PIPELINE_SEARCH_Z = -2.7
    PIPELINE_SEARCH_YAW = Math::PI / 2.0
    PIPELINE_PREFERED_YAW = Math::PI ### MATH::PI ==> turn left;    0 ==> turn right
#    PIPELINE_STABILIZE_YAW = Math::PI / 2.0
    PIPELINE_SEARCH_TIMEOUT = 160
    PIPELINE_TURN_TIMEOUT = 5
    PIPELINE_MISSION_TIMEOUT = 120
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
                                    :mission_timeout => PIPELINE_SINGLE_MISSION_TIMEOUT)

        #buoy_and_cut = survey_and_cut_buoy(:yaw => BUOY_SEARCH_YAW,
        #                                   :z => BUOY_SEARCH_Z,
        #                                   :speed => 0.0,
        #                                   :mode => :serve_180,
        #                                   :strafe_distance => 0.6,
        #                                   :survey_distance => 0.6,
        #                                   :search_timeout => 15,
        #                                   :cut_timout => BUOY_CUT_TIMEOUT)
        
#       buoy_and_cut = dummy(:msg => "BuoyDetector")

        #wall = survey_wall(:z => WALL_SERVOING_Z,
        #                     :speed => WALL_SERVOING_SPEED, 
        #                     #:initial_wall_yaw => 0.0, # Math::PI / 2.0,
        #                     #:servoing_wall_yaw => 0.0, # Math::PI / 2.0,
        #                     :ref_distance => 4.5,
        #                     :timeout => WALL_SERVOING_TIMEOUT,
        #                     :corners => 1)

        #nav = navigate(:waypoint => Eigen::Vector3.new(0.0, 0.0, -2.2))


        run = Planning::MissionRun.new
        run.design do
            # Define start and end states
            start(dive_and_align)
            finish(surface)
            
            # Set up state machine
            transition(dive_and_align, :success => follow_pipe)
            transition(follow_pipe, :success => surface)
        end        
        
    end

end
