class AvalonModelParameter
end

class UwvDynamicModel::Task
    def configure
        # We need to set the model parameters before calling the
        # configure hook because they are used in there.
        puts "UwvDynamicModel: Initializing vehicle parameters ..."
        task = Orocos::TaskContext.get self.orocos_name

        # Get parameter property
        parameters = task.uwv_param

        # Set parameters
        AvalonModelParameters::intialise_vehicle_parameters(parameters)

        # Update parameter property
        task.uwv_param = parameters
    end
end


class AvalonModelParameters
    # UWV dimensional parameters
    def self.vehicle_dimensional_parameters(task)
        # vector position from the origin of body-fixed frame to center of buoyancy in body-fixed frame
        task.distance_body2centerofbuoyancy[0] = 0;
        task.distance_body2centerofbuoyancy[1] = 0;
        task.distance_body2centerofbuoyancy[2] = 0;

        # vector position from the origin of body-fixed frame to center of gravity in body-fixed frame
        task.distance_body2centerofgravity[0] = 0;
        task.distance_body2centerofgravity[1] = 0;
        task.distance_body2centerofgravity[2] = 0;
    end

    # UWV physical parameters
    def self.vehicle_physical_parameters(task)
        task.uwv_mass = 68 		# total mass of the vehicle in kg
        task.uwv_volume = ((0.445+0.56)*0.13*0.13*Math::PI+0.41*Math::PI*0.18*0.18)#(2*(0.55*0.15*0.15*Math::PI)+0.30*Math::PI*0.15*0.15) # total volume of the vehicle - considered as two cylinders and center as cylinder
        task.uwv_float = true		# to assume that the vehicle floats . i.e gravity == buoyancy
    end

    # Environment parameters
    def self.environmental_parameters(task)
        task.waterDensity = 998.2	# density of pure water at 20°C in kg/m^3
        task.gravity = 9.81
    end

    # UWV interia + added mass Matrix
    # consider Avalon as one big cylinder
    def self.mass_matrix(task)
#        task.mass_matrix = [7.48,0,0,0,0,0,  0,16.29,0,0,0,0,  0,0,16.29,0,0,0,  0,0,0,0.61,0,0,  0,0,0,0,1.67,0,  0,0,0,0,0,1.67]
         task.massCoefficient[0].positive = 7.49
         task.massCoefficient[0].negative = 7.49
         task.massCoefficient[1].positive = 16.29
         task.massCoefficient[1].negative = 16.29
         task.massCoefficient[2].positive = 16.29
         task.massCoefficient[2].negative = 16.29
         task.massCoefficient[3].positive = 0.61
         task.massCoefficient[3].negative = 0.61
         task.massCoefficient[4].positive = 1.67
         task.massCoefficient[4].negative = 1.67
         task.massCoefficient[5].positive = 1.67
         task.massCoefficient[5].negative = 1.67
    end

    # Linear damp coefficient
    def self.linDampCoeff(task)
