module Planning
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
