require 'petri_net'
def generatePetriNet_old(coordination_model)

    net = PetriNet::Net.new(:name => 'test', :description => 'test-petrinet')
    coordination_model.all_transition.each do |s1,e,s2|
        place1 = PetriNet::Place.new(:name => s1.name)
        place2 = PetriNet::Place.new(:name => s2.name)
        transition = PetriNet::Transition.new(:name => e.task_model.name + "-" + e.symbol)
        net << place1
        net << place2
        net << transition
        net << PetriNet::Arc.new do |a|
            a.name = s1.name + "->" + e.task_model.name + e.symbol
            a.weight = 1
            a.add_source(net.get_place s1.name)
            a.add_destination(net.get_transition e.task_model.name + "-" + e.symbol)
        end
        net << PetriNet::Arc.new do |a|
            a.name = e.task_model.name + e.symbol + "->" + s2.name
            a.weight = 1
            a.add_source(net.get_transition(e.task_model.name + "-" + e.symbol))
            a.add_destination(net.get_place(s2.name))
        end
    end
    net.get_place(coordination_model.starting_state.name).add_marking
#    puts net
    net 
end

def addProbabilities(net, probabilities)
    probabilities.each do |trans,prob|
        t = net.get_transition(trans)
        t.probability = prob
    end
end

#def generatePetriNet2(coordination_model, coordination_model2)
#
#    net = PetriNet::Net.new(:name => 'test', :description => 'test-petrinet')
#    coordination_model.all_transition.each do |s1,e,s2|
#        place1 = PetriNet::Place.new(:name => s1.name)
#        place2 = PetriNet::Place.new(:name => s2.name)
#        transition = PetriNet::Transition.new(:name => e.task_model.name + "-" + e.symbol)
#        net << place1
#        net << place2
#        net << transition
#        net << PetriNet::Arc.new do |a|
#            a.name = s1.name + "->" + e.task_model.name + e.symbol
#            a.weight = 1
#            a.add_source(net.objects[net.places[s1.name]])
#            a.add_destination(net.objects[net.transitions[e.task_model.name + "-" + e.symbol]])
#        end
#        net << PetriNet::Arc.new do |a|
#            a.name = e.task_model.name + e.symbol + "->" + s2.name
#            a.weight = 1
#            a.add_source(net.objects[net.transitions[e.task_model.name + "-" + e.symbol]])
#            a.add_destination(net.objects[net.places[s2.name]])
#        end
#    end
#    coordination_model2.all_transition.each do |s1,e,s2|
#        place1 = PetriNet::Place.new(:name => s1.name)
#        place2 = PetriNet::Place.new(:name => s2.name)
#        transition = PetriNet::Transition.new(:name => e.task_model.name + "-" + e.symbol)
#        net << place1
#        net << place2
#        net << transition
 ##       net << PetriNet::Arc.new do |a|
 #           a.name = s1.name + "->" + e.task_model.name + e.symbol
 #           a.weight = 1
 #           a.add_source(net.objects[net.places[s1.name]])
 #           a.add_destination(net.objects[net.transitions[e.task_model.name + "-" + e.symbol]])
 #       end
 #       net << PetriNet::Arc.new do |a|
 #           a.name = e.task_model.name + e.symbol + "->" + s2.name
 #           a.weight = 1
 #           a.add_source(net.objects[net.transitions[e.task_model.name + "-" + e.symbol]])
 #           a.add_destination(net.objects[net.places[s2.name]])
 #       end
 #   end
##    puts net
 #   puts net.to_gv
#end
