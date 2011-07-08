IS_SIMULATION = true

require 'planners/main'

class MainPlanner
    method(:simple_move) do
	move_forward(:heading => 0.0, 
			:speed => 1.0, 
			:z => -2.0,
			:duration => 1000)
    end
end

