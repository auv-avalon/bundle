class MainPlanner
    SIMPLE_MOVE_HEADING_THRESHOLD = 10 * Math::PI / 180.0
    SIMPLE_MOVE_Z_THRESHOLD   = 0.3

    PIPELINE_SEARCH_HEADING = 10 * Math::PI / 180
    PIPELINE_SEARCH_TIMEOUT = 2 * 60
    PIPELINE_SEARCH_Z = -2.7
    PIPELINE_SEARCH_SPEED = 0.6
    PIPELINE_SEARCH_CANDIDATE_SPEED = 0.2
    PIPELINE_EXPECTED_HEADING = 110 * Math::PI / 180
    PIPELINE_STABILIZATION_TIME = 10

    FIRST_GATE_PASSING_SPEED = 0.5
    FIRST_GATE_PASSING_DURATION = 4
    FIRST_GATE_PASSING_Z = PIPELINE_SEARCH_Z

    PIPELINE_RETURNING_SPEED = 0.3
    PIPELINE_RETURNING_TIMEOUT = 60

    SECOND_PIPELINE_SERVOING_ACTIVATION_THRESHOLD = 0.8

    SECOND_GATE_PASSING_SPEED = 0.5
    SECOND_GATE_PASSING_DURATION = 7
    SECOND_GATE_PASSING_Z = PIPELINE_SEARCH_Z

    FIND_BUOY_MIN_Z = -1 # only when starting at the surface: do not allow detection above -1m
    BUOY_DIRECTION_AT_GATE = 60 * Math::PI / 180
    BUOY_SEARCH_TIMEOUT = 15 # !!!! if we ram the wall, that's the end of it !!!!
    BUOY_SEARCH_SPEED = 0.2
    BUOY_Z = -2.2

    BUOY_HAS_STRAFE_STATE = false
    BUOY_DETECTION_TO_STRAFE_TIMEOUT = 1 * 60
    BUOY_STRAFE_TO_CUT_TIMEOUT = 3 * 60
    BUOY_CUTTING_TIMEOUT = 15

    LOST_BUOY_TO_WALL_TIME = 10
    LOST_BUOY_TO_WALL_SPEED = 0.2

    WALL_ALIGNMENT_STABILIZATION_TIME = 5
    WALL_SERVOING_Z = -1
    WALL_SEARCH_TIMEOUT = 60
    WALL_CORNER_TIMEOUT = 4 * 60
    # TODO: change for consecutive missions / tasks
    WALL_SUCCESS_TIMEOUT_AFTER_CORNER = 2 * 60
    
    if IS_SIMULATION
        PIPELINE_SEARCH_HEADING   = - Math::PI
        PIPELINE_EXPECTED_HEADING = - Math::PI
        BUOY_SEARCH_TIMEOUT = 40
        BUOY_DIRECTION_AT_GATE = 40 * Math::PI / 180
    end

    method(:sauce_pipeline_and_gates, :returns => SaucE::PipelineAndGates) do
        find_pipe = find_and_follow_pipeline(:heading => PIPELINE_SEARCH_HEADING, 
			:speed => PIPELINE_SEARCH_SPEED, 
			:z => PIPELINE_SEARCH_Z,
			:expected_pipeline_heading => PIPELINE_EXPECTED_HEADING,
                        :timeout => PIPELINE_SEARCH_TIMEOUT)
	find_pipe.on :success do |event|
            heading = event.task.detector_child.pipeline_heading
            Robot.info "storing pipeline heading: #{heading * 180 / Math::PI}deg"
	    State.pipeline_heading = heading
	end
        gate_passing = simple_move(
            :forward_speed => FIRST_GATE_PASSING_SPEED,
            :z => FIRST_GATE_PASSING_Z,
            :duration => FIRST_GATE_PASSING_DURATION,
            :heading => proc { State.pipeline_heading })
        
        gate_returning = find_and_follow_pipeline(
            :speed => -PIPELINE_RETURNING_SPEED, 
            :z => PIPELINE_SEARCH_Z,
            :pipeline_activation_threshold => SECOND_PIPELINE_SERVOING_ACTIVATION_THRESHOLD,
            :timeout => PIPELINE_RETURNING_TIMEOUT)
        gate_returning.on :success do |event|
            heading = event.task.detector_child.pipeline_heading
            Robot.info "storing pipeline heading: #{heading * 180 / Math::PI}deg"
            State.pipeline_heading = heading
        end
        
        second_gate_passing = simple_move(
            :forward_speed => SECOND_GATE_PASSING_SPEED,
            :z => SECOND_GATE_PASSING_Z,
            :duration => SECOND_GATE_PASSING_DURATION,
            :heading => proc { State.pipeline_heading })

        main = SaucE::PipelineAndGates.new
        main.add_sequence(find_pipe, gate_passing, gate_returning, second_gate_passing)
        second_gate_passing.success_event.forward_to main.success_event
        main
    end

    method(:sauce_buoy) do
        find_and_servo_buoy(
            :heading => proc { normalize_angle(State.pipeline_heading + BUOY_DIRECTION_AT_GATE) },
            :speed => BUOY_SEARCH_SPEED,
            :z => BUOY_Z,
            :search_timeout => BUOY_SEARCH_TIMEOUT)
    end

    method(:sauce_wall) do
        main = SaucE::Wall.new
        alignment = simple_move(:heading => proc { State.pipeline_heading },
                    :z => WALL_SERVOING_Z,
                    :forward_speed => 0,
                    :duration => WALL_ALIGNMENT_STABILIZATION_TIME)

        main.add_sequence(alignment, self.wall_servoing(:classic_wall))
        main
    end

    method(:sauce_buoy_simtest) do
        State.pipeline_heading = 0

        buoy = sauce_buoy
        wall = sauce_wall

        main = SaucE::Mission.new

        main.depends_on(buoy, :success => [:behaviour_failure, :failed_to_find_buoy, :success],
                        :remove_when_done => false)
        main.depends_on(wall)

        # Movement that puts us closer to the wall if we lost the buoy
        move_to_wall = simple_move(:heading => proc { State.pipeline_heading + Math::PI / 2 },
                    :z => WALL_SERVOING_Z,
                    :forward_speed => LOST_BUOY_TO_WALL_SPEED,
                    :duration => LOST_BUOY_TO_WALL_TIME)
        main.depends_on(move_to_wall)

        move_to_wall.should_start_after (buoy.behaviour_failure_event | buoy.failed_to_find_buoy_event)
        wall.should_start_after(move_to_wall.success_event | buoy.success_event)
        main
    end


    describe("Autonomous run for running all sauce-specific tasks")
    method(:autonomous_run, :returns => SaucE::Mission) do
        pipeline_and_gates = sauce_pipeline_and_gates
        buoy = sauce_buoy
        wall = sauce_wall

        main = SaucE::Mission.new

        main.depends_on(pipeline_and_gates)
        main.depends_on(buoy, :success => [:behaviour_failure, :failed_to_find_buoy, :success],
                        :remove_when_done => false)
        main.depends_on(wall)

        # Movement that puts us closer to the wall if we lost the buoy
        move_to_wall = simple_move(:heading => proc { State.pipeline_heading + Math::PI / 2 },
                    :z => WALL_SERVOING_Z,
                    :forward_speed => LOST_BUOY_TO_WALL_SPEED,
                    :duration => LOST_BUOY_TO_WALL_TIME)
        main.depends_on(move_to_wall)

        buoy.should_start_after pipeline_and_gates
        move_to_wall.should_start_after (buoy.behaviour_failure_event | buoy.failed_to_find_buoy_event)
        wall.should_start_after(move_to_wall.success_event | buoy.success_event)
        main
    end

    method(:sauce_dumb_forward) do
    	simple_move :z => -1,
	    :duration => 10,
	    :forward_speed => 0.3,
	    :move_during_descent => true,
	    :heading => nil
    end
end

