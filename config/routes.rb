Caboose::Engine.routes.draw do
  
  #if Caboose::use_comment_routes
  #  #puts "----------------------------------------------------------------------"
  #  #puts Caboose::CommentRoutes.controller_routes
  #  #puts "----------------------------------------------------------------------"
  #  
  #  eval(Caboose::CommentRoutes.controller_routes)      
  #end
  
  match '*path' => 'pages#show'
  root :to => 'pages#show'
  
end
