Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  root to: 'static#index'
  scope 'api', defaults: { format: :json } do
    get '/auth/:provider/callback' => 'sessions#create'
    if Rails.env.development?
      post '/auth/:provider/callback' => 'sessions#create'
    end
    get '/sign_out' => 'sessions#destroy', as: :signout
    get '/current_user' => 'sessions#show'

    scope 'datatables' do
      get 'variants' => 'variants#datatable'
      get 'genes' => 'genes#datatable'
      get 'variant_groups' => 'variant_groups#datatable'
      get 'sources' => 'sources#datatable'
      get 'evidence_items' => 'evidence_items#datatable'
      get 'source_suggestions' => 'sources#suggestions_datatable'
      get 'assertions' => 'assertions#datatable'
    end
    get '/variants/typeahead_results' => 'variants#typeahead_results'

    get '/events' => 'events#index'
    get '/events/:root_type/:root_id' => 'events#scoped_index',
      root_type: /(gene|variant|evidence_item|variant_group|suggested_change)s?/i

    get '/text/:term' => 'text#show'
    get '/text' => 'text#index'

    scope 'ccc' do
      get 'genes/:entrez_id/variants' => 'variants#entrez_gene_index'
      get 'genes/:entrez_id' =>  'genes#entrez_show'
      get 'entrez_ids' => 'genes#entrez_index'
    end

    scope 'typeahead_searches' do
      get 'variants' => 'typeahead_searches#variants'
    end

    scope 'stats' do
      get 'site' => 'stats#site_overview'
      get 'dashboard' => 'stats#dashboard'
      get 'community' => 'stats#community'
    end

    concern :audited do |options|
      get 'revisions/last' => "#{options[:controller]}#last"
      resources :revisions, { only: [:index, :show] }.merge(options)
    end

    concern :commentable do |options|
      resources :comments, { only: [:index, :show, :create, :update, :destroy] }.merge(options)
    end

    concern :flaggable do |options|
      resources :flags, { only: [:index, :show, :create, :update]}.merge(options) do
        concerns :commentable, controller: 'flag_comments'
      end
    end

    concern :moderated do |options|
      get 'fields_with_pending_changes' => "#{options[:controller]}#fields_with_pending_changes"
      post 'suggested_changes/:id/accept' => "#{options[:controller]}#accept"
      post 'suggested_changes/:id/reject' => "#{options[:controller]}#reject"
      resources :suggested_changes, { only: [:index, :show, :create, :update] }.merge(options) do
        concerns :commentable, controller: 'moderation_comments'
      end
    end

    concern :advanced_search do |options|
      post '/search' => "advanced_search#create", on: :collection
      get '/search/:token' => "advanced_search#show", on: :collection
    end

    resources 'variant_groups', except: [:edit] do
      get 'variants' => 'variants#variant_group_index'
      get 'evidence_items' => 'evidence_items#variant_group_index'
      concerns :audited, controller: 'variant_group_audits'
      concerns :moderated, controller: 'variant_group_moderations'
      concerns :flaggable, controller: 'variant_group_flags'
      concerns :commentable, controller: 'variant_group_comments'
    end

    resources 'genes', except: [:edit, :new] do
      get 'variants_status' => 'variants#variant_navigation'
      get 'mygene_info_proxy' => 'genes#mygene_info_proxy'
      get 'variants' => 'variants#gene_index'
      get 'variant_groups' => 'variant_groups#gene_index'
      concerns :audited, controller: 'gene_audits'
      concerns :moderated, controller: 'gene_moderations'
      concerns :commentable, controller: 'gene_comments'
      concerns :flaggable, controller: 'gene_flags'
      concerns :advanced_search
    end

    resources 'suggested_changes', except: [:edit, :new] do
      concerns :advanced_search
    end

    resources 'variants', except: [:edit] do
      get 'myvariant_info_proxy' => 'variants#myvariant_info_proxy'
      get 'allele_registry_proxy' => 'variants#allele_registry_proxy'
      get 'mane_preferred_transcript' => 'variants#mane_preferred_transcript'
      get 'evidence_items' => 'evidence_items#variant_index'
      get 'variant_groups' => 'variant_groups#variant_index'
      get 'assertions' => 'assertions#variant_index'
      get 'indirectly_related_assertions' => 'assertions#variant_indirectly_related_index'
      concerns :audited, controller: 'variant_audits'
      concerns :moderated, controller: 'variant_moderations'
      concerns :commentable, controller: 'variant_comments'
      concerns :flaggable, controller: 'variant_flags'
      concerns :advanced_search
    end

    resources 'evidence_items', except: [:new, :create, :edit] do
      concerns :audited, controller: 'evidence_item_audits'
      concerns :moderated, controller: 'evidence_item_moderations'
      concerns :commentable, controller: 'evidence_item_comments'
      concerns :flaggable, controller: 'evidence_item_flags'
      concerns :advanced_search
      post 'accept' => 'evidence_items#accept'
      post 'reject' => 'evidence_items#reject'
      post 'revert' => 'evidence_items#revert'
    end

    resources 'assertions', except: [:new, :create, :edit] do
      concerns :flaggable, controller: 'assertion_flags'
      concerns :audited, controller: 'assertion_audits'
      concerns :commentable, controller: 'assertion_comments'
      concerns :moderated, controller: 'assertion_moderations'
      concerns :advanced_search
      post 'accept' => 'assertions#accept'
      post 'reject' => 'assertions#reject'
    end

    scope 'releases' do
      get '/' => 'tsv_releases#index'
      get 'nightly' => 'tsv_releases#nightly'
    end

    scope 'current_user' do
      get 'events' => 'users#events'
      get 'stats' => 'stats#current_user_stats'
      get 'feed' => 'notifications#index'
      patch 'feed' => 'notifications#update'
      get 'subscriptions' => 'subscriptions#current_user'
      resources 'conflict_of_interest_statements', only: [:index, :create]
    end

    delete 'current_user' => 'users#destroy'
    patch 'current_user' => 'users#update'

    resources 'users', except: [:new, :create] do
      get 'stats' => 'stats#user_stats'
      get 'events' => 'users#events'
      get 'suggestions' => 'users#username_suggestions', on: :collection
      get 'username_status' => 'users#username_status', on: :collection
    end

    resources 'sources', only: [:index, :show, :create, :update] do
      get '/existence/:citation_id' => 'sources#existence', on: :collection
      concerns :commentable, controller: 'source_comments'
      concerns :advanced_search
    end

    get '/community/leaderboards/users' => 'community#user_leaderboards'
    get '/community/leaderboards/organizations' => 'community#organization_leaderboards'

    post '/evidence_items' => 'evidence_items#propose'
    post '/assertions' => 'assertions#propose'
    post '/markdown' => 'markdown#preview'
    get '/diseases' => 'diseases#index'
    get '/diseases/existence/:doid' => 'diseases#existence'
    get '/genes/existence/:entrez_id' => 'genes#existence'
    get '/genes/local_suggestions/:q' => 'genes#local_name_suggestion'
    get '/drugs' => 'drugs#index'
    post '/drugs' => "drugs#create"
    get '/drugs/suggestions' => 'drugs#name_suggestion'
    get '/drugs/local_suggestions' => 'drugs#local_name_suggestion'
    get '/acmg_codes' => 'acmg_codes#index'
    get '/regulatory_agencies' => 'regulatory_agencies#index'
    get '/phenotypes' => 'phenotypes#index'
    get '/nccn_guidelines' => 'nccn_guidelines#index'

    get '/variant_types' => 'variant_types#index'
    get 'variant_types/relationships' => 'variant_types#relationships'

    get '/entity_suggestions' => 'entity_suggestions#index'

    scope 'docm' do
      get '/variants' => 'docm#variant_index'
    end

    get '/server' => 'server#show'

    patch '/source_suggestions/:id' => 'sources#update_source_suggestion'

    scope 'ga4gh' do
      post '/phenotypes/search' => 'ga4gh#phenotype_search'
      post '/genotypes/search' => 'ga4gh#genotype_search'
      post '/featurephenotypeassociations/search' => 'ga4gh#feature_phenotype_associations_search'
    end

    get '/badges/redeem/:claim_id' => 'badge_claim#redeem'
    get '/badges' => 'badge_claim#index'

    resources 'organizations', only: [:index, :show] do
      get 'evidence_items' => 'organizations#evidence_items'
      get 'events' => 'organizations#events'
      get 'stats' => 'organizations#stats'
    end

    resources 'subscriptions', except: [:update] do
      delete  '/' => 'subscriptions#destroy', on: :collection
    end

    resources 'domain_experts', except: [:update] do
      delete  '/' => 'domain_experts#destroy', on: :collection
    end

    get 'panels/:pipeline_tech' => 'panels#show'
    get 'panels/:pipeline_tech/qualifying_variants' => 'panels#qualifying_variants'
    get 'panels' => 'panels#index'

    scope 'curation' do
      get 'open_flags' => 'curation_dashboard#open_flags'
      get 'evidence_items_requiring_action' => 'curation_dashboard#evidence_items_requiring_action'
      get 'entities_with_outstanding_revisions' => 'curation_dashboard#entities_with_outstanding_revisions'
    end

    require 'sidekiq/web'
    require 'sidekiq/cron/web'
    mount Sidekiq::Web, at: '/jobs', constraints: UserLoggedInConstraint.new
  end


  get '/links' => 'links#redirect'
  get 'links/:idtype/:id' => 'links#redirect'

end
