class Users::SessionsController < Devise::SessionsController
# before_filter :configure_sign_in_params, only: [:create]

    def after_sign_in_path_for(resource_or_scope)
          # your_path
          '/lobby/index'
     end

    def after_sign_out_path_for(resource_or_scope)
        # '/lobby/index'
    end

end
