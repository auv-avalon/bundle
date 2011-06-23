load_system_model 'tasks/data_services/base'

# -----------------------------------------------------------------------------
# Low-Level actuator interface 
# -----------------------------------------------------------------------------

data_service_type 'Actuators' do 
  input_port('command', 'base/actuators/Command')
  output_port('status', 'base/actuators/Status')
end

data_service_type 'ActuatorController' do
  output_port('actuator_command', 'base/actuators/Command')
end


# ----------------------------------------------------------------------------
# High-Level command interface
# ----------------------------------------------------------------------------

data_service_type 'Command'

data_service_type 'MotionInput' do
  input_port('pose_samples', '/base/samples/RigidBodyState')
  input_port('motion_commands', '/base/AUVMotionCommand')
end

data_service_type 'RelativePositionCommand' do
  output_port 'relative_position_command', 'base/AUVPositionCommand'
end

data_service_type 'AbsolutePositionCommand' do
  output_port 'absolute_position_command', 'base/AUVPositionCommand'
end



