class MainPlanner < Roby::Planning::Planner
    SEARCH_SPEED = 0.2

    PIPELINE_FOLLOWING_Z = -1.0
    PIPELINE_SEARCH_YAW = Math::PI / 2.0
    PIPELINE_PREFERED_YAW = Math::PI
    PIPELINE_STABILIZATION = 7.0
    PIPELINE_STABILIZE_YAW = 0.0

    BUOY_DISTANCE_ALIGNMENT = 4.0
    BUOY_SEARCH_Z = -1.0
    BUOY_SEARCH_YAW = -Math::PI / 2.0

    describe("run a complete autonomous mission for studiobad")
    method(:demo_autonomous_run, :returns => Planning::Mission) do
        main = Planning::Mission.new
        seq = []

        start_align = align_and_move(:z => PIPELINE_FOLLOWING_Z, :yaw => PIPELINE_SEARCH_YAW)

        follow_pipe = follow_and_turn_pipeline(:yaw => PIPELINE_SEARCH_YAW, 
                                    :z => PIPELINE_FOLLOWING_Z,
                                    :speed => SEARCH_SPEED,
                                    :prefered_yaw => PIPELINE_PREFERED_YAW,
                                    :turns => 1)

        stop_on_weak = align_and_move(:z => PIPELINE_FOLLOWING_Z, :yaw => PIPELINE_STABILIZE_YAW, :forward_speed => -0.2, :duration => 5.0)

        stabilize = align_frontal_distance(:z => PIPELINE_FOLLOWING_Z, :yaw => PIPELINE_STABILIZE_YAW,
                                            :distance => BUOY_DISTANCE_ALIGNMENT,
                                            :stabilization_time => PIPELINE_STABILIZATION)

        align_to_buoy = align_and_move(:z => BUOY_SEARCH_Z, :yaw => BUOY_SEARCH_YAW)
        
        seq << start_align
        seq << follow_pipe
        seq << stop_on_weak
        seq << stabilize
        seq << align_to_buoy

        main.add_task_sequence(seq)
        main
    end
end
