Caboose::Engine.routes.draw do
  
  # Note: this needs to be at the top of the application routes file for caboose routes to work
  #if Caboose::use_comment_routes
  #  eval(Caboose::CommentRoutes.controller_routes)      
  #end
  
  get '*path' => 'pages#show'
  root :to => 'pages#show'
  
end
