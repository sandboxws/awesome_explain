module AwesomeExplain
  module Utils
    class Color
      COLOR_ESCAPES = {
        none: 0, bright: 1, black: 30,
        red: 31, green: 32, yellow: 33,
        blue: 34, magenta: 35, cyan: 36,
        white: 37, default: 39
      }

      def self.fg_color(clr, text)
        "\x1B[" + (COLOR_ESCAPES[clr] || 0).to_s + 'm' + (text ? text + "\x1B[0m" : '')
      end
    end
  end
end
