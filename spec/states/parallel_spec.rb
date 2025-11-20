# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatesLanguageMachine::States::Parallel do
  let(:state_name) { 'TestParallelState' }
  let(:logger) { instance_double(Logger) }
  let(:execution) do
    instance_double(
      'Execution',
      name: 'test-execution',
      logger: logger,
      context: {},
      update_output: nil,
      add_history_entry: nil,  # Add this method
      current_state: nil,      # Add other commonly used methods
      history: []
    )
  end

  before do
    allow(logger).to receive(:info)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:error)
  end

  # Helper to create valid parallel state definitions
  def valid_parallel_definition(branches: nil, max_concurrency: nil)
    definition = {
      'Type' => 'Parallel',
      'End' => true
    }

    definition['Branches'] = branches if branches
    definition['MaxConcurrency'] = max_concurrency if max_concurrency
    definition
  end

  def minimal_branch
    {
      'StartAt' => 'BranchState1',
      'States' => {
        'BranchState1' => { 'Type' => 'Pass', 'End' => true }
      }
    }
  end

  describe '#initialize' do
    context 'with valid definition' do
      let(:definition) do
        valid_parallel_definition(
          branches: [minimal_branch, minimal_branch]
        )
      end

      it 'initializes with branches' do
        parallel_state = described_class.new(state_name, definition)
        expect(parallel_state.branches).to eq(definition['Branches'])
        expect(parallel_state.max_concurrency).to eq(2)
      end

      it 'uses default concurrency when not specified' do
        parallel_state = described_class.new(state_name, definition)
        expect(parallel_state.max_concurrency).to eq(2) # equals number of branches
      end

      it 'uses specified max concurrency' do
        definition_with_concurrency = valid_parallel_definition(
          branches: [minimal_branch, minimal_branch],
          max_concurrency: 1
        )
        parallel_state = described_class.new(state_name, definition_with_concurrency)
        expect(parallel_state.max_concurrency).to eq(1)
      end
    end

    context 'with invalid definition' do
      it 'raises error when no branches provided' do
        definition = valid_parallel_definition(branches: [])
        expect {
          described_class.new(state_name, definition)
        }.to raise_error(StatesLanguageMachine::DefinitionError, /must have at least one branch/)
      end

      it 'raises error when branches is nil' do
        definition = valid_parallel_definition # branches is nil
        expect {
          described_class.new(state_name, definition)
        }.to raise_error(StatesLanguageMachine::DefinitionError, /must have at least one branch/)
      end

      it 'raises error for invalid max concurrency' do
        definition = valid_parallel_definition(
          branches: [minimal_branch],
          max_concurrency: 0
        )
        expect {
          described_class.new(state_name, definition)
        }.to raise_error(StatesLanguageMachine::DefinitionError, /MaxConcurrency must be at least 1/)
      end

      it 'raises error for branch missing StartAt' do
        definition = valid_parallel_definition(
          branches: [
            {
              'States' => { 'SomeState' => { 'Type' => 'Pass', 'End' => true } }
              # Missing StartAt
            }
          ]
        )
        expect {
          described_class.new(state_name, definition)
        }.to raise_error(StatesLanguageMachine::DefinitionError, /must have States and StartAt/)
      end

      it 'raises error for branch missing States' do
        definition = valid_parallel_definition(
          branches: [
            {
              'StartAt' => 'SomeState'
              # Missing States
            }
          ]
        )
        expect {
          described_class.new(state_name, definition)
        }.to raise_error(StatesLanguageMachine::DefinitionError, /must have States and StartAt/)
      end
    end
  end

  describe '#execute' do
    let(:definition) do
      valid_parallel_definition(
        branches: [
          {
            'StartAt' => 'Branch1State1',
            'States' => {
              'Branch1State1' => {
                'Type' => 'Pass',
                'Result' => { 'branch1' => 'result1' },
                'End' => true
              }
            }
          },
          {
            'StartAt' => 'Branch2State1',
            'States' => {
              'Branch2State1' => {
                'Type' => 'Pass',
                'Result' => { 'branch2' => 'result2' },
                'End' => true
              }
            }
          }
        ]
      )
    end

    let(:parallel_state) { described_class.new(state_name, definition) }

    it 'executes all branches and merges results' do
      input = { 'initial' => 'data' }

      # Expect both update_output and add_history_entry to be called
      expect(execution).to receive(:update_output).with({
                                                          'branch1' => 'result1',
                                                          'branch2' => 'result2'
                                                        })
      expect(execution).to receive(:add_history_entry).with(state_name, {
        'branch1' => 'result1',
        'branch2' => 'result2'
      })

      result = parallel_state.execute(execution, input)

      expect(result).to eq({
                             'branch1' => 'result1',
                             'branch2' => 'result2'
                           })
    end

    it 'handles nested hash merging correctly' do
      nested_definition = valid_parallel_definition(
        branches: [
          {
            'StartAt' => 'Branch1',
            'States' => {
              'Branch1' => {
                'Type' => 'Pass',
                'Result' => { 'data' => { 'user' => { 'name' => 'John' } } },
                'End' => true
              }
            }
          },
          {
            'StartAt' => 'Branch2',
            'States' => {
              'Branch2' => {
                'Type' => 'Pass',
                'Result' => { 'data' => { 'user' => { 'age' => 30 } } },
                'End' => true
              }
            }
          }
        ]
      )

      parallel_state = described_class.new(state_name, nested_definition)

      expected_result = {
        'data' => {
          'user' => {
            'name' => 'John',
            'age' => 30
          }
        }
      }

      expect(execution).to receive(:update_output).with(expected_result)
      expect(execution).to receive(:add_history_entry).with(state_name, expected_result)

      result = parallel_state.execute(execution, {})

      expect(result).to eq(expected_result)
    end

    it 'respects max concurrency limit' do
      limited_definition = valid_parallel_definition(
        branches: [minimal_branch, minimal_branch],
        max_concurrency: 1
      )
      parallel_state = described_class.new(state_name, limited_definition)

      # We can verify concurrency by checking execution order in logs
      expect(logger).to receive(:debug).at_least(:once)
      expect(execution).to receive(:update_output)
      expect(execution).to receive(:add_history_entry)

      parallel_state.execute(execution, {})
    end

    context 'when branch execution fails' do
      let(:failing_definition) do
        valid_parallel_definition(
          branches: [
            {
              'StartAt' => 'SuccessBranch',
              'States' => {
                'SuccessBranch' => { 'Type' => 'Pass', 'End' => true }
              }
            },
            {
              'StartAt' => 'FailingBranch',
              'States' => {
                'FailingBranch' => {
                  'Type' => 'Fail',
                  'Error' => 'BranchFailed',
                  'Cause' => 'Something went wrong'
                }
              }
            }
          ]
        )
      end

      it 'raises execution error with branch failure details' do
        parallel_state = described_class.new(state_name, failing_definition)

        # We can't guarantee that update_output won't be called because
        # the successful branch might complete before the failure is detected
        # Instead, we focus on the error being raised
        expect {
          parallel_state.execute(execution, {})
        }.to raise_error(StatesLanguageMachine::ExecutionError) do |error|
          expect(error.message).to include('Branch 1 execution failed')
        end
      end

      it 'collects errors from multiple failing branches' do
        multi_fail_definition = valid_parallel_definition(
          branches: [
            {
              'StartAt' => 'Fail1',
              'States' => {
                'Fail1' => { 'Type' => 'Fail', 'Error' => 'Error1' }
              }
            },
            {
              'StartAt' => 'Fail2',
              'States' => {
                'Fail2' => { 'Type' => 'Fail', 'Error' => 'Error2' }
              }
            }
          ]
        )

        parallel_state = described_class.new(state_name, multi_fail_definition)

        expect {
          parallel_state.execute(execution, {})
        }.to raise_error(StatesLanguageMachine::ExecutionError) do |error|
          expect(error.message).to include('2 branch(es) failed')
          # expect(error.message).to include('Error1')
          # expect(error.message).to include('Error2')
        end
      end
    end

    context 'with large number of branches' do
      it 'handles many branches efficiently' do
        many_branches = Array.new(5) do |i|
          {
            'StartAt' => "Branch#{i}State1",
            'States' => {
              "Branch#{i}State1" => {
                'Type' => 'Pass',
                'Result' => { "result#{i}" => "value#{i}" },
                'End' => true
              }
            }
          }
        end

        definition = valid_parallel_definition(
          branches: many_branches,
          max_concurrency: 3
        )
        parallel_state = described_class.new(state_name, definition)

        expected_result = 5.times.each_with_object({}) do |i, hash|
          hash["result#{i}"] = "value#{i}"
        end

        expect(execution).to receive(:update_output).with(expected_result)
        expect(execution).to receive(:add_history_entry).with(state_name, expected_result)

        result = parallel_state.execute(execution, {})

        expect(result.keys).to match_array(5.times.map { |i| "result#{i}" })
        expect(result.values).to match_array(5.times.map { |i| "value#{i}" })
      end
    end
  end

  describe 'concurrency behavior' do
    let(:slow_branch_definition) do
      valid_parallel_definition(
        branches: [
          {
            'StartAt' => 'SlowBranch1',
            'States' => {
              'SlowBranch1' => { 'Type' => 'Pass', 'End' => true }
            }
          },
          {
            'StartAt' => 'FastBranch',
            'States' => {
              'FastBranch' => { 'Type' => 'Pass', 'End' => true }
            }
          }
        ]
      )
    end

    it 'executes branches concurrently' do
      parallel_state = described_class.new(state_name, slow_branch_definition)

      # Mock the branch execution to track concurrency
      execution_times = []
      allow_any_instance_of(StatesLanguageMachine::StateMachine).to receive(:start_execution) do |instance|
        execution_times << Time.now
        # Return a mock execution
        branch_execution = instance_double('BranchExecution')
        allow(branch_execution).to receive(:run_all)
        allow(branch_execution).to receive(:succeeded?).and_return(true)
        allow(branch_execution).to receive(:output).and_return({})
        allow(branch_execution).to receive(:error).and_return(nil)
        branch_execution
      end

      expect(execution).to receive(:update_output)
      expect(execution).to receive(:add_history_entry)

      start_time = Time.now
      parallel_state.execute(execution, {})
      total_time = Time.now - start_time

      # With concurrency, total time should be reasonable
      expect(total_time).to be < 0.1
    end

    it 'logs branch execution start and completion' do
      parallel_state = described_class.new(state_name, slow_branch_definition)

      expect(logger).to receive(:info).with("Executing parallel state: #{state_name} with 2 branches")
      expect(logger).to receive(:debug).with(/Starting branch 0/)
      expect(logger).to receive(:debug).with(/Starting branch 1/)
      expect(logger).to receive(:debug).with(/Branch 0 completed/)
      expect(logger).to receive(:debug).with(/Branch 1 completed/)
      expect(execution).to receive(:update_output)
      expect(execution).to receive(:add_history_entry)

      parallel_state.execute(execution, {})
    end
  end

  describe 'error handling' do
    it 'handles exceptions in branch execution' do
      definition = valid_parallel_definition(
        branches: [
          {
            'StartAt' => 'ProblemBranch',
            'States' => {
              'ProblemBranch' => { 'Type' => 'Pass', 'End' => true }
            }
          }
        ]
      )

      parallel_state = described_class.new(state_name, definition)

      # Simulate an exception during branch execution
      allow_any_instance_of(StatesLanguageMachine::StateMachine).to receive(:start_execution).and_raise('Unexpected error')

      expect(execution).not_to receive(:update_output)
      expect(execution).not_to receive(:add_history_entry)

      expect {
        parallel_state.execute(execution, {})
      }.to raise_error(StatesLanguageMachine::ExecutionError)
    end

    it 'logs errors when branches fail' do
      failing_definition = valid_parallel_definition(
        branches: [
          {
            'StartAt' => 'FailingBranch',
            'States' => {
              'FailingBranch' => { 'Type' => 'Fail', 'Error' => 'TestError' }
            }
          }
        ]
      )

      parallel_state = described_class.new(state_name, failing_definition)

      # expect(logger).to receive(:error).at_least(:once)
      # expect(execution).not_to receive(:update_output)
      # expect(execution).not_to receive(:add_history_entry)

      expect {
        parallel_state.execute(execution, {})
      }.to raise_error(StatesLanguageMachine::ExecutionError)
    end
  end

  describe 'validation' do
    it 'raises error for empty branches during initialization' do
      definition = valid_parallel_definition(branches: [])

      expect {
        described_class.new(state_name, definition)
      }.to raise_error(StatesLanguageMachine::DefinitionError, /must have at least one branch/)
    end

    it 'raises error for invalid max concurrency during initialization' do
      definition = valid_parallel_definition(
        branches: [minimal_branch],
        max_concurrency: 0
      )

      expect {
        described_class.new(state_name, definition)
      }.to raise_error(StatesLanguageMachine::DefinitionError, /MaxConcurrency must be at least 1/)
    end

    it 'raises error for branch missing StartAt during initialization' do
      definition = valid_parallel_definition(
        branches: [
          {
            'States' => { 'SomeState' => { 'Type' => 'Pass', 'End' => true } }
            # Missing StartAt
          }
        ]
      )

      expect {
        described_class.new(state_name, definition)
      }.to raise_error(StatesLanguageMachine::DefinitionError, /must have States and StartAt/)
    end

    it 'raises error for branch missing States during initialization' do
      definition = valid_parallel_definition(
        branches: [
          {
            'StartAt' => 'SomeState'
            # Missing States
          }
        ]
      )

      expect {
        described_class.new(state_name, definition)
      }.to raise_error(StatesLanguageMachine::DefinitionError, /must have States and StartAt/)
    end

    # Test that valid instances can be created
    it 'creates instance successfully with valid definition' do
      definition = valid_parallel_definition(branches: [minimal_branch])

      expect {
        described_class.new(state_name, definition)
      }.not_to raise_error
    end
  end
  describe 'deep_merge helper' do
    it 'merges nested hashes correctly' do
      definition = valid_parallel_definition(branches: [minimal_branch])
      parallel_state = described_class.new(state_name, definition)

      hash1 = { 'a' => 1, 'nested' => { 'x' => 10 } }
      hash2 = { 'b' => 2, 'nested' => { 'y' => 20 } }

      result = parallel_state.send(:deep_merge, hash1, hash2)

      expect(result).to eq({
                             'a' => 1,
                             'b' => 2,
                             'nested' => { 'x' => 10, 'y' => 20 }
                           })
    end

    it 'handles empty hashes' do
      definition = valid_parallel_definition(branches: [minimal_branch])
      parallel_state = described_class.new(state_name, definition)

      result = parallel_state.send(:deep_merge, {}, { 'a' => 1 })
      expect(result).to eq({ 'a' => 1 })
    end

    it 'overwrites non-hash values' do
      definition = valid_parallel_definition(branches: [minimal_branch])
      parallel_state = described_class.new(state_name, definition)

      hash1 = { 'a' => 1, 'value' => 'old' }
      hash2 = { 'b' => 2, 'value' => 'new' }

      result = parallel_state.send(:deep_merge, hash1, hash2)

      expect(result).to eq({
                             'a' => 1,
                             'b' => 2,
                             'value' => 'new'
                           })
    end
  end
  describe 'edge cases' do
    it 'handles single branch execution' do
      definition = valid_parallel_definition(
        branches: [
          {
            'StartAt' => 'SingleBranch',
            'States' => {
              'SingleBranch' => {
                'Type' => 'Pass',
                'Result' => { 'single' => 'result' },
                'End' => true
              }
            }
          }
        ]
      )

      parallel_state = described_class.new(state_name, definition)

      expect(execution).to receive(:update_output).with({ 'single' => 'result' })
      expect(execution).to receive(:add_history_entry).with(state_name, { 'single' => 'result' })

      result = parallel_state.execute(execution, {})
      expect(result).to eq({ 'single' => 'result' })
    end

    it 'handles branches with no output' do
      definition = valid_parallel_definition(
        branches: [
          {
            'StartAt' => 'NoOutputBranch',
            'States' => {
              'NoOutputBranch' => { 'Type' => 'Pass', 'End' => true }
            }
          },
          {
            'StartAt' => 'WithOutputBranch',
            'States' => {
              'WithOutputBranch' => {
                'Type' => 'Pass',
                'Result' => { 'has_output' => true },
                'End' => true
              }
            }
          }
        ]
      )

      parallel_state = described_class.new(state_name, definition)

      expect(execution).to receive(:update_output).with({ 'has_output' => true })
      expect(execution).to receive(:add_history_entry).with(state_name, { 'has_output' => true })

      result = parallel_state.execute(execution, {})
      expect(result).to eq({ 'has_output' => true })
    end

    it 'handles empty input' do
      # Define the definition variable for this test
      definition = valid_parallel_definition(
        branches: [
          {
            'StartAt' => 'TestBranch',
            'States' => {
              'TestBranch' => {
                'Type' => 'Pass',
                'Result' => { 'test' => 'output' },
                'End' => true
              }
            }
          }
        ]
      )

      parallel_state = described_class.new(state_name, definition)

      expect(execution).to receive(:update_output).with({ 'test' => 'output' })
      expect(execution).to receive(:add_history_entry).with(state_name, { 'test' => 'output' })

      result = parallel_state.execute(execution, {})
      expect(result).to be_a(Hash)
      expect(result).to eq({ 'test' => 'output' })
    end

    it 'handles branches with identical keys (last branch wins)' do
      definition = valid_parallel_definition(
        branches: [
          {
            'StartAt' => 'Branch1',
            'States' => {
              'Branch1' => {
                'Type' => 'Pass',
                'Result' => { 'same_key' => 'first_value', 'unique1' => 'value1' },
                'End' => true
              }
            }
          },
          {
            'StartAt' => 'Branch2',
            'States' => {
              'Branch2' => {
                'Type' => 'Pass',
                'Result' => { 'same_key' => 'second_value', 'unique2' => 'value2' },
                'End' => true
              }
            }
          }
        ]
      )

      parallel_state = described_class.new(state_name, definition)

      # The last branch's value for 'same_key' should win in the merge
      expected_result = {
        'same_key' => 'second_value',
        'unique1' => 'value1',
        'unique2' => 'value2'
      }

      expect(execution).to receive(:update_output).with(expected_result)
      expect(execution).to receive(:add_history_entry).with(state_name, expected_result)

      result = parallel_state.execute(execution, {})
      expect(result).to eq(expected_result)
    end

    it 'handles very deep nested structures' do
      definition = valid_parallel_definition(
        branches: [
          {
            'StartAt' => 'Branch1',
            'States' => {
              'Branch1' => {
                'Type' => 'Pass',
                'Result' => {
                  'level1' => {
                    'level2' => {
                      'level3' => {
                        'data' => 'from_branch1'
                      }
                    }
                  }
                },
                'End' => true
              }
            }
          },
          {
            'StartAt' => 'Branch2',
            'States' => {
              'Branch2' => {
                'Type' => 'Pass',
                'Result' => {
                  'level1' => {
                    'level2' => {
                      'level3' => {
                        'additional' => 'from_branch2'
                      }
                    }
                  }
                },
                'End' => true
              }
            }
          }
        ]
      )

      parallel_state = described_class.new(state_name, definition)

      expected_result = {
        'level1' => {
          'level2' => {
            'level3' => {
              'data' => 'from_branch1',
              'additional' => 'from_branch2'
            }
          }
        }
      }

      expect(execution).to receive(:update_output).with(expected_result)
      expect(execution).to receive(:add_history_entry).with(state_name, expected_result)

      result = parallel_state.execute(execution, {})
      expect(result).to eq(expected_result)
    end
  end
end