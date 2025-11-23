#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'securerandom'

# Enhanced ComplexOrderProcessor with parallel processing capabilities
class ComplexOrderProcessor
  # Order Classification
  def determine_order_type(input)
    order = input['order'] || {}

    total = order['total'].to_f
    items = order['items'] || []
    quantity = order['quantity'].to_i

    puts "    [determine_order_type] Analyzing order: #{order['id']} - Total: $#{total}, Items: #{items.size}, Quantity: #{quantity}"

    # Business logic for order classification
    if total > 500 || order['premium_customer']
      { "order_type" => "premium", "reason" => "high_value_or_premium_customer" }
    elsif quantity > 10 || total > 1000
      { "order_type" => "bulk", "reason" => "large_quantity" }
    elsif order['shipping'] && order['shipping']['country'] != 'US'
      { "order_type" => "international", "reason" => "international_shipping" }
    elsif order['digital_product']
      { "order_type" => "digital", "reason" => "digital_product" }
    else
      { "order_type" => "standard", "reason" => "regular_order" }
    end
  end

  # Premium Order Processing
  def process_premium_order(input)
    order = input['order']
    puts "    [process_premium_order] VIP processing for: #{order['id']}"

    {
      "premium_processed" => true,
      "order_id" => order['id'],
      "vip_handling" => true,
      "dedicated_support" => true,
      "processing_tier" => "premium",
      "priority_level" => 1
    }
  end

  # Bulk Order Processing
  def check_bulk_inventory(input)
    order = input['order']
    required_quantity = input['required_quantity']

    puts "    [check_bulk_inventory] Checking bulk inventory for: #{order['id']}"

    # Simulate inventory check with occasional delays
    sleep(0.05) if rand(0..1) == 0 # Simulate API call

    available = rand(0..1) == 1
    {
      "available" => available,
      "checked_at" => Time.now.to_i,
      "required_quantity" => required_quantity,
      "available_quantity" => available ? required_quantity : 0,
      "warehouse" => "main_warehouse"
    }
  end

  def process_bulk_order(input)
    order = input['order']
    puts "    [process_bulk_order] Processing bulk order: #{order['id']}"

    {
      "bulk_processed" => true,
      "order_id" => order['id'],
      "volume_discount_applied" => true,
      "special_handling" => true,
      "bulk_tier" => "large"
    }
  end

  # International Order Processing
  def process_international_order(input)
    order = input['order']
    country = input['destination_country']

    puts "    [process_international_order] International processing for: #{order['id']} to #{country}"

    {
      "international_processed" => true,
      "order_id" => order['id'],
      "destination_country" => country,
      "export_documentation" => "required",
      "customs_declaration" => "needed",
      "requires_export_license" => country == 'IR' # Example restriction
    }
  end

  def calculate_customs_duty(input)
    order_value = input['order_value'].to_f
    country = input['country']

    puts "    [calculate_customs_duty] Calculating duty for $#{order_value} to #{country}"

    # Simple customs calculation
    duty_rate = case country
                when 'CA', 'MX' then 0.05
                when 'EU' then 0.15
                when 'UK' then 0.12
                else 0.10
                end

    duty_amount = order_value * duty_rate

    {
      "duty_calculated" => true,
      "duty_rate" => duty_rate,
      "duty_amount" => duty_amount,
      "total_with_duty" => order_value + duty_amount,
      "currency" => "USD",
      "calculation_method" => "standard"
    }
  end

  # Digital Order Processing
  def process_digital_order(input)
    order = input['order']
    puts "    [process_digital_order] Digital order processing: #{order['id']}"

    {
      "digital_processed" => true,
      "order_id" => order['id'],
      "product_type" => order['digital_product']['type'],
      "instant_delivery" => true,
      "digital_rights" => "granted"
    }
  end

  def generate_digital_access(input)
    puts "    [generate_digital_access] Generating access for: #{input['order_id']}"

    {
      "access_generated" => true,
      "order_id" => input['order_id'],
      "access_codes" => ["CODE-#{SecureRandom.hex(8)}"],
      "download_links" => ["https://download.example.com/#{SecureRandom.hex(4)}"],
      "license_key" => "LIC-#{SecureRandom.hex(12)}",
      "valid_until" => (Time.now + 365 * 24 * 60 * 60).to_i # 1 year
    }
  end

  # Standard Order Processing
  def process_standard_order(input)
    order = input['order']
    puts "    [process_standard_order] Standard processing: #{order['id']}"

    {
      "standard_processed" => true,
      "order_id" => order['id'],
      "processing_tier" => "standard",
      "service_level" => "normal"
    }
  end

  # Payment Processing with retry simulation
  def process_payment(input)
    amount = input['amount'].to_f
    payment_method = input['payment_method']

    puts "    [process_payment] Processing $#{amount} via #{payment_method}"

    # Simulate payment processing with retry scenarios
    @payment_attempts ||= {}
    order_id = input['order_id']
    @payment_attempts[order_id] ||= 0
    @payment_attempts[order_id] += 1

    # Fail first attempt for certain conditions to test retry
    if @payment_attempts[order_id] == 1 && amount > 1500
      raise "PaymentGatewayTimeout - Gateway busy, please retry"
    end

    success = amount < 2000 && payment_method != 'expired_card'

    if success
      {
        "status" => "completed",
        "payment_id" => "pay_#{SecureRandom.hex(8)}",
        "amount_charged" => amount,
        "currency" => input['currency'],
        "processed_at" => Time.now.to_i,
        "attempts" => @payment_attempts[order_id]
      }
    else
      raise "Payment declined: #{payment_method} cannot process $#{amount}"
    end
  end

  def wait_for_payment_confirmation(input)
    payment_id = input['payment_id']

    puts "    [wait_for_payment_confirmation] Waiting for confirmation: #{payment_id}"

    # Simulate waiting for confirmation
    sleep(0.1)

    {
      "confirmed" => true,
      "payment_id" => payment_id,
      "confirmation_code" => "CONF-#{SecureRandom.hex(6)}",
      "confirmed_at" => Time.now.to_i,
      "confirmation_method" => "3ds_secure"
    }
  end

  def finalize_payment(input)
    puts "    [finalize_payment] Finalizing: #{input['payment_id']}"

    {
      "finalized" => true,
      "payment_id" => input['payment_id'],
      "status" => "completed",
      "finalized_at" => Time.now.to_i,
      "settlement_initiated" => true
    }
  end

  # Inventory Management
  def update_inventory(input)
    order_id = input['order_id']
    items = input['items']

    puts "    [update_inventory] Updating inventory for: #{order_id}"

    # Simulate inventory update with occasional stock issues
    out_of_stock = rand(0..9) == 0 # 10% chance of out of stock

    if out_of_stock
      raise "OutOfStock - Item unavailable for order #{order_id}"
    else
      {
        "inventory_updated" => true,
        "order_id" => order_id,
        "items_processed" => items.size,
        "updated_at" => Time.now.to_i,
        "inventory_system" => "warehouse_db_v2"
      }
    end
  end

  # Shipping Methods
  def schedule_express_shipping(input)
    order = input['order']
    puts "    [schedule_express_shipping] Express shipping for: #{order['id']}"

    {
      "shipping_scheduled" => true,
      "order_id" => order['id'],
      "method" => "express",
      "estimated_days" => 1,
      "tracking_number" => "EXP#{SecureRandom.hex(6).upcase}",
      "priority" => "high",
      "carrier" => "fedex_priority"
    }
  end

  def schedule_standard_shipping(input)
    order = input['order']
    puts "    [schedule_standard_shipping] Standard shipping for: #{order['id']}"

    {
      "shipping_scheduled" => true,
      "order_id" => order['id'],
      "method" => "standard",
      "estimated_days" => 3,
      "tracking_number" => "STD#{SecureRandom.hex(6).upcase}",
      "carrier" => "ups_ground"
    }
  end

  def schedule_economy_shipping(input)
    order = input['order']
    puts "    [schedule_economy_shipping] Economy shipping for: #{order['id']}"

    {
      "shipping_scheduled" => true,
      "order_id" => order['id'],
      "method" => "economy",
      "estimated_days" => 7,
      "tracking_number" => "ECO#{SecureRandom.hex(6).upcase}",
      "carrier" => "usps_parcel"
    }
  end

  # Digital Delivery
  def send_digital_delivery(input)
    order = input['order']
    puts "    [send_digital_delivery] Sending digital delivery: #{order['id']}"

    {
      "digital_delivered" => true,
      "order_id" => order['id'],
      "customer_email" => input['customer_email'],
      "delivery_method" => "email",
      "sent_at" => Time.now.to_i,
      "delivery_status" => "sent"
    }
  end

  # Parallel Processing Methods
  def send_customer_notifications(input)
    order = input['order']
    puts "    [send_customer_notifications] Sending notifications: #{order['id']}"

    {
      "notifications_sent" => true,
      "order_id" => order['id'],
      "email_sent" => true,
      "sms_sent" => true,
      "push_notification_sent" => true,
      "notification_timestamp" => Time.now.to_i
    }
  end

  def update_customer_profile(input)
    order = input['order']
    puts "    [update_customer_profile] Updating profile: #{order['customer_id']}"

    {
      "profile_updated" => true,
      "customer_id" => order['customer_id'],
      "order_count_incremented" => true,
      "loyalty_points_added" => (order['total'].to_i / 10),
      "last_order_date" => Time.now.to_i
    }
  end

  def generate_analytics(input)
    order = input['order']
    puts "    [generate_analytics] Generating analytics: #{order['id']}"

    {
      "analytics_generated" => true,
      "order_id" => order['id'],
      "revenue_tracked" => order['total'],
      "customer_segment" => order['total'] > 100 ? "high_value" : "standard",
      "analytics_timestamp" => Time.now.to_i
    }
  end

  def process_loyalty_points(input)
    order = input['order']
    puts "    [process_loyalty_points] Processing loyalty: #{order['customer_id']}"

    points = (order['total'].to_i / 5).to_i # 1 point per $5

    {
      "loyalty_processed" => true,
      "customer_id" => order['customer_id'],
      "points_earned" => points,
      "total_points" => rand(100..1000) + points,
      "tier_checked" => true
    }
  end

  # Notifications
  def send_order_confirmation(input)
    order = input['order']
    puts "    [send_order_confirmation] Sending confirmation: #{order['id']}"

    {
      "confirmation_sent" => true,
      "order_id" => order['id'],
      "customer_id" => input['customer'],
      "sent_via" => ["email", "sms"],
      "confirmation_id" => "CONF-#{SecureRandom.hex(6)}",
      "template_used" => "order_confirmation_v2"
    }
  end

  # Error Handling Methods
  def handle_classification_error(input)
    puts "    [handle_classification_error] Recovering from classification error"

    {
      "classification_recovered" => true,
      "order_id" => input['order']['id'],
      "fallback_strategy" => "standard_processing",
      "recovered_at" => Time.now.to_i,
      "recovery_method" => "fallback_to_standard"
    }
  end

  def handle_payment_failure(input)
    order = input['order']
    puts "    [handle_payment_failure] Handling payment failure: #{order['id']}"

    {
      "payment_failure_handled" => true,
      "order_id" => order['id'],
      "attempt" => input['payment_attempt'],
      "next_action" => "notify_customer",
      "handled_at" => Time.now.to_i,
      "escalation_level" => "customer_support"
    }
  end

  def notify_payment_failure(input)
    order = input['order']
    puts "    [notify_payment_failure] Notifying customer: #{order['id']}"

    {
      "payment_failure_notified" => true,
      "order_id" => order['id'],
      "customer_notified" => true,
      "notification_method" => "email",
      "notified_at" => Time.now.to_i,
      "notification_template" => "payment_failed_v1"
    }
  end

  def handle_out_of_stock(input)
    order = input['order']
    puts "    [handle_out_of_stock] Handling out of stock: #{order['id']}"

    {
      "out_of_stock_handled" => true,
      "order_id" => order['id'],
      "action" => "notify_customer_and_restock",
      "handled_at" => Time.now.to_i,
      "restock_eta" => Time.now + 7 * 24 * 60 * 60 # 7 days
    }
  end

  def notify_out_of_stock(input)
    order = input['order']
    puts "    [notify_out_of_stock] Notifying out of stock: #{order['id']}"

    {
      "out_of_stock_notified" => true,
      "order_id" => order['id'],
      "customer_notified" => true,
      "notification_method" => "email",
      "notified_at" => Time.now.to_i,
      "alternative_suggested" => true
    }
  end

  def handle_bulk_unavailable(input)
    order = input['order']
    puts "    [handle_bulk_unavailable] Handling bulk unavailable: #{order['id']}"

    {
      "bulk_unavailable_handled" => true,
      "order_id" => order['id'],
      "action" => "offer_alternative",
      "handled_at" => Time.now.to_i,
      "fallback_to_standard" => true
    }
  end