#        task.linDampCoeff = [1.2832, 10, 10, 0, 1.7, 1.7 ]
	task.linDampCoeff[0].positive = 8.203187564
	task.linDampCoeff[0].negative = 8.203187564
	task.linDampCoeff[1].positive = 24.94216
	task.linDampCoeff[1].negative = 24.94216
	task.linDampCoeff[2].positive = 24
	task.linDampCoeff[2].negative = 24
	task.linDampCoeff[3].positive = 0.0
	task.linDampCoeff[3].negative = 0.0
	task.linDampCoeff[4].positive = 1.7
	task.linDampCoeff[4].negative = 1.7
	task.linDampCoeff[5].positive = 1.7
	task.linDampCoeff[5].negative = 1.7
    end

    # Quadratic damp coefficient
    def self.quadDampCoeff(task)
        # task.quadDampCoeff = [8.962, 20, 20, 10, 50, 50]
	task.quadDampCoeff[0].positive = 0.04959
	task.quadDampCoeff[0].negative = 0.04959
	task.quadDampCoeff[1].positive = 0.042393
	task.quadDampCoeff[1].negative = 0.042393
	task.quadDampCoeff[2].positive = 0.04
	task.quadDampCoeff[2].negative = 0.04
	task.quadDampCoeff[3].positive = 10.0
	task.quadDampCoeff[3].negative = 10.0
	task.quadDampCoeff[4].positive = 50.0
	task.quadDampCoeff[4].negative = 50.0
	task.quadDampCoeff[5].positive = 50.0
	task.quadDampCoeff[5].negative = 50.0
    end
    # ThrusterCoefficient
    def self.thrusterCoefficient(task)
        task.thruster_coefficient_pwm.surge.positive.coefficient_a = 0.005
        task.thruster_coefficient_pwm.surge.positive.coefficient_b = 0.005
        task.thruster_coefficient_pwm.surge.negative.coefficient_a = 0.005
        task.thruster_coefficient_pwm.surge.negative.coefficient_b = 0.005
 
        task.thruster_coefficient_pwm.sway.positive.coefficient_a = 0.005
        task.thruster_coefficient_pwm.sway.positive.coefficient_b = 0.005
        task.thruster_coefficient_pwm.sway.negative.coefficient_a = 0.005
        task.thruster_coefficient_pwm.sway.negative.coefficient_b = 0.005
 
        task.thruster_coefficient_pwm.heave.positive.coefficient_a = 0.005
        task.thruster_coefficient_pwm.heave.positive.coefficient_b = 0.005
        task.thruster_coefficient_pwm.heave.negative.coefficient_a = 0.005
        task.thruster_coefficient_pwm.heave.negative.coefficient_b = 0.005
 
        task.thruster_coefficient_pwm.roll.positive.coefficient_a = 0.0
        task.thruster_coefficient_pwm.roll.positive.coefficient_b = 0.0
        task.thruster_coefficient_pwm.roll.negative.coefficient_a = 0.0
        task.thruster_coefficient_pwm.roll.negative.coefficient_b = 0.0
 
        task.thruster_coefficient_pwm.pitch.positive.coefficient_a = 0.0
        task.thruster_coefficient_pwm.pitch.positive.coefficient_b = 0.0
        task.thruster_coefficient_pwm.pitch.negative.coefficient_a = 0.0
        task.thruster_coefficient_pwm.pitch.negative.coefficient_b = 0.0
 
        task.thruster_coefficient_pwm.yaw.positive.coefficient_a = 0.0
        task.thruster_coefficient_pwm.yaw.positive.coefficient_b = 0.0
        task.thruster_coefficient_pwm.yaw.negative.coefficient_a = 0.0
        task.thruster_coefficient_pwm.yaw.negative.coefficient_b = 0.0
    end

    # Thruster mapping
    def self.thruster_mapping(task)
        array_thruster_value = task.thruster_value.to_a
            array_thruster_value= [25.4 , 25.4, 25.4, 25.4 , 25.4, 25.4]
        task.thruster_value = array_thruster_value

        array_thruster_mapped_names = task.thruster_mapped_names.to_a
            #array_thruster_mapped_names= "SURGE,SURGE,SWAY,SWAY,HEAVE,HEAVE".split(/,/)
            array_thruster_mapped_names= ['HEAVE','HEAVE','SURGE','SURGE','SWAY','SWAY']
        task.thruster_mapped_names = array_thruster_mapped_names

    end

    # Thruster control matrix
    def self.thruster_control_matrix(task)
        task.thruster_control_matrix = [0,0,1,0,-0.92,0,  0,0,1,0,0.205,0,  1,0,0,0,0,-0.17,  1,0,0,0,0,0.17,  0,1,0,0,0,-0.81,  0,1,0,0,0,0.04]
    end

    # Simulation parameters
    def self.simulation_data(task)
        task.sim_per_cycle = 5					# number of RK4 simulations per sampling interval
        task.plant_order = 12					# plant order - number of states in the model - generally 12 states -> 3 position, 3 orientation and 6 linear&angular velocity
        task.ctrl_order = 5;					# ctrl order - number of controllable inputs
        task.samplingtime = 0.1;           				# sampling time used in simulation
        task.initial_condition = [ 0,0,0,0,0,0, 0,0,0,0,0,0];	# Initial conditions used for simulation - currently it 12 states
        task.initial_time = 0.0;              			# Initial time	used for simulation
    end

    def self.intialise_vehicle_parameters(task)
        vehicle_dimensional_parameters(task)
        vehicle_physical_parameters(task)
        mass_matrix(task)
        linDampCoeff(task)
        quadDampCoeff(task)
        thrusterCoefficient(task)
        thruster_mapping(task.thrusters)
        thruster_control_matrix(task)
        simulation_data(task)
        task.thrusterVoltage = 25.4

    end
end

