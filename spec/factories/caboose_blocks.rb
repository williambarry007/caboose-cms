require 'faker'

FactoryGirl.define do
  factory :caboose_block, :class => Caboose::Block do |f|
    f.page_id             { nil }
    f.parent_id           { nil }
    f.block_type_id       { nil }
    f.sort_order          { rand(0..10) }
    f.name                { Faker::Internet.user_name }
    f.value               { Faker::Lorem.sentence }
    f.file_file_name      { "#{Faker::Lorem.word}.#{['pdf','xls','csv'].sample}" }
    f.file_content_type   { ['application/pdf','application/xls'].sample }
    f.file_file_size      { rand(100..100000) }
    f.file_updated_at     { Faker::Time.between(1.month.ago, Time.now, :all) }
    f.image_file_name     { "#{Faker::Lorem.word}.#{['gif','jpg','png'].sample}" }
    f.image_content_type  { ['image/gif','image/jpeg','image/png'].sample }
    f.image_file_size     { rand(100..100000) }
    f.image_updated_at    { Faker::Time.between(1.month.ago, Time.now, :all) }        
  end
end
