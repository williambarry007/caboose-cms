|APP_NAME|::Application.routes.draw do

	# Catch everything with caboose
	mount Caboose::Engine => '/'
	match '*path' => 'caboose/pages#show'
  root :to      => 'caboose/pages#show'
	
end
