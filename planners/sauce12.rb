class MainPlanner < Roby::Planning::Planner

    PIPELINE_SEARCH_SPEED = 0.50
    PIPELINE_SEARCH_Z = -2.7
    PIPELINE_SEARCH_YAW = Math::PI / 2.0
    PIPELINE_PREFERED_YAW = 0#Math::PI
#    PIPELINE_STABILIZE_YAW = Math::PI / 2.0

    WALL_SERVOING_Z = -2.2
    WALL_SERVOING_SPEED = -0.25
    WALL_SERVOING_TIMEOUT = 240

    BUOY_SEARCH_Z = -2.2
    BUOY_SEARCH_YAW = deg_to_rad(50)
#    BUOY_CUT_TIMEOUT = 240

    describe("Autonomous mission SAUC-E'12")
    method(:sauce12_complete) do

        # Submerge and align to start heading
        dive_and_align = align_and_move(:z => PIPELINE_SEARCH_Z, :yaw => PIPELINE_SEARCH_YAW)
        
        surface = simple_move(:z => 0)

        follow_pipe = find_follow_turn_pipeline(:yaw => PIPELINE_SEARCH_YAW, 
                                    :z => PIPELINE_SEARCH_Z,
                                    :speed => PIPELINE_SEARCH_SPEED,
                                    :prefered_yaw => PIPELINE_PREFERED_YAW,
                                    :turns => 1)

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
