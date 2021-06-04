# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для модели Игры
# В идеале - все методы должны быть покрыты тестами,
# в этом классе содержится ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { FactoryGirl.create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # генерим 60 вопросов с 4х запасом по полю level,
      # чтобы проверить работу RANDOM при создании игры
      generate_questions(60)

      game = nil
      # создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(# проверка: Game.count изменился на 1 (создали в базе 1 игру)
        change(GameQuestion, :count).by(15).and(# GameQuestion.count +15
          change(Question, :count).by(0) # Game.count не должен измениться
        )
      )
      # проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      # проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end


  # тесты на основную игровую логику
  context 'game mechanics' do

    # правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)
      # ранее текущий вопрос стал предыдущим
      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_game_question).not_to eq(q)
      # игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end
  end

  context 'take_money!' do
    it 'working take money' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      game_w_questions.take_money!

      prize = game_w_questions.prize

      expect(prize).to eq(100)
      expect(prize).to be > 0

      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize

    end
  end

  context '.status' do

    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it 'timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it 'money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  describe 'check current_game_question / previous_level' do
    context 'when questions' do
      context 'check current questions' do
        it 'return current question' do
          expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions[0])
        end
      end

      context 'check uncurrent questions' do
        it 'return uncurrent question' do
          expect(game_w_questions.current_game_question).to_not eq(game_w_questions.game_questions[1])
        end
      end
    end

    context 'when level' do
      context 'last' do
        let(:game_with_level) { FactoryGirl.create(:game_with_questions, user: user, current_level: 14) }
        it 'check previous level' do
          expect(game_with_level.previous_level).to eq(13)
          expect(game_with_level.finished?).to be_falsey
          expect(game_with_level.status).to eq(:in_progress)
        end
      end

      context 'when level' do
        context 'not last' do
          let(:game_with_level) { FactoryGirl.create(:game_with_questions, user: user, current_level: 2) }
          it 'check previous level' do
            expect(game_with_level.previous_level).to eq(1)
            expect(game_with_level.finished?).to be_falsey
            expect(game_with_level.status).to eq(:in_progress)
          end
        end
      end

      context 'when level is' do
        context 'time out' do
          let(:game_with_level_timeout) { FactoryGirl.create(:game_with_questions, user: user, current_level: 2) }
          it 'check previous level' do
            game_with_level_timeout.created_at = 1.hour.ago
            expect(game_with_level_timeout.previous_level).to eq(1)
            expect(game_with_level_timeout.finished?).to be_falsey
            expect(game_with_level_timeout.status).to eq(:in_progress)
          end
        end
      end
    end
  end

  describe 'answer_current_question!' do
    let(:answer) { game_w_questions.current_game_question.correct_answer_key }
    context 'when answer correct' do
      context 'and question is not last' do
        let(:game_with_level_correct) { FactoryGirl.create(:game_with_questions, user: user, current_level: 2) }
        it 'should answer correct and status game :in_progress' do
          expect(game_with_level_correct.answer_current_question!(answer)).to be_truthy
          expect(game_with_level_correct.finished?).to be_falsey
          expect(game_with_level_correct.status).to eq(:in_progress)
        end
      end

      context 'and question is last' do
        let(:game_with_level_correct) { FactoryGirl.create(:game_with_questions, user: user, current_level: 14) }
        it 'should answer correct and status game :won' do
          expect(game_with_level_correct.answer_current_question!(answer)).to be_truthy
          expect(game_with_level_correct.finished?).to be_truthy
          expect(game_with_level_correct.status).to eq(:won)
        end
      end

      context 'and time is timeout' do
        let(:game_with_timeout) { FactoryGirl.create(:game_with_questions, user: user, created_at: 1.hour.ago) }
        it 'should answer correct and status game :timeout' do
          expect(game_with_timeout.answer_current_question!(answer)).to be_falsey
          expect(game_with_timeout.finished?).to be_truthy
          expect(game_with_timeout.status).to eq(:timeout)
        end
      end
    end

    context 'when answer correct' do
      context 'and question is not last' do
        it 'should answer uncorrect and status game :fail' do
          expect(game_w_questions.answer_current_question!('b')).to be_falsey
          expect(game_w_questions.status).to eq(:fail)
          expect(game_w_questions.finished?).to be_truthy
        end
      end

      context 'and question is last' do
        let(:game_with_level_correct) { FactoryGirl.create(:game_with_questions, user: user, current_level: 14) }
        it 'should answer uncorrect and status game :fail' do
          expect(game_with_level_correct.answer_current_question!('b')).to be_falsey
          expect(game_with_level_correct.status).to eq(:fail)
          expect(game_with_level_correct.finished?).to be_truthy
        end
      end

      context 'and question is timeout' do
        let(:game_with_timeout) { FactoryGirl.create(:game_with_questions, user: user, created_at: 1.hour.ago) }
        it 'should answer uncorrect and status game :timeout' do
          expect(game_with_timeout.answer_current_question!('f')).to be_falsey
          expect(game_with_timeout.status).to eq(:timeout)
          expect(game_with_timeout.finished?).to be_truthy
        end
      end
    end

    context 'when answer is last' do
      context 'and question is correct' do
        it 'should answer correct and status game :won' do
          game_w_questions.current_level = Question::QUESTION_LEVELS.max
          expect(game_w_questions.answer_current_question!(answer)).to be_truthy
          expect(game_w_questions.status).to eq(:won)
          expect(game_w_questions.finished?).to be_truthy
        end
      end
      context 'and question is uncorect' do
        it 'should answer uncorrect and status game :fail' do
          game_w_questions.current_level = Question::QUESTION_LEVELS.max
          expect(game_w_questions.answer_current_question!('b')).to be_falsey
          expect(game_w_questions.status).to eq(:fail)
          expect(game_w_questions.finished?).to be_truthy
        end
      end
      context 'and question is timeout' do
        let(:game_with_timeout) { FactoryGirl.create(:game_with_questions, user: user, created_at: 1.hour.ago) }
        it 'should answer correct and status game :timeout' do
          game_w_questions.current_level = Question::QUESTION_LEVELS.max
          expect(game_with_timeout.answer_current_question!(answer)).to be_falsey
          expect(game_with_timeout.status).to eq(:timeout)
          expect(game_with_timeout.finished?).to be_truthy
        end
      end
    end

    context 'when answer is timeout' do
      let(:game_timeout) {FactoryGirl.create(:game_with_questions, user: user, created_at: 1.hour.ago)}
      context 'and question is correct' do
        it 'should answer correct and status game :timeout' do
          expect(game_timeout.answer_current_question!(answer)).to be_falsey
          expect(game_timeout.status).to eq(:timeout)
          expect(game_timeout.finished?).to be_truthy
        end
      end
      context 'and question is uncorect' do
        it 'should answer uncorrect and status game :timeout' do
          expect(game_timeout.answer_current_question!('b')).to be_falsey
          expect(game_timeout.status).to eq(:timeout)
          expect(game_timeout.finished?).to be_truthy
        end
      end
    end
  end
end