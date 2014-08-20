require "models/profiles/avalon_simulation/main"
#require "models/actions/sim"

class Main < Roby::Actions::Interface
    use_profile Avalon::Profiles::Simulation

end
