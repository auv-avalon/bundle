class MainPlanner < Roby::Planning::Planner
    SEARCH_SPEED = 0.15

    PIPELINE_SEARCH_Z = -0.8
    PIPELINE_SEARCH_YAW = -15 * Math::PI / 180
    PIPELINE_PREFERED_YAW = -80 * Math::PI / 180
    PIPELINE_STABILIZE_YAW = Math::PI / 2.0

    WALL_SERVOING_Z = -1.1
    WALL_SERVOING_SPEED = -0.25
    WALL_SERVOING_TIMEOUT = 240

    BUOY_SEARCH_Z = -0.8
    BUOY_SEARCH_YAW = 15 * Math::PI / 180.0
    BUOY_CUT_TIMEOUT = 240

    describe("run a complete autonomous mission for studiobad")
    method(:demo_autonomous_run, :returns => Planning::Mission) do
        main = Planning::Mission.new
        seq = []

        start_align = align_and_move(:z => PIPELINE_SEARCH_Z, :yaw => PIPELINE_SEARCH_YAW)

        follow_pipe = find_follow_turn_pipeline(:yaw => PIPELINE_SEARCH_YAW, 
                                    :z => PIPELINE_SEARCH_Z,
                                    :speed => SEARCH_SPEED,
                                    :prefered_yaw => PIPELINE_PREFERED_YAW,
                                    :turns => 1)

        #stop_on_weak = align_and_move(:z => PIPELINE_SEARCH_Z, 
        #                              :yaw => PIPELINE_STABILIZE_YAW, 
        #                              :speed => -0.1, 
        #                              :duration => 1.5)

        align_to_buoy = align_and_move(:z => BUOY_SEARCH_Z, :yaw => BUOY_SEARCH_YAW)
         
        buoy_and_cut = survey_and_cut_buoy(:yaw => BUOY_SEARCH_YAW,
                                           :z => BUOY_SEARCH_Z,
                                           :speed => 0.0,
                                           :mode => :serve_180,
                                           :strafe_distance => 0.6,
                                           :survey_distance => 0.6,
					   :search_timeout => 15,
					   :cut_timout => BUOY_CUT_TIMEOUT)
 
        align_to_wall = align_and_strafe(:z => WALL_SERVOING_Z, 
                                         :yaw => 0.0,
                                         :speed => 0.3,
                                         :duration => 2.0)

        wall_survey = survey_wall(:z => WALL_SERVOING_Z,
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

    method(:demo_pipeline, :returns => Planning::Mission) do
        main = Planning::Mission.new
        seq = []

        start_align = align_and_move(:z => PIPELINE_SEARCH_Z, 
                                     :yaw => PIPELINE_SEARCH_YAW)

        follow_pipe = find_follow_turn_pipeline(:yaw => PIPELINE_SEARCH_YAW,
                                                       :z => PIPELINE_SEARCH_Z,
						       :speed => SEARCH_SPEED,
                                                       :prefered_yaw => PIPELINE_PREFERED_YAW,
                                                       :turns => 4)

        seq << start_align
        seq << follow_pipe

        main.add_task_sequence(seq)
        main
    end

    method(:demo_buoy, :returns => Planning::Mission) do
        main = Planning::Mission.new
        seq = []

        buoy_and_cut = survey_and_cut_buoy(:yaw => BUOY_SEARCH_YAW,
                                           :z => BUOY_SEARCH_Z,
                                           :speed => SEARCH_SPEED,
                                           :mode => :serve_180,
                                           :strafe_distance => 0.5,
                                           :survey_distance => 0.55,
					   :search_timeout => 10,
                                           :cut_timeout => BUOY_CUT_TIMEOUT)

        seq << buoy_and_cut

        main.add_task_sequence(seq)
        main       
    end

    method(:demo_wall, :returns => Planning::Mission) do
    	main = Planning::Mission.new
	seq = []

	wall_survey = survey_wall(:corners => 2,
                             :z => WALL_SERVOING_Z,
                             :speed => WALL_SERVOING_SPEED, 
                             :initial_wall_yaw => 0.0, # Math::PI / 2.0,
                             :servoing_wall_yaw => 0.0, # Math::PI / 2.0,
                             :ref_distance => 2.5,
                             :timeout => WALL_SERVOING_TIMEOUT)

	seq << wall_survey

	main.add_task_sequence(seq)
	main
    end
end
