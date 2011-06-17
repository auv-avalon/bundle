# The main planner. A planner of this model is automatically added in the
# Interface planner list.
class MainPlanner < Roby::Planning::Planner

	method(:pipline_following) do
		main = PiplineFollowing.new
		#main.depends_on(Cmp::PiplineFollowing)
		main
	end
end

