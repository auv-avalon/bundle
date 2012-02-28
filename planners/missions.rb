class MainPlanner < Roby::Planning::Planner
    describe("run a complete buoy servoing with cutting given a found buoy using current alignment").
        required_arg("mode", ":serve_180, :serve_360 (180 or 360 degree servoing").
        required_arg("timeout", "timeout for automatically cutting mode")
    method(:survey_and_cut_buoy) do
    end

    describe("run a complete pipeline following using current alignment").
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

            execute do
                detector_child.offshorePipelineDetector_child.orogen_task.prefered_heading = normalize_angle(prefered_heading)
            end

            wait detector_child.follow_pipe_event
            

            execute do
                Plan.info "Following pipeline until END_OF_PIPE is occuring"
            end

            wait detector_child.end_of_pipe_event

            execute do
                Plan.info "Stabilizing on end of pipeline for #{stabilization_time} seconds"
            end
            wait stabilization_time

            emit :success
        end
    end

    method(:find_and_follow_pipeline) do
        search = search_pipeline(:yaw => 0.0, :z => -3.0, :forward_speed => 4.0)
        follow = follow_pipeline(:turns => 2, :z => -3.0, :prefered_heading => 0.05, 
                                 :stabilization_time => 5.0)
        follow.depends_on(search)
        follow.should_start_after search.success_event
        follow
    end

    describe("run a complete wall servoing using current alignment to wall").
        required_arg("corners", "number of serving corners").
        optional_arg("yaw_modulation", "fixed heading modulation to serve the wall: 0 is front").
        optional_arg("ref_distance", "reference distance to wall").
        optional_arg("timeout", "timeout after successful corner passing")        
    method(:survey_wall) do
        yaw_modulation = arguments[:yaw_modulation]
        ref_distance = arguments[:ref_distance]
        corners = arguments[:corners]
        timeout = arguments[:timeout]

        PASSING_CORNER_TIMEOUT = 4

        wall_servoing = self.wall
        wall_servoing.script do
            execute do 
                survey = detector_child.servoing_child
                survey.orogen_task.wall_distance = ref_distance if ref_distance
                survey.orogen_task.heading_modulation = yaw_modulation if yaw_modulation

                Plan.info "Start wall servoing over #{corners} corners"
            end

            wait_any detector_child.start_event
            wait_any control_child.command_child.start_event

            corners.times do |i|
                wait detector_child.servoing_child.detected_corner_event
                wait detector_child.servoing_child.wall_servoing_event
                wait PASSING_CORNER_TIMEOUT
                wait detector_child.servoing_child.wall_servoing_event

                execute do
                    Plan.info "Corner #{i} passed, remaining #{corners - i} times"
                end
            end

            execute do
                Plan.info "Survey #{timeout} seconds until finish"
            end

            wait timeout
            emit :success
        end
    end
end
