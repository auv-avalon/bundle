require "models/profiles/avalon_simulation/main"
#require "models/actions/sim"

class Main < Roby::Actions::Interface
    use_profile Avalon::Profiles::Simulation

    describe("foo")
    state_machine "sim_test_structure" do
        set = state sim_setter_def(:node => "avalon", :posX => -50, :posY => 20, :posZ => -10, :rotZ => 90) 
        detector = state structure_inspection_def
        start set
        transition(set.success_event, detector)
    end
end
