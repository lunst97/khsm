# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса,
# в идеале весь наш функционал (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do

  # задаем локальную переменную game_question, доступную во всех тестах этого сценария
  # она будет создана на фабрике заново для каждого блока it, где она вызывается
  let(:game_question) { FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  # группа тестов на игровое состояние объекта вопроса
  describe 'game status' do
    context 'when status work correct' do
      # тест на правильную генерацию хэша с вариантами
      it 'should current answers hash' do
        expect(game_question.variants).to eq({'a' => game_question.question.answer2,
                                              'b' => game_question.question.answer1,
                                              'c' => game_question.question.answer4,
                                              'd' => game_question.question.answer3})
      end

      it 'should current answer' do
        # именно под буквой b в тесте мы спрятали указатель на верный ответ
        expect(game_question.answer_correct?('b')).to be_truthy
      end
    end
  end


  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказски остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }
  #

  context 'user helpers' do
    it 'correct audience_help' do
      expect(game_question.help_hash).not_to include(:audience_help)

      game_question.add_audience_help

      expect(game_question.help_hash).to include(:audience_help)

      ah = game_question.help_hash[:audience_help]
      expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
    end
  end

  context 'text level' do
    it 'test text level' do
      expect(game_question.text).to eq(game_question.question.text)
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  context 'correct_answer_key' do
    it 'current answer' do
      expect(game_question.correct_answer_key).to eq('b')
    end
  end

  describe 'help_hash' do
    let(:game_question) { FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3) }
    context 'when answers not empty' do
      it 'should answers hash' do
        expect(game_question.help_hash).to eq({})

        game_question.help_hash[:some_key1] = 'blabla1'
        game_question.help_hash[:some_key2] = 'blabla2'

        expect(game_question.save).to be_truthy

        gq = GameQuestion.find(game_question.id)

        expect(gq.help_hash).to eq({some_key1: 'blabla1', some_key2: 'blabla2'})
      end
    end

    context 'when used fifty_fifty' do
      it 'should current answers hash' do
        expect(game_question.help_hash).not_to include(:fifty_fifty)

        game_question.add_fifty_fifty

        expect(game_question.help_hash).to include(:fifty_fifty)
        ff = game_question.help_hash[:fifty_fifty]

        expect(ff).to include('b')
        expect(ff.size).to eq 2
      end
    end

    context 'when used friend_call' do
      it 'should current answers hash' do
        expect(game_question.help_hash).not_to include(:friend_call)

        game_question.add_friend_call

        expect(game_question.help_hash).to include(:friend_call)
        fc = game_question.help_hash[:friend_call]

        expect(fc).to be
        expect(fc.last).to match("#{/^[A|B|C|D]\z/}")
      end
    end
  end
end
