class MainPlanner
    describe("run a complete buoy servoing with cutting given a found buoy using current alignment").
        required_arg("mode", ":serve_180, :serve_360 (180 or 360 degree servoing").
        required_arg("timeout", "timeout for automatically cutting mode")
    method(:survey_and_cut_buoy) do
    end

    describe("run a complete pipeline following using current alignment").
        required_arg("turns", "number of turns on pipeline following").
        required_arg("z", "initial z value for pipeline following").
        required_arg("prefered_heading", "prefered heading on pipeline").
        required_arg("stabilization_time", "time of stabilization of the pipeline").
        optional_arg("timeout", "timeout for aborting pipeline following")
    method(:follow_pipeline) do
        turns = arguments[:turns] + 1
        z = arguments[:z]
        timeout = arguments[:timeout] 
        prefered_heading = arguments[:prefered_heading]
        stabilization_time = arguments[:stabilization_time]

        pipeline = self.pipeline
        pipeline.script do
            if timeout
                execute do
                    detector_child.found_pipe_event.should_emit_after detector_child.start_event,
                    :max_t => timeout
                end
            end

            wait_any detector_child.start_event
            wait_any control_child.command_child.start_event

            turns.times do |i|
                execute do
                    detector_child.offshorePipelineDetector_child.orogen_task.prefered_heading = 
                        (i % 2) * Math::PI + prefered_heading
                end

                wait detector_child.follow_pipe_event
                wait detector_child.end_of_pipe_event
                wait stabilization_time
            end

            emit :success
        end
    end

    method(:find_and_follow_pipeline) do
        search = search_pipeline(:yaw => Math::PI / 2.0, :z => -3.0, :forward_speed => 4.0)
        follow = follow_pipeline(:turns => 2, :z => -3.0, :prefered_heading => 0.05, 
                                 :stabilization_time => 5.0)
        follow.depends_on(search)
        follow.should_start_after search.success_event
        follow
    end

    describe("run a complete wall servoing using current alignment to wall").
        required_arg("yaw_modulation", "fixed heading modulation to serve the wall: 0 is front").
        required_arg("ref_distance", "reference distance to wall").
        required_arg("min_distance", "minimal distance to wall").
        required_arg("corners", "number of serving corners").
        optional_arg("timeout", "timeout for aborting wall servoing")        
    method(:survey_wall) do
        yaw_modulation = arguments[:yaw_modulation]
        ref_distance = arguments[:ref_distance]
        min_distance = arguments[:min_distance]
        corners = arguments[:corners]
        timeout = arguments[:timeout]

        wall_servoing = self.wall
        wall_servoing.script do
            wait_any detector_child.start_event
            wait_any control_child.command_child.start_event

            corners.times do |i|
                wait detector_child.servoing_child.detected_corner_event
            end

            wait timeout
        end
    end
end
