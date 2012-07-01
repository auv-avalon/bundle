module Planning
    class AutonomousRun < Roby::Task
        terminates

        event :abort_run
        forward :abort_run => :failed

        def design(&block)
            self.instance_eval(&block)
            self
        end

        def start(task)
            depends_on task if !depends_on?(task)
        end

        def finish(task, event = :success)
            depends_on task if !depends_on?(task)

            task.success_event.forward_to self.send("#{event.to_s}_event".to_sym)
        end

        def transition(task1, event1, task2)
            depends_on task1 if !depends_on?(task1)
            depends_on task2 if !depends_on?(task2)

            task2.should_start_after task1.send("#{event1.to_s}_event".to_sym)
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
