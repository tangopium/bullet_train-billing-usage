module Billing::UsageHelper
  include ActionView::Helpers::NumberHelper

  def broken_hard_limits_message(limiter, model, action: :create, count: 1)
    limiter.broken_hard_limits_for(action, model, count: count).each_with_index.reduce([]) do |message_parts, (limit, index)|
      message_parts << broken_limits_introduction(model, limit, index: index, count: count)
      message_parts << broken_hard_limits_usage(limit, count: count)
      message_parts << broken_limits_limit(model, limit)
    end.flatten.join(" ")
  end

  def broken_soft_limits_message(limiter, model, action: :create, count: 1)
    limiter.broken_soft_limits_for(action, model, count: count).each_with_index.each_with_object([]) do |(limit, index), message_parts|
      message_parts << broken_limits_introduction(model, limit, index: index, count: count)
      message_parts << broken_soft_limits_usage(limit, count: count)
      message_parts << broken_limits_limit(model, limit)
      message_parts
    end.flatten.join(" ")
  end

  def broken_hard_limits_upgradable?(limiter, model, action: :create, count: 1)
    limiter.broken_hard_limits_for(action, model, count: count).any? { |limit| limit_upgradable?(limit) }
  end

  def broken_soft_limits_upgradable?(limiter, model, action: :create, count: 1)
    limiter.broken_soft_limits_for(action, model, count: count).any? { |limit| limit_upgradable?(limit) }
  end

  private

  def broken_limits_introduction(model, limit, count:, index:)
    return ["You've"] unless display_unavailable_action?(limit, count)

    action = limit[:action]

    introduction = ["You"]
    introduction << "also" if index > 0
    introduction << "can't"
    introduction << (action == :have ? "add" : action)
    introduction << (count == 1 ? "a" : number_with_delimiter(count))
    introduction << broken_limits_model_name(model, count: count)
  end

  def broken_limits_limit(model, limit)
    limit_count = limit.dig(:limit, "count")
    duration = limit.dig(:limit, "duration") || 1
    interval = limit.dig(:limit, "interval")
    product_id = limit.dig(:limit, "product_id")

    limit = [number_with_delimiter(limit_count)]
    limit << broken_limits_model_name(model, count: limit_count)
    limit << "allowed by your"
    limit << I18n.t("billing/products.#{product_id}.name")
    limit << if interval.nil?
      "account."
    else
      "account in the current #{duration} #{interval.singularize} period."
    end
    limit
  end

  def broken_limits_model_name(model, count:)
    I18n.t("#{model.name.underscore.pluralize}.label").singularize.pluralize(count)
  end

  def broken_hard_limits_usage(limit, count:)
    action = limit[:action]

    usage = []

    usage << if action == :have
      (count.zero? ? "used" : "because you already have")
    else
      "because you've already #{action.verb.conjugate(tense: :past)}"
    end

    usage << number_with_delimiter(limit[:usage])
    usage << (action == :have && count.zero? ? "of" : "out of")
  end

  def broken_soft_limits_usage(limit, count:)
    action = limit[:action]

    usage = []

    usage << (action == :have ? "used" : action.verb.conjugate(tense: :past))

    usage << number_with_delimiter(limit[:usage])
    usage << (action == :have && count.zero? ? "of" : "out of")
  end

  def display_unavailable_action?(limit, count)
    enforcement = limit.dig(:limit, "enforcement")

    !(limit[:action] == :have && count.zero?) && enforcement == "hard"
  end

  def limit_upgradable?(limit)
    limit.dig(:limit, "upgradable")
  end
end
