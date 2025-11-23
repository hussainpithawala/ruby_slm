# Ruby State Language Machine (SLM)

A powerful, flexible state machine implementation for Ruby that's compatible with AWS Step Functions state language. Define complex workflows using YAML/JSON and execute them with local Ruby methods or external resources.

[![Gem Version](https://badge.fury.io/rb/ruby_slm.svg)](https://rubygems.org/gems/ruby_slm/versions/0.1.1)
[![Ruby](https://img.shields.io/badge/Ruby-3.4+-red.svg)](https://ruby-lang.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Features

- 🚀 **AWS Step Functions Compatible** - Use the same state language as AWS Step Functions
  - 🔄 https://states-language.net/
- 🔧 **Local Method Execution** - Execute Ruby methods directly from state tasks
- 📁 **YAML/JSON Support** - Define workflows in human-readable formats
- 🛡️ **Error Handling** - Built-in retry and catch mechanisms
- ⏱️ **Timeout & Heartbeat** - Control task execution timing
- 🔄 **All State Types** - Support for Pass, Task, Choice, Parallel, Wait, Succeed, Fail
- 🧪 **Test-Friendly** - Easy to mock and test workflows

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby_slm'
```

And then execute:

```bash
$ bundle install
```
Quick Start

1. Define Your Workflow
   Create a YAML file (order_workflow.yaml):
```yaml
Comment: Order Processing Workflow
StartAt: ValidateOrder
States:
  ValidateOrder:
    Type: Task
    Resource: method:validate_order
    Next: ProcessPayment
    ResultPath: $.validation_result

  ProcessPayment:
    Type: Task
    Resource: method:process_payment
    Next: UpdateInventory
    ResultPath: $.payment_result
    Catch:
      - ErrorEquals: ["States.ALL"]
        Next: HandlePaymentFailure
        ResultPath: $.error_info

  HandlePaymentFailure:
    Type: Task
    Resource: method:handle_payment_failure
    End: true

  UpdateInventory:
    Type: Task
    Resource: method:update_inventory
    Next: SendConfirmation
    ResultPath: $.inventory_result

  SendConfirmation:
    Type: Task
    Resource: method:send_confirmation
    End: true
    ResultPath: $.confirmation_result
```

2. Implement Your Business Logic
```ruby
class OrderProcessor
  def validate_order(input)
    order = input['order']
    {
      "valid" => true,
      "order_id" => order['id'],
      "customer_id" => order['customer_id']
    }
  end

  def process_payment(input)
    {
      "payment_status" => "completed",
      "payment_id" => "pay_#{SecureRandom.hex(8)}",
      "amount_charged" => input['order']['total']
    }
  end

  def update_inventory(input)
    {
      "inventory_updated" => true,
      "order_id" => input['order']['id']
    }
  end

  def send_confirmation(input)
    {
      "confirmation_sent" => true,
      "order_id" => input['order']['id']
    }
  end

  def handle_payment_failure(input)
    {
      "payment_failure_handled" => true,
      "order_id" => input['order']['id']
    }
  end
end
```

3. Execute the Workflow
```ruby
require 'ruby_slm'

# Create your business logic processor
processor = OrderProcessor.new

# Create an executor that routes to local methods
executor = ->(resource, input, credentials) do
  method_name = resource.sub('method:', '')
  processor.send(method_name, input)
end

# Load and execute the workflow
state_machine = StatesLanguageMachine.from_yaml_file('order_workflow.yaml')

input = {
  "order" => {
    "id" => "ORD-123",
    "total" => 99.99,
    "customer_id" => "CUST-456"
  }
}

execution = state_machine.start_execution(input, "my-order-execution")
execution.context[:task_executor] = executor
execution.run_all

puts "Status: #{execution.status}" # => "succeeded"
puts "Output: #{execution.output}"
```

## State Types
### Task State
#### Execute work using local methods or external resources.

```yaml
ProcessData:
  Type: Task
  Resource: method:process_data
  Next: NextState
  TimeoutSeconds: 300
  Retry:
    - ErrorEquals: ["States.Timeout"]
      IntervalSeconds: 5
      MaxAttempts: 3
  Catch:
    - ErrorEquals: ["States.ALL"]
      Next: HandleError
  ResultPath: $.processing_result
```

### Pass State
#### Transform data without performing work.
```yaml
TransformData:
  Type: Pass
  Parameters:
    original_id.$: $.order.id
    processed_at: 1698765432
    status: "processing"
  ResultPath: $.metadata
  Next: NextState
```

### Choice State
#### Make decisions based on data.
```yaml
CheckInventory:
  Type: Choice
  Choices:
    - Variable: $.inventory.available
      BooleanEquals: true
      Next: ProcessOrder
    - Variable: $.order.priority
      StringEquals: "high"
      Next: ExpediteOrder
  Default: WaitForStock
```

### Parallel State
#### Execute multiple branches concurrently.
```yaml
ProcessInParallel:
  Type: Parallel
  Branches:
    - StartAt: UpdateInventory
      States: { ... }
    - StartAt: NotifyCustomer
      States: { ... }
  Next: AggregateResults  
```

### Wait State
#### Wait for a specified time or until a timestamp.

```yaml
WaitForPayment:
  Type: Wait
  Seconds: 300
  Next: CheckPaymentStatus
`````

### Succeed & Fail States
#### Terminate execution successfully or with error.

```yaml
OrderCompleted:
  Type: Succeed

OrderFailed:
  Type: Fail
  Cause: "Payment processing failed"
  Error: "PaymentError"
```

## Advanced Features

### Retry Mechanisms

```yaml
CallExternalAPI:
  Type: Task
  Resource: method:call_external_api
  Retry:
    - ErrorEquals: ["States.Timeout", "NetworkError"]
      IntervalSeconds: 1
      MaxAttempts: 5
      BackoffRate: 2.0
    - ErrorEquals: ["RateLimitExceeded"]
      IntervalSeconds: 60
      MaxAttempts: 3
  Next: NextState
```
### Input/Output Processing

```yaml
ProcessOrder:
  Type: Task
  Resource: method:process_order
  InputPath: $.order_data
  OutputPath: $.result
  ResultPath: $.processing_result
  ResultSelector:
    success: true
    processed_at: 1698765432
    order_id.$: $.order.id
```

### Intrinsic Functions
```yaml
FormatMessage:
  Type: Pass
  Parameters:
    message: "States.Format('Hello {}, your order {} is ready!', $.customer.name, $.order.id)"
    uuid: "States.UUID()"
    random_number: "States.MathRandom(1, 100)"
  ResultPath: $.formatted_data
```

### Local Method Execution
#### Method Routing

```ruby
class BusinessLogic
  def process_data(input)
    # Your business logic here
    { "processed" => true, "result" => input.transform_values(&:upcase) }
  end
  
  def validate_input(input)
    # Validation logic
    raise "Invalid input" unless input['required_field']
    { "valid" => true }
  end
end

# Create executor
logic = BusinessLogic.new
executor = ->(resource, input, credentials) do
  method_name = resource.sub('method:', '')
  logic.send(method_name, input)
end

# Use in execution context
execution.context[:task_executor] = executor

```
#### Custom Executors

```ruby
class CustomExecutor
  def call(resource, input, credentials)
    case resource
    when /^method:/
      execute_local_method(resource, input)
    when /^arn:aws:lambda:/
      execute_lambda(resource, input, credentials)
    when /^arn:aws:sqs:/
      send_sqs_message(resource, input)
    else
      { "error" => "Unknown resource type" }
    end
  end

  private

  def execute_local_method(resource, input)
    method_name = resource.sub('method:', '')
    # Your method dispatch logic
  end
end

execution.context[:task_executor] = CustomExecutor.new
```
### Error Handling

#### Catch Blocks

```yaml
ProcessPayment:
  Type: Task
  Resource: method:process_payment
  Catch:
    - ErrorEquals: ["InsufficientFunds", "CardDeclined"]
      Next: HandlePaymentFailure
      ResultPath: $.payment_error
    - ErrorEquals: ["States.Timeout"]
      Next: HandleTimeout
    - ErrorEquals: ["States.ALL"]
      Next: HandleGenericError
  Next: NextState
```

## Testing

### Unit Testing Workflows
```ruby
require 'spec_helper'

RSpec.describe 'Order Workflow' do
  let(:processor) { OrderProcessor.new }
  let(:executor) { ->(r, i, c) { processor.send(r.sub('method:', ''), i) } }
  
  it 'processes orders successfully' do
    state_machine = StatesLanguageMachine.from_yaml_file('workflows/order_processing.yaml')
    execution = state_machine.start_execution(order_input, "test-execution")
    execution.context[:task_executor] = executor
    execution.run_all
    
    expect(execution.status).to eq('succeeded')
    expect(execution.output['confirmation_result']['confirmation_sent']).to be true
  end
end
```
### Testing Error Scenarios

```ruby
it 'handles payment failures gracefully' do
  # Mock payment failure
  allow(processor).to receive(:process_payment).and_raise('Payment declined')
  
  execution.run_all
  
  expect(execution.status).to eq('succeeded') # Because catch handled it
  expect(execution.output['payment_failure_handled']).to be true
end
```

## Configuration
### Execution Context
```ruby
execution.context = {
  task_executor: your_executor,
  method_receiver: your_object,  # For method: resources
  logger: Logger.new($stdout),   # For execution logging
  metrics: your_metrics_client   # For monitoring
}
```

### Timeout configuration
```yaml
LongRunningTask:
  Type: Task
Resource: method:long_running_process
TimeoutSeconds: 3600          # 1 hour timeout
HeartbeatSeconds: 300         # 5 minute heartbeat
Next: NextState
```

## Examples
### Check the examples/ directory for complete working examples:

- exammples/ - Complex order processing workflow
    - examples/test_complex_workflow.rb 
```bash
🚀 Starting Complex Workflow Test
This tests Pass, Task, Choice, Succeed, and Fail states with local methods

📄 Generated workflow file: complex_workflow.yaml

============================================================
🧪 Testing: Premium Order
============================================================
    📞 Executing: determine_order_type
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "premium", "Next" => "ProcessPremiumOrder"}
StringEquals
true
    📞 Executing: process_premium_order
    📞 Executing: process_payment
    📞 Executing: update_inventory
✅ Workflow completed successfully!
📊 Final Status: failed
🛣️  Execution Path: ValidateInput → CheckOrderType → RouteOrder → ProcessPremiumOrder → ProcessPayment
⏱️  Execution Time: 0.0008 seconds
📦 Output Keys: order, $, order_type_result, premium_result, payment_result
   - order_type_result: order_type,reason
   - premium_result: premium_processed,order_id,vip_handling,dedicated_support,processing_tier
   - payment_result: status,payment_id,amount_charged,currency,processed_at


============================================================
🧪 Testing: Bulk Order (Available)
============================================================
    📞 Executing: determine_order_type
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "premium", "Next" => "ProcessPremiumOrder"}
StringEquals
true
    📞 Executing: process_premium_order
    📞 Executing: process_payment
    📞 Executing: update_inventory
✅ Workflow completed successfully!
📊 Final Status: failed
🛣️  Execution Path: ValidateInput → CheckOrderType → RouteOrder → ProcessPremiumOrder → ProcessPayment
⏱️  Execution Time: 0.0003 seconds
📦 Output Keys: order, $, order_type_result, premium_result, payment_result
   - order_type_result: order_type,reason
   - premium_result: premium_processed,order_id,vip_handling,dedicated_support,processing_tier
   - payment_result: status,payment_id,amount_charged,currency,processed_at


============================================================
🧪 Testing: Digital Order
============================================================
    📞 Executing: determine_order_type
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "premium", "Next" => "ProcessPremiumOrder"}
StringEquals
false
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "bulk", "Next" => "CheckBulkInventory"}
StringEquals
false
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "international", "Next" => "ProcessInternationalOrder"}
StringEquals
true
    📞 Executing: process_international_order
    📞 Executing: process_payment
    📞 Executing: update_inventory
