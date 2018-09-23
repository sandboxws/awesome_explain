require 'spec_helper'

RSpec.describe AwesomeExplain::Utils::Color do
  describe 'color printing' do
    it 'defines the correct color escapes' do
      expect(AwesomeExplain::Utils::Color::COLOR_ESCAPES).to eq({
        none: 0, bright: 1, black: 30,
        red: 31, green: 32, yellow: 33,
        blue: 34, magenta: 35, cyan: 36,
        white: 37, default: 39
      })
    end

    it 'returns string with the correct foreground color' do
      expect(AwesomeExplain::Utils::Color.fg_color(:red, 'AwesomeExplain')).to eq("\e[31mAwesomeExplain\e[0m")
    end
  end
end
