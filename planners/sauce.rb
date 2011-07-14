class MainPlanner
    SIMPLE_MOVE_HEADING_THRESHOLD = 10 * Math::PI / 180.0
    SIMPLE_MOVE_Z_THRESHOLD   = 0.3

    PIPELINE_SEARCH_HEADING = 20 * Math::PI / 180
    PIPELINE_SEARCH_TIMEOUT = 90
    PIPELINE_SEARCH_Z = -2.85
    PIPELINE_SEARCH_SPEED = 0.5
    PIPELINE_SEARCH_CANDIDATE_SPEED = 0.2
    PIPELINE_EXPECTED_HEADING = 110 * Math::PI / 180
    PIPELINE_STABILIZATION_TIME = 10

    FIRST_GATE_PASSING_SPEED = 0.5
    FIRST_GATE_PASSING_DURATION = 4
    FIRST_GATE_PASSING_Z = PIPELINE_SEARCH_Z

    PIPELINE_RETURNING_SPEED = 0.3
    PIPELINE_RETURNING_TIMEOUT = 15

    SECOND_PIPELINE_SERVOING_ACTIVATION_THRESHOLD = 0.8

    SECOND_GATE_PASSING_SPEED = 0.5
    SECOND_GATE_PASSING_DURATION = 7
    SECOND_GATE_PASSING_Z = PIPELINE_SEARCH_Z

    FIND_BUOY_MIN_Z = -1 # only when starting at the surface: do not allow detection above -1m
    BUOY_DIRECTION_AT_GATE = 60 * Math::PI / 180
    BUOY_SEARCH_TIMEOUT = 15 # !!!! if we ram the wall, that's the end of it !!!!
    BUOY_SEARCH_SPEED = 0.2
    BUOY_Z = -1.5
    BUOY_WALL_APPROACH_SPEED = 0.2 # speed at which we approach the wall if we use the wall detector method

    BUOY_HAS_STRAFE_STATE = false
    BUOY_DETECTION_TO_STRAFE_TIMEOUT = 1 * 60
    BUOY_STRAFE_TO_CUT_TIMEOUT = 3 * 60
    BUOY_CUTTING_TIMEOUT = 15

    LOST_BUOY_TO_WALL_TIME = 10
    LOST_BUOY_TO_WALL_SPEED = 0.3

    WALL_ALIGNMENT_STABILIZATION_TIME = 5
    WALL_SERVOING_Z = -1
    WALL_SEARCH_TIMEOUT = 60
    WALL_CORNER_TIMEOUT = 4 * 60
    # TODO: change for consecutive missions / tasks
    WALL_SUCCESS_TIMEOUT_AFTER_CORNER = 2 * 60

    ASV_AWAY_FROM_WALL_SPEED = 0.3
    ASV_AWAY_FROM_WALL_TIME  = 2
    ASV_TO_PIPELINE_LEVEL_SPEED = 0.5
    ASV_TO_PIPELINE_LEVEL_TIME  = 10
    ASV_GATE_PASSING_SPEED = 0.6
    ASV_GATE_PASSING_TIME = 15
    ASV_SEARCH_Z = -3
    
    if IS_SIMULATION
        PIPELINE_SEARCH_HEADING   = Math::PI / 2
        PIPELINE_EXPECTED_HEADING = - Math::PI
        BUOY_SEARCH_TIMEOUT = 40
        BUOY_DIRECTION_AT_GATE = 90 * Math::PI / 180
        WALL_CORNER_TIMEOUT = 20
    end

    method(:sauce_pipeline_and_gates, :returns => SaucE::PipelineAndGates) do
        find_pipe = find_and_follow_pipeline(:heading => PIPELINE_SEARCH_HEADING, 
			:speed => PIPELINE_SEARCH_SPEED, 
			:z => PIPELINE_SEARCH_Z,
			:expected_pipeline_heading => PIPELINE_EXPECTED_HEADING,
                        :timeout => PIPELINE_SEARCH_TIMEOUT)
        find_pipe.on :start do |event|
            task = event.task.detector_child
            task.on :lost_pipe do |_|
                if !event.task.end_of_pipe?
                    event.task.emit :failed
                end
            end
        end
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
            :timeout => PIPELINE_RETURNING_TIMEOUT,
            :stabilization_time => 0)
        gate_returning.on :start do |event|
            task = event.task.detector_child
            task.lost_pipe_event.forward_to task.end_of_pipe_event
        end
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
            :heading => arguments[:heading],
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

        servoing = self.wall_servoing(:classic_wall)
        main.add_sequence(alignment, servoing)
        servoing.failed_event.forward_to main.timeout_event
        main
    end

    method(:sauce_cool_buoy_and_wall, :returns => SaucE::CoolBuoyAndWall) do
        main = SaucE::CoolBuoyAndWall.new

        # Find out if we can get a distance to the wall
        distance_estimator = classic_wall_detector
        station_keep = simple_move(:heading => proc { State.pipeline_heading },
                    :z => WALL_SERVOING_Z,
                    :forward_speed => 0,
                    :duration => 10)
        main.depends_on(distance_estimator, :success => :stop, :role => 'distance_estimator')
        main.depends_on(station_keep, :success => :stop, :role => 'station_keep')
        main.wall_acquisition_finished_event.signals distance_estimator.stop_event
        main.wall_acquisition_finished_event.signals station_keep.stop_event
        main.script do
            wait_any distance_estimator_child.start_event

            wall_info_reader = nil
            execute do
                wall_info_reader = distance_estimator_child.detector_child.laser_servoing_state_port.reader
            end
            wait 5
            execute do
                if data = wall_info_reader.read
                    puts "wall data: #{data.wall_pos} #{data.distance} #{data.diff_heading}"
                    if data.wall_pos != :NO_WALL && data.distance > 8 && data.distance < 12 && data.diff_heading.abs < 10 * Math::PI / 180
                        emit :found_distance
                    else
                        emit :no_distance
                    end
                else puts "no data"
                end
            end
        end

        # Actions if we have a distance estimation
        move = simple_move(:heading => proc { State.pipeline_heading },
                    :z => WALL_SERVOING_Z,
                    :forward_speed => BUOY_WALL_APPROACH_SPEED)
        move.depends_on(classic_wall_detector, :role => 'distance_estimator')
        move.script do
            data_reader 'wall_info', ['distance_estimator', 'detector', 'laser_servoing_state']
            poll do
                if data = wall_info
                    if data.distance < 4.5
                        emit :success
                    elsif data.wall_pos == :NO_WALL
                        emit :success
                    end
                end
            end
        end
        task1 = sauce_buoy_and_wall :heading => proc { State.pipeline_heading + Math::PI / 2 }
        main.add_sequence(move, task1)
        move.should_start_after main.found_distance_event

        # Actions if we don't have a distance estimation
        task2 = sauce_buoy_and_wall :heading => proc { State.pipeline_heading + BUOY_DIRECTION_AT_GATE }
        main.depends_on(task2)
        task2.should_start_after main.no_distance_event

        main
    end

    method(:sauce_buoy_and_wall, :returns => SaucE::BuoyAndWall) do
        buoy = sauce_buoy :heading => arguments[:heading]
        wall = sauce_wall

        main = SaucE::BuoyAndWall.new
        main.depends_on(buoy,
            :success => [:behaviour_failure, :failed_to_find_buoy, :success],
                        :remove_when_done => false)
        main.depends_on(wall)

        # Movement that puts us closer to the wall if we lost the buoy
        move_to_wall = simple_move(:heading => proc { State.pipeline_heading + Math::PI / 2 },
                    :z => WALL_SERVOING_Z,
                    :forward_speed => LOST_BUOY_TO_WALL_SPEED,
                    :duration => LOST_BUOY_TO_WALL_TIME)
        main.depends_on(move_to_wall)

        move_to_wall.should_start_after(buoy.behaviour_failure_event | buoy.failed_to_find_buoy_event)
        wall.should_start_after(move_to_wall.success_event | buoy.success_event)

        wall.timeout_event.forward_to main.wall_timeout_event
        wall.success_event.forward_to main.success_event
        main
    end

    method(:sauce_asv_from_wall, :returns => SaucE::ASVFromWall) do
        main = SaucE::ASVFromWall.new
        away_from_wall = simple_move(:heading => proc { State.pipeline_heading + Math::PI / 4 },
                    :z => WALL_SERVOING_Z,
                    :forward_speed => -ASV_AWAY_FROM_WALL_SPEED,
                    :duration => ASV_AWAY_FROM_WALL_TIME)
        to_pipeline_level = simple_move(:heading => proc { Math::PI + State.pipeline_heading },
                    :z => WALL_SERVOING_Z,
                    :forward_speed => ASV_TO_PIPELINE_LEVEL_SPEED,
                    :duration => ASV_TO_PIPELINE_LEVEL_TIME)
        to_pipeline_direction = simple_move(:heading => proc { State.pipeline_heading - Math::PI/2},
                    :z => PIPELINE_SEARCH_Z,
                    :forward_speed => 0,
                    :duration => 0)
        to_pipeline_direction.on :stop do |event|
            State.pipeline_heading = normalize_angle(State.pipeline_heading + Math::PI)
        end
        to_pipeline_end = find_and_follow_pipeline(:heading => nil,
            :speed => PIPELINE_SEARCH_SPEED, 
            :z => PIPELINE_SEARCH_Z,
            :timeout => PIPELINE_SEARCH_TIMEOUT)
	to_pipeline_end.on :success do |event|
            heading = event.task.detector_child.pipeline_heading
            Robot.info "storing pipeline heading: #{heading * 180 / Math::PI}deg"
	    State.pipeline_heading = heading
	end
        to_asv_position = simple_move(
            :forward_speed => ASV_GATE_PASSING_SPEED,
            :z => ASV_SEARCH_Z,
            :duration => ASV_GATE_PASSING_TIME,
            :heading => proc { State.pipeline_heading })
        asv = self.asv

        main.add_sequence(away_from_wall, to_pipeline_level, to_pipeline_direction, to_pipeline_end, to_asv_position, asv)
        main
    end

    method(:sauce_from_second_gate) do
        if IS_SIMULATION
            State.pipeline_heading = 0
        else
            State.pipeline_heading = (110 - 180) * Math::PI / 180
        end

        main = SaucE::Mission.new
        buoy_and_wall = sauce_buoy_and_wall :heading => proc { normalize_angle(State.pipeline_heading + BUOY_DIRECTION_AT_GATE) }
        asv = sauce_asv_from_wall
        main.depends_on(buoy_and_wall, :success => :stop)
        main.depends_on(asv)

        asv.should_start_after buoy_and_wall

        main
    end

    method(:sauce_after_wall) do
        if IS_SIMULATION
            State.pipeline_heading = 0
        else
            State.pipeline_heading = (110 - 180) * Math::PI / 180
        end
        sauce_asv_from_wall
    end

    method(:sauce_from_second_gate_cool) do
        if IS_SIMULATION
            State.pipeline_heading = 0
        else
            State.pipeline_heading = (110 - 180) * Math::PI / 180
        end
        sauce_cool_buoy_and_wall
    end

    describe("Autonomous run for running all sauce-specific tasks")
    method(:autonomous_run, :returns => SaucE::Mission) do
        main = SaucE::Mission.new
        pipeline_and_gates = sauce_pipeline_and_gates
        buoy_and_wall = sauce_buoy_and_wall :heading => proc { normalize_angle(State.pipeline_heading + BUOY_DIRECTION_AT_GATE) }
        asv = sauce_asv_from_wall

        main.depends_on(pipeline_and_gates)
        main.depends_on(buoy_and_wall, :success => :stop)
        main.depends_on(asv)

        buoy_and_wall.should_start_after pipeline_and_gates.success_event
        asv.should_start_after buoy_and_wall

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