✅ Workflow completed successfully!
📊 Final Status: failed
🛣️  Execution Path: ValidateInput → CheckOrderType → RouteOrder → ProcessInternationalOrder → ProcessPayment
⏱️  Execution Time: 0.0003 seconds
📦 Output Keys: order, $, order_type_result, international_result, payment_result
   - order_type_result: order_type,reason
   - international_result: international_processed,order_id,destination_country,export_documentation,customs_declaration
   - payment_result: status,payment_id,amount_charged,currency,processed_at


============================================================
🧪 Testing: Standard Order
============================================================
    📞 Executing: determine_order_type
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "premium", "Next" => "ProcessPremiumOrder"}
StringEquals
false
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "bulk", "Next" => "CheckBulkInventory"}
StringEquals
false
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "international", "Next" => "ProcessInternationalOrder"}
StringEquals
false
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "digital", "Next" => "ProcessDigitalOrder"}
StringEquals
false
    📞 Executing: process_standard_order
    📞 Executing: process_payment
    📞 Executing: update_inventory
✅ Workflow completed successfully!
📊 Final Status: failed
🛣️  Execution Path: ValidateInput → CheckOrderType → RouteOrder → ProcessStandardOrder → ProcessPayment
⏱️  Execution Time: 0.0003 seconds
📦 Output Keys: order, $, order_type_result, standard_result, payment_result
   - order_type_result: order_type,reason
   - standard_result: standard_processed,order_id,processing_tier
   - payment_result: status,payment_id,amount_charged,currency,processed_at


