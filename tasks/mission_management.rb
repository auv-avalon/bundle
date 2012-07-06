module Planning

    # Contains tools and structures to handle the progress of multiple missions.
    module Management
    
        # Defines several mission progress states
        class MissionProgress
            STOPPED = 0
            RUNNING = 1
            PAUSED  = 2
            FAILURE = 3
            SUCCESS = 4
        end
        
        # Defines a single Mission.
        class Mission
            
            # Mission name
            attr_accessor :name
            
            # Estimated Location of the mission in world coordinates. Ideally 
            # a point where the robot can start executing the mission directly.
            attr_accessor :position
            
            # Confidence in position estimate
            attr_accessor :position_probability
            
            # Mission progress
            attr_accessor :progress
            
            # Maximal available time in seconds
            attr_accessor :timeout
            
            # Planning method for this mission
            attr_accessor :planning_method
            
            def initialize(name, planning_method, timeout)
                @name = name
                @position = nil
                @position_probability = 0
                @progress = MissionProgress::STOPPED
                @timeout = timeout
                @planning_method = planning_method
            end
        end
 
        # Central Management of the process and progress of all missions in the plan.
        class MissionManagement
            # Complete list of all missions in the plan
            attr_accessor :missions
            
            # Which mission is being executed right now
            attr_accessor :current_mission
            
            # Last known position (world) of the robot
            attr_accessor :last_position
            
            # Overall timeout for the whole plan in seconds
            attr_accessor :timeout
        end
    end ### module MissionManagement

# -----------------------------------------------------------------

    MissionDependency = Struct.new(:task, :event)

    class MissionRun < Roby::Task
        terminates

        def initialize
            super()

            @mission_graph = {}
        end

        def design(&block)
            self.instance_eval(&block)

            @mission_graph.each do |task, dependency_list|
                ev = nil

                dependency_list.each do |dep|
                    ev = if ev 
                             (ev | dep.task.event(dep.event)) 
                         else 
                             dep.task.event(dep.event)
                         end
                end

                task.should_start_after(ev)
            end

            self
        end

        def finish(task)
            depends_on(task)
            task.event(:success).forward_to self.event(:success)
        end

        def start(task)
            @mission_graph[task] = [] unless @mission_graph[task]
            @mission_graph[task] << Planning::MissionDependency.new(self, :start)
        end

        def transition(task, map)
            map.each do |k, v|
                v.influenced_by(task)
                @mission_graph[v] = [] unless @mission_graph[v]
                @mission_graph[v] << Planning::MissionDependency.new(task, k)
            end

            task.event(:failed).forward_to self.event(:failed) if !map.key(:failed)
        end

        on :stop do |event|
            Plan.info "Autonomous run finished"
        end

        #        on :stop do |event|
        #            Robot.emergency_surfacing
        #        end
    end

end

=begin
include Planning::Management
mgmt = MissionManagement.new
mgmt.missions = [
    Mission.new("Pipeline","120"),
    Mission.new("Buoy","120"),
    Mission.new("Wall", "240"),
    Mission.new("Pingersearch", "240"),
    Mission.new("Asv", "360")
]    
=end
