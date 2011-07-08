    describe "just after the pipeline, approaches the wall using the sonar, turns towards the buoy and servoes the wall until either a buoy is detected or a timeout is found"
    method(:find_buoy) do
        main = LookForBuoy.new

        # First part: get closer to the wall, using the wall detector as a
        # distance estimator
        move = move_forward(:duration => 10,
                            :speed => FIND_BUOY_SPEED,
                            :z => FIND_BUOY_Z)
        move.depends_on(wall_distance_estimator, :as => 'wall_distance')
        move.script do
            data_reader 'wall_info', ['wall_distance']
            wait_any wall_distance_child.start_event
            
            poll do
                # TODO
                # Wait for distance < threshold
                # transition!
                current_distance = wall_info.detector.distance

                if not current_distance.nil?
                    if current_distance < WALL_DISTANCE_THRESHOLD
                        transition!
                    end
                end
            end

            emit :success
        end

        # Second part: rotate towards the buoy
        turn = rotate(:relative_heading => Math::PI, :z => FIND_BUOY_TURNING_Z)

        # Third part: use the wall servoing with the wall full right. Try to get
        # a detected buoy
        main.depends_on(approach = wall_approach_buoy, :role => 'approach')
        approach.depends_on(buoy_detector = self.buoy_detector, :as => "buoy_detector")
        buoy_detector.buoy_detected_event.
            forward_to main.found_event

        # Timeout on the buoy detection
        main.script do
            wait approach_child.start_event
            start = nil
            execute do
                start = Time.now
            end
            poll do
                if Time.now - start > FIND_BUOY_TIMEOUT
                    emit :not_found
                end
            end
        end

        main.add_sequence(move, turn, approach)
        main
    end

    method(:sauce_pipeline) do
	find_and_follow_pipeline(:heading => PIPELINE_SEARCH_HEADING, 
			:speed => PIPELINE_SEARCH_SPEED, 
			:z => PIPELINE_SEARCH_Z,
			:expected_pipeline_heading => PIPELINE_EXPECTED_HEADING)
    end

    # The angular tolerance around the target heading to declare that we reached
    # it. The task will require the heading to not be further away than
    # PIPELINE_HOVERING_STABILITY_THRESHOLD radians for
    # PIPELINE_HOVERING_STABILITY_TIME before declaring success
    PIPELINE_HOVERING_STABILITY_THRESHOLD = 10 * Math::PI / 180
    # The amound of seconds we require our heading to be close to target before
    # announcing a success
    PIPELINE_HOVERING_STABILITY_TIME = 10
    describe("rotate to a specific direction in focus of the end of pipeline").
        required_arg("target_yaw", "the target heading in radians")
    method(:pipeline_hovering) do
        rotation_speed = arguments[:rotation_speed]
        target_yaw     = arguments[:target_yaw]

        # we need the pipeline definition for visual servoing on the end of pipeline
        pipeline = self.pipeline
        pipeline.script do
            data_reader 'orientation', ['control', 'orientation_with_z', 'orientation_z_samples']
            data_reader 'pipeline_servoing_command', ['detector', 'relative_position_command']
            data_writer 'rel_pos_command', ['control', 'command', 'position_command']

            wait_any control_child.command_child.start_event
            execute do
                # Disconnect the pipeline detector from the AUV relpos
                # controller
                pipeline_detector_port = detector_child.relative_position_command_port
                auv_relpos_port        = control_child.command_child.position_command_port
                pipeline_detector_port.disconnect_from auv_relpos_port
            end

            stability_start = nil
            poll do
                servoing_command    = pipeline_servoing_command
                current_orientation = orientation
                if servoing_command && current_orientation
                    heading_error = target_yaw - current_orientation.orientation.yaw
                    servoing_command.heading = heading_error
                    rel_pos_command_writer.write(servoing_command)

                    if heading_error.abs < PIPELINE_HOVERING_STABILITY_THRESHOLD
                        stability_start ||= Time.now
                    else stability_start = nil
                    end

                    if stability_start && (Time.now - stability_start) > PIPELINE_HOVERING_STABILITY_TIME
                        transition!
                    end
                end
            end
            emit :success
        end
    end
    

