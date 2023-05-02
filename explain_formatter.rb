require 'rspec/core/formatters/console_codes'


class ExplainFormatter
  RSpec::Core::Formatters.register self,
                                   :example_group_started,
                                   :example_group_finished,
                                   :start,
                                   :close,
                                   :stop,
                                   :example_passed,
                                   :example_failed,
                                   :example_pending,
                                   :dump_failures

  def initialize output
    @output = output

    @example_group_stats = Hash.new { |h, k| h[k] = { passed: 0, failed: 0 } }
    @current_group = nil
  end

  def start(notification)
    tests_count = notification.count

    system('clear')

    line(color: :bold_yellow)
    msg = "  #{Time.now.strftime('%H:%M:%S')} - Starting #{tests_count} Tests"
    text(msg, color: :bold_yellow)
    line(color: :bold_yellow)

    empty_line
    @fails_count = 0
  end

  def example_group_started(notification)
    return unless notification.group.parent_groups.count == 1

    @current_group = notification.group.description

    text("- #{notification.group.description}:\n", color: :bold_yellow)
  end

  def example_group_finished(notification)
    return unless notification.group.parent_groups.count == 1

    group_description = notification.group.description
    passed_count = @example_group_stats[group_description][:passed]
    failed_count = @example_group_stats[group_description][:failed]

    msg = @fails_count.positive? ? "😡 #{failed_count} example fails" : "🎉 ALL PASS"
    text("  #{msg}\n\n")
  end

  def example_passed(notification)
    text("  ✅ PASS - #{notification.example.full_description} \n", color: :green)
    @example_group_stats[@current_group][:passed] += 1
    sleep 0.02
  end

  def example_failed(notification)
    text("  ❌ FAIL ##{@fails_count + 1} - #{notification.example.full_description}\n", color: :red)
    @fails_count += 1
    @example_group_stats[@current_group][:failed] += 1
    sleep 0.02
  end

  def example_pending(notification)
    @output << "*"
  end

  def dump_failures(notification)
    return unless notification.failed_examples.count.positive?

    loop do
      option = prompt_user_input
      break unless process_option(option, notification)
    end
  end

  def stop(notification)
    fail_count = notification.failed_examples.count
    total_count = notification.examples.count

    if fail_count.positive?
      color = :bold_red
      msg = "  Finished. #{fail_count}/#{total_count} tests failed 😡"
    else
      color = :bold_green
      msg = "  Finished. No tests failed. 🎉🎉🎉"
    end

    line(color:)
    text(msg, color:)
    line(color:)
  end

  def close(notification)
    empty_line
  end

  private

  def empty_line(lines: 1)
    lines.times { @output << "\n" }
  end

  def line(color: :white, size: 80)
    @output << RSpec::Core::Formatters::ConsoleCodes.wrap("\n#{'-' * size}\n", color)
  end

  def text(text, color: :white)
    @output << RSpec::Core::Formatters::ConsoleCodes.wrap(text, color)
  end

  def display_failures(notification)
    system('clear')
    line
    notification.failure_notifications.each_with_index do |failure, index|
      text("FAIL ##{index + 1} - #{failure.description}\n", color: :red)
    end
    line
  end

  def prompt_user_input
    empty_line
    text("Enter fail number, (a)ll fails or (q)uit:\n", color: :bold_white)
    text("➡️  ")
    $stdin.gets.chomp.strip.downcase
  end

  def process_option(option, notification)
    case option
    when 'q' then return false
    when 'a' then display_failures(notification)
    else
      index = option.to_i - 1
      failure = notification.failure_notifications[index]
      display_failure(failure, index)
    end
    true
  end

  def display_all_failures(notification)
    notification.failed_examples.each_with_index do |failure, index|
      display_failure(failure, index)
    end
  end

  def display_failure(failure, index)
    system('clear')
    line(color: :bold_cyan)
    fail_msg = " FAIL ##{index + 1}: "
    text(fail_msg, color: :bold_cyan)
    text("#{failure.example.example_group.description}\n", color: :bold_yellow)
    text("#{' ' * fail_msg.size}#{failure.example.full_description}", color: :bold_white)
    line(color: :bold_cyan)
    empty_line
    display_error_message(failure)
    display_backtrace(failure)
    line(color: :bold_cyan)
  end

  def display_error_message(failure)
    text(" ERROR MESSAGE:\n", color: :bold_yellow)
    failure.colorized_message_lines.each do |line|
      @output << " " + line
      empty_line
    end
    empty_line
  end

  def display_backtrace(failure)
    text(" BACKTRACE:\n", color: :bold_yellow)
    failure.formatted_backtrace.each do |location|
      text(" #{location}\n")
    end
  end
end
