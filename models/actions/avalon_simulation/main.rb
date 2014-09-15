require "models/profiles/avalon_simulation/main"
#require "models/actions/main"

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
    
    describe("foo")
    state_machine "sim_test_structure_align" do
        set = state sim_setter_def(:node => "avalon", :posX => -50, :posY => 24.5, :posZ => -8, :rotZ => 90) 
        detector = state structure_inspection_def
        start set
        transition(set.success_event, detector)
    end
    
    describe("foo")
    state_machine "sim_test_gate" do
        set = state sim_setter_def(:node => "avalon", :posX => -53, :posY => 25, :posZ => -3.5, :rotZ => 180) 
#        detector = state buoy_detector_def 
        start set
 #       transition(set.success_event, detector)
    end
  
    describe("foo")
    state_machine "sim_test_buoy_wall" do
        set = state sim_setter_def(:node => "avalon", :posX => -3, :posY => 25, :posZ => -1.5, :rotZ => 90) 
 #       detector = state buoy_wall
        start set
  #      transition(set.success_event, detector)
    end
end

require "auv/models/actions/main"
