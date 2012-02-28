module Planning
    class Mission < Roby::Task
        terminates

        # surface directly if all tasks are finished
        on :stop do |event|
            Robot.emergency_surfacing
        end

        def <<(roby_task)
            depends_on roby_task

            roby_task.should_start_after @last_task.success_event if @last_task
            
            @last_task = roby_task
        end
    end
end
