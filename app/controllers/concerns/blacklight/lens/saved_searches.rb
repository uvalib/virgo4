# app/controllers/concerns/blacklight/lens/saved_searches.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight::Lens

  # Replacement for Blacklight::SavedSearches
  #
  # @see Blacklight::SavedSearches
  #
  # == Implementation Notes
  # This does not include Blacklight::SavedSearches to avoid executing its
  # `included` block -- which means that it has to completely recreate the
  # module.
  #
  module SavedSearches

    extend ActiveSupport::Concern

    included do |base|

      __included(base, 'Blacklight::Lens::SavedSearches')

      # =======================================================================
      # :section: Controller filter actions
      # =======================================================================

      if respond_to?(:before_action)
        before_action :require_user_authentication_provider
        before_action :verify_user
      end

    end

    # =========================================================================
    # :section: Blacklight::SavedSearches replacements
    # =========================================================================

    public

    # == GET /saved_searches
    #
    # This method replaces:
    # @see Blacklight::SavedSearches#index
    #
    # Compare with:
    # @see Blacklight::Lens::SearchHistory#index
    #
    def index
      @searches = @user.searches
      respond_to do |format|
        format.html { }
        format.json { @presenter = json_presenter(@searches) }
      end
    end

    # == PUT /saved_searches/save/:id
    #
    # This method replaces:
    # @see Blacklight::SavedSearches#save
    #
    def save
      @user.searches << searches_from_history.find(params[:id])
      if @user.save
        go_back notice: I18n.t('blacklight.saved_searches.add.success')
      else
        go_back error:  I18n.t('blacklight.saved_searches.add.failure')
      end
    end

    # == DELETE /saved_searches/forget/:id
    # == POST   /saved_searches/forget/:id
    # Only dereferences the user rather than removing the item in case it is in
    # the session[:history].
    #
    # This method replaces:
    # @see Blacklight::SavedSearches#forget
    #
    def forget
      search = @user.searches.find(params[:id])
      if search.present?
        search.user_id = nil
        search.save
        go_back notice: I18n.t('blacklight.saved_searches.remove.success')
      else
        go_back error:  I18n.t('blacklight.saved_searches.remove.failure')
      end
    end

    # == DELETE /saved_searches/clear
    # Only dereferences the user rather than removing the items in case they
    # are in the session[:history].
    #
    # This method replaces:
    # @see Blacklight::SavedSearches#clear
    #
    # Compare with:
    # @see Blacklight::Lens::SearchHistory#clear
    #
    def clear
      if @user.searches.update_all('user_id = NULL')
        flash[:notice] = I18n.t('blacklight.saved_searches.clear.success')
      else
        flash[:error]  = I18n.t('blacklight.saved_searches.clear.failure')
      end
      redirect_to saved_searches_path
    end

    # =========================================================================
    # :section: Blacklight::SavedSearches replacements
    # =========================================================================

    protected

    # Called before each action to ensure that saved search operations are
    # limited to logged in users.
    #
    # @raise [Blacklight::Exceptions::AccessDenied]  If session is anonymous.
    #
    # This method replaces:
    # @see Blacklight::SavedSearches#verify_user
    #
    def verify_user
      return if (@user = current_user)
      flash[:notice] = I18n.t('blacklight.saved_searches.need_login')
      raise Blacklight::Exceptions::AccessDenied
    end

  end

end

__loading_end(__FILE__)
