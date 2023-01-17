require 'rails_helper'

RSpec.feature 'USER looks another users profile ', type: :feature do
  let(:user) { create :user, name: 'Вася' }
  let!(:games) {[
    create(:game, created_at: '2023-01-10 10:14:25', finished_at: '2023-01-10 10:17:35', current_level: 4, is_failed: true, prize: 0, user_id: user.id),
    create(:game, created_at: '2023-01-11 10:17:15', finished_at: '2023-01-11 10:25:25', current_level: 5, is_failed: false, prize: 1000, user_id: user.id),
    create(:game, created_at: '2023-01-12 10:20:35', finished_at: '2023-01-12 10:50:31', current_level: 15, is_failed: false, prize: 1000000, user_id: user.id)
  ]}

  before do
    visit user_path(user)
  end

  scenario 'user see correct info about first games' do
    expect(page).to have_content('10 янв., 10:14')
    expect(page).to have_content('4')
    expect(page).to have_content('0')
    expect(page).to have_content('проигрыш')
  end

  scenario 'user see correct info about second games' do
    expect(page).to have_content('11 янв., 10:17')
    expect(page).to have_content('5')
    expect(page).to have_content('1 000')
    expect(page).to have_content('деньги')
  end

  scenario 'user see correct info about third games' do
    expect(page).to have_content('12 янв., 10:20')
    expect(page).to have_content('15')
    expect(page).to have_content('1 000 000')
    expect(page).to have_content('победа')
  end

  scenario 'user not see change password button' do
    expect(page).not_to have_content('Сменить имя и пароль')
  end
end