end

# Simple executor that routes to ComplexOrderProcessor methods
class LocalMethodExecutor
  def initialize
    @processor = ComplexOrderProcessor.new
  end

  def call(resource, input, credentials = nil)
    method_name = resource.sub('method:', '')

    unless @processor.respond_to?(method_name)
      raise "Method not found: #{method_name}"
    end

    puts "    📞 Executing: #{method_name}"
    @processor.send(method_name, input)
  end
end

# Enhanced workflow tester with Parallel states
class WorkflowTester
  def initialize
    @executor = LocalMethodExecutor.new
    @workflow_file = 'complex_workflow_with_parallel.yaml'
    generate_workflow_file
  end

  def generate_workflow_file
    workflow_yaml = <<~YAML
    Comment: Complex E-commerce Workflow with Parallel Processing
    StartAt: ValidateInput
    States:
      # PASS State - Initial data transformation
      ValidateInput:
        Type: Pass
        Parameters:
          order_id.$: $.order.id
          customer_id.$: $.order.customer_id
          total_amount.$: $.order.total
          item_count.$: $.order.items.length
          timestamp: #{Time.now.to_i}
          workflow_version: "2.1.0"
        ResultPath: $.validation_metadata
        Next: CheckOrderType

      # TASK State - Order classification
      CheckOrderType:
        Type: Task
        Resource: method:determine_order_type
        ResultPath: $.order_type_result
        Next: RouteOrder
        Retry:
          - ErrorEquals: ["States.ALL"]
            IntervalSeconds: 2
            MaxAttempts: 2
            BackoffRate: 1.5

      # CHOICE State - Route based on order type
      RouteOrder:
        Type: Choice
        Choices:
          - Variable: $.order_type_result.order_type
            StringEquals: "premium"
            Next: ProcessPremiumOrder
          - Variable: $.order_type_result.order_type
            StringEquals: "bulk"
            Next: CheckBulkInventory
          - Variable: $.order_type_result.order_type
            StringEquals: "international"
            Next: ProcessInternationalOrder
          - Variable: $.order_type_result.order_type
            StringEquals: "digital"
            Next: ProcessDigitalOrder
        Default: ProcessStandardOrder

      # TASK States for different order types
      ProcessPremiumOrder:
        Type: Task
        Resource: method:process_premium_order
        ResultPath: $.premium_result
        Next: ProcessPayment

      CheckBulkInventory:
        Type: Task
        Resource: method:check_bulk_inventory
        Parameters:
          order.$: $.order
          required_quantity.$: $.order.quantity
        ResultPath: $.bulk_inventory_result
        Next: VerifyBulkAvailability
        Retry:
          - ErrorEquals: ["States.Timeout"]
            IntervalSeconds: 5
            MaxAttempts: 3
            BackoffRate: 2.0

      VerifyBulkAvailability:
        Type: Choice
        Choices:
          - Variable: $.bulk_inventory_result.available
            BooleanEquals: true
            Next: ProcessBulkOrder
          - Variable: $.bulk_inventory_result.available
            BooleanEquals: false
            Next: HandleBulkUnavailable
        Default: HandleBulkUnavailable

      ProcessBulkOrder:
        Type: Task
        Resource: method:process_bulk_order
        ResultPath: $.bulk_result
        Next: ProcessPayment

      HandleBulkUnavailable:
        Type: Task
        Resource: method:handle_bulk_unavailable
        ResultPath: $.bulk_unavailable_result
        Next: ProcessStandardOrder

      ProcessInternationalOrder:
        Type: Task
        Resource: method:process_international_order
        ResultPath: $.international_result
        Next: ProcessPayment

      ProcessDigitalOrder:
        Type: Task
        Resource: method:process_digital_order
        ResultPath: $.digital_result
        Next: GenerateDigitalAccess

      GenerateDigitalAccess:
        Type: Task
        Resource: method:generate_digital_access
        ResultPath: $.digital_access_result
        Next: SendDigitalDelivery

      ProcessStandardOrder:
        Type: Task
        Resource: method:process_standard_order
        ResultPath: $.standard_result
        Next: ProcessPayment

      # TASK State - Payment processing with retry
      ProcessPayment:
        Type: Task
        Resource: method:process_payment
        Parameters:
          order_id.$: $.order.id
          amount.$: $.order.total
          currency: "USD"
          payment_method.$: $.order.payment_method
          customer_id.$: $.order.customer_id
        ResultPath: $.payment_result
        Next: VerifyPaymentSuccess
        Retry:
          - ErrorEquals: ["PaymentGatewayTimeout", "States.Timeout"]
            IntervalSeconds: 3
            MaxAttempts: 3
            BackoffRate: 2.0
        Catch:
          - ErrorEquals: ["States.ALL"]
            Next: HandlePaymentFailure
            ResultPath: $.payment_error

      # CHOICE State - Verify payment outcome
      VerifyPaymentSuccess:
        Type: Choice
        Choices:
          - Variable: $.payment_result.status
            StringEquals: "completed"
            Next: ParallelPostPayment
          - Variable: $.payment_result.status
            StringEquals: "pending"
            Next: WaitForPaymentConfirmation
        Default: HandlePaymentFailure

      WaitForPaymentConfirmation:
        Type: Task
        Resource: method:wait_for_payment_confirmation
        ResultPath: $.payment_confirmation
        Next: FinalizePayment

      FinalizePayment:
        Type: Task
        Resource: method:finalize_payment
        ResultPath: $.final_payment_result
        Next: ParallelPostPayment

      HandlePaymentFailure:
        Type: Task
        Resource: method:handle_payment_failure
        Parameters:
          order.$: $.order
          error.$: $.payment_error
          payment_attempt: 1
        ResultPath: $.payment_failure_result
        Next: NotifyPaymentFailure

      NotifyPaymentFailure:
        Type: Task
        Resource: method:notify_payment_failure
        ResultPath: $.payment_failure_notification
        End: true

      # PARALLEL State - Execute multiple tasks concurrently
      ParallelPostPayment:
        Type: Parallel
        Branches:
          - StartAt: UpdateInventoryBranch
            States:
              UpdateInventoryBranch:
                Type: Task
                Resource: method:update_inventory
                Parameters:
                  order_id.$: $.order.id
                  items.$: $.order.items
                  action: "decrement"
                End: true
                ResultPath: $.inventory_result
                Catch:
                  - ErrorEquals: ["OutOfStock"]
                    Next: HandleOutOfStockBranch
                    ResultPath: $.inventory_error

              HandleOutOfStockBranch:
                Type: Task
                Resource: method:handle_out_of_stock
                ResultPath: $.out_of_stock_result
                End: true

          - StartAt: CustomerNotificationsBranch
            States:
              CustomerNotificationsBranch:
                Type: Task
                Resource: method:send_customer_notifications
                Parameters:
                  order.$: $.order
                End: true
                ResultPath: $.notification_result

          - StartAt: AnalyticsBranch
            States:
              AnalyticsBranch:
                Type: Task
                Resource: method:generate_analytics
                Parameters:
                  order.$: $.order
                End: true
                ResultPath: $.analytics_result

          - StartAt: LoyaltyBranch
            States:
              LoyaltyBranch:
                Type: Task
                Resource: method:process_loyalty_points
                Parameters:
                  order.$: $.order
                End: true
                ResultPath: $.loyalty_result

        Next: HandleShipping
        Catch:
          - ErrorEquals: ["States.ALL"]
            Next: HandleParallelError
            ResultPath: $.parallel_error

      HandleParallelError:
        Type: Pass
        Parameters:
          parallel_error_handled: true
          timestamp: #{Time.now.to_i}
        ResultPath: $.parallel_recovery
        Next: HandleShipping

      # CHOICE State - Shipping decisions
      HandleShipping:
        Type: Choice
        Choices:
          - Variable: $.order.shipping.required
            BooleanEquals: false
            Next: SendDigitalDelivery
          - Variable: $.order_type_result.order_type
            StringEquals: "premium"
            Next: ScheduleExpressShipping
          - Variable: $.order.total
            NumericGreaterThan: 100
            Next: ScheduleStandardShipping
        Default: ScheduleEconomyShipping

      # TASK States - Shipping methods
      ScheduleExpressShipping:
        Type: Task
        Resource: method:schedule_express_shipping
        ResultPath: $.shipping_result
        Next: FinalConfirmation

      ScheduleStandardShipping:
        Type: Task
        Resource: method:schedule_standard_shipping
        ResultPath: $.shipping_result
        Next: FinalConfirmation

      ScheduleEconomyShipping:
        Type: Task
        Resource: method:schedule_economy_shipping
        ResultPath: $.shipping_result
        Next: FinalConfirmation

      SendDigitalDelivery:
        Type: Task
        Resource: method:send_digital_delivery
        ResultPath: $.digital_delivery_result
        Next: FinalConfirmation

      # Final confirmation with potential FAIL state
      FinalConfirmation:
        Type: Task
        Resource: method:send_order_confirmation
        ResultPath: $.confirmation_result
        Next: OrderSuccessCheck

      # CHOICE State - Final success/fail check
      OrderSuccessCheck:
        Type: Choice
        Choices:
          - Variable: $.confirmation_result.confirmation_sent
            BooleanEquals: true
            Next: OrderCompleted
        Default: OrderFailed

      # SUCCEED State - Successful completion
      OrderCompleted:
        Type: Succeed

      # FAIL State - Final failure
      OrderFailed:
        Type: Fail
        Cause: "Order confirmation failed to send"
        Error: "ConfirmationError"
    YAML

    File.write(@workflow_file, workflow_yaml)
    puts "📄 Generated enhanced workflow file: #{@workflow_file}"
  end

  def run_test_cases
    test_cases = [
      {
        name: "🏆 Premium Order with Parallel Processing",
        input: {
          "order" => {
            "id" => "ORD-PREM-001",
            "total" => 750.00,
            "customer_id" => "CUST-PREM-001",
            "items" => ["premium_item_1", "premium_item_2"],
            "quantity" => 2,
            "premium_customer" => true,
            "payment_method" => "credit_card",
            "shipping" => { "required" => true, "country" => "US" }
          }
        }
      },
      {
        name: "📦 Bulk Order (Testing Retry)",
        input: {
          "order" => {
            "id" => "ORD-BULK-001",
            "total" => 1800.00, # Will trigger payment retry
            "customer_id" => "CUST-BULK-001",
            "items" => ["bulk_item_1"],
            "quantity" => 25,
            "payment_method" => "credit_card",
            "shipping" => { "required" => true, "country" => "US" }
          }
        }
      },
      {
        name: "💻 Digital Order (No Shipping)",
        input: {
          "order" => {
            "id" => "ORD-DIG-001",
            "total" => 49.99,
            "customer_id" => "CUST-DIG-001",
            "items" => ["ebook"],
            "quantity" => 1,
            "payment_method" => "paypal",
            "shipping" => { "required" => false },
            "digital_product" => { "type" => "ebook" },
            "customer_email" => "customer@example.com"
          }
        }
      },
      {
        name: "🌍 International Order",
        input: {
          "order" => {
            "id" => "ORD-INT-001",
            "total" => 299.99,
            "customer_id" => "CUST-INT-001",
            "items" => ["international_item"],
            "quantity" => 1,
            "payment_method" => "paypal",
            "shipping" => { "required" => true, "country" => "UK" }
          }
        }
      },
      {
        name: "💸 Payment Failure Scenario",
        input: {
          "order" => {
            "id" => "ORD-FAIL-001",
            "total" => 2500.00, # High amount that will fail payment
            "customer_id" => "CUST-FAIL-001",
            "items" => ["expensive_item"],
            "quantity" => 1,
            "payment_method" => "expired_card", # This will cause failure
            "shipping" => { "required" => true, "country" => "US" }
          }
        }
      }
    ]

    test_cases.each do |test_case|
      puts "\n" + "="*70
      puts "🧪 #{test_case[:name]}"
      puts "="*70

      start_time = Time.now

      begin
        # Load the state machine from YAML
        state_machine = StatesLanguageMachine.from_yaml_file(@workflow_file)

        # Start execution
        execution = state_machine.start_execution(test_case[:input], "test-#{test_case[:input]['order']['id']}")

        # Set the executor in context
        execution.context[:task_executor] = @executor

        # Run the workflow
        execution.run_all

        execution_time = Time.now - start_time

        # Display results
        puts "✅ Workflow completed successfully!"
        puts "📊 Final Status: #{execution.status}"
        puts "🛣️  Execution Path: #{execution.history.map { |h| h[:state_name] }.join(' → ')}"
        puts "⏱️  Execution Time: #{execution_time.round(4)} seconds"
        puts "📈 States Visited: #{execution.history.size}"

        if execution.output
          puts "📦 Final Output Summary:"
          execution.output.each do |key, value|
            if value.is_a?(Hash)
              puts "   - #{key}: #{value.keys.join(', ')}"
            else
              puts "   - #{key}: #{value}"
            end
          end

          # Show parallel results specifically
          if execution.output['inventory_result'] || execution.output['notification_result']
            puts "🔀 Parallel Branch Results:"
            %w[inventory_result notification_result analytics_result loyalty_result].each do |branch|
              if execution.output[branch]
                status = execution.output[branch].keys.first rescue 'unknown'
                puts "   - #{branch}: #{status}"
              end
            end
          end
        end

      rescue => e
        execution_time = Time.now - start_time
        puts "❌ Workflow failed!"
        puts "💥 Error: #{e.message}"
        if execution
          puts "🛑 Final Status: #{execution.status}"
          puts "📍 Last State: #{execution.history.last[:state_name]}" if execution.history.any?
          puts "📝 History: #{execution.history.map { |h| h[:state_name] }.join(' → ')}"
        end
        puts "⏱️  Execution Time: #{execution_time.round(4)} seconds"
      end

      puts "\n"
    end
  end
end

# Main execution
if __FILE__ == $0
  begin
    require 'ruby_slm'

    puts "🚀 Starting Enhanced Complex Workflow Test"
    puts "Testing ALL state types: Pass, Task, Choice, Parallel, Succeed, Fail"
    puts "With retry mechanisms, error handling, and parallel processing"
    puts ""

    tester = WorkflowTester.new
    tester.run_test_cases

    puts "🎉 All tests completed!"
    puts ""
    puts "📋 State Types Demonstrated:"
    puts "   ✅ Pass     - Data transformation"
    puts "   ✅ Task     - Business logic execution"
    puts "   ✅ Choice   - Conditional routing"
    puts "   ✅ Parallel - Concurrent branch execution"
    puts "   ✅ Succeed  - Successful termination"
    puts "   ✅ Fail     - Error termination"
    puts "   ✅ Retry    - Automatic retry mechanisms"
    puts "   ✅ Catch    - Error handling blocks"

  rescue LoadError => e
    puts "❌ Error: Could not load ruby_slm gem"
    puts "Make sure the gem is installed and in your load path"
    puts "Details: #{e.message}"
  end
end# frozen_string_literal: true

