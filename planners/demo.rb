class MainPlanner < Roby::Planning::Planner
    PIPELINE_FOLLOWING_Z = -1.0
    PIPELINE_SEARCH_SPEED = 0.2
    PIPELINE_SEARCH_YAW = Math::PI / 2.0
    PIPELINE_PREFERED_YAW = Math::PI
    PIPELINE_STABILIZATION = 4.0

    describe("run a complete autonomous mission for studiobad")
    method(:demo_autonomous_run, :returns => Planning::Mission) do
        main = Planning::Mission.new

        start_align = align_and_move(:z => PIPELINE_FOLLOWING_Z, :yaw => PIPELINE_SEARCH_YAW)

        find_pipe = search_pipeline(:yaw => PIPELINE_SEARCH_YAW, 
                                    :z => PIPELINE_FOLLOWING_Z,
                                    :forward_speed => PIPELINE_SEARCH_SPEED,
                                    :prefered_yaw => PIPELINE_PREFERED_YAW)

        follow_pipe = follow_and_turn_pipeline(:z => PIPELINE_FOLLOWING_Z,
                                               :prefered_yaw => PIPELINE_PREFERED_YAW,
                                               :stabilization_time => PIPELINE_STABILIZATION, :turns => 5)

        main << start_align
        main << find_pipe
        main << follow_pipe
        main
    end
end
