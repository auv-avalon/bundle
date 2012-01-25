class MainPlanner
    describe("run a complete buoy servoing with cutting given a found buoy using current alignment").
        required_arg("mode", ":serve_180, :serve_360 (180 or 360 degree servoing").
        required_arg("timeout", "timeout for automatically cutting mode")
    method(:serve_and_cut_buoy) do
    end

    describe("run a complete pipeline following using current alignment").
        required_arg("turns", "number of turns on pipeline following").
        required_arg("activation", "activation threshold for finding a pipeline").
        optional_arg("timeout", "timeout for aborting pipeline following")
    method(:follow_pipeline) do
    end

    describe("run a complete wall servoing using current alignment to wall").
        required_arg("yaw_modulation", "fixed heading modulation to serve the wall: 0 is front").
        required_arg("ref_distance", "reference distance to wall").
        required_arg("min_distance", "minimal distance to wall").
        required_arg("corners", "number of serving corners").
        optional_arg("timeout", "timeout for aborting wall servoing")        
    method(:serve_wall) do
    end

end
