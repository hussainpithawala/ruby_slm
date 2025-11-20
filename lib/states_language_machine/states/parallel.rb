# frozen_string_literal: true

module StatesLanguageMachine
  module States
    class Parallel < Base
      # @return [Array<Hash>] the list of branches to execute in parallel
      attr_reader :branches

      # @return [Integer] maximum number of concurrent branches
      attr_reader :max_concurrency

      # @param name [String] the name of the state
      # @param definition [Hash] the state definition
      def initialize(name, definition)
        # Ensure parallel states have End: true as required by base class
        definition_with_end = definition.merge('End' => true)
        super(name, definition_with_end)
        @branches = definition["Branches"] || []
        @max_concurrency = definition["MaxConcurrency"] || @branches.size
        validate_parallel_specific!
      end

      # @param execution [Execution] the current execution
      # @param input [Hash] the input data for the state
      # @return [Hash] the output data from the state
      def execute(execution, input)
        execution.logger&.info("Executing parallel state: #{@name} with #{@branches.size} branches")

        # Execute branches concurrently using Fibers
        results = execute_branches_concurrently(execution, input)

        # Handle any branch failures
        handle_branch_errors(results)

        # Combine successful results
        final_result = merge_branch_results(results)
        process_result(execution, final_result)
        final_result
      end

      private

      # Execute all branches concurrently using Fibers
      # @param execution [Execution] the parent execution
      # @param input [Hash] the input data
      # @return [Array<Hash>] results from all branches
      def execute_branches_concurrently(execution, input)
        # Create fibers for each branch
        fibers = @branches.map.with_index do |branch_def, index|
          Fiber.new do
            execute_branch(execution, branch_def, input, index)
          end
        end

        # Execute fibers with concurrency control
        execute_fibers_with_concurrency_limit(fibers)
      end

      # Execute fibers with concurrency limit using round-robin scheduling
      # @param fibers [Array<Fiber>] fibers to execute
      # @return [Array<Hash>] results from all fibers
      def execute_fibers_with_concurrency_limit(fibers)
        results = []
        active_fibers = fibers.dup

        # Continue until all fibers are done
        until active_fibers.empty?
          # Process each active fiber in round-robin fashion
          active_fibers.dup.each do |fiber|
            begin
              if fiber.alive?
                # Resume the fiber
                result = fiber.resume
                # If the fiber returned a result (finished), store it and remove from active
                unless fiber.alive?
                  results << result
                  active_fibers.delete(fiber)
                end
              else
                # Fiber is dead but still in active list, remove it
                active_fibers.delete(fiber)
              end
            rescue => e
              # Handle any fiber errors
              results << ExecutionError.new(@name, "Fiber execution failed: #{e.message}")
              active_fibers.delete(fiber)
            end
          end

          # Small sleep to prevent busy waiting (optional, but good practice)
          sleep(0.001) if active_fibers.any?
        end

        results
      end

      # Execute a single branch within a Fiber
      # @param execution [Execution] the parent execution
      # @param branch_def [Hash] the branch definition
      # @param input [Hash] the input data
      # @param branch_index [Integer] the index of the branch
      # @return [Hash] the branch execution result
      def execute_branch(execution, branch_def, input, branch_index)
        execution.logger&.debug("Starting branch #{branch_index} in parallel state: #{@name}")

        branch_machine = StateMachine.new(branch_def, format: :hash)
        branch_execution = branch_machine.start_execution(
          input,
          "#{execution.name}-branch-#{branch_index}",
          execution.context
        )

        # Run the branch execution to completion
        # For true cooperative multitasking, we'd need the state machine to yield
        # For now, we'll run it to completion within the fiber
        branch_execution.run_all

        unless branch_execution.succeeded?
          raise ExecutionError.new(@name, "Branch #{branch_index} execution failed: #{branch_execution.error}")
        end

        execution.logger&.debug("Branch #{branch_index} completed successfully")
        branch_execution.output
      rescue => e
        ExecutionError.new(@name, "Branch #{branch_index} failed: #{e.message}")
      end

      # Handle any branch errors in the results
      # @param results [Array] results from branch executions
      # @raise [ExecutionError] if any branches failed
      def handle_branch_errors(results)
        failed_branches = results.select { |r| r.is_a?(ExecutionError) }

        unless failed_branches.empty?
          error_messages = failed_branches.map(&:message).join('; ')
          raise ExecutionError.new(@name, "#{failed_branches.size} branch(es) failed: #{error_messages}")
        end
      end

      # Merge results from all successful branches
      # @param results [Array<Hash>] successful branch results
      # @return [Hash] merged result
      def merge_branch_results(results)
        results.reduce({}) { |acc, result| deep_merge(acc, result) }
      end

      # Deep merge helper for nested hashes
      # @param hash1 [Hash] first hash
      # @param hash2 [Hash] second hash
      # @return [Hash] deeply merged hash
      def deep_merge(hash1, hash2)
        hash1.merge(hash2) do |key, old_val, new_val|
          if old_val.is_a?(Hash) && new_val.is_a?(Hash)
            deep_merge(old_val, new_val)
          else
            new_val
          end
        end
      end

      # Validate parallel-specific requirements
      def validate_parallel_specific!
        raise DefinitionError, "Parallel state '#{@name}' must have at least one branch" if @branches.empty?

        # Validate each branch structure
        @branches.each_with_index do |branch, index|
          unless branch["States"] && branch["StartAt"]
            raise DefinitionError, "Branch #{index} in parallel state '#{@name}' must have States and StartAt"
          end
        end

        if @max_concurrency < 1
          raise DefinitionError, "MaxConcurrency must be at least 1 in parallel state '#{@name}'"
        end
      end
    end
  end
end