============================================================
🧪 Testing: Payment Failure Order
============================================================
    📞 Executing: determine_order_type
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "premium", "Next" => "ProcessPremiumOrder"}
StringEquals
true
    📞 Executing: process_premium_order
    📞 Executing: process_payment
    📞 Executing: update_inventory
{"Variable" => "$.order.shipping.required", "BooleanEquals" => false, "Next" => "SendDigitalDelivery"}
BooleanEquals
false
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "premium", "Next" => "ScheduleExpressShipping"}
StringEquals
true
    📞 Executing: schedule_express_shipping
    📞 Executing: send_order_confirmation
✅ Workflow completed successfully!
📊 Final Status: succeeded
🛣️  Execution Path: ValidateInput → CheckOrderType → RouteOrder → ProcessPremiumOrder → ProcessPayment → HandleShipping → ScheduleExpressShipping → SendOrderConfirmation
⏱️  Execution Time: 0.0005 seconds
📦 Output Keys: order, $, order_type_result, premium_result, payment_result, inventory_error, shipping_result, confirmation_result
   - order_type_result: order_type,reason
   - premium_result: premium_processed,order_id,vip_handling,dedicated_support,processing_tier
   - payment_result: status,payment_id,amount_charged,currency,processed_at
   - shipping_result: shipping_scheduled,order_id,method,estimated_days,tracking_number,priority
   - confirmation_result: confirmation_sent,order_id,customer_id,sent_via,confirmation_id

