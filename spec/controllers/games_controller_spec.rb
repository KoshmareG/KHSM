require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  shared_examples 'anonymous cant gaming' do
    it 'returns status not to 200' do
      expect(response.status).not_to eq(200)
    end

    it 'redirect to new user session' do
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns flash alert' do
      expect(flash[:alert]).to be
    end
  end

  describe '#show' do
    context 'when anonymous' do
      before { get :show, id: game_w_questions.id }

      include_examples 'anonymous cant gaming'
    end

    context 'when signed in user' do
      let(:game) { assigns(:game) }

      before do
        sign_in user
        get :show, id: game_w_questions.id
      end

      it 'it returns status to 200' do
        expect(response.status).to eq(200)
      end

      it 'returns that game not be finished' do
        expect(game).not_to be_finished
      end

      it 'returns game user' do
        expect(game.user).to eq(user)
      end

      it 'returns show template' do
        expect(response).to render_template('show')
      end
    end
  end

  describe '#create' do
    context 'when anonymous' do
      before { expect { post :create }.to change(Game, :count).by(0) }

      include_examples 'anonymous cant gaming'
    end

    context 'when signed in user' do
      let(:game) { assigns(:game) }

      before do
        sign_in user
        generate_questions(15)
        post :create
      end

      it 'returns that game not be finished' do
        expect(game).not_to be_finished
      end

      it 'reutrns game user' do
        expect(game.user).to eq(user)
      end

      it 'redirect to game path' do
        expect(response).to redirect_to(game_path(game))
      end

      it 'returns flash notice' do
        expect(flash[:notice]).to be
      end
    end
  end

  describe '#answer' do
    context 'when anonymous' do
      before { put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }

      include_examples 'anonymous cant gaming'
    end

    context 'signed in user giving correct answer' do
      let(:game) { assigns(:game) }

      before do
        sign_in user
        put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
      end

      it 'returns that game not be finished' do
        expect(game).not_to be_finished
      end

      it 'reutrns next level' do
        expect(game.current_level).to be > 0
      end

      it 'redirect to game path' do
        expect(response).to redirect_to(game_path(game))
      end
    end

    context 'signed in user giving wrong answer' do
      let(:wrong_answer) { %w[a b c d].grep_v(game_w_questions.current_game_question.correct_answer_key).sample }
      let(:game) { assigns(:game) }

      before do
        sign_in user
        put :answer, id: game_w_questions.id, letter: wrong_answer
      end

      it 'returns game finished' do
        expect(game).to be_finished
      end

      it 'returns :fail' do
        expect(game.status).to eq(:fail)
      end

      it 'redirect to user path' do
        expect(response).to redirect_to(user_path(user))
      end

      it 'returns flash alert' do
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#take_money' do
    context 'when anonymous' do
      before { put :take_money, id: game_w_questions.id }

      include_examples 'anonymous cant gaming'
    end

    context 'when signed in user' do
      let(:game) { assigns(:game) }
      let(:prize) { Game::PRIZES[game_w_questions.previous_level] }

      before do
        sign_in user
        game_w_questions.update_attribute(:current_level, 2)
        put :take_money, id: game_w_questions.id
      end

      it 'redirect to user path' do
        expect(response).to redirect_to(user_path(user))
      end

      it 'returns game status money' do
        expect(game.status).to eq(:money)
      end

      it 'returns flash warning' do
        expect(flash[:warning]).to be
      end

      it 'returns that game be finished' do
        expect(game).to be_finished
      end

      it 'returns correct game prize' do
        expect(game.prize).to eq(prize)
      end

      it 'returns user balance' do
        user.reload
        expect(user.balance).to eq(prize)
      end
    end
  end

  describe '#help' do
    context 'when anonymous' do
      before { put :help, id: game_w_questions.id }

      include_examples 'anonymous cant gaming'
    end

    context 'signed in user uses audience help' do
      let(:game) { assigns(:game) }

      before do
        sign_in user

        expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
        expect(game_w_questions.audience_help_used).to be_falsey

        put :help, id: game_w_questions.id, help_type: :audience_help
      end

      it 'returns that game not be finished' do
        expect(game).not_to be_finished
      end

      it 'returns that audience help was be used' do
        expect(game.audience_help_used).to be_truthy
      end

      it 'returns that help hash includes audience help' do
        expect(game.current_game_question.help_hash[:audience_help]).to be
      end

      it 'redirect to game path' do
        expect(response).to redirect_to(game_path(game))
      end
    end

    context 'signed in user uses fifty fifty' do
      let(:game) { assigns(:game) }

      before do
        sign_in user

        expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
        expect(game_w_questions.fifty_fifty_used).to be_falsey

        put :help, id: game_w_questions.id, help_type: :fifty_fifty
      end

      it 'returns that game not be finished' do
        expect(game).not_to be_finished
      end

      it 'returns that audience help was be used' do
        expect(game.fifty_fifty_used).to be_truthy
      end

      it 'returns that help hash includes audience help' do
        expect(game.current_game_question.help_hash[:fifty_fifty]).to be
      end

      it 'redirect to game path' do
        expect(response).to redirect_to(game_path(game))
      end
    end

    context 'signed in user uses fifty fifty' do
      let(:game) { assigns(:game) }

      before do
        sign_in user

        expect(game_w_questions.current_game_question.help_hash[:friend_call]).not_to be
        expect(game_w_questions.friend_call_used).to be_falsey

        put :help, id: game_w_questions.id, help_type: :friend_call
      end

      it 'returns that game not be finished' do
        expect(game).not_to be_finished
      end

      it 'returns that audience help was be used' do
        expect(game.friend_call_used).to be_truthy
      end

      it 'returns that help hash includes audience help' do
        expect(game.current_game_question.help_hash[:friend_call]).to be
      end

      it 'redirect to game path' do
        expect(response).to redirect_to(game_path(game))
      end
    end
  end

  describe 'unavailable actions' do
    context 'user to watch foreign game' do
      let(:foreign_game) { FactoryBot.create(:game_with_questions) }

      before do
        sign_in user
        get :show, id: foreign_game.id
      end

      it 'returns status not to 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to root path' do
        expect(response).to redirect_to(root_path)
      end

      it 'returns flash alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'redirect to in progress game when creating new' do
      let(:game) { assigns(:game) }

      before do
        expect(game_w_questions).not_to be_finished
        expect { post :create }.to change(Game, :count).by(0)
        sign_in user
        get :create
      end

      it 'returns nil' do
        expect(game).to be_nil
      end

      it 'returns status not to 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to in progress game' do
        expect(response).to redirect_to(game_path(game_w_questions))
      end

      it 'returns flash alert' do
        expect(flash[:alert]).to be
      end
    end
  end
end
