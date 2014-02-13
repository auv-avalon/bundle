require "models/profiles/avalon_simulation_fast/main"

class Main < Roby::Actions::Interface
    use_profile Avalon::Profiles::SimulationFast

end
