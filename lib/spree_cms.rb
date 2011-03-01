require 'spree_core'
require 'spree_cms_hooks'

module SpreeCms
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)
    
    initializer "cms" do
      require 'extensions/string'
    end
    
	  def self.activate
	    
	    Disqus::defaults[:account] = "my_disqus_account_name"
      # Optional, only if you're using the API
      Disqus::defaults[:api_key] = "my_disqus_api_key"    
      Disqus::defaults[:developer] = (RAILS.env != "production")
      
	    Spree::BaseController.class_eval do
        helper CmsHelper      

        before_filter :render_page_if_exists

        def render_page_if_exists
          # Using request.path allows us to override dynamic pages including
          # the home page, product and taxon pages. params[:path] is only good
          # for requests that get as far as content_controller. params[:path]
          # query left in for backwards compatibility for slugs that don't start
          # with a slash.
          @page = Page.publish.find_by_permalink(params[:path]) if params[:path]
          @page = Page.publish.find_by_permalink(request.path) unless @page
          render :template => 'content/show' if @page
        end      

        # Returns post.title for use in the <title> element. 
        def title_with_cms_post_check
          return "#{@post.title} - #{Spree::Config[:site_name]}" if @post && !@post.title.blank?
          title_without_cms_post_check
        end
        alias_method_chain :title, :cms_post_check      

      end

      AppConfiguration.class_eval do
        preference :cms_permalink, :string, :default => 'blog'      
        preference :cms_posts_per_page, :integer, :default => 5
        preference :cms_posts_recent, :integer, :default => 15
        preference :cms_post_comment_default, :integer, :default => 1
        preference :cms_post_status_default, :integer, :default => 0
        preference :cms_page_status_default, :integer, :default => 0
        preference :cms_page_comment_default, :integer, :default => 0
        preference :cms_rss_description, :string, :default => 'description about your main post rss.'
      end  

      User.class_eval do
          has_many :posts

          attr_accessible :display_name        
      end

	  end

    config.to_prepare  &method(:activate).to_proc
	end
end