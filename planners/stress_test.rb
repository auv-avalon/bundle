class MainPlanner
    method(:stress_test) do
    	main = Roby::Tasks::Simple.new

    	tasks = []
	5.times do
	     tasks << classic_wall
	     tasks << pipeline
	     tasks << buoy
        end

	tasks.each do |t|
	     t.script do
	        wait 10
		emit :success
	     end
	end
	main.add_sequence(*tasks)
	main
    end
end
