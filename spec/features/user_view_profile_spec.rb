require 'rails_helper'

RSpec.feature 'should view profile', type: :feature do

  let(:user) { FactoryGirl.create :user }
  let(:second_user) { FactoryGirl.create :user}

  let!(:game_1) { FactoryGirl.create :game, user: second_user, current_level: 2, finished_at: Time.now, prize: 200 }

  scenario 'the profile of an authorize user' do
    login_as user

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
end