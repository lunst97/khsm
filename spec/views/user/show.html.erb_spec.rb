require 'rails_helper'

RSpec.describe 'users/show', type: :view do

  describe 'view show profile' do
    before(:each) do
      user = assign(:user, FactoryGirl.build_stubbed(:user, name: 'Вадик'))
      allow(view).to receive(:current_user).and_return(user)

      render
    end
    context 'user view' do
      it 'your name' do
        expect(rendered).to match 'Вадик'
      end

      it 'button editing profile' do
        expect(rendered).to match 'Сменить имя и пароль'
      end

      it 'last your game' do
        assign(:games, [FactoryGirl.build_stubbed(:game)])
        stub_template 'users/_game.html.erb' => 'Игра существует'

        render
        expect(rendered).to match 'Игра существует'
      end
    end
  end
end
