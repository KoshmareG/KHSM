require 'rails_helper'

RSpec.describe GameQuestion, type: :model do
  let(:game_question) { FactoryBot.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  context 'game status' do
    it '#variants' do
      expect(game_question.variants).to eq({
        'a' => game_question.question.answer2,
        'b' => game_question.question.answer1,
        'c' => game_question.question.answer4,
        'd' => game_question.question.answer3
      })
    end

    it '#answer_correct?' do
      expect(game_question.answer_correct?('b')).to be_truthy
    end

    it '#correct_answer_key' do
      expect(game_question.correct_answer_key).to eq('b')
    end
  end

  describe '#text' do
    it 'returns correct text' do
      expect(game_question.text).to eq(game_question.question.text)
    end
  end

  describe '#level' do
    it 'returns correct level' do
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  describe '#help_hash' do
    context 'uses fifty fifty' do
      before do
        expect(game_question.help_hash).not_to include(:fifty_fifty)
        game_question.add_fifty_fifty
      end

      it 'returns help hash with fifty fifty' do
        expect(game_question.help_hash).to include(:fifty_fifty)
      end

      it 'returns correct varians count' do
        expect(game_question.help_hash[:fifty_fifty].size).to eq(2)
      end

      it 'includes correct answer' do
        expect(game_question.help_hash[:fifty_fifty]).to include(game_question.correct_answer_key)
      end
    end

    context 'uses audience help' do
      before do
        expect(game_question.help_hash).not_to include(:audience_help)
        game_question.add_audience_help
      end

      it 'returns help hash with audience help' do
        expect(game_question.help_hash).to include(:audience_help)
      end

      it 'returns all answers varians' do
        expect(game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      end

      it 'returns hash' do
        expect(game_question.help_hash[:audience_help]).to be_an_instance_of(Hash)
      end
    end

    context 'uses audience help after fifty fifty' do
      before do
        game_question.add_fifty_fifty
        game_question.add_audience_help
      end

      it 'returns correct answers count' do
        expect(game_question.help_hash[:audience_help].keys.size).to eq(2)
      end

      it 'includes correct answer' do
        expect(game_question.help_hash[:audience_help].keys).to include(game_question.correct_answer_key)
      end
    end

    context 'uses friend call' do
      before do
        expect(game_question.help_hash).not_to include(:friend_call)
        game_question.add_friend_call
      end

      it 'returns help hash with friend call' do
        expect(game_question.help_hash).to include(:friend_call)
      end

      it 'returns string' do
        expect(game_question.help_hash[:friend_call]).to be_an_instance_of(String)
      end
    end
  end
end
