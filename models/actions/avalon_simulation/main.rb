require "models/profiles/avalon_simulation/main"
#require "models/actions/main"

#require "models/actions/sim"

class Main < Roby::Actions::Interface
    use_profile Avalon::Profiles::Simulation

    
    describe("foo")
    state_machine "sim_test_structure" do
        set = state sim_setter_def(:node => "avalon", :posX => -45, :posY => 20, :posZ => -10, :rotZ => 90) 
        detector = state structure_inspection_def
        start set
        transition(set.success_event, detector)
        forward detector.success_event, success_event
    end
    
    describe("foo")
    state_machine "sim_test_structure_align" do
        set = state sim_setter_def(:node => "avalon", :posX => -45, :posY => 24.5, :posZ => -8, :rotZ => 90) 
        detector = state structure_alignment_def 
        start set
        transition(set.success_event, detector)
        forward detector.success_event, success_event
    end
    
    describe("foo")
    state_machine "sim_test_gate" do
        set = state sim_setter_def(:node => "avalon", :posX => -53, :posY => 25, :posZ => -3.5, :rotZ => 180) 
        detector = state buoy_detector_def 
        start set
        transition(set.success_event, detector)
        forward detector.success_event, success_event
    end
  
end

require "auv/models/actions/main"

#Here are comming actions that depending on statemachines
class Main 
    describe("foo")
    state_machine "sim_test_buoy_wall" do
        set = state sim_setter_def(:node => "avalon", :posX => -3, :posY => 25, :posZ => -1.5, :rotZ => 0) 
        detector = state buoy_wall
        start set
        transition(set.success_event, detector)
        forward detector.success_event, success_event
    end
    describe("foo")
    state_machine "sim_test_sauce" do
        set = state sim_setter_def(:node => "avalon", :posX => -45, :posY => 2.5, :posZ => 0, :rotZ => 90) 
        sauce = state win
        start set
        transition(set.success_event, sauce)
        forward sauce.success_event, success_event
    end
    describe("fara")
    state_machine "sim_test_wall" do
        set = state sim_setter_def(:node => "avalon", :posX => -45, :posY => 25, :posZ => -1.5, :rotZ => 0) 
        wall = state win(:start_state => "wall")
        start set 
        transition(set.success_event, wall)
        forward set.success_event, success_event
    end
    describe("foo")
    state_machine "sim_test_blackbox" do
        set = state sim_setter_def(:node => "avalon", :posX => -20, :posY => 5, :posZ => -1.5, :rotZ => 0) 
        box = state win(:start_state => 'blackbox')
        start set
        transition(set.success_event, box)
        forward box.success_event, success_event
    end
end
