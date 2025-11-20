# frozen_string_literal: true

require_relative "ruby_slm/version"
require_relative "ruby_slm/errors"
require_relative "ruby_slm/state_machine"
require_relative "ruby_slm/state"
require_relative "ruby_slm/execution"

# State implementations
require_relative "ruby_slm/states/base"
require_relative "ruby_slm/states/task"
require_relative "ruby_slm/states/choice"
require_relative "ruby_slm/states/wait"
require_relative "ruby_slm/states/parallel"
require_relative "ruby_slm/states/pass"
require_relative "ruby_slm/states/succeed"
require_relative "ruby_slm/states/fail"

module StatesLanguageMachine
  class << self
    # Create a state machine from a YAML string
    # @param yaml_string [String] the YAML definition of the state machine
    # @return [StateMachine] the parsed state machine
    def from_yaml(yaml_string)
      StateMachine.new(yaml_string)
    end

    # Create a state machine from a YAML file
    # @param file_path [String] the path to the YAML file
    # @return [StateMachine] the parsed state machine
    def from_yaml_file(file_path)
      yaml_content = File.read(file_path)
      StateMachine.new(yaml_content)
    end

    # Create a state machine from a JSON string
    # @param json_string [String] the JSON definition of the state machine
    # @return [StateMachine] the parsed state machine
    def from_json(json_string)
      StateMachine.new(json_string, format: :json)
    end

    # Create a state machine from a Hash
    # @param hash [Hash] the Hash definition of the state machine
    # @return [StateMachine] the parsed state machine
    def from_hash(hash)
      StateMachine.new(hash, format: :hash)
    end
  end
end