🎉 All tests completed! 
```
    - examples/test_parallel_complex_workflow.rb
```bash
🚀 Starting Enhanced Complex Workflow Test
Testing ALL state types: Pass, Task, Choice, Parallel, Succeed, Fail
With retry mechanisms, error handling, and parallel processing

📄 Generated enhanced workflow file: complex_workflow_with_parallel.yaml

======================================================================
🧪 🏆 Premium Order with Parallel Processing
======================================================================
    📞 Executing: determine_order_type
    [determine_order_type] Analyzing order: ORD-PREM-001 - Total: $750.0, Items: 2, Quantity: 2
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "premium", "Next" => "ProcessPremiumOrder"}
StringEquals
true
    📞 Executing: process_premium_order
    [process_premium_order] VIP processing for: ORD-PREM-001
    📞 Executing: process_payment
    [process_payment] Processing $0.0 via
{"Variable" => "$.payment_result.status", "StringEquals" => "completed", "Next" => "ParallelPostPayment"}
StringEquals
true
    📞 Executing: update_inventory
    [update_inventory] Updating inventory for:
    📞 Executing: send_customer_notifications
    [send_customer_notifications] Sending notifications: ORD-PREM-001
    📞 Executing: generate_analytics
    [generate_analytics] Generating analytics: ORD-PREM-001
    📞 Executing: process_loyalty_points
    [process_loyalty_points] Processing loyalty: CUST-PREM-001
