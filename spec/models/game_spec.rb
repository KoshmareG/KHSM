require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) { create(:user) }
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      generate_questions(60)

      game = nil

      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15).and(
          change(Question, :count).by(0)
        )
      )

      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  context 'game mechanics' do
    it 'answer correct continues game' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)


      expect(game_w_questions.current_level).to eq(level + 1)

      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_game_question).not_to eq(q)

      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions).not_to be_finished
    end

    it 'take money ends the game' do
      game_w_questions.answer_current_question!(game_w_questions.current_game_question.correct_answer_key)
      game_w_questions.take_money!

      prize = Game::PRIZES[game_w_questions.previous_level]

      expect(game_w_questions).to be_finished
      expect(game_w_questions.status).to eq(:money)
      expect(game_w_questions.prize).to eq(prize)
      expect(user.balance).to eq(prize)
    end
  end

  context '#status' do
    before do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions).to be_finished
    end

    it 'returns :won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it 'returns :fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it 'returns :timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it 'returns :money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  describe '#current_game_question' do
    it 'returns first qustion' do
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions.first)
    end
  end

  describe '#previous_level' do
    it 'returns previous level' do
      expect(game_w_questions.previous_level).to eq(-1)
    end
  end

  describe '#answer_current_question!' do
    context 'correct answer' do
      let(:correct_answer) { game_w_questions.current_game_question.correct_answer_key }

      it 'returns true' do
        expect(game_w_questions.answer_current_question!(correct_answer)).to be_truthy
      end

      it 'returns next level' do
        game_w_questions.answer_current_question!(correct_answer)

        expect(game_w_questions.current_level).to eq(1)
      end
    end

    context 'wrong answer' do
      let(:wrong_answer) {%w[a b c d].grep_v(game_w_questions.current_game_question.correct_answer_key).sample}

      it 'returns false' do
        expect(game_w_questions.answer_current_question!(wrong_answer)).to be_falsey
      end

      it 'returns true' do
        game_w_questions.answer_current_question!(wrong_answer)

        expect(game_w_questions).to be_finished
      end
    end

    context 'correct answer for last question' do
      before do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max
        correct_answer = game_w_questions.current_game_question.correct_answer_key
        expect(game_w_questions.answer_current_question!(correct_answer)).to be_truthy
      end

      it 'returns true' do
        expect(game_w_questions).to be_finished
      end

      it 'returns :won' do
        expect(game_w_questions.status).to eq(:won)
      end

      it 'returns previous level' do
        expect(user.balance).to eq(prize = Game::PRIZES[game_w_questions.previous_level])
      end
    end

    context 'timeout' do
      it 'returns false' do
        game_w_questions.created_at = 1.hour.ago
        correct_answer = game_w_questions.current_game_question.correct_answer_key

        expect(game_w_questions.answer_current_question!(correct_answer)).to be_falsey
      end
    end
  end
end
