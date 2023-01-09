module Billing::UsageHelper
  include ActionView::Helpers::NumberHelper

  def broken_hard_limits_message(limiter, model, action: :create, count: 1)
    limiter.broken_hard_limits_for(action, model, count: count).each_with_index.reduce([]) do |message_parts, (limit, index)|
      message_parts << broken_hard_limits_introduction(model, limit, index: index, count: count)
      message_parts << broken_hard_limits_usage(limit, count: count)
      message_parts << broken_hard_limits_limit(model, limit)
    end.flatten.join(" ")
  end

  private

  def broken_hard_limits_introduction(model, limit, index:, count:)
    action = limit[:action]

    if action == :have && count.zero? # already exhausted product
      return ["You've"]
    end

    introduction = ["You"]
    introduction << "also" if index > 0
    introduction << "can't"
    introduction << (action == :have ? "add" : action)
    introduction << (count == 1 ? "a" : number_with_delimiter(count))
    introduction << I18n.t("#{model.name.underscore.pluralize}.label").singularize.pluralize(count)
  end

  def broken_hard_limits_limit(model, limit)
    limit_count = limit.dig(:limit, "count")
    duration = limit.dig(:limit, "duration") || 1
    interval = limit.dig(:limit, "interval")
    product_id = limit.dig(:limit, "product_id")

    limit = [number_with_delimiter(limit_count)]
    limit << I18n.t("#{model.name.underscore.pluralize}.label").singularize.pluralize(limit_count)
    limit << "allowed by your"
    limit << I18n.t("billing/products.#{product_id}.name")
    limit << "account#{"." if interval.nil?}"
    limit << "in the current #{duration} #{interval.singularize} period." unless interval.nil?

    limit
  end

  def broken_hard_limits_usage(limit, count:)
    action = limit[:action]

    usage = []

    if action == :have
      usage << (count.zero? ? "used" : "because you already have")
    else
      usage << "because you've already #{action.verb.conjugate(tense: :past)}"
    end

    usage << number_with_delimiter(limit[:usage])
    usage << (action == :have && count.zero? ? "of" : "out of")
  end
end