✅ Workflow completed successfully!
📊 Final Status: failed
🛣️  Execution Path: ValidateInput → CheckOrderType → RouteOrder → ProcessPremiumOrder → ProcessPayment → VerifyPaymentSuccess
⏱️  Execution Time: 0.0066 seconds
📈 States Visited: 6
📦 Final Output Summary:
   - order: id, total, customer_id, items, quantity, premium_customer, payment_method, shipping
   - $: validation_metadata
   - order_type_result: order_type, reason
   - premium_result: premium_processed, order_id, vip_handling, dedicated_support, processing_tier, priority_level
   - payment_result: status, payment_id, amount_charged, currency, processed_at, attempts


======================================================================
🧪 📦 Bulk Order (Testing Retry)
======================================================================
    📞 Executing: determine_order_type
    [determine_order_type] Analyzing order: ORD-BULK-001 - Total: $1800.0, Items: 1, Quantity: 25
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "premium", "Next" => "ProcessPremiumOrder"}
StringEquals
true
    📞 Executing: process_premium_order
    [process_premium_order] VIP processing for: ORD-BULK-001
    📞 Executing: process_payment
    [process_payment] Processing $0.0 via
{"Variable" => "$.payment_result.status", "StringEquals" => "completed", "Next" => "ParallelPostPayment"}
StringEquals
true
    📞 Executing: update_inventory
    [update_inventory] Updating inventory for:
    📞 Executing: send_customer_notifications
    [send_customer_notifications] Sending notifications: ORD-BULK-001
    📞 Executing: generate_analytics
    [generate_analytics] Generating analytics: ORD-BULK-001
    📞 Executing: process_loyalty_points
    [process_loyalty_points] Processing loyalty: CUST-BULK-001
✅ Workflow completed successfully!
📊 Final Status: failed
🛣️  Execution Path: ValidateInput → CheckOrderType → RouteOrder → ProcessPremiumOrder → ProcessPayment → VerifyPaymentSuccess
⏱️  Execution Time: 0.0033 seconds
📈 States Visited: 6
📦 Final Output Summary:
   - order: id, total, customer_id, items, quantity, payment_method, shipping
   - $: validation_metadata
   - order_type_result: order_type, reason
   - premium_result: premium_processed, order_id, vip_handling, dedicated_support, processing_tier, priority_level
   - payment_result: status, payment_id, amount_charged, currency, processed_at, attempts


======================================================================
🧪 💻 Digital Order (No Shipping)
======================================================================
    📞 Executing: determine_order_type
    [determine_order_type] Analyzing order: ORD-DIG-001 - Total: $49.99, Items: 1, Quantity: 1
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "premium", "Next" => "ProcessPremiumOrder"}
StringEquals
false
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "bulk", "Next" => "CheckBulkInventory"}
StringEquals
false
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "international", "Next" => "ProcessInternationalOrder"}
StringEquals
true
    📞 Executing: process_international_order
    [process_international_order] International processing for: ORD-DIG-001 to
    📞 Executing: process_payment
    [process_payment] Processing $0.0 via
{"Variable" => "$.payment_result.status", "StringEquals" => "completed", "Next" => "ParallelPostPayment"}
StringEquals
true
    📞 Executing: update_inventory
    [update_inventory] Updating inventory for:
    📞 Executing: send_customer_notifications
    [send_customer_notifications] Sending notifications: ORD-DIG-001
    📞 Executing: generate_analytics
    [generate_analytics] Generating analytics: ORD-DIG-001
    📞 Executing: process_loyalty_points
    [process_loyalty_points] Processing loyalty: CUST-DIG-001
✅ Workflow completed successfully!
📊 Final Status: failed
🛣️  Execution Path: ValidateInput → CheckOrderType → RouteOrder → ProcessInternationalOrder → ProcessPayment → VerifyPaymentSuccess
⏱️  Execution Time: 0.003 seconds
📈 States Visited: 6
📦 Final Output Summary:
   - order: id, total, customer_id, items, quantity, payment_method, shipping, digital_product, customer_email
   - $: validation_metadata
   - order_type_result: order_type, reason
   - international_result: international_processed, order_id, destination_country, export_documentation, customs_declaration, requires_export_license
   - payment_result: status, payment_id, amount_charged, currency, processed_at, attempts


