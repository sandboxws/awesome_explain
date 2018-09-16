module AwesomeExplain
  module Renderers
    class Mongoid
      attr_reader :result, :query

      COLOR_ESCAPES = {
        none: 0, bright: 1, black: 30,
        red: 31, green: 32, yellow: 33,
        blue: 34, magenta: 35, cyan: 36,
        white: 37, default: 39
      }

      def initialize(query)
        @query = query
      end

      def print
        @result = query.explain

        print_general_info
      end

      # Text foreground color
      def fg_color(clr, text = nil)
        "\x1B[" + (COLOR_ESCAPES[clr] || 0).to_s + 'm' + (text ? text + "\x1B[0m" : '')
      end

      # Text background color
      def bg_color(clr, text = nil)
        "\x1B[" + ((COLOR_ESCAPES[clr] || 0) + 10).to_s + 'm' + (text ?  text + "\x1B[0m" : '')
      end

      def print_general_info
        ap result, indent: -2
        table = Terminal::Table.new do |t|
          winning_plan_label = 'Winning Plan'
          plan_data = winning_plan_data
          winning_plan_str = plan_data[0]
          used_indexes = plan_data[1]
          winning_plan_label = fg_color :red, winning_plan_label if winning_plan_str =~ /COLLSCAN/
          t << [winning_plan_label, winning_plan_str]
          t << :separator
          t << ['Used Indexes', used_indexes.join(', ')]
          if execution_stats
            t << :separator
            t << ['Rejected Plans', rejected_plans.size]
            t << :separator
            t << ['Documents Returned', execution_stats.dig('nReturned')]
            t << :separator
            t << ['Documents Examined', execution_stats.dig('totalDocsExamined')]
            t << :separator
            t << ['Keys Examined', execution_stats.dig('totalKeysExamined')]
            t << :separator

            # Execution Time
            exec_time = execution_stats.dig('executionTimeMillis').to_f/1000
            exec_time_ms = execution_stats.dig('executionTimeMillis')
            exec_label = 'Execution time(s)'
            exec_label_ms = 'Execution time(ms)'

            if exec_time > 10
              exec_label = fg_color :red, exec_label
              exec_label_ms = fg_color :red, exec_label_ms
            end
            t << [exec_label_ms, exec_time_ms]
            t << :separator
            t << [exec_label, exec_time]
          end
        end

        puts
        puts table
        puts
      end

      def winning_plan_data
        used_indexes = []
        plan = winning_plan
        plan_str = stage_label_and_stats(plan)
        plan_str = dig_input_stages(plan.dig('inputStage'), plan_str, used_indexes) if plan['inputStage']

        [plan_str, used_indexes]
      end

      def root
        result.dig('$cursor') || result
      end

      def winning_plan
        root.dig('executionStats', 'executionStages') || root.dig('queryPlanner', 'winningPlan')
      end

      def rejected_plans
        root.dig('queryPlanner', 'rejectedPlans')
      end

      def execution_stats
        root.dig('executionStats')
      end

      def dig_input_stages(stage, str, used_indexes, input_stages = false)
        used_indexes << "#{stage.dig('indexName')} (#{stage.dig('direction')})" if stage.dig('indexName').present?
        if stage.dig('inputStage').nil? && stage.dig('inputStages').nil?
          str += ' -> ' + stage_label_and_stats(stage)
        end
        if stage.dig('inputStage').present?
          str += ' ->' if !input_stages
          str += ' ' + stage_label_and_stats(stage)
          str = dig_input_stages(stage.dig('inputStage'), str, used_indexes, input_stages)
        end

        if stage.dig('inputStages').present?
          str += ' -> ' + stage_label_and_stats(stage) + ' ->'
          str += ' [ '
          stage.dig('inputStages').each_with_index do |s, idx|
            str = dig_input_stages(s, str, used_indexes, true)
            str += ' , ' if idx < stage.dig('inputStages').size - 1
          end
          str += ' ] '
        end

        str
      end

      def stage_label_and_stats(stage)
        str = "#{stage.dig('stage')} ("
        str += "#{stage.dig('docsExamined')} / " if stage.dig('docsExamined').present?
        str += stage.dig('nReturned').to_s if stage.dig('nReturned').present?
        str += ')'

        str.gsub(' ()', '')
      end
    end
  end
end
