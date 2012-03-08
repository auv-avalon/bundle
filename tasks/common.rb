module Planning
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
        def <<(task)
            super(task)
        end

        def add_task_sequence(list)
            super(list)
        end

        # surface directly if all tasks are finished
        on :stop do |event|
            Robot.emergency_surfacing
        end
   end
end
