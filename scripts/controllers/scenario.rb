require 'models/actions/spacebot.rb'
require 'petri_net'
require_relative './mission_analyser.rb'

probs = {"grab_state-success" => 0.2,
    "move_state-success" => 0.1,
    "grab_state-failed" => 0.4,
#    "goto_state-success" => 0.5,
    "back_off_state-success" => 0.25,
#    "move_state-failed" => 0.7}
}

ma = MissionAnalyser.new
net = ma.generatePetriNet Main.find_action_by_name('machine').coordination_model, 'maschine'
ma.merge(MissionAnalyser.generatePetriNet(Main.find_action_by_name('grabing2').coordination_model, 'grabing2'))
#net = generatePetriNet Main.find_action_by_name('grabing').coordination_model, 'grabing'
#net = generatePetriNet Main.find_action_by_name('grabing2').coordination_model, 'grabing2'
#net = generatePetriNet Main.find_action_by_name('parallel').coordination_model, 'parallel'
#ma.addProbabilities(net, probs)
#puts net.to_s
ma.get_net.to_gv_new
ma.get_net.generate_reachability_graph.to_gv
ma.analyse
#exit(0)
