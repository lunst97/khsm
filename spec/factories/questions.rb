# (c) goodprogrammer.ru
# Объявление фабрики для создания нужных в тестах объектов
# см. другие примеры на
# http://www.rubydoc.info/gems/factory_girl/file/GETTING_STARTED.md

FactoryGirl.define do
  factory :question do
    # Ответы сделаем рандомными для красоты
    answer1 { "f#{rand(2001)}" }
    answer2 { "d#{rand(2001)}" }
    answer3 { "s#{rand(2001)}" }
    answer4 { "q#{rand(2001)}" }

    sequence(:text) { |n| "В каком году была космическая одиссея e #{n}?" }

    sequence(:level) { |n| n % 15 }
  end
end

# PS: неплохой фильмец
# https://ru.wikipedia.org/wiki/Космическая_одиссея_2001_года
