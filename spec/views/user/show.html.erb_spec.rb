require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:user) { FactoryBot.create(:user, name: 'TestUser') }

  context 'authorized user' do
    before do
      assign(:games, [FactoryBot.build_stubbed(:game, finished_at: '2023-01-10 10:00:00', current_level: 2, prize: 100)])
      assign(:user, user)
      sign_in user

      render
    end

    it 'render user name' do
      expect(rendered).to match('TestUser')
    end

    it 'render change password button' do
      expect(rendered).to match('Сменить имя и пароль')
    end

    it 'render game partial' do
      expect(rendered).to match('100')
    end
  end

  context 'not authorized user' do
    before do
      assign(:user, user)

      render
    end

    it 'not render change password button' do
      expect(rendered).not_to match('Сменить имя и пароль')
    end
  end
end
