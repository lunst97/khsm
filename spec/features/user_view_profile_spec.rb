require 'rails_helper'

RSpec.feature 'USER view profile', type: :feature do

  let(:user) { FactoryGirl.create :user }
  let(:second_user) { FactoryGirl.create :user}

  let!(:game_1) { FactoryGirl.create :game, user: second_user, current_level: 2, finished_at: Time.now, prize: 200 }
  let!(:game_2) { FactoryGirl.create :game, user: user, current_level: 5, prize: 0, finished_at: Time.now }

  before(:each) do
    login_as user
  end
  scenario 'authorize user view profile' do
    visit user_path(second_user)

    expect(page).to have_current_path '/users/2'
    expect(page).to have_content(second_user.name)
    expect(page).to have_content(2)
    expect(page).not_to have_content('Сменить имя и пароль')
    expect(page).to have_content('деньги')
    expect(page).to have_content(I18n.l(game_1.finished_at, format: :short))
    expect(page).to have_content(200)
    expect(page).to have_content('50/50')
  end

  scenario 'unuthorize user view profile' do
    visit user_path(user)

    expect(page).to have_current_path '/users/3'
    expect(page).to have_content(user.name)
    expect(page).to have_content(5)
    expect(page).to have_content('Сменить имя и пароль')
    expect(page).to have_content('деньги')
    expect(page).to have_content(I18n.l(game_2.finished_at, format: :short))
    expect(page).to have_content(0)
    expect(page).to have_content('50/50')
  end
end