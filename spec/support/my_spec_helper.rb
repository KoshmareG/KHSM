module MySpecHelper

  # наш хелпер, для населения базы нужным количеством рандомных вопросов
  def generate_questions(number)
    number.times do
      create(:question)
    end
  end
end


RSpec.configure do |c|
  c.include MySpecHelper
  c.include FactoryBot::Syntax::Methods
end