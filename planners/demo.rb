class MainPlanner < Roby::Planning::Planner
    SEARCH_SPEED = 0.15

    PIPELINE_SEARCH_Z = -0.8
    PIPELINE_SEARCH_YAW = 0.0
    PIPELINE_PREFERED_YAW = 80 * Math::PI / 180.0
    PIPELINE_STABILIZE_YAW = Math::PI / 2.0

    WALL_SERVOING_Z = -1.1
    WALL_SERVOING_SPEED = -0.25
    WALL_SERVOING_TIMEOUT = 400

    BUOY_SEARCH_Z = -0.6
    BUOY_SEARCH_YAW = 0.0 * Math::PI / 180.0

    describe("run a complete autonomous mission for studiobad")
    method(:demo_autonomous_run, :returns => Planning::Mission) do
        main = Planning::Mission.new
        seq = []

        start_align = align_and_move(:z => PIPELINE_SEARCH_Z, :yaw => PIPELINE_SEARCH_YAW)

        follow_pipe = simple_find_follow_turn_pipeline(:yaw => PIPELINE_SEARCH_YAW, 
                                    :z => PIPELINE_SEARCH_Z,
                                    :speed => SEARCH_SPEED,
                                    :prefered_yaw => PIPELINE_PREFERED_YAW,
                                    :turns => 0)

        #stop_on_weak = align_and_move(:z => PIPELINE_SEARCH_Z, 
        #                              :yaw => PIPELINE_STABILIZE_YAW, 
        #                              :speed => -0.1, 
        #                              :duration => 1.5)

        align_to_buoy = align_and_move(:z => BUOY_SEARCH_Z, :yaw => BUOY_SEARCH_YAW, :speed => 0.05, :duration => 1.0)
         
        buoy_and_cut = survey_and_cut_buoy(:yaw => BUOY_SEARCH_YAW,
                                           :z => BUOY_SEARCH_Z,
                                           :speed => SEARCH_SPEED,
                                           :mode => :serve_180,
                                           :strafe_distance => 0.5,
                                           :survey_distance => 0.55)
 
        align_to_wall = align_and_strafe(:z => WALL_SERVOING_Z, 
                                         :yaw => 0.0,
                                         :speed => 0.3,
                                         :duration => 2.0)

        wall_survey = survey_wall(:corners => 1,
                             :z => WALL_SERVOING_Z,
                             :speed => WALL_SERVOING_SPEED, 
                             :initial_wall_yaw => 0.0, # Math::PI / 2.0,
                             :servoing_wall_yaw => 0.0, # Math::PI / 2.0,
                             :ref_distance => 2.5,
                             :timeout => WALL_SERVOING_TIMEOUT)
       
        seq << start_align
        seq << follow_pipe
        #seq << stop_on_weak
        seq << align_to_buoy
        seq << buoy_and_cut
        seq << align_to_wall
        seq << wall_survey

        main.add_task_sequence(seq)
        main
    end
end
