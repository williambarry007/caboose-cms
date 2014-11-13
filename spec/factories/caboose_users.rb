require 'faker'

FactoryGirl.define do
  factory :caboose_user, :class => Caboose::User do |f|
    f.first_name           { Faker::Name.first_name }
    f.last_name            { Faker::Name.last_name }
    f.username             { Faker::Internet.user_name }
    f.email                { Faker::Internet.email }
    f.address              { Faker::Address.street_address }
    f.address2             { Faker::Address.secondary_address }
    f.city                 { Faker::Address.city }
    f.state                { Faker::Address.state }
    f.zip                  { Faker::Address.zip }
    f.phone                { Faker::PhoneNumber.phone_number }
    f.fax                  { Faker::PhoneNumber.phone_number }            
    f.password             { Faker::Internet.password(20) }    
    f.date_created         { Faker::Time.between(1.year.ago, Time.now, :all) }
  end
end