======================================================================
🧪 🌍 International Order
======================================================================
    📞 Executing: determine_order_type
    [determine_order_type] Analyzing order: ORD-INT-001 - Total: $299.99, Items: 1, Quantity: 1
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "premium", "Next" => "ProcessPremiumOrder"}
StringEquals
false
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "bulk", "Next" => "CheckBulkInventory"}
StringEquals
false
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "international", "Next" => "ProcessInternationalOrder"}
StringEquals
true
    📞 Executing: process_international_order
    [process_international_order] International processing for: ORD-INT-001 to
    📞 Executing: process_payment
    [process_payment] Processing $0.0 via
{"Variable" => "$.payment_result.status", "StringEquals" => "completed", "Next" => "ParallelPostPayment"}
StringEquals
true
    📞 Executing: update_inventory
    [update_inventory] Updating inventory for:
    📞 Executing: send_customer_notifications
    [send_customer_notifications] Sending notifications: ORD-INT-001
    📞 Executing: generate_analytics
    [generate_analytics] Generating analytics: ORD-INT-001
    📞 Executing: process_loyalty_points
    [process_loyalty_points] Processing loyalty: CUST-INT-001
✅ Workflow completed successfully!
📊 Final Status: failed
🛣️  Execution Path: ValidateInput → CheckOrderType → RouteOrder → ProcessInternationalOrder → ProcessPayment → VerifyPaymentSuccess
⏱️  Execution Time: 0.0031 seconds
📈 States Visited: 6
📦 Final Output Summary:
   - order: id, total, customer_id, items, quantity, payment_method, shipping
   - $: validation_metadata
   - order_type_result: order_type, reason
   - international_result: international_processed, order_id, destination_country, export_documentation, customs_declaration, requires_export_license
   - payment_result: status, payment_id, amount_charged, currency, processed_at, attempts


======================================================================
🧪 💸 Payment Failure Scenario
======================================================================
    📞 Executing: determine_order_type
    [determine_order_type] Analyzing order: ORD-FAIL-001 - Total: $2500.0, Items: 1, Quantity: 1
{"Variable" => "$.order_type_result.order_type", "StringEquals" => "premium", "Next" => "ProcessPremiumOrder"}
StringEquals
true
    📞 Executing: process_premium_order
    [process_premium_order] VIP processing for: ORD-FAIL-001
    📞 Executing: process_payment
    [process_payment] Processing $0.0 via
{"Variable" => "$.payment_result.status", "StringEquals" => "completed", "Next" => "ParallelPostPayment"}
StringEquals
true
    📞 Executing: update_inventory
    [update_inventory] Updating inventory for:
    📞 Executing: send_customer_notifications
    [send_customer_notifications] Sending notifications: ORD-FAIL-001
    📞 Executing: generate_analytics
    [generate_analytics] Generating analytics: ORD-FAIL-001
    📞 Executing: process_loyalty_points
    [process_loyalty_points] Processing loyalty: CUST-FAIL-001
✅ Workflow completed successfully!
📊 Final Status: failed
🛣️  Execution Path: ValidateInput → CheckOrderType → RouteOrder → ProcessPremiumOrder → ProcessPayment → VerifyPaymentSuccess
⏱️  Execution Time: 0.0028 seconds
📈 States Visited: 6
📦 Final Output Summary:
   - order: id, total, customer_id, items, quantity, payment_method, shipping
   - $: validation_metadata
   - order_type_result: order_type, reason
   - premium_result: premium_processed, order_id, vip_handling, dedicated_support, processing_tier, priority_level
   - payment_result: status, payment_id, amount_charged, currency, processed_at, attempts

🎉 All tests completed!

📋 State Types Demonstrated:
   ✅ Pass     - Data transformation
   ✅ Task     - Business logic execution
   ✅ Choice   - Conditional routing
   ✅ Parallel - Concurrent branch execution
   ✅ Succeed  - Successful termination
   ✅ Fail     - Error termination
   ✅ Retry    - Automatic retry mechanisms
   ✅ Catch    - Error handling blocks
```


## License
The gem is available as open source under the terms of the MIT License.

## Acknowledgments
Inspired by AWS Step Functions state language

Built for Ruby developers who need workflow orchestration

Designed for both simple and complex business processes

## Author
 - Hussain Pithawala (https://www.linkedin.com/in/hussainpithawala)
