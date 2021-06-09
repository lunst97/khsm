require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  describe 'view show profile' do
    let(:user) { FactoryGirl.create(:user, name: 'Алекс') }

    before(:each) do
      assign(:user, user)
      assign(:games, [FactoryGirl.build_stubbed(:game, id: 1, current_level: 2, prize: 200)])

      render
    end

    context 'current user view' do
      before(:each) do
        login_as user

        render
      end

      it 'your name' do
        expect(rendered).to match 'Алекс'
      end

      it 'button editing profile' do
        expect(rendered).to match 'Сменить имя и пароль'
      end

      it 'last your game' do
        stub_template 'users/_game.html.erb' => 'Игра существует'

        render
        expect(rendered).to match 'Игра существует'
      end

      it 'view game' do
        expect(rendered).to match '2'
        expect(rendered).to match '200'
      end
    end

    context 'another user view' do
      it 'your name' do
        expect(rendered).to match 'Алекс'
      end

      it 'button editing profile' do
        expect(rendered).not_to match 'Сменить имя и пароль'
      end

      it 'last your game' do
        stub_template 'users/_game.html.erb' => 'Игра существует'

        render
        expect(rendered).to match 'Игра существует'
      end

      it 'view game' do
        expect(rendered).to match '2'
        expect(rendered).to match '200'
      end
    end
  end
end
