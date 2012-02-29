module Planning
    class BaseTask < Roby::Task
        def <<(roby_task)
            depends_on roby_task

            roby_task.should_start_after @last_task.success_event if @last_task
            
            @last_task = roby_task
        end

        def add_tasklist(list)
            list.each do |n|
                self << n
            end
        end
    end

    class Mission < Planning::BaseTask
        terminates

        def <<(task)
            super(task)
        end

        def add_tasklist(list)
            super(task)
        end

        # surface directly if all tasks are finished
        on :stop do |event|
            Robot.emergency_surfacing
        end
   end
end
