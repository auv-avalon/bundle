class Taskmon::Task
    def initialize(options = Hash.new)
        super

        @watched_deployments = Hash.new { |h, k| h[k] = ValueSet.new }
        @watched_tasks = ValueSet.new
        @watched_pids = Hash.new
    end

    on :start do |event|
        @query_tasks = plan.find_tasks(Orocos::RobyPlugin::TaskContext).
            running
        @query_deployments = plan.find_tasks(Orocos::RobyPlugin::Deployment).
            running
    end

    poll do
        @query_tasks.reset
        tasks = @query_tasks.to_value_set
        new_tasks = (tasks - @watched_tasks)
        new_tasks.delete_if { |t| !t.on_same_server?(self) }

        @query_deployments.reset
        deployments = @query_deployments.to_value_set
        old_deployments = (@watched_deployments.keys.to_value_set - deployments)

        # If there is no new tasks / old deployments, no need to do anything
        if new_tasks.empty? && old_deployments.empty?
            return
        end

        @watched_tasks.delete_if { |t| !t.running? }
        @watched_tasks |= new_tasks

        required_deployments = new_tasks.map(&:execution_agent).to_value_set

        threads = Hash.new
        new_tasks.each do |task|
            threads[task.tid] = task.orocos_name
        end

        pids = Hash.new
        required_deployments.map do |p|
            pids[p.pid] = p.deployment_name
        end
        orogen_task.add_watches(pids, threads)

        old_tids = Set.new
        old_deployments.each do |deployment_task|
            tids = @watched_deployments.delete(deployment_task)
            next if !tids
            old_tids |= tids.to_set
        end
        orogen_task.remove_watches(old_tids)
    end
end

