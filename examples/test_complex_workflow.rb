#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'securerandom'

# ComplexOrderProcessor class from previous step
class ComplexOrderProcessor
  # Order Classification
  def determine_order_type(input)
    order = input['order'] || {}

    total = order['total'].to_f
    items = order['items'] || []
    quantity = order['quantity'].to_i

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
    {
      "premium_processed" => true,
      "order_id" => order['id'],
      "vip_handling" => true,
      "dedicated_support" => true,
      "processing_tier" => "premium"
    }
  end

  # Bulk Order Processing
  def check_bulk_inventory(input)
    order = input['order']
    required_quantity = input['required_quantity']

    # Simulate inventory check
    available = rand(0..1) == 1
    {
      "available" => available,
      "checked_at" => Time.now.to_i,
      "required_quantity" => required_quantity,
      "available_quantity" => available ? required_quantity : 0
    }
  end

  def process_bulk_order(input)
    order = input['order']
    {
      "bulk_processed" => true,
      "order_id" => order['id'],
      "volume_discount_applied" => true,
      "special_handling" => true
    }
  end

  # International Order Processing
  def process_international_order(input)
    order = input['order']
    country = input['destination_country']

    {
      "international_processed" => true,
      "order_id" => order['id'],
      "destination_country" => country,
      "export_documentation" => "required",
      "customs_declaration" => "needed"
    }
  end

  def calculate_customs_duty(input)
    order_value = input['order_value'].to_f
    country = input['country']

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
      "currency" => "USD"
    }
  end

  # Digital Order Processing
  def process_digital_order(input)
    order = input['order']
    {
      "digital_processed" => true,
      "order_id" => order['id'],
      "product_type" => order['digital_product']['type'],
      "instant_delivery" => true
    }
  end

  def generate_digital_access(input)
    {
      "access_generated" => true,
      "order_id" => input['order_id'],
      "access_codes" => ["CODE-#{SecureRandom.hex(8)}"],
      "download_links" => ["https://download.example.com/#{SecureRandom.hex(4)}"],
      "license_key" => "LIC-#{SecureRandom.hex(12)}"
    }
  end

  # Standard Order Processing
  def process_standard_order(input)
    order = input['order']
    {
      "standard_processed" => true,
      "order_id" => order['id'],
      "processing_tier" => "standard"
    }
  end

  # Payment Processing
  def process_payment(input)
    amount = input['amount'].to_f
    payment_method = input['payment_method']

    # Simulate payment processing with occasional failures
    success = amount < 2000 && payment_method != 'expired_card'

    if success
      {
        "status" => "completed",
        "payment_id" => "pay_#{SecureRandom.hex(8)}",
        "amount_charged" => amount,
        "currency" => input['currency'],
        "processed_at" => Time.now.to_i
      }
    else
      raise "Payment declined: #{payment_method} cannot process $#{amount}"
    end
  end

  def wait_for_payment_confirmation(input)
    payment_id = input['payment_id']

    # Simulate waiting for confirmation
    sleep(0.1) # Reduced for testing

    {
      "confirmed" => true,
      "payment_id" => payment_id,
      "confirmation_code" => "CONF-#{SecureRandom.hex(6)}",
      "confirmed_at" => Time.now.to_i
    }
  end

  def finalize_payment(input)
    {
      "finalized" => true,
      "payment_id" => input['payment_id'],
      "status" => "completed",
      "finalized_at" => Time.now.to_i
    }
  end

  # Inventory Management
  def update_inventory(input)
    order_id = input['order_id']
    items = input['items']

    # Simulate inventory update with occasional stock issues
    out_of_stock = rand(0..9) == 0 # 10% chance of out of stock

    if out_of_stock
      raise "OutOfStock - Item unavailable for order #{order_id}"
    else
      {
        "inventory_updated" => true,
        "order_id" => order_id,
        "items_processed" => items.size,
        "updated_at" => Time.now.to_i
      }
    end
  end

  # Shipping Methods
  def schedule_express_shipping(input)
    order = input['order']
    {
      "shipping_scheduled" => true,
      "order_id" => order['id'],
      "method" => "express",
      "estimated_days" => 1,
      "tracking_number" => "EXP#{SecureRandom.hex(6).upcase}",
      "priority" => "high"
    }
  end

  def schedule_standard_shipping(input)
    order = input['order']
    {
      "shipping_scheduled" => true,
      "order_id" => order['id'],
      "method" => "standard",
      "estimated_days" => 3,
      "tracking_number" => "STD#{SecureRandom.hex(6).upcase}"
    }
  end

  def schedule_economy_shipping(input)
    order = input['order']
    {
      "shipping_scheduled" => true,
      "order_id" => order['id'],
      "method" => "economy",
      "estimated_days" => 7,
      "tracking_number" => "ECO#{SecureRandom.hex(6).upcase}"
    }
  end

  # Digital Delivery
  def send_digital_delivery(input)
    order = input['order']
    {
      "digital_delivered" => true,
      "order_id" => order['id'],
      "customer_email" => input['customer_email'],
      "delivery_method" => "email",
      "sent_at" => Time.now.to_i
    }
  end

  # Notifications
  def send_order_confirmation(input)
    order = input['order']
    {
      "confirmation_sent" => true,
      "order_id" => order['id'],
      "customer_id" => input['customer'],
      "sent_via" => ["email", "sms"],
      "confirmation_id" => "CONF-#{SecureRandom.hex(6)}"
    }
  end

  # Error Handling Methods
  def handle_classification_error(input)
    {
      "classification_recovered" => true,
      "order_id" => input['order']['id'],
      "fallback_strategy" => "standard_processing",
      "recovered_at" => Time.now.to_i
    }
  end

  def handle_premium_error(input)
    {
      "premium_recovered" => true,
      "order_id" => input['order']['id'],
      "fallback_strategy" => "standard_processing",
      "recovered_at" => Time.now.to_i
    }
  end

  def handle_bulk_unavailable(input)
    order = input['order']
    {
      "bulk_unavailable_handled" => true,
      "order_id" => order['id'],
      "action" => "offer_alternative",
      "unavailable_items" => input['inventory']['unavailable_items'] || []
    }
  end

  def handle_bulk_error(input)
    {
      "bulk_error_recovered" => true,
      "order_id" => input['order']['id'],
      "fallback_strategy" => "standard_processing",
      "recovered_at" => Time.now.to_i
    }
  end

  def handle_digital_error(input)
    {
      "digital_error_recovered" => true,
      "order_id" => input['order']['id'],
      "fallback_strategy" => "standard_processing",
      "recovered_at" => Time.now.to_i
    }
  end

  def handle_payment_failure(input)
    order = input['order']
    {
      "payment_failure_handled" => true,
      "order_id" => order['id'],
      "attempt" => input['payment_attempt'],
      "next_action" => "notify_customer",
      "handled_at" => Time.now.to_i
    }
  end

  def handle_payment_error(input)
    {
      "payment_error_handled" => true,
      "order_id" => input['order']['id'],
      "action" => "escalate_to_support",
      "handled_at" => Time.now.to_i
    }
  end

  def handle_out_of_stock(input)
    order = input['order']
    {
      "out_of_stock_handled" => true,
      "order_id" => order['id'],
      "action" => "notify_customer_and_restock",
      "handled_at" => Time.now.to_i
    }
  end

  def notify_payment_failure(input)
    order = input['order']
    {
      "payment_failure_notified" => true,
      "order_id" => order['id'],
      "customer_notified" => true,
      "notification_method" => "email",
      "notified_at" => Time.now.to_i
    }
  end

  def notify_out_of_stock(input)
    order = input['order']
    {
      "out_of_stock_notified" => true,
      "order_id" => order['id'],
      "customer_notified" => true,
      "notification_method" => "email",
      "notified_at" => Time.now.to_i
    }
  end

  def offer_alternative(input)
    order = input['order']
    {
      "alternative_offered" => true,
      "order_id" => order['id'],
      "alternative_products" => ["similar_item_1", "similar_item_2"],
      "discount_offered" => true,
      "discount_percentage" => 10
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

# Simple workflow runner using the actual StatesLanguageMachine
class WorkflowTester
  def initialize
    @executor = LocalMethodExecutor.new
    @workflow_file = 'complex_workflow.yaml'
    generate_workflow_file
  end

  def generate_workflow_file
    workflow_yaml = <<~YAML
    Comment: Complex E-commerce Order Processing Workflow
    StartAt: ValidateInput
    States:
      ValidateInput:
        Type: Pass
        Parameters:
          order_id.$: $.order.id
          customer_id.$: $.order.customer_id
          total_amount.$: $.order.total
          item_count.$: $.order.items.length
          timestamp: #{Time.now.to_i}
        ResultPath: $.validation_metadata
        Next: CheckOrderType

      CheckOrderType:
        Type: Task
        Resource: method:determine_order_type
        ResultPath: $.order_type_result
        Next: RouteOrder

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
        Next: UpdateInventory
        Catch:
          - ErrorEquals: ["States.ALL"]
            Next: HandlePaymentFailure
            ResultPath: $.payment_error

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

      UpdateInventory:
        Type: Task
        Resource: method:update_inventory
        Parameters:
          order_id.$: $.order.id
          items.$: $.order.items
          action: "decrement"
        ResultPath: $.inventory_result
        Next: HandleShipping
        Catch:
          - ErrorEquals: ["OutOfStock"]
            Next: HandleOutOfStock
            ResultPath: $.inventory_error

      HandleOutOfStock:
        Type: Task
        Resource: method:handle_out_of_stock
        ResultPath: $.out_of_stock_result
        Next: NotifyOutOfStock

      NotifyOutOfStock:
        Type: Task
        Resource: method:notify_out_of_stock
        ResultPath: $.out_of_stock_notification
        End: true

      HandleBulkUnavailable:
        Type: Task
        Resource: method:handle_bulk_unavailable
        ResultPath: $.bulk_unavailable_result
        Next: ProcessStandardOrder

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

      ScheduleExpressShipping:
        Type: Task
        Resource: method:schedule_express_shipping
        ResultPath: $.shipping_result
        Next: SendOrderConfirmation

      ScheduleStandardShipping:
        Type: Task
        Resource: method:schedule_standard_shipping
        ResultPath: $.shipping_result
        Next: SendOrderConfirmation

      ScheduleEconomyShipping:
        Type: Task
        Resource: method:schedule_economy_shipping
        ResultPath: $.shipping_result
        Next: SendOrderConfirmation

      SendDigitalDelivery:
        Type: Task
        Resource: method:send_digital_delivery
        ResultPath: $.digital_delivery_result
        Next: SendOrderConfirmation

      SendOrderConfirmation:
        Type: Task
        Resource: method:send_order_confirmation
        ResultPath: $.confirmation_result
        End: true
    YAML

    File.write(@workflow_file, workflow_yaml)
    puts "📄 Generated workflow file: #{@workflow_file}"
  end

  def run_test_cases
    test_cases = [
      {
        name: "Premium Order",
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
        name: "Bulk Order (Available)",
        input: {
          "order" => {
            "id" => "ORD-BULK-001",
            "total" => 1500.00,
            "customer_id" => "CUST-BULK-001",
            "items" => ["bulk_item_1"],
            "quantity" => 25,
            "payment_method" => "credit_card",
            "shipping" => { "required" => true, "country" => "US" }
          }
        }
      },
      {
        name: "Digital Order",
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
        name: "Standard Order",
        input: {
          "order" => {
            "id" => "ORD-STD-001",
            "total" => 89.99,
            "customer_id" => "CUST-STD-001",
            "items" => ["standard_item_1", "standard_item_2"],
            "quantity" => 3,
            "payment_method" => "credit_card",
            "shipping" => { "required" => true, "country" => "US" }
          }
        }
      },
      {
        name: "Payment Failure Order",
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
      puts "\n" + "="*60
      puts "🧪 Testing: #{test_case[:name]}"
      puts "="*60

      begin
        # Load the state machine from YAML
        state_machine = StatesLanguageMachine.from_yaml_file(@workflow_file)

        # Start execution
        execution = state_machine.start_execution(test_case[:input], "test-#{test_case[:input]['order']['id']}")

        # Set the executor in context
        execution.context[:task_executor] = @executor

        # Run the workflow
        execution.run_all

        # Display results
        puts "✅ Workflow completed successfully!"
        puts "📊 Final Status: #{execution.status}"
        puts "🛣️  Execution Path: #{execution.history.map { |h| h[:state_name] }.join(' → ')}"
        puts "⏱️  Execution Time: #{execution.execution_time.round(4)} seconds"

        if execution.output
          puts "📦 Output Keys: #{execution.output.keys.join(', ')}"
          # Show some key results
          execution.output.each do |key, value|
            if key =~ /result|status|confirmation/
              puts "   - #{key}: #{value.is_a?(Hash) ? value.keys.join(',') : value}"
            end
          end
        end

      rescue => e
        puts "❌ Workflow failed!"
        puts "💥 Error: #{e.message}"
        if execution
          puts "🛑 Final Status: #{execution.status}"
          puts "📍 Failed at: #{execution.history.last[:state_name]}" if execution.history.any?
        end
      end

      puts "\n"
    end
  end
end

# Main execution
if __FILE__ == $0
  begin
    require 'ruby_slm'

    puts "🚀 Starting Complex Workflow Test"
    puts "This tests Pass, Task, Choice, Succeed, and Fail states with local methods"
    puts ""

    tester = WorkflowTester.new
    tester.run_test_cases

    puts "🎉 All tests completed!"

  rescue LoadError
    puts "❌ Error: Could not load ruby_slm gem"
    puts "Make sure the gem is installed and in your load path"
  end
end