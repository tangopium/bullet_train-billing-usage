module Billing::Limiter::Base
  extend ActiveSupport::Concern
  include ActiveModel::Model

  def initialize(parent)
    @parent = parent
  end

  def broken_hard_limits_for(action, model, count: 1)
    broken_limits_for(action, model, enforcement: "hard", count: count)
  end

  def broken_soft_limits_for(action, model, count: 1)
    broken_limits_for(action, model, enforcement: "soft", count: count)
  end

  def can?(action, model, count: 1)
    return true unless billing_enabled?
    broken_hard_limits_for(action, model, count: count).empty?
  end

  def current_products
    Billing::Usage::ProductCatalog.new(@parent).current_products
  end

  def exhausted?(model, enforcement = "hard")
    return false unless billing_enabled?

    broken_limits_for(:have, model, enforcement: enforcement.to_s, count: 1).any?
  end

  def exhausted_usage_for(limit, action, model, count: 0)
    # If count is nil we treat that as unlimited, and it can't be exhausted
    if limit["count"].nil?
      return nil
    end
    current_count = if action == :have
      exists_count_for(model)
    else
      usage_for(action, model, limit["duration"], limit["interval"]) || 0
    end

    current_count + count > limit["count"] ? current_count : nil
  end

  def hard_limits_for(action, model)
    limits_for(action, model, enforcement: "hard")
  end

  def limits_for(action, model, enforcement: nil)
    # Collect any relevant limits from all active products.
    all_limits = current_products.map do |product|
      limits = product.respond_to?(:limits) && product.limits.present? ? (product.limits[limit_key(model)] || {}) : {}
      limits.each do |action, limit|
        limit["product_id"] = product.id
      end
      limits
    end.compact.map do |limits_by_action|
      limits_by_action[action.to_s]
    end.compact

    if enforcement.present?
      all_limits.select { |limit| limit["enforcement"] == enforcement.to_s }
    else
      all_limits
    end
  end

  private

  def broken_limits_for(action, model, enforcement:, count: 1)
    limit = enforced_limit_for(action, model, enforcement: enforcement)

    [].tap do |exceeded_limits|
      if (exhausted_usage = exhausted_usage_for(limit, action, model, count: count))
        # We notate the action here because `:create` ends up aggregating broken limits for both `:create` and `:have`.
        exceeded_limits << {action: action, usage: exhausted_usage, limit: limit}
      end

      # If we're checking whether we can create something, we also need to check if it can exist.
      if action == :create
        exceeded_limits << broken_limits_for(:have, model, enforcement: enforcement, count: count)
      end
    end
  end

  def collection_for(model)
    limit_key(model).underscore.to_sym
  end

  def enforced_limit_for(action, model, enforcement:)
    # most permissive limit wins out
    limits = limits_for(action, model, enforcement: enforcement)

    if limits.any? { |limit| limit.has_key?("count") && limit["count"].nil? }
      # a nil count represents unlimited
      []
    else
      limits.max_by { |limit| limit["count"] }
    end
  end

  def exists_count_for(model)
    @parent.send(collection_for(model)).billable.count
  end

  def limit_key(model)
    model.to_s.underscore.tr("/", "_").pluralize
  end

  def usage_for(action, model, duration, interval)
    @parent.billing_usage_trackers.current.detect do |tracker|
      tracker.duration == duration && tracker.interval == interval
    end&.counts&.for(action.to_s.verb.conjugate(tense: :past), model)&.count
  end
end
