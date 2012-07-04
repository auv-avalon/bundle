module Planning
    Waypoint = Struct.new(:position, :tolerance)

    class SimpleMission < Roby::Task
        terminates

        attr_accessor :planning_method

        def initialize(task)
            super()

            @planning_method = task
            influenced_by(task)

            task.should_start_after self.event(:start)

            task.event(:success).forward_to self.event(:success)
            task.event(:failed).forward_to self.event(:failed)
            task.event(:stop).forward_to self.event(:stop)
        end
    end


    class TimeoutMission < Roby::Task
        terminates

        event :timeout
        event :finished

        # Mission name
        attr_accessor :name

        # planning method for this mission
        attr_accessor :planning_method

        # timeout for this mission
        attr_accessor :timeout

        # starting time
        attr_accessor :start_time

        # progress
        attr_accessor :progress

        on :start do |event|
            @start_time = Time.now
            Plan.info "Mission <#{@name}> has been started"
            @progress = :running
        end

        poll do
            if @timeout and time_over?(@start_time, @timeout)
                Plan.error "Mission timout emitted for <#{@name}>"
                @progress = :failed
                emit :timeout
            end
        end

        on :failed do |event|
            Plan.error "Mission <#{@name}> failed"
            @progress = :failed
        end

        def initialize(name, task, timeout = nil)
            super()
            
            @name = name
            @planning_method = task
            @timeout = timeout
            @progress = :to_perform
            @start_time = nil

            influenced_by(task)

            task.on :success do |event|
                Plan.info "Mission <#{@name}> completed"
                @progress = :finished
            end

            task.should_start_after self.event(:start)

            task.event(:failed).forward_to self.event(:failed)
            task.event(:success).forward_to self.event(:success)

            self.event(:timeout).forward_to self.event(:stop)

            self.event(:stop).forward_to task.event(:stop)
        end
    end


    class MissionRun < Roby::Task
        terminates

        # current missions for this autonomous run
        attr_accessor :missions

        def initialize
            super()

            @missions = []
        end

        def design(&block)
            self.instance_eval(&block)
            self
        end

        def state(task)
            mission = Planning::SimpleMission.new(task)
            influenced_by(mission)
            mission
        end

        def mission(name, task, timeout = nil, events = [])
            mission = Planning::TimeoutMission.new(name, task, timeout)
            influenced_by(mission)

            @missions << mission
            mission
        end

        def finish(task)
            depends_on task

            task.event(:success).forward_to self.event(:success)
        end

        def start(task1)
            task1.should_start_after self.event(:start)
        end

        def transition(task1, map)
            map.each do |k, v|
                task1.event(k).forward_to v.event(:start)
            end

            task1.event(:failed).forward_to self.event(:failed) if !map.hasKey?(:failed)
        end

        on :stop do |event|
            Plan.info "= REPORT ============================================="
            @missions.each do |m|
                Plan.info "#{m.name}: #{m.progress}"
            end
            Plan.info "======================================================"
        end

#        on :stop do |event|
#            Robot.emergency_surfacing
#        end
    end

    class BaseTask < Roby::Task
        terminates

        def <<(roby_task)
            depends_on roby_task

            roby_task.should_start_after @last_task.success_event if @last_task
            
            @last_task = roby_task
        end

        def add_task_sequence(list)
            list.each do |n|
                self << n
            end

            @last_task.success_event.forward_to self.success_event
        end
    end

    class Mission < Planning::BaseTask
        terminates

        def <<(task)
            super(task)
        end

        def add_task_sequence(list)
            super(list)
        end

        # surface directly if all tasks are finished
        #on :stop do |event|
        #    Robot.emergency_surfacing
        #end
   end

    class Dummy < Roby::Task
        terminates
    end
end
